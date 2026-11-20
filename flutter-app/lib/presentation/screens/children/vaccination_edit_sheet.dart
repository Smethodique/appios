import 'package:flutter/material.dart';
import 'package:medcin_app/core/errors/api_exception.dart';
import 'package:medcin_app/data/repositories/vaccination_repository.dart';
import 'package:medcin_app/domain/models/vaccination.dart';

Future<bool?> showVaccinationSheet(
  BuildContext context, {
  required int childId,
  Vaccination? existing,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (_) => VaccinationEditSheet(childId: childId, existing: existing),
  );
}

class VaccinationEditSheet extends StatefulWidget {
  final int childId;
  final Vaccination? existing;
  const VaccinationEditSheet({super.key, required this.childId, this.existing});

  @override
  State<VaccinationEditSheet> createState() => _VaccinationEditSheetState();
}

class _VaccinationEditSheetState extends State<VaccinationEditSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  DateTime? _scheduled;
  DateTime? _administered;
  String _status;
  bool _saving = false;
  String? _error;

  _VaccinationEditSheetState() : _status = 'scheduled';

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _name = TextEditingController(text: e?.vaccineName ?? '');
    _scheduled = e?.scheduledDateTime;
    _administered = e?.administeredDateTime;
    _status = e?.status ?? 'scheduled';
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  String _fmt(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> _pickScheduled() async {
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(DateTime.now().year - 1),
      lastDate: DateTime(DateTime.now().year + 2),
      initialDate: _scheduled ?? DateTime.now(),
    );
    if (picked != null) setState(() => _scheduled = picked);
  }

  Future<void> _pickAdministered() async {
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(DateTime.now().year - 16),
      lastDate: DateTime.now(),
      initialDate: _administered ?? DateTime.now(),
    );
    if (picked != null) setState(() => _administered = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final e = widget.existing;
      if (e == null) {
        await VaccinationRepository.create(
          childId: widget.childId,
          vaccineName: _name.text.trim(),
          scheduledDate: _scheduled == null ? null : _fmt(_scheduled!),
          administeredDate: _administered == null ? null : _fmt(_administered!),
          status: _status,
        );
      } else {
        await VaccinationRepository.update(
          e.id,
          vaccineName: _name.text.trim(),
          scheduledDate: _scheduled == null ? null : _fmt(_scheduled!),
          administeredDate: _administered == null ? null : _fmt(_administered!),
          status: _status,
        );
      }
      if (mounted) Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'Erreur lors de l\'enregistrement.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.existing == null ? 'Nouveau vaccin' : 'Modifier le vaccin',
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF2C2B22))),
              const SizedBox(height: 16),
              TextFormField(
                controller: _name,
                decoration: _dec('Nom du vaccin'),
                validator: (v) => (v ?? '').trim().isEmpty ? 'Nom requis' : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _status,
                decoration: _dec('Statut'),
                items: const [
                  DropdownMenuItem(value: 'scheduled', child: Text('Planifiée')),
                  DropdownMenuItem(value: 'administered', child: Text('Administrée')),
                  DropdownMenuItem(value: 'missed', child: Text('Manquée')),
                ],
                onChanged: (v) => setState(() => _status = v ?? 'scheduled'),
              ),
              const SizedBox(height: 12),
              InkWell(
                onTap: _pickScheduled,
                borderRadius: BorderRadius.circular(16),
                child: InputDecorator(
                  decoration: _dec('Date prévue'),
                  child: Text(
                    _scheduled == null ? 'Aucune' : _fmt(_scheduled!),
                    style: TextStyle(
                        color: _scheduled == null ? const Color(0xFFA69D8F) : const Color(0xFF2C2B22)),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              InkWell(
                onTap: _pickAdministered,
                borderRadius: BorderRadius.circular(16),
                child: InputDecorator(
                  decoration: _dec('Date administrée'),
                  child: Text(
                    _administered == null ? 'Aucune' : _fmt(_administered!),
                    style: TextStyle(
                        color: _administered == null
                            ? const Color(0xFFA69D8F)
                            : const Color(0xFF2C2B22)),
                  ),
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!,
                    style: const TextStyle(
                        color: Color(0xFFEF4444), fontWeight: FontWeight.w600)),
              ],
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFBD7F66),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: _saving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                      : Text(widget.existing == null ? 'Enregistrer' : 'Mettre à jour'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _dec(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: const Color(0xFFF8F6F3).withValues(alpha: 0.8),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
      enabledBorder:
          OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFBD7F66), width: 1.5)),
    );
  }
}