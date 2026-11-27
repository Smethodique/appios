// Nassreddin — new file. The bottom menu of the redesign: a dark bar with a
// circular notch, and an amber disc sitting in the notch that carries the
// active tab's icon. When the tab changes, notch and disc glide together with a
// small overshoot. `BottomNavigationBar` cannot lift its selected item above
// the bar, which is why this is a custom widget.

import 'package:flutter/material.dart';
import 'package:medcin_app/core/theme/app_theme.dart';
import 'package:medcin_app/core/theme/app_tokens.dart';

class NotchNavItem {
  final IconData icon;
  final String label;

  /// Optional key so the guided tour can point at this tab.
  final GlobalKey? key;

  const NotchNavItem({required this.icon, required this.label, this.key});
}

class NotchNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<NotchNavItem> items;

  const NotchNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
  });

  // Geometry shared by the painter and the disc so they stay aligned.
  static const double _barHeight = 70;
  static const double _lift = 34; // how far the bar top sits below the widget top
  static const double _discSize = 56;
  static const double _notchRadius = 34;
  static const double _sideMargin = 14;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(_sideMargin, 0, _sideMargin, bottomInset > 0 ? bottomInset : 16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final slot = constraints.maxWidth / items.length;
          final targetCx = slot * (currentIndex + 0.5);
          return SizedBox(
            height: _barHeight + _lift,
            // One tween drives both the notch and the disc, so they move as a
            // single object. The overshoot comes from easeOutBack.
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(end: targetCx),
              duration: const Duration(milliseconds: 520),
              curve: Curves.easeOutBack,
              builder: (context, cx, _) {
                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      height: _barHeight,
                      child: CustomPaint(painter: _NotchBarPainter(cx)),
                    ),
                    Positioned(
                      left: cx - _discSize / 2,
                      top: _lift - _discSize / 2 - 4,
                      child: Container(
                        width: _discSize,
                        height: _discSize,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: AppGradients.amber,
                          boxShadow: AppShadows.disc,
                        ),
                      ),
                    ),
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      height: _barHeight,
                      child: Row(
                        children: [
                          for (var i = 0; i < items.length; i++)
                            Expanded(
                              child: _NavSlot(
                                key: items[i].key,
                                item: items[i],
                                active: i == currentIndex,
                                onTap: () => onTap(i),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _NavSlot extends StatelessWidget {
  final NotchNavItem item;
  final bool active;
  final VoidCallback onTap;

  const _NavSlot({super.key, required this.item, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = active ? AppColors.forest : Colors.white.withValues(alpha: 0.62);
    return InkWell(
      onTap: onTap,
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // The active icon rises into the disc; AnimatedContainer tweens the
          // transform with the same spring as the disc.
          AnimatedContainer(
            duration: const Duration(milliseconds: 520),
            curve: Curves.easeOutBack,
            transform: Matrix4.translationValues(0, active ? -38 : 0, 0)..scale(active ? 1.15 : 1.0),
            transformAlignment: Alignment.center,
            child: Icon(item.icon, color: color, size: 22),
          ),
          const SizedBox(height: 4),
          Text(
            item.label,
            style: AppTypography.sans(
              10,
              weight: FontWeight.w800,
              color: active ? Colors.white : Colors.white.withValues(alpha: 0.62),
            ),
          ),
          const SizedBox(height: 11),
        ],
      ),
    );
  }
}

class _NotchBarPainter extends CustomPainter {
  final double cx;
  const _NotchBarPainter(this.cx);

  @override
  void paint(Canvas canvas, Size size) {
    final bar = Path()
      ..addRRect(RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(28)));
    final notch = Path()
      ..addOval(Rect.fromCircle(center: Offset(cx, 0), radius: NotchNavBar._notchRadius));
    final shape = Path.combine(PathOperation.difference, bar, notch);
    final paint = Paint()
      ..shader = AppGradients.navBar.createShader(Offset.zero & size);
    canvas.drawShadow(shape, Colors.black.withValues(alpha: 0.35), 10, false);
    canvas.drawPath(shape, paint);
  }

  @override
  bool shouldRepaint(_NotchBarPainter old) => old.cx != cx;
}
