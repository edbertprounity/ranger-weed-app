import 'dart:io';

import 'package:citp_ranger/data/local/app_database.dart';
import 'package:citp_ranger/data/models/site.dart';
import 'package:citp_ranger/data/models/treatment.dart';
import 'package:citp_ranger/data/reminders.dart';
import 'package:citp_ranger/state/app_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class SilentReminders extends ReminderService {
  @override
  Future<void> init() async {}

  @override
  Future<void> reschedule(List<SiteView> followUps) async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  test('a saved site and spray are still there after the database closes', () async {
    final folder = await Directory.systemTemp.createTemp('citp_ranger');
    final path = '${folder.path}${Platform.pathSeparator}ranger.db';
    final first = AppController(
      database: await AppDatabase.open(path: path),
      reminders: SilentReminders(),
    );
    await first.start();
    await first.setRangerName('Riley');

    final draft = await first.createDraft();
    await first.saveSite(
      draft.copyWith(speciesKey: 'lantana', latitude: -14.36, longitude: 143.68, notes: 'North of camp'),
    );
    expect(await first.publishSite(draft.id), isNull);
    await first.addTreatment(draft.id, 'Spot spray');

    final before = first.siteById(draft.id);
    final treatment = first.latestTreatment(draft.id);
    expect(before?.status, SiteStatus.open);
    expect(before?.notes, 'North of camp');
    expect(treatment, isNotNull);
    expect(
      treatment!.nextCheckDue.difference(treatment.treatedAt).inDays,
      30,
    );

    final second = AppController(
      database: await AppDatabase.open(path: path),
      reminders: SilentReminders(),
    );
    await second.start();
    final after = second.siteById(draft.id);
    expect(after?.speciesKey, 'lantana');
    expect(after?.notes, 'North of camp');
    expect(second.latestTreatment(draft.id)?.notes, 'Spot spray');
    expect(second.priorityList.any((view) => view.site.id == draft.id), isTrue);
    expect(second.sites.where((site) => site.status == SiteStatus.open).length, 7);
  });
}
