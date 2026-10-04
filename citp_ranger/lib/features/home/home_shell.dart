import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/role.dart';
import '../../core/theme.dart';
import '../../state/app_controller.dart';
import '../../widgets/sync_status_pill.dart';
import '../dashboard/dashboard_screen.dart';
import '../public/public_report_screen.dart';
import '../site/site_form_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> with WidgetsBindingObserver {
  int _phoneTab = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      context.read<AppController>().syncNow();
    }
  }

  void _logInfestation() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const SiteFormScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<AppController>();
    final isPublic = controller.role == AppRole.public;
    final wide = MediaQuery.sizeOf(context).width >= DashboardScreen.wideWidth;
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isPublic ? 'Report a weed' : 'Lama Lama',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            Text(
              isPublic ? 'Public' : roleLabel(controller.role!),
              style: const TextStyle(fontSize: 12, color: muted, fontWeight: FontWeight.w400),
            ),
          ],
        ),
        actions: [
          const SyncStatusPill(),
          const SizedBox(width: 4),
          IconButton(
            tooltip: 'Sign out',
            onPressed: controller.signOut,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      floatingActionButton: isPublic
          ? null
          : FloatingActionButton.extended(
              onPressed: _logInfestation,
              backgroundColor: accent,
              foregroundColor: ink,
              icon: const Icon(Icons.add_location_alt_outlined),
              label: const Text('Log infestation'),
            ),
      bottomNavigationBar: isPublic || wide
          ? null
          : NavigationBar(
              backgroundColor: paper,
              indicatorColor: const Color(0xFF243528),
              selectedIndex: _phoneTab,
              onDestinationSelected: (index) => setState(() => _phoneTab = index),
              destinations: const [
                NavigationDestination(icon: Icon(Icons.list_alt), label: 'Sites'),
                NavigationDestination(icon: Icon(Icons.map_outlined), label: 'Map'),
              ],
            ),
      body: Column(
        children: [
          if (controller.syncMessage != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(controller.syncMessage!, style: const TextStyle(color: muted, fontSize: 12)),
              ),
            ),
          Expanded(
            child: isPublic
                ? const PublicReportScreen()
                : DashboardScreen(phoneTab: _phoneTab),
          ),
        ],
      ),
    );
  }
}
