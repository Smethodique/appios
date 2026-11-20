import 'dart:async';

import 'package:flutter/material.dart';
import 'package:medcin_app/core/errors/api_exception.dart';
import 'package:medcin_app/data/services/appointment_service.dart';
import 'package:medcin_app/domain/models/appointment.dart';

class DoctorAppointmentsScreen extends StatefulWidget {
  const DoctorAppointmentsScreen({super.key});

  @override
  State<DoctorAppointmentsScreen> createState() =>
      _DoctorAppointmentsScreenState();
}

class _DoctorAppointmentsScreenState extends State<DoctorAppointmentsScreen> {
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

  String _fmtDate(Appointment a) {
    final d = a.scheduledAt;
    if (d == null) return '';
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year} à ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _confirm(Appointment a) async {
    DateTime date = a.scheduledAt ?? DateTime.now().add(const Duration(days: 1));
    TimeOfDay time = a.scheduledAt != null
        ? TimeOfDay.fromDateTime(a.scheduledAt!)
        : const TimeOfDay(hour: 9, minute: 0);

    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: const Color(0xFF131A2E),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('Confirmer le rendez-vous',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            Text(
                'Ajustez la date/heure si nécessaire pour ${a.childName}.',
                textAlign: TextAlign.center,
                style:
                    const TextStyle(color: Colors.white54, fontSize: 13)),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: ctx,
                      initialDate: date,
                      firstDate: DateTime.now(),
                      lastDate:
                          DateTime.now().add(const Duration(days: 365)),
                    );
                    if (picked != null) setSheet(() => date = picked);
                  },
                  icon: const Icon(Icons.calendar_month_rounded, size: 18),
                  label: Text(
                      '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}'),
                  style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white24),
                      padding: const EdgeInsets.symmetric(vertical: 14)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final picked = await showTimePicker(
                        context: ctx, initialTime: time);
                    if (picked != null) setSheet(() => time = picked);
                  },
                  icon: const Icon(Icons.access_time_rounded, size: 18),
                  label: Text(time.format(ctx)),
                  style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white24),
                      padding: const EdgeInsets.symmetric(vertical: 14)),
                ),
              ),
            ]),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFBD7F66),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text('Confirmer',
                    style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ),
          ]),
        ),
      ),
    );
    if (confirmed != true) return;

    final scheduledAt =
        DateTime(date.year, date.month, date.day, time.hour, time.minute);
    try {
      final msg = await AppointmentService.instance
          .confirm(a.id, scheduledAt: scheduledAt);
      _toast(msg);
      _load();
    } on ApiException catch (e) {
      _toast(e.message);
    }
  }

  Future<void> _refuse(Appointment a) async {
    final reasonCtrl = TextEditingController();
    final refused = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF131A2E),
        title: const Text('Refuser la demande ?',
            style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: reasonCtrl,
          maxLines: 2,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'Motif (optionnel)',
            hintStyle: TextStyle(color: Colors.white38),
            enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.white24)),
            focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.white54)),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Retour',
                  style: TextStyle(color: Colors.white54))),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Refuser',
                  style: TextStyle(color: Color(0xFFEF4444)))),
        ],
      ),
    );
    if (refused != true) return;
    try {
      final msg = await AppointmentService.instance
          .cancel(a.id, notes: reasonCtrl.text.trim());
      _toast(msg);
      _load();
    } on ApiException catch (e) {
      _toast(e.message);
    }
  }

  Widget _pendingCard(Appointment a) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF131A2E),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(
            child: Text(a.childName,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w800)),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(999)),
            child: const Text('En attente',
                style: TextStyle(
                    color: Color(0xFFFBBF24),
                    fontSize: 11,
                    fontWeight: FontWeight.w700)),
          ),
        ]),
        if (a.parentName != null && a.parentName!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text('Parent : ${a.parentName}',
                style: const TextStyle(color: Colors.white54, fontSize: 12)),
          ),
        const SizedBox(height: 8),
        Row(children: [
          const Icon(Icons.calendar_month_rounded,
              size: 16, color: Color(0xFFF59E0B)),
          const SizedBox(width: 6),
          Text(_fmtDate(a),
              style:
                  const TextStyle(color: Colors.white70, fontSize: 13)),
          const SizedBox(width: 12),
          Text(a.displayType,
              style:
                  const TextStyle(color: Colors.white54, fontSize: 13)),
        ]),
        if (a.reason != null && a.reason!.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text('Motif : ${a.reason}',
              style:
                  const TextStyle(color: Colors.white70, fontSize: 13)),
        ],
        if (a.notes != null && a.notes!.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text('« ${a.notes} »',
              style: const TextStyle(
                  color: Colors.white38,
                  fontSize: 12,
                  fontStyle: FontStyle.italic)),
        ],
        const SizedBox(height: 14),
        Row(children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => _confirm(a),
              icon: const Icon(Icons.check_rounded, size: 18),
              label: const Text('Confirmer'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFBD7F66),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => _refuse(a),
              icon: const Icon(Icons.close_rounded, size: 18),
              label: const Text('Refuser'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFEF4444),
                side: const BorderSide(color: Color(0xFFEF4444)),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
        ]),
      ]),
    );
  }

  Widget _upcomingCard(Appointment a) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF131A2E),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Row(children: [
        const Icon(Icons.event_available_rounded,
            color: Color(0xFF34D399), size: 26),
        const SizedBox(width: 14),
        Expanded(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(a.childName,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 3),
            Text('${_fmtDate(a)} — ${a.displayType}',
                style: const TextStyle(
                    color: Colors.white54, fontSize: 12.5)),
          ]),
        ),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pending = _appointments.where((a) => a.isPending).toList();
    final upcoming = _appointments
        .where((a) =>
            a.isConfirmed &&
            (a.scheduledAt?.isAfter(DateTime.now()) ?? false))
        .toList();

    return Scaffold(
      backgroundColor: const Color(0xFF0A0F1D),
      appBar: AppBar(
        title: const Text('Rendez-vous',
            style: TextStyle(fontWeight: FontWeight.w700)),
        backgroundColor: const Color(0xFF0A0F1D),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _loading
          ? const Center(
              child:
                  CircularProgressIndicator(color: Color(0xFFF59E0B)))
          : _error != null
              ? Center(
                  child: Text(_error!,
                      style: const TextStyle(color: Colors.white54)))
              : RefreshIndicator(
                  onRefresh: _load,
                  color: const Color(0xFFF59E0B),
                  child: ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      if (pending.isNotEmpty) ...[
                        const Text('Demandes en attente',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w800)),
                        const SizedBox(height: 12),
                        ...pending.map(_pendingCard),
                        const SizedBox(height: 12),
                      ],
                      if (upcoming.isNotEmpty) ...[
                        const Text('À venir',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w800)),
                        const SizedBox(height: 12),
                        ...upcoming.map(_upcomingCard),
                      ],
                      if (pending.isEmpty && upcoming.isEmpty)
                        const Padding(
                          padding: EdgeInsets.only(top: 120),
                          child: Center(
                            child: Text(
                              'Aucune demande de rendez-vous\npour le moment.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  color: Colors.white38, fontSize: 15),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
    );
  }
}
