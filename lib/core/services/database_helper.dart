import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

import '../../data/models/chat_message.dart';
import '../../data/models/gap_draft_model.dart';

/// Local storage for GAP drafts and assistant chat history, so farmers can
/// keep working where the signal is poor.
///
/// Uses SQLite on mobile and desktop. On the web, where sqflite is not
/// available, the same API is backed by SharedPreferences.
class DatabaseHelper {
  DatabaseHelper._init();

  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  static const _webDraftsKey = 'drafts_v1';
  static const _webChatKey = 'chat_v1';

  Future<Database> get database async {
    return _database ??= await _initDB('taptom_gap.db');
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    return openDatabase(
      join(dbPath, filePath),
      version: 2,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE drafts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        category TEXT NOT NULL,
        jsonData TEXT NOT NULL,
        lastUpdated TEXT NOT NULL
      )
    ''');
    await _createChatTable(db);
  }

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) await _createChatTable(db);
  }

  Future<void> _createChatTable(Database db) async {
    await db.execute('''
      CREATE TABLE chat_messages (
        id TEXT PRIMARY KEY,
        content TEXT NOT NULL,
        imagePath TEXT,
        isUser INTEGER NOT NULL,
        timestamp TEXT NOT NULL
      )
    ''');
  }

  // Web fallback ------------------------------------------------------------

  Future<Map<String, GapDraftModel>> _webDrafts() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_webDraftsKey);
    if (raw == null) return {};
    final map = Map<String, dynamic>.from(jsonDecode(raw) as Map);
    return map.map(
      (k, v) => MapEntry(k, GapDraftModel.fromMap(Map<String, dynamic>.from(v))),
    );
  }

  Future<void> _saveWebDrafts(Map<String, GapDraftModel> drafts) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _webDraftsKey,
      jsonEncode(drafts.map((k, v) => MapEntry(k, v.toMap()))),
    );
  }

  // Drafts ------------------------------------------------------------------

  Future<int> insertDraft(GapDraftModel draft) async {
    if (kIsWeb) {
      await saveDraft(draft.category, draft.jsonData);
      return 1;
    }
    final db = await database;
    return db.insert('drafts', draft.toMap());
  }

  /// Saves or replaces the draft stored under [category]
  /// (`<form>_<plotId>`).
  Future<void> saveDraft(String category, String json) async {
    final draft = GapDraftModel(
      category: category,
      jsonData: json,
      lastUpdated: DateTime.now().toIso8601String(),
    );
    if (kIsWeb) {
      final drafts = await _webDrafts();
      drafts[category] = draft;
      await _saveWebDrafts(drafts);
      return;
    }
    final db = await database;
    final updated = await db.update(
      'drafts',
      draft.toMap()..remove('id'),
      where: 'category = ?',
      whereArgs: [category],
    );
    if (updated == 0) await db.insert('drafts', draft.toMap()..remove('id'));
  }

  Future<GapDraftModel?> getDraft(String category) async {
    if (kIsWeb) return (await _webDrafts())[category];
    final db = await database;
    final rows = await db.query(
      'drafts',
      where: 'category = ?',
      whereArgs: [category],
      limit: 1,
    );
    return rows.isEmpty ? null : GapDraftModel.fromMap(rows.first);
  }

  Future<List<GapDraftModel>> getAllDrafts() async {
    if (kIsWeb) return (await _webDrafts()).values.toList();
    final db = await database;
    final rows = await db.query('drafts', orderBy: 'lastUpdated DESC');
    return rows.map(GapDraftModel.fromMap).toList();
  }

  /// Drafts that belong to [plotId].
  Future<List<GapDraftModel>> getDraftsForPlot(String plotId) async {
    final all = await getAllDrafts();
    return all.where((d) => d.category.endsWith('_$plotId')).toList();
  }

  Future<int> deleteDraft(String category) async {
    if (kIsWeb) {
      final drafts = await _webDrafts();
      final removed = drafts.remove(category) != null;
      await _saveWebDrafts(drafts);
      return removed ? 1 : 0;
    }
    final db = await database;
    return db.delete('drafts', where: 'category = ?', whereArgs: [category]);
  }

  // Chat --------------------------------------------------------------------

  Future<void> saveMessage(ChatMessage message) async {
    if (kIsWeb) {
      final history = await getChatHistory();
      history.add(message);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _webChatKey,
        jsonEncode(history.map((m) => m.toMap()).toList()),
      );
      return;
    }
    final db = await database;
    await db.insert(
      'chat_messages',
      message.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<ChatMessage>> getChatHistory() async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_webChatKey);
      if (raw == null) return [];
      return (jsonDecode(raw) as List)
          .map((m) => ChatMessage.fromMap(Map<String, dynamic>.from(m)))
          .toList();
    }
    final db = await database;
    final rows = await db.query('chat_messages', orderBy: 'timestamp ASC');
    return rows.map(ChatMessage.fromMap).toList();
  }

  Future<void> clearChatHistory() async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_webChatKey);
      return;
    }
    final db = await database;
    await db.delete('chat_messages');
  }
}
