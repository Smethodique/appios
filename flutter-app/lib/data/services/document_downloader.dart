import 'dart:typed_data';

import 'package:medcin_app/core/network/api_service.dart';
import 'package:medcin_app/data/services/document_downloader_stub.dart'
    if (dart.library.io) 'package:medcin_app/data/services/document_downloader_io.dart'
    if (dart.library.html) 'package:medcin_app/data/services/document_downloader_web.dart'
    as platform;

class DocumentDownloader {
  static Future<void> downloadAndOpen(
      String endpoint, String filename) async {
    final bytes = await ApiService.downloadBytes(endpoint);
    if (bytes.isEmpty) {
      throw Exception('Fichier vide reçu.');
    }
    return platform.openBytes(bytes, filename);
  }

  /// Opens a PDF with the browser's own viewer on web, or the system viewer
  /// on mobile. Avoids the printing package's broken pdf.js on web.
  static Future<void> openPdfBytes(Uint8List bytes, String filename) async {
    if (bytes.isEmpty) throw Exception('Fichier vide reçu.');
    return platform.openPdf(bytes, filename);
  }

  static Future<void> openPdf(String endpoint, String filename) async {
    final bytes = await ApiService.downloadBytes(endpoint);
    await openPdfBytes(bytes, filename);
  }
}