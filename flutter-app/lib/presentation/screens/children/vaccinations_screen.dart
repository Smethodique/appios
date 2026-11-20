import 'package:flutter/material.dart';
import 'package:medcin_app/data/repositories/vaccination_repository.dart';
import 'package:medcin_app/domain/models/vaccination.dart';
import 'package:medcin_app/utils/formatters.dart';
import 'package:table_calendar/table_calendar.dart';

class VaccinationsScreen extends StatefulWidget {
  final int childId;
  const VaccinationsScreen({super.key, required this.childId});

  @override
  State<VaccinationsScreen> createState() => _VaccinationsScreenState();
}

class _VaccinationsScreenState extends State<VaccinationsScreen> {
  List<Vaccination> _vaccinations = [];
  List<VaccineScheduleItem> _schedule = [];

  bool _loading = true;
  String? _error;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

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
      final data = await VaccinationRepository.childData(widget.childId);
      if (mounted) {
        setState(() {
          _vaccinations = data.vaccinations
              .where((v) => v.childId == widget.childId)
              .toList();
          _schedule = data.schedule;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  DateTime _normalize(DateTime d) => DateTime(d.year, d.month, d.day);

  List<Vaccination> _eventsFor(DateTime day) {
    final d = _normalize(day);
    return _vaccinations.where((v) {
      final s = v.scheduledDateTime;
      final a = v.administeredDateTime;
      return (s != null && _normalize(s) == d) ||
          (a != null && _normalize(a) == d);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final due = _schedule.where((s) => !s.isDone).toList();
    final done = _schedule.where((s) => s.isDone).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F1EA),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFBD7F66)))
          : RefreshIndicator(
              onRefresh: _load,
              color: const Color(0xFFBD7F66),
              child: ListView(
                padding: const EdgeInsets.only(bottom: 40),
                children: [
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(_error!,
                          style: const TextStyle(color: Color(0xFFEF4444))),
                    ),
                  Container(
                    margin: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [
                        BoxShadow(
                            color: const Color(0xFFBD7F66).withValues(alpha: 0.06),
                            blurRadius: 20,
                            offset: const Offset(0, 6)),
                      ],
                    ),
                    child: TableCalendar<Vaccination>(
                      firstDay: DateTime(DateTime.now().year - 1),
                      lastDay: DateTime(DateTime.now().year + 2),
                      focusedDay: _focusedDay,
                      selectedDayPredicate: (day) =>
                          _selectedDay != null && isSameDay(day, _selectedDay!),
                      onDaySelected: (selected, focused) {
                        setState(() {
                          _selectedDay = selected;
                          _focusedDay = focused;
                        });
                      },
                      onPageChanged: (focused) => _focusedDay = focused,
                      eventLoader: _eventsFor,
                      availableCalendarFormats: const {CalendarFormat.month: 'Mois'},
                      calendarFormat: CalendarFormat.month,
                      startingDayOfWeek: StartingDayOfWeek.monday,
                      headerStyle: const HeaderStyle(
                        formatButtonVisible: false,
                        titleCentered: true,
                      ),
                      calendarBuilders: CalendarBuilders(
                        markerBuilder: (context, day, events) {
                          if (events.isEmpty) return const SizedBox.shrink();
                          return Positioned(
                            bottom: 1,
                            child: Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                color: Color(0xFFBD7F66),
                                shape: BoxShape.circle,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.fromLTRB(20, 10, 20, 6),
                    child: Text('Vaccins recommandés',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFFBD7F66))),
                  ),
                  if (due.isEmpty && done.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(
                        child: Text('Aucun vaccin recommandé.',
                            style: TextStyle(color: Color(0xFFA69D8F))),
                      ),
                    ),
                  ...due.map((s) => _scheduleCard(s)),
                  if (due.isNotEmpty && done.isNotEmpty)
                    const Padding(
                      padding: EdgeInsets.fromLTRB(20, 14, 20, 6),
                      child: Text('Déjà administrés',
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFFBD7F66))),
                    ),
                  ...done.map((s) => _scheduleCard(s)),
                  if (_vaccinations.isNotEmpty) ...[
                    const Padding(
                      padding: EdgeInsets.fromLTRB(20, 14, 20, 6),
                      child: Text('Dossier du médecin',
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFFBD7F66))),
                    ),
                    ..._vaccinations.map((v) => _vaccineCard(v)),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _scheduleCard(VaccineScheduleItem s) {
    final color = s.isDone
        ? const Color(0xFFBD7F66)
        : (s.isOverdue
            ? const Color(0xFFEF4444)
            : (s.isDue ? const Color(0xFFC4953A) : const Color(0xFF8B8173)));
    final dueAt = s.dueDate;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: const Color(0xFFBD7F66).withValues(alpha: 0.05),
              blurRadius: 14,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              s.isDone ? Icons.check_circle_rounded : Icons.vaccines_rounded,
              color: color,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${s.vaccine} · ${s.dose}',
                    style: const TextStyle(
                        color: Color(0xFF2C2B22),
                        fontWeight: FontWeight.w700,
                        fontSize: 15)),
                const SizedBox(height: 2),
                Text(
                  dueAt != null
                      ? '${s.age} · dû le ${Formatters.date(dueAt)}'
                      : s.age,
                  style: const TextStyle(color: Color(0xFF8B8173), fontSize: 12.5),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(s.statusLabel,
                style: TextStyle(
                    color: color, fontSize: 11, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Widget _vaccineCard(Vaccination v) {
    final date = v.isAdministered ? v.administeredDate : v.scheduledDate;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: const Color(0xFFBD7F66).withValues(alpha: 0.05),
              blurRadius: 14,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: _statusColor(v).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(_statusIcon(v), color: _statusColor(v)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(v.vaccineName,
                    style: const TextStyle(
                        color: Color(0xFF2C2B22),
                        fontWeight: FontWeight.w700,
                        fontSize: 15)),
                const SizedBox(height: 2),
                Text('${v.statusLabel} · ${Formatters.date(date)}',
                    style: const TextStyle(color: Color(0xFF8B8173), fontSize: 12.5)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: _statusColor(v).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(v.statusLabel,
                style: TextStyle(
                    color: _statusColor(v), fontSize: 11, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Color _statusColor(Vaccination v) {
    if (v.isAdministered) return const Color(0xFFBD7F66);
    if (v.isMissed) return const Color(0xFFEF4444);
    return const Color(0xFFC4953A);
  }

  IconData _statusIcon(Vaccination v) {
    if (v.isAdministered) return Icons.check_circle_rounded;
    if (v.isMissed) return Icons.cancel_rounded;
    return Icons.schedule_rounded;
  }
}