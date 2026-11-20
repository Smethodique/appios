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
}