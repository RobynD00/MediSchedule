import 'package:flutter/material.dart';
// Central visual system for accessible, consistent MediSchedule screens.
// Update colors, typography and widget themes here rather than per screen.
abstract final class AppTheme 
{
  static const Color primary = Color(0xFF087E78);
  static const Color background = Color(0xFFF7FAF9);
  static const Color textColor = Color(0xFF202B28);

  static ThemeData get lightTheme => light;

  static ThemeData get light 
  {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: primary,
      brightness: Brightness.light,
      surface: background,
    );

    final textTheme = ThemeData.light().textTheme;

    return ThemeData
    (
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: background,

      textTheme: textTheme.copyWith(
        headlineMedium: const TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          color: textColor,
        ),

        headlineSmall: const TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          height: 1.2,
          color: textColor,
        ),

        titleLarge: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: textColor,
        ),

        titleMedium: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),

        bodyLarge: const TextStyle(
          fontSize: 17,
          height: 1.4,
          color: textColor,
        ),

        bodyMedium: const TextStyle(
          fontSize: 15,
          height: 1.4,
          color: textColor,
        ),
      ),

      appBarTheme: AppBarTheme
      (
        backgroundColor: background,
        foregroundColor: colorScheme.onSurface,
        centerTitle: false,
        titleTextStyle: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: textColor,
        ),
      ),

      cardTheme: CardThemeData
      (
        color: Colors.white,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(
            color: Color(0xFFE1EAE7),
          ),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme
      (
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 18,
        ),

        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
        ),

        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: Color(0xFFB7C9C4),
          ),
        ),

        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: colorScheme.primary,
            width: 2,
          ),
        ),

        labelStyle: const TextStyle(fontSize: 16),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData
      (
        style: ElevatedButton.styleFrom
        (
          backgroundColor: primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 56),
          textStyle: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),

      filledButtonTheme: FilledButtonThemeData
      (
        style: FilledButton.styleFrom(
          minimumSize: const Size(64, 56),
          padding: const EdgeInsets.symmetric(
            horizontal: 22,
            vertical: 14,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),

      navigationBarTheme: NavigationBarThemeData
      (
        height: 76,
        backgroundColor: Colors.white,
        indicatorColor: colorScheme.primaryContainer,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            fontSize: 13,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w700
                : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
