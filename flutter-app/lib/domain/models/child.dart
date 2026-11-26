import 'dart:convert';
import 'dart:typed_data';

class Child {
  final int id;
  final String firstName;
  final String lastName;
  final String? birthDate;
  final String? gender;
  final String? bloodGroup;
  final String? relationship;
  final bool validated;
  final String? parentName;
  final String? doctorName;
  final String? photo;
  final int? ageDays;
  final String? ageLabel;
  final List<String> dossierWarnings;

  Child({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.birthDate,
    this.gender,
    this.bloodGroup,
    this.relationship,
    this.validated = false,
    this.parentName,
    this.doctorName,
    this.photo,
    this.ageDays,
    this.ageLabel,
    this.dossierWarnings = const [],
  });

  factory Child.fromJson(Map<String, dynamic> json) {
    final photo = json['photo'] ?? json['photo_url'];
    return Child(
      id: json['id'] ?? 0,
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      birthDate: json['birth_date'],
      gender: json['gender'],
      bloodGroup: json['blood_group'],
      relationship: json['relationship'],
      validated: json['validated_by_doctor'] == true || json['validated'] == true,
      parentName: json['parent']?['name'] ?? json['parent_name'],
      doctorName: json['doctor']?['name'],
      photo: photo is String && photo.isNotEmpty ? photo : null,
      ageDays: _toInt(json['age_days']),
      ageLabel: json['age_label'],
      dossierWarnings: (json['dossier_warnings'] as List? ?? [])
          .map((e) => e.toString())
          .toList(),
    );
  }

  bool get hasPhoto => photo != null && photo!.isNotEmpty;
  bool get isDataUriAware {
    if (!hasPhoto) return false;
    return photo!.contains('data:image');
  }

  Uint8List? get photoBytes {
    if (!isDataUriAware) return null;
    final comma = photo!.indexOf(',');
    if (comma < 0) return null;
    try {
      return Uint8List.fromList(base64Decode(photo!.substring(comma + 1)));
    } catch (_) {
      return null;
    }
  }

  String get fullName => '$firstName $lastName';
  String get displayGender => gender == 'male' ? 'Garçon' : 'Fille';

  static int? _toInt(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }
}
