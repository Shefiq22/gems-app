import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class GEMSTheme {
  // ── Core palette ─────────────────────────────────────────
  static const Color primaryGreen  = Color(0xFF1B5E20);
  static const Color accentGreen   = Color(0xFF4CAF50);
  static const Color lightGreen    = Color(0xFF81C784);
  static const Color emerald       = Color(0xFF00897B);
  static const Color forestGreen   = Color(0xFF2E7D32);
  static const Color limeAccent    = Color(0xFFCCFF90);

  // ── Surfaces ─────────────────────────────────────────────
  static const Color white    = Color(0xFFFFFFFF);
  static const Color offWhite = Color(0xFFF1F8E9);
  static const Color cardBg   = Color(0xFFF9FBF7);
  static const Color darkBg   = Color(0xFF0D1F0F);
  static const Color darkCard = Color(0xFF1A2E1C);

  // ── Text ─────────────────────────────────────────────────
  static const Color textDark  = Color(0xFF1A2E1C);
  static const Color textMid   = Color(0xFF4A6741);
  static const Color textLight = Color(0xFF89A882);

  // ── Semantic ─────────────────────────────────────────────
  static const Color danger   = Color(0xFFD32F2F);
  static const Color warning  = Color(0xFFF57F17);
  static const Color success  = Color(0xFF388E3C);
  static const Color critical = Color(0xFFB71C1C);

  // ── Faculty colours ───────────────────────────────────────
  static const Color nasFacultyColor = Color(0xFFD32F2F);
  static const Color esFacultyColor  = Color(0xFF388E3C);
  static const Color engFacultyColor = Color(0xFFE65100);
  static const Color medFacultyColor = Color(0xFF1565C0);

  // ── Theme ────────────────────────────────────────────────
  static ThemeData get theme => ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: primaryGreen,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        textTheme: GoogleFonts.poppinsTextTheme(),
        scaffoldBackgroundColor: offWhite,
        cardTheme: CardTheme(
          elevation: 0,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20)),
          color: white,
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          titleTextStyle: GoogleFonts.playfairDisplay(
            color: white, fontSize: 22, fontWeight: FontWeight.w700),
        ),
      );

  // ── Text styles ───────────────────────────────────────────
  static TextStyle get displayLarge => GoogleFonts.playfairDisplay(
        fontSize: 48, fontWeight: FontWeight.w800,
        color: white, height: 1.1);

  static TextStyle get displayMedium => GoogleFonts.playfairDisplay(
        fontSize: 32, fontWeight: FontWeight.w700,
        color: textDark, height: 1.2);

  static TextStyle get headingLarge => GoogleFonts.poppins(
        fontSize: 24, fontWeight: FontWeight.w700, color: textDark);

  static TextStyle get headingMedium => GoogleFonts.poppins(
        fontSize: 18, fontWeight: FontWeight.w600, color: textDark);

  static TextStyle get bodyLarge => GoogleFonts.poppins(
        fontSize: 16, fontWeight: FontWeight.w400, color: textMid);

  static TextStyle get bodySmall => GoogleFonts.poppins(
        fontSize: 13, fontWeight: FontWeight.w400, color: textLight);

  static TextStyle get label => GoogleFonts.poppins(
        fontSize: 11, fontWeight: FontWeight.w600,
        color: textLight, letterSpacing: 1.2);

  // ── Gradients ─────────────────────────────────────────────
  static LinearGradient get heroGradient => const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF1B5E20), Color(0xFF2E7D32), Color(0xFF00695C)]);

  static LinearGradient get cardGradient => const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF43A047), Color(0xFF1B5E20)]);

  // ── Shadows ───────────────────────────────────────────────
  static BoxShadow get softShadow => BoxShadow(
        color: primaryGreen.withOpacity(0.07),
        blurRadius: 24, offset: const Offset(0, 8));

  static BoxShadow get strongShadow => BoxShadow(
        color: primaryGreen.withOpacity(0.16),
        blurRadius: 32, spreadRadius: 2, offset: const Offset(0, 12));
}