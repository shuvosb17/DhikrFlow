import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../providers/analytics_providers.dart';
import '../../widgets/app_card.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/section_header.dart';
import '../../widgets/stat_tile.dart';
import 'widgets/category_pie_chart.dart';
import 'widgets/monthly_heatmap.dart';
import 'widgets/weekly_bar_chart.dart';
import 'widgets/yearly_line_chart.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Analytics'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Weekly'),
              Tab(text: 'Monthly'),
              Tab(text: 'Yearly'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _WeeklyTab(),
            _MonthlyTab(),
            _YearlyTab(),
          ],
        ),
      ),
    );
  }
}

class _WeeklyTab extends ConsumerWidget {
  const _WeeklyTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(weeklyAnalyticsProvider);
    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('$e')),
      data: (a) {
        if (a.total == 0) {
          return const EmptyState(
            icon: Icons.insights_outlined,
            title: 'No activity this week',
            message: 'Start counting to see your weekly insights here.',
          );
        }
        return ListView(
          padding: const EdgeInsets.all(Gap.md),
          children: [
            Row(
              children: [
                Expanded(
                  child: StatTile(
                    label: 'Weekly total',
                    value: Formatters.number(a.total),
                    icon: Icons.functions_rounded,
                  ),
                ),
                const SizedBox(width: Gap.sm),
                Expanded(
                  child: StatTile(
                    label: 'Daily average',
                    value: Formatters.number(a.average.round()),
                    icon: Icons.timeline_rounded,
                  ),
                ),
              ],
            ),
            if (a.topCategory != null) ...[
              const SizedBox(height: Gap.sm),
              StatTile(
                label: 'Most used dhikr',
                value: a.topCategory!.category.name,
                caption:
                    '${Formatters.number(a.topCategory!.count)} this week',
                icon: a.topCategory!.category.icon,
                accent: a.topCategory!.category.color,
              ),
            ],
            const SizedBox(height: Gap.lg),
            const SectionHeader(title: 'Daily counts'),
            AppCard(child: WeeklyBarChart(data: a.dailyCounts)),
            const SizedBox(height: Gap.xxl),
          ],
        );
      },
    );
  }
}

class _MonthlyTab extends ConsumerWidget {
  const _MonthlyTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(monthlyAnalyticsProvider(null));
    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('$e')),
      data: (a) {
        return ListView(
          padding: const EdgeInsets.all(Gap.md),
          children: [
            Text(
              DateFormat('MMMM yyyy').format(a.month),
              style: context.text.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: Gap.md),
            Row(
              children: [
                Expanded(
                  child: StatTile(
                    label: 'Monthly total',
                    value: Formatters.number(a.total),
                    icon: Icons.calendar_month_rounded,
                  ),
                ),
                const SizedBox(width: Gap.sm),
                Expanded(
                  child: StatTile(
                    label: 'Current streak',
                    value: Formatters.pluralize(
                        a.streak.currentStreak, 'day'),
                    icon: Icons.local_fire_department_rounded,
                    accent: context.extras.warning,
                  ),
                ),
              ],
            ),
            if (a.total == 0)
              const Padding(
                padding: EdgeInsets.only(top: Gap.xl),
                child: EmptyState(
                  icon: Icons.calendar_today_outlined,
                  title: 'No activity yet this month',
                  message: 'Your monthly heatmap will fill in as you count.',
                ),
              )
            else ...[
              const SizedBox(height: Gap.lg),
              const SectionHeader(title: 'Activity heatmap'),
              AppCard(
                child: MonthlyHeatmap(
                  month: a.month,
                  dailyCounts: a.dailyCounts,
                ),
              ),
              if (a.categoryTotals.isNotEmpty) ...[
                const SizedBox(height: Gap.lg),
                const SectionHeader(title: 'Category distribution'),
                AppCard(child: CategoryPieChart(totals: a.categoryTotals)),
              ],
            ],
            const SizedBox(height: Gap.xxl),
          ],
        );
      },
    );
  }
}

class _YearlyTab extends ConsumerWidget {
  const _YearlyTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(yearlyAnalyticsProvider(null));
    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('$e')),
      data: (a) {
        final bestMonthLabel = a.bestMonth == null
            ? '—'
            : DateFormat('MMM')
                .format(DateTime(a.year, a.bestMonth!.monthIndex));
        return ListView(
          padding: const EdgeInsets.all(Gap.md),
          children: [
            Text(
              '${a.year}',
              style: context.text.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: Gap.md),
            Row(
              children: [
                Expanded(
                  child: StatTile(
                    label: 'Yearly total',
                    value: Formatters.compact(a.total),
                    icon: Icons.stacked_line_chart_rounded,
                  ),
                ),
                const SizedBox(width: Gap.sm),
                Expanded(
                  child: StatTile(
                    label: 'Best month',
                    value: bestMonthLabel,
                    caption: a.bestMonth == null
                        ? null
                        : Formatters.compact(a.bestMonth!.count),
                    icon: Icons.workspace_premium_rounded,
                    accent: context.extras.accent,
                  ),
                ),
              ],
            ),
            const SizedBox(height: Gap.sm),
            StatTile(
              label: 'Longest streak',
              value: Formatters.pluralize(a.longestStreak, 'day'),
              icon: Icons.emoji_events_rounded,
              accent: context.extras.warning,
            ),
            if (a.total == 0)
              const Padding(
                padding: EdgeInsets.only(top: Gap.xl),
                child: EmptyState(
                  icon: Icons.show_chart_rounded,
                  title: 'No activity yet this year',
                  message: 'Build a habit and watch your yearly trend grow.',
                ),
              )
            else ...[
              const SizedBox(height: Gap.lg),
              const SectionHeader(title: 'Monthly trend'),
              AppCard(child: YearlyLineChart(data: a.monthlyCounts)),
            ],
            const SizedBox(height: Gap.xxl),
          ],
        );
      },
    );
  }
}
