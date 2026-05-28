import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Colors (Luxury Red & White Theme)
  static const Color primaryColor = Color(0xFFE52D27); // Luxury Vibrant Scarlet Red
  static const Color primaryDark = Color(0xFFB31217); // Rich Crimson Dark
  static const Color secondaryColor = Color(0xFFFFFFFF); // Pure White
  static const Color accentColor = Color(0xFFFF4E50); // Soft Coral Red
  
  static const Color successColor = Color(0xFF10B981); // Modern Emerald Green
  static const Color dangerColor = Color(0xFFEF4444); // Scarlet Danger
  static const Color warningColor = Color(0xFFF59E0B); // Amber Warning
  static const Color infoColor = Color(0xFF3B82F6); // Royal Blue Info

  static const Color bgPrimary = Color(0xFFF8FAFC); // Clean Ice-White Background
  static const Color bgSecondary = Color(0xFFFFFFFF); // Pure White Surfaces
  static const Color bgCard = Color(0xFFFFFFFF); // Pure White Cards
  static const Color bgSurface = Color(0xFFF1F5F9); // Premium Slate Gray Inputs

  static const Color textPrimary = Color(0xFF0F172A); // Luxury Deep Indigo Black
  static const Color textSecondary = Color(0xFF475569); // Slate Gray Secondary
  static const Color textMuted = Color(0xFF94A3B8); // Muted Silver Text

  static const Color borderColor = Color(0xFFE2E8F0); // Subtle Soft Borders

  // Premium Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFFF71E1E), Color(0xFFE52D27), Color(0xFFB31217)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient successGradient = LinearGradient(
    colors: [Color(0xFF10B981), Color(0xFF059669)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient goldGradient = LinearGradient(
    colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Theme Data (High-Fidelity Luxury Light Theme)
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
    textTheme: GoogleFonts.outfitTextTheme(
      ThemeData.light().textTheme,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: primaryColor,
      elevation: 0,
      centerTitle: true,
      shadowColor: const Color(0x1F000000),
      titleTextStyle: GoogleFonts.outfit(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: Colors.white,
        letterSpacing: 0.5,
      ),
      iconTheme: const IconThemeData(color: Colors.white),
    ),
    cardTheme: CardThemeData(
      color: bgCard,
      elevation: 4,
      shadowColor: const Color(0x0A000000),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: borderColor, width: 1),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 2,
        shadowColor: primaryColor.withOpacity(0.3),
        textStyle: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: 0.5),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: bgSecondary,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: primaryColor, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      labelStyle: GoogleFonts.outfit(color: textSecondary, fontWeight: FontWeight.w500),
      hintStyle: GoogleFonts.outfit(color: textMuted),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: bgSecondary,
      selectedItemColor: primaryColor,
      unselectedItemColor: textSecondary,
      selectedLabelStyle: TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
      unselectedLabelStyle: TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
      type: BottomNavigationBarType.fixed,
      elevation: 16,
    ),
  );
}
