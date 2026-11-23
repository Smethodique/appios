import 'dart:async';

import 'package:flutter/material.dart';
import 'package:medcin_app/config/api_config.dart';
import 'package:medcin_app/data/services/payment_service.dart';
import 'package:medcin_app/domain/models/subscription.dart';
import 'package:medcin_app/core/errors/api_exception.dart';
import 'package:medcin_app/core/network/api_service.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  Subscription? _current;
  List<Plan> _plans = [];
  List<Map<String, dynamic>> _invoices = [];
  final Map<String, int> _selectedDuration = {};
  bool _loading = true;
  String? _subscribingPlan;
  String? _error;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _load();
    _refreshTimer = Timer.periodic(const Duration(seconds: 10), (_) => _load(silent: true));
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _load({bool silent = false}) async {
    if (!silent && mounted) setState(() => _loading = true);
    try {
      final subData = await ApiService.get(ApiConfig.subscriptionsEndpoint);
      final plansData = await ApiService.get(ApiConfig.plansEndpoint);
      final invoicesData = await ApiService.get(ApiConfig.invoicesEndpoint);
      if (!mounted) return;
      setState(() {
        _current = subData['current'] != null
            ? Subscription.fromJson(subData['current'])
            : null;
        final plansList = plansData is Map ? plansData['plans'] : null;
        _plans = (plansList as List? ?? [])
            .map((j) => Plan.fromJson(j as Map<String, dynamic>))
            .toList();
        for (final p in _plans) {
          _selectedDuration.putIfAbsent(p.key, () => p.tiers.first.durationMonths);
        }
        _invoices = (invoicesData as List? ?? [])
            .map((j) => j as Map<String, dynamic>)
            .toList();
      });
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (!silent && mounted) setState(() => _loading = false);
    }
  }

  Future<void> _subscribe(Plan plan, PlanTier tier) async {
    setState(() => _subscribingPlan = plan.key);
    try {
      final data = await ApiService.post(
        ApiConfig.subscribeEndpoint,
        body: {
          'plan': plan.key,
          'duration_months': tier.durationMonths,
          'return_url': 'medcinapp://payment',
        },
      );
      final paymentUrl = data['payment_url'] as String?;
      if (paymentUrl == null) {
        throw ApiException(message: 'URL de paiement manquante', statusCode: 0);
      }
      if (!mounted) return;
      final launched = await launchUrl(
        Uri.parse(paymentUrl),
        mode: LaunchMode.externalApplication,
      );
      if (!mounted) return;
      setState(() => _subscribingPlan = null);
      if (!launched) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Impossible d’ouvrir la page de paiement.')),
        );
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Paiement lancé — vérification automatique.')),
      );
      final reference = PaymentService.referenceFromUrl(paymentUrl);
      if (reference != null) {
        unawaited(PaymentService.waitUntilFinished(reference).then((status) async {
          if (!mounted) return;
          if (status == 'paid') {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Paiement accepté, abonnement activé.')),
            );
          }
          await _load();
        }));
      }
      return;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) setState(() => _subscribingPlan = null);
    }
  }

  Future<void> _cancel() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Résilier ?'),
        content: const Text('Votre abonnement restera actif jusqu\'à la fin de la période.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Non')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Oui')),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await ApiService.post(ApiConfig.cancelSubscriptionEndpoint);
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F1EA),
      appBar: AppBar(
        title: const Text('Mon abonnement'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFFBD7F66),
        elevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFBD7F66)))
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  if (_error != null) _errorCard(),
                  if (_current != null)
                    _currentCard()
                  else
                    _freeCard(),
                  const SizedBox(height: 24),
                  const Text('Plans',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Color(0xFFBD7F66))),
                  const SizedBox(height: 12),
                  ..._plans.map((p) => _planCard(p)),
                  if (_invoices.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    const Text('Factures',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Color(0xFFBD7F66))),
                    const SizedBox(height: 12),
                    ..._invoices.map(_invoiceCard),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _errorCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFECACA),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(_error!, style: const TextStyle(color: Color(0xFFEF4444))),
    );
  }

  Widget _freeCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
              color: const Color(0xFFBD7F66).withValues(alpha: 0.05),
              blurRadius: 20,
              offset: const Offset(0, 6)),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFBD7F66).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.verified_user_rounded,
                color: Color(0xFFBD7F66), size: 26),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Plan Gratuit',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFBD7F66))),
                SizedBox(height: 4),
                Text('Vous utilisez actuellement le plan gratuit.',
                    style: TextStyle(color: Color(0xFF8B8173), fontSize: 12.5)),
                SizedBox(height: 2),
                Text('Passez à Family pour débloquer tous les avantages.',
                    style: TextStyle(color: Color(0xFF8B8173), fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _currentCard() {
    final plan = _plans.where((p) => p.key == _current!.plan).firstOrNull;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [BoxShadow(color: const Color(0xFFBD7F66).withValues(alpha: 0.08), blurRadius: 20, offset: const Offset(0, 6))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.verified_rounded, color: Color(0xFFBD7F66)),
              const SizedBox(width: 8),
              Text(plan?.name ?? _current!.plan,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFFBD7F66))),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: const Color(0xFFD1FAE5), borderRadius: BorderRadius.circular(12)),
                child: const Text('Actif', style: TextStyle(color: Color(0xFFBD7F66), fontSize: 12, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text('Expire le ${_current!.endsAt != null ? DateFormat('dd/MM/yyyy').format(_current!.endsAt!) : '-'}',
              style: const TextStyle(color: Color(0xFF8B8173))),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: _cancel,
              icon: const Icon(Icons.close_rounded, size: 18),
              label: const Text('Résilier'),
              style: TextButton.styleFrom(foregroundColor: const Color(0xFFEF4444)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _planCard(Plan plan) {
    final isCurrent = _current?.plan == plan.key;
    final selected = _selectedDuration[plan.key] ?? plan.tiers.first.durationMonths;
    final tier = plan.tiers.firstWhere(
      (t) => t.durationMonths == selected,
      orElse: () => plan.tiers.first,
    );
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: isCurrent ? const Color(0xFFBD7F66) : Colors.transparent, width: 2),
        boxShadow: [BoxShadow(color: const Color(0xFFBD7F66).withValues(alpha: 0.05), blurRadius: 20, offset: const Offset(0, 6))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(plan.name,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFFBD7F66))),
              const Spacer(),
              Text('${tier.priceDh.toStringAsFixed(0)} MAD',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFFBD7F66))),
            ],
          ),
          const SizedBox(height: 6),
          Text(plan.description, style: const TextStyle(color: Color(0xFF8B8173), fontSize: 13)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: plan.tiers.map((t) {
              final active = t.durationMonths == selected;
              return ChoiceChip(
                label: Text(t.label),
                selected: active,
                onSelected: (_) => setState(() => _selectedDuration[plan.key] = t.durationMonths),
                selectedColor: const Color(0xFFBD7F66),
                labelStyle: TextStyle(
                  color: active ? Colors.white : const Color(0xFFBD7F66),
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                ),
                backgroundColor: const Color(0xFFBD7F66).withValues(alpha: 0.08),
              );
            }).toList(),
          ),
          const SizedBox(height: 10),
          ...plan.features.map((f) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle_rounded, size: 16, color: Color(0xFFBD7F66)),
                    const SizedBox(width: 8),
                    Text(f, style: const TextStyle(color: Color(0xFF2C2B22), fontSize: 13)),
                  ],
                ),
              )),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _subscribingPlan == plan.key || isCurrent ? null : () => _subscribe(plan, tier),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFBD7F66),
                foregroundColor: Colors.white,
                disabledBackgroundColor: const Color(0xFFBD7F66),
                disabledForegroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: _subscribingPlan == plan.key
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : Text(isCurrent ? 'Abonnement actif' : 'S\'abonner'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _invoiceCard(Map<String, dynamic> invoice) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.receipt_long_rounded, color: Color(0xFFBD7F66)),
          const SizedBox(width: 12),
          Expanded(
            child: Text('Facture #${invoice['id']} — ${invoice['issued_at'] ?? ''}',
                style: const TextStyle(color: Color(0xFF2C2B22), fontSize: 13)),
          ),
          Text('${invoice['amount']} MAD',
              style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFFBD7F66))),
        ],
      ),
    );
  }
}
