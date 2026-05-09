// lib/providers/theme_provider.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider with ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.light;
  static const String _themeKey = 'theme_mode';

  ThemeMode get themeMode => _themeMode;

  bool get isDarkMode => _themeMode == ThemeMode.dark;

  ThemeProvider() {
    _loadTheme();
  }

  void toggleTheme() {
    _themeMode = _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    _saveTheme();
    notifyListeners();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    // Menggunakan ThemeMode.light.index sebagai default jika tidak ada yang tersimpan
    final themeIndex = prefs.getInt(_themeKey) ?? ThemeMode.light.index;
    _themeMode = ThemeMode.values[themeIndex];
    // Gunakan addPostFrameCallback agar tidak memanggil notifyListeners saat build
    WidgetsBinding.instance.addPostFrameCallback((_) => notifyListeners());
  }

  Future<void> _saveTheme() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_themeKey, _themeMode.index);
  }
}
