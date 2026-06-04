import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/di/providers.dart';
import '../../core/utils/date_helpers.dart';
import '../../domain/entities/daily_record.dart';
import '../../domain/entities/dhikr_session.dart';

enum RangePreset { today, yesterday, last7, last30, custom }

@immutable
class HistoryFilter {
  const HistoryFilter({
    this.preset = RangePreset.last7,
    required this.start,
    required this.end,
    this.categoryId,
  });

  final RangePreset preset;
  final DateTime start;
  final DateTime end;
  final String? categoryId; // null = all categories

  HistoryFilter copyWith({
    RangePreset? preset,
    DateTime? start,
    DateTime? end,
    String? categoryId,
    bool clearCategory = false,
  }) {
    return HistoryFilter(
      preset: preset ?? this.preset,
      start: start ?? this.start,
      end: end ?? this.end,
      categoryId: clearCategory ? null : (categoryId ?? this.categoryId),
    );
  }

  static HistoryFilter forPreset(RangePreset preset, {String? categoryId}) {
    final today = DateHelpers.today;
    switch (preset) {
      case RangePreset.today:
        return HistoryFilter(
            preset: preset, start: today, end: today, categoryId: categoryId);
      case RangePreset.yesterday:
        final y = today.subtract(const Duration(days: 1));
        return HistoryFilter(
            preset: preset, start: y, end: y, categoryId: categoryId);
      case RangePreset.last7:
        return HistoryFilter(
          preset: preset,
          start: today.subtract(const Duration(days: 6)),
          end: today,
          categoryId: categoryId,
        );
      case RangePreset.last30:
        return HistoryFilter(
          preset: preset,
          start: today.subtract(const Duration(days: 29)),
          end: today,
          categoryId: categoryId,
        );
      case RangePreset.custom:
        return HistoryFilter(
          preset: preset,
          start: today.subtract(const Duration(days: 6)),
          end: today,
          categoryId: categoryId,
        );
    }
  }
}

class HistoryFilterNotifier extends Notifier<HistoryFilter> {
  @override
  HistoryFilter build() => HistoryFilter.forPreset(RangePreset.last7);

  void setPreset(RangePreset preset) {
    state = HistoryFilter.forPreset(preset, categoryId: state.categoryId);
  }

  void setCustomRange(DateTime start, DateTime end) {
    state = state.copyWith(
      preset: RangePreset.custom,
      start: DateHelpers.dayOnly(start),
      end: DateHelpers.dayOnly(end),
    );
  }

  void setCategory(String? categoryId) {
    state = categoryId == null
        ? state.copyWith(clearCategory: true)
        : state.copyWith(categoryId: categoryId);
  }
}

final historyFilterProvider =
    NotifierProvider<HistoryFilterNotifier, HistoryFilter>(
  HistoryFilterNotifier.new,
);

/// Daily records that match the active history filter.
final filteredRecordsProvider = FutureProvider<List<DailyRecord>>((ref) async {
  final filter = ref.watch(historyFilterProvider);
  final repo = ref.watch(dhikrRepositoryProvider);
  if (filter.categoryId != null) {
    return repo.recordsForCategory(
      filter.categoryId!,
      start: filter.start,
      end: filter.end,
    );
  }
  return repo.recordsInRange(start: filter.start, end: filter.end);
});

final recentSessionsProvider = FutureProvider<List<DhikrSession>>((ref) async {
  return ref.watch(dhikrRepositoryProvider).recentSessions(limit: 30);
});
