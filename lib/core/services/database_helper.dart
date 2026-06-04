import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../../data/models/gap_draft_model.dart';
import '../../data/models/chat_message.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('taptom_gap.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 2,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future _createDB(Database db, int version) async {
    // V1 Tables
    await db.execute('''
      CREATE TABLE drafts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        category TEXT NOT NULL,
        jsonData TEXT NOT NULL,
        lastUpdated TEXT NOT NULL
      )
    ''');

    // V2 Tables
    await _createChatTable(db);
  }

  Future _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await _createChatTable(db);
    }
  }

  Future _createChatTable(Database db) async {
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

  // --- Drafts Accessors ---

  Future<int> insertDraft(GapDraftModel draft) async {
    final db = await instance.database;
    return await db.insert('drafts', draft.toMap());
  }

  Future<void> saveDraft(String category, String json) async {
    final db = await instance.database;
    final exists = await db.query(
      'drafts',
      where: 'category = ?',
      whereArgs: [category],
    );

    final draft = GapDraftModel(
      category: category,
      jsonData: json,
      lastUpdated: DateTime.now().toIso8601String(),
    );

    if (exists.isNotEmpty) {
      await db.update(
        'drafts',
        draft.toMap(),
        where: 'category = ?',
        whereArgs: [category],
      );
    } else {
      await db.insert('drafts', draft.toMap());
    }
  }

  Future<GapDraftModel?> getDraft(String category) async {
    final db = await instance.database;
    final maps = await db.query(
      'drafts',
      columns: ['id', 'category', 'jsonData', 'lastUpdated'],
      where: 'category = ?',
      whereArgs: [category],
    );

    if (maps.isNotEmpty) {
      return GapDraftModel.fromMap(maps.first);
    } else {
      return null;
    }
  }

  Future<List<GapDraftModel>> getAllDrafts() async {
    final db = await instance.database;
    final result = await db.query('drafts');
    return result.map((json) => GapDraftModel.fromMap(json)).toList();
  }

  Future<int> deleteDraft(String category) async {
    final db = await instance.database;
    return await db.delete(
      'drafts',
      where: 'category = ?',
      whereArgs: [category],
    );
  }

  // --- Chat Persistence Accessors ---

  Future<void> saveMessage(ChatMessage message) async {
    final db = await instance.database;
    await db.insert(
      'chat_messages',
      message.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<ChatMessage>> getChatHistory() async {
    final db = await instance.database;
    final result = await db.query('chat_messages', orderBy: 'timestamp ASC');
    return result.map((json) => ChatMessage.fromMap(json)).toList();
  }

  Future<void> clearChatHistory() async {
    final db = await instance.database;
    await db.delete('chat_messages');
  }
}
