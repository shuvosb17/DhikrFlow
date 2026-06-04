import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/di/providers.dart';
import '../../domain/entities/dhikr_category.dart';

/// Loads and manages the list of (non-archived) dhikr categories.
class CategoriesNotifier extends AsyncNotifier<List<DhikrCategory>> {
  @override
  Future<List<DhikrCategory>> build() async {
    final repo = ref.watch(categoryRepositoryProvider);
    await repo.seedDefaultsIfEmpty();
    return repo.getCategories();
  }

  Future<void> refresh() async {
    final repo = ref.read(categoryRepositoryProvider);
    state = AsyncData(await repo.getCategories());
  }

  Future<DhikrCategory> create({
    required String name,
    String? arabic,
    String? transliteration,
    String? description,
    required int colorValue,
    required int iconCodePoint,
    int? dailyTarget,
  }) async {
    final repo = ref.read(categoryRepositoryProvider);
    final created = await repo.createCategory(
      name: name,
      arabic: arabic,
      transliteration: transliteration,
      description: description,
      colorValue: colorValue,
      iconCodePoint: iconCodePoint,
      dailyTarget: dailyTarget,
    );
    await refresh();
    return created;
  }

  Future<void> update(DhikrCategory category) async {
    final repo = ref.read(categoryRepositoryProvider);
    await repo.updateCategory(category);
    await refresh();
  }

  Future<void> delete(String id) async {
    final repo = ref.read(categoryRepositoryProvider);
    await repo.deleteCategory(id);
    await refresh();
  }

  Future<void> reorder(int oldIndex, int newIndex) async {
    final current = state.valueOrNull;
    if (current == null) return;
    final list = [...current];
    if (newIndex > oldIndex) newIndex -= 1;
    final item = list.removeAt(oldIndex);
    list.insert(newIndex, item);
    state = AsyncData(list);
    final repo = ref.read(categoryRepositoryProvider);
    await repo.reorderCategories(list.map((c) => c.id).toList());
  }
}

final categoriesProvider =
    AsyncNotifierProvider<CategoriesNotifier, List<DhikrCategory>>(
  CategoriesNotifier.new,
);

/// Single category lookup by id (depends on [categoriesProvider]).
final categoryByIdProvider =
    Provider.family<DhikrCategory?, String>((ref, id) {
  final list = ref.watch(categoriesProvider).valueOrNull ?? const [];
  for (final c in list) {
    if (c.id == id) return c;
  }
  return null;
});
