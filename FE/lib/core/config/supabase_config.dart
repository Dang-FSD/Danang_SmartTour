import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'env_config.dart';

class SupabaseConfig {
  static bool _isInitialized = false;

  static bool get isInitialized => _isInitialized;

  static SupabaseClient? get client {
    if (!_isInitialized) return null;
    return Supabase.instance.client;
  }

  static Future<void> initialize() async {
    if (!EnvConfig.hasSupabaseConfig) {
      debugPrint('[Supabase] Missing or default Supabase URL/Key. Running in Local Offline Mode.');
      _isInitialized = false;
      return;
    }

    try {
      await Supabase.initialize(
        url: EnvConfig.supabaseUrl,
        anonKey: EnvConfig.supabaseAnonKey,
      );
      _isInitialized = true;
      debugPrint('[Supabase] Connected successfully to ${EnvConfig.supabaseUrl}');
    } catch (e) {
      debugPrint('[Supabase] Connection error: $e. Falling back to Local Mode.');
      _isInitialized = false;
    }
  }
}
