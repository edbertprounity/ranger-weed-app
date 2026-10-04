import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/role.dart';
import '../../core/theme.dart';
import '../../state/app_controller.dart';

class CreateAccountScreen extends StatefulWidget {
  const CreateAccountScreen({super.key});

  @override
  State<CreateAccountScreen> createState() => _CreateAccountScreenState();
}

class _CreateAccountScreenState extends State<CreateAccountScreen> {
  final TextEditingController _name = TextEditingController();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();
  final TextEditingController _confirm = TextEditingController();
  final TextEditingController _adminEmail = TextEditingController();
  final TextEditingController _adminPassword = TextEditingController();
  AppRole _role = AppRole.ranger;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final email = context.read<AppController>().signedInEmail;
    if (email != null) _adminEmail.text = email;
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    _adminEmail.dispose();
    _adminPassword.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final knownAdmin = context.watch<AppController>().signedInEmail;
    return Scaffold(
      appBar: AppBar(title: const Text('Add ranger')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Create a sign-in for a ranger or another admin. It is kept on this phone, and sent to the shared database when you confirm with your admin password.',
            style: TextStyle(color: muted, height: 1.4),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _name,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(labelText: 'Name'),
          ),
          const SizedBox(height: 12),
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
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _confirm,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'Confirm password'),
          ),
          const SizedBox(height: 16),
          const Text('Role', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              ChoiceChip(
                label: const Text('Ranger'),
                selected: _role == AppRole.ranger,
                onSelected: (_) => setState(() => _role = AppRole.ranger),
              ),
              ChoiceChip(
                label: const Text('Admin'),
                selected: _role == AppRole.admin,
                onSelected: (_) => setState(() => _role = AppRole.admin),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Text('Confirm you are the admin', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          if (knownAdmin == null) ...[
            TextField(
              controller: _adminEmail,
              keyboardType: TextInputType.emailAddress,
              autocorrect: false,
              decoration: const InputDecoration(labelText: 'Your admin email'),
            ),
            const SizedBox(height: 12),
          ],
          TextField(
            controller: _adminPassword,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'Your password'),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: const TextStyle(color: overdueInk)),
          ],
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _busy ? null : _submit,
            child: Text(_busy ? 'Saving...' : 'Create account'),
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    if (_password.text != _confirm.text) {
      setState(() => _error = 'The two passwords do not match.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final message = await context.read<AppController>().createAccount(
      adminEmail: _adminEmail.text,
      adminPassword: _adminPassword.text,
      email: _email.text,
      password: _password.text,
      displayName: _name.text,
      accountRole: _role,
    );
    if (!mounted) return;
    setState(() => _busy = false);
    if (message != null && !message.startsWith('Saved on this phone')) {
      setState(() => _error = message);
      return;
    }
    if (message != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    }
    Navigator.of(context).pop();
  }
}
