import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../state/app_controller.dart';

class GateScreen extends StatefulWidget {
  const GateScreen({super.key});

  @override
  State<GateScreen> createState() => _GateScreenState();
}

class _GateScreenState extends State<GateScreen> {
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          children: [
            const Text('Lama Lama', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            const Text(
              'Sign in once. This phone keeps that sign-in, so a lost connection does not lock you out.',
              style: TextStyle(color: muted),
            ),
            const SizedBox(height: 28),
            TextField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              autocorrect: false,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _password,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Password'),
              onSubmitted: (_) => _signIn(),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: const TextStyle(color: ink)),
            ],
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _busy ? null : _signIn,
              child: const Text('Sign in'),
            ),
            const SizedBox(height: 8),
            const Text(
              'Admin  admin@lamalama.test  /  Admin1234\nRanger  ranger@lamalama.test  /  Ranger1234',
              style: TextStyle(color: muted, fontSize: 12, height: 1.5),
            ),
            const SizedBox(height: 28),
            const Divider(),
            const SizedBox(height: 20),
            const Text('No account', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            const Text(
              'Report a weed without signing in. It is reviewed before it is listed.',
              style: TextStyle(color: muted),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: _busy ? null : _public,
              child: const Text('Report a weed'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _signIn() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    final error = await context.read<AppController>().signIn(_email.text, _password.text);
    if (!mounted) return;
    setState(() {
      _busy = false;
      _error = error;
    });
  }

  Future<void> _public() async {
    await context.read<AppController>().continueAsPublic('');
  }
}
