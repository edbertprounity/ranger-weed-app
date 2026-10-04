import 'package:flutter/material.dart';

import 'app.dart';
import 'data/local/database_factory.dart';
import 'data/remote/supabase_gate.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initDatabaseFactory();
  await SupabaseGate.tryInit();
  runApp(const RangerApp());
}
