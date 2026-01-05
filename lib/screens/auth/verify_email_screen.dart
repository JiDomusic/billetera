import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../config/supabase_config.dart';
import '../../widgets/loading_button.dart';

class VerifyEmailScreen extends StatefulWidget {
  final String email;

  const VerifyEmailScreen({
    super.key,
    required this.email,
  });

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  bool _isResending = false;
  bool _isChecking = false;

  Future<void> _resendVerification() async {
    setState(() => _isResending = true);

    try {
      await SupabaseConfig.client.auth.resend(
        type: OtpType.signup,
        email: widget.email,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Email de verificacion reenviado'),
            backgroundColor: Color(0xFF47E6B1),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isResending = false);
      }
    }
  }

  Future<void> _checkVerification() async {
    setState(() => _isChecking = true);

    try {
      final session = SupabaseConfig.client.auth.currentSession;
      if (session != null) {
        final user = SupabaseConfig.client.auth.currentUser;
        if (user?.emailConfirmedAt != null) {
          if (mounted) {
            context.go('/home');
          }
          return;
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Email aun no verificado. Revisa tu bandeja de entrada.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isChecking = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/login'),
        ),
        title: const Text('Verificar Email'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFF4AC1FF).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.mark_email_unread_outlined,
                  size: 64,
                  color: Color(0xFF4AC1FF),
                ),
              ),
              const SizedBox(height: 32),
              const Text(
                'Verifica tu email',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Enviamos un email de verificacion a:',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                widget.email,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF47E6B1),
                ),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF131A22),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white12),
                ),
                child: const Column(
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.white60, size: 20),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Haz clic en el enlace del email para activar tu cuenta.',
                            style: TextStyle(color: Colors.white70, fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(Icons.folder_outlined, color: Colors.white60, size: 20),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Revisa tambien la carpeta de spam.',
                            style: TextStyle(color: Colors.white70, fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              LoadingButton(
                label: 'Ya verifique mi email',
                isLoading: _isChecking,
                onPressed: _checkVerification,
                icon: Icons.check_circle_outline,
              ),
              const SizedBox(height: 16),
              LoadingButton(
                label: 'Reenviar email',
                isLoading: _isResending,
                onPressed: _resendVerification,
                backgroundColor: const Color(0xFF1A212C),
                foregroundColor: Colors.white,
                icon: Icons.refresh,
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => context.go('/login'),
                child: const Text('Usar otra cuenta'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
