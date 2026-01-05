import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/wallet_model.dart';
import '../models/transaction_model.dart';
import '../models/exchange_rate_model.dart';
import '../models/user_model.dart';
import '../services/wallet_service.dart';
import '../config/supabase_config.dart';

class WalletProvider extends ChangeNotifier {
  final WalletService _walletService = WalletService();

  List<WalletModel> _wallets = [];
  List<TransactionModel> _transactions = [];
  ExchangeRateModel? _exchangeRate;
  bool _isLoading = false;
  String? _error;
  RealtimeChannel? _exchangeRateChannel;

  List<WalletModel> get wallets => _wallets;
  List<TransactionModel> get transactions => _transactions;
  ExchangeRateModel? get exchangeRate => _exchangeRate;
  bool get isLoading => _isLoading;
  String? get error => _error;

  WalletModel? get arsWallet =>
      _wallets.where((w) => w.currency == 'ARS').firstOrNull;
  WalletModel? get usdWallet =>
      _wallets.where((w) => w.currency == 'USD').firstOrNull;

  Future<void> loadWallets(String userId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _wallets = await _walletService.getWallets(userId);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Error al cargar billeteras';
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadExchangeRate() async {
    try {
      _exchangeRate = await _walletService.getExchangeRate();
      _ensureExchangeRateSubscription();
      notifyListeners();
    } catch (e) {
      _error = 'Error al cargar cotizacion';
      notifyListeners();
    }
  }

  Future<void> loadTransactions(String userId) async {
    try {
      _transactions = await _walletService.getTransactions(userId);
      notifyListeners();
    } catch (e) {
      _error = 'Error al cargar transacciones';
      notifyListeners();
    }
  }

  Future<UserModel?> findUser(String query) async {
    if (query.contains('@')) {
      return await _walletService.findUserByEmail(query);
    } else {
      return await _walletService.findUserByCVU(query);
    }
  }

  Future<bool> transfer({
    required String fromUserId,
    required String toUserId,
    required double amount,
    required String currency,
    String? description,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _walletService.transfer(
        fromUserId: fromUserId,
        toUserId: toUserId,
        amount: amount,
        currency: currency,
        description: description,
      );
      await loadWallets(fromUserId);
      await loadTransactions(fromUserId);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> convert({
    required String userId,
    required double amount,
    required String fromCurrency,
    required String toCurrency,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _walletService.convert(
        userId: userId,
        amount: amount,
        fromCurrency: fromCurrency,
        toCurrency: toCurrency,
      );
      await loadWallets(userId);
      await loadTransactions(userId);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> requestDeposit({
    required String userId,
    required double amount,
    required String currency,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _walletService.requestDeposit(
        userId: userId,
        amount: amount,
        currency: currency,
      );
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Error al solicitar deposito';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void _ensureExchangeRateSubscription() {
    if (_exchangeRateChannel != null) return;
    _exchangeRateChannel = SupabaseConfig.client
        .channel('public:exchange_rates')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'exchange_rates',
          callback: (payload) {
            final record = payload.newRecord;
            if (record != null) {
              _exchangeRate = ExchangeRateModel.fromJson(record);
              notifyListeners();
            }
          },
        )
        .subscribe();
  }

  @override
  void dispose() {
    _exchangeRateChannel?.unsubscribe();
    super.dispose();
  }
}
