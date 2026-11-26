import 'dart:io';
import 'dart:typed_data';

import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';

Future<void> openBytes(Uint8List bytes, String filename) async {
  final dir = await getApplicationDocumentsDirectory();
  final safeName = filename.replaceAll(RegExp(r'[/\\:*?"<>|]'), '_');
  final file = File('${dir.path}/$safeName');
  await file.writeAsBytes(bytes, flush: true);
  final result = await OpenFile.open(file.path);
  if (result.type != ResultType.done && result.type != ResultType.noAppToOpen) {
    throw Exception('Impossible d’ouvrir le fichier.');
  }
}

Future<void> openPdf(Uint8List bytes, String filename) async {
  await openBytes(bytes, filename.endsWith('.pdf') ? filename : '$filename.pdf');
}
