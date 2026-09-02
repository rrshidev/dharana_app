import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dharana_app/app/theme.dart';

/// Глобальный контроллер темы: хранит ThemeMode (светлая/тёмная/система)
/// и персистит выбор в shared_preferences.
class ThemeController extends ValueNotifier<ThemeMode> {
  ThemeController._() : super(AppTheme.themeMode) {
    _load();
  }

  static final ThemeController instance = ThemeController._();

  static const _prefsKey = 'theme_mode';
  static const _map = <String, ThemeMode>{
    'light': ThemeMode.light,
    'dark': ThemeMode.dark,
    'system': ThemeMode.system,
  };

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getString(_prefsKey);
      if (stored != null && _map.containsKey(stored)) {
        _apply(_map[stored]!);
      }
    } catch (_) {}
  }

  Future<void> setTheme(ThemeMode mode) async {
    _apply(mode);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsKey, _map.entries
          .firstWhere((e) => e.value == mode,
              orElse: () => const MapEntry('system', ThemeMode.system))
          .key);
    } catch (_) {}
  }

  void _apply(ThemeMode mode) {
    AppTheme.themeMode = mode;
    if (value != mode) value = mode;
  }

  static ThemeMode fromIndex(int index) {
    return const [ThemeMode.system, ThemeMode.light, ThemeMode.dark]
        .elementAt(index);
  }

  static int indexOf(ThemeMode mode) {
    return const [ThemeMode.system, ThemeMode.light, ThemeMode.dark]
        .indexOf(mode);
  }
}
