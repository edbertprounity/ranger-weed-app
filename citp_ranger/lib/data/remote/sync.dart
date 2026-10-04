import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../local/app_database.dart';
import '../local/photo_store.dart';
import '../models/site.dart';
import '../models/treatment.dart';

class SyncService {
  SyncService(this.db, this.photos);

  final AppDatabase db;
  final PhotoStore photos;

  Future<int> sync() async {
    final client = Supabase.instance.client;
    var failed = 0;
    failed += await _pushSites(client);
    failed += await _pushTreatments(client);
    try {
      await _pullSites(client);
      await _pullTreatments(client);
    } catch (_) {
      failed += 1;
    }
    return failed;
  }

  Future<int> _pushSites(SupabaseClient client) async {
    final sites = await db.allSites();
    var failed = 0;
    for (final site in sites) {
      if (site.status == SiteStatus.draft || site.syncedAt != null) continue;
      try {
        var photoUrl = site.photoUrl;
        final path = site.photoPath;
        if (path != null && File(resolvePhotoPath(path)).existsSync()) {
          await client.storage.from('site-photos').uploadBinary(
            '${site.id}.jpg',
            await File(resolvePhotoPath(path)).readAsBytes(),
            fileOptions: const FileOptions(upsert: true, contentType: 'image/jpeg'),
          );
          photoUrl = client.storage.from('site-photos').getPublicUrl('${site.id}.jpg');
        }
        final payload = site.copyWith(photoUrl: photoUrl).toRemote();
        await client.from('sites').upsert(payload);
        await db.markSiteSynced(site.id, photoUrl);
      } catch (_) {
        failed += 1;
      }
    }
    return failed;
  }

  Future<int> _pushTreatments(SupabaseClient client) async {
    final treatments = await db.allTreatments();
    final sites = {for (final site in await db.allSites()) site.id: site};
    var failed = 0;
    for (final treatment in treatments) {
      if (treatment.syncedAt != null) continue;
      final site = sites[treatment.siteId];
      if (site == null || site.status != SiteStatus.open) continue;
      try {
        await client.from('treatments').upsert(treatment.toRemote());
        await db.markTreatmentSynced(treatment.id);
      } catch (_) {
        failed += 1;
      }
    }
    return failed;
  }

  Future<void> _pullSites(SupabaseClient client) async {
    final rows = await client.from('sites').select();
    final local = {for (final site in await db.allSites()) site.id: site};
    for (final row in rows) {
      final incoming = Site.fromRemote(
        Map<String, dynamic>.from(row as Map),
        photoPath: local[row['id'].toString()]?.photoPath,
      );
      if (incoming.status == SiteStatus.draft) continue;
      final existing = local[incoming.id];
      if (existing != null &&
          existing.syncedAt == null &&
          existing.status != SiteStatus.draft) {
        continue;
      }
      await db.upsertSite(incoming);
      await _downloadPhoto(client, incoming);
    }
  }

  Future<void> _downloadPhoto(SupabaseClient client, Site site) async {
    if (site.photoUrl == null || site.photoUrl!.isEmpty) return;
    final path = site.photoPath;
    if (path != null && File(resolvePhotoPath(path)).existsSync()) return;
    try {
      final bytes = await client.storage.from('site-photos').download('${site.id}.jpg');
      final saved = await photos.writeBytes(site.id, bytes);
      await db.setPhotoPath(site.id, saved);
    } catch (_) {
      // The row is already saved. The photo can download on the next share.
    }
  }

  Future<void> _pullTreatments(SupabaseClient client) async {
    final rows = await client.from('treatments').select();
    final local = {
      for (final treatment in await db.allTreatments()) treatment.id: treatment,
    };
    final siteIds = {for (final site in await db.allSites()) site.id};
    for (final row in rows) {
      final existing = local[row['id'].toString()];
      final incoming = Treatment.fromRemote(
        Map<String, dynamic>.from(row as Map),
        photoPath: existing?.photoPath,
      );
      if (!siteIds.contains(incoming.siteId)) continue;
      if (existing != null && existing.syncedAt == null) continue;
      await db.upsertTreatment(incoming);
    }
  }
}
