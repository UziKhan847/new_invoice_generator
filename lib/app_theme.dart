import 'package:flutter/material.dart';

/// Centralised theme builders for Light / Dark / OLED.
class AppThemes {
  AppThemes._();

  static const _seed = Colors.blue;

  // ── LIGHT ──────────────────────────────────────────────────────────────────
  // The previous light theme used the raw fromSeed ColorScheme which made the
  // scaffold a washed-out grey. This rebuilds it with explicit surfaces so
  // cards and chips look crisp on a true-white background.
  static ThemeData light() {
    final base = ColorScheme.fromSeed(
      seedColor: _seed,
      brightness: Brightness.light,
    );

    final scheme = base.copyWith(
      surface: Colors.white,
      surfaceContainerLowest: Colors.white,
      surfaceContainerLow: const Color(0xFFF7F9FC),
      surfaceContainer: const Color(0xFFEEF2F7),
      surfaceContainerHigh: const Color(0xFFE6EBF2),
      surfaceContainerHighest: const Color(0xFFDFE5ED),
      outlineVariant: const Color(0xFFE2E8F0),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: const Color(0xFFF5F7FA),
      cardTheme: CardThemeData(
        elevation: 0,
        color: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: scheme.outlineVariant.withAlpha(160)),
        ),
        margin: EdgeInsets.zero,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: const Color(0xFFF5F7FA),
        foregroundColor: scheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        indicatorColor: scheme.primaryContainer.withAlpha(140),
        elevation: 1,
      ),
      dividerColor: scheme.outlineVariant.withAlpha(140),
      inputDecorationTheme: _inputTheme(scheme),
      segmentedButtonTheme: _segmentedButtonTheme(scheme),
    );
  }

  // ── DARK (soft, low-glare) ─────────────────────────────────────────────────
  static ThemeData dark() {
    final base = ColorScheme.fromSeed(
      seedColor: _seed,
      brightness: Brightness.dark,
    );

    const scaffold = Color(0xFF15171C);
    const surface = Color(0xFF1C1F26);
    const surfaceHigh = Color(0xFF252932);

    final scheme = base.copyWith(
      surface: surface,
      surfaceContainerLowest: scaffold,
      surfaceContainerLow: surface,
      surfaceContainer: surfaceHigh,
      surfaceContainerHigh: const Color(0xFF2A2F39),
      surfaceContainerHighest: const Color(0xFF323844),
      outlineVariant: const Color(0xFF3A4150),
    );

    return _darkLike(scheme, scaffold: scaffold, cardColor: surface);
  }

  // ── OLED (pure black) ──────────────────────────────────────────────────────
  static ThemeData oled() {
    final base = ColorScheme.fromSeed(
      seedColor: _seed,
      brightness: Brightness.dark,
    );

    const scaffold = Colors.black;
    const surface = Color(
      0xFF0A0A0A,
    ); // very dark, just barely visible vs pure black

    final scheme = base.copyWith(
      surface: surface,
      surfaceContainerLowest: Colors.black,
      surfaceContainerLow: const Color(0xFF080808),
      surfaceContainer: const Color(0xFF111111),
      surfaceContainerHigh: const Color(0xFF161616),
      surfaceContainerHighest: const Color(0xFF1C1C1C),
      outlineVariant: const Color(0xFF222222),
    );

    return _darkLike(scheme, scaffold: scaffold, cardColor: surface);
  }

  // ── Shared dark/OLED builder ───────────────────────────────────────────────
  static ThemeData _darkLike(
    ColorScheme scheme, {
    required Color scaffold,
    required Color cardColor,
  }) {
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: scaffold,
      cardTheme: CardThemeData(
        elevation: 0,
        color: cardColor,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: scheme.outlineVariant.withAlpha(140)),
        ),
        margin: EdgeInsets.zero,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: scaffold,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: cardColor,
        surfaceTintColor: Colors.transparent,
        indicatorColor: scheme.primaryContainer.withAlpha(60),
        elevation: 0,
      ),
      dividerColor: scheme.outlineVariant.withAlpha(120),
      inputDecorationTheme: _inputTheme(scheme),
      segmentedButtonTheme: _segmentedButtonTheme(scheme),
    );
  }

  // ── Shared component themes ────────────────────────────────────────────────
  static InputDecorationTheme _inputTheme(ColorScheme scheme) =>
      InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerLow,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: scheme.primary, width: 1.4),
        ),
      );

  static SegmentedButtonThemeData _segmentedButtonTheme(ColorScheme scheme) =>
      SegmentedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return scheme.primaryContainer.withAlpha(160);
            }
            return Colors.transparent;
          }),
        ),
      );
}
