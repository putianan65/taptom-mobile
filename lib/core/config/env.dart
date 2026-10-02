import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Runtime configuration.
///
/// Values come from `--dart-define` first (for CI and release builds), then
/// from the bundled `.env` file (for local development).
abstract final class Env {
  static const fileName = '.env';

  /// Serve every API call from local fixtures. Enable with
  /// `--dart-define=TAPTOM_DEMO=true`; used for showcase builds and UI
  /// testing without a backend.
  static const bool demoMode = bool.fromEnvironment('TAPTOM_DEMO');

  static const String _apiBaseUrlDefine = String.fromEnvironment('API_BASE_URL');
  static const String _mapTilerDefine = String.fromEnvironment('MAPTILER_API_KEY');
  static const String _geminiDefine = String.fromEnvironment('GEMINI_API_KEY');

  static String _read(String define, String key) {
    if (define.isNotEmpty) return define;
    if (!dotenv.isInitialized) return '';
    return dotenv.env[key] ?? '';
  }

  static String get apiBaseUrl {
    final value = _read(_apiBaseUrlDefine, 'API_BASE_URL');
    final url = value.isEmpty ? 'http://localhost:3000/api/v1' : value;
    // The Android emulator reaches the host machine through 10.0.2.2.
    if (!kIsWeb &&
        defaultTargetPlatform == TargetPlatform.android &&
        url.contains('localhost')) {
      return url.replaceFirst('localhost', '10.0.2.2');
    }
    return url;
  }

  static String get mapTilerApiKey => _read(_mapTilerDefine, 'MAPTILER_API_KEY');

  static String get geminiApiKey => _read(_geminiDefine, 'GEMINI_API_KEY');

  static Future<void> init() async {
    try {
      await dotenv.load(fileName: fileName);
    } catch (error) {
      // Missing or empty .env is fine when values come from --dart-define.
      debugPrint('Env: $fileName not loaded ($error)');
    }
  }
}
