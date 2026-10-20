import 'package:flutter/material.dart';

/// iPANTAU v2 design tokens (light + dark), mirrors styles.css in the
/// design handoff. Read with `context.ip` (see extension below).
@immutable
class IpColors extends ThemeExtension<IpColors> {
  const IpColors({
    required this.navy900,
    required this.navy800,
    required this.navy700,
    required this.navy600,
    required this.headerGradStart,
    required this.headerGradEnd,
    required this.azure700,
    required this.azure600,
    required this.azure500,
    required this.azure400,
    required this.azure100,
    required this.azure50,
    required this.emerald600,
    required this.emerald500,
    required this.emerald50,
    required this.amber500,
    required this.amberText,
    required this.amber50,
    required this.crimson600,
    required this.crimson500,
    required this.crimson50,
    required this.bg,
    required this.surface,
    required this.surface2,
    required this.surface3,
    required this.line,
    required this.line2,
    required this.text,
    required this.text2,
    required this.text3,
    required this.onNavy,
    required this.onNavy2,
    required this.icon,
    required this.shadowSm,
    required this.shadowMd,
    required this.shadowLg,
    required this.shadowNav,
    required this.isDark,
  });

  final Color navy900, navy800, navy700, navy600;
  final Color headerGradStart, headerGradEnd;
  final Color azure700, azure600, azure500, azure400, azure100, azure50;
  final Color emerald600, emerald500, emerald50;
  final Color amber500, amberText, amber50;
  final Color crimson600, crimson500, crimson50;
  final Color bg, surface, surface2, surface3, line, line2;
  final Color text, text2, text3, onNavy, onNavy2, icon;
  final List<BoxShadow> shadowSm, shadowMd, shadowLg, shadowNav;
  final bool isDark;

  LinearGradient get headerGradient => LinearGradient(
        // 160deg in CSS is roughly top-left to bottom-right, mostly vertical
        begin: const Alignment(-0.35, -1),
        end: const Alignment(0.35, 1),
        colors: [headerGradStart, headerGradEnd],
      );

  static const _navyShadow = Color(0xFF14223C);

  static final light = IpColors(
    navy900: const Color(0xFF14223C),
    navy800: const Color(0xFF1B2F50),
    navy700: const Color(0xFF223C66),
    navy600: const Color(0xFF2A4B7E),
    headerGradStart: const Color(0xFF213A63),
    headerGradEnd: const Color(0xFF16263F),
    azure700: const Color(0xFF1257C7),
    azure600: const Color(0xFF1C66DD),
    azure500: const Color(0xFF2F7BEF),
    azure400: const Color(0xFF5798FF),
    azure100: const Color(0xFFE2ECFE),
    azure50: const Color(0xFFF0F6FF),
    emerald600: const Color(0xFF0F9D63),
    emerald500: const Color(0xFF18B478),
    emerald50: const Color(0xFFE4F6EE),
    amber500: const Color(0xFFE6A019),
    amberText: const Color(0xFF9A6710),
    amber50: const Color(0xFFFCF2DC),
    crimson600: const Color(0xFFDB2B41),
    crimson500: const Color(0xFFEF4259),
    crimson50: const Color(0xFFFDEBED),
    bg: const Color(0xFFEAEFF6),
    surface: const Color(0xFFFFFFFF),
    surface2: const Color(0xFFF4F7FC),
    surface3: const Color(0xFFEEF3F9),
    line: const Color(0xFFE0E7F1),
    line2: const Color(0xFFCCD6E4),
    text: const Color(0xFF15233D),
    text2: const Color(0xFF5A6B86),
    text3: const Color(0xFF8794AA),
    onNavy: const Color(0xFFFFFFFF),
    onNavy2: const Color(0xFFAEBED8),
    icon: const Color(0xFF25406B),
    shadowSm: [
      BoxShadow(color: _navyShadow.withValues(alpha: .06), blurRadius: 2, offset: const Offset(0, 1)),
      BoxShadow(color: _navyShadow.withValues(alpha: .05), blurRadius: 3, offset: const Offset(0, 1)),
    ],
    shadowMd: [
      BoxShadow(color: _navyShadow.withValues(alpha: .08), blurRadius: 14, offset: const Offset(0, 4)),
      BoxShadow(color: _navyShadow.withValues(alpha: .05), blurRadius: 6, offset: const Offset(0, 2)),
    ],
    shadowLg: [
      BoxShadow(color: _navyShadow.withValues(alpha: .16), blurRadius: 34, offset: const Offset(0, 12)),
    ],
    shadowNav: [
      BoxShadow(color: _navyShadow.withValues(alpha: .08), blurRadius: 18, offset: const Offset(0, -2)),
    ],
    isDark: false,
  );

  static final dark = IpColors(
    navy900: const Color(0xFF0C1424),
    navy800: const Color(0xFF121C30),
    navy700: const Color(0xFF1A2742),
    navy600: const Color(0xFF233452),
    headerGradStart: const Color(0xFF1A2A47),
    headerGradEnd: const Color(0xFF0D1828),
    azure700: const Color(0xFF2F7BEF),
    azure600: const Color(0xFF3F86F2),
    azure500: const Color(0xFF5798FF),
    azure400: const Color(0xFF79AFFF),
    azure100: const Color(0xFF1B2C49),
    azure50: const Color(0xFF16243D),
    emerald600: const Color(0xFF2BC287),
    emerald500: const Color(0xFF2BC287),
    emerald50: const Color(0xFF11321F),
    amber500: const Color(0xFFF0AD33),
    amberText: const Color(0xFFF0AD33),
    amber50: const Color(0xFF33270C),
    crimson600: const Color(0xFFFF5D72),
    crimson500: const Color(0xFFFF5D72),
    crimson50: const Color(0xFF331118),
    bg: const Color(0xFF0A111E),
    surface: const Color(0xFF131D30),
    surface2: const Color(0xFF0F1827),
    surface3: const Color(0xFF18243A),
    line: const Color(0xFF243248),
    line2: const Color(0xFF30415C),
    text: const Color(0xFFE9EFF9),
    text2: const Color(0xFF9FB0CB),
    text3: const Color(0xFF6C7D9B),
    onNavy: const Color(0xFFFFFFFF),
    onNavy2: const Color(0xFF9FB2D0),
    icon: const Color(0xFFAEBFD9),
    shadowSm: [BoxShadow(color: Colors.black.withValues(alpha: .3), blurRadius: 2, offset: const Offset(0, 1))],
    shadowMd: [BoxShadow(color: Colors.black.withValues(alpha: .35), blurRadius: 14, offset: const Offset(0, 4))],
    shadowLg: [BoxShadow(color: Colors.black.withValues(alpha: .5), blurRadius: 36, offset: const Offset(0, 14))],
    shadowNav: [BoxShadow(color: Colors.black.withValues(alpha: .4), blurRadius: 18, offset: const Offset(0, -2))],
    isDark: true,
  );

  @override
  IpColors copyWith() => this;

  @override
  IpColors lerp(ThemeExtension<IpColors>? other, double t) {
    if (other is! IpColors) return this;
    return t < .5 ? this : other;
  }
}

/// Radius scale from the handoff.
class IpRadius {
  static const double sm = 10;
  static const double md = 14;
  static const double lg = 20;
  static const double xl = 26;
}

extension IpContext on BuildContext {
  IpColors get ip => Theme.of(this).extension<IpColors>() ?? IpColors.light;
}
