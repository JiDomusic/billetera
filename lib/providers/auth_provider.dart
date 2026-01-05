import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  User? _supabaseUser;
  UserModel? _user;
  bool _isLoading = false;
  String? _error;

  User? get supabaseUser => _supabaseUser;
  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _supabaseUser != null;

  AuthProvider() {
    _authService.authStateChanges.listen((authState) {
      _supabaseUser = authState.session?.user;
      if (_supabaseUser != null) {
        _loadUserData();
      } else {
        _user = null;
        notifyListeners();
      }
    });
  }

  Future<void> _loadUserData() async {
    try {
      _user = await _authService.getCurrentUserData();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<bool> signIn(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _authService.signIn(email, password);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Error al iniciar sesion';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> signUp(String email, String password, String fullName) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _authService.signUp(email, password, fullName);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Error al registrarse: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> signOut() async {
    await _authService.signOut();
    _user = null;
    notifyListeners();
  }

  Future<bool> resetPassword(String email) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _authService.resetPassword(email);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Error al enviar email';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  String _getErrorMessage(String code) {
    // Supabase no expone codes como Firebase, devolvemos genérico.
    return 'Error de autenticacion ($code)';
  }
}
