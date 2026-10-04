import 'package:flutter/material.dart';

import '../core/format.dart';
import '../core/priority.dart';
import '../core/species.dart';
import '../core/theme.dart';
import '../data/models/treatment.dart';
import 'status_badge.dart';

class SiteCard extends StatelessWidget {
  const SiteCard({
    super.key,
    required this.view,
    required this.rank,
    required this.sharingReady,
    required this.onTap,
    required this.onNavigate,
  });

  final SiteView view;
  final int rank;
  final bool sharingReady;
  final VoidCallback onTap;
  final VoidCallback onNavigate;

  @override
  Widget build(BuildContext context) {
    final site = view.site;
    final species = WeedSpecies.byKey(site.speciesKey);
    final now = DateTime.now();
    final band = bandFor(view, now.toUtc());
    final (label, tone) = switch (band) {
      PriorityBand.overdue => (followUpLabel(view.treatment!.nextCheckDue, now), BadgeTone.overdue),
      PriorityBand.untreated => ('No spray on record', BadgeTone.pending),
      PriorityBand.scheduled => (followUpLabel(view.treatment!.nextCheckDue, now), BadgeTone.clear),
    };
    final sprayed = view.treatment == null ? 'No treatment' : 'Sprayed ${formatDate(view.treatment!.treatedAt)}';
    final share = site.syncedAt == null
        ? 'Pending sync'
        : sharingReady
        ? 'Shared with camp'
        : 'On this phone';

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: panel,
        elevation: 3,
        shadowColor: Colors.black,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        species?.name ?? 'Unspecified',
                        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                      ),
                    ),
                    Text(
                      rank.toString().padLeft(2, '0'),
                      style: const TextStyle(
                        color: muted,
                        fontSize: 12,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                StatusBadge(label: label, tone: tone),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: raised,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.place_outlined, size: 16, color: muted),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _coordinates(site.latitude, site.longitude),
                          style: const TextStyle(
                            color: ink,
                            fontSize: 12,
                            fontFeatures: [FontFeature.tabularFigures()],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Logged by ${site.rangerName}  ·  ${formatDateTime(site.createdAt)}',
                  style: const TextStyle(color: muted, fontSize: 12),
                ),
                const SizedBox(height: 2),
                Text(
                  '$sprayed  ·  $share',
                  style: const TextStyle(color: muted, fontSize: 12),
                ),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerLeft,
                  child: OutlinedButton.icon(
                    onPressed: site.hasLocation ? onNavigate : null,
                    icon: const Icon(Icons.navigation_outlined, size: 16),
                    label: const Text('Navigate'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

String _coordinates(double? latitude, double? longitude) {
  if (latitude == null || longitude == null) return 'No GPS fix';
  final lat = '${latitude.abs().toStringAsFixed(5)}° ${latitude < 0 ? 'S' : 'N'}';
  final lng = '${longitude.abs().toStringAsFixed(5)}° ${longitude < 0 ? 'W' : 'E'}';
  return '$lat    $lng';
}
