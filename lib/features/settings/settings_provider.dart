import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';

class SettingsProvider extends ChangeNotifier {
  // State variables
  ThemeMode _themeMode = ThemeMode.system;
  Locale _locale = const Locale('th', 'TH');
  bool _notificationsEnabled = true;
  String _version = '';

  // Getters
  ThemeMode get themeMode => _themeMode;
  Locale get locale => _locale;
  bool get notificationsEnabled => _notificationsEnabled;
  String get version => _version;
  bool get isDarkMode => _themeMode == ThemeMode.dark;

  // Keys for SharedPreferences
  static const String _keyTheme = 'theme_mode';
  static const String _keyLocale = 'locale';
  static const String _keyNotifications = 'notifications_enabled';

  SettingsProvider() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();

    // Load Theme
    final themeIndex = prefs.getInt(_keyTheme);
    if (themeIndex != null) {
      _themeMode = ThemeMode.values[themeIndex];
    }

    // Load Locale
    final languageCode = prefs.getString(_keyLocale);
    if (languageCode != null) {
      if (languageCode == 'en') {
        _locale = const Locale('en', 'US');
      } else {
        _locale = const Locale('th', 'TH');
      }
    }

    // Load Notifications
    _notificationsEnabled = prefs.getBool(_keyNotifications) ?? true;

    // Load Version
    final packageInfo = await PackageInfo.fromPlatform();
    _version = '${packageInfo.version} (${packageInfo.buildNumber})';

    notifyListeners();
  }

  Future<void> toggleTheme(bool isDark) async {
    _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyTheme, _themeMode.index);
    notifyListeners();
  }

  Future<void> setLocale(String languageCode) async {
    if (languageCode == 'en') {
      _locale = const Locale('en', 'US');
    } else {
      _locale = const Locale('th', 'TH');
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyLocale, languageCode);
    notifyListeners();
  }

  Future<bool> toggleNotifications(bool value) async {
    if (value) {
      final status = await Permission.notification.request();
      if (status.isDenied || status.isPermanentlyDenied) {
        // If denied, we cannot enable notifications
        _notificationsEnabled = false;
        notifyListeners();
        return false;
      }
    }

    _notificationsEnabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyNotifications, value);
    notifyListeners();
    return true;
  }
}
