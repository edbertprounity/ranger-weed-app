import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/format.dart';
import '../../core/species.dart';
import '../../core/theme.dart';
import '../../data/models/site.dart';
import '../../state/app_controller.dart';
import '../../widgets/status_badge.dart';
import '../site/site_form_screen.dart';

class PublicReportScreen extends StatelessWidget {
  const PublicReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<AppController>();
    final sent = controller.ownPublicReports;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
      children: [
        const Text(
          'Send a weed report. It stays off the ranger list until an admin approves it.',
          style: TextStyle(color: muted, height: 1.4),
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const SiteFormScreen()),
            );
          },
          icon: const Icon(Icons.add),
          label: const Text('Report a weed'),
        ),
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
                    WeedSpecies.byKey(draft.speciesKey)?.name ?? 'Unfinished report',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: const Text('Draft on this phone', style: TextStyle(color: muted)),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(builder: (_) => SiteFormScreen(siteId: draft.id)),
                    );
                  },
                ),
              ),
            ),
        ],
        if (sent.isNotEmpty) ...[
          const SizedBox(height: 20),
          const Text('Your reports', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          for (final site in sent) _SentCard(site: site),
        ],
      ],
    );
  }
}

class _SentCard extends StatelessWidget {
  const _SentCard({required this.site});

  final Site site;

  @override
  Widget build(BuildContext context) {
    final (label, tone) = switch (site.status) {
      SiteStatus.pending => ('Waiting for review', BadgeTone.pending),
      SiteStatus.open => ('Accepted', BadgeTone.clear),
      SiteStatus.rejected => ('Not listed', BadgeTone.overdue),
      SiteStatus.draft => ('Draft', BadgeTone.pending),
    };
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: panel, borderRadius: BorderRadius.circular(12)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              WeedSpecies.byKey(site.speciesKey)?.name ?? 'Unspecified',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            StatusBadge(label: label, tone: tone),
            const SizedBox(height: 8),
            Text('Sent ${formatDate(site.updatedAt)}', style: const TextStyle(color: muted, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
