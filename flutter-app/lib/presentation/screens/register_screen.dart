import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:medcin_app/core/errors/api_exception.dart';
import 'package:medcin_app/presentation/providers/auth_provider.dart';
import 'package:medcin_app/presentation/screens/privacy_policy_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _pass = TextEditingController();
  final _confirm = TextEditingController();

  bool _loading = false;
  bool _hidePass = true;
  bool _hideConfirm = true;
  bool _terms = false;
  bool _submitted = false;
  String? _termsError;
  Map<String, String> _serverErrors = {};

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _pass.dispose();
    _confirm.dispose();
    super.dispose();
  }

  void _clearServerError(String field) {
    if (_serverErrors.containsKey(field)) {
      setState(() => _serverErrors.remove(field));
    }
  }

  String? _validateName(String? v) {
    final server = _serverErrors['name'];
    if (server != null) return server;
    if (v == null || v.trim().isEmpty) return 'Le nom est requis.';
    return null;
  }

  String? _validateEmail(String? v) {
    final server = _serverErrors['email'];
    if (server != null) return server;
    if (v == null || v.trim().isEmpty) return 'L\'email est requis.';
    final ok = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(v.trim());
    if (!ok) return 'Adresse email invalide.';
    return null;
  }

  String? _validatePassword(String? v) {
    final server = _serverErrors['password'];
    if (server != null) return server;
    if (v == null || v.isEmpty) return 'Le mot de passe est requis.';
    if (v.length < 8) return '8 caractères minimum.';
    return null;
  }

  String? _validateConfirm(String? v) {
    final server = _serverErrors['password_confirmation'];
    if (server != null) return server;
    if (v == null || v.isEmpty) return 'Confirmez le mot de passe.';
    if (v != _pass.text) return 'Les mots de passe ne correspondent pas.';
    return null;
  }

  Future<void> _submit() async {
    setState(() {
      _submitted = true;
      _termsError = null;
      _serverErrors = {};
    });
    if (!_formKey.currentState!.validate()) return;
    if (!_terms) {
      setState(() => _termsError = 'Vous devez accepter les conditions générales.');
      return;
    }
    setState(() => _loading = true);
    try {
      await AuthProvider.instance.register(
        name: _name.text,
        email: _email.text,
        password: _pass.text,
        confirmation: _confirm.text,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Inscription réussie ! Vérifiez votre email.'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
        ),
      );
      context.go('/verify-email?email=${Uri.encodeComponent(_email.text.trim())}');
    } on ApiException catch (e) {
      final mapped = <String, String>{};
      for (final field in ['name', 'email', 'password', 'password_confirmation']) {
        final msg = e.firstErrorFor(field);
        if (msg != null) mapped[field] = msg;
      }
      if (mapped.isNotEmpty) {
        setState(() => _serverErrors = mapped);
        _formKey.currentState!.validate();
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message),
            behavior: SnackBarBehavior.floating,
            shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(12))),
          ),
        );
      }
    } on Exception {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erreur de connexion au serveur.'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  InputDecoration _d(String h, {String? errorText, Widget? suffix, Widget? prefix}) {
    return InputDecoration(
      hintText: h,
      hintStyle: const TextStyle(color: Color(0xFFA69D8F)),
      errorText: errorText,
      prefixIcon: prefix,
      suffixIcon: suffix,
      filled: true,
      fillColor: const Color(0xFFF8F6F3),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Color(0xFFBD7F66), width: 1.5)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F1EA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFFBD7F66)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
          child: Form(
            key: _formKey,
            autovalidateMode: _submitted ? AutovalidateMode.onUserInteraction : AutovalidateMode.disabled,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Créer un compte',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: Color(0xFFBD7F66))),
                const SizedBox(height: 4),
                const Text('Pour suivre la santé de vos enfants',
                    style: TextStyle(color: Color(0xFF8B8173), fontSize: 14)),
                const SizedBox(height: 32),
                Container(
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                          color: const Color(0xFFBD7F66).withValues(alpha: 0.06),
                          blurRadius: 30,
                          offset: const Offset(0, 10)),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextFormField(
                        controller: _name,
                        style: const TextStyle(color: Color(0xFF2C2B22)),
                        textInputAction: TextInputAction.next,
                        decoration: _d('Nom complet',
                            prefix: const Icon(Icons.person_outline_rounded, color: Color(0xFFBD7F66), size: 20)),
                        validator: _validateName,
                        onChanged: (_) => _clearServerError('name'),
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _email,
                        style: const TextStyle(color: Color(0xFF2C2B22)),
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        decoration: _d('Email',
                            prefix: const Icon(Icons.mail_outline_rounded, color: Color(0xFFBD7F66), size: 20)),
                        validator: _validateEmail,
                        onChanged: (_) => _clearServerError('email'),
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _pass,
                        obscureText: _hidePass,
                        style: const TextStyle(color: Color(0xFF2C2B22)),
                        textInputAction: TextInputAction.next,
                        decoration: _d('Mot de passe (8+ car.)',
                            prefix: const Icon(Icons.lock_outline_rounded, color: Color(0xFFBD7F66), size: 20),
                            suffix: IconButton(
                              icon: Icon(_hidePass ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                                  size: 20, color: const Color(0xFFA69D8F)),
                              onPressed: () => setState(() => _hidePass = !_hidePass),
                            )),
                        validator: _validatePassword,
                        onChanged: (_) {
                          _clearServerError('password');
                          if (_confirm.text.isNotEmpty && _confirm.text != _pass.text) {
                            setState(() {});
                          }
                        },
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _confirm,
                        obscureText: _hideConfirm,
                        style: const TextStyle(color: Color(0xFF2C2B22)),
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => _submit(),
                        decoration: _d('Confirmer le mot de passe',
                            prefix: const Icon(Icons.lock_rounded, color: Color(0xFFBD7F66), size: 20),
                            suffix: IconButton(
                              icon: Icon(_hideConfirm ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                                  size: 20, color: const Color(0xFFA69D8F)),
                              onPressed: () => setState(() => _hideConfirm = !_hideConfirm),
                            )),
                        validator: _validateConfirm,
                        onChanged: (_) => _clearServerError('password_confirmation'),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: SizedBox(
                              width: 22,
                              height: 22,
                              child: Checkbox(
                                value: _terms,
                                onChanged: (v) => setState(() {
                                  _terms = v ?? false;
                                  _termsError = null;
                                }),
                                activeColor: const Color(0xFFBD7F66),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() {
                                _terms = !_terms;
                                _termsError = null;
                              }),
                              child: Text.rich(
                                TextSpan(
                                  style: const TextStyle(
                                      color: Color(0xFF6B6152), fontSize: 13, height: 1.45),
                                  children: [
                                    const TextSpan(
                                        text:
                                            'J\'accepte les conditions générales d\'utilisation et la '),
                                    WidgetSpan(
                                      alignment: PlaceholderAlignment.baseline,
                                      baseline: TextBaseline.alphabetic,
                                      child: GestureDetector(
                                        onTap: () => Navigator.of(context).push(
                                          MaterialPageRoute(
                                              builder: (_) => const PrivacyPolicyScreen()),
                                        ),
                                        child: const Text(
                                          'Politique de confidentialité',
                                          style: TextStyle(
                                            color: Color(0xFFBD7F66),
                                            fontWeight: FontWeight.w600,
                                            decoration: TextDecoration.underline,
                                            decorationColor: Color(0xFFBD7F66),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (_termsError != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(_termsError!,
                              style: const TextStyle(color: Color(0xFFB3261E), fontSize: 12, fontWeight: FontWeight.w600)),
                        ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _loading ? null : _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFBD7F66),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                            elevation: 0,
                          ),
                          child: _loading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : const Text('S\'inscrire',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: TextButton(
                    onPressed: () => context.go('/auth/login'),
                    child: RichText(
                      text: const TextSpan(
                        style: TextStyle(color: Color(0xFF8E7F68), fontSize: 14),
                        children: [
                          TextSpan(text: 'Déjà un compte ? '),
                          TextSpan(text: 'Se connecter',
                              style: TextStyle(color: Color(0xFFBD7F66), fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}