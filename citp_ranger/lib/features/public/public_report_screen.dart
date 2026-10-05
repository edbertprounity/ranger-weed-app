import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../widgets/app_logo.dart';
import '../site/site_form_screen.dart';

class PublicReportScreen extends StatelessWidget {
  const PublicReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
      children: [
        const Row(
          children: [
            AppLogo(size: 64),
            SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Lama Lama', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                Text('Rangers', style: TextStyle(color: muted, fontSize: 13)),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
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
      ],
    );
  }
}
