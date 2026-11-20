import 'package:medcin_app/config/api_config.dart';
import 'package:medcin_app/core/network/api_service.dart';
import 'package:medcin_app/domain/models/vaccination.dart';

class VaccinationData {
  final List<Vaccination> vaccinations;
  final List<VaccineScheduleItem> schedule;

  const VaccinationData({required this.vaccinations, required this.schedule});
}

class VaccinationRepository {
  static Future<VaccinationData> childData(int childId) async {
    final data = await ApiService.get(
        '${ApiConfig.childrenEndpoint}/$childId/vaccination-data');
    final map = (data as Map).cast<String, dynamic>();
    return VaccinationData(
      vaccinations: (map['vaccinations'] as List? ?? [])
          .map((e) => Vaccination.fromJson((e as Map).cast<String, dynamic>()))
          .toList(),
      schedule: (map['schedule'] as List? ?? [])
          .map((e) =>
              VaccineScheduleItem.fromJson((e as Map).cast<String, dynamic>()))
          .toList(),
    );
  }

  static Future<Vaccination> create({
    required int childId,
    required String vaccineName,
    String? scheduledDate,
    String? administeredDate,
    String status = 'scheduled',
  }) async {
    final data = await ApiService.post(
      ApiConfig.vaccinationsEndpoint,
      body: {
        'child_id': childId,
        'vaccine_name': vaccineName,
        if (scheduledDate != null && scheduledDate.isNotEmpty)
          'scheduled_date': scheduledDate,
        if (administeredDate != null && administeredDate.isNotEmpty)
          'administered_date': administeredDate,
        'status': status,
      },
    );
    return Vaccination.fromJson((data as Map).cast<String, dynamic>());
  }

  static Future<Vaccination> update(
    int id, {
    required String vaccineName,
    String? scheduledDate,
    String? administeredDate,
    required String status,
  }) async {
    final data = await ApiService.patch(
      '${ApiConfig.vaccinationsEndpoint}/$id',
      body: {
        'vaccine_name': vaccineName,
        if (scheduledDate != null && scheduledDate.isNotEmpty)
          'scheduled_date': scheduledDate,
        if (administeredDate != null && administeredDate.isNotEmpty)
          'administered_date': administeredDate,
        'status': status,
      },
    );
    return Vaccination.fromJson((data as Map).cast<String, dynamic>());
  }

  static Future<void> delete(int id) async {
    await ApiService.delete('${ApiConfig.vaccinationsEndpoint}/$id');
  }
}