import 'package:flutter/material.dart';

/// Paleta dependiente del tema. Los getters cambian según [setDark]; las
/// pantallas se reconstruyen al notificar SettingsProvider.
class AppColors {
  static bool _dark = true;
  static void setDark(bool value) => _dark = value;
  static bool get isDark => _dark;

  static Color get primaryPurple => const Color(0xFF673BB7);
  static Color get lightPurple =>
      _dark ? const Color(0xFF9C68E0) : const Color(0xFF7E4FD1);
  static Color get mintGreen =>
      _dark ? const Color(0xFF92E3A9) : const Color(0xFF1F9D57);
  static Color get darkBg =>
      _dark ? const Color(0xFF0D0D1A) : const Color(0xFFF4F4FB);
  static Color get surfaceBg =>
      _dark ? const Color(0xFF16162A) : const Color(0xFFFFFFFF);
  static Color get cardBg =>
      _dark ? const Color(0xFF1E1E38) : const Color(0xFFFFFFFF);
  static Color get incomeGreen =>
      _dark ? const Color(0xFF92E3A9) : const Color(0xFF1F9D57);
  static Color get expenseRed =>
      _dark ? const Color(0xFFFF6B6B) : const Color(0xFFD64545);
  static Color get savingsBlue =>
      _dark ? const Color(0xFF5AB0FF) : const Color(0xFF2F7FD6);
  static Color get textPrimary =>
      _dark ? const Color(0xFFFFFFFF) : const Color(0xFF1B1B2F);
  static Color get textSecondary =>
      _dark ? const Color(0xFFB0B0CC) : const Color(0xFF5C5C7A);
  static Color get divider =>
      _dark ? const Color(0xFF2A2A48) : const Color(0xFFDDDDEA);
}

class AppTheme {
  static ThemeData get dark => _build(Brightness.dark);
  static ThemeData get light => _build(Brightness.light);

  static ThemeData _build(Brightness brightness) => ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primaryPurple,
      brightness: brightness,
      primary: AppColors.primaryPurple,
      secondary: AppColors.mintGreen,
      surface: AppColors.surfaceBg,
    ),
    scaffoldBackgroundColor: AppColors.darkBg,
    appBarTheme: AppBarTheme(
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
      labelStyle: TextStyle(color: AppColors.textSecondary),
    ),
  );
}
