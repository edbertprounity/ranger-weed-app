import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../state/app_controller.dart';

class RangerScreen extends StatefulWidget {
  const RangerScreen({super.key});

  @override
  State<RangerScreen> createState() => _RangerScreenState();
}

class _RangerScreenState extends State<RangerScreen> {
  final TextEditingController _name = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const SizedBox(height: 24),
            const Text(
              'FIELD LOG',
              style: TextStyle(color: muted, fontSize: 11, letterSpacing: 2.2),
            ),
            const SizedBox(height: 8),
            Text(
              'Lama Lama',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            const Text(
              'Sites stay on this phone if the battery dies. A name is stamped on every record you log.',
              style: TextStyle(color: muted),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _name,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Your name',
                hintText: 'Shown on every site you log',
              ),
              onSubmitted: (_) => _continue(),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _continue,
              child: const Text('Continue'),
            ),
            const SizedBox(height: 24),
            const Text(
              'Sample sites from Alex, Sam, and Jo are already on this phone so the list and map are ready to demo.',
              style: TextStyle(color: muted),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _continue() async {
    final name = _name.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a name to stamp on new records.')),
      );
      return;
    }
    await context.read<AppController>().setRangerName(name);
  }
}
