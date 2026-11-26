import 'package:flutter/material.dart';
import 'package:medcin_app/domain/models/child.dart';
import 'package:medcin_app/presentation/screens/children/child_form_screen.dart';
import 'package:medcin_app/presentation/screens/children/dossier_medical_editable_screen.dart';
import 'package:medcin_app/presentation/screens/children/documents_screen.dart';
import 'package:medcin_app/presentation/screens/children/growth_screen.dart';
import 'package:medcin_app/presentation/screens/children/medical_history_screen.dart';
import 'package:medcin_app/presentation/screens/children/vaccinations_screen.dart';

class ChildDashboardScreen extends StatefulWidget {
  final Child child;
  const ChildDashboardScreen({super.key, required this.child});

  @override
  State<ChildDashboardScreen> createState() => _ChildDashboardScreenState();
}

class _ChildDashboardScreenState extends State<ChildDashboardScreen> {
  late Child _child;

  @override
  void initState() {
    super.initState();
    _child = widget.child;
  }

  Future<void> _edit() async {
    final result = await Navigator.of(context).push<Child>(
      MaterialPageRoute(
        builder: (_) => ChildFormScreen(initial: _child),
      ),
    );
    if (result != null && mounted) {
      setState(() => _child = result);
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F1EA),
        appBar: AppBar(
          backgroundColor: const Color(0xFFBD7F66),
          foregroundColor: Colors.white,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_child.fullName,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 17)),
              if (_child.ageLabel != null && _child.ageLabel!.isNotEmpty)
                Text(
                  _child.ageDays == null
                      ? _child.ageLabel!
                      : '${_child.ageLabel} · ${_child.ageDays} jours',
                  style: const TextStyle(fontSize: 11, color: Colors.white70),
                ),
            ],
          ),
          actions: [
            IconButton(
              tooltip: 'Dossier médical',
              icon: const Icon(Icons.medical_information_rounded),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => DossierMedicalScreen(child: _child),
                ),
              ),
            ),
            IconButton(
              tooltip: 'Modifier le profil',
              icon: const Icon(Icons.edit_rounded),
              onPressed: _edit,
            ),
          ],
          bottom: const TabBar(
            isScrollable: true,
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: [
              Tab(icon: Icon(Icons.vaccines_rounded), text: 'Vaccins'),
              Tab(icon: Icon(Icons.monitor_weight_rounded), text: 'Croissance'),
              Tab(icon: Icon(Icons.folder_rounded), text: 'Documents'),
              Tab(icon: Icon(Icons.history_rounded), text: 'Antécédents'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            VaccinationsScreen(childId: _child.id),
            GrowthScreen(child: _child),
            DocumentsScreen(childId: _child.id),
            MedicalHistoryScreen(childId: _child.id),
          ],
        ),
      ),
    );
  }
}