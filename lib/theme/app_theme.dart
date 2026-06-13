import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Colors
  static const Color bgTop = Color(0xFFCDD3F5);
  static const Color bgBottom = Color(0xFFE8EBF8);
  static const Color bgWhite = Color(0xFFF2F4FB);
  static const Color primary = Color(0xFF6B8EF5);
  static const Color primaryLight = Color(0xFFB8C8FF);
  static const Color cardActive = Color(0xFFD6E8FF);
  static const Color cardLocked = Color(0xFFE8E8E8);
  static const Color textDark = Color(0xFF1A1A2E);
  static const Color textMedium = Color(0xFF6B7280);
  static const Color starYellow = Color(0xFFFBBC05);
  static const Color buttonBlue = Color(0xFF4285F4);

  static ThemeData get theme {
    return ThemeData(
      useMaterial3: true,
      textTheme: GoogleFonts.nunitoTextTheme(),
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        brightness: Brightness.light,
      ),
    );
  }
}

// Gradient background decoration
BoxDecoration get appGradientBg => const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [AppTheme.bgTop, AppTheme.bgBottom],
        stops: [0.0, 0.7],
      ),
    );
