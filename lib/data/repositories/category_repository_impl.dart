import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import '../../core/constants/default_dhikr.dart';
import '../../domain/entities/dhikr_category.dart';
import '../../domain/repositories/category_repository.dart';
import '../datasources/app_database.dart';
import '../models/category_mapper.dart';

class CategoryRepositoryImpl implements CategoryRepository {
  CategoryRepositoryImpl(this._db, {Uuid? uuid}) : _uuid = uuid ?? const Uuid();

  final AppDatabase _db;
  final Uuid _uuid;

  @override
  Future<List<DhikrCategory>> getCategories(
      {bool includeArchived = false}) async {
    final db = await _db.database;
    final rows = await db.query(
      'categories',
      where: includeArchived ? null : 'is_archived = 0',
      orderBy: 'sort_order ASC, created_at ASC',
    );
    return rows.map(CategoryMapper.fromRow).toList();
  }

  @override
  Future<DhikrCategory?> getCategory(String id) async {
    final db = await _db.database;
    final rows =
        await db.query('categories', where: 'id = ?', whereArgs: [id], limit: 1);
    if (rows.isEmpty) return null;
    return CategoryMapper.fromRow(rows.first);
  }

  @override
  Future<DhikrCategory> createCategory({
    required String name,
    String? arabic,
    String? transliteration,
    String? description,
    required int colorValue,
    required int iconCodePoint,
    int? dailyTarget,
  }) async {
    final db = await _db.database;
    final maxOrder = await _maxSortOrder();
    final category = DhikrCategory(
      id: _uuid.v4(),
      name: name.trim(),
      arabic: arabic?.trim().isEmpty ?? true ? null : arabic!.trim(),
      transliteration:
          transliteration?.trim().isEmpty ?? true ? null : transliteration!.trim(),
      description:
          description?.trim().isEmpty ?? true ? null : description!.trim(),
      colorValue: colorValue,
      iconCodePoint: iconCodePoint,
      dailyTarget: (dailyTarget != null && dailyTarget > 0) ? dailyTarget : null,
      lifetimeCount: 0,
      sortOrder: maxOrder + 1,
      createdAt: DateTime.now(),
    );
    await db.insert('categories', CategoryMapper.toRow(category));
    return category;
  }

  @override
  Future<void> updateCategory(DhikrCategory category) async {
    final db = await _db.database;
    await db.update(
      'categories',
      CategoryMapper.toRow(category),
      where: 'id = ?',
      whereArgs: [category.id],
    );
  }

  @override
  Future<void> deleteCategory(String id) async {
    final db = await _db.database;
    // daily_records & sessions cascade via FK.
    await db.delete('categories', where: 'id = ?', whereArgs: [id]);
  }

  @override
  Future<void> reorderCategories(List<String> orderedIds) async {
    final db = await _db.database;
    await db.transaction((txn) async {
      for (var i = 0; i < orderedIds.length; i++) {
        await txn.update(
          'categories',
          {'sort_order': i},
          where: 'id = ?',
          whereArgs: [orderedIds[i]],
        );
      }
    });
  }

  @override
  Future<bool> seedDefaultsIfEmpty() async {
    final db = await _db.database;
    final count = Sqflite.firstIntValue(
            await db.rawQuery('SELECT COUNT(*) FROM categories')) ??
        0;
    if (count > 0) return false;

    await db.transaction((txn) async {
      var order = 0;
      for (final d in DefaultDhikr.all) {
        final category = DhikrCategory(
          id: _uuid.v4(),
          name: d.name,
          arabic: d.arabic,
          transliteration: d.transliteration,
          description: d.description,
          colorValue: d.color.toARGB32(),
          iconCodePoint: d.iconCodePoint,
          dailyTarget: d.target,
          lifetimeCount: 0,
          sortOrder: order++,
          createdAt: DateTime.now(),
        );
        await txn.insert('categories', CategoryMapper.toRow(category));
      }
    });
    return true;
  }

  Future<int> _maxSortOrder() async {
    final db = await _db.database;
    final result =
        await db.rawQuery('SELECT MAX(sort_order) AS m FROM categories');
    return (result.first['m'] as int?) ?? -1;
  }
}
