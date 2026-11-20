import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:medcin_app/config/api_config.dart';
import 'package:medcin_app/core/errors/api_exception.dart';
import 'package:medcin_app/core/network/api_service.dart';
import 'package:medcin_app/presentation/providers/auth_provider.dart';
import 'package:medcin_app/presentation/screens/privacy_policy_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _pass = TextEditingController();
  bool _loading = false, _hide = true;
  bool _unverified = false;
  bool _resending = false;
  String? _errorMsg;

  late final AnimationController _orb = AnimationController(vsync: this, duration: const Duration(seconds: 12))..repeat(reverse: true);
  late final Animation<double> _move = Tween(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _orb, curve: Curves.easeInOut));

  void _showError(String msg) {
    setState(() => _errorMsg = msg);
    Future.delayed(const Duration(seconds: 5), () { if (mounted) setState(() => _errorMsg = null); });
  }

  void _login() async {
    if (!_formKey.currentState!.validate()) {
      final e = _email.text, p = _pass.text;
      Future.delayed(const Duration(seconds: 5), () { if (mounted) { _formKey.currentState!.reset(); _email.text = e; _pass.text = p; setState(() {}); } });
      return;
    }
    final auth = AuthProvider.instance;
    setState(() => _loading = true);
    try {
      await auth.login(_email.text.trim(), _pass.text);
      if (mounted) {
        context.go(auth.isDoctor ? '/doctor-home' : '/');
      }
    } on ApiException catch (e) {
      if (e.statusCode == 422 && e.errors.containsKey('email')) {
        setState(() => _unverified = true);
        _showError('Vérifiez votre email');
        return;
      }
      _showError(e.message == 'CSRF token mismatch.' ? 'Identifiants invalides' : e.message);
    } on Exception {
      _showError('Erreur de connexion au serveur.');
    } finally { setState(() => _loading = false); }
  }

  Future<void> _resendVerification() async {
    setState(() => _resending = true);
    try {
      await ApiService.post(
        ApiConfig.emailVerifyResend,
        body: {'email': _email.text.trim()},
      );
      _showError('Email de vérification renvoyé. Vérifiez votre boîte mail.');
    } on ApiException catch (e) {
      _showError(e.message);
    } on Exception {
      _showError('Erreur de réseau. Réessayez.');
    } finally {
      if (mounted) setState(() => _resending = false);
    }
  }

  @override
  void dispose() { _orb.dispose(); _email.dispose(); _pass.dispose(); super.dispose(); }

  Widget _field(TextEditingController c, String l, IconData ic, bool pwd, TextInputType t) => TextFormField(
    controller: c, obscureText: pwd && _hide, keyboardType: t,
    style: const TextStyle(color: Color(0xFF2C2B22), fontSize: 15),
    decoration: InputDecoration(
      labelText: l, labelStyle: const TextStyle(color: Color(0xFFA69D8F)),
      floatingLabelStyle: const TextStyle(color: Color(0xFFBD7F66), fontWeight: FontWeight.w600),
      prefixIcon: Icon(ic, color: const Color(0xFFBD7F66).withValues(alpha: 0.6), size: 20),
      suffixIcon: pwd ? IconButton(icon: Icon(_hide ? Icons.visibility_off_rounded : Icons.visibility_rounded, size: 20, color: const Color(0xFFA69D8F)), onPressed: () => setState(() => _hide = !_hide)) : null,
      filled: true, fillColor: const Color(0xFFF8F6F3).withValues(alpha: 0.8),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: const BorderSide(color: Color(0xFFBD7F66), width: 1.5)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      errorStyle: const TextStyle(color: Color(0xFFDC2626), fontWeight: FontWeight.w700, fontSize: 13),
    ),
    validator: (v) => v?.isEmpty == true ? '$l requis' : null,
  );


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F5F2),
      body: Stack(children: [
        AnimatedBuilder(animation: _move, builder: (_, __) => Stack(children: [
          Positioned(top: -120 + _move.value * 40, right: -100 + _move.value * 20, child: Container(width: 420, height: 420, decoration: const BoxDecoration(shape: BoxShape.circle, gradient: RadialGradient(colors: [Color(0x4DFFD4B8), Color(0x00000000)])))),
          Positioned(bottom: -80 - _move.value * 30, left: -60 - _move.value * 25, child: Container(width: 320, height: 320, decoration: const BoxDecoration(shape: BoxShape.circle, gradient: RadialGradient(colors: [Color(0x40D5E8F5), Color(0x00000000)])))),
        ])),
        SafeArea(child: Center(child: SingleChildScrollView(padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 30), child: Form(key: _formKey, child: Column(mainAxisSize: MainAxisSize.min, children: [
          const SizedBox(height: 20),
          Container(
            width: 110,
            height: 110,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(26),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFBD7F66).withValues(alpha: 0.25),
                  blurRadius: 30,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(26),
              child: Image.asset('assets/images/logo.png'),
            ),
          ),
          const SizedBox(height: 20),
          const Text('Votre espace médical familial', textAlign: TextAlign.center, style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: Color(0xFFBD7F66), fontFamily: 'Playfair Display', height: 1.2)),
          const SizedBox(height: 12),
          const Text('Parce que leur sourire est notre plus beau remède.', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF8E7F68), fontSize: 13, letterSpacing: 0.8, height: 1.5)),
          const SizedBox(height: 38),
          if (_errorMsg != null)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(color: const Color(0xFFDC2626), borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: const Color(0xFFDC2626).withValues(alpha: 0.3), blurRadius: 20)]),
              child: Column(children: [
                Row(children: [const Icon(Icons.error_outline, color: Colors.white, size: 20), const SizedBox(width: 10), Expanded(child: Text(_errorMsg!, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)))]),
                if (_unverified)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: _resending ? null : _resendVerification,
                      icon: _resending
                          ? const SizedBox(height: 14, width: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.refresh_rounded, size: 16, color: Colors.white),
                      label: Text(_resending ? 'Envoi...' : 'Renvoyer le lien de vérification',
                          style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                    ),
                  ),
              ])),
          ClipRRect(
            borderRadius: BorderRadius.circular(32),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
              child: Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.75), borderRadius: BorderRadius.circular(32), border: Border.all(color: Colors.white.withValues(alpha: 0.6)), boxShadow: [BoxShadow(color: const Color(0xFFBD7F66).withValues(alpha: 0.06), blurRadius: 40, offset: const Offset(0, 15))]),
                child: Column(children: [
                  _field(_email, 'Email', Icons.mail_outline_rounded, false, TextInputType.emailAddress),
                  const SizedBox(height: 16),
                  _field(_pass, 'Mot de passe', Icons.lock_outline_rounded, true, TextInputType.text),
                  const SizedBox(height: 8),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    const Flexible(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.lock, size: 12, color: Color(0xFFBD7F66)),
                          SizedBox(width: 4),
                          Flexible(
                            child: Text('🔒 Données chiffrées',
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(fontSize: 10, color: Color(0xFFA69D8F))),
                          ),
                        ],
                      ),
                    ),
                    TextButton(onPressed: () => context.go('/auth/forgot-password'), child: const Text('Mot de passe oublié ?', style: TextStyle(fontSize: 11, color: Color(0xFFBD7F66)))),
                  ]),
                  const SizedBox(height: 18),
                  Container(
                    decoration: const BoxDecoration(borderRadius: BorderRadius.all(Radius.circular(30)), gradient: LinearGradient(colors: [Color(0xFFBD7F66), Color(0xFFBD7F66)])),
                    child: Material(color: Colors.transparent, child: InkWell(onTap: _loading ? null : _login, borderRadius: BorderRadius.circular(30), child: Container(width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 15), child: Center(child: _loading ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white)) : const Text('Se connecter', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white))))))),
                  const SizedBox(height: 16),
                ]),
              ),
            ),
          ),
          const SizedBox(height: 24),
          TextButton(onPressed: () => context.go('/auth/register'), child: RichText(text: const TextSpan(style: TextStyle(color: Color(0xFF8E7F68), fontSize: 14), children: [TextSpan(text: 'Pas de compte ? '), TextSpan(text: 'Créer un compte', style: TextStyle(color: Color(0xFFBD7F66), fontWeight: FontWeight.w700))]))),
          TextButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen()),
            ),
            child: const Text('Politique de confidentialité',
                style: TextStyle(color: Color(0xFFBD7F66), fontSize: 12, fontWeight: FontWeight.w600)),
          ),
        ]))))),
      ]),
    );
  }
}
