import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:medcin_app/config/api_config.dart';
import 'package:medcin_app/core/network/api_service.dart';

class ResetPasswordScreen extends StatefulWidget {
  final String email;
  const ResetPasswordScreen({super.key, required this.email});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _email;
  final _code = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _loading = false;
  bool _obscure = true;

  @override
  void initState() {
    super.initState();
    _email = TextEditingController(text: widget.email);
  }

  @override
  void dispose() {
    _email.dispose();
    _code.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await ApiService.post(
        ApiConfig.passwordResetEndpoint,
        body: {
          'email': _email.text.trim(),
          'code': _code.text.trim(),
          'password': _password.text,
          'password_confirmation': _confirm.text,
        },
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mot de passe réinitialisé. Connectez-vous.'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 400));
      if (mounted) context.go('/auth/login');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Code invalide ou expiré. Veuillez réessayer.'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Nouveau mot de passe',
                    style: TextStyle(
                        fontSize: 28, fontWeight: FontWeight.w700, color: Color(0xFFBD7F66))),
                const SizedBox(height: 4),
                const Text(
                  'Entrez le code reçu par email et définissez votre nouveau mot de passe.',
                  style: TextStyle(color: Color(0xFF8B8173), fontSize: 14),
                ),
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
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _email,
                        keyboardType: TextInputType.emailAddress,
                        style: const TextStyle(color: Color(0xFF2C2B22)),
                        decoration: InputDecoration(
                          hintText: 'Email',
                          hintStyle: const TextStyle(color: Color(0xFFA69D8F)),
                          prefixIcon: const Icon(Icons.mail_outline_rounded, color: Color(0xFFBD7F66)),
                          filled: true,
                          fillColor: const Color(0xFFF8F6F3),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none),
                          enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none),
                          focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(18),
                              borderSide: const BorderSide(color: Color(0xFFBD7F66), width: 1.5)),
                        ),
                        validator: (v) => v?.isEmpty == true ? 'Email requis' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _code,
                        keyboardType: TextInputType.number,
                        maxLength: 4,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            color: Color(0xFF2C2B22),
                            fontSize: 24,
                            letterSpacing: 12,
                            fontWeight: FontWeight.w700),
                        decoration: InputDecoration(
                          hintText: '• • • •',
                          hintStyle: const TextStyle(color: Color(0xFFD2C9BC), letterSpacing: 12),
                          counterText: '',
                          filled: true,
                          fillColor: const Color(0xFFF8F6F3),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none),
                          enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none),
                          focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(18),
                              borderSide: const BorderSide(color: Color(0xFFBD7F66), width: 1.5)),
                        ),
                        validator: (v) =>
                            (v?.trim().length ?? 0) != 4 ? 'Code à 4 chiffres requis' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _password,
                        obscureText: _obscure,
                        style: const TextStyle(color: Color(0xFF2C2B22)),
                        decoration: InputDecoration(
                          hintText: 'Nouveau mot de passe',
                          hintStyle: const TextStyle(color: Color(0xFFA69D8F)),
                          prefixIcon: const Icon(Icons.lock_outline_rounded, color: Color(0xFFBD7F66)),
                          suffixIcon: IconButton(
                            icon: Icon(_obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                color: const Color(0xFFA69D8F)),
                            onPressed: () => setState(() => _obscure = !_obscure),
                          ),
                          filled: true,
                          fillColor: const Color(0xFFF8F6F3),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none),
                          enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none),
                          focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(18),
                              borderSide: const BorderSide(color: Color(0xFFBD7F66), width: 1.5)),
                        ),
                        validator: (v) => (v?.length ?? 0) < 8 ? '8 caractères minimum' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _confirm,
                        obscureText: _obscure,
                        style: const TextStyle(color: Color(0xFF2C2B22)),
                        decoration: InputDecoration(
                          hintText: 'Confirmer le mot de passe',
                          hintStyle: const TextStyle(color: Color(0xFFA69D8F)),
                          prefixIcon: const Icon(Icons.lock_outline_rounded, color: Color(0xFFBD7F66)),
                          filled: true,
                          fillColor: const Color(0xFFF8F6F3),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none),
                          enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none),
                          focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(18),
                              borderSide: const BorderSide(color: Color(0xFFBD7F66), width: 1.5)),
                        ),
                        validator: (v) => v != _password.text ? 'Les mots de passe ne correspondent pas' : null,
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
                              : const Text('Réinitialiser',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                        ),
                      ),
                    ],
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
