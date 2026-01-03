import 'package:firebase_auth/firebase_auth.dart';
import '../config/supabase_config.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  User? get currentUser => _firebaseAuth.currentUser;
  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  Future<UserCredential> signIn(String email, String password) async {
    return await _firebaseAuth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<UserCredential> signUp(String email, String password, String fullName) async {
    final credential = await _firebaseAuth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    await _createUserInSupabase(credential.user!, fullName);

    return credential;
  }

  Future<void> _createUserInSupabase(User firebaseUser, String fullName) async {
    final cvu = _generateCVU();

    final userData = {
      'firebase_uid': firebaseUser.uid,
      'email': firebaseUser.email,
      'full_name': fullName,
      'cvu': cvu,
    };

    final response = await SupabaseConfig.client
        .from('users')
        .insert(userData)
        .select()
        .single();

    final userId = response['id'];

    await SupabaseConfig.client.from('wallets').insert([
      {'user_id': userId, 'currency': 'ARS', 'balance': 0.00},
      {'user_id': userId, 'currency': 'USD', 'balance': 0.00},
    ]);
  }

  String _generateCVU() {
    final random = DateTime.now().millisecondsSinceEpoch.toString();
    return '0000003100${random.substring(random.length - 11).padLeft(11, '0')}';
  }

  Future<UserModel?> getCurrentUserData() async {
    if (currentUser == null) return null;

    final response = await SupabaseConfig.client
        .from('users')
        .select()
        .eq('firebase_uid', currentUser!.uid)
        .single();

    return UserModel.fromJson(response);
  }

  Future<void> signOut() async {
    await _firebaseAuth.signOut();
  }

  Future<void> resetPassword(String email) async {
    await _firebaseAuth.sendPasswordResetEmail(email: email);
  }
}
