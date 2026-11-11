import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../utils/logger.dart';

class EnvConfig {
  static const String _defaultApiBaseUrl = 'https://interconnect-burundi.onrender.com';
  static const String _defaultWsUrl = 'wss://full-shoes-boil.loca.lt';
  static const String _defaultLivekitUrl = 'wss://interconnect-burundi-c8nah4fz.livekit.cloud';
  static const String _defaultSupabaseUrl = 'https://sdzzzikdophekbzuzdwx.supabase.co';
  static const String _defaultSupabaseAnonKey = 'sb_publishable_eM1CQLSwbQIuApMVP66y4w_Tc49caef';

  static String get apiBaseUrl =>
      (dotenv.env['API_BASE_URL']?.isNotEmpty ?? false)
          ? dotenv.env['API_BASE_URL']!
          : _defaultApiBaseUrl;

  static String get wsUrl =>
      (dotenv.env['WS_URL']?.isNotEmpty ?? false)
          ? dotenv.env['WS_URL']!
          : _defaultWsUrl;

  static String get livekitUrl =>
      (dotenv.env['LIVEKIT_URL']?.isNotEmpty ?? false)
          ? dotenv.env['LIVEKIT_URL']!
          : _defaultLivekitUrl;

  static String get supabaseUrl =>
      (dotenv.env['SUPABASE_URL']?.isNotEmpty ?? false)
          ? dotenv.env['SUPABASE_URL']!
          : _defaultSupabaseUrl;

  static String get supabaseAnonKey =>
      (dotenv.env['SUPABASE_ANON_KEY']?.isNotEmpty ?? false)
          ? dotenv.env['SUPABASE_ANON_KEY']!
          : _defaultSupabaseAnonKey;

  static void validate() {
    final required = [
      'API_BASE_URL',
      'WS_URL',
      'LIVEKIT_URL',
      'SUPABASE_URL',
      'SUPABASE_ANON_KEY',
    ];
    for (final key in required) {
      if (dotenv.env[key] == null || dotenv.env[key]!.isEmpty) {
        AppLogger.w('Variable d\'environnement absente ou vide dans .env: $key (utilisation du fallback)');
      }
    }
  }
}
