import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

class AppLogger {
  static final Logger _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 0,
      errorMethodCount: 8,
      lineLength: 120,
      colors: true,
      printEmojis: false,
      printTime: true,
    ),
    filter: ProductionFilter(), // Custom filter to control logs in production
  );

  static void debug(String message, {dynamic error, StackTrace? stackTrace, Map<String, dynamic>? params}) {
    // Only log debug messages in debug mode
    if (kDebugMode) {
      _logger.d(message, error: error, stackTrace: stackTrace);
      if (params != null) {
        _logger.d('Params: $params');
      }
    }
  }

  static void info(String message, {Map<String, dynamic>? params}) {
    if (kDebugMode) {
      _logger.i(message);
       if (params != null) {
        _logger.i('Params: $params');
      }
    }
  }

  static void warning(String message, {dynamic error, StackTrace? stackTrace}) {
    _logger.w(message, error: error, stackTrace: stackTrace);
  }

  static void error(String message, {dynamic error, StackTrace? stackTrace}) {
    // Log to console in debug
    if (kDebugMode) {
      _logger.e(message, error: error, stackTrace: stackTrace);
    }
    
    // In production without Firebase, we might silent fail or use another simplified reporting
    // if (kReleaseMode) { ... }
  }
}
