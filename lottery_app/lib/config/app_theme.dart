import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class LotteryCardTheme {
  final Color primaryColor;
  final Color textIconColor;
  final Color overlayColor;
  final LinearGradient gradient;

  const LotteryCardTheme({
    required this.primaryColor,
    required this.textIconColor,
    required this.overlayColor,
    required this.gradient,
  });
}

class AppTheme {
  // Dynamic Lottery Themes
  static const List<LotteryCardTheme> lotteryThemes = [
    LotteryCardTheme(
      primaryColor: Color(0xFFE52D27),
      textIconColor: Color(0xFFE52D27),
      overlayColor: Color(0xFFFDE8E8),
      gradient: LinearGradient(
        colors: [Color(0xFFF71E1E), Color(0xFFE52D27), Color(0xFFB31217)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),
    LotteryCardTheme(
      primaryColor: Color(0xFF2563EB),
      textIconColor: Color(0xFF2563EB),
      overlayColor: Color(0xFFEFF6FF),
      gradient: LinearGradient(
        colors: [Color(0xFF60A5FA), Color(0xFF2563EB), Color(0xFF1E3A8A)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),
    LotteryCardTheme(
      primaryColor: Color(0xFF10B981),
      textIconColor: Color(0xFF047857),
      overlayColor: Color(0xFFECFDF5),
      gradient: LinearGradient(
        colors: [Color(0xFF34D399), Color(0xFF10B981), Color(0xFF047857)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),
    LotteryCardTheme(
      primaryColor: Color(0xFF7C3AED),
      textIconColor: Color(0xFF7C3AED),
      overlayColor: Color(0xFFF5F3FF),
      gradient: LinearGradient(
        colors: [Color(0xFFA78BFA), Color(0xFF7C3AED), Color(0xFF5B21B6)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),
    LotteryCardTheme(
      primaryColor: Color(0xFFD97706),
      textIconColor: Color(0xFFB45309),
      overlayColor: Color(0xFFFEF3C7),
      gradient: LinearGradient(
        colors: [Color(0xFFFBBF24), Color(0xFFD97706), Color(0xFFB45309)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),
    LotteryCardTheme(
      primaryColor: Color(0xFFDB2777),
      textIconColor: Color(0xFFDB2777),
      overlayColor: Color(0xFFFDF2F8),
      gradient: LinearGradient(
        colors: [Color(0xFFF472B6), Color(0xFFDB2777), Color(0xFF9D174D)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),
  ];

  static LotteryCardTheme getLotteryTheme(String? name) {
    if (name == null || name.isEmpty) return lotteryThemes[0];
    int hash = 0;
    for (int i = 0; i < name.length; i++) {
      hash = name.codeUnitAt(i) + ((hash << 5) - hash);
    }
    final index = hash.abs() % lotteryThemes.length;
    return lotteryThemes[index];
  }

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

class TicketClipper extends CustomClipper<Path> {
  final double punchRadius;
  final double punchY;

  const TicketClipper({this.punchRadius = 8.0, this.punchY = 85.0});

  @override
  Path getClip(Size size) {
    final path = Path();
    
    // Top-left corner
    path.moveTo(0.0, 16.0);
    path.quadraticBezierTo(0.0, 0.0, 16.0, 0.0);
    
    // Top line
    path.lineTo(size.width - 16.0, 0.0);
    
    // Top-right corner
    path.quadraticBezierTo(size.width, 0.0, size.width, 16.0);
    
    // Right side top down to notch
    path.lineTo(size.width, punchY - punchRadius);
    
    // Right notch (inward curve)
    path.quadraticBezierTo(
      size.width - punchRadius,
      punchY,
      size.width,
      punchY + punchRadius,
    );
    
    // Right side down to bottom
    path.lineTo(size.width, size.height - 16.0);
    
    // Bottom-right corner
    path.quadraticBezierTo(size.width, size.height, size.width - 16.0, size.height);
    
    // Bottom line
    path.lineTo(16.0, size.height);
    
    // Bottom-left corner
    path.quadraticBezierTo(0.0, size.height, 0.0, size.height - 16.0);
    
    // Left side bottom up to notch
    path.lineTo(0.0, punchY + punchRadius);
    
    // Left notch (inward curve)
    path.quadraticBezierTo(
      punchRadius,
      punchY,
      0.0,
      punchY - punchRadius,
    );
    
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

class TicketPatternPainter extends CustomPainter {
  final Color color;
  const TicketPatternPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.0;
    
    // Subtle diagonal lines
    for (double i = -size.height; i < size.width; i += 10) {
      canvas.drawLine(
        Offset(i, 0),
        Offset(i + size.height, size.height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class DashedLinePainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double dashWidth;
  final double dashSpace;

  const DashedLinePainter({
    this.color = const Color(0xFFE2E8F0),
    this.strokeWidth = 1.0,
    this.dashWidth = 6.0,
    this.dashSpace = 4.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    double startX = 0;
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth;
    while (startX < size.width) {
      canvas.drawLine(Offset(startX, 0), Offset(startX + dashWidth, 0), paint);
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

