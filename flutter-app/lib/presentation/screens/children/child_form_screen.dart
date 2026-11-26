import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:medcin_app/core/errors/api_exception.dart';
import 'package:medcin_app/data/repositories/child_repository.dart';
import 'package:medcin_app/domain/models/child.dart';

class ChildFormScreen extends StatefulWidget {
  final Child? initial;
  const ChildFormScreen({super.key, this.initial});

  bool get isEditing => initial != null;

  @override
  State<ChildFormScreen> createState() => _ChildFormScreenState();
}

class _ChildFormScreenState extends State<ChildFormScreen> {
  static const _bloodTypes = ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'];

  final _formKey = GlobalKey<FormState>();
  final _first = TextEditingController();
  final _last = TextEditingController();
  DateTime? _birth;
  String? _gender;
  String? _bloodType;
  String? _photo;
  bool _saving = false;
  String? _error;

  bool get _editing => widget.initial != null;

  @override
  void initState() {
    super.initState();
    final c = widget.initial;
    if (c != null) {
      _first.text = c.firstName;
      _last.text = c.lastName;
      _birth = DateTime.tryParse(c.birthDate ?? '');
      _gender = c.gender;
      _bloodType = c.bloodGroup;
      _photo = c.hasPhoto ? c.photo : null;
    }
  }

  @override
  void dispose() {
    _first.dispose();
    _last.dispose();
    super.dispose();
  }

  String _fmt(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> _pickBirth() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(now.year - 18),
      lastDate: now,
      initialDate: _birth ?? now.subtract(const Duration(days: 365)),
      helpText: 'Date de naissance',
    );
    if (picked != null) setState(() => _birth = picked);
  }

  Future<void> _pickPhoto() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            ListTile(
              leading: const Icon(Icons.photo_library_rounded,
                  color: Color(0xFFBD7F66)),
              title: const Text('Choisir depuis la galerie',
                  style: TextStyle(color: Colors.black, fontSize: 14)),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera_rounded,
                  color: Color(0xFFBD7F66)),
              title: const Text('Prendre une photo',
                  style: TextStyle(color: Colors.black, fontSize: 14)),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (source == null || !mounted) return;

    try {
      final picked = await ImagePicker().pickImage(
        source: source,
        maxWidth: 900,
        imageQuality: 80,
      );
      if (picked == null) return;
      final bytes = await picked.readAsBytes();
      if (!mounted) return;
      setState(() => _photo = 'data:image/jpeg;base64,${base64Encode(bytes)}');
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Impossible de charger l’image.');
      }
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_birth == null) {
      setState(() => _error = 'Date de naissance requise.');
      return;
    }
    if (_gender == null) {
      setState(() => _error = 'Sélectionnez le genre.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final params = (
        firstName: _first.text.trim(),
        lastName: _last.text.trim(),
        birthDate: _fmt(_birth!),
        gender: _gender!,
        bloodGroup: _bloodType,
        photo: _photo,
      );
      if (_editing) {
        final updated = await ChildRepository.update(
          widget.initial!.id,
          firstName: params.firstName,
          lastName: params.lastName,
          birthDate: params.birthDate,
          gender: params.gender,
          bloodGroup: params.bloodGroup,
          photo: params.photo,
        );
        if (mounted) Navigator.of(context).pop(updated);
      } else {
        await ChildRepository.create(
          firstName: params.firstName,
          lastName: params.lastName,
          birthDate: params.birthDate,
          gender: params.gender,
          bloodGroup: params.bloodGroup,
          photo: params.photo,
        );
        if (mounted) Navigator.of(context).pop(true);
      }
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) {
        setState(() => _error = _editing
            ? 'Erreur lors de la mise à jour.'
            : 'Erreur lors de la création.');
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F1EA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFBD7F66),
        foregroundColor: Colors.white,
        centerTitle: true,
        title: Text(_editing ? 'Modifier l’enfant' : 'Nouvel enfant',
            style: const TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Center(child: _photoPicker()),
            const SizedBox(height: 20),
            TextFormField(
              controller: _first,
              style: const TextStyle(color: Color(0xFF2C2B22)),
              decoration: _dec('Prénom'),
              validator: (v) => (v ?? '').trim().isEmpty ? 'Prénom requis' : null,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _last,
              style: const TextStyle(color: Color(0xFF2C2B22)),
              decoration: _dec('Nom'),
              validator: (v) => (v ?? '').trim().isEmpty ? 'Nom requis' : null,
            ),
            const SizedBox(height: 22),
            InkWell(
              onTap: _editing ? null : _pickBirth,
              borderRadius: BorderRadius.circular(16),
              child: InputDecorator(
                decoration: _dec('Date de naissance',
                    suffix: _editing
                        ? null
                        : const Icon(Icons.calendar_month_rounded,
                            color: Color(0xFFBD7F66))),
                child: Text(
                  _birth == null ? 'Sélectionner une date' : _fmt(_birth!),
                  style: TextStyle(
                      color: _birth == null
                          ? const Color(0xFFA69D8F)
                          : const Color(0xFF2C2B22)),
                ),
              ),
            ),
            const SizedBox(height: 20),
            _fieldLabel('Genre'),
            DropdownButtonFormField<String>(
              initialValue: _gender,
              decoration: _dropdownDec(),
              style: const TextStyle(color: Colors.white, fontSize: 14),
              selectedItemBuilder: (context) => const [
                Text('Garçon', style: TextStyle(color: Colors.white, fontSize: 14)),
                Text('Fille', style: TextStyle(color: Colors.white, fontSize: 14)),
              ],
              hint: const Text('Sélectionner le genre',
                  style: TextStyle(color: Colors.white70, fontSize: 14)),
              dropdownColor: const Color(0xFF0A0F1D),
              isExpanded: true,
              itemHeight: 48,
              items: const [
                DropdownMenuItem(
                    value: 'male',
                    child: Text('Garçon', style: TextStyle(color: Colors.white))),
                DropdownMenuItem(
                    value: 'female',
                    child: Text('Fille', style: TextStyle(color: Colors.white))),
              ],
              onChanged: (v) => setState(() => _gender = v),
            ),
            const SizedBox(height: 20),
            _fieldLabel('Groupe sanguin (optionnel)'),
            DropdownButtonFormField<String>(
              initialValue: _bloodType,
              decoration: _dropdownDec(),
              style: const TextStyle(color: Colors.white, fontSize: 14),
              selectedItemBuilder: (context) => _bloodTypes
                  .map((b) => Text(b,
                      style: const TextStyle(color: Colors.white, fontSize: 14)))
                  .toList(),
              hint: const Text('Sélectionner un groupe',
                  style: TextStyle(color: Colors.white70, fontSize: 14)),
              dropdownColor: const Color(0xFF0A0F1D),
              isExpanded: true,
              itemHeight: 48,
              items: _bloodTypes
                  .map((b) => DropdownMenuItem(
                      value: b,
                      child: Text(b,
                          style: const TextStyle(color: Colors.white))))
                  .toList(),
              onChanged: (v) => setState(() => _bloodType = v),
            ),
            if (_error != null) ...[
              const SizedBox(height: 14),
              Text(_error!,
                  style: const TextStyle(
                      color: Color(0xFFEF4444), fontWeight: FontWeight.w600)),
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _saving ? null : _save,
                icon: _saving
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2.5, color: Colors.white))
                    : const Icon(Icons.check_rounded, size: 20),
                label: Text(_saving
                    ? (_editing ? 'Enregistrement…' : 'Création…')
                    : (_editing ? 'Enregistrer' : 'Créer le profil')),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFBD7F66),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: const Color(0xFFBD7F66)
                      .withValues(alpha: 0.6),
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),
            const SizedBox(height: 12),
            if (!_editing)
              const Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.hourglass_top_rounded,
                        color: Color(0xFFB45309), size: 16),
                    SizedBox(width: 6),
                    Text('Validation par le médecin requise',
                        style: TextStyle(
                            color: Color(0xFFB45309),
                            fontSize: 12,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _photoPicker() {
    final photo = _photo;
    Widget child;
    if (photo == null) {
      child = const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.add_a_photo_rounded, color: Color(0xFFBD7F66), size: 30),
          SizedBox(height: 6),
          Text('Photo',
              style: TextStyle(
                  color: Colors.black,
                  fontSize: 12,
                  fontWeight: FontWeight.w600)),
        ],
      );
    } else if (photo.contains('data:image')) {
      child = ClipOval(
        child: Image.memory(
          _decodePhoto(photo),
          fit: BoxFit.cover,
          width: 116,
          height: 116,
          errorBuilder: (context, error, stack) =>
              const Icon(Icons.person_rounded, color: Color(0xFFBD7F66), size: 40),
        ),
      );
    } else {
      child = ClipOval(
        child: Image.network(
          photo,
          fit: BoxFit.cover,
          width: 116,
          height: 116,
          errorBuilder: (context, error, stack) =>
              const Icon(Icons.person_rounded, color: Color(0xFFBD7F66), size: 40),
        ),
      );
    }
    return GestureDetector(
      onTap: _pickPhoto,
      child: Stack(
        children: [
          Container(
            width: 116,
            height: 116,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFBD7F66).withValues(alpha: 0.1),
              border: Border.all(color: const Color(0xFFBD7F66), width: 2),
            ),
            child: child,
          ),
          Positioned(
            right: 2,
            bottom: 2,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: Color(0xFFBD7F66),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.edit_rounded,
                  color: Colors.white, size: 16),
            ),
          ),
        ],
      ),
    );
  }

  Uint8List _decodePhoto(String dataUri) {
    try {
      return Uint8List.fromList(
          base64Decode(dataUri.substring(dataUri.indexOf(',') + 1)));
    } catch (_) {
      return Uint8List(0);
    }
  }

  InputDecoration _dec(String label, {Widget? suffix}) {
    const labelColor = Color(0xFF6B6358);
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: labelColor),
      floatingLabelStyle: const TextStyle(color: Color(0xFFBD7F66)),
      hintStyle: const TextStyle(color: Color(0xFF8B8173)),
      suffixIcon: suffix,
      filled: true,
      fillColor: Colors.white,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFBD7F66), width: 1.5)),
    );
  }

  /// Label drawn above the field instead of inside it. InputDecorator cannot
  /// reliably float a label on a dropdown, which made it sit on top of the
  /// selected value; keeping them separate removes the overlap completely.
  Widget _fieldLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: const TextStyle(
            color: Color(0xFF2C2B22), fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }

  /// Brown dropdown field with white text and no internal label.
  InputDecoration _dropdownDec() {
    const border = OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(16)),
      borderSide: BorderSide.none,
    );
    return const InputDecoration(
      hintStyle: TextStyle(color: Colors.white70),
      filled: true,
      fillColor: Color(0xFF9C5B3E),
      contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: border,
      enabledBorder: border,
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(16)),
        borderSide: BorderSide(color: Color(0xFFBD7F66), width: 1.5),
      ),
    );
  }
}