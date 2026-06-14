import 'package:flutter/material.dart';

abstract final class AppColors {
  static const night = Color(0xFF07130F);
  static const forest = Color(0xFF0D271B);
  static const moss = Color(0xFF1B4A32);
  static const leaf = Color(0xFF4E8D51);
  static const bone = Color(0xFFF2E2BD);
  static const parchment = Color(0xFFE8D4A8);
  static const tiger = Color(0xFFF37A24);
  static const tigerDark = Color(0xFF9D2E16);
  static const ember = Color(0xFFFFC451);
  static const blood = Color(0xFFB92E2A);
  static const stone = Color(0xFF25372D);
}

abstract final class AppTheme {
  static ThemeData get dark {
    const scheme = ColorScheme.dark(
      primary: AppColors.tiger,
      secondary: AppColors.ember,
      surface: AppColors.forest,
      error: AppColors.blood,
      onPrimary: Colors.black,
      onSecondary: Colors.black,
      onSurface: AppColors.bone,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.night,
      fontFamily: 'serif',
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontWeight: FontWeight.w900,
          letterSpacing: 1.2,
          height: 0.95,
        ),
        headlineMedium: TextStyle(
          fontWeight: FontWeight.w800,
          letterSpacing: 0.4,
        ),
        titleLarge: TextStyle(fontWeight: FontWeight.w800),
        bodyLarge: TextStyle(height: 1.45),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 17),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.4,
          ),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: AppColors.bone,
          backgroundColor: Colors.white.withValues(alpha: 0.06),
        ),
      ),
    );
  }
}
