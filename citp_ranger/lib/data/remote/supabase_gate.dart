import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/supabase_config.dart';

class SupabaseGate {
  static bool ready = false;

  static Future<void> tryInit() async {
    if (!SupabaseConfig.enabled) {
      ready = false;
      return;
    }
    try {
      if (!ready) {
        await Supabase.initialize(
          url: SupabaseConfig.url,
          publishableKey: SupabaseConfig.anonKey,
        );
      }
      ready = true;
    } catch (_) {
      try {
        Supabase.instance.client;
        ready = true;
      } catch (_) {
        ready = false;
      }
    }
  }
}
