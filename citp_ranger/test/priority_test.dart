import 'package:citp_ranger/core/priority.dart';
import 'package:citp_ranger/data/models/site.dart';
import 'package:citp_ranger/data/models/treatment.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime.utc(2026, 10, 1, 12);

  Site site(String id, String species, int ageDays) {
    final created = now.subtract(Duration(days: ageDays));
    return Site(
      id: id,
      rangerName: 'Alex',
      speciesKey: species,
      notes: '',
      status: SiteStatus.open,
      createdAt: created,
      updatedAt: created,
    );
  }

  Treatment spray(String siteId, int daysAgo) {
    final treated = now.subtract(Duration(days: daysAgo));
    return Treatment(
      id: 't-$siteId',
      siteId: siteId,
      rangerName: 'Alex',
      treatedAt: treated,
      notes: '',
      nextCheckDue: treated.add(const Duration(days: 30)),
    );
  }

  test('overdue sites come before untreated, then scheduled', () {
    final views = [
      SiteView(site: site('gamba', 'gamba_grass', 9)),
      SiteView(site: site('rubber', 'rubbervine', 18)),
      SiteView(
        site: site('sickle', 'sicklepod', 45),
        treatment: spray('sickle', 40),
      ),
      SiteView(
        site: site('lantana', 'lantana', 12),
        treatment: spray('lantana', 10),
      ),
    ];

    final ordered = prioritize(views, now).map((view) => view.site.id).toList();
    expect(ordered, ['sickle', 'rubber', 'gamba', 'lantana']);
  });

  test('untreated sites follow the weed action plan order', () {
    final views = [
      SiteView(site: site('olive', 'olive_hymenachne', 4)),
      SiteView(site: site('rubber', 'rubbervine', 3)),
    ];

    final ordered = prioritize(views, now).map((view) => view.site.speciesKey).toList();
    expect(ordered, ['rubbervine', 'olive_hymenachne']);
  });

  test('follow-ups list the earliest re-check first', () {
    final views = [
      SiteView(site: site('olive', 'olive_hymenachne', 4), treatment: spray('olive', 2)),
      SiteView(site: site('sickle', 'sicklepod', 45), treatment: spray('sickle', 40)),
      SiteView(site: site('rubber', 'rubbervine', 18)),
    ];

    final ordered = orderFollowUps(views).map((view) => view.site.id).toList();
    expect(ordered, ['sickle', 'olive']);
  });
}
