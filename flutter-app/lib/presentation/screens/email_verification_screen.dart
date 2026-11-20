import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:medcin_app/config/api_config.dart';
import 'package:medcin_app/core/network/api_service.dart';
import 'package:medcin_app/presentation/providers/auth_provider.dart';

class EmailVerificationScreen extends StatefulWidget {
  const EmailVerificationScreen({required this.email, super.key});

  final String email;

  @override
  State<EmailVerificationScreen> createState() => _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  bool _resending = false;
  bool _checking = false;

  void _snack(String msg, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text(msg),
          behavior: SnackBarBehavior.floating,
          backgroundColor: error ? const Color(0xFFDC2626) : const Color(0xFFBD7F66),
          shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(12))),
        ),
      );
  }

  Future<void> _resend() async {
    setState(() => _resending = true);
    try {
      await ApiService.post(
        ApiConfig.emailVerifyResend,
        body: {'email': widget.email},
      );
      _snack('Email de vérification renvoyé. Vérifiez votre boîte mail.');
    } on Exception {
      _snack('Erreur de réseau. Réessayez.', error: true);
    } finally {
      if (mounted) setState(() => _resending = false);
    }
  }

  Future<void> _checkVerified() async {
    setState(() => _checking = true);
    try {
      final verified = await _fetchStatus();
      if (!mounted) return;
      if (verified) {
        _snack('Email vérifié avec succès ! Vous pouvez maintenant vous connecter.');
        context.go('/auth/login');
      } else {
        _snack('Email non vérifié pour le moment. Vérifiez votre boîte mail.');
      }
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  Future<bool> _fetchStatus() async {
    final auth = AuthProvider.instance;
    if (auth.status == AuthStatus.authenticated && auth.displayEmail.isNotEmpty) {
      return auth.refreshUser();
    }
    final data = await ApiService.get(
      ApiConfig.emailVerifyStatus,
      queryParams: {'email': widget.email},
    );
    return data is Map && data['verified'] == true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F1EA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFFBD7F66)),
        title: const Text('Vérification email'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 96,
                height: 96,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFFBD7F66).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(32),
                ),
                child: const Icon(Icons.mark_email_read_rounded,
                    size: 48, color: Color(0xFFBD7F66)),
              ),
              const SizedBox(height: 24),
              const Text(
                'Vérifiez votre adresse email',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFBD7F66),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Un email de vérification a été envoyé à :',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
              ),
              const SizedBox(height: 6),
              Text(
                widget.email,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFBD7F66),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Cliquez sur le lien contenu dans l\'email pour confirmer votre adresse. '
                'Pensez à vérifier vos spams. Votre compte ne sera activé qu\'après vérification.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, height: 1.5, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 36),
              ElevatedButton.icon(
                onPressed: _checking ? null : _checkVerified,
                icon: _checking
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.verified_rounded, size: 20),
                label: const Text('J\'ai vérifié mon email'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFBD7F66),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  elevation: 0,
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _resending ? null : _resend,
                icon: _resending
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.refresh_rounded, size: 20),
                label: const Text('Renvoyer le lien de vérification'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFBD7F66),
                  side: const BorderSide(color: Color(0xFFBD7F66)),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => context.go('/auth/login'),
                child: const Text(
                  'Retour à la connexion',
                  style: TextStyle(color: Color(0xFF8B8173), fontSize: 13),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}