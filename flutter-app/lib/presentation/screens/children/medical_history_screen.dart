import 'package:flutter/material.dart';
import 'package:medcin_app/data/repositories/child_repository.dart';
import 'package:medcin_app/domain/models/medical_history.dart';
import 'package:medcin_app/utils/formatters.dart';

class MedicalHistoryScreen extends StatefulWidget {
  final int childId;
  const MedicalHistoryScreen({super.key, required this.childId});

  @override
  State<MedicalHistoryScreen> createState() => _MedicalHistoryScreenState();
}

class _MedicalHistoryScreenState extends State<MedicalHistoryScreen> {
  MedicalHistory? _history;
  bool _loading = true;
  String? _error;

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
      final history = await ChildRepository.medicalHistory(widget.childId);
      if (mounted) setState(() => _history = history);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F1EA),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFBD7F66)))
          : RefreshIndicator(
              onRefresh: _load,
              color: const Color(0xFFBD7F66),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                children: [
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(_error!,
                          style: const TextStyle(color: Color(0xFFEF4444))),
                    ),
                  if (_history?.isEmpty ?? true)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 80),
                      child: Center(
                        child: Text(
                          'Aucun antécédent médical pour le moment.\nLes consultations, ordonnances et allergies apparaîtront ici.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Color(0xFFA69D8F)),
                        ),
                      ),
                    ),
                  if ((_history?.consultations.isNotEmpty ?? false))
                    _section(
                      Icons.medical_information_rounded,
                      'Consultations',
                      _history!.consultations
                          .map((c) => _EventTile(
                                icon: Icons.favorite_rounded,
                                color: const Color(0xFFBD7F66),
                                date: Formatters.date(c.date),
                                title: _doctor(c.doctorName) ?? 'Consultation',
                                lines: _consultLines(c),
                              ))
                          .toList(),
                    ),
                  if ((_history?.prescriptions.isNotEmpty ?? false))
                    _section(
                      Icons.medication_rounded,
                      'Ordonnances',
                      _history!.prescriptions
                          .map((p) => _EventTile(
                                icon: Icons.medication_rounded,
                                color: const Color(0xFF2563EB),
                                date: Formatters.date(p.date),
                                title: 'Prescription${p.itemsText.isNotEmpty ? '' : ''}',
                                lines: [
                                  if (p.itemsText.isNotEmpty) p.itemsText,
                                  if (_doctor(p.doctorName) != null)
                                    _doctor(p.doctorName)!,
                                ],
                              ))
                          .toList(),
                    ),
                  if ((_history?.treatments.isNotEmpty ?? false))
                    _section(
                      Icons.healing_rounded,
                      'Traitements',
                      _history!.treatments
                          .map((t) => _EventTile(
                                icon: Icons.healing_rounded,
                                color: const Color(0xFFC4953A),
                                date: Formatters.date(t.date),
                                title: t.type ?? 'Traitement',
                                lines: [
                                  if (t.plan != null && t.plan!.isNotEmpty) t.plan!,
                                  if (t.notes != null && t.notes!.isNotEmpty) t.notes!,
                                  if (_doctor(t.doctorName) != null) _doctor(t.doctorName)!,
                                ],
                              ))
                          .toList(),
                    ),
                  if ((_history?.allergies.isNotEmpty ?? false))
                    _section(
                      Icons.warning_amber_rounded,
                      'Allergies',
                      _history!.allergies
                          .map((a) => _EventTile(
                                icon: Icons.warning_amber_rounded,
                                color: const Color(0xFFDC2626),
                                date: null,
                                title: a.name ?? 'Allergie',
                                lines: [
                                  if (a.severity != null && a.severity!.isNotEmpty)
                                    'Sévérité : ${a.severity}',
                                  if (a.notes != null && a.notes!.isNotEmpty) a.notes!,
                                ],
                              ))
                          .toList(),
                    ),
                ],
              ),
            ),
    );
  }

  String? _doctor(String? name) {
    if (name == null || name.isEmpty) return null;
    return 'Dr $name';
  }

  List<String> _consultLines(Consultation c) {
    final lines = <String>[
      if (c.assessment != null && c.assessment!.isNotEmpty) c.assessment!,
      if (c.notes != null && c.notes!.isNotEmpty) c.notes!,
      if (c.plan != null && c.plan!.isNotEmpty) 'Plan : ${c.plan}',
      if (_doctor(c.doctorName) != null) _doctor(c.doctorName)!,
    ];
    return lines.isEmpty ? ['Consultation' ] : lines;
  }

  Widget _section(IconData headerIcon, String title, List<Widget> tiles) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(headerIcon, color: const Color(0xFFBD7F66), size: 20),
              const SizedBox(width: 8),
              Text(title,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFFBD7F66))),
            ],
          ),
          const SizedBox(height: 10),
          _Timeline(children: tiles),
        ],
      ),
    );
  }
}

class _Timeline extends StatelessWidget {
  final List<Widget> children;
  const _Timeline({required this.children});

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) return const SizedBox.shrink();
    return Column(
      children: [
        for (var i = 0; i < children.length; i++)
          _timelineRow(
            child: children[i],
            isLast: i == children.length - 1,
          ),
      ],
    );
  }

  Widget _timelineRow({required Widget child, required bool isLast}) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 22,
            child: Column(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  margin: const EdgeInsets.only(top: 18),
                  decoration: const BoxDecoration(
                    color: Color(0xFFBD7F66),
                    shape: BoxShape.circle,
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      decoration: const BoxDecoration(color: Color(0xFFBD7F66)),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(child: child),
        ],
      ),
    );
  }
}

class _EventTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String? date;
  final String title;
  final List<String> lines;

  const _EventTile({
    required this.icon,
    required this.color,
    required this.title,
    this.date,
    this.lines = const [],
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
              color: const Color(0xFFBD7F66).withValues(alpha: 0.05),
              blurRadius: 14,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (date != null && date!.isNotEmpty)
                  Text(date!,
                      style: const TextStyle(
                          color: Color(0xFFA69D8F), fontSize: 11.5)),
                if (date != null && date!.isNotEmpty) const SizedBox(height: 2),
                Text(title,
                    style: const TextStyle(
                        color: Color(0xFF2C2B22),
                        fontWeight: FontWeight.w700,
                        fontSize: 14)),
                if (lines.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  for (final line in lines)
                    if (line.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(line,
                            style: const TextStyle(
                                color: Color(0xFF8B8173), fontSize: 12.5)),
                      ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}