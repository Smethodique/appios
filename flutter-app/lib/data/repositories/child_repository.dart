import 'package:medcin_app/config/api_config.dart';
import 'package:medcin_app/core/network/api_service.dart';
import 'package:medcin_app/domain/models/child.dart';
import 'package:medcin_app/domain/models/growth_measurement.dart';
import 'package:medcin_app/domain/models/medical_history.dart';

class ChildRepository {
  static Future<List<Child>> list() async {
    final data = await ApiService.get(ApiConfig.childrenEndpoint);
    final list = data is List ? data : (data['data'] as List? ?? []);
    return list
        .map((e) => Child.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static Future<List<GrowthMeasurement>> growthData(int childId) async {
    final data = await ApiService.get(
        '${ApiConfig.childrenEndpoint}/$childId/growth-data');
    final list = data is Map ? (data['measurements'] as List? ?? []) : [];
    return list
        .map((e) => GrowthMeasurement.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Full growth payload, including the latest WHO warnings.
  static Future<({List<GrowthMeasurement> measurements, List<String> warnings})>
      growthDataDetailed(int childId) async {
    final data = await ApiService.get(
        '${ApiConfig.childrenEndpoint}/$childId/growth-data');
    final map = data is Map ? data.cast<String, dynamic>() : <String, dynamic>{};
    return (
      measurements: (map['measurements'] as List? ?? [])
          .map((e) => GrowthMeasurement.fromJson((e as Map).cast<String, dynamic>()))
          .toList(),
      warnings: (map['warnings'] as List? ?? []).map((e) => e.toString()).toList(),
    );
  }

  static Future<({GrowthMeasurement measurement, List<String> warnings})>
      logMeasure(
    int childId, {
    double? weight,
    double? height,
    double? headCircumference,
    required String measuredAt,
  }) async {
    final data = await ApiService.post(
      '${ApiConfig.childrenEndpoint}/$childId/measures',
      body: {
        if (weight != null) 'weight': weight,
        if (height != null) 'height': height,
        if (headCircumference != null)
          'head_circumference': headCircumference,
        'measured_at': measuredAt,
      },
    );
    final map = (data as Map).cast<String, dynamic>();
    return (
      measurement: GrowthMeasurement.fromJson(
          (map['measurement'] as Map).cast<String, dynamic>()),
      warnings:
          (map['warnings'] as List? ?? []).map((e) => e.toString()).toList(),
    );
  }

  static Future<MedicalHistory> medicalHistory(int childId) async {
    final data = await ApiService.get(
        '${ApiConfig.childrenEndpoint}/$childId/medical-history');
    return MedicalHistory.fromJson((data as Map).cast<String, dynamic>());
  }

  static Future<Child> create({
    required String firstName,
    required String lastName,
    required String birthDate,
    required String gender,
    String? bloodGroup,
    String? photo,
  }) async {
    final data = await ApiService.post(
      ApiConfig.childrenEndpoint,
      body: {
        'first_name': firstName,
        'last_name': lastName,
        'birth_date': birthDate,
        'gender': gender,
        if (bloodGroup != null && bloodGroup.isNotEmpty)
          'blood_group': bloodGroup,
        if (photo != null && photo.isNotEmpty) 'photo': photo,
      },
    );
    final child = data is Map ? (data['child'] ?? data) : null;
    return Child.fromJson((child as Map).cast<String, dynamic>());
  }

  static Future<Child> update(
    int id, {
    required String firstName,
    required String lastName,
    required String birthDate,
    required String gender,
    String? bloodGroup,
    String? photo,
  }) async {
    final data = await ApiService.patch(
      '${ApiConfig.childrenEndpoint}/$id',
      body: {
        'first_name': firstName,
        'last_name': lastName,
        'birth_date': birthDate,
        'gender': gender,
        if (bloodGroup != null && bloodGroup.isNotEmpty)
          'blood_group': bloodGroup,
        if (photo != null && photo.isNotEmpty) 'photo': photo,
      },
    );
    final child = data is Map ? (data['child'] ?? data) : null;
    return Child.fromJson((child as Map).cast<String, dynamic>());
  }

  // ── Dossier médical (parent-éditable) ──

  static Future<MedicalHistory> dossier(int childId) => medicalHistory(childId);

  static Future<void> addAllergy(
    int childId, {
    required String name,
    required String severity,
    String? notes,
  }) async {
    await ApiService.post(ApiConfig.allergiesEndpoint, body: {
      'child_id': childId,
      'name': name,
      'severity': severity,
      'notes': notes,
    });
  }

  static Future<void> updateAllergy(
    int id, {
    required String name,
    required String severity,
    String? notes,
  }) async {
    await ApiService.patch('${ApiConfig.allergiesEndpoint}/$id', body: {
      'name': name,
      'severity': severity,
      'notes': notes,
    });
  }

  static Future<void> deleteAllergy(int id) async {
    await ApiService.delete('${ApiConfig.allergiesEndpoint}/$id');
  }

  static Future<void> addNote(
    int childId, {
    required String type,
    required String notes,
    required String date,
  }) async {
    await ApiService.post(ApiConfig.medicalRecordsEndpoint, body: {
      'child_id': childId,
      'type': type,
      'notes': notes,
      'consultation_date': date,
    });
  }

  static Future<void> updateNote(
    int id, {
    required String notes,
    required String date,
  }) async {
    await ApiService.patch('${ApiConfig.medicalRecordsEndpoint}/$id', body: {
      'notes': notes,
      'consultation_date': date,
    });
  }

  static Future<void> deleteNote(int id) async {
    await ApiService.delete('${ApiConfig.medicalRecordsEndpoint}/$id');
  }

  static Future<void> updateMeasure(
    int id, {
    double? weight,
    double? height,
    double? headCircumference,
    required String measuredAt,
  }) async {
    await ApiService.patch('${ApiConfig.growthEndpoint}/$id', body: {
      if (weight != null) 'weight': weight,
      if (height != null) 'height': height,
      if (headCircumference != null) 'head_circumference': headCircumference,
      'measured_at': measuredAt,
    });
  }

  static Future<void> deleteMeasure(int id) async {
    await ApiService.delete('${ApiConfig.growthEndpoint}/$id');
  }

  static Future<void> deleteDocument(int id) async {
    await ApiService.delete('${ApiConfig.documentsEndpoint}/$id');
  }
}