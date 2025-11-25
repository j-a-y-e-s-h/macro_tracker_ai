import 'package:flutter/material.dart';

class AppTheme {
  // Ultimate "Midnight" Palette
  static const Color black = Color(0xFF0F172A); // Slate 900 - Deep Background
  static const Color surface = Color(0xFF1E293B); // Slate 800 - Card Surface
  static const Color surfaceHighlight = Color(0xFF334155); // Slate 700 - Lighter Surface
  
  // "Neon" Accents
  static const Color primary = Color(0xFF2DD4BF); // Teal 400 - Vibrant Primary
  static const Color secondary = Color(0xFFF472B6); // Pink 400 - Vibrant Secondary
  static const Color tertiary = Color(0xFFFB923C); // Orange 400 - Vibrant Tertiary
  
  // Text Colors
  static const Color textPrimary = Color(0xFFF8FAFC); // Slate 50
  static const Color textSecondary = Color(0xFF94A3B8); // Slate 400
  static const Color textDim = Color(0xFF64748B); // Slate 500

  // Macro Colors (Pastels for readability)
  static const Color proteinColor = Color(0xFFA78BFA); // Violet 400
  static const Color carbsColor = Color(0xFF60A5FA); // Blue 400
  static const Color fatColor = Color(0xFFFBBF24); // Amber 400
  
  static final darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: black,
    primaryColor: primary,
    colorScheme: const ColorScheme.dark(
      primary: primary,
      secondary: secondary,
      tertiary: tertiary,
      surface: surface,
      onSurface: textPrimary,
      background: black,
    ),
    cardTheme: CardThemeData(
      color: surface.withOpacity(0.8), // Glassmorphism base
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(20)), // Modern rounded corners
        side: BorderSide(color: Colors.white10, width: 1), // Subtle border
      ),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent, // Transparent for glass effect
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        color: textPrimary,
        fontSize: 20,
        fontWeight: FontWeight.bold,
        letterSpacing: 0.5,
      ),
      iconTheme: IconThemeData(color: textSecondary),
    ),
    textTheme: const TextTheme(
      displayLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: textPrimary, letterSpacing: -1.0),
      titleLarge: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: textPrimary, letterSpacing: -0.5),
      titleMedium: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: textPrimary),
      bodyLarge: TextStyle(fontSize: 16, color: textPrimary, height: 1.5),
      bodyMedium: TextStyle(fontSize: 14, color: textSecondary, height: 1.4),
      labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: primary, letterSpacing: 0.5),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: surface,
      selectedItemColor: primary,
      unselectedItemColor: textSecondary,
      type: BottomNavigationBarType.fixed,
      showSelectedLabels: true,
      showUnselectedLabels: true,
      selectedLabelStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
      unselectedLabelStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
      elevation: 0,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: primary, width: 1.5),
      ),
      labelStyle: const TextStyle(color: textSecondary),
      hintStyle: const TextStyle(color: textDim),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: black,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    ),
  );
}
