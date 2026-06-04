import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/date_helpers.dart';
import '../../../core/utils/formatters.dart';
import '../../providers/analytics_providers.dart';
import '../../providers/category_providers.dart';
import '../../widgets/app_card.dart';
import '../../widgets/category_card.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/section_header.dart';
import '../categories/category_form_screen.dart';
import '../counter/counter_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoriesProvider);

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(categoriesProvider);
            ref.invalidate(todayTotalProvider);
            ref.invalidate(streakInfoProvider);
          },
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: _Greeting()),
              const SliverPadding(
                padding: EdgeInsets.symmetric(horizontal: Gap.md),
                sliver: SliverToBoxAdapter(child: _DailySummaryCard()),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(Gap.md, Gap.lg, Gap.md, 0),
                sliver: SliverToBoxAdapter(
                  child: SectionHeader(
                    title: 'Your dhikr',
                    subtitle: 'Tap a category to start counting',
                    trailing: IconButton.filledTonal(
                      onPressed: () => _openForm(context),
                      icon: const Icon(Icons.add_rounded),
                      tooltip: 'New category',
                    ),
                  ),
                ),
              ),
              categoriesAsync.when(
                loading: () => const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (e, _) => SliverFillRemaining(
                  hasScrollBody: false,
                  child: EmptyState(
                    icon: Icons.error_outline_rounded,
                    title: 'Something went wrong',
                    message: '$e',
                  ),
                ),
                data: (categories) {
                  if (categories.isEmpty) {
                    return SliverFillRemaining(
                      hasScrollBody: false,
                      child: EmptyState(
                        icon: Icons.spa_outlined,
                        title: 'No categories yet',
                        message:
                            'Create your first dhikr to begin your journey.',
                        action: FilledButton.icon(
                          onPressed: () => _openForm(context),
                          icon: const Icon(Icons.add_rounded),
                          label: const Text('Add dhikr'),
                        ),
                      ),
                    );
                  }
                  return SliverPadding(
                    padding: const EdgeInsets.fromLTRB(
                        Gap.md, 0, Gap.md, Gap.xxl),
                    sliver: SliverList.separated(
                      itemCount: categories.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: Gap.sm),
                      itemBuilder: (context, i) {
                        final category = categories[i];
                        final todayCount = ref
                                .watch(categoryTodayCountProvider(category.id))
                                .valueOrNull ??
                            0;
                        return CategoryCard(
                          category: category,
                          todayCount: todayCount,
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) =>
                                  CounterScreen(categoryId: category.id),
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openForm(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const CategoryFormScreen()),
    );
  }
}

class _Greeting extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Good morning'
        : hour < 17
            ? 'Good afternoon'
            : 'Good evening';
    return Padding(
      padding: const EdgeInsets.fromLTRB(Gap.md, Gap.md, Gap.md, Gap.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            greeting,
            style: context.text.bodyMedium
                ?.copyWith(color: context.extras.textSecondary),
          ),
          const SizedBox(height: 2),
          Text(
            DateHelpers.readable(DateTime.now()),
            style:
                context.text.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

class _DailySummaryCard extends ConsumerWidget {
  const _DailySummaryCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final today = ref.watch(todayTotalProvider).valueOrNull ?? 0;
    final streak = ref.watch(streakInfoProvider).valueOrNull;

    return AppCard(
      padding: const EdgeInsets.all(Gap.lg),
      color: context.colors.primary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome_rounded,
                  color: Colors.white70, size: 18),
              const SizedBox(width: 8),
              Text(
                "Today's remembrance",
                style: context.text.labelLarge
                    ?.copyWith(color: Colors.white70),
              ),
            ],
          ),
          const SizedBox(height: Gap.sm),
          Text(
            Formatters.number(today),
            style: context.text.displaySmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            'total counts',
            style: context.text.bodySmall?.copyWith(color: Colors.white60),
          ),
          const SizedBox(height: Gap.md),
          const Divider(color: Colors.white24, height: 1),
          const SizedBox(height: Gap.md),
          Row(
            children: [
              Expanded(
                child: _MiniStat(
                  icon: Icons.local_fire_department_rounded,
                  label: 'Current streak',
                  value: Formatters.pluralize(
                      streak?.currentStreak ?? 0, 'day'),
                ),
              ),
              Container(width: 1, height: 32, color: Colors.white24),
              Expanded(
                child: _MiniStat(
                  icon: Icons.emoji_events_rounded,
                  label: 'Best streak',
                  value: Formatters.pluralize(
                      streak?.longestStreak ?? 0, 'day'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: const Color(0xFFE7C97A), size: 22),
        const SizedBox(height: 6),
        Text(
          value,
          style: context.text.titleMedium
              ?.copyWith(color: Colors.white, fontWeight: FontWeight.w700),
        ),
        Text(
          label,
          style: context.text.labelSmall?.copyWith(color: Colors.white60),
        ),
      ],
    );
  }
}
