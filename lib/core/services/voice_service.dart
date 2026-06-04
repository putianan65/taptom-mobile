import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:speech_to_text/speech_recognition_result.dart';

/// Service for handling Speech-to-Text functionality
class VoiceService {
  final SpeechToText _speechToText = SpeechToText();
  bool _isInitialized = false;
  bool _isListening = false;

  bool get isListening => _isListening;
  bool get isAvailable => _isInitialized;

  /// Initialize the speech recognition service
  Future<bool> initialize() async {
    if (_isInitialized) return true;

    try {
      _isInitialized = await _speechToText.initialize(
        onError: (error) {
          /* Silent error handling */
        },
        onStatus: (status) {
          /* Silent status handling */
        },
      );
      return _isInitialized;
    } catch (e) {
      return false;
    }
  }

  /// Start listening for speech input
  Future<void> startListening({
    required void Function(String text) onResult,
    void Function()? onListeningStarted,
    void Function()? onListeningStopped,
  }) async {
    if (!_isInitialized) {
      final success = await initialize();
      if (!success) {
        return;
      }
    }

    if (_isListening) return;

    _isListening = true;
    onListeningStarted?.call();

    await _speechToText.listen(
      onResult: (SpeechRecognitionResult result) {
        if (result.finalResult) {
          onResult(result.recognizedWords);
          _isListening = false;
          onListeningStopped?.call();
        }
      },
      localeId: 'th_TH', // Thai language
      listenMode: ListenMode.confirmation,
      cancelOnError: true,
      partialResults: false,
    );
  }

  /// Stop listening
  Future<void> stopListening() async {
    if (!_isListening) return;

    await _speechToText.stop();
    _isListening = false;
  }

  /// Cancel listening
  Future<void> cancelListening() async {
    if (!_isListening) return;

    await _speechToText.cancel();
    _isListening = false;
  }

  /// Get available locales
  Future<List<String>> getAvailableLocales() async {
    if (!_isInitialized) await initialize();

    final locales = await _speechToText.locales();
    return locales.map((l) => l.localeId).toList();
  }

  void dispose() {
    _speechToText.cancel();
  }
}
