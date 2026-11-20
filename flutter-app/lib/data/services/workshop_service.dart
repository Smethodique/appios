import 'dart:typed_data';

import 'package:medcin_app/config/api_config.dart';
import 'package:medcin_app/core/network/api_service.dart';

class WorkshopMaterial {
  final int id;
  final String title;
  final String? mime;
  final String? url;

  const WorkshopMaterial({
    required this.id,
    required this.title,
    this.mime,
    this.url,
  });

  factory WorkshopMaterial.fromJson(Map<String, dynamic> json) {
    return WorkshopMaterial(
      id: (json['id'] as num?)?.toInt() ?? 0,
      title: json['title']?.toString() ?? 'Document',
      mime: json['mime']?.toString(),
      url: json['url']?.toString(),
    );
  }
}

class WorkshopItem {
  final int id;
  final String title;
  final String? description;
  final String? theme;
  final DateTime? scheduledAt;
  final int durationMinutes;
  final double price;
  final String status;
  final DateTime? doctorStartedAt;
  final String? doctorName;
  final bool enrolled;
  final List<WorkshopMaterial> materials;

  const WorkshopItem({
    required this.id,
    required this.title,
    this.description,
    this.theme,
    this.scheduledAt,
    required this.durationMinutes,
    required this.price,
    required this.status,
    this.doctorStartedAt,
    this.doctorName,
    required this.enrolled,
    required this.materials,
  });

  factory WorkshopItem.fromJson(Map<String, dynamic> json) {
    return WorkshopItem(
      id: (json['id'] as num?)?.toInt() ?? 0,
      title: json['title']?.toString() ?? 'Atelier',
      description: json['description']?.toString(),
      theme: json['theme']?.toString(),
      scheduledAt: DateTime.tryParse(json['scheduled_at']?.toString() ?? ''),
      durationMinutes: (json['duration_minutes'] as num?)?.toInt() ?? 60,
      price: (json['price_dh'] as num?)?.toDouble() ?? 0,
      status: json['status']?.toString() ?? 'scheduled',
      doctorStartedAt: DateTime.tryParse(json['doctor_started_at']?.toString() ?? ''),
      doctorName: json['doctor_name']?.toString(),
      enrolled: json['enrolled'] == true,
      materials: ((json['materials'] as List?) ?? [])
          .whereType<Map>()
          .map((m) => WorkshopMaterial.fromJson(Map<String, dynamic>.from(m)))
          .toList(),
    );
  }
}

class WorkshopService {
  static Future<List<WorkshopItem>> list() async {
    final data = await ApiService.get(ApiConfig.workshopsEndpoint);
    final items = (data is Map) ? (data['workshops'] as List?) ?? [] : [];
    return items
        .whereType<Map>()
        .map((e) => WorkshopItem.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  static Future<String> purchase(int workshopId) async {
    final data = await ApiService.post(
      '${ApiConfig.workshopsEndpoint}/$workshopId/purchase',
      body: {'return_url': 'medcinapp://payment'},
    );
    final url = (data is Map) ? data['payment_url']?.toString() : null;
    if (url == null || url.isEmpty) {
      throw Exception('Lien de paiement indisponible.');
    }
    return url;
  }

  static Future<String> join(int workshopId) async {
    final data = await ApiService.post(
      '${ApiConfig.workshopsEndpoint}/$workshopId/join',
      body: {},
    );
    final url = (data is Map) ? data['prebuilt_url']?.toString() : null;
    if (url == null || url.isEmpty) {
      throw Exception('Lien de l’atelier indisponible.');
    }
    return url;
  }

  static Future<Uint8List> material(int materialId) {
    return ApiService.downloadBytes(
      '${ApiConfig.workshopsEndpoint}/materials/$materialId',
    );
  }
}
