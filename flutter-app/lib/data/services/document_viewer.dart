import 'package:medcin_app/core/network/api_service.dart';
import 'package:medcin_app/data/services/document_viewer_stub.dart'
    if (dart.library.io) 'package:medcin_app/data/services/document_viewer_io.dart'
    if (dart.library.html) 'package:medcin_app/data/services/document_viewer_web.dart'
    as platform;

class DocumentViewer {
  static Future<void> openFromEndpoint(
    String endpoint,
    String filename,
    String mime,
  ) async {
    final bytes = await ApiService.downloadBytes(endpoint);
    if (bytes.isEmpty) {
      throw Exception('Fichier vide reçu.');
    }
    return platform.openBytes(bytes, filename, mime);
  }
}
