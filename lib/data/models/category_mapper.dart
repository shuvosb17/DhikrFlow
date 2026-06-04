import '../../domain/entities/dhikr_category.dart';

/// Maps between `categories` table rows and [DhikrCategory] entities.
class CategoryMapper {
  CategoryMapper._();

  static DhikrCategory fromRow(Map<String, Object?> row) {
    return DhikrCategory(
      id: row['id'] as String,
      name: row['name'] as String,
      arabic: row['arabic'] as String?,
      transliteration: row['transliteration'] as String?,
      description: row['description'] as String?,
      colorValue: row['color'] as int,
      iconCodePoint: row['icon'] as int,
      dailyTarget: row['daily_target'] as int?,
      lifetimeCount: (row['lifetime_count'] as int?) ?? 0,
      sortOrder: (row['sort_order'] as int?) ?? 0,
      isArchived: ((row['is_archived'] as int?) ?? 0) == 1,
      createdAt:
          DateTime.fromMillisecondsSinceEpoch(row['created_at'] as int),
    );
  }

  static Map<String, Object?> toRow(DhikrCategory c) {
    return {
      'id': c.id,
      'name': c.name,
      'arabic': c.arabic,
      'transliteration': c.transliteration,
      'description': c.description,
      'color': c.colorValue,
      'icon': c.iconCodePoint,
      'daily_target': c.dailyTarget,
      'lifetime_count': c.lifetimeCount,
      'sort_order': c.sortOrder,
      'is_archived': c.isArchived ? 1 : 0,
      'created_at': c.createdAt.millisecondsSinceEpoch,
    };
  }
}
