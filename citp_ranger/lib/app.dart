import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/theme.dart';
import 'features/auth/gate_screen.dart';
import 'features/home/home_shell.dart';
import 'state/app_controller.dart';

class RangerApp extends StatelessWidget {
  const RangerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppController()..start(),
      child: MaterialApp(
        title: 'Ranger App',
        theme: buildRangerTheme(),
        debugShowCheckedModeBanner: false,
        home: const RootScreen(),
      ),
    );
  }
}

class RootScreen extends StatelessWidget {
  const RootScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<AppController>();
    if (!controller.ready) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (controller.role == null) {
      return const GateScreen();
    }
    return const HomeShell();
  }
}
