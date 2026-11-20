import 'package:flutter/material.dart';
import 'package:medcin_app/data/repositories/child_repository.dart';
import 'package:medcin_app/domain/models/child.dart';
import 'package:medcin_app/presentation/screens/children/child_dashboard_screen.dart';
import 'package:medcin_app/presentation/screens/children/child_form_screen.dart';

class ChildProfileScreen extends StatefulWidget {
  const ChildProfileScreen({super.key});

  @override
  State<ChildProfileScreen> createState() => _ChildProfileScreenState();
}

class _ChildProfileScreenState extends State<ChildProfileScreen> {
  List<Child> _children = [];
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
      final children = await ChildRepository.list();
      if (mounted) setState(() => _children = children);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openAdd() async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const ChildFormScreen()),
    );
    if (created == true) await _load();
  }

  String _age(Child c) {
    final b = c.birthDate;
    if (b == null || b.isEmpty) return '';
    final parsed = DateTime.tryParse(b);
    if (parsed == null) return '';
    final now = DateTime.now();
    var months = (now.year - parsed.year) * 12 + (now.month - parsed.month);
    if (now.day < parsed.day) months -= 1;
    if (months < 12) return '$months mois';
    final years = months ~/ 12;
    return '$years an${years > 1 ? 's' : ''}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0F1D),
      appBar: AppBar(
        backgroundColor: const Color(0xFFBD7F66),
        foregroundColor: Colors.white,
        title: const Text('Mes enfants', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAdd,
        backgroundColor: const Color(0xFFBD7F66),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.person_add_alt_1_rounded),
        label: const Text('Nouvel enfant'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFBD7F66)))
          : RefreshIndicator(
              color: const Color(0xFFBD7F66),
              onRefresh: _load,
              child: _children.isEmpty
                  ? ListView(
                      children: [
                        const SizedBox(height: 120),
                        const Icon(Icons.child_care_rounded, color: Color(0xFFBD7F66), size: 64),
                        const SizedBox(height: 16),
                        Center(
                          child: Text(
                            _error ?? 'Aucun enfant pour le moment.\nAjoutez votre premier profil enfant.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: _error != null ? const Color(0xFFEF4444) : const Color(0xFF8B8173)),
                          ),
                        ),
                      ],
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _children.length,
                      itemBuilder: (context, i) => _childCard(_children[i]),
                    ),
            ),
    );
  }

  Widget _initialAvatar(Child child) {
    return Center(
      child: Text(
        child.firstName.isNotEmpty ? child.firstName[0].toUpperCase() : '?',
        style: const TextStyle(
            color: Color(0xFFBD7F66), fontSize: 22, fontWeight: FontWeight.w800),
      ),
    );
  }

  Widget _childCard(Child child) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: () async {
            final changed = await Navigator.of(context).push<bool>(
              MaterialPageRoute(
                builder: (_) => ChildDashboardScreen(child: child),
              ),
            );
            if (changed == true) await _load();
          },
          child: Ink(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                    color: const Color(0xFFBD7F66).withValues(alpha: 0.08),
                    blurRadius: 20,
                    offset: const Offset(0, 6)),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    color: const Color(0xFFBD7F66).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: child.photoBytes != null
                      ? Image.memory(
                          child.photoBytes!,
                          width: 52,
                          height: 52,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stack) =>
                              _initialAvatar(child),
                        )
                      : child.hasPhoto
                          ? Image.network(
                              child.photo!,
                              width: 52,
                              height: 52,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stack) =>
                                  _initialAvatar(child),
                            )
                          : _initialAvatar(child),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(child.fullName,
                          style: const TextStyle(
                              color: Color(0xFF2C2B22),
                              fontSize: 16,
                              fontWeight: FontWeight.w700)),
                      const SizedBox(height: 4),
                      Text(
                        '${child.displayGender}${_age(child).isEmpty ? '' : ' · ${_age(child)}'}',
                        style: const TextStyle(color: Color(0xFF8B8173), fontSize: 13),
                      ),
                    ],
                  ),
                ),
                if (child.validated)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                        color: const Color(0xFFD1FAE5), borderRadius: BorderRadius.circular(12)),
                    child: const Text('Validé',
                        style: TextStyle(
                            color: Color(0xFFBD7F66), fontSize: 11, fontWeight: FontWeight.w600)),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                        color: const Color(0xFFFEF3C7), borderRadius: BorderRadius.circular(12)),
                    child: const Text('En attente',
                        style: TextStyle(
                            color: Color(0xFFB45309), fontSize: 11, fontWeight: FontWeight.w600)),
                  ),
                const SizedBox(width: 8),
                const Icon(Icons.chevron_right_rounded, color: Color(0xFFA69D8F)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}