import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Colors (Dream Red & White Theme)
  static const Color primaryColor = Color(0xFFD32F2F); // Premium Red
  static const Color primaryDark = Color(0xFFB71C1C);
  static const Color secondaryColor = Color(0xFFFFFFFF); // White
  static const Color accentColor = Color(0xFFFF5252);
  
  static const Color successColor = Color(0xFF2E7D32); // Green
  static const Color dangerColor = Color(0xFFC62828); // Red
  static const Color warningColor = Color(0xFFF57C00); // Orange
  static const Color infoColor = Color(0xFF1976D2); // Blue

  static const Color bgPrimary = Color(0xFFF5F5F5); // Light Gray Background
  static const Color bgSecondary = Color(0xFFFFFFFF); // White
  static const Color bgCard = Color(0xFFFFFFFF); // White Cards
  static const Color bgSurface = Color(0xFFEEEEEE); // Input backgrounds

  static const Color textPrimary = Color(0xFF212121); // Dark Gray Text
  static const Color textSecondary = Color(0xFF757575); // Medium Text
  static const Color textMuted = Color(0xFF9E9E9E); // Muted Text

  static const Color borderColor = Color(0xFFE0E0E0); // Light Borders

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFFE53935), Color(0xFFD32F2F), Color(0xFFC62828)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient successGradient = LinearGradient(
    colors: [Color(0xFF4CAF50), Color(0xFF2E7D32)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient goldGradient = LinearGradient(
    colors: [Color(0xFFFFB300), Color(0xFFFFA000)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Theme Data
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: bgPrimary,
    colorScheme: const ColorScheme.light(
      primary: primaryColor,
      secondary: secondaryColor,
      surface: bgSecondary,
      error: dangerColor,
      onPrimary: Colors.white,
    ),
    textTheme: GoogleFonts.interTextTheme(
      ThemeData.light().textTheme,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: primaryColor,
      elevation: 2,
      centerTitle: true,
      titleTextStyle: GoogleFonts.inter(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),
      iconTheme: const IconThemeData(color: Colors.white),
    ),
    cardTheme: CardThemeData(
      color: bgCard,
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: borderColor, width: 1),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: bgSecondary,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: primaryColor, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      labelStyle: const TextStyle(color: textSecondary),
      hintStyle: const TextStyle(color: textMuted),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: bgSecondary,
      selectedItemColor: primaryColor,
      unselectedItemColor: textSecondary,
      type: BottomNavigationBarType.fixed,
      elevation: 8,
    ),
  );
}
