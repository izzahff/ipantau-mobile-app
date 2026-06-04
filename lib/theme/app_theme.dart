import 'package:flutter/material.dart';

class AppTheme {
  // Primary colors
  static const Color navy = Color(0xFF1E3A5F);
  static const Color navyLight = Color(0xFF2451A3);
  static const Color gold = Color(0xFFD97706);
  static const Color goldLight = Color(0xFFFEF3C7);

  // Status colors
  static const Color success = Color(0xFF059669);
  static const Color successLight = Color(0xFFD1FAE5);
  static const Color error = Color(0xFFDC2626);
  static const Color errorLight = Color(0xFFFEE2E2);
  static const Color warning = Color(0xFFD97706);
  static const Color warningLight = Color(0xFFFEF3C7);

  // Neutral colors
  static const Color background = Color(0xFFF8FAFF);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color border = Color(0xFFE8EFF8);
  static const Color textPrimary = Color(0xFF0F1B35);
  static const Color textSecondary = Color(0xFF4A5568);
  static const Color textMuted = Color(0xFF94A3B8);

  // Spacing
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;

  // Border radius
  static const double radiusSm = 8;
  static const double radiusMd = 12;
  static const double radiusLg = 16;
  static const double radiusXl = 24;
  static const double radiusRound = 50;

  // Shadows
  static List<BoxShadow> cardShadow = [
    BoxShadow(
      color: navy.withValues(alpha: 0.06),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> buttonShadow = [
    BoxShadow(
      color: navy.withValues(alpha: 0.25),
      blurRadius: 8,
      offset: const Offset(0, 4),
    ),
  ];
}
