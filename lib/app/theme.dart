import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();

  static const Color background = Color(0xFF1A1B2E);
  static const Color surface = Color(0xFF252640);
  static const Color surfaceLight = Color(0xFF2E2F4A);
  static const Color accent = Color(0xFFE8A87C);
  static const Color accentGreen = Color(0xFF85C88A);
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFA0A0B8);
  static const Color danger = Color(0xFFE85D5D);
  static const Color cardBorder = Color(0xFF353656);

  // ---------------- Light palette ----------------
  static const Color _lightBackground = Color(0xFFF6F1EA);
  static const Color _lightSurface = Color(0xFFFFFFFF);
  static const Color _lightSurfaceLight = Color(0xFFEDE6DC);
  static const Color _lightAccent = Color(0xFFE8A87C);
  static const Color _lightAccentGreen = Color(0xFF6FB47A);
  static const Color _lightTextPrimary = Color(0xFF1A1B2E);
  static const Color _lightTextSecondary = Color(0xFF6B6B7D);
  static const Color _lightDanger = Color(0xFFD95050);
  static const Color _lightCardBorder = Color(0xFFE2D9CD);
  // ------------------------------------------------

  static ThemeMode themeMode = ThemeMode.system;

  static bool get isDark {
    return themeMode == ThemeMode.dark ||
        (themeMode == ThemeMode.system &&
            WidgetsBinding.instance.platformDispatcher.platformBrightness ==
                Brightness.dark);
  }

  static ThemeMode effectiveMode() {
    return themeMode;
  }

  /// Effective Brightness for the current themeMode setting.
  static Brightness get brightness =>
      isDark ? Brightness.dark : Brightness.light;

  // Dynamic color getters that follow themeMode.
  static Color get Background => isDark ? background : _lightBackground;
  static Color get Surface => isDark ? surface : _lightSurface;
  static Color get SurfaceLight => isDark ? surfaceLight : _lightSurfaceLight;
  static Color get Accent => isDark ? accent : _lightAccent;
  static Color get AccentGreen => isDark ? accentGreen : _lightAccentGreen;
  static Color get TextPrimary => isDark ? textPrimary : _lightTextPrimary;
  static Color get TextSecondary =>
      isDark ? textSecondary : _lightTextSecondary;
  static Color get Danger => isDark ? danger : _lightDanger;
  static Color get CardBorder => isDark ? cardBorder : _lightCardBorder;

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      colorScheme: const ColorScheme.dark(
        primary: accent,
        secondary: accentGreen,
        surface: surface,
        error: danger,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: background,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        iconTheme: IconThemeData(color: textPrimary),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: cardBorder, width: 1),
        ),
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          color: textPrimary,
        ),
        headlineMedium: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        titleLarge: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: textPrimary,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          color: textPrimary,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          color: textSecondary,
        ),
        bodySmall: TextStyle(
          fontSize: 12,
          color: textSecondary,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: background,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: cardBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: cardBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: accent, width: 2),
        ),
        hintStyle: const TextStyle(color: textSecondary),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: surfaceLight,
        labelStyle: const TextStyle(
          fontSize: 12,
          color: textSecondary,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: cardBorder),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: surface,
        selectedItemColor: accent,
        unselectedItemColor: textSecondary,
      ),
    );
  }

  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: _lightBackground,
      colorScheme: const ColorScheme.light(
        primary: _lightAccent,
        secondary: _lightAccentGreen,
        surface: _lightSurface,
        error: _lightDanger,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: _lightBackground,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: _lightTextPrimary,
        ),
        iconTheme: IconThemeData(color: _lightTextPrimary),
      ),
      cardTheme: CardThemeData(
        color: _lightSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: _lightCardBorder, width: 1),
        ),
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          color: _lightTextPrimary,
        ),
        headlineMedium: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: _lightTextPrimary,
        ),
        titleLarge: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: _lightTextPrimary,
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: _lightTextPrimary,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          color: _lightTextPrimary,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          color: _lightTextSecondary,
        ),
        bodySmall: TextStyle(
          fontSize: 12,
          color: _lightTextSecondary,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _lightAccent,
          foregroundColor: _lightTextPrimary,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _lightSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _lightCardBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _lightCardBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _lightAccent, width: 2),
        ),
        hintStyle: const TextStyle(color: _lightTextSecondary),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: _lightSurfaceLight,
        labelStyle: const TextStyle(
          fontSize: 12,
          color: _lightTextSecondary,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: _lightCardBorder),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: _lightSurface,
        selectedItemColor: _lightTextPrimary,
        unselectedItemColor: _lightTextSecondary,
      ),
    );
  }

  static ThemeData get current {
    return isDark ? darkTheme : lightTheme;
  }

  static TextStyle difficultyStars(int count) {
    return TextStyle(
      fontSize: 14,
      color: Accent,
      letterSpacing: 2,
    );
  }

  static String starsText(int count) {
    return '★' * count + '☆' * (5 - count);
  }
}
