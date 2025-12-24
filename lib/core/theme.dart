import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Earthy, organic color palette
  static const Color leafGreen = Color(0xFF2D5A27);
  static const Color mintGreen = Color(0xFF98D4BB);
  static const Color softSage = Color(0xFFB8D4BE);
  static const Color warmCream = Color(0xFFFAF8F5);
  static const Color terracotta = Color(0xFFD4744A);
  static const Color waterBlue = Color(0xFF5B9BD5);
  static const Color waterBlueDark = Color(0xFF3A7BC8);
  static const Color soilBrown = Color(0xFF6B4423);
  static const Color sunYellow = Color(0xFFFFD93D);
  
  static ThemeData get theme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: warmCream,
      colorScheme: ColorScheme.fromSeed(
        seedColor: leafGreen,
        brightness: Brightness.light,
        primary: leafGreen,
        secondary: terracotta,
        surface: warmCream,
        background: warmCream,
      ),
      textTheme: GoogleFonts.quicksandTextTheme().copyWith(
        displayLarge: GoogleFonts.comfortaa(
          fontSize: 36,
          fontWeight: FontWeight.bold,
          color: leafGreen,
        ),
        headlineMedium: GoogleFonts.quicksand(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: leafGreen,
        ),
        titleLarge: GoogleFonts.quicksand(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: soilBrown,
        ),
        bodyLarge: GoogleFonts.quicksand(
          fontSize: 16,
          color: soilBrown,
        ),
        bodyMedium: GoogleFonts.quicksand(
          fontSize: 14,
          color: soilBrown,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.comfortaa(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: leafGreen,
        ),
        iconTheme: const IconThemeData(color: leafGreen),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: leafGreen,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
          textStyle: GoogleFonts.quicksand(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: softSage, width: 2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: leafGreen, width: 2),
        ),
        labelStyle: GoogleFonts.quicksand(color: soilBrown),
        hintStyle: GoogleFonts.quicksand(color: soilBrown.withOpacity(0.5)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: terracotta,
        foregroundColor: Colors.white,
        elevation: 4,
      ),
    );
  }
}
