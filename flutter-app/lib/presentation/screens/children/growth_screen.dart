import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:medcin_app/data/repositories/child_repository.dart';
import 'package:medcin_app/domain/models/child.dart';
import 'package:medcin_app/domain/models/growth_measurement.dart';
import 'package:medcin_app/utils/formatters.dart';
import 'package:medcin_app/utils/who_percentiles.dart';

class GrowthScreen extends StatefulWidget {
  final Child child;
  const GrowthScreen({super.key, required this.child});

  int get childId => child.id;

  @override
  State<GrowthScreen> createState() => _GrowthScreenState();
}

class _GrowthScreenState extends State<GrowthScreen> {
  List<GrowthMeasurement> _items = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final items = await ChildRepository.growthData(widget.childId);
      items.sort((a, b) {
        final da = a.measuredDateTime;
        final db = b.measuredDateTime;
        if (da == null || db == null) return 0;
        return da.compareTo(db);
      });
      if (mounted) setState(() => _items = items);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  DateTime? get _birthDate {
    final s = widget.child.birthDate;
    if (s == null || s.isEmpty) return null;
    return DateTime.tryParse(s);
  }

  double _ageMonths(DateTime measuredAt) {
    final birth = _birthDate;
    if (birth == null) return -1;
    final months = (measuredAt.year - birth.year) * 12 +
        (measuredAt.month - birth.month) +
        (measuredAt.day - birth.day) / 30.44;
    return months < 0 ? 0 : months;
  }

  bool get _hasRef => _birthDate != null && widget.child.gender != null;

  WhoReference get _ref => WhoReference.forGender(widget.child.gender);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F1EA),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFBD7F66)))
          : RefreshIndicator(
              onRefresh: _load,
              color: const Color(0xFFBD7F66),
              child: ListView(
                padding: const EdgeInsets.only(bottom: 90),
                children: [
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(_error!,
                          style: const TextStyle(color: Color(0xFFEF4444))),
                    ),
                  if (_items.isNotEmpty) _summaryCard(),
                  if (!_hasRef)
                    const Padding(
                      padding: EdgeInsets.fromLTRB(20, 8, 20, 0),
                      child: Text(
                        'Précisez la date de naissance et le genre dans l’édition du profil pour afficher les percentiles OMS.',
                        style: TextStyle(color: Color(0xFFA69D8F), fontSize: 12),
                      ),
                    ),
                  if (_items.length < 2)
                    const Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(
                        child: Text(
                          'Ajoutez au moins 2 mesures pour afficher la courbe de croissance.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Color(0xFFA69D8F)),
                        ),
                      ),
                    ),
                  if (_hasWeight(_items)) _weightChart(),
                  if (_hasHeight(_items)) _heightChart(),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                    child: Text('Historique des mesures',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFFBD7F66))),
                  ),
                  ..._items.reversed.map((m) => _measureCard(m)),
                ],
              ),
            ),
    );
  }

  Widget _summaryCard() {
    final last = _items.last;
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFBD7F66),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _summaryItem(last.weight, 'kg', 'Poids'),
          _summaryItem(last.height, 'cm', 'Taille'),
          _summaryItem(last.headCircumference, 'cm', 'Périmètre crânien'),
          _summaryItem(last.bmi, '', 'IMC'),
        ],
      ),
    );
  }

  Widget _summaryItem(double? value, String unit, String label) {
    return Column(
      children: [
        Text(value == null ? '—' : '${value.toStringAsFixed(1)}$unit',
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15)),
        const SizedBox(height: 3),
        Text(label,
            style: const TextStyle(color: Color(0xFFBFDCCD), fontSize: 10.5)),
      ],
    );
  }

  bool _hasWeight(List<GrowthMeasurement> items) =>
      items.where((m) => m.weight != null).length >= 2;
  bool _hasHeight(List<GrowthMeasurement> items) =>
      items.where((m) => m.height != null).length >= 2;

  Widget _weightChart() {
    return _metricChartCard(
      title: 'Poids (kg)',
      dataColor: const Color(0xFFBD7F66),
      metric: 0,
      unit: 'kg',
      yPadding: 2,
      points: _items
          .where((m) => m.weight != null)
          .map((m) => (
                x: _hasRef
                    ? _ageMonths(m.measuredDateTime!)
                    : _indexOf(m).toDouble(),
                y: m.weight!,
                label:
                    '${Formatters.date(m.measuredAt)} · ${m.weight!.toStringAsFixed(1)} kg',
              ))
          .toList(),
    );
  }

  Widget _heightChart() {
    return _metricChartCard(
      title: 'Taille (cm)',
      dataColor: const Color(0xFF2563EB),
      metric: 1,
      unit: 'cm',
      yPadding: 5,
      points: _items
          .where((m) => m.height != null)
          .map((m) => (
                x: _hasRef
                    ? _ageMonths(m.measuredDateTime!)
                    : _indexOf(m).toDouble(),
                y: m.height!,
                label:
                    '${Formatters.date(m.measuredAt)} · ${m.height!.toStringAsFixed(1)} cm',
              ))
          .toList(),
    );
  }

  int _indexOf(GrowthMeasurement m) => _items.indexOf(m);

  Widget _metricChartCard({
    required String title,
    required Color dataColor,
    required int metric,
    required String unit,
    required double yPadding,
    required List<({double x, double y, String label})> points,
  }) {
    final ys = points.map((p) => p.y).toList();
    double axisMin;
    double axisMax;
    if (points.length == 1) {
      axisMin = points.first.y - yPadding;
      axisMax = points.first.y + yPadding;
    } else {
      axisMin = ys.reduce(math.min) - yPadding;
      axisMax = ys.reduce(math.max) + yPadding;
    }
    if (axisMin < 0) axisMin = 0;
    if (points.isEmpty) {
      axisMin = 0;
      axisMax = 10;
    }
    if (axisMax - axisMin < 1e-6) axisMax = axisMin + yPadding * 2;

    final maxDataX =
        points.fold<double>(0, (mx, p) => p.x > mx ? p.x : mx);
    final maxX = (math.max(maxDataX + 0.5, 1.0) * 100).round() / 100;

    final who = _hasRef ? _ref : null;
    final p3 = who == null
        ? const <FlSpot>[]
        : _whoCurve(
            metric: metric,
            pick: (a) => who.p3At(metric, a),
            upToX: maxX,
            axisMin: axisMin,
            axisMax: axisMax);
    final p50 = who == null
        ? const <FlSpot>[]
        : _whoCurve(
            metric: metric,
            pick: (a) => who.p50At(metric, a),
            upToX: maxX,
            axisMin: axisMin,
            axisMax: axisMax);
    final p97 = who == null
        ? const <FlSpot>[]
        : _whoCurve(
            metric: metric,
            pick: (a) => who.p97At(metric, a),
            upToX: maxX,
            axisMin: axisMin,
            axisMax: axisMax);

    final xInterval =
        maxX <= 6 ? 1.0 : (maxX / 6).ceilToDouble().clamp(1.0, 24.0);
    final ySpan = axisMax - axisMin;
    final labelsByX = <String, String>{
      for (final p in points) p.x.toStringAsFixed(3): p.label,
    };

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
              color: const Color(0xFFBD7F66).withValues(alpha: 0.06),
              blurRadius: 20,
              offset: const Offset(0, 6)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFFBD7F66))),
          const SizedBox(height: 12),
          SizedBox(
            height: 230,
            child: LineChart(
              LineChartData(
                minX: 0,
                maxX: maxX,
                minY: axisMin,
                maxY: axisMax,
                gridData: FlGridData(
                  drawVerticalLine: false,
                  horizontalInterval: ySpan / 5,
                  getDrawingHorizontalLine: (v) => const FlLine(
                    color: Color(0xFFE8E2D8),
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 38,
                      getTitlesWidget: (v, meta) => Text(
                        ySpan > 30 ? v.toStringAsFixed(0) : v.toStringAsFixed(1),
                        style: const TextStyle(color: Color(0xFFA69D8F), fontSize: 11),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 26,
                      interval: xInterval,
                      getTitlesWidget: (v, meta) => Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          '${(v).round()} mois',
                          style: const TextStyle(color: Color(0xFFA69D8F), fontSize: 9.5),
                        ),
                      ),
                    ),
                  ),
                ),
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    tooltipBgColor: const Color(0xFFBD7F66),
                    getTooltipItems: (tool) => tool.map((s) {
                      final key = s.x.toStringAsFixed(3);
                      final label = labelsByX[key] ??
                          '${s.x.round()} mois · ${s.y.toStringAsFixed(1)} $unit';
                      return LineTooltipItem(label,
                          const TextStyle(color: Colors.white, fontSize: 12));
                    }).toList(),
                  ),
                ),
                betweenBarsData: p3.isEmpty || p97.isEmpty
                    ? const []
                    : [
                        BetweenBarsData(
                          fromIndex: 0,
                          toIndex: 1,
                          color: const Color(0xFFA69D8F).withValues(alpha: 0.08),
                        ),
                      ],
                lineBarsData: [
                  _whoBar(p97, const Color(0xFFA69D8F)),
                  _whoBar(p3, const Color(0xFFA69D8F)),
                  LineChartBarData(
                    spots: p50.isEmpty ? const [FlSpot(0, 0)] : p50,
                    color: const Color(0xFFA69D8F).withValues(alpha: 0.6),
                    barWidth: 1.6,
                    isCurved: true,
                    dashArray: [8, 5],
                    dotData: const FlDotData(show: false),
                  ),
                  LineChartBarData(
                    spots: points.isEmpty
                        ? const [FlSpot(0, 0)]
                        : points.map((p) => FlSpot(p.x, p.y)).toList(),
                    color: dataColor,
                    barWidth: 3,
                    isCurved: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) =>
                          FlDotCirclePainter(
                        radius: 4.5,
                        color: dataColor,
                        strokeWidth: 2,
                        strokeColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 14,
            runSpacing: 4,
            children: [
              _LegendDot(color: dataColor, label: 'Enfant'),
              const _LegendDot(
                  color: Color(0xFFA69D8F),
                  label: 'Percentiles OMS (P3 · P50 · P97)',
                  dashed: true),
            ],
          ),
        ],
      ),
    );
  }

  List<FlSpot> _whoCurve({
    required int metric,
    required double Function(double age) pick,
    required double upToX,
    required double axisMin,
    required double axisMax,
  }) {
    final spots = <FlSpot>[];
    final end = math.min(upToX, 24.0);
    final step = end > 12 ? 0.5 : 0.25;
    for (var a = 0.0; a <= end + 1e-6; a += step) {
      final who = _ref;
      final p3 = who.p3At(metric, a);
      final p97 = who.p97At(metric, a);
      spots.add(FlSpot(a, _mapWho(pick(a), p3, p97, axisMin, axisMax)));
    }
    return spots;
  }

  double _mapWho(double v, double p3, double p97, double axisMin, double axisMax) {
    final span = p97 - p3;
    if (span <= 0) return (axisMin + axisMax) / 2;
    final t = ((v - p3) / span).clamp(0.0, 1.0);
    return axisMin + t * (axisMax - axisMin);
  }

  LineChartBarData _whoBar(List<FlSpot> spots, Color color) {
    return LineChartBarData(
      spots: spots.isEmpty ? const [FlSpot(0, 0)] : spots,
      color: color.withValues(alpha: 0.55),
      barWidth: 1.2,
      isCurved: true,
      dashArray: [4, 4],
      dotData: const FlDotData(show: false),
    );
  }

  Widget _measureCard(GrowthMeasurement m) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: const Color(0xFFBD7F66).withValues(alpha: 0.05),
              blurRadius: 14,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFFBD7F66).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.monitor_weight_rounded, color: Color(0xFFBD7F66)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(Formatters.date(m.measuredAt),
                    style: const TextStyle(
                        color: Color(0xFF2C2B22), fontWeight: FontWeight.w700, fontSize: 14.5)),
                const SizedBox(height: 3),
                Text(
                  [
                    if (m.weight != null) '${m.weight!.toStringAsFixed(2)} kg',
                    if (m.height != null) '${m.height!.toStringAsFixed(2)} cm',
                    if (m.headCircumference != null)
                      'PC ${m.headCircumference!.toStringAsFixed(2)} cm',
                    if (m.bmi != null) 'IMC ${m.bmi!.toStringAsFixed(1)}',
                  ].join(' · '),
                  style: const TextStyle(color: Color(0xFF8B8173), fontSize: 12.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  final bool dashed;
  const _LegendDot({required this.color, required this.label, this.dashed = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: dashed ? 14 : 10,
          height: dashed ? 3 : 10,
          decoration: BoxDecoration(
            color: dashed ? Colors.transparent : color,
            shape: dashed ? BoxShape.rectangle : BoxShape.circle,
            border: dashed ? Border.all(color: color) : null,
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(color: Color(0xFF8B8173), fontSize: 11)),
      ],
    );
  }
}