class MedicalHistory {
  final List<Consultation> consultations;
  final List<PrescriptionItem> prescriptions;
  final List<AllergyItem> allergies;
  final List<TreatmentItem> treatments;

  const MedicalHistory({
    this.consultations = const [],
    this.prescriptions = const [],
    this.allergies = const [],
    this.treatments = const [],
  });

  factory MedicalHistory.fromJson(Map<String, dynamic> json) {
    return MedicalHistory(
      consultations: (json['consultations'] as List? ?? [])
          .map((e) => Consultation.fromJson((e as Map).cast<String, dynamic>()))
          .toList(),
      prescriptions: (json['prescriptions'] as List? ?? [])
          .map((e) => PrescriptionItem.fromJson((e as Map).cast<String, dynamic>()))
          .toList(),
      allergies: (json['allergies'] as List? ?? [])
          .map((e) => AllergyItem.fromJson((e as Map).cast<String, dynamic>()))
          .toList(),
      treatments: (json['treatments'] as List? ?? [])
          .map((e) => TreatmentItem.fromJson((e as Map).cast<String, dynamic>()))
          .toList(),
    );
  }

  bool get isEmpty =>
      consultations.isEmpty &&
      prescriptions.isEmpty &&
      allergies.isEmpty &&
      treatments.isEmpty;
}

class Consultation {
  final int id;
  final String? date;
  final String? notes;
  final String? subjective;
  final String? objective;
  final String? assessment;
  final String? plan;
  final String? nextVisit;
  final String? doctorName;
  final String? type;

  const Consultation({
    required this.id,
    this.date,
    this.notes,
    this.subjective,
    this.objective,
    this.assessment,
    this.plan,
    this.nextVisit,
    this.doctorName,
    this.type,
  });

  factory Consultation.fromJson(Map<String, dynamic> json) {
    return Consultation(
      id: json['id'] ?? 0,
      date: json['consultation_date'],
      notes: json['notes'],
      subjective: json['subjective'],
      objective: json['objective'],
      assessment: json['assessment'],
      plan: json['plan'],
      nextVisit: json['next_visit'],
      doctorName: json['doctor']?['name'] ?? json['doctor_name'],
      type: json['type'],
    );
  }

  String get summary {
    final parts = <String>[
      if (assessment != null && assessment!.isNotEmpty) assessment!,
      if (plan != null && plan!.isNotEmpty) 'Plan : $plan',
    ];
    return parts.isEmpty ? (notes ?? 'Consultation') : parts.join('\n');
  }
}

class PrescriptionItem {
  final int id;
  final List<dynamic> items;
  final String? notes;
  final String? date;
  final String? doctorName;

  const PrescriptionItem({
    required this.id,
    this.items = const [],
    this.notes,
    this.date,
    this.doctorName,
  });

  factory PrescriptionItem.fromJson(Map<String, dynamic> json) {
    return PrescriptionItem(
      id: json['id'] ?? 0,
      items: json['items'] is List ? json['items'] as List : const [],
      notes: json['notes'],
      date: json['created_at'],
      doctorName: json['doctor']?['name'] ?? json['doctor_name'],
    );
  }

  String get itemsText => items.map((i) => i.toString()).map((s) {
        if (s.startsWith('{')) {
          final clean = s.replaceAll(RegExp(r'[{"}]'), '');
          final bits = clean.split(',').where((b) => b.isNotEmpty).toList();
          return bits.join(' · ');
        }
        return s;
      }).join('\n');
}

class AllergyItem {
  final int id;
  final String? name;
  final String? severity;
  final String? notes;

  const AllergyItem({required this.id, this.name, this.severity, this.notes});

  factory AllergyItem.fromJson(Map<String, dynamic> json) {
    return AllergyItem(
      id: json['id'] ?? 0,
      name: json['name'],
      severity: json['severity'],
      notes: json['notes'],
    );
  }
}

class TreatmentItem {
  final int id;
  final String? type;
  final String? date;
  final String? plan;
  final String? notes;
  final String? doctorName;

  const TreatmentItem({
    required this.id,
    this.type,
    this.date,
    this.plan,
    this.notes,
    this.doctorName,
  });

  factory TreatmentItem.fromJson(Map<String, dynamic> json) {
    return TreatmentItem(
      id: json['id'] ?? 0,
      type: json['type'],
      date: json['consultation_date'],
      plan: json['plan'],
      notes: json['notes'],
      doctorName: json['doctor']?['name'] ?? json['doctor_name'],
    );
  }
}