import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // ألوان موقعك
  static const Color bgMain = Color(0xFF1a1a2e);
  static const Color bgSecondary = Color(0xFF16213e);
  static const Color bgTertiary = Color(0xFF0f3460);
  static const Color accentPurple = Color(0xFFa259ff);
  static const Color accentBlue = Color(0xFF4d8aff);
  static const Color accentGreen = Color(0xFF28a745);
  static const Color accentYellow = Color(0xFFffc107);
  static const Color dangerColor = Color(0xFFdc3545);
  static const Color textPrimary = Color(0xFFe0e0e0);
  static const Color textSecondary = Color(0xFFa9a9a9);

  static ThemeData get dark {
    final baseTextTheme = GoogleFonts.cairoTextTheme(
      ThemeData.dark().textTheme,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: bgMain,
      primaryColor: accentBlue,
      textTheme: baseTextTheme,
      colorScheme: const ColorScheme.dark(
        primary: accentBlue,
        secondary: accentPurple,
        surface: bgSecondary,
        error: dangerColor,
        onPrimary: Colors.white,
        onSurface: textPrimary,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: bgMain,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.cairo(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: bgSecondary,
        contentTextStyle: GoogleFonts.cairo(color: textPrimary),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: accentBlue,
      ),
    );
  }
}