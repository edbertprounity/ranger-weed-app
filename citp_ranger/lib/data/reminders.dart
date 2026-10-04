import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../core/species.dart';
import 'models/treatment.dart';

class ReminderService {
  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _ready = false;

  Future<void> init() async {
    tzdata.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Australia/Brisbane'));
    const settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      windows: WindowsInitializationSettings(
        appName: 'Ranger App',
        appUserModelId: 'Com.Citp.Prototype.RangerApp',
        guid: 'c1a7b2e4-6d58-4a1e-9f33-7b2e8a4d1c90',
      ),
    );
    try {
      await _plugin.initialize(settings);
      await _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.requestNotificationsPermission();
      _ready = true;
    } catch (_) {
      _ready = false;
    }
  }

  Future<void> reschedule(List<SiteView> followUps) async {
    if (!_ready) return;
    try {
      await _plugin.cancelAll();
      final now = tz.TZDateTime.now(tz.local);
      for (final view in followUps) {
        final due = view.treatment?.nextCheckDue;
        if (due == null) continue;
        final when = tz.TZDateTime.from(due.toUtc(), tz.local);
        if (!when.isAfter(now)) continue;
        final species = WeedSpecies.byKey(view.site.speciesKey)?.name ?? 'weed';
        await _plugin.zonedSchedule(
          view.site.id.hashCode & 0x7fffffff,
          'Re-check $species',
          'Follow up the site logged by ${view.site.rangerName}.',
          when,
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'weed_followups',
              'Weed follow-ups',
              channelDescription: 'Reminders to re-check a treated site',
            ),
          ),
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        );
      }
    } catch (_) {
      // The follow-up list is saved in the phone database either way.
    }
  }
}
