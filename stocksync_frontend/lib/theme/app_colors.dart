import 'package:flutter/material.dart';

class AppColors {
  static const primary = Color(0xFF4361EE);
  static const primaryDark = Color(0xFF3A0CA3);
  static const primaryLight = Color(0xFF7B9EFF);
  static const accent = Color(0xFF4CC9F0);
  static const accentSecondary = Color(0xFFF72585);
  static const background = Color(0xFFF0F4FF);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceVariant = Color(0xFFEEF2FF);
  static const gradientStart = Color(0xFF4361EE);
  static const gradientEnd = Color(0xFF3A0CA3);
  static const textPrimary = Color(0xFF0D1B2A);
  static const textSecondary = Color(0xFF6B7A9D);
  static const textOnPrimary = Color(0xFFFFFFFF);
  static const success = Color(0xFF06D6A0);
  static const warning = Color(0xFFFFB703);
  static const danger = Color(0xFFEF233C);
  static const info = Color(0xFF4CC9F0);
  static const successBg = Color(0xFFE6FFF9);
  static const warningBg = Color(0xFFFFF8E1);
  static const dangerBg = Color(0xFFFFE8EC);
  static const infoBg = Color(0xFFE0F7FC);
  static const shadow = Color(0x1A4361EE);
  static const divider = Color(0xFFE8ECFF);
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [gradientStart, gradientEnd],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
