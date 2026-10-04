import 'dart:convert';

import 'package:crypto/crypto.dart';

import 'role.dart';

class LocalAccount {
  const LocalAccount({
    required this.email,
    required this.passwordHash,
    required this.role,
    required this.displayName,
  });

  final String email;
  final String passwordHash;
  final AppRole role;
  final String displayName;
}

String localPasswordHash(String email, String password) {
  final material = utf8.encode('citp-ranger|${email.trim().toLowerCase()}|$password');
  return sha256.convert(material).toString();
}

const demoLocalAccounts = <({String email, String password, AppRole role, String name})>[
  (email: 'admin@lamalama.test', password: 'Admin1234', role: AppRole.admin, name: 'Admin'),
  (email: 'ranger@lamalama.test', password: 'Ranger1234', role: AppRole.ranger, name: 'Ranger'),
];
