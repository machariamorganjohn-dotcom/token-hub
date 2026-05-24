import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const primaryColor = Color(0xFF0052D4);
  static const secondaryColor = Color(0xFF4364F7);
  static const accentColor = Color(0xFF6FB1FC);
  static const backgroundColor = Color(0xFFF0F4FA);
  static const cardColor = Colors.white;
  static const textColor = Color(0xFF0F172A); // Darker for better contrast
  static const subTextColor = Color(0xFF475569); // Darker for better contrast
  static const dividerColor = Color(0xFFE2E8F0);
  static const faintTextColor = Color(0xFF64748B);

  // Dark theme surface colours
  static const darkBackground = Color(0xFF0D1117);
  static const darkSurface = Color(0xFF161B22);
  static const darkCard = Color(0xFF21262D);
  static const darkText = Color(0xFFF8FAFC); // Brighter for better contrast
  static const darkSubText = Color(0xFF94A3B8); // Brighter for better contrast
  static const darkDivider = Color(0xFF334155);
  static const darkFaintText = Color(0xFF64748B);

  // Status Colours
  static const successColor = Color(0xFF10B981);
  static const warningColor = Color(0xFFF59E0B);
  static const errorColor = Color(0xFFEF4444);
  static const infoColor = Color(0xFF3B82F6);

  // Payment Platform Colours
  static const mpesaColor = Color(0xFF49B642);
  static const visaColor = Color(0xFF1A1F71);
  static const mastercardColor = Color(0xFFEB001B);
  static const bankColor = Color(0xFF64748B);

  // Modern UI Constants
  static const double borderRadius = 24.0;
  
  static Gradient get primaryGradient => const LinearGradient(
    colors: [primaryColor, secondaryColor],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static BoxDecoration premiumCardDecoration({bool isDark = false}) => BoxDecoration(
    color: isDark ? darkCard : Colors.white,
    borderRadius: BorderRadius.circular(borderRadius),
    boxShadow: [
      BoxShadow(
        color: (isDark ? Colors.black : primaryColor).withValues(alpha: 0.1),
        blurRadius: 30,
        offset: const Offset(0, 15),
      ),
    ],
  );

  static BoxDecoration glassBoxDecoration({Color? color}) => BoxDecoration(
        color: (color ?? Colors.white).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      );

  // ── Light Theme ─────────────────────────────────────────────────────────────
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: Brightness.light,
        primary: primaryColor,
        secondary: secondaryColor,
        surface: backgroundColor,
      ),
      scaffoldBackgroundColor: backgroundColor,
      textTheme: GoogleFonts.outfitTextTheme().apply(
        bodyColor: textColor,
        displayColor: textColor,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: backgroundColor,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.outfit(
          color: textColor,
          fontSize: 22,
          fontWeight: FontWeight.bold,
          letterSpacing: -0.5,
        ),
        iconTheme: const IconThemeData(color: textColor),
      ),
      cardColor: Colors.white,
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 60),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 8,
          shadowColor: primaryColor.withValues(alpha: 0.4),
          textStyle: GoogleFonts.outfit(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: primaryColor, width: 2.5),
        ),
        labelStyle: GoogleFonts.outfit(color: subTextColor, fontWeight: FontWeight.w500),
        contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      ),
    );
  }

  // ── Dark Theme ──────────────────────────────────────────────────────────────
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: Brightness.dark,
        primary: accentColor,
        secondary: secondaryColor,
        surface: darkSurface,
      ),
      scaffoldBackgroundColor: darkBackground,
      textTheme: GoogleFonts.outfitTextTheme().apply(
        bodyColor: darkText,
        displayColor: darkText,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: darkBackground,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.outfit(
          color: darkText,
          fontSize: 22,
          fontWeight: FontWeight.bold,
          letterSpacing: -0.5,
        ),
        iconTheme: const IconThemeData(color: darkText),
      ),
      cardColor: darkCard,
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 60),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 12,
          shadowColor: primaryColor.withValues(alpha: 0.5),
          textStyle: GoogleFonts.outfit(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkCard,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: accentColor, width: 2.5),
        ),
        labelStyle: GoogleFonts.outfit(color: darkSubText, fontWeight: FontWeight.w500),
        contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      ),
    );
  }
}
