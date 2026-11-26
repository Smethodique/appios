import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:medcin_app/core/errors/api_exception.dart';
import 'package:medcin_app/data/repositories/child_repository.dart';
import 'package:medcin_app/data/repositories/document_repository.dart';
import 'package:medcin_app/data/services/document_downloader.dart';
import 'package:medcin_app/domain/models/child.dart';
import 'package:medcin_app/domain/models/growth_measurement.dart';
import 'package:medcin_app/domain/models/medical_history.dart';
import 'package:medcin_app/presentation/screens/children/add_measure_dialog.dart';
import 'package:medcin_app/presentation/screens/children/document_upload_sheet.dart';
import 'package:medcin_app/presentation/screens/pdf_view_screen.dart';
import 'package:medcin_app/utils/formatters.dart';

/// Full dossier médical for a parent.
///
/// parent-created entries can be edited/deleted here; doctor-created entries
/// are shown read-only. The doctor can still edit everything in the web admin.
class DossierMedicalScreen extends StatefulWidget {
  final Child child;

  const DossierMedicalScreen({super.key, required this.child});

  @override
  State<DossierMedicalScreen> createState() => _DossierMedicalScreenState();
}

class _DossierMedicalScreenState extends State<DossierMedicalScreen> {
  static const brown = Color(0xFFBD7F66);
  static const deepBrown = Color(0xFF9C5B3E);
  static const ink = Color(0xFF2C2B22);
  static const muted = Color(0xFF8B8173);
  static const cream = Color(0xFFF5F1EA);
  static const amber = Color(0xFFB45309);
  static const red = Color(0xFFDC2626);

  MedicalHistory? _history;
  List<GrowthMeasurement> _measures = [];
  List<String> _warnings = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        ChildRepository.dossier(widget.child.id),
        ChildRepository.growthDataDetailed(widget.child.id),
      ]);
      final growth = results[1] as ({List<GrowthMeasurement> measurements, List<String> warnings});
      if (!mounted) return;
      setState(() {
        _history = results[0] as MedicalHistory;
        _measures = growth.measurements;
        _warnings = growth.warnings;
      });
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'Impossible de charger le dossier médical.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _run(Future<void> Function() action, String message) async {
    try {
      await action();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: deepBrown),
        );
      }
      // A refresh failure must not turn a successful save into an "error".
      if (!mounted) return;
      try {
        await _load();
      } catch (_) {}
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: red),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Une erreur est survenue : $e'), backgroundColor: red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final history = _history;
    final allWarnings = <String>[
      ...widget.child.dossierWarnings,
      ..._warnings.where((w) => w.startsWith('Poids')).map((w) => w.contains('au-dessus') ? 'Poids élevé' : 'Poids bas'),
    ];

    return Scaffold(
      backgroundColor: cream,
      appBar: AppBar(
        backgroundColor: brown,
        foregroundColor: Colors.white,
        title: Text('Dossier médical · ${widget.child.firstName}',
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
        actions: [
          IconButton(
            tooltip: 'Actualiser',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _load,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: brown))
          : RefreshIndicator(
              onRefresh: _load,
              color: brown,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                children: [
                  if (_error != null)
                    _errorCard(_error!),
                  if (allWarnings.isNotEmpty)
                    _warningBanner(allWarnings),
                  if (history == null)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 60),
                      child: Center(child: Text('Dossier indisponible.', style: TextStyle(color: muted))),
                    )
                  else ...[
                    _section(
                      icon: Icons.warning_amber_rounded,
                      title: 'Allergies',
                      addLabel: 'Ajouter une allergie',
                      onAdd: () => _showAllergySheet(),
                      tiles: history.allergies
                          .map(
                            (a) => _entryTile(
                              icon: Icons.warning_amber_rounded,
                              iconColor: red,
                              title: a.name ?? 'Allergie',
                              subtitle: [
                                if (a.severity != null && a.severity!.isNotEmpty)
                                  'Sévérité : ${a.severity}',
                                if (a.notes != null && a.notes!.isNotEmpty) a.notes!,
                              ],
                              author: a.authorLabel,
                              canEdit: a.canEdit,
                              onEdit: () => _showAllergySheet(allergy: a),
                              onDelete: () => _run(
                                  () => ChildRepository.deleteAllergy(a.id),
                                  'Allergie supprimée.'),
                            ),
                          )
                          .toList(),
                      empty: 'Aucune allergie déclarée.',
                    ),
                    _section(
                      icon: Icons.note_alt_rounded,
                      title: 'Observations',
                      addLabel: 'Ajouter une observation',
                      onAdd: () => _showNoteSheet(type: 'observation'),
                      tiles: history.observations
                          .map(
                            (n) => _entryTile(
                              icon: Icons.note_alt_rounded,
                              iconColor: deepBrown,
                              title: Formatters.date(n.date),
                              subtitle: [n.notes ?? ''],
                              author: n.authorLabel,
                              canEdit: n.canEdit,
                              onEdit: () => _showNoteSheet(entry: n),
                              onDelete: () =>
                                  _run(() => ChildRepository.deleteNote(n.id), 'Observation supprimée.'),
                            ),
                          )
                          .toList(),
                      empty: 'Aucune observation. Notez ici ce que vous observez à la maison.',
                    ),
                    _section(
                      icon: Icons.history_rounded,
                      title: 'Antécédents',
                      addLabel: 'Ajouter un antécédent',
                      onAdd: () => _showNoteSheet(type: 'antecedent'),
                      tiles: history.antecedents
                          .map(
                            (n) => _entryTile(
                              icon: Icons.history_rounded,
                              iconColor: deepBrown,
                              title: Formatters.date(n.date),
                              subtitle: [n.notes ?? ''],
                              author: n.authorLabel,
                              canEdit: n.canEdit,
                              onEdit: () => _showNoteSheet(entry: n),
                              onDelete: () =>
                                  _run(() => ChildRepository.deleteNote(n.id), 'Antécédent supprimé.'),
                            ),
                          )
                          .toList(),
                      empty: 'Aucun antécédent déclaré.',
                    ),
                    _section(
                      icon: Icons.monitor_weight_rounded,
                      title: 'Mesures',
                      addLabel: 'Ajouter une mesure',
                      onAdd: () async {
                        final result = await showAddMeasureDialog(context, childId: widget.child.id);
                        if (result != null) await _load();
                      },
                      tiles: _measures.reversed
                          .map(
                            (m) => _entryTile(
                              icon: Icons.monitor_weight_rounded,
                              iconColor: brown,
                              title: Formatters.date(m.measuredAt),
                              subtitle: [
                                if (m.weight != null) '${m.weight} kg',
                                if (m.height != null) '${m.height} cm',
                                if (m.headCircumference != null) 'PC ${m.headCircumference} cm',
                              ],
                              author: m.authorLabel,
                              canEdit: m.canEdit,
                              onEdit: () => _showMeasureSheet(m),
                              onDelete: () =>
                                  _run(() => ChildRepository.deleteMeasure(m.id), 'Mesure supprimée.'),
                            ),
                          )
                          .toList(),
                      empty: 'Aucune mesure enregistrée.',
                    ),
                    _section(
                      icon: Icons.folder_rounded,
                      title: 'Documents & ordonnances',
                      addLabel: 'Ajouter un document',
                      onAdd: () async {
                        final uploaded = await showDocumentUploadSheet(context, childId: widget.child.id);
                        if (uploaded == true) await _load();
                      },
                      tiles: history.documents
                          .map(
                            (d) => _entryTile(
                              icon: Icons.description_rounded,
                              iconColor: const Color(0xFF2563EB),
                              title: d.title ?? 'Document',
                              subtitle: [
                                d.type ?? '',
                                Formatters.date(d.date),
                              ],
                              author: d.authorLabel,
                              canEdit: d.canEdit,
                              onOpen: () => _openDocument(d),
                              onDelete: () => _run(
                                  () => DocumentRepository.delete(d.id), 'Document supprimé.'),
                            ),
                          )
                          .toList(),
                      empty: 'Aucun document ajouté.',
                    ),
                    _section(
                      icon: Icons.medical_information_rounded,
                      title: 'Consultations (médecin)',
                      tiles: history.consultations
                          .map(
                            (c) => _entryTile(
                              icon: Icons.monitor_heart_rounded,
                              iconColor: brown,
                              title: Formatters.dateTime(c.date),
                              subtitle: [
                                c.authorLabel ?? 'Médecin',
                                if (c.assessment != null && c.assessment!.isNotEmpty) c.assessment!,
                              ],
                              locked: true,
                            ),
                          )
                          .toList(),
                      empty: 'Aucune consultation enregistrée.',
                    ),
                    _section(
                      icon: Icons.medication_rounded,
                      title: 'Ordonnances (médecin)',
                      tiles: history.prescriptions
                          .map(
                            (p) => _entryTile(
                              icon: Icons.medication_rounded,
                              iconColor: const Color(0xFF2563EB),
                              title: Formatters.dateTime(p.date),
                              subtitle: [
                                p.authorLabel ?? 'Médecin',
                                if (p.itemsText.isNotEmpty) p.itemsText,
                              ],
                              locked: true,
                            ),
                          )
                          .toList(),
                      empty: 'Aucune ordonnance du médecin.',
                    ),
                  ],
                ],
              ),
            ),
    );
  }

  void _openDocument(DossierDocument doc) {
    if (doc.isImage) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => _ImageView(
            title: doc.title ?? 'Image',
            loader: () => DocumentRepository.download(doc.id),
          ),
        ),
      );
      return;
    }
    if (doc.isPdf) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => PdfViewScreen(
            title: doc.title ?? 'Document',
            loader: () => DocumentRepository.download(doc.id),
          ),
        ),
      );
      return;
    }
    _run(
      () => DocumentDownloader.downloadAndOpen(
        '${DocumentRepository.downloadEndpoint}/${doc.id}/download',
        doc.originalName ?? doc.title ?? 'document',
      ),
      'Téléchargement lancé.',
    );
  }

  Widget _errorCard(String message) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: red.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(message, style: const TextStyle(color: red, fontSize: 13)),
    );
  }

  Widget _warningBanner(List<String> warnings) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: amber.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: amber.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: amber, size: 18),
              SizedBox(width: 8),
              Text('Points d’attention',
                  style: TextStyle(
                      color: amber, fontSize: 14, fontWeight: FontWeight.w800)),
            ],
          ),
          const SizedBox(height: 8),
          ...warnings.map(
            (w) => Padding(
              padding: const EdgeInsets.only(bottom: 3),
              child: Text('• $w',
                  style: const TextStyle(color: ink, fontSize: 12)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _section({
    required IconData icon,
    required String title,
    String? addLabel,
    VoidCallback? onAdd,
    required List<Widget> tiles,
    String empty = 'Aucune donnée.',
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: brown.withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: brown, size: 19),
              const SizedBox(width: 8),
              Expanded(
                child: Text(title,
                    style: const TextStyle(
                        color: ink, fontSize: 16, fontWeight: FontWeight.w800)),
              ),
              if (addLabel != null && onAdd != null)
                TextButton.icon(
                  onPressed: onAdd,
                  icon: const Icon(Icons.add_rounded, size: 16),
                  label: Text(addLabel,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                  style: TextButton.styleFrom(foregroundColor: deepBrown),
                ),
            ],
          ),
          const SizedBox(height: 8),
          if (tiles.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Text(empty,
                  style: const TextStyle(color: muted, fontSize: 12)),
            )
          else
            ...tiles,
        ],
      ),
    );
  }

  Widget _entryTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required List<String> subtitle,
    String? author,
    bool canEdit = false,
    bool locked = false,
    VoidCallback? onEdit,
    Future<void> Function()? onDelete,
    VoidCallback? onOpen,
  }) {
    final isParent = author == null || author.toLowerCase() == 'parent';
    // If the server omits/stales `can_edit`, a parent-authored (or unlabelled
    // legacy) entry is still editable by that parent. Doctor entries stay locked.
    final editable = !locked && (canEdit || isParent);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cream,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        color: ink, fontSize: 13, fontWeight: FontWeight.w700)),
                const SizedBox(height: 3),
                ...subtitle.where((s) => s.isNotEmpty).map(
                      (s) => Padding(
                        padding: const EdgeInsets.only(bottom: 2),
                        child: Text(s,
                            maxLines: 3,
                            style: const TextStyle(color: muted, fontSize: 12)),
                      ),
                    ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: isParent
                            ? amber.withValues(alpha: 0.12)
                            : brown.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        locked
                            ? '🔒 ${author ?? 'Médecin'}'
                            : (author ?? 'Parent'),
                        style: TextStyle(
                            color: isParent ? amber : deepBrown,
                            fontSize: 10,
                            fontWeight: FontWeight.w700),
                      ),
                    ),
                    if (locked)
                      const Padding(
                        padding: EdgeInsets.only(left: 6),
                        child: Text('Non modifiable',
                            style: TextStyle(color: muted, fontSize: 10)),
                      ),
                  ],
                ),
              ],
            ),
          ),
          if (editable) ...[
            if (onOpen != null)
              IconButton(
                tooltip: 'Ouvrir',
                icon: const Icon(Icons.visibility_rounded, size: 18, color: brown),
                onPressed: onOpen,
              ),
            if (onEdit != null)
              IconButton(
                tooltip: 'Modifier',
                icon: const Icon(Icons.edit_rounded, size: 18, color: brown),
                onPressed: onEdit,
              ),
            if (onDelete != null)
              IconButton(
                tooltip: 'Supprimer',
                icon: const Icon(Icons.delete_outline_rounded, size: 18, color: red),
                onPressed: () => _confirmDelete(onDelete),
              ),
          ] else if (onOpen != null)
            IconButton(
              tooltip: 'Ouvrir',
              icon: const Icon(Icons.visibility_rounded, size: 18, color: brown),
              onPressed: onOpen,
            ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(Future<void> Function() onDelete) async {
    if (!mounted) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Supprimer cet élément ?'),
        content: const Text('Cette action est définitive.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Annuler')),
          TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Supprimer',
                  style: TextStyle(color: red))),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    // Await the request so the real server error is shown instead of silently
    // dropping the future when the screen is rebuilt.
    await onDelete();
  }

  Future<void> _showAllergySheet({AllergyItem? allergy}) async {
    final name = TextEditingController(text: allergy?.name ?? '');
    final notes = TextEditingController(text: allergy?.notes ?? '');
    var severity = allergy?.severity ?? 'faible';
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.viewInsetsOf(sheetContext).bottom + 20),
        child: StatefulBuilder(
          builder: (context, setSheetState) => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(allergy == null ? 'Ajouter une allergie' : 'Modifier l’allergie',
                  style: const TextStyle(
                      fontSize: 19, fontWeight: FontWeight.w800, color: ink)),
              const SizedBox(height: 14),
              _field(name, 'Nom de l’allergie', Icons.warning_amber_rounded),
              const SizedBox(height: 10),
              const Text('Sévérité',
                  style: TextStyle(color: muted, fontSize: 12, fontWeight: FontWeight.w700)),
              Wrap(
                spacing: 8,
                children: ['faible', 'moderee', 'severe']
                    .map(
                      (s) => ChoiceChip(
                        label: Text(_severityLabel(s)),
                        selected: severity == s,
                        onSelected: (_) => setSheetState(() => severity = s),
                        selectedColor: brown.withValues(alpha: 0.2),
                        labelStyle: TextStyle(
                            color: severity == s ? deepBrown : muted,
                            fontSize: 12,
                            fontWeight: FontWeight.w600),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 10),
              _field(notes, 'Notes (facultatif)', Icons.notes_rounded),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.of(context).pop(true),
                  icon: const Icon(Icons.check_rounded),
                  label: const Text('Enregistrer'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: brown,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (saved != true) return;
    if (name.text.trim().isEmpty) return;
    await _run(
      () => allergy == null
          ? ChildRepository.addAllergy(widget.child.id,
              name: name.text.trim(), severity: severity, notes: notes.text.trim())
          : ChildRepository.updateAllergy(allergy.id,
              name: name.text.trim(), severity: severity, notes: notes.text.trim()),
      allergy == null ? 'Allergie ajoutée.' : 'Allergie mise à jour.',
    );
  }

  Future<void> _showNoteSheet({String type = 'observation', DossierEntry? entry}) async {
    final notes = TextEditingController(text: entry?.notes ?? '');
    DateTime date = DateTime.tryParse(entry?.date ?? '') ?? DateTime.now();
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.viewInsetsOf(sheetContext).bottom + 20),
        child: StatefulBuilder(
          builder: (context, setSheetState) => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                  entry == null
                      ? (type == 'antecedent' ? 'Ajouter un antécédent' : 'Ajouter une observation')
                      : 'Modifier ${entry.label.toLowerCase()}',
                  style: const TextStyle(
                      fontSize: 19, fontWeight: FontWeight.w800, color: ink)),
              const SizedBox(height: 14),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.calendar_month_rounded, color: brown),
                title: Text(
                    '${date.day}/${date.month}/${date.year}',
                    style: const TextStyle(color: ink, fontSize: 13, fontWeight: FontWeight.w700)),
                trailing: TextButton(
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: date,
                        firstDate: DateTime(2000),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) setSheetState(() => date = picked);
                    },
                    child: const Text('Changer')),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: notes,
                maxLines: 5,
                style: const TextStyle(color: ink, fontSize: 14),
                cursorColor: brown,
                decoration: InputDecoration(
                  labelText: 'Description',
                  labelStyle: const TextStyle(color: muted, fontSize: 13),
                  floatingLabelStyle:
                      const TextStyle(color: deepBrown, fontSize: 13),
                  filled: true,
                  fillColor: cream,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.of(context).pop(true),
                  icon: const Icon(Icons.check_rounded),
                  label: const Text('Enregistrer'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: brown,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (saved != true || notes.text.trim().isEmpty) return;
    final iso = date.toIso8601String();
    await _run(
      () => entry == null
          ? ChildRepository.addNote(widget.child.id,
              type: type, notes: notes.text.trim(), date: iso)
          : ChildRepository.updateNote(entry.id,
              notes: notes.text.trim(), date: iso),
      entry == null ? 'Note ajoutée.' : 'Note mise à jour.',
    );
  }

  Future<void> _showMeasureSheet(GrowthMeasurement measure) async {
    final weight = TextEditingController(text: measure.weight?.toString() ?? '');
    final height = TextEditingController(text: measure.height?.toString() ?? '');
    DateTime date = measure.measuredDateTime ?? DateTime.now();
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.viewInsetsOf(sheetContext).bottom + 20),
        child: StatefulBuilder(
          builder: (context, setSheetState) => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Modifier la mesure',
                  style: TextStyle(
                      fontSize: 19, fontWeight: FontWeight.w800, color: ink)),
              const SizedBox(height: 14),
              _field(weight, 'Poids (kg)', Icons.monitor_weight_rounded),
              const SizedBox(height: 10),
              _field(height, 'Taille (cm)', Icons.straighten_rounded),
              const SizedBox(height: 10),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.calendar_month_rounded, color: brown),
                title: Text('${date.day}/${date.month}/${date.year}',
                    style: const TextStyle(
                        color: ink, fontSize: 13, fontWeight: FontWeight.w700)),
                trailing: TextButton(
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: date,
                        firstDate: DateTime(2000),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) setSheetState(() => date = picked);
                    },
                    child: const Text('Changer')),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.of(context).pop(true),
                  icon: const Icon(Icons.check_rounded),
                  label: const Text('Enregistrer'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: brown,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (saved != true) return;
    await _run(
      () => ChildRepository.updateMeasure(
        measure.id,
        weight: double.tryParse(weight.text.replaceAll(',', '.')),
        height: double.tryParse(height.text.replaceAll(',', '.')),
        measuredAt: date.toIso8601String(),
      ),
      'Mesure mise à jour.',
    );
  }

  Widget _field(TextEditingController controller, String label, IconData icon) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: ink, fontSize: 14),
      cursorColor: brown,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: muted, fontSize: 13),
        floatingLabelStyle: const TextStyle(color: deepBrown, fontSize: 13),
        prefixIcon: Icon(icon, color: brown, size: 18),
        filled: true,
        fillColor: cream,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
      ),
    );
  }

  String _severityLabel(String value) {
    switch (value) {
      case 'moderee':
        return 'Modérée';
      case 'severe':
        return 'Sévère';
      default:
        return 'Faible';
    }
  }
}

class _ImageView extends StatelessWidget {
  final String title;
  final Future<Uint8List> Function() loader;
  const _ImageView({required this.title, required this.loader});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0F1D),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFFBD7F66),
        title: Text(title, overflow: TextOverflow.ellipsis),
      ),
      body: FutureBuilder<Uint8List>(
        future: loader(),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(
                child: CircularProgressIndicator(color: Color(0xFFBD7F66)));
          }
          if (snapshot.hasError || snapshot.data == null || snapshot.data!.isEmpty) {
            return const Center(
              child: Text('Impossible d’afficher cette image.',
                  style: TextStyle(color: Colors.white70)),
            );
          }
          return InteractiveViewer(
            child: Center(child: Image.memory(snapshot.data!)),
          );
        },
      ),
    );
  }
}
