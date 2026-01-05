import 'package:firebase_auth/firebase_auth.dart' as firebase;
import '../config/supabase_config.dart';

class AdminService {
  final firebase.FirebaseAuth _firebaseAuth = firebase.FirebaseAuth.instance;

  firebase.User? get currentAdmin => _firebaseAuth.currentUser;
  Stream<firebase.User?> get adminAuthChanges => _firebaseAuth.authStateChanges();

  Future<firebase.UserCredential> signIn(String email, String password) async {
    return await _firebaseAuth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<void> signOut() async {
    await _firebaseAuth.signOut();
  }

  // Obtener todos los usuarios
  Future<List<Map<String, dynamic>>> getAllUsers() async {
    final response = await SupabaseConfig.client
        .from('users')
        .select()
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  // Obtener solicitudes de depósito pendientes
  Future<List<Map<String, dynamic>>> getPendingDeposits() async {
    final response = await SupabaseConfig.client
        .from('deposit_requests')
        .select('*, users(full_name, email)')
        .eq('status', 'pending')
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  // Aprobar depósito
  Future<void> approveDeposit(String depositId, String userId, double amount, String currency) async {
    // Actualizar solicitud
    await SupabaseConfig.client.from('deposit_requests').update({
      'status': 'approved',
      'processed_at': DateTime.now().toIso8601String(),
    }).eq('id', depositId);

    // Obtener wallet del usuario
    final wallet = await SupabaseConfig.client
        .from('wallets')
        .select()
        .eq('user_id', userId)
        .eq('currency', currency)
        .single();

    // Sumar saldo
    final newBalance = (wallet['balance'] as num).toDouble() + amount;
    await SupabaseConfig.client.from('wallets').update({
      'balance': newBalance,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', wallet['id']);

    // Registrar transacción
    await SupabaseConfig.client.from('transactions').insert({
      'to_wallet_id': wallet['id'],
      'type': 'deposit',
      'amount': amount,
      'currency': currency,
      'description': 'Deposito aprobado por admin',
      'status': 'completed',
    });
  }

  // Rechazar depósito
  Future<void> rejectDeposit(String depositId, String? reason) async {
    await SupabaseConfig.client.from('deposit_requests').update({
      'status': 'rejected',
      'admin_notes': reason,
      'processed_at': DateTime.now().toIso8601String(),
    }).eq('id', depositId);
  }

  // Obtener cotización actual
  Future<Map<String, dynamic>?> getExchangeRate() async {
    final response = await SupabaseConfig.client
        .from('exchange_rates')
        .select()
        .order('updated_at', ascending: false)
        .limit(1)
        .maybeSingle();
    return response;
  }

  // Actualizar cotización
  Future<void> updateExchangeRate(double buyRate, double sellRate) async {
    await SupabaseConfig.client.from('exchange_rates').insert({
      'buy_rate': buyRate,
      'sell_rate': sellRate,
    });
  }

  // Agregar saldo manualmente a un usuario
  Future<void> addBalance(String userId, double amount, String currency) async {
    final wallet = await SupabaseConfig.client
        .from('wallets')
        .select()
        .eq('user_id', userId)
        .eq('currency', currency)
        .single();

    final newBalance = (wallet['balance'] as num).toDouble() + amount;
    await SupabaseConfig.client.from('wallets').update({
      'balance': newBalance,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', wallet['id']);

    await SupabaseConfig.client.from('transactions').insert({
      'to_wallet_id': wallet['id'],
      'type': 'deposit',
      'amount': amount,
      'currency': currency,
      'description': 'Carga manual por admin',
      'status': 'completed',
    });
  }

  // Obtener solicitudes de retiro pendientes
  Future<List<Map<String, dynamic>>> getPendingWithdrawals() async {
    final response = await SupabaseConfig.client
        .from('withdrawal_requests')
        .select('*, users(full_name, email)')
        .eq('status', 'pending')
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  // Aprobar retiro
  Future<void> approveWithdrawal(String withdrawalId, String userId, double amount, String currency) async {
    // Obtener wallet del usuario
    final wallet = await SupabaseConfig.client
        .from('wallets')
        .select()
        .eq('user_id', userId)
        .eq('currency', currency)
        .single();

    final currentBalance = (wallet['balance'] as num).toDouble();
    if (currentBalance < amount) {
      throw Exception('Saldo insuficiente en la billetera del usuario');
    }

    // Actualizar solicitud
    await SupabaseConfig.client.from('withdrawal_requests').update({
      'status': 'approved',
      'processed_at': DateTime.now().toIso8601String(),
    }).eq('id', withdrawalId);

    // Restar saldo
    final newBalance = currentBalance - amount;
    await SupabaseConfig.client.from('wallets').update({
      'balance': newBalance,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', wallet['id']);

    // Registrar transaccion
    await SupabaseConfig.client.from('transactions').insert({
      'from_wallet_id': wallet['id'],
      'type': 'withdraw',
      'amount': amount,
      'currency': currency,
      'description': 'Retiro aprobado por admin',
      'status': 'completed',
    });
  }

  // Rechazar retiro
  Future<void> rejectWithdrawal(String withdrawalId, String? reason) async {
    await SupabaseConfig.client.from('withdrawal_requests').update({
      'status': 'rejected',
      'admin_notes': reason,
      'processed_at': DateTime.now().toIso8601String(),
    }).eq('id', withdrawalId);
  }
}
