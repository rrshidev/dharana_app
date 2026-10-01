// Имена геттеров палитры намеренно в UpperCamelCase (стиль Flutter-палитр: Background, Surface, Accent).
// ignore_for_file: non_constant_identifier_names
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
  static const Color accentOn = Color(0xFF1A1B2E);
  static const Color accentGreenOn = Color(0xFF1A1B2E);

  // ---------------- Light palette ----------------
  // Дефолтная тема приложения (как и на сайте): светлая.
  // ink — глубокий графитово-кофейный вместо почти чёрного, чтобы текст
  // не выглядел тяжело на светлом фоне.
  static const Color _lightBackground = Color(0xFFF6F1EA);
  static const Color _lightSurface = Color(0xFFFFFEFC);
  static const Color _lightSurfaceLight = Color(0xFFEDE6DC);
  static const Color _lightAccent = Color(0xFFE8A87C);
  static const Color _lightAccentGreen = Color(0xFF6FB47A);
  static const Color _lightTextPrimary = Color(0xFF3A352E);
  static const Color _lightTextSecondary = Color(0xFF736B60);
  static const Color _lightDanger = Color(0xFFD95050);
  static const Color _lightCardBorder = Color(0xFFE2D9CD);
  // Текст на пастельной заливке/текст акцентом: без затемнения контраст 1.8–2.2.
  static const Color _lightAccentInk = Color(0xFF9C5F34);
  static const Color _lightAccentGreenInk = Color(0xFF3F7A49);
  static const Color _lightAccentOn = Color(0xFF33281C);
  static const Color _lightAccentGreenOn = Color(0xFF1E3F1B);
  // ------------------------------------------------

  static ThemeMode themeMode = ThemeMode.light;

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

  /// Акцент, пригодный для ТЕКСТА на фоне страницы (контраст 4.56 в светлой).
  static Color get AccentInk =>
      isDark ? accent : _lightAccentInk;

  /// Шалфей, пригодный для ТЕКСТА на фоне страницы (контраст 4.57 в светлой).
  static Color get AccentGreenInk =>
      isDark ? accentGreen : _lightAccentGreenInk;

  /// Цвет текста ПОВЕРХ заливки [Accent] (контраст 7.07 в светлой).
  static Color get AccentOn => isDark ? accentOn : _lightAccentOn;

  /// Цвет текста ПОВЕРХ заливки [AccentGreen] (контраст 4.76 в светлой).
  static Color get AccentGreenOn =>
      isDark ? accentGreenOn : _lightAccentGreenOn;

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      fontFamily: 'Inter',
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
          fontSize: 20,
          fontWeight: FontWeight.w500,
          fontFamily: 'CormorantGaramond',
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
      // Заголовки — антиква Cormorant Garamond (как на сайте), текст — Inter.
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          fontSize: 34,
          fontWeight: FontWeight.w500,
          fontFamily: 'CormorantGaramond',
          height: 1.15,
          color: textPrimary,
        ),
        headlineMedium: TextStyle(
          fontSize: 27,
          fontWeight: FontWeight.w500,
          fontFamily: 'CormorantGaramond',
          height: 1.2,
          color: textPrimary,
        ),
        headlineSmall: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w500,
          fontFamily: 'CormorantGaramond',
          height: 1.25,
          color: textPrimary,
        ),
        titleLarge: TextStyle(
          fontSize: 19,
          fontWeight: FontWeight.w500,
          fontFamily: 'CormorantGaramond',
          height: 1.25,
          color: textPrimary,
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: textPrimary,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          height: 1.5,
          color: textPrimary,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          height: 1.45,
          color: textSecondary,
        ),
        bodySmall: TextStyle(
          fontSize: 12,
          height: 1.4,
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
            fontFamily: 'Inter',
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
      fontFamily: 'Inter',
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
          fontSize: 20,
          fontWeight: FontWeight.w500,
          fontFamily: 'CormorantGaramond',
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
      // Заголовки — антиква Cormorant Garamond (как на сайте), текст — Inter.
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          fontSize: 34,
          fontWeight: FontWeight.w500,
          fontFamily: 'CormorantGaramond',
          height: 1.15,
          color: _lightTextPrimary,
        ),
        headlineMedium: TextStyle(
          fontSize: 27,
          fontWeight: FontWeight.w500,
          fontFamily: 'CormorantGaramond',
          height: 1.2,
          color: _lightTextPrimary,
        ),
        headlineSmall: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w500,
          fontFamily: 'CormorantGaramond',
          height: 1.25,
          color: _lightTextPrimary,
        ),
        titleLarge: TextStyle(
          fontSize: 19,
          fontWeight: FontWeight.w500,
          fontFamily: 'CormorantGaramond',
          height: 1.25,
          color: _lightTextPrimary,
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: _lightTextPrimary,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          height: 1.5,
          color: _lightTextPrimary,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          height: 1.45,
          color: _lightTextSecondary,
        ),
        bodySmall: TextStyle(
          fontSize: 12,
          height: 1.4,
          color: _lightTextSecondary,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _lightAccent,
          foregroundColor: _lightAccentOn,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            fontFamily: 'Inter',
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
        selectedItemColor: _lightAccentInk,
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
      color: AccentInk,
      letterSpacing: 2,
    );
  }

  static String starsText(int count) {
    return '★' * count + '☆' * (5 - count);
  }
}
