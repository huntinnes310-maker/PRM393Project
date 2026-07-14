import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  static const String _themeKey = 'is_dark_theme';
  bool _isDarkTheme = true; // Mặc định là Dark Theme

  bool get isDarkTheme => _isDarkTheme;
  ThemeMode get themeMode => _isDarkTheme ? ThemeMode.dark : ThemeMode.light;

  ThemeProvider() {
    _loadThemeFromPrefs();
  }

  Future<void> _loadThemeFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isDarkTheme = prefs.getBool(_themeKey) ?? true;
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading theme from prefs: $e');
    }
  }

  Future<void> toggleTheme() async {
    _isDarkTheme = !_isDarkTheme;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_themeKey, _isDarkTheme);
    } catch (e) {
      debugPrint('Error saving theme to prefs: $e');
    }
  }
}
