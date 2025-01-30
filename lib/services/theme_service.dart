import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeService {
  static const String _key = 'theme_mode';
  final SharedPreferences _prefs;

  ThemeService(this._prefs);

  static Future<ThemeService> init() async {
    final prefs = await SharedPreferences.getInstance();
    return ThemeService(prefs);
  }

  ThemeMode getThemeMode() {
    final value = _prefs.getString(_key);
    return value == null
        ? ThemeMode.system
        : ThemeMode.values.firstWhere(
            (mode) => mode.toString() == value,
            orElse: () => ThemeMode.system,
          );
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    await _prefs.setString(_key, mode.toString());
  }
}
