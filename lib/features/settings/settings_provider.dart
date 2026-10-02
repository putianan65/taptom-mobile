import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// User preferences persisted on the device.
class SettingsProvider extends ChangeNotifier {
  SettingsProvider() {
    _load();
  }

  static const _keyTheme = 'theme_mode';
  static const _keyNotifications = 'notifications_enabled';
  static const _keyTextScale = 'text_scale';

  /// Text size steps offered in settings. Older farmers often prefer large.
  static const textScales = <(double, String)>[
    (0.94, 'เล็ก'),
    (1.0, 'ปกติ'),
    (1.12, 'ใหญ่'),
    (1.25, 'ใหญ่มาก'),
  ];

  ThemeMode _themeMode = ThemeMode.system;
  bool _notificationsEnabled = true;
  double _textScale = 1.0;
  String _version = '';

  ThemeMode get themeMode => _themeMode;
  bool get notificationsEnabled => _notificationsEnabled;
  double get textScale => _textScale;
  String get version => _version;
  bool get isDarkMode => _themeMode == ThemeMode.dark;

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final themeIndex = prefs.getInt(_keyTheme);
    if (themeIndex != null && themeIndex < ThemeMode.values.length) {
      _themeMode = ThemeMode.values[themeIndex];
    }
    _notificationsEnabled = prefs.getBool(_keyNotifications) ?? true;
    _textScale = prefs.getDouble(_keyTextScale) ?? 1.0;
    notifyListeners();

    try {
      final info = await PackageInfo.fromPlatform();
      _version = '${info.version} (${info.buildNumber})';
      notifyListeners();
    } catch (_) {
      _version = '';
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyTheme, mode.index);
  }

  /// Kept for older call sites that toggle dark mode on and off.
  Future<void> toggleTheme(bool isDark) =>
      setThemeMode(isDark ? ThemeMode.dark : ThemeMode.light);

  Future<void> setTextScale(double scale) async {
    _textScale = scale;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_keyTextScale, scale);
  }

  /// Turns in-app notifications on or off. Returns false when the OS
  /// permission was refused.
  Future<bool> toggleNotifications(bool value) async {
    if (value) {
      try {
        final status = await Permission.notification.request();
        if (status.isDenied || status.isPermanentlyDenied) {
          _notificationsEnabled = false;
          notifyListeners();
          return false;
        }
      } catch (_) {
        // Platforms without a notification permission (web) fall through.
      }
    }
    _notificationsEnabled = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyNotifications, value);
    return true;
  }
}
