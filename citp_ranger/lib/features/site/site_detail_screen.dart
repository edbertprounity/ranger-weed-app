import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/format.dart';
import '../../core/navigation.dart';
import '../../core/priority.dart';
import '../../core/species.dart';
import '../../core/theme.dart';
import '../../data/local/photo_store.dart';
import '../../data/models/site.dart';
import '../../data/models/treatment.dart';
import '../../state/app_controller.dart';
import '../../widgets/app_logo.dart';
import '../../widgets/site_map.dart';
import '../../widgets/site_photo.dart';
import '../../widgets/status_badge.dart';
import '../treatment/treatment_screen.dart';

class SiteDetailScreen extends StatelessWidget {
  const SiteDetailScreen({super.key, required this.siteId});

  final String siteId;

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<AppController>();
    final site = controller.siteById(siteId);
    if (site == null) {
      return const Scaffold(body: Center(child: Text('This site is no longer on the phone.')));
    }
    final species = WeedSpecies.byKey(site.speciesKey);
    final history = controller.treatmentsFor(siteId);
    final latest = controller.latestTreatment(siteId);
    final view = SiteView(site: site, treatment: latest);
    final now = DateTime.now();
    final band = site.status == SiteStatus.open ? bandFor(view, now.toUtc()) : null;
    final (badge, tone) = switch (site.status) {
      SiteStatus.pending => ('Waiting for review', BadgeTone.pending),
      SiteStatus.rejected => ('Not listed', BadgeTone.overdue),
      SiteStatus.draft => ('Draft', BadgeTone.pending),
      SiteStatus.open => switch (band!) {
        PriorityBand.overdue => (followUpLabel(latest!.nextCheckDue, now), BadgeTone.overdue),
        PriorityBand.untreated => ('No spray on record', BadgeTone.pending),
        PriorityBand.scheduled => (followUpLabel(latest!.nextCheckDue, now), BadgeTone.clear),
      },
    };
    return Scaffold(
      appBar: AppBar(title: BrandTitle(species?.name ?? 'Weed site')),
      bottomNavigationBar: _ActionPanel(site: site),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          Text(
            species?.name ?? 'Unspecified',
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
          ),
          if (species != null) ...[
            const SizedBox(height: 2),
            Text(species.scientific, style: const TextStyle(color: muted, fontStyle: FontStyle.italic)),
          ],
          const SizedBox(height: 10),
          StatusBadge(label: badge, tone: tone),
          if (species != null) ...[
            const SizedBox(height: 12),
            Text(species.identification, style: const TextStyle(height: 1.4)),
          ],
          const SizedBox(height: 16),
          SitePhoto(site: site, height: 180),
          const SizedBox(height: 16),
          _Block(
            title: 'Location',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(formatPoint(site.latitude, site.longitude)),
                if (site.hasLocation) ...[
                  const SizedBox(height: 12),
                  SiteMap(views: [view], onOpen: (_) {}),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),
          _Block(
            title: 'Log',
            child: Text(
              'Logged by ${site.rangerName}\n${formatDateTime(site.createdAt)}'
              '${site.notes.isEmpty ? '' : '\n\n${site.notes}'}',
              style: const TextStyle(height: 1.4),
            ),
          ),
          const SizedBox(height: 12),
          _Block(
            title: 'Treatment',
            child: history.isEmpty
                ? const Text('No spray on record.')
                : Column(
                    children: [
                      for (final treatment in history)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: raised,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  [
                                    'Sprayed ${formatDateTime(treatment.treatedAt)} by ${treatment.rangerName}',
                                    if (treatment.notes.isNotEmpty) treatment.notes,
                                    'Re-check ${formatDate(treatment.nextCheckDue)}',
                                  ].join('\n'),
                                  style: const TextStyle(height: 1.4),
                                ),
                                if (treatment.photoPath != null &&
                                    File(resolvePhotoPath(treatment.photoPath!)).existsSync()) ...[
                                  const SizedBox(height: 8),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.file(
                                      File(resolvePhotoPath(treatment.photoPath!)),
                                      height: 140,
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _Block extends StatelessWidget {
  const _Block({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: panel, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

class _ActionPanel extends StatelessWidget {
  const _ActionPanel({required this.site});

  final Site site;

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<AppController>();
    final canTreat = controller.canRecordTreatment && site.status == SiteStatus.open;
    final canApprove = controller.canReview && site.status == SiteStatus.pending;
    final name = WeedSpecies.byKey(site.speciesKey)?.name ?? 'Weed site';
    return Material(
      color: raised,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (site.hasLocation)
                OutlinedButton.icon(
                  onPressed: () => openSiteDirections(
                    context,
                    latitude: site.latitude!,
                    longitude: site.longitude!,
                    label: name,
                  ),
                  icon: const Icon(Icons.navigation_outlined),
                  label: const Text('Navigate'),
                ),
              if (canTreat) ...[
                const SizedBox(height: 8),
                FilledButton.icon(
                  onPressed: () => _openTreatment(context),
                  icon: const Icon(Icons.water_drop_outlined),
                  label: const Text('Update status'),
                ),
              ],
              if (canApprove) ...[
                const SizedBox(height: 8),
                FilledButton(
                  onPressed: () => controller.decideReview(site.id, approve: true),
                  child: const Text('Approve'),
                ),
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: () => controller.decideReview(site.id, approve: false),
                  child: const Text('Reject'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _openTreatment(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => TreatmentScreen(siteId: site.id)),
    );
  }
}
