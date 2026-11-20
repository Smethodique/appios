import 'package:medcin_app/config/api_config.dart';
import 'package:medcin_app/core/network/api_service.dart';
import 'package:medcin_app/domain/models/growth_measurement.dart';

class GrowthRepository {
  static Future<List<GrowthMeasurement>> list({required int childId}) async {
    final data = await ApiService.get(
      ApiConfig.growthEndpoint,
      queryParams: {'child_id': '$childId'},
    );
    final list = data is List ? data : (data['data'] as List? ?? []);
    return list
        .map((e) => GrowthMeasurement.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static Future<GrowthMeasurement> create({
    required int childId,
    double? weight,
    double? height,
    double? headCircumference,
    required String measuredAt,
  }) async {
    final data = await ApiService.post(
      ApiConfig.growthEndpoint,
      body: {
        'child_id': childId,
        if (weight != null) 'weight': weight,
        if (height != null) 'height': height,
        if (headCircumference != null)
          'head_circumference': headCircumference,
        'measured_at': measuredAt,
      },
    );
    return GrowthMeasurement.fromJson((data as Map).cast<String, dynamic>());
  }

  static Future<void> delete(int id) async {
    await ApiService.delete('${ApiConfig.growthEndpoint}/$id');
  }
}