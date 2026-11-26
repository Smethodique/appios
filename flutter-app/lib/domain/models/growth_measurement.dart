/// Older servers may omit `can_edit`; a parent-authored measure stays editable.
bool _canEdit(Map<String, dynamic> json) {
  final flag = json['can_edit'];
  if (flag is bool) return flag;
  return json['author_label']?.toString().toLowerCase() == 'parent';
}

class GrowthMeasurement {
  final int id;
  final int childId;
  final double? weight;
  final double? height;
  final double? headCircumference;
  final double? bmi;
  final String measuredAt;
  final String? authorLabel;
  final bool canEdit;

  GrowthMeasurement({
    required this.id,
    required this.childId,
    this.weight,
    this.height,
    this.headCircumference,
    this.bmi,
    required this.measuredAt,
    this.authorLabel,
    this.canEdit = true,
  });

  factory GrowthMeasurement.fromJson(Map<String, dynamic> json) {
    final weight = _toDouble(json['weight']);
    final height = _toDouble(json['height']);
    var bmi = _toDouble(json['bmi']);
    if (bmi == null && weight != null && height != null && height > 0) {
      bmi = double.parse((weight / ((height / 100) * (height / 100))).toStringAsFixed(2));
    }
    return GrowthMeasurement(
      id: json['id'] ?? 0,
      childId: json['child_id'] ?? 0,
      weight: weight,
      height: height,
      headCircumference: _toDouble(json['head_circumference']),
      bmi: bmi,
      measuredAt: json['measured_at'] ?? '',
      authorLabel: json['author_label'],
      canEdit: _canEdit(json),
    );
  }

  DateTime? get measuredDateTime {
    final s = measuredAt;
    if (s.isEmpty) return null;
    return DateTime.tryParse(s);
  }

  static double? _toDouble(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString().replaceAll(',', '.'));
  }
}