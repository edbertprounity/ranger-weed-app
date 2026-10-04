import 'models/site.dart';
import 'models/treatment.dart';

const demoRubbervine = '11111111-1111-4111-8111-111111111101';
const demoSicklepod = '11111111-1111-4111-8111-111111111102';
const demoLantana = '11111111-1111-4111-8111-111111111103';
const demoGamba = '11111111-1111-4111-8111-111111111104';
const demoRatsTail = '11111111-1111-4111-8111-111111111105';
const demoOlive = '11111111-1111-4111-8111-111111111106';

const demoTreatSicklepod = '22222222-2222-4222-8222-222222222202';
const demoTreatLantana = '22222222-2222-4222-8222-222222222203';
const demoTreatOlive = '22222222-2222-4222-8222-222222222206';

class DemoBundle {
  const DemoBundle({required this.sites, required this.treatments});

  final List<Site> sites;
  final List<Treatment> treatments;
}

DemoBundle buildDemoData(DateTime now) {
  final utc = now.toUtc();
  Site site({
    required String id,
    required String ranger,
    required String species,
    required double latitude,
    required double longitude,
    required String note,
    required int ageDays,
  }) {
    final created = utc.subtract(Duration(days: ageDays));
    return Site(
      id: id,
      rangerName: ranger,
      speciesKey: species,
      latitude: latitude,
      longitude: longitude,
      notes: note,
      status: SiteStatus.open,
      createdAt: created,
      updatedAt: created,
    );
  }

  Treatment spray({
    required String id,
    required String siteId,
    required String ranger,
    required int daysAgo,
  }) {
    final treated = utc.subtract(Duration(days: daysAgo));
    return Treatment(
      id: id,
      siteId: siteId,
      rangerName: ranger,
      treatedAt: treated,
      notes: 'Demo spray record.',
      nextCheckDue: treated.add(const Duration(days: 30)),
    );
  }

  const note = 'Demo point for the prototype. Not a surveyed infestation.';
  return DemoBundle(
    sites: [
      site(
        id: demoRubbervine,
        ranger: 'Alex',
        species: 'rubbervine',
        latitude: -14.35210,
        longitude: 143.67120,
        note: note,
        ageDays: 18,
      ),
      site(
        id: demoSicklepod,
        ranger: 'Sam',
        species: 'sicklepod',
        latitude: -14.36080,
        longitude: 143.68940,
        note: note,
        ageDays: 45,
      ),
      site(
        id: demoLantana,
        ranger: 'Jo',
        species: 'lantana',
        latitude: -14.37120,
        longitude: 143.67650,
        note: note,
        ageDays: 12,
      ),
      site(
        id: demoGamba,
        ranger: 'Alex',
        species: 'gamba_grass',
        latitude: -14.34760,
        longitude: 143.70110,
        note: note,
        ageDays: 9,
      ),
      site(
        id: demoRatsTail,
        ranger: 'Sam',
        species: 'giant_rats_tail',
        latitude: -14.37840,
        longitude: 143.70880,
        note: note,
        ageDays: 6,
      ),
      site(
        id: demoOlive,
        ranger: 'Jo',
        species: 'olive_hymenachne',
        latitude: -14.35690,
        longitude: 143.65870,
        note: note,
        ageDays: 4,
      ),
    ],
    treatments: [
      spray(
        id: demoTreatSicklepod,
        siteId: demoSicklepod,
        ranger: 'Sam',
        daysAgo: 40,
      ),
      spray(
        id: demoTreatLantana,
        siteId: demoLantana,
        ranger: 'Jo',
        daysAgo: 10,
      ),
      spray(id: demoTreatOlive, siteId: demoOlive, ranger: 'Jo', daysAgo: 2),
    ],
  );
}
