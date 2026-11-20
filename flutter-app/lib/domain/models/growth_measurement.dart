class GrowthMeasurement {
  final int id;
  final int childId;
  final double? weight;
  final double? height;
  final double? headCircumference;
  final double? bmi;
  final String measuredAt;

  GrowthMeasurement({
    required this.id,
    required this.childId,
    this.weight,
    this.height,
    this.headCircumference,
    this.bmi,
    required this.measuredAt,
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