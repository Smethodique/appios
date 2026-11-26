import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:medcin_app/config/api_config.dart';
import 'package:medcin_app/core/network/api_service.dart';
import 'package:medcin_app/domain/models/medcin_document.dart';

class DocumentRepository {
  static String get downloadEndpoint => ApiConfig.documentsEndpoint;

  static Future<List<MedcinDocument>> list({String? type, int? childId}) async {
    final data = await ApiService.get(
      ApiConfig.documentsEndpoint,
      queryParams: {
        if (type != null) 'type': type,
        if (childId != null) 'child_id': '$childId',
      },
    );
    final list = data is List ? data : (data['data'] as List? ?? []);
    return list
        .map((e) => MedcinDocument.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static Future<void> upload({
    required int childId,
    required String type,
    required String title,
    required List<int> bytes,
    required String fileName,
  }) async {
    // The caller only needs to know the request succeeded. Parsing the server's
    // response here was fragile and could report a false "send error" after a
    // successful upload.
    await ApiService.postMultipart(
      '${ApiConfig.documentsEndpoint}/upload',
      file: MultipartFile.fromBytes(bytes, filename: fileName),
      fields: {'child_id': '$childId', 'type': type, 'title': title},
    );
  }

  static Future<Uint8List> download(int id) {
    return ApiService.downloadBytes('${ApiConfig.documentsEndpoint}/$id/download');
  }

  static Future<Uint8List> generatePdf(int id) {
    return ApiService.downloadBytes('${ApiConfig.documentsEndpoint}/$id/pdf');
  }

  static Future<void> delete(int id) async {
    await ApiService.delete('${ApiConfig.documentsEndpoint}/$id');
  }
}