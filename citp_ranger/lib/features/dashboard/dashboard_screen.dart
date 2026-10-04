import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/format.dart';
import '../../core/navigation.dart';
import '../../core/priority.dart';
import '../../core/species.dart';
import '../../core/theme.dart';
import '../../data/models/treatment.dart';
import '../../data/models/site.dart';
import '../../state/app_controller.dart';
import '../../widgets/site_card.dart';
import '../../widgets/site_map.dart';
import '../../widgets/status_badge.dart';
import '../site/site_detail_screen.dart';
import '../site/site_form_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key, this.phoneTab = 0});

  /// Used when the window is phone-width. 0 is the site list, 1 is the map.
  final int phoneTab;

  static const wideWidth = 720.0;

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= wideWidth;
    if (wide) return const _WideBoard();
    if (phoneTab == 0) return const _SiteList();
    final sites = context.watch<AppController>().priorityList;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      child: SiteMap(
        views: sites,
        expand: true,
        onOpen: (view) => _openSite(context, view.site.id),
      ),
    );
  }
}

class _WideBoard extends StatelessWidget {
  const _WideBoard();

  @override
  Widget build(BuildContext context) {
    final sites = context.watch<AppController>().priorityList;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Expanded(flex: 5, child: _SiteList()),
        const VerticalDivider(width: 1),
        Expanded(
          flex: 6,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            child: SiteMap(
              views: sites,
              expand: true,
              onOpen: (view) => _openSite(context, view.site.id),
            ),
          ),
        ),
      ],
    );
  }
}

void _openSite(BuildContext context, String siteId) {
  Navigator.of(context).push(
    MaterialPageRoute<void>(builder: (_) => SiteDetailScreen(siteId: siteId)),
  );
}

class _SiteList extends StatelessWidget {
  const _SiteList();

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<AppController>();
    final sites = controller.priorityList;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
      children: [
        if (controller.canReview && controller.pendingReviews.isNotEmpty) ...[
          const SizedBox(height: 20),
          const Text('Waiting for approval', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
          const SizedBox(height: 10),
          for (final site in controller.pendingReviews) _ReviewCard(site: site),
        ],
        if (controller.drafts.isNotEmpty) ...[
          const SizedBox(height: 16),
          for (final draft in controller.drafts)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Material(
                color: panel,
                borderRadius: BorderRadius.circular(12),
                child: ListTile(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  title: Text(
                    WeedSpecies.byKey(draft.speciesKey)?.name ?? 'Unfinished site',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: const Text('Draft on this phone', style: TextStyle(color: muted)),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(builder: (_) => SiteFormScreen(siteId: draft.id)),
                    );
                  },
                ),
              ),
            ),
        ],
        const SizedBox(height: 8),
        _Group(
          title: 'Critical',
          detail: 'Return is overdue',
          views: sites.where((view) => bandFor(view, DateTime.now().toUtc()) == PriorityBand.overdue).toList(),
          all: sites,
          sharingReady: controller.sharingReady,
        ),
        _Group(
          title: 'Pending treatment',
          detail: 'No spray on record',
          views: sites.where((view) => bandFor(view, DateTime.now().toUtc()) == PriorityBand.untreated).toList(),
          all: sites,
          sharingReady: controller.sharingReady,
        ),
        _Group(
          title: 'Controlled',
          detail: 'Sprayed, re-check still ahead',
          views: sites.where((view) => bandFor(view, DateTime.now().toUtc()) == PriorityBand.scheduled).toList(),
          all: sites,
          sharingReady: controller.sharingReady,
        ),
      ],
    );
  }
}

class _Group extends StatelessWidget {
  const _Group({
    required this.title,
    required this.detail,
    required this.views,
    required this.all,
    required this.sharingReady,
  });

  final String title;
  final String detail;
  final List<SiteView> views;
  final List<SiteView> all;
  final bool sharingReady;

  @override
  Widget build(BuildContext context) {
    if (views.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        const SizedBox(height: 2),
        Text(detail, style: const TextStyle(color: muted, fontSize: 12)),
        const SizedBox(height: 10),
        for (final view in views)
          SiteCard(
            view: view,
            rank: all.indexOf(view) + 1,
            sharingReady: sharingReady,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => SiteDetailScreen(siteId: view.site.id),
                ),
              );
            },
            onNavigate: () {
              final site = view.site;
              openSiteDirections(
                context,
                latitude: site.latitude!,
                longitude: site.longitude!,
                label: WeedSpecies.byKey(site.speciesKey)?.name ?? 'Weed site',
              );
            },
          ),
      ],
    );
  }
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({required this.site});

  final Site site;

  @override
  Widget build(BuildContext context) {
    final controller = context.read<AppController>();
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: panel,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => SiteDetailScreen(siteId: site.id)),
          );
        },
        child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              WeedSpecies.byKey(site.speciesKey)?.name ?? 'Unspecified',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            const StatusBadge(label: 'Waiting for review', tone: BadgeTone.pending),
            const SizedBox(height: 8),
            Text(formatPoint(site.latitude, site.longitude), style: const TextStyle(color: muted, fontSize: 12)),
            if (site.notes.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(site.notes, style: const TextStyle(color: muted, fontSize: 12)),
              ),
            Row(
              children: [
                TextButton(
                  onPressed: () => controller.decideReview(site.id, approve: true),
                  child: const Text('Approve'),
                ),
                TextButton(
                  onPressed: () => controller.decideReview(site.id, approve: false),
                  child: const Text('Reject'),
                ),
              ],
            ),
          ],
        ),
      ),
      ),
      ),
    );
  }
}
