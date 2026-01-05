import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'config/firebase_config.dart';
import 'config/supabase_config.dart';
import 'config/app_routes.dart';
import 'providers/auth_provider.dart';
import 'providers/wallet_provider.dart';
import 'services/notification_service.dart';
import 'services/cache_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await FirebaseConfig.initialize();
  await SupabaseConfig.initialize();
  await CacheService().initialize();
  await NotificationService().initialize();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => WalletProvider()),
      ],
      child: MaterialApp.router(
        title: 'Billetera JJ',
        debugShowCheckedModeBanner: false,
        theme: _buildDarkTheme(),
        routerConfig: AppRoutes.router,
      ),
    );
  }

  ThemeData _buildDarkTheme() {
    const background = Color(0xFF0D1117);
    const surface = Color(0xFF131A22);
    const accent = Color(0xFF47E6B1);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      colorScheme: ColorScheme.fromSeed(
        seedColor: accent,
        brightness: Brightness.dark,
        background: background,
        surface: surface,
        primary: accent,
        secondary: const Color(0xFF7DF2C3),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: surface,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF1A212C),
        labelStyle: const TextStyle(color: Colors.white70),
        hintStyle: const TextStyle(color: Colors.white54),
        prefixIconColor: Colors.white70,
        suffixIconColor: Colors.white70,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.white12),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.white24),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: accent, width: 2),
        ),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Colors.white12),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: Colors.black,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      textTheme: Typography.whiteCupertino.apply(
        displayColor: Colors.white,
        bodyColor: Colors.white.withOpacity(0.9),
      ),
      dividerColor: Colors.white12,
      listTileTheme: const ListTileThemeData(
        iconColor: Colors.white70,
      ),
    );
  }
}
