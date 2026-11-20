import 'dart:async';

import 'package:flutter/material.dart';
import 'package:medcin_app/core/errors/api_exception.dart';
import 'package:medcin_app/data/services/appointment_service.dart';
import 'package:medcin_app/domain/models/appointment.dart';
import 'package:medcin_app/presentation/screens/appointments/appointment_request_screen.dart';

class ParentAppointmentsScreen extends StatefulWidget {
  const ParentAppointmentsScreen({super.key});

  @override
  State<ParentAppointmentsScreen> createState() =>
      _ParentAppointmentsScreenState();
}

class _ParentAppointmentsScreenState extends State<ParentAppointmentsScreen> {
  List<Appointment> _appointments = [];
  bool _loading = true;
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
    if (!silent && mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final list = await AppointmentService.instance.fetchAppointments();
      if (!mounted) return;
      setState(() {
        _appointments = list;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _error = e.message;
          _loading = false;
        });
      }
    } on Exception {
      if (mounted) {
        setState(() {
          _error = 'Erreur de chargement.';
          _loading = false;
        });
      }
    }
  }

  Future<void> _cancel(Appointment a) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Annuler la demande ?'),
        content: Text(
            'Annuler la demande de rendez-vous pour ${a.childName} du ${_fmtDate(a)} ?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Non')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Oui, annuler',
                  style: TextStyle(color: Color(0xFFEF4444)))),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      final msg = await AppointmentService.instance.cancel(a.id);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(msg)));
      }
      _load();
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }

  String _fmtDate(Appointment a) {
    final d = a.scheduledAt;
    if (d == null) return '';
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year} à ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }

  Widget _statusChip(Appointment a) {
    final (label, bg, fg) = switch (a.status) {
      'pending' => ('En attente', const Color(0xFFFEF3C7), const Color(0xFFB45309)),
      'confirmed' => ('Confirmé', const Color(0xFFD1FAE5), const Color(0xFFBD7F66)),
      'done' => ('Terminé', const Color(0xFFE5E7EB), const Color(0xFF4B5563)),
      _ => ('Annulé', const Color(0xFFFEE2E2), const Color(0xFFEF4444)),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
          color: bg, borderRadius: BorderRadius.circular(999)),
      child: Text(label,
          style:
              TextStyle(color: fg, fontSize: 11, fontWeight: FontWeight.w700)),
    );
  }

  Widget _card(Appointment a) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
              color: const Color(0xFFBD7F66).withValues(alpha: 0.06),
              blurRadius: 20,
              offset: const Offset(0, 8)),
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(
            child: Text(a.childName,
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF2C2B22))),
          ),
          _statusChip(a),
        ]),
        const SizedBox(height: 8),
        Row(children: [
          const Icon(Icons.calendar_month_rounded,
              size: 16, color: Color(0xFFBD7F66)),
          const SizedBox(width: 6),
          Text(_fmtDate(a),
              style: const TextStyle(color: Color(0xFF8E7F68), fontSize: 13)),
          const SizedBox(width: 12),
          const Icon(Icons.medical_services_outlined,
              size: 16, color: Color(0xFFBD7F66)),
          const SizedBox(width: 6),
          Text(a.displayType,
              style: const TextStyle(color: Color(0xFF8E7F68), fontSize: 13)),
        ]),
        if (a.reason != null && a.reason!.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text('Motif : ${a.reason}',
              style: const TextStyle(color: Color(0xFF2C2B22), fontSize: 13)),
        ],
        if (a.isPending) ...[
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () => _cancel(a),
              icon: const Icon(Icons.cancel_outlined,
                  size: 16, color: Color(0xFFEF4444)),
              label: const Text('Annuler la demande',
                  style: TextStyle(color: Color(0xFFEF4444), fontSize: 12)),
            ),
          ),
        ],
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pending = _appointments.where((a) => a.isPending).toList();
    final others = _appointments.where((a) => !a.isPending).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8F5F2),
      appBar: AppBar(
        title: const Text('Mes rendez-vous',
            style: TextStyle(fontWeight: FontWeight.w700)),
        backgroundColor: const Color(0xFFBD7F66),
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final created = await Navigator.of(context).push<bool>(
            MaterialPageRoute(
                builder: (_) => const AppointmentRequestScreen()),
          );
          if (created == true) _load();
        },
        backgroundColor: const Color(0xFFBD7F66),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Prendre rendez-vous'),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFBD7F66)))
          : _error != null
              ? Center(child: Text(_error!))
              : RefreshIndicator(
                  onRefresh: _load,
                  color: const Color(0xFFBD7F66),
                  child: _appointments.isEmpty
                      ? ListView(children: const [
                          SizedBox(height: 160),
                          Center(
                            child: Padding(
                              padding: EdgeInsets.all(32),
                              child: Text(
                                'Aucun rendez-vous pour le moment.\nPrenez rendez-vous avec votre médecin.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    color: Color(0xFF8E7F68), fontSize: 15),
                              ),
                            ),
                          ),
                        ])
                      : ListView(
                          padding: const EdgeInsets.all(20),
                          children: [
                            if (pending.isNotEmpty) ...[
                              const Text('Demandes en attente',
                                  style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFFBD7F66))),
                              const SizedBox(height: 12),
                              ...pending.map(_card),
                              const SizedBox(height: 8),
                            ],
                            if (others.isNotEmpty) ...[
                              const Text('Historique',
                                  style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFFBD7F66))),
                              const SizedBox(height: 12),
                              ...others.map(_card),
                            ],
                          ],
                        ),
                ),
    );
  }
}
