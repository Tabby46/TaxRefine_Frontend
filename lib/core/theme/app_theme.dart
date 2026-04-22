import 'package:flutter/material.dart';

// Theme utility for the neon colors
class NeonColors {
  static const Color personalBlue = Color(0xFF00D1FF);
  static const Color businessGreen = Color(0xFF00FF66);
}

class AppTheme {
  static ThemeData light() {
    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: const Color(0xFFF8FAFB),
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF0B6E4F),
        brightness: Brightness.light,
        background: const Color(0xFFF8FAFB),
        surface: Colors.white.withOpacity(0.7),
      ),
      cardColor: Colors.white.withOpacity(0.7),
      useMaterial3: true,
      textTheme: Typography.englishLike2021.apply(
        bodyColor: Colors.black87,
        displayColor: Colors.black87,
      ),
      // Neon colors can be accessed via NeonColors
    );
  }

  static ThemeData dark() {
    return ThemeData.dark().copyWith(
      scaffoldBackgroundColor: Colors.black,
      cardColor: Colors.black,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF0B6E4F),
        brightness: Brightness.dark,
        background: Colors.black,
        surface: Colors.black,
      ),
      useMaterial3: true,
      textTheme: Typography.englishLike2021.apply(
        bodyColor: Colors.white,
        displayColor: Colors.white,
      ),
      // Neon colors can be accessed via NeonColors
    );
  }
}
