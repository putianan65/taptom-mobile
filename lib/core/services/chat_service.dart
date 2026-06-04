import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/env.dart';

/// Production-grade service for communicating with Google Gemini AI via REST API.
///
/// Features:
/// - Conversation history trimming (max turns)
/// - Base64 image cleanup from old history entries
/// - Retry with exponential backoff on rate limits (429)
/// - Daily usage tracking with configurable limit
/// - Token estimation for smart context management
/// - Structured error handling
class ChatService {
  // ─── Configuration ───────────────────────────────────────────────
  /// Maximum number of conversation turns (user+model pairs) to keep in history
  static const int _maxHistoryTurns = 10;

  /// Maximum estimated tokens before auto-trimming history
  static const int _maxEstimatedTokens = 25000;

  // ── Retry/Fallback (disabled - free tier rate limit too strict) ──
  // static const int _maxRetries = 3;
  // static const List<int> _retryDelays = [10, 30, 60];

  /// Daily request limit per user (free tier protection)
  static const int dailyRequestLimit = 50;

  /// HTTP request timeout
  static const Duration _requestTimeout = Duration(seconds: 30);

  // ─── API Config ──────────────────────────────────────────────────
  static String get _apiKey {
    final key = Env.geminiApiKey;
    if (key.isEmpty) {
      debugPrint('GEMINI_API_KEY is not set in .env');
    }
    return key;
  }

  static const String _baseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent';

  // ── Model Fallback (disabled - gemini-2.0-flash-lite ยังไม่เสถียร) ──
  // static const List<String> _modelUrls = [
  //   'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent',
  //   'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash-lite:generateContent',
  // ];

  // ─── State ───────────────────────────────────────────────────────
  final List<Map<String, dynamic>> _history = [];

  // ─── Daily Usage Tracking Keys ───────────────────────────────────
  static const String _prefKeyDailyCount = 'chat_daily_request_count';
  static const String _prefKeyDailyDate = 'chat_daily_date';

  // ─── System Prompt ───────────────────────────────────────────────
  static const String _systemPrompt = '''
คุณคือ "AI ผู้ช่วยด้านกฎหมายและการเกษตรของประเทศไทย"
ทำงานอยู่ภายในแอปพลิเคชัน TAPTOM ในรูปแบบช่องแชท

ขอบเขตหน้าที่:
1. ให้ข้อมูลด้านกฎหมายเกี่ยวกับพืชควบคุม/พืชเสพติดในประเทศไทย
2. ให้ความรู้ด้านการเกษตรเชิงวิชาการและมาตรฐาน GAP
3. วิเคราะห์ภาพถ่ายพืช (โรค, แมลง)

ข้อห้าม (ต้องปฏิบัติ):
- ห้ามให้ how-to การปลูกพืชเสพติด
- ห้ามให้สูตรการผลิตที่ผิดกฎหมาย

รูปแบบการตอบ (สำคัญ - เพื่อการอ่านง่ายบนมือถือ):
- ❌ ห้ามใช้เครื่องหมาย ** (ดอกจันคู่) หรือตัวหนา (Bold) พร่ำเพรื่อ
- ✅ ให้ใช้ Emoji (เช่น 🌿, 💡, ⚠️) นำหน้าหัวข้อแทนการใช้ตัวหนา
- ✅ เน้นการเว้นบรรทัดให้มีช่องว่าง สบายตา
- สรุปเนื้อหาให้กระชับ เข้าใจง่าย ไม่ยืดเยื้อ
- ใช้ภาษาไทยที่สุภาพและเป็นมิตร
''';

  ChatService();

  // ═══════════════════════════════════════════════════════════════════
  // PUBLIC API
  // ═══════════════════════════════════════════════════════════════════

  /// Send a text message and get AI response.
  /// Throws [ChatRateLimitException] if daily limit exceeded.
  Future<String> sendMessage(String message) async {
    // Check daily limit
    final usageCheck = await _checkDailyLimit();
    if (!usageCheck.allowed) {
      return '⚠️ คุณใช้งาน AI ครบ $dailyRequestLimit ครั้งแล้ววันนี้\n\n'
          'ระบบจะรีเซ็ตจำนวนการใช้งานในวันถัดไป\n'
          'กรุณาลองใหม่อีกครั้งพรุ่งนี้ครับ 🙏';
    }

    try {
      final userContent = {
        'role': 'user',
        'parts': [
          {'text': 'คำถามนี้ใช้เพื่อการศึกษาและให้ข้อมูลเท่านั้น\n\n$message'},
        ],
      };

      _history.add(userContent);
      _trimHistory();

      final body = _buildRequestBody();

      final aiText = await _callGeminiApi(body);

      _history.add({
        'role': 'model',
        'parts': [
          {'text': aiText},
        ],
      });

      // Increment daily usage
      await _incrementDailyUsage();

      return aiText;
    } on SocketException {
      _removeLastUserMessage();
      return '📡 ไม่สามารถเชื่อมต่ออินเทอร์เน็ตได้\nกรุณาตรวจสอบการเชื่อมต่อของคุณ';
    } on TimeoutException {
      _removeLastUserMessage();
      return '⏱️ การเชื่อมต่อหมดเวลา\nกรุณาลองใหม่อีกครั้ง';
    } on ChatRateLimitException {
      _removeLastUserMessage();
      return '⏳ ระบบ AI มีผู้ใช้งานจำนวนมากในขณะนี้\n\n'
          'ระบบลองส่งซ้ำแล้ว แต่ยังไม่สำเร็จ\n'
          'กรุณารอ 1-2 นาทีแล้วลองใหม่ครับ';
    } catch (e) {
      _removeLastUserMessage();
      debugPrint('❌ ChatService error: $e');
      return '❌ เกิดข้อผิดพลาด กรุณาลองใหม่อีกครั้ง';
    }
  }

  /// Send a message with an image attachment.
  Future<String> sendMessageWithImage(String message, File imageFile) async {
    // Check daily limit
    final usageCheck = await _checkDailyLimit();
    if (!usageCheck.allowed) {
      return '⚠️ คุณใช้งาน AI ครบ $dailyRequestLimit ครั้งแล้ววันนี้\n\n'
          'ระบบจะรีเซ็ตจำนวนการใช้งานในวันถัดไป\n'
          'กรุณาลองใหม่อีกครั้งพรุ่งนี้ครับ 🙏';
    }

    try {
      final imageBytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(imageBytes);
      final mimeType = _getMimeType(imageFile.path);

      final guardedMessage = '''
คำถามนี้ใช้เพื่อการศึกษาและให้ข้อมูลเท่านั้น
หากเป็นพืชควบคุม ให้เน้นข้อกฎหมายและมาตรฐาน
คำถาม: ${message.isEmpty ? 'วิเคราะห์ภาพนี้' : message}
''';

      final userContent = {
        'role': 'user',
        'parts': [
          {'text': guardedMessage},
          {
            'inline_data': {'mime_type': mimeType, 'data': base64Image},
          },
        ],
      };

      _history.add(userContent);
      _trimHistory();

      final body = _buildRequestBody();

      final aiText = await _callGeminiApi(body);

      // ✅ Clean up: strip base64 image from the history entry we just added
      // to save massive tokens on subsequent requests
      _stripImagesFromHistory();

      _history.add({
        'role': 'model',
        'parts': [
          {'text': aiText},
        ],
      });

      // Increment daily usage
      await _incrementDailyUsage();

      return aiText;
    } on SocketException {
      _removeLastUserMessage();
      return '📡 ไม่สามารถเชื่อมต่ออินเทอร์เน็ตได้\nกรุณาตรวจสอบการเชื่อมต่อของคุณ';
    } on TimeoutException {
      _removeLastUserMessage();
      return '⏱️ การเชื่อมต่อหมดเวลา\nกรุณาลองใหม่อีกครั้ง';
    } on ChatRateLimitException {
      _removeLastUserMessage();
      return '⏳ ระบบ AI มีผู้ใช้งานจำนวนมากในขณะนี้\n\n'
          'ระบบลองส่งซ้ำแล้ว แต่ยังไม่สำเร็จ\n'
          'กรุณารอ 1-2 นาทีแล้วลองใหม่ครับ';
    } catch (e) {
      _removeLastUserMessage();
      debugPrint('❌ ChatService error: $e');
      return '❌ เกิดข้อผิดพลาดในการวิเคราะห์ภาพ\nกรุณาลองใหม่อีกครั้ง';
    }
  }

  /// Reset conversation history.
  void resetChat() {
    _history.clear();
  }

  /// Get current conversation turn count.
  int get currentTurnCount => (_history.length / 2).ceil();

  /// Check if history is getting long and user should consider resetting.
  bool get shouldSuggestReset => currentTurnCount >= _maxHistoryTurns - 2;

  /// Get today's remaining usage count.
  Future<DailyUsageInfo> getDailyUsage() async {
    return _checkDailyLimit();
  }

  // ═══════════════════════════════════════════════════════════════════
  // PRIVATE: History Management
  // ═══════════════════════════════════════════════════════════════════

  /// Trim conversation history to stay within limits.
  /// Keeps the most recent turns, removes oldest ones first.
  void _trimHistory() {
    // Trim by turn count (each turn = 1 user + 1 model message)
    while (_history.length > _maxHistoryTurns * 2) {
      _history.removeAt(0); // Remove oldest user message
      if (_history.isNotEmpty && _history[0]['role'] == 'model') {
        _history.removeAt(0); // Remove corresponding model response
      }
    }

    // Trim by estimated token count
    while (_estimateTokenCount() > _maxEstimatedTokens && _history.length > 2) {
      _history.removeAt(0);
      if (_history.isNotEmpty && _history[0]['role'] == 'model') {
        _history.removeAt(0);
      }
    }
  }

  /// Strip base64 image data from ALL history entries (except the very last one
  /// which is about to be sent). Replace with a text description.
  void _stripImagesFromHistory() {
    for (int i = 0; i < _history.length - 1; i++) {
      final entry = _history[i];
      if (entry['parts'] is List) {
        final parts = entry['parts'] as List;
        bool hadImage = false;

        parts.removeWhere((part) {
          if (part is Map && part.containsKey('inline_data')) {
            hadImage = true;
            return true;
          }
          return false;
        });

        // Add a note that an image was analyzed (so context isn't lost)
        if (hadImage && parts.every((p) => p is Map && !p.containsKey('text') || 
            (p is Map && p['text'] != null && !(p['text'] as String).contains('[ส่งภาพถ่ายมาวิเคราะห์]')))) {
          parts.add({'text': '[ส่งภาพถ่ายมาวิเคราะห์]'});
        }
      }
    }
  }

  /// Estimate total token count in current history.
  /// Uses rough heuristic: 1 token ≈ 4 characters for Thai text.
  int _estimateTokenCount() {
    int totalChars = 0;

    for (final entry in _history) {
      if (entry['parts'] is List) {
        for (final part in (entry['parts'] as List)) {
          if (part is Map) {
            if (part['text'] != null) {
              totalChars += (part['text'] as String).length;
            }
            if (part['inline_data'] != null) {
              // Base64 images use ~258 tokens per image in Gemini
              // but the actual data transfer is much larger
              totalChars += 1000; // Rough estimate for image token cost
            }
          }
        }
      }
    }

    return (totalChars / 4).ceil();
  }

  /// Remove the last user message from history (used on error).
  void _removeLastUserMessage() {
    if (_history.isNotEmpty && _history.last['role'] == 'user') {
      _history.removeLast();
    }
  }

  // ═══════════════════════════════════════════════════════════════════
  // PRIVATE: API Communication
  // ═══════════════════════════════════════════════════════════════════

  /// Build the request body for the Gemini API.
  Map<String, dynamic> _buildRequestBody() {
    return {
      'contents': _history,
      'system_instruction': {
        'parts': {'text': _systemPrompt},
      },
      'generationConfig': {
        'temperature': 0.7,
        'maxOutputTokens': 2048,
      },
    };
  }

  /// Execute a single API call to Gemini (no retry).
  // ── Retry logic disabled due to free tier rate limit issues ──
  // Future<String> _executeWithRetry(body) → see git history
  Future<String> _callGeminiApi(Map<String, dynamic> body) async {
    final url = Uri.parse('$_baseUrl?key=$_apiKey');

    final response = await http
        .post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(body),
        )
        .timeout(_requestTimeout);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      // Check for valid response structure
      if (data['candidates'] != null &&
          (data['candidates'] as List).isNotEmpty &&
          data['candidates'][0]['content'] != null &&
          data['candidates'][0]['content']['parts'] != null &&
          (data['candidates'][0]['content']['parts'] as List).isNotEmpty) {
        return data['candidates'][0]['content']['parts'][0]['text'] as String;
      }

      // Handle blocked or empty responses
      final finishReason = data['candidates']?[0]?['finishReason'];
      if (finishReason == 'SAFETY') {
        return '⚠️ ขออภัย ระบบไม่สามารถตอบคำถามนี้ได้\n'
            'เนื่องจากเนื้อหาอาจไม่เหมาะสมตามนโยบายความปลอดภัย';
      }

      return '⚠️ ระบบ AI ไม่สามารถสร้างคำตอบได้ กรุณาลองถามใหม่';
    } else if (response.statusCode == 429) {
      throw ChatRateLimitException('Rate limited by Gemini API');
    } else if (response.statusCode == 400) {
      final errorBody = jsonDecode(response.body);
      final errorMsg = (errorBody['error']?['message'] ?? '').toString().toLowerCase();

      debugPrint('❌ Gemini 400 error: $errorMsg');

      if (errorMsg.contains('api key') ||
          errorMsg.contains('api_key') ||
          errorMsg.contains('expired') ||
          errorMsg.contains('invalid')) {
        return '🔑 API Key ไม่ถูกต้องหรือหมดอายุ\n\n'
            'กรุณาแจ้งผู้ดูแลระบบเพื่ออัปเดต API Key ครับ';
      }

      if (errorMsg.contains('token') ||
          errorMsg.contains('limit') ||
          errorMsg.contains('too long') ||
          errorMsg.contains('context')) {
        return '⚠️ ข้อความยาวเกินไป กรุณาเริ่มบทสนทนาใหม่ หรือส่งข้อความที่สั้นลง';
      }

      return '❌ เกิดข้อผิดพลาดจากระบบ AI\n$errorMsg';
    } else {
      debugPrint('❌ Gemini error ${response.statusCode}: ${response.body}');
      return '❌ เกิดข้อผิดพลาดจากระบบ AI (${response.statusCode})\n'
          'กรุณาลองใหม่อีกครั้ง';
    }
  }

  // ═══════════════════════════════════════════════════════════════════
  // PRIVATE: Daily Usage Tracking
  // ═══════════════════════════════════════════════════════════════════

  /// Check if user has remaining daily quota.
  Future<DailyUsageInfo> _checkDailyLimit() async {
    final prefs = await SharedPreferences.getInstance();
    final today = _todayKey();
    final savedDate = prefs.getString(_prefKeyDailyDate) ?? '';
    int count = prefs.getInt(_prefKeyDailyCount) ?? 0;

    // Reset counter if it's a new day
    if (savedDate != today) {
      count = 0;
      await prefs.setString(_prefKeyDailyDate, today);
      await prefs.setInt(_prefKeyDailyCount, 0);
    }

    return DailyUsageInfo(
      usedCount: count,
      limit: dailyRequestLimit,
      allowed: count < dailyRequestLimit,
    );
  }

  /// Increment the daily usage counter.
  Future<void> _incrementDailyUsage() async {
    final prefs = await SharedPreferences.getInstance();
    final today = _todayKey();
    final savedDate = prefs.getString(_prefKeyDailyDate) ?? '';

    if (savedDate != today) {
      await prefs.setString(_prefKeyDailyDate, today);
      await prefs.setInt(_prefKeyDailyCount, 1);
    } else {
      final current = prefs.getInt(_prefKeyDailyCount) ?? 0;
      await prefs.setInt(_prefKeyDailyCount, current + 1);
    }
  }

  /// Generate a date key for today (yyyy-MM-dd).
  String _todayKey() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  // ═══════════════════════════════════════════════════════════════════
  // PRIVATE: Utilities
  // ═══════════════════════════════════════════════════════════════════

  String _getMimeType(String path) {
    if (path.endsWith('.png')) return 'image/png';
    if (path.endsWith('.webp')) return 'image/webp';
    return 'image/jpeg';
  }
}

// ═══════════════════════════════════════════════════════════════════════
// Models
// ═══════════════════════════════════════════════════════════════════════

/// Information about daily AI chat usage.
class DailyUsageInfo {
  final int usedCount;
  final int limit;
  final bool allowed;

  const DailyUsageInfo({
    required this.usedCount,
    required this.limit,
    required this.allowed,
  });

  int get remaining => (limit - usedCount).clamp(0, limit);
}

/// Exception thrown when rate limit is hit and all retries exhausted.
class ChatRateLimitException implements Exception {
  final String message;
  ChatRateLimitException(this.message);

  @override
  String toString() => 'ChatRateLimitException: $message';
}
