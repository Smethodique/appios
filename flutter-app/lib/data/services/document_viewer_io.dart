import 'dart:io';
import 'dart:typed_data';

import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';

Future<void> openBytes(Uint8List bytes, String filename, String mime) async {
  final dir = await getTemporaryDirectory();
  final safeName = filename.replaceAll(RegExp(r'[/\\:*?"<>|]'), '_');
  final file = File('${dir.path}/$safeName');
  await file.writeAsBytes(bytes, flush: true);

  final result = await OpenFile.open(
    file.path,
    type: mime.trim().isEmpty ? null : mime.trim(),
  );
  if (result.type == ResultType.noAppToOpen) {
    throw Exception('Aucune application disponible pour ouvrir ce fichier.');
  }
  if (result.type != ResultType.done) {
    throw Exception('Impossible d’ouvrir le fichier.');
  }
}
