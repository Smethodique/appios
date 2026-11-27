import 'dart:typed_data';
import 'package:medcin_app/core/network/api_client.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';

/// Native (Android/iOS/desktop) implementation of offline downloads.
class Downloader {
  // Nassreddin — app renamed to DrImane; files already saved under 'Medcin'
  // stay tracked by full path in SharedPreferences, so nothing is lost.
  static const String _folder = 'DrImane';

  static Future<Directory> _baseDir(String sub) async {
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory('${docs.path}/$_folder/$sub');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  /// Saves on Android 10- (legacy storage) to the public Downloads folder when
  /// permitted; otherwise falls back to the app documents directory (always
  /// reliable, no runtime permission needed on modern Android).
  static Future<Directory> _targetDir(String sub) async {
    if (Platform.isAndroid) {
      final status = await Permission.storage.request();
      if (status.isGranted) {
        final downloads = await getDownloadsDirectory();
        if (downloads != null) return downloads;
      }
      return _baseDir(sub);
    }
    final downloads = await getDownloadsDirectory();
    if (downloads != null) return downloads;
    return _baseDir(sub);
  }

  static Future<String?> download({
    required String url,
    required String fileName,
    required String sub,
    void Function(double)? onProgress,
  }) async {
    final dir = await _targetDir(sub);
    final file = File('${dir.path}/$fileName');
    if (await file.exists()) return file.path;
    try {
      await ApiClient.instance.dio.download(
        url,
        file.path,
        onReceiveProgress: (received, total) {
          if (total > 0) onProgress?.call(received / total);
        },
      );
      return file.existsSync() ? file.path : null;
    } catch (e) {
      rethrow;
    }
  }
}

class FileSystem {
  static Future<bool> exists(String path) async {
    final f = File(path);
    if (!f.existsSync()) return false;
    final stat = f.statSync();
    return stat.size > 0;
  }

  static Future<Uint8List> readBytes(String path) async =>
      await File(path).readAsBytes();

  static Future<void> delete(String path) async {
    final f = File(path);
    if (f.existsSync()) await f.delete();
  }
}