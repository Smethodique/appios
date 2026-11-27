// Nassreddin — new file. Design tokens for the DrImane redesign (November 2026).
// Single source of truth for colour, spacing, radius and shadow. Screens read
// from here instead of writing `Color(0x...)` inline, so a palette change is a
// one-file change. `app_theme.dart` assembles these into ThemeData.

import 'package:flutter/material.dart';

/// Colour roles. Named by purpose, never by appearance.
///
/// The palette: a pale mint canvas, deep forest for the header shape and the
/// navigation bar, sage for buttons, tan and amber as accents. Amber is the one
/// colour that means "tap me" and is used sparingly on purpose.
abstract final class AppColors {
  // ---------------------------------------------------------------- canvas
  /// Scaffold background.
  static const Color canvas = Color(0xFFEEF3EF);

  /// Cards, sheets, dialogs, app bars.
  static const Color surface = Color(0xFFFFFFFF);

  /// Recessed fills: text fields, inert chips, table stripes.
  static const Color recess = Color(0xFFE2EBE4);

  /// Hairline dividers and outlines.
  static const Color border = Color(0xFFCFDCD3);

  // ---------------------------------------------------------------- forest
  /// The identity green. Header dome, navigation bar, headings, text ink.
  static const Color forest = Color(0xFF0C3B2E);

  /// Lighter forest, top of the header gradient.
  static const Color forestLight = Color(0xFF134A3B);

  /// Darkest forest, bottom of the navigation bar gradient.
  static const Color forestDeep = Color(0xFF082A21);

  // ---------------------------------------------------------------- sage
  /// Buttons and icon fills. White on sage is 3.3:1 — fine for icons and for
  /// bold button labels, never for body text (use [sageText] for text).
  static const Color sage = Color(0xFF6D9773);
  static const Color sageLight = Color(0xFF8BB391);
  static const Color sageDeep = Color(0xFF5B8562);
  static const Color sageTint = Color(0xFFDDEBE1);

  /// Sage as text, darkened so it reads on the canvas (5.6:1).
  static const Color sageText = Color(0xFF3E6B4B);

  // ---------------------------------------------------------------- tan
  static const Color tan = Color(0xFFBB8A52);
  static const Color tanLight = Color(0xFFD8AA74);
  static const Color tanDeep = Color(0xFFA6773F);
  static const Color tanTint = Color(0xFFF3E6D6);

  /// Tan as text (prices, emphasis) — darkened to pass on the canvas.
  static const Color tanText = Color(0xFF8A5A24);

  // ---------------------------------------------------------------- amber
  /// The action highlight: Rendez-vous disc, active tab disc, play buttons,
  /// calendar selection. Always carries [forest] ink on top (7.3:1).
  static const Color amber = Color(0xFFFFBA00);
  static const Color amberLight = Color(0xFFFFD15A);
  static const Color amberDeep = Color(0xFFF0A800);
  static const Color amberTint = Color(0xFFFFF1C9);

  /// Amber as text on light surfaces.
  static const Color amberText = Color(0xFF7A5310);

  // ---------------------------------------------------------------- text
  static const Color textPrimary = forest;
  static const Color textSecondary = Color(0xFF3F5E52);
  static const Color textMuted = Color(0xFF52706B);
  static const Color textOnDark = Color(0xFFFFFFFF);

  // ---------------------------------------------------------------- status
  static const Color success = Color(0xFF3E6B4B);
  static const Color successTint = Color(0xFFDCEBDF);
  static const Color warning = Color(0xFF8A5E10);
  static const Color warningTint = Color(0xFFF7EBCD);
  static const Color danger = Color(0xFFA8321F);
  static const Color dangerTint = Color(0xFFF7DAD4);

  // ---------------------------------------------------------------- doctor side
  // Nassreddin — the doctor screens keep their dark stage; untouched by the
  // redesign. These two exist so the dark theme has named values.
  static const Color stage = Color(0xFF0A0F1D);
  static const Color stageRaised = Color(0xFF0F172A);
}

/// Two-stop gradients used for discs, bubbles and the header.
abstract final class AppGradients {
  static const LinearGradient header = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.forestLight, AppColors.forest],
  );
  static const LinearGradient navBar = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF0A2F25), Color(0xFF04170F)],
  );
  static const LinearGradient sage = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.sageLight, AppColors.sageDeep],
  );
  static const LinearGradient amber = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.amberLight, AppColors.amberDeep],
  );
  static const LinearGradient tan = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.tanLight, AppColors.tanDeep],
  );
  static const LinearGradient button = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [Color(0xFF7FA886), Color(0xFF5F8966)],
  );
  static const LinearGradient tile = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFFFFFF), Color(0xFFF2F7F3)],
  );
}

/// 4pt spacing scale.
abstract final class AppSpacing {
  static const double xxs = 4;
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 20;
  static const double xl = 24;
  static const double xxl = 32;
  static const double gutter = 20;
}

/// Corner radii. One radius for cards (22) so nothing competes.
abstract final class AppRadius {
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 22;
  static const double xl = 28;
  static const double pill = 999;

  static const BorderRadius smAll = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius mdAll = BorderRadius.all(Radius.circular(md));
  static const BorderRadius lgAll = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius xlAll = BorderRadius.all(Radius.circular(xl));
  static const BorderRadius pillAll = BorderRadius.all(Radius.circular(pill));
  static const BorderRadius sheetTop = BorderRadius.vertical(top: Radius.circular(xl));
}

/// Shadows: always a low-alpha forest, never a saturated colour.
abstract final class AppShadows {
  static final List<BoxShadow> card = [
    BoxShadow(
      color: AppColors.forest.withValues(alpha: 0.07),
      blurRadius: 22,
      offset: const Offset(0, 8),
    ),
  ];
  static final List<BoxShadow> disc = [
    BoxShadow(
      color: const Color(0xFF000000).withValues(alpha: 0.22),
      blurRadius: 24,
      offset: const Offset(0, 12),
    ),
  ];
  static final List<BoxShadow> raised = [
    BoxShadow(
      color: AppColors.forest.withValues(alpha: 0.12),
      blurRadius: 28,
      offset: const Offset(0, 10),
    ),
  ];
}
