import 'package:flutter/material.dart';
import '../services/storage_service.dart';
import 'app_theme.dart';

class ThemeProvider extends ChangeNotifier {

  
  ThemeMode _themeMode = ThemeMode.system;
  
  ThemeMode get themeMode => _themeMode;
  
  bool get isDarkMode {
    if (_themeMode == ThemeMode.system) {
      return WidgetsBinding.instance.platformDispatcher.platformBrightness == Brightness.dark;
    }
    return _themeMode == ThemeMode.dark;
  }
  
  bool get isLightMode => _themeMode == ThemeMode.light;
  
  bool get isSystemMode => _themeMode == ThemeMode.system;

  ThemeProvider() {
    _loadThemeMode();
  }

  // Load saved theme mode from storage
  Future<void> _loadThemeMode() async {
    try {
      final themeModeString = await StorageService.getThemeMode();
      if (themeModeString != null) {
        final themeIndex = int.tryParse(themeModeString) ?? 0;
        if (themeIndex >= 0 && themeIndex < ThemeMode.values.length) {
          _themeMode = ThemeMode.values[themeIndex];
        }
      }
      notifyListeners();
    } catch (e) {
      // If loading fails, use system theme
      _themeMode = ThemeMode.system;
    }
  }

  // Save theme mode to storage
  Future<void> _saveThemeMode() async {
    try {
      await StorageService.saveThemeMode(_themeMode.index.toString());
    } catch (e) {
      // Log error for debugging (in production, you might want to send this to a logging service)
      debugPrint('Failed to save theme mode: $e');
      // Could also show a user-friendly error message here
    }
  }

  // Set theme mode
  Future<void> setThemeMode(ThemeMode themeMode) async {
    if (_themeMode != themeMode) {
      _themeMode = themeMode;
      notifyListeners();
      await _saveThemeMode();
    }
  }

  // Toggle between light and dark themes
  Future<void> toggleTheme() async {
    if (_themeMode == ThemeMode.light) {
      await setThemeMode(ThemeMode.dark);
    } else if (_themeMode == ThemeMode.dark) {
      await setThemeMode(ThemeMode.light);
    } else {
      // If system mode, check current system brightness and switch to opposite
      final isCurrentlyDark = WidgetsBinding.instance.platformDispatcher.platformBrightness == Brightness.dark;
      await setThemeMode(isCurrentlyDark ? ThemeMode.light : ThemeMode.dark);
    }
  }

  // Set to light theme
  Future<void> setLightTheme() async {
    await setThemeMode(ThemeMode.light);
  }

  // Set to dark theme
  Future<void> setDarkTheme() async {
    await setThemeMode(ThemeMode.dark);
  }

  // Set to system theme
  Future<void> setSystemTheme() async {
    await setThemeMode(ThemeMode.system);
  }

  // Get current theme data
  ThemeData get currentTheme {
    if (_themeMode == ThemeMode.system) {
      final brightness = WidgetsBinding.instance.platformDispatcher.platformBrightness;
      return AppTheme.getTheme(brightness);
    } else if (_themeMode == ThemeMode.dark) {
      return AppTheme.darkTheme;
    } else {
      return AppTheme.lightTheme;
    }
  }

  // Get theme data for specific mode
  ThemeData getThemeForMode(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return AppTheme.lightTheme;
      case ThemeMode.dark:
        return AppTheme.darkTheme;
      case ThemeMode.system:
        final brightness = WidgetsBinding.instance.platformDispatcher.platformBrightness;
        return AppTheme.getTheme(brightness);
    }
  }

  // Get theme name for display
  String getThemeName(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.dark:
        return 'Dark';
      case ThemeMode.system:
        return 'System';
    }
  }

  // Get theme description
  String getThemeDescription(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'Always use light theme';
      case ThemeMode.dark:
        return 'Always use dark theme';
      case ThemeMode.system:
        return 'Follow system theme';
    }
  }

  // Get theme icon
  IconData getThemeIcon(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return Icons.light_mode;
      case ThemeMode.dark:
        return Icons.dark_mode;
      case ThemeMode.system:
        return Icons.brightness_auto;
    }
  }
}
