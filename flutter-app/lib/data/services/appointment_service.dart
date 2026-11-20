import 'package:medcin_app/config/api_config.dart';
import 'package:medcin_app/core/network/api_service.dart';
import 'package:medcin_app/domain/models/appointment.dart';

class AppointmentService {
  AppointmentService._();
  static final AppointmentService instance = AppointmentService._();

  Future<List<Appointment>> fetchAppointments({String? filter, String? status}) async {
    final params = <String, String>{
      if (filter != null) 'filter': filter,
      if (status != null) 'status': status,
    };
    final res = await ApiService.get(
      ApiConfig.appointmentsEndpoint,
      queryParams: params.isEmpty ? null : params,
    );
    final list = (res['appointments'] as List?) ?? const [];
    return list
        .whereType<Map<String, dynamic>>()
        .map(Appointment.fromJson)
        .toList();
  }

  Future<Map<String, dynamic>> createAppointment({
    required int childId,
    required DateTime scheduledAt,
    String type = 'consultation',
    String? reason,
    String? notes,
  }) async {
    final res = await ApiService.post(ApiConfig.appointmentsEndpoint, body: {
      'child_id': childId,
      'type': type,
      'scheduled_at': _format(scheduledAt),
      if (reason != null && reason.isNotEmpty) 'reason': reason,
      if (notes != null && notes.isNotEmpty) 'notes': notes,
      'return_url': 'medcinapp://payment',
    });
    if (res is Map<String, dynamic>) return res;
    return <String, dynamic>{'message': res?.toString() ?? 'Demande envoyée.'};
  }

  Future<String> confirm(int id, {DateTime? scheduledAt}) async {
    final res = await ApiService.patch(
      '${ApiConfig.appointmentsEndpoint}/$id/confirm',
      body: {if (scheduledAt != null) 'scheduled_at': _format(scheduledAt)},
    );
    return res['message']?.toString() ?? 'Rendez-vous confirmé.';
  }

  Future<List<String>> availableSlots({
    required int childId,
    required DateTime date,
  }) async {
    final res = await ApiService.get(
      '${ApiConfig.appointmentsEndpoint}/available-slots',
      queryParams: {
        'child_id': '$childId',
        'date':
            '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
      },
    );
    return (res['slots'] as List? ?? []).map((e) => e.toString()).toList();
  }

  Future<List<Map<String, dynamic>>> fetchMySchedule() async {
    final res = await ApiService.get(
        '${ApiConfig.appointmentsEndpoint}/my-schedule');
    return (res['days'] as List? ?? []).map((e) => (e as Map).cast<String, dynamic>()).toList();
  }

  Future<String> updateMySchedule(List<Map<String, dynamic>> days) async {
    final res = await ApiService.put(
      '${ApiConfig.appointmentsEndpoint}/my-schedule',
      body: {'days': days},
    );
    return res['message']?.toString() ?? 'Planning enregistré.';
  }

  Future<String> cancel(int id, {String? notes}) async {
    final res = await ApiService.post(
      '${ApiConfig.appointmentsEndpoint}/$id/cancel',
      body: {if (notes != null && notes.isNotEmpty) 'notes': notes},
    );
    return res['message']?.toString() ?? 'Rendez-vous annulé.';
  }

  static String _format(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')} '
      '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}:00';
}
