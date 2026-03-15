import 'package:flutter/material.dart';

class AppTheme {
  static const brand = Color(0xFF137FEC);
  static const bgLight = Color(0xFFF6F7F8);
  static const bgDark = Color(0xFF101922);
  static const surface = Colors.white;
  static const textPrimary = Color(0xFF172033);
  static const textMuted = Color(0xFF8B97AA);
  static const line = Color(0xFFE3E8F0);

  static ThemeData get lightTheme {
    const baseText = TextTheme(
      headlineLarge: TextStyle(fontSize: 30, fontWeight: FontWeight.w800, color: textPrimary),
      headlineMedium: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: textPrimary),
      titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: textPrimary),
      titleMedium: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: textPrimary),
      bodyLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: textPrimary),
      bodyMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: textMuted),
      bodySmall: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textMuted),
      labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
      labelMedium: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: brand, brightness: Brightness.light),
      scaffoldBackgroundColor: bgLight,
      dividerColor: line,
      textTheme: baseText,
      snackBarTheme: SnackBarThemeData(
        backgroundColor: textPrimary,
        contentTextStyle: baseText.bodyMedium?.copyWith(color: Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        behavior: SnackBarBehavior.floating,
      ),
      cardTheme: const CardThemeData(
        color: surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(20))),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        hintStyle: const TextStyle(color: textMuted, fontWeight: FontWeight.w500),
        labelStyle: const TextStyle(color: textMuted, fontWeight: FontWeight.w600),
        prefixIconColor: textMuted,
        suffixIconColor: textMuted,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: brand, width: 1.4),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: brand,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(56),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          foregroundColor: textPrimary,
          side: const BorderSide(color: line),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      chipTheme: const ChipThemeData(
        backgroundColor: surface,
        selectedColor: brand,
        secondarySelectedColor: brand,
        side: BorderSide(color: line),
        shape: StadiumBorder(),
        labelStyle: TextStyle(fontWeight: FontWeight.w700),
        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      ),
    );
  }

  static ThemeData get darkTheme {
    final theme = lightTheme;
    return theme.copyWith(
      colorScheme: ColorScheme.fromSeed(seedColor: brand, brightness: Brightness.dark),
      scaffoldBackgroundColor: bgDark,
      dividerColor: const Color(0xFF1E293B),
      cardTheme: theme.cardTheme.copyWith(color: const Color(0xFF0F172A)),
      inputDecorationTheme: theme.inputDecorationTheme.copyWith(
        fillColor: const Color(0xFF0F172A),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF1E293B)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF1E293B)),
        ),
      ),
    );
  }
}
