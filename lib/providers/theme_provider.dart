import 'package:flutter/material.dart';
import '../services/storage_service.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.dark;

  ThemeMode get themeMode => _themeMode;
  bool get isDarkMode => _themeMode == ThemeMode.dark;

  ThemeProvider() {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    // Default to dark; only switch to light if user has explicitly saved light.
    final isDark = await StorageService.getTheme();
    _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    // If no preference has ever been saved, keep dark (the field default).
    notifyListeners();
  }

  Future<void> toggleTheme() async {
    _themeMode =
        _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    await StorageService.saveTheme(_themeMode == ThemeMode.dark);
    notifyListeners();
  }
}
