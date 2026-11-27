// Nassreddin — new file. The in-app guide, in the style of iOS feature tips:
// the live screen dims, a glowing ring glides to the control the parent should
// tap, a pulse marks the tap, and a white callout explains the step. It runs
// over the real screen rather than over screenshots, so it never goes stale.
//
// Usage: give each target widget a GlobalKey, then
//   SpotlightTour.show(context, steps: [...], onFinished: () {...});

import 'package:flutter/material.dart';
import 'package:medcin_app/core/theme/app_theme.dart';
import 'package:medcin_app/core/theme/app_tokens.dart';

class TourStep {
  final GlobalKey target;
  final String title;
  final String body;

  /// Extra space between the control and the ring.
  final double padding;

  /// Ring corner radius. Defaults to a circle for round targets.
  final double? radius;

  const TourStep({
    required this.target,
    required this.title,
    required this.body,
    this.padding = 8,
    this.radius,
  });
}

class SpotlightTour extends StatefulWidget {
  final List<TourStep> steps;
  final VoidCallback onFinished;

  const SpotlightTour({super.key, required this.steps, required this.onFinished});

  /// Inserts the tour into the root overlay so it also covers the bottom menu.
  static void show(
    BuildContext context, {
    required List<TourStep> steps,
    required VoidCallback onFinished,
  }) {
    final overlay = Overlay.of(context, rootOverlay: true);
    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => SpotlightTour(
        steps: steps,
        onFinished: () {
          entry.remove();
          onFinished();
        },
      ),
    );
    overlay.insert(entry);
  }

  @override
  State<SpotlightTour> createState() => _SpotlightTourState();
}

class _SpotlightTourState extends State<SpotlightTour> with SingleTickerProviderStateMixin {
  int _index = 0;
  late final AnimationController _pulse =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1500))..repeat();

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  /// Target rectangle in overlay (global) coordinates, padded. Null when the
  /// target is not currently laid out, in which case the step is skipped.
  Rect? _rectFor(TourStep step) {
    final ctx = step.target.currentContext;
    final box = ctx?.findRenderObject();
    if (box is! RenderBox || !box.hasSize) return null;
    final topLeft = box.localToGlobal(Offset.zero);
    return (topLeft & box.size).inflate(step.padding);
  }

  void _next() {
    if (_index >= widget.steps.length - 1) {
      widget.onFinished();
      return;
    }
    setState(() => _index++);
  }

  @override
  Widget build(BuildContext context) {
    final step = widget.steps[_index];
    final rect = _rectFor(step);
    if (rect == null) {
      // Skip steps whose control is off-screen or not built yet.
      WidgetsBinding.instance.addPostFrameCallback((_) => _next());
      return const SizedBox.shrink();
    }
    final screen = MediaQuery.sizeOf(context);
    final radius = step.radius ?? rect.shortestSide / 2;
    final isRound = step.radius == null;

    return Material(
      type: MaterialType.transparency,
      // The ring glides between steps; RectTween with a null begin places the
      // first ring instantly instead of flying it in from a corner.
      child: TweenAnimationBuilder<Rect?>(
        tween: RectTween(end: rect),
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOutCubic,
        builder: (context, r, _) {
          final cur = r ?? rect;
          final rad = isRound ? cur.shortestSide / 2 : radius;
          final calloutBelow = cur.bottom + 16 + 190 < screen.height - 20;
          return Stack(
            children: [
              // Scrim with the cutout, the glowing ring and the tap pulse.
              Positioned.fill(
                child: AnimatedBuilder(
                  animation: _pulse,
                  builder: (_, __) => CustomPaint(
                    painter: _SpotlightPainter(cur, rad, _pulse.value),
                  ),
                ),
              ),
              // Absorb taps everywhere except the buttons below.
              Positioned.fill(child: GestureDetector(onTap: () {}, behavior: HitTestBehavior.opaque)),
              Positioned(
                left: 18,
                right: 18,
                top: calloutBelow ? cur.bottom + 16 : null,
                bottom: calloutBelow ? null : screen.height - cur.top + 16,
                child: _Callout(
                  index: _index,
                  count: widget.steps.length,
                  title: step.title,
                  body: step.body,
                  onSkip: widget.onFinished,
                  onNext: _next,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SpotlightPainter extends CustomPainter {
  final Rect target;
  final double radius;
  final double pulse; // 0 → 1

  const _SpotlightPainter(this.target, this.radius, this.pulse);

  @override
  void paint(Canvas canvas, Size size) {
    final rrect = RRect.fromRectAndRadius(target, Radius.circular(radius));
    final scrim = Path.combine(
      PathOperation.difference,
      Path()..addRect(Offset.zero & size),
      Path()..addRRect(rrect),
    );
    canvas.drawPath(scrim, Paint()..color = const Color(0xFF03140F).withValues(alpha: 0.74));

    // Static ring with glow.
    canvas.drawRRect(
      rrect.inflate(3),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..color = AppColors.amber
        ..maskFilter = const MaskFilter.blur(BlurStyle.outer, 10),
    );
    canvas.drawRRect(
      rrect.inflate(3),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..color = AppColors.amber,
    );
    // Expanding pulse ring.
    final grow = 3 + pulse * 14;
    canvas.drawRRect(
      rrect.inflate(grow),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = AppColors.amber.withValues(alpha: (1 - pulse) * 0.9),
    );
    // Tap marker at the centre: shrinks to 72% mid-cycle and back, like a press.
    final tapScale = 1 - 0.28 * (1 - (pulse * 2 - 1).abs());
    final c = target.center;
    canvas.drawCircle(c, 11 * tapScale, Paint()..color = AppColors.amber.withValues(alpha: 0.45));
    canvas.drawCircle(c, 8 * tapScale, Paint()..color = Colors.white.withValues(alpha: 0.95));
  }

  @override
  bool shouldRepaint(_SpotlightPainter old) =>
      old.target != target || old.radius != radius || old.pulse != pulse;
}

class _Callout extends StatelessWidget {
  final int index;
  final int count;
  final String title;
  final String body;
  final VoidCallback onSkip;
  final VoidCallback onNext;

  const _Callout({
    required this.index,
    required this.count,
    required this.title,
    required this.body,
    required this.onSkip,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.lgAll,
        boxShadow: AppShadows.raised,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Étape ${index + 1} sur $count',
            style: AppTypography.sans(10.5, weight: FontWeight.w800, color: AppColors.sageText, letterSpacing: 1.2),
          ),
          const SizedBox(height: 4),
          Text(title, style: AppTypography.display(19)),
          const SizedBox(height: 5),
          Text(body, style: AppTypography.sans(13, color: AppColors.textSecondary, height: 1.5)),
          const SizedBox(height: 13),
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    for (var i = 0; i < count; i++)
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.only(right: 5),
                        width: i == index ? 18 : 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: i == index ? AppColors.amber : AppColors.border,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                  ],
                ),
              ),
              TextButton(
                onPressed: onSkip,
                style: TextButton.styleFrom(foregroundColor: AppColors.textMuted),
                child: const Text('Passer'),
              ),
              const SizedBox(width: 4),
              FilledButton(
                onPressed: onNext,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.amber,
                  foregroundColor: AppColors.forest,
                  minimumSize: const Size(0, 40),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  shape: const RoundedRectangleBorder(borderRadius: AppRadius.smAll),
                  textStyle: AppTypography.sans(13, weight: FontWeight.w800),
                ),
                child: Text(index == count - 1 ? 'Terminer' : 'Suivant'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
