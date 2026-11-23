import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:medcin_app/config/api_config.dart';
import 'package:medcin_app/core/errors/api_exception.dart';
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
      _snack('Nouveau lien envoyé. Vérifiez votre boîte mail.');
    } on ApiException catch (e) {
      _snack(e.message, error: true);
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
        _snack('Email non vérifié pour le moment. Ouvrez le lien reçu par email.');
      }
    } on ApiException catch (e) {
      _snack(e.message, error: true);
    } on Exception {
      _snack('Impossible de vérifier le statut. Réessayez.', error: true);
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
        title: const Text(
          'Vérification email',
          style: TextStyle(color: Color(0xFF2C2B22), fontWeight: FontWeight.w700),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Confirmez votre adresse',
                style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFBD7F66)),
              ),
              const SizedBox(height: 4),
              const Text(
                'Un lien de vérification vous a été envoyé par email.',
                style: TextStyle(fontSize: 14, color: Color(0xFF8B8173)),
              ),
              const SizedBox(height: 28),
              Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFBD7F66).withValues(alpha: 0.06),
                      blurRadius: 30,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      width: 88,
                      height: 88,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: const Color(0xFFBD7F66).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(28),
                      ),
                      child: const Icon(Icons.mark_email_read_rounded,
                          size: 44, color: Color(0xFFBD7F66)),
                    ),
                    const SizedBox(height: 22),
                    const Text(
                      'Ouvrez votre boîte mail',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF2C2B22),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Cliquez sur le lien dans l’email envoyé à :',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8F6F3),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Text(
                        widget.email,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFBD7F66),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'Après avoir cliqué sur le lien, revenez ici et appuyez sur « J’ai vérifié mon email ». Pensez à vérifier vos spams.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13, height: 1.55, color: Color(0xFF8B8173)),
                    ),
                    const SizedBox(height: 26),
                    ElevatedButton.icon(
                      onPressed: _checking ? null : _checkVerified,
                      icon: _checking
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.verified_rounded, size: 20),
                      label: const Text("J'ai vérifié mon email"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFBD7F66),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 18),
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
                      label: const Text('Renvoyer le lien'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFBD7F66),
                        side: const BorderSide(color: Color(0xFFBD7F66)),
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                      ),
                    ),
                  ],
                ),
              ),
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
