// Nassreddin — rewritten for the DrImane redesign. This file used to hold nine
// bare colour constants and two near-empty ThemeData objects, and nothing read
// from it: every screen hand-painted its own colours, so dialogs, snack bars
// and date pickers fell back to Material defaults that matched nothing.
//
// It is now the assembly layer: it turns `app_tokens.dart` into a complete
// ThemeData with component themes, so unstyled Material surfaces look right by
// default. The original constants are kept as aliases so nothing breaks.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:medcin_app/core/theme/app_tokens.dart';

/// Typography: Fredoka for display, Nunito for everything else.
///
/// Nassreddin — the previous `fontFamily: 'Inter'` was a dead string (no font
/// by that name ships with the app). Both faces below are resolved through the
/// google_fonts package that is already a dependency (6.3.3 in pubspec.lock,
/// which includes both families). For production, bundling the .ttf files
/// under assets/fonts/ removes the first-launch network fetch.
abstract final class AppTypography {
  /// Rounded display face for headings. Fredoka ships w300–w700.
  static TextStyle display(double size, {Color? color, double height = 1.2}) =>
      GoogleFonts.fredoka(
        fontSize: size,
        fontWeight: FontWeight.w600,
        color: color ?? AppColors.forest,
        height: height,
      );

  /// Workhorse sans. Nunito ships w200–w900.
  static TextStyle sans(
    double size, {
    FontWeight weight = FontWeight.w400,
    Color? color,
    double height = 1.4,
    double? letterSpacing,
  }) =>
      GoogleFonts.nunito(
        fontSize: size,
        fontWeight: weight,
        color: color ?? AppColors.textPrimary,
        height: height,
        letterSpacing: letterSpacing,
      );

  static TextTheme textTheme(Color onSurface, Color muted) => TextTheme(
        displayLarge: display(28, color: onSurface),
        displayMedium: display(22, color: onSurface),
        displaySmall: display(18, color: onSurface),
        titleLarge: sans(18, weight: FontWeight.w800, color: onSurface),
        titleMedium: sans(16, weight: FontWeight.w800, color: onSurface),
        titleSmall: sans(15, weight: FontWeight.w700, color: onSurface),
        bodyLarge: sans(15, color: onSurface),
        bodyMedium: sans(13.5, color: onSurface),
        bodySmall: sans(12, color: muted),
        labelLarge: sans(14, weight: FontWeight.w800, color: onSurface),
        labelMedium: sans(12, weight: FontWeight.w800, color: onSurface),
        labelSmall: sans(11, weight: FontWeight.w700, color: muted),
      );
}

class AppTheme {
  // Nassreddin — aliases kept so any existing reference still resolves.
  // Prefer `AppColors` in new code.
  static const Color primary = AppColors.forest;
  static const Color primarySoft = AppColors.stage;
  static const Color accent = AppColors.sage;
  static const Color backgroundLight = AppColors.canvas;
  static const Color surface = AppColors.surface;
  static const Color textPrimary = AppColors.textPrimary;
  static const Color textMuted = AppColors.textMuted;
  static const Color danger = AppColors.danger;

  /// The parent app theme: pale mint canvas, forest ink, sage buttons.
  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.forest,
      brightness: Brightness.light,
      primary: AppColors.forest,
      onPrimary: AppColors.textOnDark,
      secondary: AppColors.sage,
      surface: AppColors.surface,
      onSurface: AppColors.textPrimary,
      error: AppColors.danger,
      outline: AppColors.border,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.canvas,
      canvasColor: AppColors.surface,
      textTheme: AppTypography.textTheme(AppColors.textPrimary, AppColors.textMuted),
      splashFactory: InkSparkle.splashFactory,

      appBarTheme: AppBarThemeData(
        backgroundColor: AppColors.canvas,
        foregroundColor: AppColors.forest,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        titleTextStyle: AppTypography.display(20),
        iconTheme: const IconThemeData(color: AppColors.forest, size: 22),
      ),

      inputDecorationTheme: InputDecorationThemeData(
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
        border: const OutlineInputBorder(borderRadius: AppRadius.mdAll, borderSide: BorderSide.none),
        enabledBorder: const OutlineInputBorder(borderRadius: AppRadius.mdAll, borderSide: BorderSide(color: AppColors.border)),
        focusedBorder: const OutlineInputBorder(borderRadius: AppRadius.mdAll, borderSide: BorderSide(color: AppColors.sage, width: 1.6)),
        errorBorder: const OutlineInputBorder(borderRadius: AppRadius.mdAll, borderSide: BorderSide(color: AppColors.danger, width: 1.4)),
        focusedErrorBorder: const OutlineInputBorder(borderRadius: AppRadius.mdAll, borderSide: BorderSide(color: AppColors.danger, width: 1.6)),
        hintStyle: AppTypography.sans(14, color: AppColors.textMuted),
        labelStyle: AppTypography.sans(14, color: AppColors.textMuted),
        floatingLabelStyle: AppTypography.sans(14, weight: FontWeight.w700, color: AppColors.sageText),
        errorStyle: AppTypography.sans(12.5, weight: FontWeight.w700, color: AppColors.danger),
        prefixIconColor: AppColors.sageText,
        suffixIconColor: AppColors.textMuted,
      ),

      cardTheme: const CardThemeData(
        color: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.lgAll),
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.forest,
        contentTextStyle: AppTypography.sans(14, weight: FontWeight.w600, color: AppColors.textOnDark),
        actionTextColor: AppColors.amber,
        behavior: SnackBarBehavior.floating,
        elevation: 4,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.xlAll),
        titleTextStyle: AppTypography.display(19),
        contentTextStyle: AppTypography.sans(14, color: AppColors.textSecondary, height: 1.5),
      ),

      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.sheetTop),
        showDragHandle: true,
        dragHandleColor: AppColors.border,
      ),

      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surface,
        selectedColor: AppColors.sage,
        checkmarkColor: AppColors.textOnDark,
        side: const BorderSide(color: AppColors.border),
        labelStyle: AppTypography.sans(12, weight: FontWeight.w800, color: AppColors.textSecondary),
        secondaryLabelStyle: AppTypography.sans(12, weight: FontWeight.w800, color: AppColors.textOnDark),
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.pillAll),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xxs),
      ),

      datePickerTheme: DatePickerThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        headerBackgroundColor: AppColors.forest,
        headerForegroundColor: AppColors.textOnDark,
        todayBorder: const BorderSide(color: AppColors.sage),
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.xlAll),
      ),

      timePickerTheme: TimePickerThemeData(
        backgroundColor: AppColors.surface,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.xlAll),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.sage,
          foregroundColor: AppColors.textOnDark,
          disabledBackgroundColor: AppColors.border,
          disabledForegroundColor: AppColors.textMuted,
          elevation: 0,
          minimumSize: const Size.fromHeight(52),
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
          textStyle: AppTypography.sans(15, weight: FontWeight.w800),
        ),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.sage,
          foregroundColor: AppColors.textOnDark,
          minimumSize: const Size.fromHeight(52),
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
          textStyle: AppTypography.sans(15, weight: FontWeight.w800),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.sageText,
          textStyle: AppTypography.sans(14, weight: FontWeight.w800),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.forest,
          side: const BorderSide(color: AppColors.border, width: 1.5),
          minimumSize: const Size.fromHeight(52),
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
          textStyle: AppTypography.sans(15, weight: FontWeight.w800),
        ),
      ),

      dividerTheme: const DividerThemeData(color: AppColors.border, thickness: 1, space: 1),

      listTileTheme: ListTileThemeData(
        iconColor: AppColors.sageText,
        titleTextStyle: AppTypography.sans(15, weight: FontWeight.w700),
        subtitleTextStyle: AppTypography.sans(13, color: AppColors.textMuted),
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
      ),

      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.sage,
        linearTrackColor: AppColors.recess,
      ),

      iconTheme: const IconThemeData(color: AppColors.forest, size: 22),
    );
  }

  /// Dark theme for the doctor side (video calls, room, live sessions).
  /// Nassreddin — the doctor screens are still in development and were left
  /// untouched; this theme only gives them matching fonts.
  static ThemeData dark() {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.forest,
      brightness: Brightness.dark,
      primary: AppColors.sage,
      onPrimary: AppColors.textOnDark,
      surface: AppColors.stage,
      onSurface: AppColors.textOnDark,
      error: AppColors.danger,
    );
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.stage,
      textTheme: AppTypography.textTheme(AppColors.textOnDark, const Color(0xFF9DB8AB)),
      appBarTheme: const AppBarThemeData(
        backgroundColor: AppColors.stageRaised,
        foregroundColor: AppColors.textOnDark,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      iconTheme: const IconThemeData(color: AppColors.textOnDark, size: 22),
    );
  }
}
