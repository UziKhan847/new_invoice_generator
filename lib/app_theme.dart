// Markaz Umaza — Invoice App
// Refined-indigo design system with Light / Dark / OLED variants.
//
// Fonts: bundle "Plus Jakarta Sans" and "Spline Sans Mono" in pubspec.yaml.

import 'package:flutter/material.dart';

/// ---------------------------------------------------------------------------
/// PALETTE — a set of resolved colors for one brightness mode.
/// AppColors below exposes the *active* palette so widgets can read tokens
/// without caring which mode is on.
/// ---------------------------------------------------------------------------
class AppPalette {
  final Brightness brightness;

  // Brand
  final Color primary;
  final Color primaryTint; // active pill / chip background
  final Color primaryPanel; // info panel background
  final Color primaryPanelBorder;
  final Color barMuted; // unselected bars
  final Color gold;

  // Neutrals
  final Color ink; // primary text
  final Color textSecondary;
  final Color textTertiary;
  final Color background; // scaffold
  final Color surface; // cards
  final Color surfaceAlt; // slightly raised inner surfaces
  final Color border; // hairline
  final Color cardBorder;

  // Semantic
  final Color successText, successBg, successBorder;
  final Color warningText, warningBg, warningBorder;
  final Color dangerText, dangerBg, dangerBorder;
  final Color purple, purpleBg;

  // Chart
  final Color chartTrack; // donut empty track
  final Color gridline;

  // Shadows (softer / absent in dark)
  final List<BoxShadow> cardShadow;
  final List<BoxShadow> primaryButtonShadow;

  const AppPalette({
    required this.brightness,
    required this.primary,
    required this.primaryTint,
    required this.primaryPanel,
    required this.primaryPanelBorder,
    required this.barMuted,
    required this.gold,
    required this.ink,
    required this.textSecondary,
    required this.textTertiary,
    required this.background,
    required this.surface,
    required this.surfaceAlt,
    required this.border,
    required this.cardBorder,
    required this.successText,
    required this.successBg,
    required this.successBorder,
    required this.warningText,
    required this.warningBg,
    required this.warningBorder,
    required this.dangerText,
    required this.dangerBg,
    required this.dangerBorder,
    required this.purple,
    required this.purpleBg,
    required this.chartTrack,
    required this.gridline,
    required this.cardShadow,
    required this.primaryButtonShadow,
  });

  // ── LIGHT (from the supplied design tokens) ─────────────────────────────────
  static const light = AppPalette(
    brightness: Brightness.light,
    primary: Color(0xFF2C56B5),
    primaryTint: Color(0xFFE4ECFB),
    primaryPanel: Color(0xFFEEF3FC),
    primaryPanelBorder: Color(0xFFD7E2F6),
    barMuted: Color(0xFFBDCBE6),
    gold: Color(0xFFC29A43),
    ink: Color(0xFF172234),
    textSecondary: Color(0xFF5C6878),
    textTertiary: Color(0xFF9AA4B2),
    background: Color(0xFFEEF1F6),
    surface: Color(0xFFFFFFFF),
    surfaceAlt: Color(0xFFF6F8FC),
    border: Color(0xFFE5E9F0),
    cardBorder: Color(0xFFEAEDF3),
    successText: Color(0xFF157A45),
    successBg: Color(0xFFE7F4EC),
    successBorder: Color(0xFFCBE7D5),
    warningText: Color(0xFFA87A22),
    warningBg: Color(0xFFFBF1DE),
    warningBorder: Color(0xFFEFE6D2),
    dangerText: Color(0xFFC2453E),
    dangerBg: Color(0xFFFBEAEA),
    dangerBorder: Color(0xFFF0D3D3),
    purple: Color(0xFF7C5CCB),
    purpleBg: Color(0xFFF0ECFA),
    chartTrack: Color(0xFFEAEDF3),
    gridline: Color(0xFFE5E9F0),
    cardShadow: [
      BoxShadow(color: Color(0x0D14201C), blurRadius: 2, offset: Offset(0, 1)),
      BoxShadow(
        color: Color(0x0D14201C),
        blurRadius: 28,
        offset: Offset(0, 10),
      ),
    ],
    primaryButtonShadow: [
      BoxShadow(color: Color(0x472C56B5), blurRadius: 12, offset: Offset(0, 4)),
    ],
  );

  // ── DARK (soft slate-navy, derived from the indigo brand) ───────────────────
  static const dark = AppPalette(
    brightness: Brightness.dark,
    primary: Color(0xFF5B82DE), // lifted indigo for contrast on dark
    primaryTint: Color(0xFF22304D),
    primaryPanel: Color(0xFF1B2740),
    primaryPanelBorder: Color(0xFF2C3C5C),
    barMuted: Color(0xFF3A4458),
    gold: Color(0xFFD4AF5A),
    ink: Color(0xFFE8ECF3),
    textSecondary: Color(0xFFA3AEC0),
    textTertiary: Color(0xFF6B7689),
    background: Color(0xFF12161F),
    surface: Color(0xFF1A1F2B),
    surfaceAlt: Color(0xFF222836),
    border: Color(0xFF2A3140),
    cardBorder: Color(0xFF272E3C),
    successText: Color(0xFF5FD295),
    successBg: Color(0xFF15281E),
    successBorder: Color(0xFF1F3D2C),
    warningText: Color(0xFFE0B765),
    warningBg: Color(0xFF2B2415),
    warningBorder: Color(0xFF3D341F),
    dangerText: Color(0xFFE8847D),
    dangerBg: Color(0xFF2C1B1A),
    dangerBorder: Color(0xFF402927),
    purple: Color(0xFFA288E0),
    purpleBg: Color(0xFF241F38),
    chartTrack: Color(0xFF2A3140),
    gridline: Color(0xFF252C3A),
    cardShadow: [],
    primaryButtonShadow: [
      BoxShadow(color: Color(0x4D000000), blurRadius: 12, offset: Offset(0, 4)),
    ],
  );

  // ── OLED (pure black) ───────────────────────────────────────────────────────
  static const oled = AppPalette(
    brightness: Brightness.dark,
    primary: Color(0xFF5B82DE),
    primaryTint: Color(0xFF1A2740),
    primaryPanel: Color(0xFF121A2C),
    primaryPanelBorder: Color(0xFF223155),
    barMuted: Color(0xFF2B3242),
    gold: Color(0xFFD4AF5A),
    ink: Color(0xFFEDF0F6),
    textSecondary: Color(0xFF9AA4B6),
    textTertiary: Color(0xFF5E6878),
    background: Color(0xFF000000),
    surface: Color(0xFF0B0D12),
    surfaceAlt: Color(0xFF12151C),
    border: Color(0xFF1C2230),
    cardBorder: Color(0xFF181D28),
    successText: Color(0xFF5FD295),
    successBg: Color(0xFF0C1A12),
    successBorder: Color(0xFF173025),
    warningText: Color(0xFFE0B765),
    warningBg: Color(0xFF1C1709),
    warningBorder: Color(0xFF2E2715),
    dangerText: Color(0xFFE8847D),
    dangerBg: Color(0xFF1C1110),
    dangerBorder: Color(0xFF311F1D),
    purple: Color(0xFFA288E0),
    purpleBg: Color(0xFF161227),
    chartTrack: Color(0xFF1C2230),
    gridline: Color(0xFF14191F),
    cardShadow: [],
    primaryButtonShadow: [],
  );
}

/// ---------------------------------------------------------------------------
/// ACTIVE-PALETTE ACCESSOR
/// AppColors.of(context) gives the palette for the current brightness.
/// Static fields mirror the LIGHT palette for places that can't take a context
/// (e.g. const defaults) — prefer AppColors.of(context) in widgets.
/// ---------------------------------------------------------------------------
class AppColors {
  AppColors._();

  static AppPalette of(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
      ? _darkActive
      : AppPalette.light;

  /// Set by AppTheme when building dark vs oled so `of()` returns the right one.
  static AppPalette _darkActive = AppPalette.dark;
  static void setDarkVariant(AppPalette p) => _darkActive = p;

  // Convenience static (light) tokens for non-context use:
  static const primary = Color(0xFF2C56B5);
  static const gold = Color(0xFFC29A43);
  static const ink = Color(0xFF172234);
  static const purple = Color(0xFF7C5CCB);
}

/// ---------------------------------------------------------------------------
/// TYPOGRAPHY
/// ---------------------------------------------------------------------------
class AppTypography {
  AppTypography._();
  static const _ui = 'Plus Jakarta Sans';
  static const mono = 'Spline Sans Mono';

  static TextStyle display(Color c) => TextStyle(
    fontFamily: _ui,
    fontSize: 27,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.5,
    color: c,
    height: 1.1,
  );

  static TextStyle amount(Color c) => TextStyle(
    fontFamily: _ui,
    fontSize: 31,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.6,
    color: c,
    height: 1.0,
    fontFeatures: const [FontFeature.tabularFigures()],
  );

  static TextStyle title(Color c) => TextStyle(
    fontFamily: _ui,
    fontSize: 15,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.15,
    color: c,
  );

  static TextStyle body(Color c) => TextStyle(
    fontFamily: _ui,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: c,
  );

  static TextStyle bodyMuted(Color c) => TextStyle(
    fontFamily: _ui,
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: c,
  );

  static TextStyle caption(Color c) => TextStyle(
    fontFamily: _ui,
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: c,
  );

  static TextStyle label(Color c) => TextStyle(
    fontFamily: _ui,
    fontSize: 10.5,
    fontWeight: FontWeight.w800,
    letterSpacing: 0.6,
    color: c,
  );

  static TextStyle numeric(Color c) => TextStyle(
    fontFamily: mono,
    fontSize: 10,
    fontWeight: FontWeight.w500,
    color: c,
  );
}

/// ---------------------------------------------------------------------------
/// SHAPE · SPACING
/// ---------------------------------------------------------------------------
class AppRadii {
  AppRadii._();
  static const tile = 11.0, button = 13.0, card = 17.0, pill = 999.0;
}

class AppSpacing {
  AppSpacing._();
  static const xs = 8.0, sm = 11.0, md = 14.0, lg = 16.0, xl = 18.0, xxl = 22.0;
}

/// ---------------------------------------------------------------------------
/// THEME BUILDERS
/// ---------------------------------------------------------------------------
class AppTheme {
  AppTheme._();

  static ThemeData light() => _build(AppPalette.light);
  static ThemeData dark() {
    AppColors.setDarkVariant(AppPalette.dark);
    return _build(AppPalette.dark);
  }

  static ThemeData oled() {
    AppColors.setDarkVariant(AppPalette.oled);
    return _build(AppPalette.oled);
  }

  static ThemeData _build(AppPalette p) {
    const ui = 'Plus Jakarta Sans';
    final scheme = ColorScheme(
      brightness: p.brightness,
      primary: p.primary,
      onPrimary: Colors.white,
      secondary: p.gold,
      onSecondary: Colors.white,
      tertiary: p.purple,
      onTertiary: Colors.white,
      surface: p.surface,
      onSurface: p.ink,
      surfaceContainerLowest: p.background,
      surfaceContainerLow: p.surfaceAlt,
      surfaceContainer: p.surfaceAlt,
      surfaceContainerHigh: p.surface,
      surfaceContainerHighest: p.surfaceAlt,
      onSurfaceVariant: p.textSecondary,
      outline: p.border,
      outlineVariant: p.cardBorder,
      error: p.dangerText,
      onError: Colors.white,
    );

    return ThemeData(
      useMaterial3: true,
      fontFamily: ui,
      brightness: p.brightness,
      scaffoldBackgroundColor: p.background,
      colorScheme: scheme,
      cardTheme: CardThemeData(
        color: p.surface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.card),
          side: BorderSide(color: p.cardBorder),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: p.background,
        foregroundColor: p.ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: AppTypography.display(p.ink).copyWith(fontSize: 22),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: p.surface,
        surfaceTintColor: Colors.transparent,
        indicatorColor: p.primaryTint,
        elevation: 0,
        height: 64,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return AppTypography.caption(
            selected ? p.primary : p.textTertiary,
          ).copyWith(fontSize: 11);
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected ? p.primary : p.textTertiary,
            size: 24,
          );
        }),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: p.primary,
          foregroundColor: Colors.white,
          textStyle: AppTypography.body(
            Colors.white,
          ).copyWith(fontWeight: FontWeight.w700, fontSize: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.button),
          ),
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: p.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          textStyle: AppTypography.body(
            Colors.white,
          ).copyWith(fontWeight: FontWeight.w700, fontSize: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.button),
          ),
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: p.ink,
          side: BorderSide(color: p.border, width: 1.5),
          textStyle: AppTypography.body(
            p.ink,
          ).copyWith(fontWeight: FontWeight.w700),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.button),
          ),
          padding: const EdgeInsets.symmetric(vertical: 11),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: p.primary),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: p.surfaceAlt,
        hintStyle: AppTypography.bodyMuted(p.textTertiary),
        labelStyle: AppTypography.bodyMuted(p.textSecondary),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 13,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.button),
          borderSide: BorderSide(color: p.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.button),
          borderSide: BorderSide(color: p.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.button),
          borderSide: BorderSide(color: p.primary, width: 1.6),
        ),
      ),
      dividerTheme: DividerThemeData(color: p.border, thickness: 1, space: 1),
      iconTheme: IconThemeData(color: p.textSecondary),
      textTheme: _textTheme(p),
    );
  }

  static TextTheme _textTheme(AppPalette p) => TextTheme(
    displaySmall: AppTypography.display(p.ink),
    headlineMedium: AppTypography.display(p.ink),
    titleLarge: AppTypography.title(p.ink).copyWith(fontSize: 18),
    titleMedium: AppTypography.title(p.ink),
    titleSmall: AppTypography.title(p.ink).copyWith(fontSize: 13),
    bodyLarge: AppTypography.body(p.ink),
    bodyMedium: AppTypography.body(p.ink),
    bodySmall: AppTypography.bodyMuted(p.textSecondary),
    labelLarge: AppTypography.label(p.textSecondary),
    labelSmall: AppTypography.numeric(p.textTertiary),
  );
}
