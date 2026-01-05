import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import '../models/user_model.dart';

class AuthService {
  final SupabaseClient _supabase = SupabaseConfig.client;

  User? get currentUser => _supabase.auth.currentUser;
  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;

  Future<AuthResponse> signIn(String email, String password) async {
    return await _supabase.auth.signInWithPassword(email: email, password: password);
  }

  Future<AuthResponse> signUp(String email, String password, String fullName) async {
    final response = await _supabase.auth.signUp(
      email: email,
      password: password,
      data: {'full_name': fullName},
    );
    final user = response.user;
    if (user != null) {
      try {
        await _createUserInSupabase(user, fullName);
      } catch (_) {
        // Puede fallar si no hay sesion (email por confirmar); se creara al ingresar.
      }
    }
    return response;
  }

  Future<void> _createUserInSupabase(User supabaseUser, String fullName) async {
    final cvu = await _generateUniqueCVU();

    final userData = {
      'firebase_uid': supabaseUser.id,
      'email': supabaseUser.email,
      'full_name': fullName,
      'cvu': cvu,
    };

    final response = await SupabaseConfig.client.from('users').insert(userData).select().single();

    final userId = response['id'];

    await SupabaseConfig.client.from('wallets').insert([
      {'user_id': userId, 'currency': 'ARS', 'balance': 0.00},
      {'user_id': userId, 'currency': 'USD', 'balance': 0.00},
    ]);
  }

  Future<String> _generateUniqueCVU() async {
    String cvu;
    bool exists = true;
    int attempts = 0;
    const maxAttempts = 10;

    do {
      final random = DateTime.now().millisecondsSinceEpoch.toString();
      final randomSuffix = (attempts * 1000).toString().padLeft(4, '0');
      cvu = '0000003100${random.substring(random.length - 7).padLeft(7, '0')}$randomSuffix';

      final existing = await SupabaseConfig.client
          .from('users')
          .select('id')
          .eq('cvu', cvu)
          .maybeSingle();

      exists = existing != null;
      attempts++;
    } while (exists && attempts < maxAttempts);

    if (exists) {
      throw Exception('No se pudo generar un CVU unico');
    }

    return cvu;
  }

  Future<UserModel?> getCurrentUserData() async {
    if (currentUser == null) return null;

    var response = await SupabaseConfig.client
        .from('users')
        .select()
        .eq('firebase_uid', currentUser!.id)
        .maybeSingle();

    if (response == null) {
      // Si no existe el registro (pudo fallar en signUp), intentamos crearlo ahora.
      final meta = currentUser!.userMetadata ?? {};
      final fullName = meta['full_name'] ?? currentUser!.email ?? 'Usuario';
      try {
        await _createUserInSupabase(currentUser!, fullName);
        response = await SupabaseConfig.client
            .from('users')
            .select()
            .eq('firebase_uid', currentUser!.id)
            .maybeSingle();
      } catch (_) {
        return null;
      }
    }

    if (response == null) return null;
    return UserModel.fromJson(response);
  }

  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  Future<void> resetPassword(String email) async {
    await _supabase.auth.resetPasswordForEmail(email);
  }
}
