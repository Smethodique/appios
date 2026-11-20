import 'package:flutter/material.dart';
import 'package:medcin_app/data/repositories/document_repository.dart';
import 'package:medcin_app/data/services/document_downloader.dart';
import 'package:medcin_app/domain/models/medcin_document.dart';
import 'package:medcin_app/presentation/screens/pdf_view_screen.dart';
import 'package:medcin_app/utils/formatters.dart';

class DocumentsScreen extends StatefulWidget {
  final int childId;
  const DocumentsScreen({super.key, required this.childId});

  @override
  State<DocumentsScreen> createState() => _DocumentsScreenState();
}

class _DocumentsScreenState extends State<DocumentsScreen> {
  List<MedcinDocument> _docs = [];
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
      final docs = await DocumentRepository.list(childId: widget.childId);
      docs.sort((a, b) => (b.createdAt ?? '').compareTo(a.createdAt ?? ''));
      if (mounted) setState(() => _docs = docs);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _view(MedcinDocument doc) async {
    try {
      if (doc.isPdf) {
        if (!mounted) return;
        await Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => PdfViewScreen(
            title: doc.title,
            loader: () => DocumentRepository.download(doc.id),
          ),
        ));
      } else if (doc.isImage) {
        final bytes = await DocumentRepository.download(doc.id);
        if (!mounted) return;
        await showDialog<void>(
          context: context,
          builder: (ctx) => Dialog(
            backgroundColor: Colors.transparent,
            child: GestureDetector(
              onTap: () => Navigator.pop(ctx),
              child: InteractiveViewer(
                child: Image.memory(bytes, fit: BoxFit.contain),
              ),
            ),
          ),
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ce type de fichier ne peut pas être prévisualisé.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Erreur: $e')));
      }
    }
  }

  Future<void> _download(MedcinDocument doc) async {
    try {
      await DocumentDownloader.downloadAndOpen(
        '${DocumentRepository.downloadEndpoint}/${doc.id}/download',
        doc.originalName ?? 'document_${doc.id}',
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Téléchargement terminé.')),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Téléchargement impossible : $e')));
      }
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
                padding: const EdgeInsets.only(bottom: 90, top: 8),
                children: [
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(_error!,
                          style: const TextStyle(color: Color(0xFFEF4444))),
                    ),
                  if (_docs.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(40),
                      child: Center(
                        child: Text(
                          'Aucun document.\nAjoutez une ordonnance, une analyse, un guide…',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Color(0xFFA69D8F)),
                        ),
                      ),
                    ),
                  ..._docs.map(_docCard),
                ],
              ),
            ),
    );
  }

  Widget _docCard(MedcinDocument doc) {
    final icon = doc.isPdf
        ? Icons.picture_as_pdf_rounded
        : doc.isImage
            ? Icons.image_rounded
            : Icons.insert_drive_file_rounded;
    final color = doc.isPdf
        ? const Color(0xFFDC2626)
        : doc.isImage
            ? const Color(0xFF2563EB)
            : const Color(0xFFBD7F66);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
      padding: const EdgeInsets.all(14),
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
      child: InkWell(
        onTap: () => _view(doc),
        borderRadius: BorderRadius.circular(16),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(doc.title,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: Color(0xFF2C2B22), fontWeight: FontWeight.w700, fontSize: 14.5)),
                  const SizedBox(height: 3),
                  Text(
                    '${doc.typeLabel} · ${doc.originalName ?? ''} · ${Formatters.fileSize(doc.size)}',
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Color(0xFF8B8173), fontSize: 12),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Télécharger',
              onPressed: () => _download(doc),
              icon: const Icon(Icons.download_rounded,
                  color: Color(0xFFBD7F66), size: 20),
            ),
          ],
        ),
      ),
    );
  }
}