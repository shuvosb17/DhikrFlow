import '../entities/dhikr_category.dart';

/// Contract for managing dhikr categories.
abstract interface class CategoryRepository {
  Future<List<DhikrCategory>> getCategories({bool includeArchived = false});

  Future<DhikrCategory?> getCategory(String id);

  Future<DhikrCategory> createCategory({
    required String name,
    String? arabic,
    String? transliteration,
    String? description,
    required int colorValue,
    required int iconCodePoint,
    int? dailyTarget,
  });

  Future<void> updateCategory(DhikrCategory category);

  Future<void> deleteCategory(String id);

  Future<void> reorderCategories(List<String> orderedIds);

  /// Seeds the default dhikr set if the table is empty. Returns true if seeded.
  Future<bool> seedDefaultsIfEmpty();
}
