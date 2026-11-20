import 'package:flutter/material.dart';
import 'package:medcin_app/config/api_config.dart';
import 'package:medcin_app/core/errors/api_exception.dart';
import 'package:medcin_app/core/network/api_service.dart';
import 'package:medcin_app/data/services/chat_service.dart';
import 'package:medcin_app/presentation/providers/auth_provider.dart';
import 'package:medcin_app/presentation/screens/chat/conversations_screen.dart';
import 'package:medcin_app/presentation/screens/email_verification_screen.dart';
import 'package:medcin_app/presentation/screens/subscription_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = AuthProvider.instance;
    return Scaffold(
      backgroundColor: const Color(0xFFF5F1EA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFBD7F66),
        foregroundColor: Colors.white,
        centerTitle: true,
        title: const Text('Profil', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 8),
            Container(
              width: 92,
              height: 92,
              decoration: BoxDecoration(
                color: const Color(0xFFBD7F66).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(30),
              ),
              child: const Icon(Icons.person, size: 46, color: Color(0xFFBD7F66)),
            ),
            const SizedBox(height: 16),
            Text(
              auth.displayName,
              style: const TextStyle(
                  fontSize: 22, fontWeight: FontWeight.w700, color: Color(0xFFBD7F66)),
            ),
            const SizedBox(height: 6),
            Text(
              auth.displayEmail,
              style: const TextStyle(color: Color(0xFF8B8173), fontSize: 13),
            ),
            const SizedBox(height: 8),
            if (auth.isDoctor)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFD1FAE5),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Text('Médecin',
                    style: TextStyle(color: Color(0xFFBD7F66), fontSize: 12, fontWeight: FontWeight.w600)),
              ),
            if (!auth.isVerified) ...[
              const SizedBox(height: 20),
              const _EmailVerifyBanner(),
            ],
            const SizedBox(height: 32),
            ValueListenableBuilder<int>(
              valueListenable: ChatService.instance.totalUnread,
              builder: (context, unread, _) => SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const ConversationsScreen()),
                  ),
                  icon: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      const Icon(Icons.chat_bubble_rounded, size: 20),
                      if (unread > 0)
                        Positioned(
                          right: -12,
                          top: -10,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEF4444),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              '${unread > 99 ? '99+' : unread}',
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700),
                            ),
                          ),
                        ),
                    ],
                  ),
                  label: const Text('Messages'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFBD7F66),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                    elevation: 0,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const SubscriptionScreen()),
                ),
                icon: const Icon(Icons.workspace_premium_rounded,
                    size: 20, color: Color(0xFFBD7F66)),
                label: const Text('Mon abonnement'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFBD7F66),
                  side: const BorderSide(color: Color(0xFFBD7F66), width: 1.5),
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18)),
                  elevation: 0,
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  await AuthProvider.instance.logout();
                },
                icon: const Icon(Icons.logout_rounded, size: 20),
                label: const Text('Déconnexion'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFECACA),
                  foregroundColor: const Color(0xFFEF4444),
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmailVerifyBanner extends StatefulWidget {
  const _EmailVerifyBanner();
  @override
  State<_EmailVerifyBanner> createState() => _EmailVerifyBannerState();
}

class _EmailVerifyBannerState extends State<_EmailVerifyBanner> {
  bool _busy = false;

  Future<void> _resend() async {
    setState(() => _busy = true);
    try {
      await ApiService.post(ApiConfig.emailResend);
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(const SnackBar(
          content: Text('Email de vérification renvoyé.'),
          behavior: SnackBarBehavior.floating,
        ));
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..clearSnackBars()
          ..showSnackBar(SnackBar(
            content: Text(e.message),
            behavior: SnackBarBehavior.floating,
          ));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3CD),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFF1C40F).withValues(alpha: 0.5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline_rounded, color: Color(0xFFB7791F), size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Email non vérifié',
                  style: TextStyle(
                      color: Color(0xFF8A5A00), fontSize: 14, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Vérifiez votre adresse email pour profiter de tous les services.',
                  style: TextStyle(color: Color(0xFF8A5A00), fontSize: 12, height: 1.4),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    TextButton(
                      onPressed: _busy
                          ? null
                          : () => Navigator.of(context).push(MaterialPageRoute(
                              builder: (_) => EmailVerificationScreen(
                                  email: AuthProvider.instance.displayEmail))),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text('Vérifier maintenant',
                          style: TextStyle(
                              color: Color(0xFFBD7F66),
                              fontSize: 12,
                              fontWeight: FontWeight.w700)),
                    ),
                    TextButton(
                      onPressed: _busy ? null : _resend,
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(_busy ? 'Envoi...' : 'Renvoyer le lien',
                          style: const TextStyle(
                              color: Color(0xFF8A5A00),
                              fontSize: 12,
                              fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}