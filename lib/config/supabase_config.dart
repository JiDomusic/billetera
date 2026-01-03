import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  static const String supabaseUrl = 'https://owmoqzbwcgvmobgljxvg.supabase.co';
  static const String supabaseAnonKey = 'sb_publishable_Mlz2P60m1rQw2MKmpBMHMQ_I-XM8n4W';

  static SupabaseClient get client => Supabase.instance.client;

  static Future<void> initialize() async {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
    );
  }
}
