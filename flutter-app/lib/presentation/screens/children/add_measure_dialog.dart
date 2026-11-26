import 'package:flutter/material.dart';
import 'package:medcin_app/core/errors/api_exception.dart';
import 'package:medcin_app/data/repositories/child_repository.dart';
import 'package:medcin_app/domain/models/growth_measurement.dart';

typedef MeasureLogResult = ({GrowthMeasurement measurement, List<String> warnings});

Future<MeasureLogResult?> showAddMeasureDialog(
  BuildContext context, {
  required int childId,
}) {
  return showModalBottomSheet<MeasureLogResult>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (_) => AddMeasureDialog(childId: childId),
  );
}

class AddMeasureDialog extends StatefulWidget {
  final int childId;
  const AddMeasureDialog({super.key, required this.childId});

  @override
  State<AddMeasureDialog> createState() => _AddMeasureDialogState();
}

class _AddMeasureDialogState extends State<AddMeasureDialog> {
  final _formKey = GlobalKey<FormState>();
  final _weight = TextEditingController();
  final _height = TextEditingController();
  final _head = TextEditingController();
  DateTime? _date;
  bool _saving = false;
  String? _error;

  static const Color _brown = Color(0xFFBD7F66);
  static const Color _ink = Color(0xFF2C2B22);
  static const Color _muted = Color(0xFF8B8173);
  static const Color _deepBrown = Color(0xFF9C5B3E);
  static const TextStyle _inputStyle = TextStyle(
      color: _ink, fontSize: 14, fontWeight: FontWeight.w600);

  @override
  void initState() {
    super.initState();
    _date = DateTime.now();
  }

  @override
  void dispose() {
    _weight.dispose();
    _height.dispose();
    _head.dispose();
    super.dispose();
  }

  String _fmt(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(DateTime.now().year - 16),
      lastDate: DateTime.now(),
      initialDate: _date ?? DateTime.now(),
    );
    if (picked != null) setState(() => _date = picked);
  }

  double? _parse(String? v) {
    final t = (v ?? '').trim().replaceAll(',', '.');
    if (t.isEmpty) return null;
    return double.tryParse(t);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final result = await ChildRepository.logMeasure(
        widget.childId,
        weight: _parse(_weight.text),
        height: _parse(_height.text),
        headCircumference: _parse(_head.text),
        measuredAt: _fmt(_date!),
      );
      if (mounted) Navigator.of(context).pop(result);
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
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: const Color(0xFFBD7F66).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.monitor_weight_rounded,
                        color: Color(0xFFBD7F66)),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text('Nouvelle mesure',
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF2C2B22))),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _weight,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      style: _inputStyle,
                      cursorColor: _brown,
                      decoration: _dec('Poids (kg)'),
                      validator: (v) => _validate(v),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _height,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      style: _inputStyle,
                      cursorColor: _brown,
                      decoration: _dec('Taille (cm)'),
                      validator: (v) => _validate(v),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _head,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: _inputStyle,
                cursorColor: _brown,
                decoration: _dec('Périmètre crânien (cm)'),
                validator: (v) => _validate(v),
              ),
              const SizedBox(height: 12),
              InkWell(
                onTap: _pickDate,
                borderRadius: BorderRadius.circular(16),
                child: InputDecorator(
                  decoration: _dec('Date de la mesure'),
                  baseStyle: _inputStyle,
                  child: Text(_fmt(_date!), style: _inputStyle),
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
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  child: _saving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2.5, color: Colors.white))
                      : const Text('Enregistrer'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String? _validate(String? v) {
    if ((v ?? '').trim().isEmpty) return null;
    return _parse(v) != null ? null : 'Valeur invalide';
  }

  InputDecoration _dec(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: _muted, fontSize: 13),
      floatingLabelStyle: const TextStyle(
          color: _deepBrown, fontSize: 13, fontWeight: FontWeight.w700),
      hintStyle: const TextStyle(color: _muted, fontSize: 14),
      filled: true,
      fillColor: const Color(0xFFF8F6F3).withValues(alpha: 0.8),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFBD7F66), width: 1.5)),
    );
  }
}