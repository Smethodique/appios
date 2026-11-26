import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:medcin_app/data/services/document_downloader.dart';
import 'package:printing/printing.dart';

class PdfViewScreen extends StatefulWidget {
  final String title;
  final Future<Uint8List> Function() loader;
  const PdfViewScreen({super.key, required this.title, required this.loader});

  @override
  State<PdfViewScreen> createState() => _PdfViewScreenState();
}

class _PdfViewScreenState extends State<PdfViewScreen> {
  late final Future<Uint8List> _future;
  bool _openedInBrowser = false;

  @override
  void initState() {
    super.initState();
    _future = widget.loader();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F1EA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFFBD7F66),
        elevation: 0,
        title: Text(widget.title, overflow: TextOverflow.ellipsis),
      ),
      body: FutureBuilder<Uint8List>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFFBD7F66)),
            );
          }
          if (snapshot.hasError) {
            return _message(
              'Impossible de télécharger ce document.',
              snapshot.error.toString(),
            );
          }
          final bytes = snapshot.data;
          if (bytes == null ||
              bytes.length < 8 ||
              String.fromCharCodes(bytes.take(5)) != '%PDF-') {
            return _message(
              'Ce fichier n’est pas un PDF valide.',
              'Ouvrez-le avec une application externe ou téléchargez-le.',
            );
          }

          // On web the `printing` package's pdf.js frequently breaks
          // (getOrInsertComputed). Use the browser's own PDF viewer instead.
          if (kIsWeb && !_openedInBrowser) {
            _openedInBrowser = true;
            WidgetsBinding.instance.addPostFrameCallback((_) async {
              try {
                await DocumentDownloader.openPdfBytes(bytes, widget.title);
              } catch (_) {}
              if (mounted) setState(() {});
            });
            return _message(
              'Ouverture du PDF…',
              'Le document s’ouvre dans un nouvel onglet.',
            );
          }
          if (kIsWeb) {
            return _message(
              'PDF ouvert dans un nouvel onglet.',
              'S’il ne s’affiche pas, rouvrez-le avec le bouton ci-dessous.',
              reopen: () => DocumentDownloader.openPdfBytes(bytes, widget.title),
            );
          }
          return PdfPreview(
            build: (format) => bytes,
            allowPrinting: true,
            allowSharing: true,
            canChangeOrientation: true,
            canChangePageFormat: true,
          );
        },
      ),
    );
  }

  Widget _message(String title, String detail, {VoidCallback? reopen}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.picture_as_pdf_rounded,
                color: Color(0xFFBD7F66), size: 44),
            const SizedBox(height: 12),
            Text(title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: Color(0xFF2C2B22),
                    fontSize: 15,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text(detail,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFF8B8173), fontSize: 12)),
            const SizedBox(height: 20),
            if (reopen != null)
              OutlinedButton.icon(
                onPressed: reopen,
                icon: const Icon(Icons.open_in_new_rounded),
                label: const Text('Rouvrir le PDF'),
                style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFBD7F66)),
              ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.arrow_back_rounded),
              label: const Text('Retour'),
              style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFBD7F66)),
            ),
          ],
        ),
      ),
    );
  }
}
