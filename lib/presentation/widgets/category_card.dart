import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/di/providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../domain/entities/dhikr_category.dart';
import '../providers/analytics_providers.dart';
import 'app_card.dart';
import 'progress_ring.dart';

/// A tappable card summarizing one category with today's progress.
class CategoryCard extends ConsumerWidget {
  const CategoryCard({
    super.key,
    required this.category,
    required this.todayCount,
    this.onTap,
  });

  final DhikrCategory category;
  final int todayCount;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = category.color;
    final hasTarget = category.hasTarget;
    final progress = hasTarget ? todayCount / category.dailyTarget! : 0.0;

    return AppCard(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(category.icon, color: color),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  category.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.text.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(
                  hasTarget
                      ? '$todayCount / ${category.dailyTarget} today'
                      : '$todayCount today',
                  style: context.text.bodySmall
                      ?.copyWith(color: context.extras.textSecondary),
                ),
                const SizedBox(height: 2),
                Text(
                  '${Formatters.compact(category.lifetimeCount)} lifetime',
                  style: context.text.labelSmall?.copyWith(color: color),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (hasTarget)
            ProgressRing(
              progress: progress,
              size: 46,
              strokeWidth: 5,
              color: color,
              center: Text(
                Formatters.percent(progress),
                style: context.text.labelSmall
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
            )
          else
            Icon(Icons.chevron_right_rounded,
                color: context.extras.textSecondary),
        ],
      ),
    );
  }
}

/// Convenience provider: today's count for a category, used by cards.
final categoryTodayCountProvider =
    FutureProvider.autoDispose.family<int, String>((ref, categoryId) async {
  // Re-run when global today total changes (e.g. after counting).
  ref.watch(todayTotalProvider);
  return ref.watch(dhikrRepositoryProvider).todayCount(categoryId);
});
