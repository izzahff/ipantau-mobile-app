import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'ip_colors.dart';

/// App-wide theme. v2 keeps the legacy static constants (now mapped to the
/// v2 light palette) so any screen still using them looks consistent, and
/// adds [light] / [dark] ThemeData builders that carry [IpColors].
class AppTheme {
  // Legacy names, v2 light values
  static const Color navy = Color(0xFF1B2F50); // navy-800
  static const Color navyLight = Color(0xFF2F7BEF); // azure-500
  static const Color gold = Color(0xFF2F7BEF); // v1 accent is now azure
  static const Color goldLight = Color(0xFFE2ECFE); // azure-100

  static const Color success = Color(0xFF0F9D63);
  static const Color successLight = Color(0xFFE4F6EE);
  static const Color error = Color(0xFFDB2B41);
  static const Color errorLight = Color(0xFFFDEBED);
  static const Color warning = Color(0xFF9A6710);
  static const Color warningLight = Color(0xFFFCF2DC);

  static const Color background = Color(0xFFEAEFF6);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color border = Color(0xFFE0E7F1);
  static const Color textPrimary = Color(0xFF15233D);
  static const Color textSecondary = Color(0xFF5A6B86);
  static const Color textMuted = Color(0xFF8794AA);

  // Spacing (4pt base)
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;

  // Radius
  static const double radiusSm = 10;
  static const double radiusMd = 14;
  static const double radiusLg = 20;
  static const double radiusXl = 26;
  static const double radiusRound = 50;

  static List<BoxShadow> cardShadow = IpColors.light.shadowSm;
  static List<BoxShadow> buttonShadow = IpColors.light.shadowMd;

  /// Monospace style for IDs, coordinates and timestamps.
  static TextStyle mono({double size = 12, FontWeight weight = FontWeight.w500, Color? color}) =>
      GoogleFonts.jetBrainsMono(fontSize: size, fontWeight: weight, color: color);

  static ThemeData light() => _build(IpColors.light, Brightness.light);
  static ThemeData dark() => _build(IpColors.dark, Brightness.dark);

  static ThemeData _build(IpColors c, Brightness b) {
    final base = ThemeData(
      useMaterial3: true,
      brightness: b,
      scaffoldBackgroundColor: c.bg,
      colorScheme: ColorScheme.fromSeed(
        seedColor: c.azure500,
        brightness: b,
        primary: c.azure500,
        surface: c.surface,
        error: c.crimson600,
      ),
      extensions: [c],
    );
    return base.copyWith(
      textTheme: GoogleFonts.hankenGroteskTextTheme(base.textTheme).apply(
        bodyColor: c.text,
        displayColor: c.text,
      ),
      dividerColor: c.line,
      splashFactory: InkSparkle.splashFactory,
      textSelectionTheme: TextSelectionThemeData(cursorColor: c.azure500),
    );
  }
}
