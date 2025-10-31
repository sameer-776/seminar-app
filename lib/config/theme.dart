import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// --- Color Palette ---
const Color _primaryColor = Color(0xFF4F46E5); // A modern, vibrant Indigo
const Color _lightBackgroundColor = Color(0xFFF8F9FA); // A very light, soft grey
const Color _darkBackgroundColor = Color(0xFF0A192F); // A deep, calming navy blue
const Color _darkSurfaceColor = Color(0xFF1E293B); // A lighter blue-gray for cards

/// Builds the elegant light theme for the application.
ThemeData buildLightTheme() {
  final baseTheme = ThemeData.light(useMaterial3: true);
  final textTheme = GoogleFonts.interTextTheme(baseTheme.textTheme);

  return baseTheme.copyWith(
    // --- Color Scheme ---
    colorScheme: ColorScheme.fromSeed(
      seedColor: _primaryColor,
      brightness: Brightness.light, // Corrected typo from 'Brightlight'
      background: _lightBackgroundColor,
      surface: Colors.white,
    ),
    scaffoldBackgroundColor: _lightBackgroundColor,
    
    // --- Typography ---
    textTheme: textTheme.copyWith(
      headlineMedium: textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
      titleLarge: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
    ),
    
    // --- Component Styling ---
    appBarTheme: const AppBarTheme(
      backgroundColor: _lightBackgroundColor,
      foregroundColor: Colors.black87,
      elevation: 0,
      scrolledUnderElevation: 0.5,
      surfaceTintColor: Colors.transparent,
      centerTitle: true,
    ),
    // ✅ FIX: Using CardThemeData instead of CardTheme
    cardTheme: CardThemeData(
      elevation: 1,
      shadowColor: Colors.black.withOpacity(0.05),
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
        textStyle: const TextStyle(fontWeight: FontWeight.bold),
        elevation: 1,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.grey.shade100,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: const BorderSide(color: _primaryColor, width: 2),
      ),
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      selectedItemColor: _primaryColor,
      unselectedItemColor: Colors.grey.shade600,
      showUnselectedLabels: true,
      type: BottomNavigationBarType.fixed,
    ),
  );
}

/// Builds the eye-soothing dark theme for the application.
ThemeData buildDarkTheme() {
  final baseTheme = ThemeData.dark(useMaterial3: true);
  final textTheme = GoogleFonts.interTextTheme(baseTheme.textTheme.apply(
    bodyColor: Colors.white,
    displayColor: Colors.white,
  ));

  return baseTheme.copyWith(
    // --- Color Scheme ---
    colorScheme: ColorScheme.fromSeed(
      seedColor: _primaryColor,
      brightness: Brightness.dark,
      background: _darkBackgroundColor,
      surface: _darkSurfaceColor,
    ),
    scaffoldBackgroundColor: _darkBackgroundColor,
    
    // --- Typography ---
    textTheme: textTheme.copyWith(
      headlineMedium: textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
      titleLarge: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
    ),
    
    // --- Component Styling ---
    appBarTheme: const AppBarTheme(
      backgroundColor: _darkBackgroundColor,
      elevation: 0,
      scrolledUnderElevation: 0.5,
      surfaceTintColor: Colors.transparent,
      centerTitle: true,
    ),
    // ✅ FIX: Using CardThemeData instead of CardTheme
    cardTheme: CardThemeData(
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      color: _darkSurfaceColor,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
        textStyle: const TextStyle(fontWeight: FontWeight.bold),
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.grey.shade900,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: const BorderSide(color: _primaryColor, width: 2),
      ),
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      selectedItemColor: Colors.white,
      unselectedItemColor: Colors.grey.shade500,
      backgroundColor: _darkSurfaceColor,
      showUnselectedLabels: true,
      type: BottomNavigationBarType.fixed,
    ),
  );
}