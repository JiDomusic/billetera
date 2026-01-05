import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  // Valores inyectados en tiempo de compilacion con --dart-define
  static const String _supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const String _supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  static SupabaseClient get client => Supabase.instance.client;
  static const String _firebaseUidHeader = 'x-firebase-uid';

  static Future<void> initialize() async {
    final url = _requireEnv(_supabaseUrl, 'SUPABASE_URL');
    final anonKey = _requireEnv(_supabaseAnonKey, 'SUPABASE_ANON_KEY');

    await Supabase.initialize(
      url: url,
      anonKey: anonKey,
    );
  }

  /// Adjunta el UID de Firebase en cada request para que las politicas RLS lo lean.
  static void setAuthHeaders(String firebaseUid) {
    client.rest.headers[_firebaseUidHeader] = firebaseUid;
  }

  /// Limpia el header cuando se cierra sesion.
  static void clearAuthHeaders() {
    client.rest.headers.remove(_firebaseUidHeader);
  }

  static String _requireEnv(String value, String name) {
    if (value.isEmpty) {
      throw ArgumentError('$name no esta definido. Pasalo con --dart-define.');
    }
    return value;
  }
}
