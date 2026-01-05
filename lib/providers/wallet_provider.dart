import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/wallet_model.dart';
import '../models/transaction_model.dart';
import '../models/exchange_rate_model.dart';
import '../models/user_model.dart';
import '../services/wallet_service.dart';
import '../services/cache_service.dart';
import '../services/notification_service.dart';
import '../config/supabase_config.dart';

class WalletProvider extends ChangeNotifier {
  final WalletService _walletService = WalletService();
  final CacheService _cacheService = CacheService();
  final NotificationService _notificationService = NotificationService();

  List<WalletModel> _wallets = [];
  List<TransactionModel> _transactions = [];
  ExchangeRateModel? _exchangeRate;
  bool _isLoading = false;
  bool _isOffline = false;
  String? _error;
  RealtimeChannel? _exchangeRateChannel;

  List<WalletModel> get wallets => _wallets;
  List<TransactionModel> get transactions => _transactions;
  ExchangeRateModel? get exchangeRate => _exchangeRate;
  bool get isLoading => _isLoading;
  bool get isOffline => _isOffline;
  String? get error => _error;

  WalletModel? get arsWallet =>
      _wallets.where((w) => w.currency == 'ARS').firstOrNull;
  WalletModel? get usdWallet =>
      _wallets.where((w) => w.currency == 'USD').firstOrNull;

  Future<void> loadWallets(String userId) async {
    _isLoading = true;
    _error = null;
    _isOffline = false;
    notifyListeners();

    try {
      _wallets = await _walletService.getWallets(userId);
      await _cacheService.cacheWallets(_wallets);
      await _notificationService.subscribeToWalletChanges(userId);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      // Intentar cargar desde cache
      final cached = _cacheService.getCachedWallets();
      if (cached != null && cached.isNotEmpty) {
        _wallets = cached;
        _isOffline = true;
        _error = null;
      } else {
        _error = 'Error al cargar billeteras';
      }
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadExchangeRate() async {
    try {
      _exchangeRate = await _walletService.getExchangeRate();
      if (_exchangeRate != null) {
        await _cacheService.cacheExchangeRate(_exchangeRate!);
      }
      _ensureExchangeRateSubscription();
      notifyListeners();
    } catch (e) {
      // Intentar cargar desde cache
      final cached = _cacheService.getCachedExchangeRate();
      if (cached != null) {
        _exchangeRate = cached;
      } else {
        _error = 'Error al cargar cotizacion';
      }
      notifyListeners();
    }
  }

  Future<void> loadTransactions(String userId) async {
    try {
      _transactions = await _walletService.getTransactions(userId);
      await _cacheService.cacheTransactions(_transactions);
      notifyListeners();
    } catch (e) {
      // Intentar cargar desde cache
      final cached = _cacheService.getCachedTransactions();
      if (cached != null && cached.isNotEmpty) {
        _transactions = cached;
      } else {
        _error = 'Error al cargar transacciones';
      }
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
    required String toIdentifier,
    required double amount,
    required String currency,
    String? description,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _walletService.transfer(
        toIdentifier: toIdentifier,
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
      _error = e.toString().replaceAll('Exception: ', '');
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

  Future<bool> requestWithdrawal({
    required String userId,
    required double amount,
    required String currency,
    required String destinationCbu,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _walletService.requestWithdrawal(
        userId: userId,
        amount: amount,
        currency: currency,
        destinationCbu: destinationCbu,
      );
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Error al solicitar retiro';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Configuracion de la app (con cache)
  Future<Map<String, String>> getAppConfig() async {
    // Primero intentar cache
    final cached = _cacheService.getCachedAppConfig();
    if (cached != null && cached.isNotEmpty) {
      // Refrescar en background
      _walletService.getAppConfig().then((fresh) {
        _cacheService.cacheAppConfig(fresh);
      });
      return cached;
    }

    // Si no hay cache, buscar de Supabase
    final config = await _walletService.getAppConfig();
    await _cacheService.cacheAppConfig(config);
    return config;
  }

  Future<void> updateAppConfig(String key, String value) async {
    await _walletService.updateAppConfig(key, value);
    // Invalidar cache
    final config = await _walletService.getAppConfig();
    await _cacheService.cacheAppConfig(config);
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

  Future<void> clearCache() async {
    await _cacheService.clearUserCache();
    await _notificationService.unsubscribe();
  }

  @override
  void dispose() {
    _exchangeRateChannel?.unsubscribe();
    _notificationService.dispose();
    super.dispose();
  }
}
