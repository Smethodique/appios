class Vaccination {
  final int id;
  final int childId;
  final String vaccineName;
  final String? scheduledDate;
  final String? administeredDate;
  final String status;
  final int? administeredBy;

  Vaccination({
    required this.id,
    required this.childId,
    required this.vaccineName,
    this.scheduledDate,
    this.administeredDate,
    required this.status,
    this.administeredBy,
  });

  factory Vaccination.fromJson(Map<String, dynamic> json) {
    return Vaccination(
      id: json['id'] ?? 0,
      childId: json['child_id'] ?? 0,
      vaccineName: json['vaccine_name'] ?? '',
      scheduledDate: json['scheduled_date'],
      administeredDate: json['administered_date'],
      status: json['status'] ?? 'scheduled',
      administeredBy: (json['administered_by'] as num?)?.toInt(),
    );
  }

  bool get isScheduled => status == 'scheduled';
  bool get isAdministered => status == 'administered';
  bool get isMissed => status == 'missed';

  DateTime? get scheduledDateTime {
    final s = scheduledDate;
    if (s == null || s.isEmpty) return null;
    return DateTime.tryParse(s);
  }

  DateTime? get administeredDateTime {
    final s = administeredDate;
    if (s == null || s.isEmpty) return null;
    return DateTime.tryParse(s);
  }

  String get statusLabel {
    switch (status) {
      case 'administered':
        return 'Administrée';
      case 'missed':
        return 'Manquée';
      default:
        return 'Planifiée';
    }
  }
}

class VaccineScheduleItem {
  final String vaccine;
  final String dose;
  final String age;
  final int month;
  final String? dueDate;
  final String status;

  const VaccineScheduleItem({
    required this.vaccine,
    required this.dose,
    required this.age,
    required this.month,
    this.dueDate,
    required this.status,
  });

  factory VaccineScheduleItem.fromJson(Map<String, dynamic> json) {
    return VaccineScheduleItem(
      vaccine: json['vaccine'] ?? '',
      dose: json['dose'] ?? '',
      age: json['age'] ?? '',
      month: (json['month'] as num?)?.toInt() ?? 0,
      dueDate: json['due_date'],
      status: json['status'] ?? 'upcoming',
    );
  }

  bool get isDone => status == 'done';
  bool get isOverdue => status == 'overdue';
  bool get isDue => status == 'due';

  String get statusLabel {
    if (status == 'done') return 'Fait';
    if (status == 'overdue') return 'En retard';
    if (status == 'due') return 'À faire';
    return month <= 0 ? 'À la naissance' : 'Dans $month mois';
  }
}