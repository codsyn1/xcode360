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

  // Semantic Helpers
  static Color background(bool isDark) => isDark ? darkBackground : lightBackground;
  static Color card(bool isDark) => isDark ? darkCard : lightCard;
  static Color textPrimary(bool isDark) => isDark ? darkTextPrimary : lightTextPrimary;
  static Color textSecondary(bool isDark) => isDark ? darkTextSecondary : lightTextSecondary;
  static Color border(bool isDark) => isDark ? darkBorder : lightBorder;
  static Color divider(bool isDark) => isDark ? darkDivider : lightDivider;
  static Color bottomNav(bool isDark) => isDark ? darkBottomNav : lightBottomNav;
}
