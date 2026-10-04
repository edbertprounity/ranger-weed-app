import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../core/local_auth.dart';
import '../core/priority.dart';
import '../core/role.dart';
import '../core/supabase_config.dart';
import '../data/demo_data.dart';
import '../data/local/app_database.dart';
import '../data/local/photo_store.dart';
import '../data/models/site.dart';
import '../data/models/treatment.dart';
import '../data/reminders.dart';
import '../data/remote/supabase_gate.dart';
import '../data/remote/sync.dart';

class AppController extends ChangeNotifier {
  AppController({
    AppDatabase? database,
    PhotoStore? photos,
    ReminderService? reminders,
    SyncService? sync,
  }) : _photos = photos ?? PhotoStore(),
       _reminders = reminders ?? ReminderService(),
       _database = database,
       _sync = sync;

  final PhotoStore _photos;
  final ReminderService _reminders;
  AppDatabase? _database;
  SyncService? _sync;
  final Uuid _uuid = const Uuid();
  StreamSubscription<List<ConnectivityResult>>? _connectivity;

  bool online = false;

  bool ready = false;
  bool syncing = false;
  AppRole? role;
  String? rangerName;
  String? signedInEmail;
  String? syncMessage;
  List<Site> sites = [];
  List<Treatment> treatments = [];

  bool get sharingReady => SupabaseConfig.enabled && SupabaseGate.ready;

  bool get canReview => role == AppRole.admin;

  bool get canRecordTreatment => role == AppRole.admin || role == AppRole.ranger;

  List<SiteView> get priorityList {
    final open = sites.where((site) => site.status == SiteStatus.open);
    return prioritize([
      for (final site in open) SiteView(site: site, treatment: latestTreatment(site.id)),
    ], DateTime.now().toUtc());
  }

  List<SiteView> get followUps => orderFollowUps(priorityList);

  List<Site> get pendingReviews {
    final rows = sites.where((site) => site.status == SiteStatus.pending).toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return rows;
  }

  List<Site> get drafts {
    final name = rangerName;
    final mine = sites.where(
      (site) => site.status == SiteStatus.draft && site.rangerName == name,
    );
    final ordered = mine.toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return ordered;
  }

  int get waitingToUpload {
    final sitesWaiting = sites.where(
      (site) => site.status != SiteStatus.draft && site.syncedAt == null,
    );
    final treatmentsWaiting = treatments.where((item) => item.syncedAt == null);
    return sitesWaiting.length + treatmentsWaiting.length;
  }

  /// Public visitors only hear about the reports they just sent.
  int get recordsWaitingToSync {
    if (role != AppRole.public) return waitingToUpload;
    final name = rangerName;
    return sites
        .where(
          (site) =>
              site.source == 'public' &&
              site.rangerName == name &&
              site.status != SiteStatus.draft &&
              site.syncedAt == null,
        )
        .length;
  }

  List<Site> get ownPublicReports {
    final name = rangerName;
    final rows =
        sites
            .where(
              (site) =>
                  site.source == 'public' &&
                  site.rangerName == name &&
                  site.status != SiteStatus.draft,
            )
            .toList()
          ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return rows;
  }

  Site? siteById(String id) {
    for (final site in sites) {
      if (site.id == id) return site;
    }
    return null;
  }

  Treatment? latestTreatment(String siteId) {
    Treatment? best;
    for (final treatment in treatments) {
      if (treatment.siteId != siteId) continue;
      if (best == null || treatment.treatedAt.isAfter(best.treatedAt)) {
        best = treatment;
      }
    }
    return best;
  }

  List<Treatment> treatmentsFor(String siteId) {
    final rows = treatments.where((item) => item.siteId == siteId).toList()
      ..sort((a, b) => b.treatedAt.compareTo(a.treatedAt));
    return rows;
  }

  Future<void> start() async {
    final database = _database ?? await AppDatabase.open();
    _database = database;
    _sync ??= SyncService(database, _photos);
    await database.seedIfEmpty(buildDemoData(DateTime.now()));
    role = roleFromName(await database.getMeta('role'));
    rangerName = await database.getMeta('ranger_name');
    signedInEmail = await database.getMeta('account_email');
    await reload();
    try {
      await _reminders.init().timeout(const Duration(seconds: 4));
      await _reminders.reschedule(followUps).timeout(const Duration(seconds: 4));
    } catch (_) {
      // The follow-up list is already stored. A reminder popup is optional.
    }
    ready = true;
    notifyListeners();
    await _watchConnection();
    unawaited(syncNow());
  }

  Future<void> _watchConnection() async {
    if (Platform.environment['FLUTTER_TEST'] == 'true') return;
    final connectivity = Connectivity();
    try {
      final current = await connectivity.checkConnectivity();
      await _applyLink(_hasLink(current));
      _connectivity = connectivity.onConnectivityChanged.listen((results) {
        unawaited(_applyLink(_hasLink(results)));
      });
    } catch (_) {
      await _applyLink(false);
    }
  }

  /// A network adapter can report "none" on Windows while the internet still works.
  /// The status follows a live check in that case.
  Future<void> _applyLink(bool interfaceUp) async {
    final linked = interfaceUp || await _canReachInternet();
    final becameOnline = linked && !online;
    online = linked;
    notifyListeners();
    if (becameOnline) unawaited(syncNow());
  }

  Future<bool> _canReachInternet() async {
    if (kIsWeb) return false;
    final client = HttpClient();
    try {
      client.connectionTimeout = const Duration(seconds: 3);
      final request = await client
          .getUrl(Uri.parse('https://www.gstatic.com/generate_204'))
          .timeout(const Duration(seconds: 4));
      final response = await request.close().timeout(const Duration(seconds: 4));
      await response.drain<void>();
      return response.statusCode == 204 || response.statusCode == 200;
    } catch (_) {
      return false;
    } finally {
      client.close(force: true);
    }
  }

  bool _hasLink(List<ConnectivityResult> results) {
    return results.any((result) => result != ConnectivityResult.none);
  }

  @override
  void dispose() {
    _connectivity?.cancel();
    super.dispose();
  }

  Future<void> reload() async {
    final database = _database;
    if (database == null) return;
    sites = await database.allSites();
    treatments = await database.allTreatments();
    notifyListeners();
  }

  Future<void> setRangerName(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    rangerName = trimmed;
    await _database?.setMeta('ranger_name', trimmed);
    notifyListeners();
  }

  Future<void> signOut() async {
    role = null;
    rangerName = null;
    signedInEmail = null;
    await _database?.deleteMeta('role');
    await _database?.deleteMeta('ranger_name');
    await _database?.deleteMeta('account_email');
    notifyListeners();
  }

  Future<String?> signIn(String email, String password) async {
    final normalised = email.trim().toLowerCase();
    if (normalised.isEmpty || password.isEmpty) {
      return 'Enter the email and password.';
    }
    if (sharingReady) {
      try {
        final rows = await Supabase.instance.client.rpc(
          'sign_in',
          params: {'p_email': normalised, 'p_password': password},
        );
        if (rows is List && rows.isNotEmpty) {
          final row = Map<String, dynamic>.from(rows.first as Map);
          final nextRole = roleFromName(row['role']?.toString());
          final name = (row['display_name'] as String?)?.trim();
          if (nextRole != null && name != null && name.isNotEmpty) {
            await _database?.rememberAccount(
              LocalAccount(
                email: normalised,
                passwordHash: localPasswordHash(normalised, password),
                role: nextRole,
                displayName: name,
              ),
            );
            await _database?.setMeta('account_email', normalised);
            signedInEmail = normalised;
            await _enter(nextRole, name);
            return null;
          }
        }
        return 'Those details were not recognised.';
      } catch (_) {
        // The link dropped. A sign-in already stored on this phone can still open.
      }
    }
    final cached = await _database?.accountByEmail(normalised);
    if (cached != null && cached.passwordHash == localPasswordHash(normalised, password)) {
      await _database?.setMeta('account_email', normalised);
      signedInEmail = normalised;
      await _enter(cached.role, cached.displayName);
      return null;
    }
    return sharingReady
        ? 'Those details were not recognised.'
        : 'Sign in once while online. After that this phone keeps the sign-in.';
  }

  Future<void> _enter(AppRole nextRole, String name) async {
    role = nextRole;
    rangerName = name;
    await _database?.setMeta('role', nextRole.name);
    await _database?.setMeta('ranger_name', name);
    notifyListeners();
    unawaited(syncNow());
  }

  /// Stores a ranger or admin on this phone, then asks the shared database to keep the same account.
  /// The admin password is sent only for that check and is not saved.
  Future<String?> createAccount({
    required String adminEmail,
    required String adminPassword,
    required String email,
    required String password,
    required String displayName,
    AppRole accountRole = AppRole.ranger,
  }) async {
    if (role != AppRole.admin) return 'Only an admin can add an account.';
    if (accountRole == AppRole.public) return 'Public visitors do not get an account.';
    final normalised = email.trim().toLowerCase();
    final name = displayName.trim();
    final admin = adminEmail.trim().toLowerCase();
    if (name.isEmpty) return 'Enter the person’s name.';
    if (!normalised.contains('@') || !normalised.split('@').last.contains('.')) {
      return 'Enter a valid email.';
    }
    if (password.length < 8) return 'Use a password of at least 8 characters.';
    if (admin.isEmpty || adminPassword.isEmpty) {
      return 'Enter your admin email and password to confirm.';
    }

    final storedAdmin = await _database?.accountByEmail(admin);
    final adminConfirmedLocally = storedAdmin != null &&
        storedAdmin.role == AppRole.admin &&
        storedAdmin.passwordHash == localPasswordHash(admin, adminPassword);
    if (storedAdmin != null && !adminConfirmedLocally) {
      return 'Your admin password was not accepted.';
    }
    if (!adminConfirmedLocally && (!sharingReady || Platform.environment['FLUTTER_TEST'] == 'true')) {
      return 'Your admin password was not accepted.';
    }

    var shared = false;
    if (sharingReady && Platform.environment['FLUTTER_TEST'] != 'true') {
      try {
        await Supabase.instance.client.rpc(
          'create_account',
          params: {
            'p_admin_email': admin,
            'p_admin_password': adminPassword,
            'p_email': normalised,
            'p_password': password,
            'p_display_name': name,
            'p_role': accountRole.name,
          },
        );
        shared = true;
      } on PostgrestException catch (error) {
        final detail = error.message.toLowerCase();
        if (detail.contains('not authorised')) {
          return 'Your admin password was not accepted.';
        }
        if (!adminConfirmedLocally) {
          return 'The shared database did not confirm this account.';
        }
      } catch (_) {
        if (!adminConfirmedLocally) {
          return 'The shared database did not confirm this account.';
        }
      }
    }

    await _database?.rememberAccount(
      LocalAccount(
        email: normalised,
        passwordHash: localPasswordHash(normalised, password),
        role: accountRole,
        displayName: name,
      ),
    );
    if (shared) return null;
    if (!sharingReady) {
      return 'Saved on this phone. Connect, then add the account again to share it.';
    }
    return 'Saved on this phone. The shared database did not store it yet.';
  }

  Future<void> continueAsPublic(String name) async {
    final trimmed = name.trim().isEmpty ? 'Public' : name.trim();
    role = AppRole.public;
    rangerName = trimmed;
    await _database?.setMeta('role', AppRole.public.name);
    await _database?.setMeta('ranger_name', trimmed);
    notifyListeners();
    unawaited(syncNow());
  }

  Future<Site> createDraft() async {
    final now = DateTime.now().toUtc();
    final site = Site(
      id: _uuid.v4(),
      rangerName: rangerName ?? 'Ranger',
      speciesKey: '',
      notes: '',
      status: SiteStatus.draft,
      source: role == AppRole.public
          ? 'public'
          : role == AppRole.admin
          ? 'admin'
          : 'ranger',
      createdAt: now,
      updatedAt: now,
    );
    await _database!.upsertSite(site);
    await reload();
    return site;
  }

  Future<void> saveSite(Site site) async {
    final existing = siteById(site.id);
    final incoming = site.photoPath;
    final keptPhoto = (incoming == null || incoming.isEmpty) ? existing?.photoPath : incoming;
    final next = site.copyWith(
      photoPath: keptPhoto,
      updatedAt: DateTime.now().toUtc(),
      syncedAt: null,
    );
    await _database!.upsertSite(next);
    await reload();
  }

  Future<String?> publishSite(String id) async {
    final site = siteById(id);
    if (site == null) return 'This draft is no longer on the phone.';
    if (site.speciesKey.isEmpty) return 'Choose a weed species.';
    final listed = role == AppRole.public ? SiteStatus.pending : SiteStatus.open;
    await saveSite(site.copyWith(status: listed));
    await _reminders.reschedule(followUps);
    unawaited(syncNow());
    return null;
  }

  Future<void> discardDraft(String id) async {
    final site = siteById(id);
    if (site == null || site.status != SiteStatus.draft) return;
    await _photos.deleteIfPresent(site.photoPath);
    await _database!.deleteSite(id);
    await reload();
  }

  Future<String> attachPhoto(String siteId, String sourcePath) async {
    final bytes = await File(resolvePhotoPath(sourcePath)).readAsBytes();
    return attachPhotoBytes(siteId, bytes);
  }

  /// Writes a compressed JPEG into the documents folder and queues the row for sync.
  Future<String> attachPhotoBytes(String siteId, List<int> bytes) async {
    final saved = await _photos.writeCompressed(siteId, bytes);
    final site = siteById(siteId);
    if (site != null) {
      await saveSite(site.copyWith(photoPath: saved));
    }
    return saved;
  }

  /// Keeps a treatment photo in the documents folder before the temporary camera file disappears.
  Future<String> stagePhoto(List<int> bytes) => _photos.writeCompressed(_uuid.v4(), bytes);

  Future<void> decideReview(String id, {required bool approve}) async {
    final site = siteById(id);
    if (site == null || !canReview) return;
    await saveSite(site.copyWith(status: approve ? SiteStatus.open : SiteStatus.rejected));
    unawaited(syncNow());
  }

  Future<void> addTreatment(
    String siteId,
    String notes, {
    int followUpDays = 30,
    String? photoSourcePath,
  }) async {
    final now = DateTime.now().toUtc();
    final id = _uuid.v4();
    final days = followUpDays < 1 ? 1 : followUpDays;
    String? photoPath;
    if (photoSourcePath != null && photoSourcePath.isNotEmpty) {
      photoPath = await _photos.copyIn(id, photoSourcePath);
    }
    final treatment = Treatment(
      id: id,
      siteId: siteId,
      rangerName: rangerName ?? 'Ranger',
      treatedAt: now,
      notes: notes.trim(),
      nextCheckDue: now.add(Duration(days: days)),
      photoPath: photoPath,
    );
    await _database!.upsertTreatment(treatment);
    await reload();
    await _reminders.reschedule(followUps);
    unawaited(syncNow());
  }

  Future<void> syncNow({bool manual = false}) async {
    if (Platform.environment['FLUTTER_TEST'] == 'true') return;
    if (syncing) return;
    if (!sharingReady) {
      await SupabaseGate.tryInit();
    }
    if (!sharingReady) {
      if (manual) {
        syncMessage = online
            ? 'This phone is online. Records upload once the database link is set.'
            : 'Saved on this phone. Pending records upload when the link returns.';
        notifyListeners();
      }
      return;
    }
    syncing = true;
    if (manual) syncMessage = 'Uploading pending records...';
    notifyListeners();
    try {
      final failed = await _sync!.sync();
      await reload();
      await _reminders.reschedule(followUps);
      if (manual) {
        syncMessage = failed == 0
            ? 'Camp list updated. Other phones can see these records.'
            : 'Some records are still pending sync. They stay on this phone.';
      }
    } catch (_) {
      if (manual) {
        syncMessage = 'Still saved on this phone. Pending sync waits for the link.';
      }
    } finally {
      syncing = false;
      notifyListeners();
    }
  }
}
