import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/env.dart';
import '../network/api_client.dart';

/// Ask Lung Tom. Questions go to the TAPTOM API (`POST /assistant/chat`),
/// which holds the Gemini key and the system prompt, so no AI credentials
/// ship inside the app.
///
/// Keeps the recent conversation for context, drops photos from older turns
/// to keep requests small, and counts questions per day on the device. When
/// the server has no assistant configured, or in demo builds, answers come
/// from built-in samples instead.
class ChatService {
  ChatService({ApiClient? api}) : _api = api ?? ApiClient();

  final ApiClient _api;

  /// Questions per day on this device. The server rate-limits as well.
  static const int dailyRequestLimit = 50;

  /// Turns sent with each question. The API accepts at most 20 messages.
  static const int _maxHistoryMessages = 18;

  /// Gemini can take a while, especially with a photo.
  static const Duration _timeout = Duration(seconds: 45);

  static const String _prefKeyDailyCount = 'chat_daily_request_count';
  static const String _prefKeyDailyDate = 'chat_daily_date';

  /// Set once the server answers that the assistant is not configured.
  static bool _unavailable = false;

  /// True when answers come from the built-in samples: in demo builds, or
  /// when the server has no assistant configured.
  static bool get offline => Env.demoMode || _unavailable;

  final List<Map<String, dynamic>> _history = [];

  /// Asks a question, optionally with a photo of the plant. Always returns
  /// text to show; failures become a short Thai explanation.
  Future<String> ask(String question, {Uint8List? imageBytes, String? imageName}) async {
    final usage = await getDailyUsage();
    if (!usage.allowed) {
      return 'วันนี้ถามครบ $dailyRequestLimit คำถามแล้ว พรุ่งนี้มาถามลุงต้อมใหม่นะ';
    }

    final text = question.trim().isEmpty ? 'ช่วยดูภาพนี้ให้หน่อย' : question.trim();
    final turn = <String, dynamic>{
      'role': 'user',
      'text': text,
      if (imageBytes != null) 'image': {'mimeType': _mimeType(imageName ?? ''), 'data': base64Encode(imageBytes)},
    };
    final messages = [..._history, turn];

    String answer;
    if (offline) {
      answer = await _sampleAnswer(text, hasImage: imageBytes != null);
    } else {
      try {
        answer = await _send(messages);
      } on _Unavailable {
        _unavailable = true;
        answer = await _sampleAnswer(text, hasImage: imageBytes != null);
      } on ApiException catch (e) {
        return _explain(e);
      }
    }

    // Keep the question without its photo; the answer already describes it.
    _history
      ..add({'role': 'user', 'text': imageBytes == null ? text : '$text\n[แนบภาพถ่ายพืช]'})
      ..add({'role': 'model', 'text': answer});
    while (_history.length > _maxHistoryMessages) {
      _history.removeRange(0, 2);
    }
    await _countUsage();
    return answer;
  }

  /// Starts a new conversation.
  void resetChat() => _history.clear();

  int get currentTurnCount => _history.length ~/ 2;

  Future<String> _send(List<Map<String, dynamic>> messages) async {
    try {
      final response = await _api.post(
        '/assistant/chat',
        data: {'messages': messages},
        options: Options(sendTimeout: _timeout, receiveTimeout: _timeout),
      );
      final body = response.data;
      final map = body is Map && body['data'] is Map ? body['data'] as Map : body as Map? ?? const {};
      if (map['blocked'] == true) {
        return 'ลุงต้อมตอบคำถามนี้ไม่ได้ ลองถามเรื่องการปลูก การดูแล หรือมาตรฐาน GAP ดูนะ';
      }
      final text = '${map['text'] ?? ''}'.trim();
      return text.isEmpty ? 'ลุงต้อมยังคิดคำตอบไม่ออก ลองถามใหม่อีกครั้งนะ' : text;
    } on ApiException catch (e) {
      if (e.statusCode == 503) throw const _Unavailable();
      rethrow;
    }
  }

  String _explain(ApiException e) {
    if (e.isNetwork) return 'ยังเชื่อมต่ออินเทอร์เน็ตไม่ได้ ลองใหม่เมื่อสัญญาณดีขึ้นนะ';
    if (e.statusCode == 429) return 'ตอนนี้มีคนถามลุงต้อมเยอะ รอสักครู่แล้วลองใหม่นะ';
    if (e.statusCode == 413 || e.statusCode == 400) {
      return 'ข้อความหรือรูปใหญ่เกินไป ลองส่งรูปที่เล็กลงหรือเริ่มบทสนทนาใหม่';
    }
    debugPrint('Assistant error ${e.statusCode}: ${e.serverMessage ?? e.message}');
    return 'ตอนนี้ลุงต้อมตอบไม่ได้ ลองใหม่อีกครั้งในอีกสักครู่';
  }

  // Daily usage ---------------------------------------------------------------

  Future<DailyUsageInfo> getDailyUsage() async {
    final prefs = await SharedPreferences.getInstance();
    final count = prefs.getString(_prefKeyDailyDate) == _today() ? prefs.getInt(_prefKeyDailyCount) ?? 0 : 0;
    return DailyUsageInfo(usedCount: count, limit: dailyRequestLimit, allowed: count < dailyRequestLimit);
  }

  Future<void> _countUsage() async {
    final prefs = await SharedPreferences.getInstance();
    final today = _today();
    final count = prefs.getString(_prefKeyDailyDate) == today ? prefs.getInt(_prefKeyDailyCount) ?? 0 : 0;
    await prefs.setString(_prefKeyDailyDate, today);
    await prefs.setInt(_prefKeyDailyCount, count + 1);
  }

  String _today() => DateTime.now().toIso8601String().substring(0, 10);

  String _mimeType(String name) {
    final lower = name.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    return 'image/jpeg';
  }

  // Sample answers --------------------------------------------------------------

  /// Canned answers for demos, matched on keywords in the question.
  Future<String> _sampleAnswer(String question, {required bool hasImage}) async {
    await Future<void>.delayed(const Duration(milliseconds: 900));
    if (hasImage) {
      return 'จากภาพ ใบมีจุดสีน้ำตาลขอบเหลืองกระจายตามแผ่นใบ ลักษณะคล้ายโรคใบจุดจากเชื้อรา\n\n'
          '- ตัดใบที่เป็นโรคออกแล้วนำไปทำลายนอกแปลง\n'
          '- ลดความชื้นใต้ทรงพุ่มด้วยการตัดแต่งกิ่งให้โปร่ง\n'
          '- ฉีดพ่นเชื้อราไตรโคเดอร์มาทุก 7 ถึง 10 วัน\n\n'
          'บันทึกการจัดการนี้ในหมวด 1.3 เพื่อใช้ประกอบการตรวจ GAP';
    }
    if (question.contains('GAP') || question.contains('ขั้นตอน')) {
      return 'การขอรับรอง GAP ในแอปมี 4 ขั้นตอน\n\n'
          '- วาดขอบเขตแปลงบนแผนที่\n'
          '- บันทึกข้อมูลให้ครบ 7 หมวด ตั้งแต่ข้อมูลทั่วไปจนถึงการตรวจสอบย้อนกลับ\n'
          '- เจ้าหน้าที่ในพื้นที่ตรวจข้อมูลและอาจนัดตรวจแปลง\n'
          '- เมื่ออนุมัติ ดาวน์โหลดใบรับรองได้ที่หน้าแปลง';
    }
    if (question.contains('ปุ๋ย')) {
      return 'กระท่อมชอบดินร่วนที่มีอินทรียวัตถุสูง\n\n'
          '- ใส่ปุ๋ยคอกหรือปุ๋ยหมักต้นละ 2 ถึง 3 กก. ช่วงต้นฤดูฝน\n'
          '- เสริมปุ๋ยสูตรเสมอ 15-15-15 ปีละ 2 ครั้ง ครั้งละ 100 ถึง 200 กรัมต่อต้น\n'
          '- เว้นการใส่ปุ๋ยเคมีอย่างน้อย 15 วันก่อนเก็บใบ\n\n'
          'อย่าลืมบันทึกการใช้ปุ๋ยทุกครั้งในหมวด 1.2';
    }
    if (question.contains('กี่ต้น') || question.contains('กฎหมาย')) {
      return 'ตั้งแต่ปี 2565 พืชกระท่อมไม่เป็นยาเสพติดตามกฎหมายแล้ว ปลูกได้โดยไม่จำกัดจำนวนต้น\n\n'
          'ข้อควรระวัง\n'
          '- ห้ามขายให้ผู้ที่อายุต่ำกว่า 18 ปี สตรีมีครรภ์ และสตรีให้นมบุตร\n'
          '- การนำเข้าหรือส่งออกต้องขออนุญาตตามพระราชบัญญัติพืชกระท่อม\n\n'
          'ข้อมูลนี้เป็นความรู้ทั่วไป ควรตรวจสอบประกาศล่าสุดกับสำนักงานเกษตรอำเภอ';
    }
    return 'ลุงต้อมยังตอบเรื่องนี้ได้ไม่ละเอียดนัก ลองถามเรื่องการปลูก การดูแล การเก็บเกี่ยว หรือมาตรฐาน GAP ดูนะ\n\n'
        'ถ้าเป็นเรื่องเฉพาะแปลงของคุณ ปรึกษาเจ้าหน้าที่ในพื้นที่ได้จากเมนูติดต่อเจ้าหน้าที่';
  }
}

class _Unavailable implements Exception {
  const _Unavailable();
}

/// Today's question count on this device.
class DailyUsageInfo {
  const DailyUsageInfo({required this.usedCount, required this.limit, required this.allowed});

  final int usedCount;
  final int limit;
  final bool allowed;

  int get remaining => (limit - usedCount).clamp(0, limit);
}
