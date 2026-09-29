import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Глобальный контроллер языка: хранит Locale (ru/en), персистит
/// выбор в shared_preferences и применяет его к MaterialApp.
class LanguageController extends ValueNotifier<Locale> {
  LanguageController._() : super(const Locale('ru')) {
    _load();
  }

  static final LanguageController instance = LanguageController._();

  static const _prefsKey = 'language';
  static const supported = <Locale>[Locale('ru'), Locale('en')];
  static const _map = <String, Locale>{
    'ru': Locale('ru'),
    'en': Locale('en'),
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

  Future<void> setLanguage(Locale locale) async {
    _apply(locale);
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = locale.languageCode;
      await prefs.setString(
          _prefsKey, _map.containsKey(key) ? key : 'ru');
    } catch (_) {}
  }

  void _apply(Locale locale) {
    if (value != locale) value = locale;
  }

  static bool isSupported(Locale locale) =>
      locale.languageCode == 'ru' || locale.languageCode == 'en';
}