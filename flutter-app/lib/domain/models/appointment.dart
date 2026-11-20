class Appointment {
  final int id;
  final int childId;
  final String childName;
  final String? parentName;
  final String type;
  final String? reason;
  final String? notes;
  final DateTime? scheduledAt;
  final int duration;
  final String status;

  Appointment({
    required this.id,
    required this.childId,
    required this.childName,
    this.parentName,
    required this.type,
    this.reason,
    this.notes,
    this.scheduledAt,
    required this.duration,
    required this.status,
  });

  factory Appointment.fromJson(Map<String, dynamic> json) {
    final raw = json['scheduled_at_raw'];
    return Appointment(
      id: json['id'] ?? 0,
      childId: json['child_id'] ?? 0,
      childName: (json['child_name'] ?? '').toString().trim(),
      parentName: json['parent_name'],
      type: json['type'] ?? 'consultation',
      reason: json['reason'],
      notes: json['notes'],
      scheduledAt: raw is String && raw.isNotEmpty ? DateTime.tryParse(raw) : null,
      duration: json['duration'] ?? 30,
      status: json['status'] ?? 'pending',
    );
  }

  bool get isPending => status == 'pending';
  bool get isConfirmed => status == 'confirmed';
  bool get isCancelled => status == 'cancelled';

  String get displayType {
    switch (type) {
      case 'vaccin':
        return 'Vaccin';
      case 'mesure':
        return 'Mesure';
      case 'coaching':
        return 'Coaching';
      case 'autre':
        return 'Autre';
      case 'consultation':
        return 'Consultation';
      default:
        return type;
    }
  }
}
