import 'dart:async';

import 'package:flutter/material.dart';
import 'package:medcin_app/core/errors/api_exception.dart';
import 'package:medcin_app/data/repositories/child_repository.dart';
import 'package:medcin_app/data/services/appointment_service.dart';
import 'package:medcin_app/data/services/payment_service.dart';
import 'package:medcin_app/domain/models/child.dart';
import 'package:url_launcher/url_launcher.dart';

class AppointmentRequestScreen extends StatefulWidget {
  const AppointmentRequestScreen({super.key});

  @override
  State<AppointmentRequestScreen> createState() =>
      _AppointmentRequestScreenState();
}

class _AppointmentRequestScreenState extends State<AppointmentRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _reason = TextEditingController();
  final _message = TextEditingController();

  List<Child> _children = [];
  Child? _child;
  String _type = 'استقبال المولود والاعتناء به';
  DateTime? _date;
  String? _slot;
  List<String> _slots = [];
  bool _slotsLoading = false;
  bool _loadingChildren = true;
  bool _sending = false;
  String? _loadError;

  static const _types = [
    'استقبال المولود والاعتناء به',
    'المساعدة على الرضاعة الطبيعية',
    'القبض والنقوة اللارادية',
    'تأخر النمو',
    'التبول اللارادي',
    'تأخر الكلام',
    'التنوع الغذائي',
    'طيف التوحد',
    'فقدان الشهية والتغذية',
    'جلسات استماع للأمهات المرهقات',
  ];

  @override
  void initState() {
    super.initState();
    _loadChildren();
  }

  Future<void> _loadChildren() async {
    try {
      final children = await ChildRepository.list();
      setState(() {
        _children = children;
        _child = children.isNotEmpty ? children.first : null;
        _loadingChildren = false;
      });
    } on ApiException catch (e) {
      setState(() {
        _loadError = e.message;
        _loadingChildren = false;
      });
    } on Exception {
      setState(() {
        _loadError = 'Erreur de chargement.';
        _loadingChildren = false;
      });
    }
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date ?? now.add(const Duration(days: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 180)),
      selectableDayPredicate: (day) {
        if (day.weekday == DateTime.saturday ||
            day.weekday == DateTime.sunday) {
          return false;
        }
        return !day.isBefore(DateTime(now.year, now.month, now.day));
      },
      locale: const Locale('fr'),
    );
    if (picked == null) return;
    setState(() {
      _date = picked;
      _slot = null;
      _slots = [];
      _slotsLoading = true;
    });
    _loadSlots(picked);
  }

  Future<void> _loadSlots(DateTime date) async {
    try {
      final slots =
          await AppointmentService.instance.availableSlots(childId: _child!.id, date: date);
      if (mounted && _date == date) {
        setState(() {
          _slots = slots;
          _slotsLoading = false;
        });
      }
    } on Exception {
      if (mounted && _date == date) {
        setState(() {
          _slots = [];
          _slotsLoading = false;
        });
        _toast('Impossible de charger les créneaux.');
      }
    }
  }

  String get _dateLabel => _date == null
      ? 'Choisir une date'
      : '${_date!.day.toString().padLeft(2, '0')}/${_date!.month.toString().padLeft(2, '0')}/${_date!.year}';

  Future<void> _submit() async {
    if (_child == null) {
      _toast('Sélectionnez un enfant.');
      return;
    }
    if (_date == null || _slot == null) {
      _toast('Choisissez une date et un créneau disponible.');
      return;
    }
    final parts = _slot!.split(':');
    final scheduledAt = DateTime(
        _date!.year, _date!.month, _date!.day, int.parse(parts[0]), int.parse(parts[1]));
    if (scheduledAt.isBefore(DateTime.now())) {
      _toast('La date doit être dans le futur.');
      return;
    }

    setState(() => _sending = true);
    try {
      final data = await AppointmentService.instance.createAppointment(
        childId: _child!.id,
        scheduledAt: scheduledAt,
        type: _type,
        reason: _reason.text.trim(),
        notes: _message.text.trim(),
      );
      final paymentUrl = data['payment_url']?.toString();
      if (paymentUrl == null || paymentUrl.isEmpty) {
        throw ApiException(
          message: data['message']?.toString() ?? 'Lien de paiement indisponible.',
          statusCode: 500,
        );
      }
      if (!mounted) return;
      final launched = await launchUrl(
        Uri.parse(paymentUrl),
        mode: LaunchMode.externalApplication,
      );
      if (!mounted) return;
      setState(() => _sending = false);
      if (!launched) {
        _toast('Impossible d’ouvrir la page de paiement.');
        return;
      }
      final reference = PaymentService.referenceFromUrl(paymentUrl);
      if (reference != null) {
        unawaited(PaymentService.waitUntilFinished(reference).then((status) {
          if (!mounted) return;
          if (status == 'paid') {
            Navigator.of(context).pop(true);
            _toast('Rendez-vous payé et confirmé (500 DH).');
          }
        }));
      }
      return;
    } on ApiException catch (e) {
      _toast(e.message);
    } on Exception {
      _toast('Erreur de connexion au serveur.');
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  InputDecoration _decoGreen() => InputDecoration(
        filled: true,
        fillColor: const Color(0xFF2E7D32),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(color: Colors.white, width: 1.5)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      );

  InputDecoration _deco(String label) => InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Color(0xFFA69D8F)),
        floatingLabelStyle: const TextStyle(
            color: Color(0xFFBD7F66), fontWeight: FontWeight.w600),
        filled: true,
        fillColor: const Color(0xFFF8F6F3),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide:
                const BorderSide(color: Color(0xFFBD7F66), width: 1.5)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      );

  Widget _pickerTile(
          {required IconData icon,
          required String label,
          required VoidCallback onTap}) =>
      Expanded(
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F6F3),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(children: [
              Icon(icon, color: const Color(0xFFBD7F66), size: 20),
              const SizedBox(width: 10),
              Flexible(
                child: Text(label,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: Color(0xFF2C2B22), fontSize: 14)),
              ),
            ]),
          ),
        ),
      );

  @override
  void dispose() {
    _reason.dispose();
    _message.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F5F2),
      appBar: AppBar(
        title: const Text('Prendre rendez-vous',
            style: TextStyle(fontWeight: FontWeight.w700)),
        backgroundColor: const Color(0xFFBD7F66),
        foregroundColor: Colors.white,
      ),
      body: _loadingChildren
          ? const Center(
              child:
                  CircularProgressIndicator(color: Color(0xFFBD7F66)))
          : _loadError != null
              ? Center(child: Text(_loadError!))
              : _children.isEmpty
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: Text(
                          "Ajoutez d'abord un enfant à votre compte pour prendre rendez-vous.",
                          textAlign: TextAlign.center,
                          style:
                              TextStyle(color: Color(0xFF8E7F68), fontSize: 15),
                        ),
                      ),
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            DropdownButtonFormField<Child>(
                              initialValue: _child,
                              decoration: _deco('Enfant'),
                              items: _children
                                  .map((c) => DropdownMenuItem(
                                      value: c,
                                      child: Text(c.fullName,
                                          style: const TextStyle(
                                              color: Color(0xFF2C2B22)))))
                                  .toList(),
                              onChanged: (c) {
                                setState(() {
                                  _child = c;
                                  _slot = null;
                                });
                                if (_date != null) {
                                  setState(() {
                                    _slots = [];
                                    _slotsLoading = true;
                                  });
                                  _loadSlots(_date!);
                                }
                              },
                            ),
                            const SizedBox(height: 16),
                            const Padding(
                              padding: EdgeInsets.only(left: 4, bottom: 8),
                              child: Text('Type de rendez-vous',
                                  style: TextStyle(
                                      color: Color(0xFF2E7D32),
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700)),
                            ),
                            DropdownButtonFormField<String>(
                              initialValue: _type,
                              isExpanded: true,
                              style: const TextStyle(color: Colors.white),
                              dropdownColor: const Color(0xFF2E7D32),
                              decoration: _decoGreen(),
                              items: _types
                                  .map((t) => DropdownMenuItem(
                                      value: t,
                                      child: Text(t,
                                          style: const TextStyle(
                                              color: Colors.white))))
                                  .toList(),
                              onChanged: (t) => setState(
                                  () => _type = t ?? _types.first),
                            ),
                            const SizedBox(height: 16),
                            Row(children: [
                              _pickerTile(
                                  icon: Icons.calendar_month_rounded,
                                  label: _date == null ? 'Choisir une date (lun-ven)' : _dateLabel,
                                  onTap: _pickDate),
                            ]),
                            if (_date != null) ...[
                              const SizedBox(height: 14),
                              Row(
                                children: [
                                  const Icon(Icons.schedule_rounded,
                                      color: Color(0xFFBD7F66), size: 18),
                                  const SizedBox(width: 8),
                                  const Expanded(
                                    child: Text(
                                      'Créneaux disponibles',
                                      style: TextStyle(
                                          color: Color(0xFF2C2B22),
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700),
                                    ),
                                  ),
                                  if (_slotsLoading)
                                    const SizedBox(
                                        height: 16,
                                        width: 16,
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Color(0xFFBD7F66))),
                                ],
                              ),
                              const SizedBox(height: 10),
                              if (_slots.isEmpty && !_slotsLoading)
                                const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 8),
                                  child: Text('Aucun créneau libre ce jour-là.',
                                      style: TextStyle(
                                          color: Color(0xFF8E7F68),
                                          fontSize: 13)),
                                )
                              else
                                Wrap(
                                  spacing: 10,
                                  runSpacing: 10,
                                  children: _slots.map((s) {
                                    final selected = _slot == s;
                                    return GestureDetector(
                                      onTap: () =>
                                          setState(() => _slot = s),
                                      child: AnimatedContainer(
                                        duration:
                                            const Duration(milliseconds: 150),
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 16, vertical: 10),
                                        decoration: BoxDecoration(
                                          color: selected
                                              ? const Color(0xFFBD7F66)
                                              : const Color(0xFFF8F6F3),
                                          borderRadius:
                                              BorderRadius.circular(14),
                                          border: Border.all(
                                              color: selected
                                                  ? const Color(0xFFBD7F66)
                                                  : const Color(0xFFE4DDD2)),
                                        ),
                                        child: Text(
                                          s,
                                          style: TextStyle(
                                            color: selected
                                                ? Colors.white
                                                : const Color(0xFF2C2B22),
                                            fontWeight: FontWeight.w600,
                                            fontSize: 13.5,
                                          ),
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                            ],
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _reason,
                              style: const TextStyle(color: Color(0xFF2C2B22)),
                              decoration: _deco('Motif (ex. fièvre, suivi…)'),
                              maxLength: 255,
                            ),
                            TextFormField(
                              controller: _message,
                              style: const TextStyle(color: Color(0xFF2C2B22)),
                              decoration: _deco('Message pour le médecin'),
                              maxLines: 4,
                            ),
                            const SizedBox(height: 24),
                            Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: _sending ? null : _submit,
                                borderRadius: BorderRadius.circular(30),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 15),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFBD7F66),
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                  child: Center(
                                    child: _sending
                                        ? const SizedBox(
                                            height: 20,
                                            width: 20,
                                            child: CircularProgressIndicator(
                                                strokeWidth: 2.5,
                                                color: Colors.white))
                                        : const Text('Payer 500 DH · 15 min',
                                            style: TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.w700,
                                                color: Colors.white)),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
    );
  }
}
