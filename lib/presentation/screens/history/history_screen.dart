import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/date_helpers.dart';
import '../../../core/utils/formatters.dart';
import '../../../domain/entities/daily_record.dart';
import '../../../domain/entities/dhikr_category.dart';
import '../../providers/category_providers.dart';
import '../../providers/export_provider.dart';
import '../../providers/history_providers.dart';
import '../../widgets/app_card.dart';
import '../../widgets/empty_state.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(historyFilterProvider);
    final recordsAsync = ref.watch(filteredRecordsProvider);
    final categories = ref.watch(categoriesProvider).valueOrNull ?? const [];

    return Scaffold(
      appBar: AppBar(
        title: const Text('History'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.ios_share_rounded),
            tooltip: 'Export',
            onSelected: (value) => _export(context, ref, value),
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'csv', child: Text('Export as CSV')),
              PopupMenuItem(value: 'pdf', child: Text('Export as PDF')),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          _PresetChips(filter: filter),
          _CategoryFilter(categories: categories, filter: filter),
          const Divider(height: 1),
          Expanded(
            child: recordsAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('$e')),
              data: (records) {
                final positive =
                    records.where((r) => r.count > 0).toList();
                if (positive.isEmpty) {
                  return const EmptyState(
                    icon: Icons.history_rounded,
                    title: 'No records in this range',
                    message: 'Try a different date range or category filter.',
                  );
                }
                return _RecordList(records: positive);
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _export(BuildContext context, WidgetRef ref, String fmt) async {
    final records = ref.read(filteredRecordsProvider).valueOrNull ?? const [];
    final categories =
        ref.read(categoriesProvider).valueOrNull ?? const [];
    if (records.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nothing to export for this range.')),
      );
      return;
    }
    final service = ref.read(exportServiceProvider);
    final filter = ref.read(historyFilterProvider);
    try {
      if (fmt == 'csv') {
        await service.exportCsv(records: records, categories: categories);
      } else {
        await service.exportPdf(
          records: records,
          categories: categories,
          start: filter.start,
          end: filter.end,
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e')),
        );
      }
    }
  }
}

class _PresetChips extends ConsumerWidget {
  const _PresetChips({required this.filter});

  final HistoryFilter filter;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const labels = {
      RangePreset.today: 'Today',
      RangePreset.yesterday: 'Yesterday',
      RangePreset.last7: 'Last 7 days',
      RangePreset.last30: 'Last 30 days',
      RangePreset.custom: 'Custom',
    };
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(Gap.md, Gap.md, Gap.md, Gap.sm),
      child: Row(
        children: labels.entries.map((e) {
          final selected = filter.preset == e.key;
          return Padding(
            padding: const EdgeInsets.only(right: Gap.sm),
            child: ChoiceChip(
              label: Text(e.key == RangePreset.custom && selected
                  ? '${DateHelpers.dayKey(filter.start)} → ${DateHelpers.dayKey(filter.end)}'
                  : e.value),
              selected: selected,
              onSelected: (_) async {
                if (e.key == RangePreset.custom) {
                  final range = await showDateRangePicker(
                    context: context,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                    initialDateRange: DateTimeRange(
                        start: filter.start, end: filter.end),
                  );
                  if (range != null) {
                    ref
                        .read(historyFilterProvider.notifier)
                        .setCustomRange(range.start, range.end);
                  }
                } else {
                  ref.read(historyFilterProvider.notifier).setPreset(e.key);
                }
              },
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _CategoryFilter extends ConsumerWidget {
  const _CategoryFilter({required this.categories, required this.filter});

  final List<DhikrCategory> categories;
  final HistoryFilter filter;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(Gap.md, 0, Gap.md, Gap.sm),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            FilterChip(
              label: const Text('All'),
              selected: filter.categoryId == null,
              onSelected: (_) =>
                  ref.read(historyFilterProvider.notifier).setCategory(null),
            ),
            const SizedBox(width: Gap.sm),
            for (final c in categories)
              Padding(
                padding: const EdgeInsets.only(right: Gap.sm),
                child: FilterChip(
                  avatar: Icon(c.icon, size: 16, color: c.color),
                  label: Text(c.name),
                  selected: filter.categoryId == c.id,
                  onSelected: (_) => ref
                      .read(historyFilterProvider.notifier)
                      .setCategory(c.id),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _RecordList extends ConsumerWidget {
  const _RecordList({required this.records});

  final List<DailyRecord> records;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Group by day, newest first.
    final byDay = groupBy(records, (r) => DateHelpers.dayKey(r.date));
    final days = byDay.keys.toList()..sort((a, b) => b.compareTo(a));

    return ListView.separated(
      padding: const EdgeInsets.all(Gap.md),
      itemCount: days.length,
      separatorBuilder: (_, __) => const SizedBox(height: Gap.md),
      itemBuilder: (context, i) {
        final dayKey = days[i];
        final dayRecords = byDay[dayKey]!;
        final date = DateHelpers.parseDayKey(dayKey);
        final total = dayRecords.fold<int>(0, (s, r) => s + r.count);

        return AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      DateHelpers.relativeLabel(date),
                      style: context.text.titleSmall
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                  Text(
                    Formatters.number(total),
                    style: context.text.titleSmall?.copyWith(
                      color: context.colors.primary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: Gap.sm),
              ...dayRecords.map((r) {
                final category = ref.watch(categoryByIdProvider(r.categoryId));
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Icon(
                        category?.icon ?? Icons.circle,
                        size: 16,
                        color: category?.color ?? context.colors.primary,
                      ),
                      const SizedBox(width: Gap.sm),
                      Expanded(
                        child: Text(
                          category?.name ?? 'Unknown',
                          style: context.text.bodyMedium,
                        ),
                      ),
                      Text(
                        Formatters.number(r.count),
                        style: context.text.bodyMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }
}
