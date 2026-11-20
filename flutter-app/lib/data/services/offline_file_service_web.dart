import 'dart:typed_data';

/// Web fallback: there is no local filesystem in the browser, so files are not
/// persisted. Screens that need a "download" on web open the resource directly
/// instead (see GuidesScreen) — the downloader simply reports no local file.
class Downloader {
  static Future<String?> download({
    required String url,
    required String fileName,
    required String sub,
    void Function(double)? onProgress,
  }) async => null;
}

class FileSystem {
  static Future<bool> exists(String path) async => false;

  static Future<Uint8List> readBytes(String path) =>
      throw UnsupportedError('Local filesystem unavailable on web');

  static Future<void> delete(String path) async {}
}