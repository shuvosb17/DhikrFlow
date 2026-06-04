import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../providers/category_providers.dart';
import '../../widgets/empty_state.dart';

class ReorderCategoriesScreen extends ConsumerWidget {
  const ReorderCategoriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(categoriesProvider).valueOrNull ?? const [];

    return Scaffold(
      appBar: AppBar(title: const Text('Reorder categories')),
      body: categories.isEmpty
          ? const EmptyState(
              icon: Icons.reorder_rounded,
              title: 'No categories to reorder',
            )
          : ReorderableListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: categories.length,
              onReorder: (oldIndex, newIndex) => ref
                  .read(categoriesProvider.notifier)
                  .reorder(oldIndex, newIndex),
              itemBuilder: (context, i) {
                final c = categories[i];
                return Card(
                  key: ValueKey(c.id),
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  child: ListTile(
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: c.color.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(c.icon, color: c.color),
                    ),
                    title: Text(c.name),
                    subtitle: c.hasTarget
                        ? Text('Target ${c.dailyTarget}/day')
                        : null,
                    trailing: ReorderableDragStartListener(
                      index: i,
                      child: Icon(Icons.drag_handle_rounded,
                          color: context.extras.textSecondary),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
