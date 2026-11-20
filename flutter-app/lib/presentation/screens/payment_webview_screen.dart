import 'dart:async';

import 'package:flutter/material.dart';
import 'package:medcin_app/data/services/payment_service.dart';
import 'package:url_launcher/url_launcher.dart';

class PaymentWebViewScreen extends StatefulWidget {
  final String paymentUrl;

  const PaymentWebViewScreen({super.key, required this.paymentUrl});

  @override
  State<PaymentWebViewScreen> createState() => _PaymentWebViewScreenState();
}

class _PaymentWebViewScreenState extends State<PaymentWebViewScreen>
    with WidgetsBindingObserver {
  String? _error;
  String? _reference;
  Timer? _timer;
  bool _finished = false;
  bool _paid = false;
  bool _failed = false;
  int _failures = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _reference = Uri.tryParse(widget.paymentUrl)?.queryParameters['ref'];
    _open();
    _check();
    _timer = Timer.periodic(const Duration(seconds: 4), (_) => _check());
  }

  @override
  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _check();
  }

  Future<void> _open() async {
    try {
      final uri = Uri.parse(widget.paymentUrl);
      final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!opened && mounted) {
        setState(() => _error = 'Impossible d’ouvrir la page de paiement.');
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    }
  }

  Future<void> _check() async {
    if (_finished) return;
    final reference = _reference;
    if (reference == null || reference.isEmpty) {
      if (mounted) {
        setState(() => _error = 'Référence de paiement introuvable.');
      }
      return;
    }

    final status = await PaymentService.check(reference);
    if (!mounted || _finished) return;

    if (status == null) {
      _failures++;
      if (_failures >= 3) {
        setState(() => _error = PaymentService.lastError ??
            'Impossible de vérifier le paiement automatiquement.');
      }
      return;
    }

    _failures = 0;
    if (_error != null && status == 'pending' && mounted) {
      setState(() => _error = null);
    }
    if (status == 'pending') return;

    _finished = true;
    _timer?.cancel();

    if (status == 'paid') {
      setState(() => _paid = true);
      Future.delayed(const Duration(seconds: 5), () {
        if (mounted) Navigator.of(context).pop('success');
      });
      return;
    }

    setState(() => _failed = true);
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) Navigator.of(context).pop('failed');
    });
  }

  Widget _resultOverlay(bool success) {
    return Container(
      color: success ? const Color(0xFF16A34A) : const Color(0xFFF59E0B),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            success ? Icons.check_circle_rounded : Icons.info_rounded,
            color: Colors.white,
            size: 90,
          ),
          const SizedBox(height: 18),
          Text(
            success ? 'Paiement confirmé' : 'Paiement non effectué',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            success
                ? 'Votre rendez-vous est confirmé.'
                : 'Vous pouvez réessayer quand vous voulez.',
            style: const TextStyle(color: Colors.white, fontSize: 15),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Paiement sécurisé'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFFBD7F66),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.of(context).pop('failed'),
        ),
      ),
      body: Stack(
        children: [
          Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_error == null && !_paid && !_failed)
                    const CircularProgressIndicator(color: Color(0xFFBD7F66))
                  else if (!_paid && !_failed)
                    const Icon(Icons.error_outline, color: Colors.red, size: 44),
                  const SizedBox(height: 20),
                  Text(
                    _error ??
                        'La page de paiement sécurisé s’ouvre dans votre navigateur.\n'
                            'Le résultat sera détecté automatiquement.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: _error == null ? Colors.black87 : Colors.red,
                    ),
                  ),
                  if (_error != null)
                    const SizedBox(height: 24),
                  if (_error != null)
                    ElevatedButton.icon(
                      onPressed: _open,
                      icon: const Icon(Icons.open_in_browser),
                      label: const Text('Rouvrir la page de paiement'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2E7D32),
                        foregroundColor: Colors.white,
                      ),
                    ),
                ],
              ),
            ),
          ),
          if (_paid) _resultOverlay(true),
          if (_failed) _resultOverlay(false),
        ],
      ),
    );
  }
}
