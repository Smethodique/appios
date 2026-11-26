/// Older servers may omit `can_edit`; a parent-authored entry is still editable.
bool _canEdit(Map<String, dynamic> json) {
  final flag = json['can_edit'];
  if (flag is bool) return flag;
  return json['author_label']?.toString().toLowerCase() == 'parent';
}

class MedicalHistory {
  final List<Consultation> consultations;
  final List<PrescriptionItem> prescriptions;
  final List<AllergyItem> allergies;
  final List<TreatmentItem> treatments;
  final List<DossierEntry> observations;
  final List<DossierEntry> antecedents;
  final List<DossierDocument> documents;

  const MedicalHistory({
    this.consultations = const [],
    this.prescriptions = const [],
    this.allergies = const [],
    this.treatments = const [],
    this.observations = const [],
    this.antecedents = const [],
    this.documents = const [],
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
      observations: (json['observations'] as List? ?? [])
          .map((e) => DossierEntry.fromJson((e as Map).cast<String, dynamic>(), 'observation'))
          .toList(),
      antecedents: (json['antecedents'] as List? ?? [])
          .map((e) => DossierEntry.fromJson((e as Map).cast<String, dynamic>(), 'antecedent'))
          .toList(),
      documents: (json['documents'] as List? ?? [])
          .map((e) => DossierDocument.fromJson((e as Map).cast<String, dynamic>()))
          .toList(),
    );
  }

  bool get isEmpty =>
      consultations.isEmpty &&
      prescriptions.isEmpty &&
      allergies.isEmpty &&
      treatments.isEmpty &&
      observations.isEmpty &&
      antecedents.isEmpty &&
      documents.isEmpty;
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
  final String? authorLabel;
  final bool canEdit;

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
    this.authorLabel,
    this.canEdit = false,
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
      authorLabel: json['author_label'],
      canEdit: _canEdit(json),
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
  final String? authorLabel;
  final bool canEdit;

  const PrescriptionItem({
    required this.id,
    this.items = const [],
    this.notes,
    this.date,
    this.doctorName,
    this.authorLabel,
    this.canEdit = false,
  });

  factory PrescriptionItem.fromJson(Map<String, dynamic> json) {
    return PrescriptionItem(
      id: json['id'] ?? 0,
      items: json['items'] is List ? json['items'] as List : const [],
      notes: json['notes'],
      date: json['created_at'],
      doctorName: json['doctor']?['name'] ?? json['doctor_name'],
      authorLabel: json['author_label'],
      canEdit: _canEdit(json),
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
  final String? authorLabel;
  final bool canEdit;
  final DateTime? createdAt;

  const AllergyItem({
    required this.id,
    this.name,
    this.severity,
    this.notes,
    this.authorLabel,
    this.canEdit = false,
    this.createdAt,
  });

  factory AllergyItem.fromJson(Map<String, dynamic> json) {
    return AllergyItem(
      id: json['id'] ?? 0,
      name: json['name'],
      severity: json['severity'],
      notes: json['notes'],
      authorLabel: json['author_label'],
      canEdit: _canEdit(json),
      createdAt: DateTime.tryParse(json['created_at'] ?? ''),
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
  final String? authorLabel;
  final bool canEdit;

  const TreatmentItem({
    required this.id,
    this.type,
    this.date,
    this.plan,
    this.notes,
    this.doctorName,
    this.authorLabel,
    this.canEdit = false,
  });

  factory TreatmentItem.fromJson(Map<String, dynamic> json) {
    return TreatmentItem(
      id: json['id'] ?? 0,
      type: json['type'],
      date: json['consultation_date'],
      plan: json['plan'],
      notes: json['notes'],
      doctorName: json['doctor']?['name'] ?? json['doctor_name'],
      authorLabel: json['author_label'],
      canEdit: _canEdit(json),
    );
  }
}

/// Parent-authored note: observation or antécédent.
class DossierEntry {
  final int id;
  final String type;
  final String? date;
  final String? notes;
  final String? authorLabel;
  final bool canEdit;

  const DossierEntry({
    required this.id,
    required this.type,
    this.date,
    this.notes,
    this.authorLabel,
    this.canEdit = false,
  });

  factory DossierEntry.fromJson(Map<String, dynamic> json, String type) {
    return DossierEntry(
      id: json['id'] ?? 0,
      type: type,
      date: json['date'] ?? json['consultation_date'],
      notes: json['notes'],
      authorLabel: json['author_label'],
      canEdit: _canEdit(json),
    );
  }

  String get label => type == 'antecedent' ? 'Antécédent' : 'Observation';
}

class DossierDocument {
  final int id;
  final String? title;
  final String? type;
  final String? date;
  final String? authorLabel;
  final bool canEdit;
  final String? mimeType;
  final String? originalName;

  const DossierDocument({
    required this.id,
    this.title,
    this.type,
    this.date,
    this.authorLabel,
    this.canEdit = false,
    this.mimeType,
    this.originalName,
  });

  factory DossierDocument.fromJson(Map<String, dynamic> json) {
    return DossierDocument(
      id: json['id'] ?? 0,
      title: json['title'],
      type: json['type'],
      date: json['created_at'],
      authorLabel: json['author_label'],
      canEdit: _canEdit(json),
      mimeType: json['mime_type'],
      originalName: json['original_name'],
    );
  }

  bool get isImage => (mimeType ?? '').startsWith('image/');
  bool get isPdf =>
      (mimeType ?? '').contains('pdf') ||
      (originalName ?? '').toLowerCase().endsWith('.pdf');
}