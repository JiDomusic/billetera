import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/auth/forgot_password_screen.dart';
import '../screens/auth/verify_email_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/wallet/transfer_screen.dart';
import '../screens/wallet/convert_screen.dart';
import '../screens/wallet/qr_screen.dart';
import '../screens/wallet/deposit_screen.dart';
import '../screens/wallet/withdraw_screen.dart';
import '../screens/wallet/scan_qr_screen.dart';
import '../screens/history/transactions_screen.dart';
import '../screens/admin/admin_login_screen.dart';
import '../screens/admin/admin_dashboard_screen.dart';

class AppRoutes {
  static final GoRouter router = GoRouter(
    initialLocation: '/login',
    routes: [
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        name: 'register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        name: 'forgot_password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/verify-email',
        name: 'verify_email',
        builder: (context, state) {
          final email = state.uri.queryParameters['email'] ?? '';
          return VerifyEmailScreen(email: email);
        },
      ),
      GoRoute(
        path: '/home',
        name: 'home',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/transfer',
        name: 'transfer',
        builder: (context, state) => const TransferScreen(),
      ),
      GoRoute(
        path: '/convert',
        name: 'convert',
        builder: (context, state) => const ConvertScreen(),
      ),
      GoRoute(
        path: '/qr',
        name: 'qr',
        builder: (context, state) => const QrScreen(),
      ),
      GoRoute(
        path: '/scan-qr',
        name: 'scan_qr',
        builder: (context, state) => const ScanQrScreen(),
      ),
      GoRoute(
        path: '/deposit',
        name: 'deposit',
        builder: (context, state) => const DepositScreen(),
      ),
      GoRoute(
        path: '/withdraw',
        name: 'withdraw',
        builder: (context, state) => const WithdrawScreen(),
      ),
      GoRoute(
        path: '/history',
        name: 'history',
        builder: (context, state) => const TransactionsScreen(),
      ),
      GoRoute(
        path: '/admin',
        name: 'admin_login',
        builder: (context, state) => const AdminLoginScreen(),
      ),
      GoRoute(
        path: '/admin/dashboard',
        name: 'admin_dashboard',
        builder: (context, state) => const AdminDashboardScreen(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Error: ${state.error}'),
      ),
    ),
  );
}
