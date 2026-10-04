import '../data/models/treatment.dart';
import 'species.dart';

enum PriorityBand { overdue, untreated, scheduled }

PriorityBand bandFor(SiteView view, DateTime now) {
  final due = view.treatment?.nextCheckDue;
  if (due != null && due.isBefore(now)) return PriorityBand.overdue;
  if (view.treatment == null) return PriorityBand.untreated;
  return PriorityBand.scheduled;
}

/// Overdue re-checks, then untreated sites, then species order from the
/// Weeds Action Plan.
List<SiteView> prioritize(List<SiteView> views, DateTime now) {
  final ordered = [...views];
  ordered.sort((a, b) {
    final byBand = bandFor(a, now).index.compareTo(bandFor(b, now).index);
    if (byBand != 0) return byBand;
    final bySpecies = WeedSpecies.rank(a.site.speciesKey).compareTo(
      WeedSpecies.rank(b.site.speciesKey),
    );
    if (bySpecies != 0) return bySpecies;
    return a.site.createdAt.compareTo(b.site.createdAt);
  });
  return ordered;
}

/// Earliest re-check first, which puts overdue sites at the top.
List<SiteView> orderFollowUps(List<SiteView> views) {
  final withTreatment = views.where((view) => view.treatment != null).toList();
  withTreatment.sort(
    (a, b) => a.treatment!.nextCheckDue.compareTo(b.treatment!.nextCheckDue),
  );
  return withTreatment;
}
