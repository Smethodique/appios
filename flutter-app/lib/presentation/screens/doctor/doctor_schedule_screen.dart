import 'package:flutter/material.dart';
import 'package:medcin_app/data/services/appointment_service.dart';

class DoctorScheduleScreen extends StatefulWidget {
  const DoctorScheduleScreen({super.key});

  @override
  State<DoctorScheduleScreen> createState() => _DoctorScheduleScreenState();
}

class _DoctorScheduleScreenState extends State<DoctorScheduleScreen> {
  List<Map<String, dynamic>> _days = [];
  bool _loading = true;
  bool _saving = false;
  String? _error;

  static const _labels = [
    'Lundi',
    'Mardi',
    'Mercredi',
    'Jeudi',
    'Vendredi',
    'Samedi',
    'Dimanche',
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final days = await AppointmentService.instance.fetchMySchedule();
      if (mounted) setState(() => _days = days);
    } on Exception {
      if (mounted) setState(() => _error = 'Erreur de chargement.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _pickHours(int index) async {
    final day = _days[index];
    TimeOfDay start = const TimeOfDay(hour: 9, minute: 0);
    TimeOfDay end = const TimeOfDay(hour: 17, minute: 0);
    final s = day['start_time'] as String?;
    final e = day['end_time'] as String?;
    if (s != null && s.isNotEmpty) {
      final p = s.split(':');
      start = TimeOfDay(hour: int.parse(p[0]), minute: int.parse(p[1]));
    }
    if (e != null && e.isNotEmpty) {
      final p = e.split(':');
      end = TimeOfDay(hour: int.parse(p[0]), minute: int.parse(p[1]));
    }

    final picked = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text('${_labels[index]} — Horaires',
                style: const TextStyle(
                    color: Color(0xFFBD7F66),
                    fontSize: 17,
                    fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            const Text('Laissez le jour vide pour fermer.',
                style: TextStyle(color: Color(0xFF8B8173), fontSize: 12)),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final p = await showTimePicker(context: ctx, initialTime: start);
                    if (p != null) setSheet(() => start = p);
                  },
                  icon: const Icon(Icons.play_arrow_rounded, size: 18),
                  label: Text('Début ${start.format(ctx)}'),
                  style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFBD7F66),
                      side: const BorderSide(color: Color(0xFFC9D6CE)),
                      padding: const EdgeInsets.symmetric(vertical: 14)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final p = await showTimePicker(context: ctx, initialTime: end);
                    if (p != null) setSheet(() => end = p);
                  },
                  icon: const Icon(Icons.stop_rounded, size: 18),
                  label: Text('Fin ${end.format(ctx)}'),
                  style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFBD7F66),
                      side: const BorderSide(color: Color(0xFFC9D6CE)),
                      padding: const EdgeInsets.symmetric(vertical: 14)),
                ),
              ),
            ]),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Fermer le jour',
                      style: TextStyle(color: Color(0xFFEF4444))),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    final d = _days[index];
                    d['start_time'] =
                        '${start.hour.toString().padLeft(2, '0')}:${start.minute.toString().padLeft(2, '0')}';
                    d['end_time'] =
                        '${end.hour.toString().padLeft(2, '0')}:${end.minute.toString().padLeft(2, '0')}';
                    Navigator.pop(ctx, true);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFBD7F66),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('Enregistrer',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
            ]),
          ]),
        ),
      ),
    );
    if (!mounted || picked == null) return;
    if (!picked) {
      setState(() {
        _days[index]['start_time'] = null;
        _days[index]['end_time'] = null;
      });
      return;
    }
    setState(() => _days = List.of(_days));
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final cleanDays = _days
          .map((d) => {
                'day_of_week': d['day_of_week'],
                'start_time': d['start_time'] as String?,
                'end_time': d['end_time'] as String?,
                'slot_minutes': d['slot_minutes'] ?? 30,
              })
          .toList();
      final msg = await AppointmentService.instance.updateMySchedule(cleanDays);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(msg)));
      }
    } on Exception {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Erreur d\'enregistrement.')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _clearDay(int index) async {
    setState(() {
      _days[index]['start_time'] = null;
      _days[index]['end_time'] = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F1EA),
      appBar: AppBar(
        title: const Text('Mon planning',
            style: TextStyle(fontWeight: FontWeight.w700)),
        backgroundColor: const Color(0xFFBD7F66),
        foregroundColor: Colors.white,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFBD7F66)))
          : _error != null
              ? Center(child: Text(_error!))
              : ListView.separated(
                  padding: const EdgeInsets.all(20),
                  itemCount: _days.length + 1,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, i) {
                    if (i == _days.length) {
                      return ElevatedButton.icon(
                        onPressed: _saving ? null : _save,
                        icon: const Icon(Icons.save_rounded, size: 18),
                        label: Text(_saving ? 'Enregistrement…' : 'Enregistrer le planning'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFBD7F66),
                          foregroundColor: Colors.white,
                          disabledBackgroundColor:
                              const Color(0xFFBD7F66).withValues(alpha: 0.6),
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                        ),
                      );
                    }
                    final d = _days[i];
                    final start = d['start_time'] as String?;
                    final end = d['end_time'] as String?;
                    final enabled = start != null && end != null;
                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                              color: const Color(0xFFBD7F66)
                                  .withValues(alpha: 0.05),
                              blurRadius: 14,
                              offset: const Offset(0, 4)),
                        ],
                      ),
                      child: Row(children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(_labels[i],
                                  style: const TextStyle(
                                      color: Color(0xFF2C2B22),
                                      fontWeight: FontWeight.w700,
                                      fontSize: 15)),
                              const SizedBox(height: 3),
                              Text(
                                enabled ? '$start – $end' : 'Fermé',
                                style: TextStyle(
                                  color: enabled
                                      ? const Color(0xFFBD7F66)
                                      : const Color(0xFF8B8173),
                                  fontSize: 13,
                                  fontWeight:
                                      enabled ? FontWeight.w600 : FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (enabled)
                          IconButton(
                            tooltip: 'Fermer ce jour',
                            onPressed: () => _clearDay(i),
                            icon: const Icon(Icons.close_rounded,
                                color: Color(0xFFEF4444), size: 20),
                          ),
                        IconButton(
                          tooltip: 'Modifier',
                          onPressed: () => _pickHours(i),
                          icon: const Icon(Icons.edit_rounded,
                              color: Color(0xFFBD7F66), size: 20),
                        ),
                      ]),
                    );
                  },
                ),
    );
  }
}