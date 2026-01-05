import '../config/supabase_config.dart';
import '../models/wallet_model.dart';
import '../models/transaction_model.dart';
import '../models/exchange_rate_model.dart';
import '../models/user_model.dart';

class WalletService {
  Future<List<WalletModel>> getWallets(String userId) async {
    final response = await SupabaseConfig.client
        .from('wallets')
        .select()
        .eq('user_id', userId);

    return (response as List)
        .map((json) => WalletModel.fromJson(json))
        .toList();
  }

  Future<WalletModel?> getWallet(String userId, String currency) async {
    final response = await SupabaseConfig.client
        .from('wallets')
        .select()
        .eq('user_id', userId)
        .eq('currency', currency)
        .single();

    return WalletModel.fromJson(response);
  }

  Future<ExchangeRateModel?> getExchangeRate() async {
    final response = await SupabaseConfig.client
        .from('exchange_rates')
        .select()
        .order('updated_at', ascending: false)
        .limit(1)
        .maybeSingle();

    if (response == null) return null;
    return ExchangeRateModel.fromJson(response);
  }

  Future<UserModel?> findUserByCVU(String cvu) async {
    final response = await SupabaseConfig.client
        .from('users')
        .select()
        .eq('cvu', cvu)
        .maybeSingle();

    if (response == null) return null;
    return UserModel.fromJson(response);
  }

  Future<UserModel?> findUserByEmail(String email) async {
    final response = await SupabaseConfig.client
        .from('users')
        .select()
        .eq('email', email)
        .maybeSingle();

    if (response == null) return null;
    return UserModel.fromJson(response);
  }

  Future<void> transfer({
    required String toIdentifier,
    required double amount,
    required String currency,
    String? description,
  }) async {
    final response = await SupabaseConfig.client.rpc('transfer_money', params: {
      'p_to_identifier': toIdentifier,
      'p_amount': amount,
      'p_currency': currency,
      'p_description': description ?? 'Transferencia',
    });

    final result = response as Map<String, dynamic>;
    if (result['success'] != true) {
      throw Exception(result['error'] ?? 'Error en la transferencia');
    }
  }

  Future<void> convert({
    required String userId,
    required double amount,
    required String fromCurrency,
    required String toCurrency,
  }) async {
    final exchangeRate = await getExchangeRate();
    if (exchangeRate == null) {
      throw Exception('Cotizacion no disponible');
    }

    final fromWallet = await getWallet(userId, fromCurrency);
    final toWallet = await getWallet(userId, toCurrency);

    if (fromWallet == null || toWallet == null) {
      throw Exception('Billetera no encontrada');
    }

    if (fromWallet.balance < amount) {
      throw Exception('Saldo insuficiente');
    }

    double convertedAmount;
    double rate;

    if (fromCurrency == 'ARS' && toCurrency == 'USD') {
      rate = exchangeRate.sellRate;
      convertedAmount = amount / rate;
    } else {
      rate = exchangeRate.buyRate;
      convertedAmount = amount * rate;
    }

    await SupabaseConfig.client.from('wallets').update({
      'balance': fromWallet.balance - amount,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', fromWallet.id);

    await SupabaseConfig.client.from('wallets').update({
      'balance': toWallet.balance + convertedAmount,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', toWallet.id);

    await SupabaseConfig.client.from('transactions').insert({
      'from_wallet_id': fromWallet.id,
      'to_wallet_id': toWallet.id,
      'type': 'convert',
      'amount': amount,
      'currency': fromCurrency,
      'exchange_rate': rate,
      'description': '$fromCurrency a $toCurrency',
      'status': 'completed',
    });
  }

  Future<List<TransactionModel>> getTransactions(String userId) async {
    final wallets = await getWallets(userId);
    final walletIds = wallets.map((w) => w.id).toList();

    if (walletIds.isEmpty) return [];

    final response = await SupabaseConfig.client
        .from('transactions')
        .select()
        .or('from_wallet_id.in.(${walletIds.join(",")}),to_wallet_id.in.(${walletIds.join(",")})')
        .order('created_at', ascending: false)
        .limit(50);

    return (response as List)
        .map((json) => TransactionModel.fromJson(json))
        .toList();
  }

  Future<void> requestDeposit({
    required String userId,
    required double amount,
    required String currency,
  }) async {
    await SupabaseConfig.client.from('deposit_requests').insert({
      'user_id': userId,
      'amount': amount,
      'currency': currency,
      'status': 'pending',
    });
  }
}
