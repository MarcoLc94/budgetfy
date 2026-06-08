import 'package:flutter/material.dart';

class AppColors {
  static const Color primaryPurple = Color(0xFF673BB7);
  static const Color lightPurple = Color(0xFF9C68E0);
  static const Color mintGreen = Color(0xFF92E3A9);
  static const Color darkBg = Color(0xFF0D0D1A);
  static const Color surfaceBg = Color(0xFF16162A);
  static const Color cardBg = Color(0xFF1E1E38);
  static const Color incomeGreen = Color(0xFF92E3A9);
  static const Color expenseRed = Color(0xFFFF6B6B);
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFB0B0CC);
  static const Color divider = Color(0xFF2A2A48);
}

class AppTheme {
  static ThemeData get dark => ThemeData(
    useMaterial3: true,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.primaryPurple,
      secondary: AppColors.mintGreen,
      surface: AppColors.surfaceBg,
    ),
    scaffoldBackgroundColor: AppColors.darkBg,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.darkBg,
      foregroundColor: AppColors.textPrimary,
      elevation: 0,
      centerTitle: false,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.cardBg,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      labelStyle: const TextStyle(color: AppColors.textSecondary),
    ),
  );
}
