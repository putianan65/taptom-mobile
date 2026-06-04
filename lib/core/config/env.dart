import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class Env {
  static String get fileName => '.env';

  static String get apiBaseUrl {
    final url = dotenv.env['API_BASE_URL'] ?? 'http://localhost:3000/api/v1';
    if (Platform.isAndroid && url.contains('localhost')) {
      return url.replaceFirst('localhost', '10.0.2.2');
    }
    return url;
  }

  static String get geminiApiKey => dotenv.env['GEMINI_API_KEY'] ?? '';

  static Future<void> init() async {
    await dotenv.load(fileName: fileName);
  }
}
