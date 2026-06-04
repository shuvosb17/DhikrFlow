import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../../core/constants/app_constants.dart';

/// Thin wrapper around [Database] that owns schema creation and migrations.
///
/// Schema:
///  - categories(id, name, arabic, transliteration, description, color,
///       icon, daily_target, lifetime_count, sort_order, is_archived, created_at)
///  - daily_records(id, category_id, day, count) UNIQUE(category_id, day)
///  - sessions(id, category_id, count, started_at, ended_at)
class AppDatabase {
  AppDatabase._();
  static final AppDatabase instance = AppDatabase._();

  Database? _db;

  Future<Database> get database async {
    return _db ??= await _open();
  }

  Future<Database> _open() async {
    final dir = await getDatabasesPath();
    final path = p.join(dir, AppConstants.dbName);
    return openDatabase(
      path,
      version: AppConstants.dbVersion,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE categories (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        arabic TEXT,
        transliteration TEXT,
        description TEXT,
        color INTEGER NOT NULL,
        icon INTEGER NOT NULL,
        daily_target INTEGER,
        lifetime_count INTEGER NOT NULL DEFAULT 0,
        sort_order INTEGER NOT NULL DEFAULT 0,
        is_archived INTEGER NOT NULL DEFAULT 0,
        created_at INTEGER NOT NULL
      );
    ''');

    await db.execute('''
      CREATE TABLE daily_records (
        id TEXT PRIMARY KEY,
        category_id TEXT NOT NULL,
        day TEXT NOT NULL,
        count INTEGER NOT NULL DEFAULT 0,
        UNIQUE(category_id, day),
        FOREIGN KEY (category_id) REFERENCES categories (id) ON DELETE CASCADE
      );
    ''');

    await db.execute('''
      CREATE TABLE sessions (
        id TEXT PRIMARY KEY,
        category_id TEXT NOT NULL,
        count INTEGER NOT NULL DEFAULT 0,
        started_at INTEGER NOT NULL,
        ended_at INTEGER,
        FOREIGN KEY (category_id) REFERENCES categories (id) ON DELETE CASCADE
      );
    ''');

    await db.execute(
        'CREATE INDEX idx_daily_day ON daily_records (day);');
    await db.execute(
        'CREATE INDEX idx_daily_category ON daily_records (category_id);');
    await db.execute(
        'CREATE INDEX idx_sessions_category ON sessions (category_id);');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Reserved for future schema migrations.
  }

  Future<void> close() async {
    await _db?.close();
    _db = null;
  }

  /// Removes all rows (used by restore / reset). Categories cascade to records.
  Future<void> clearAll() async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete('sessions');
      await txn.delete('daily_records');
      await txn.delete('categories');
    });
  }
}
