import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Primary colors
  static const Color leafGreen = Color(0xFF2D5A27);
  static const Color softSage = Color(0xFFB8D4B8);
  static const Color mintGreen = Color(0xFF98D4BB);
    static const Color mossGreen = Color(0xFF8A9A5B);

  
  // Accent colors
  static const Color terracotta = Color(0xFFD4694A);
  static const Color sunYellow = Color(0xFFF4D03F);
  static const Color soilBrown = Color(0xFF5D4E37);
  
  // Water colors
  static const Color waterBlue = Color(0xFF5B9BD5);
  static const Color waterBlueDark = Color(0xFF3A7FC2);
  static const Color waterBlueLight = Color(0xFF8BC4EA);
  
  // Status colors
  static const Color successGreen = Color(0xFF4CAF50);
  static const Color warningOrange = Color(0xFFFF9800);
  static const Color errorRed = Color(0xFFE53935);
  
  // Streak colors
  static const Color streakOrange = Color(0xFFFF6B35);
  static const Color streakYellow = Color(0xFFFFD700);
  

  // Background
  static const Color cream = Color(0xFFFAF8F5);
  static const Color cardWhite = Colors.white;

  static ThemeData get theme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: leafGreen,
        primary: leafGreen,
        secondary: terracotta,
        surface: cream,
        error: terracotta,
      ),
      textTheme: GoogleFonts.quicksandTextTheme(),
      scaffoldBackgroundColor: cream,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        titleTextStyle: GoogleFonts.comfortaa(
          fontSize: 20,
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
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
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
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: softSage, width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: softSage, width: 2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: leafGreen, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: terracotta, width: 2),
        ),
        labelStyle: GoogleFonts.quicksand(color: soilBrown),
        hintStyle: GoogleFonts.quicksand(color: soilBrown.withValues(alpha:0.5)),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: leafGreen,
        unselectedItemColor: soilBrown.withValues(alpha:0.5),
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
    );
  }
}