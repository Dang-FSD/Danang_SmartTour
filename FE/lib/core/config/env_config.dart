import 'package:flutter_dotenv/flutter_dotenv.dart';

class EnvConfig {
  static Future<void> init() async {
    try {
      await dotenv.load(fileName: '.env');
    } catch (e) {
      // Fallback if .env is missing or packaged differently
    }
  }

  static String get vokeApiKey =>
      dotenv.env['VOKE_API_KEY'] ??
      const String.fromEnvironment('VOKE_API_KEY', defaultValue: '');

  static String get vokeBaseUrl =>
      dotenv.env['VOKE_BASE_URL'] ??
      const String.fromEnvironment('VOKE_BASE_URL',
          defaultValue: 'https://api.vokeapi.com/v1');

  static String get vokeModel =>
      dotenv.env['VOKE_MODEL'] ??
      const String.fromEnvironment('VOKE_MODEL', defaultValue: 'deepseek-v4-pro');

  static String get supabaseUrl =>
      dotenv.env['SUPABASE_URL'] ??
      const String.fromEnvironment('SUPABASE_URL', defaultValue: '');

  static String get supabaseAnonKey =>
      dotenv.env['SUPABASE_ANON_KEY'] ??
      const String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: '');

  static bool get hasSupabaseConfig =>
      supabaseUrl.isNotEmpty &&
      supabaseAnonKey.isNotEmpty &&
      !supabaseUrl.contains('your-project');
}
