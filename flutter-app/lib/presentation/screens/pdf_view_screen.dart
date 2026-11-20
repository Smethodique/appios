import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

class PdfViewScreen extends StatelessWidget {
  final String title;
  final Future<Uint8List> Function() loader;
  const PdfViewScreen({super.key, required this.title, required this.loader});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F1EA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFFBD7F66),
        elevation: 0,
        title: Text(title, overflow: TextOverflow.ellipsis),
      ),
      body: FutureBuilder<Uint8List>(
        future: loader(),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFFBD7F66)),
            );
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.picture_as_pdf_rounded,
                        color: Color(0xFFEF4444), size: 44),
                    const SizedBox(height: 12),
                    Text(
                      'Impossible d\'ouvrir ce document. ${snapshot.error}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Color(0xFF8B8173)),
                    ),
                  ],
                ),
              ),
            );
          }
          return PdfPreview(
            build: (format) => snapshot.data!,
            allowPrinting: true,
            allowSharing: true,
            canChangeOrientation: true,
            canChangePageFormat: true,
          );
        },
      ),
    );
  }
}