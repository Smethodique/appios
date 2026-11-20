import 'package:fl_chart/fl_chart.dart';

class WhoPercentile {
  final double p3;
  final double p50;
  final double p97;
  const WhoPercentile(this.p3, this.p50, this.p97);
}

class WhoReference {
  final bool boy;
  final Map<int, WhoPercentile> weight;
  final Map<int, WhoPercentile> height;

  const WhoReference({required this.boy, required this.weight, required this.height});

  WhoPercentile? weightAt(int month) => weight[month];
  WhoPercentile? heightAt(int month) => height[month];

  double? _interpolate(Map<int, WhoPercentile> table, double Function(WhoPercentile) pick, double ageMonths) {
    if (ageMonths <= 0) {
      final first = table[0];
      return first == null ? null : pick(first);
    }
    if (ageMonths >= 24) {
      final last = table[24];
      return last == null ? null : pick(last);
    }
    final lo = ageMonths.floor();
    final hi = lo + 1;
    final a = table[lo];
    final b = table[hi];
    if (a == null || b == null) return null;
    final t = ageMonths - lo;
    return pick(a) + (pick(b) - pick(a)) * t;
  }

  List<FlSpot> line(int metric, double Function(WhoPercentile) pick) {
    final table = metric == 0 ? weight : height;
    final spots = <FlSpot>[];
    for (var m = 0; m <= 24; m++) {
      final p = table[m];
      if (p == null) continue;
      spots.add(FlSpot(m.toDouble(), pick(p)));
    }
    return spots;
  }

  double p3At(int metric, double ageMonths) =>
      _interpolate(metric == 0 ? weight : height, (p) => p.p3, ageMonths) ?? 0;
  double p50At(int metric, double ageMonths) =>
      _interpolate(metric == 0 ? weight : height, (p) => p.p50, ageMonths) ?? 0;
  double p97At(int metric, double ageMonths) =>
      _interpolate(metric == 0 ? weight : height, (p) => p.p97, ageMonths) ?? 0;

  static const WhoReference boys = WhoReference(boy: true, weight: _boysWeight, height: _boysHeight);
  static const WhoReference girls = WhoReference(boy: false, weight: _girlsWeight, height: _girlsHeight);

  static WhoReference forGender(String? gender) =>
      gender == 'girl' || gender == 'female' ? girls : boys;

  static const Map<int, WhoPercentile> _boysWeight = {
    0: WhoPercentile(2.5, 3.3, 4.3),
    1: WhoPercentile(3.4, 4.5, 5.8),
    2: WhoPercentile(4.4, 5.8, 7.1),
    3: WhoPercentile(5.1, 6.4, 8.0),
    4: WhoPercentile(5.6, 7.0, 8.7),
    5: WhoPercentile(6.1, 7.5, 9.3),
    6: WhoPercentile(6.4, 7.9, 9.8),
    7: WhoPercentile(6.7, 8.3, 10.3),
    8: WhoPercentile(7.0, 8.6, 10.7),
    9: WhoPercentile(7.2, 8.9, 11.0),
    10: WhoPercentile(7.5, 9.2, 11.4),
    11: WhoPercentile(7.7, 9.4, 11.7),
    12: WhoPercentile(7.8, 9.6, 12.0),
    13: WhoPercentile(8.0, 9.9, 12.3),
    14: WhoPercentile(8.2, 10.1, 12.6),
    15: WhoPercentile(8.4, 10.3, 12.8),
    16: WhoPercentile(8.5, 10.5, 13.1),
    17: WhoPercentile(8.7, 10.7, 13.4),
    18: WhoPercentile(8.9, 10.9, 13.7),
    19: WhoPercentile(9.1, 11.1, 13.9),
    20: WhoPercentile(9.2, 11.3, 14.2),
    21: WhoPercentile(9.4, 11.5, 14.4),
    22: WhoPercentile(9.6, 11.8, 14.7),
    23: WhoPercentile(9.8, 12.0, 15.0),
    24: WhoPercentile(10.0, 12.2, 15.3),
  };

  static const Map<int, WhoPercentile> _girlsWeight = {
    0: WhoPercentile(2.4, 3.2, 4.2),
    1: WhoPercentile(3.2, 4.2, 5.5),
    2: WhoPercentile(4.0, 5.1, 6.6),
    3: WhoPercentile(4.6, 5.8, 7.5),
    4: WhoPercentile(5.1, 6.4, 8.2),
    5: WhoPercentile(5.5, 6.9, 8.8),
    6: WhoPercentile(5.8, 7.3, 9.3),
    7: WhoPercentile(6.1, 7.6, 9.8),
    8: WhoPercentile(6.3, 7.9, 10.2),
    9: WhoPercentile(6.6, 8.2, 10.5),
    10: WhoPercentile(6.8, 8.5, 10.9),
    11: WhoPercentile(7.0, 8.7, 11.2),
    12: WhoPercentile(7.1, 8.9, 11.5),
    13: WhoPercentile(7.3, 9.2, 11.8),
    14: WhoPercentile(7.5, 9.4, 12.1),
    15: WhoPercentile(7.7, 9.6, 12.4),
    16: WhoPercentile(7.9, 9.8, 12.6),
    17: WhoPercentile(8.1, 10.0, 12.9),
    18: WhoPercentile(8.2, 10.2, 13.2),
    19: WhoPercentile(8.4, 10.4, 13.5),
    20: WhoPercentile(8.6, 10.6, 13.7),
    21: WhoPercentile(8.8, 10.9, 14.0),
    22: WhoPercentile(8.9, 11.1, 14.3),
    23: WhoPercentile(9.1, 11.3, 14.6),
    24: WhoPercentile(9.3, 11.5, 14.8),
  };

  static const Map<int, WhoPercentile> _boysHeight = {
    0: WhoPercentile(46.3, 49.9, 53.4),
    1: WhoPercentile(50.8, 54.7, 58.6),
    2: WhoPercentile(54.4, 58.4, 62.4),
    3: WhoPercentile(57.3, 61.4, 65.5),
    4: WhoPercentile(59.7, 63.9, 68.0),
    5: WhoPercentile(61.7, 65.9, 70.1),
    6: WhoPercentile(63.3, 67.6, 71.9),
    7: WhoPercentile(64.8, 69.2, 73.5),
    8: WhoPercentile(66.2, 70.6, 75.0),
    9: WhoPercentile(67.5, 72.0, 76.5),
    10: WhoPercentile(68.7, 73.3, 77.9),
    11: WhoPercentile(69.9, 74.5, 79.2),
    12: WhoPercentile(71.0, 75.7, 80.5),
    13: WhoPercentile(72.1, 76.9, 81.8),
    14: WhoPercentile(73.1, 78.0, 83.0),
    15: WhoPercentile(74.1, 79.1, 84.2),
    16: WhoPercentile(75.0, 80.2, 85.4),
    17: WhoPercentile(76.0, 81.2, 86.5),
    18: WhoPercentile(76.9, 82.3, 87.7),
    19: WhoPercentile(77.7, 83.2, 88.8),
    20: WhoPercentile(78.6, 84.2, 89.8),
    21: WhoPercentile(79.4, 85.1, 90.9),
    22: WhoPercentile(80.2, 86.0, 91.9),
    23: WhoPercentile(81.0, 86.9, 92.9),
    24: WhoPercentile(81.7, 87.8, 94.0),
  };

  static const Map<int, WhoPercentile> _girlsHeight = {
    0: WhoPercentile(45.6, 49.1, 52.7),
    1: WhoPercentile(49.8, 53.7, 57.6),
    2: WhoPercentile(53.0, 57.1, 61.1),
    3: WhoPercentile(55.6, 59.8, 63.9),
    4: WhoPercentile(57.8, 62.1, 66.4),
    5: WhoPercentile(59.6, 64.0, 68.5),
    6: WhoPercentile(61.2, 65.7, 70.3),
    7: WhoPercentile(62.7, 67.3, 71.9),
    8: WhoPercentile(64.0, 68.7, 73.5),
    9: WhoPercentile(65.3, 70.1, 75.0),
    10: WhoPercentile(66.5, 71.5, 76.4),
    11: WhoPercentile(67.7, 72.8, 77.8),
    12: WhoPercentile(68.9, 74.0, 79.2),
    13: WhoPercentile(70.0, 75.2, 80.5),
    14: WhoPercentile(71.0, 76.4, 81.7),
    15: WhoPercentile(72.0, 77.5, 83.0),
    16: WhoPercentile(73.0, 78.6, 84.2),
    17: WhoPercentile(74.0, 79.7, 85.4),
    18: WhoPercentile(74.9, 80.7, 86.5),
    19: WhoPercentile(75.8, 81.7, 87.6),
    20: WhoPercentile(76.7, 82.7, 88.7),
    21: WhoPercentile(77.5, 83.7, 89.8),
    22: WhoPercentile(78.4, 84.6, 90.8),
    23: WhoPercentile(79.2, 85.5, 91.9),
    24: WhoPercentile(79.9, 86.4, 92.9),
  };
}