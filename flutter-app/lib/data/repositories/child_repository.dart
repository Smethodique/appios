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
}