import 'dart:convert';
import 'dart:typed_data';
import 'package:shared_preferences/shared_preferences.dart';
import 'offline_file_service_io.dart'
    if (dart.library.html) 'offline_file_service_web.dart' as platform;

/// Offline download of PDFs and videos.
///
/// On native platforms files are written to the public Downloads folder (when
/// permissible) or the app documents directory, and tracked via
/// SharedPreferences so the UI can show an "open" action. On web there is no
/// local filesystem: downloads resolve to null and callers open resources
/// directly (screens branch on `kIsWeb`).
class OfflineFileService {
  OfflineFileService._();

  static const String pdfKey = 'downloaded_pdfs';
  static const String videoKey = 'downloaded_videos';

  static Future<String?> download({
    required String url,
    required String fileName,
    required String sub,
    void Function(double)? onProgress,
  }) {
    return platform.Downloader.download(
      url: url,
      fileName: fileName,
      sub: sub,
      onProgress: onProgress,
    );
  }

  static Future<String?> downloadPdf({
    required String url,
    required String fileName,
    void Function(double)? onProgress,
  }) {
    return download(
        url: url, fileName: fileName, sub: 'pdfs', onProgress: onProgress);
  }

  static Future<String?> downloadVideo({
    required String url,
    required String fileName,
    void Function(double)? onProgress,
  }) {
    return download(
        url: url, fileName: fileName, sub: 'videos', onProgress: onProgress);
  }

  static Future<bool> markTracked(String key, int id, String path) async {
    final prefs = await SharedPreferences.getInstance();
    final decoded = _decode(prefs.getString(key) ?? '');
    decoded['$id'] = path;
    return prefs.setString(key, _encode(decoded));
  }

  static Future<String?> tracked(String key, int id) async {
    final prefs = await SharedPreferences.getInstance();
    final path = _decode(prefs.getString(key) ?? '')['$id'];
    if (path == null) return null;
    return await platform.FileSystem.exists(path) ? path : null;
  }

  static Future<void> untrack(String key, int id) async {
    final prefs = await SharedPreferences.getInstance();
    final decoded = _decode(prefs.getString(key) ?? '');
    decoded.remove('$id');
    await prefs.setString(key, _encode(decoded));
  }

  static Future<void> deleteFile(String path) =>
      platform.FileSystem.delete(path);

  static Future<Uint8List> readBytes(String path) =>
      platform.FileSystem.readBytes(path);

  static Map<String, String> _decode(String raw) {
    if (raw.isEmpty) return {};
    return (jsonDecode(raw) as Map)
        .map((k, v) => MapEntry(k.toString(), v.toString()));
  }

  static String _encode(Map<String, String> map) => jsonEncode(map);
}