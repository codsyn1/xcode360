import 'package:flutter/material.dart';

class AppColors {
  // Light Mode Colors
  static const Color lightBackground = Color(0xFFF2F2F7);
  static const Color lightCard = Colors.white;
  static const Color lightTextPrimary = Colors.black;
  static const Color lightTextSecondary = Colors.black54;
  static const Color lightBorder = Color(0xFFE0E0E0);
  static const Color lightDivider = Color(0xFFEEEEEE);
  static const Color lightBottomNav = Colors.white;

  // Dark Mode Colors
  static const Color darkBackground = Color(0xFF121212);
  static const Color darkCard = Color(0xFF1A1A1A);
  static const Color darkTextPrimary = Colors.white;
  static const Color darkTextSecondary = Colors.white70;
  static const Color darkBorder = Color(0xFF2D2D2D);
  static const Color darkDivider = Color(0xFF2A2A2A);
  static const Color darkBottomNav = Color(0xFF1A1A1A);

  // Card surface (slightly elevated from card)
  static const Color lightCardSurface = Color(0xFFEEEEEE);
  static const Color darkCardSurface = Color(0xFF2C2C2C);

  // Drawer / panel backgrounds
  static const Color lightDrawer = Colors.white;
  static const Color darkDrawer = Color(0xFF232323);

  // Semantic Helpers
  static Color background(bool isDark) => isDark ? darkBackground : lightBackground;
  static Color card(bool isDark) => isDark ? darkCard : lightCard;
  static Color cardSurface(bool isDark) => isDark ? darkCardSurface : lightCardSurface;
  static Color textPrimary(bool isDark) => isDark ? darkTextPrimary : lightTextPrimary;
  static Color textSecondary(bool isDark) => isDark ? darkTextSecondary : lightTextSecondary;
  static Color border(bool isDark) => isDark ? darkBorder : lightBorder;
  static Color divider(bool isDark) => isDark ? darkDivider : lightDivider;
  static Color bottomNav(bool isDark) => isDark ? darkBottomNav : lightBottomNav;
  static Color drawer(bool isDark) => isDark ? darkDrawer : lightDrawer;
  static Color shadow(bool isDark) => isDark ? Colors.black : Colors.black.withOpacity(0.12);

  // Card gradient for dashboard cards
  static List<Color> cardGradient(bool isDark) => isDark
      ? [const Color(0xFF2D2D2D), const Color(0xFF1A1A1A)]
      : [const Color(0xFFFFFFFF), const Color(0xFFF0F2F5)];

  // Icon container gradient inside cards
  static List<Color> iconContainerGradient(bool isDark) => isDark
      ? [const Color(0xFF3A3A3A), const Color(0xFF2A2A2A)]
      : [const Color(0xFFE3E8F0), const Color(0xFFD6DCE8)];

  // Text on card surfaces (for things like card titles/subtitles)
  static Color cardTitle(bool isDark) => isDark ? Colors.white : Colors.black87;
  static Color cardSubtitle(bool isDark) => isDark ? Colors.white70 : Colors.black54;

  // Decorative circle overlays on cards
  static Color cardOverlay(bool isDark) => isDark
      ? Colors.white.withOpacity(0.1)
      : Colors.black.withOpacity(0.04);
}
