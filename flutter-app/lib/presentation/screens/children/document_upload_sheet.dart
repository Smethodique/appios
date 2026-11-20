import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:medcin_app/core/errors/api_exception.dart';
import 'package:medcin_app/data/repositories/document_repository.dart';

Future<bool?> showDocumentUploadSheet(
  BuildContext context, {
  required int childId,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (_) => DocumentUploadSheet(childId: childId),
  );
}

class DocumentUploadSheet extends StatefulWidget {
  final int childId;
  const DocumentUploadSheet({super.key, required this.childId});

  @override
  State<DocumentUploadSheet> createState() => _DocumentUploadSheetState();
}

class _DocumentUploadSheetState extends State<DocumentUploadSheet> {
  final _title = TextEditingController();
  String _type = 'autre';
  Uint8List? _bytes;
  String? _fileName;
  String _source = 'fichier';
  bool _uploading = false;
  String? _error;

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  String _typeLabel(String t) {
    switch (t) {
      case 'ordonnance':
        return 'Ordonnance';
      case 'analyse':
        return 'Analyse';
      case 'guide':
        return 'Guide';
      default:
        return 'Document';
    }
  }

  Future<void> _pickFile() async {
    final files = await FilePicker.pickFiles(type: FileType.any);
    if (files.isEmpty) return;
    final f = files.first;
    final bytes = await f.readAsBytes();
    setState(() {
      _bytes = bytes;
      _fileName = f.name;
      _source = 'fichier';
    });
  }

  Future<void> _pickPhoto() async {
    final x = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (x == null) return;
    final bytes = await x.readAsBytes();
    setState(() {
      _bytes = bytes;
      _fileName = x.name;
      _source = 'photo';
    });
  }

  Future<void> _upload() async {
    if (_bytes == null) {
      setState(() => _error = 'Sélectionnez d\'abord un fichier ou une photo.');
      return;
    }
    if (_title.text.trim().isEmpty) {
      setState(() => _error = 'Titre requis.');
      return;
    }
    setState(() {
      _uploading = true;
      _error = null;
    });
    try {
      await DocumentRepository.upload(
        childId: widget.childId,
        type: _type,
        title: _title.text.trim(),
        bytes: _bytes!,
        fileName: _fileName ?? 'document',
      );
      if (mounted) Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'Erreur lors de l\'envoi.');
    } finally {
      if (mounted) setState(() => _uploading = false);
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Ajouter un document',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF2C2B22))),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickPhoto,
                    icon: const Icon(Icons.photo_library_rounded),
                    label: const Text('Photo'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFBD7F66),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickFile,
                    icon: const Icon(Icons.attach_file_rounded),
                    label: const Text('Fichier'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFBD7F66),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_bytes != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFD1FAE5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle_rounded, size: 18, color: Color(0xFFBD7F66)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '$_source · ${_fileName ?? ''}',
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Color(0xFFBD7F66), fontSize: 12.5, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _type,
              decoration: _dec('Type de document'),
              items: ['ordonnance', 'analyse', 'guide', 'autre']
                  .map((t) => DropdownMenuItem(value: t, child: Text(_typeLabel(t))))
                  .toList(),
              onChanged: (v) => setState(() => _type = v ?? 'autre'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _title,
              decoration: _dec('Titre'),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!,
                  style: const TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.w600)),
            ],
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _uploading ? null : _upload,
                icon: _uploading
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                    : const Icon(Icons.cloud_upload_rounded, size: 20),
                label: Text(_uploading ? 'Envoi…' : 'Envoyer'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFBD7F66),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),
          ],
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