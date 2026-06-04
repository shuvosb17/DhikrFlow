import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/di/providers.dart';
import '../../domain/entities/analytics.dart';

/// Total dhikr count across all categories for today.
final todayTotalProvider = FutureProvider.autoDispose<int>((ref) async {
  return ref.watch(dhikrRepositoryProvider).todayTotal();
});

final weeklyAnalyticsProvider =
    FutureProvider.autoDispose<WeeklyAnalytics>((ref) async {
  return ref.watch(dhikrRepositoryProvider).weeklyAnalytics();
});

final monthlyAnalyticsProvider =
    FutureProvider.autoDispose.family<MonthlyAnalytics, DateTime?>(
        (ref, month) async {
  return ref.watch(dhikrRepositoryProvider).monthlyAnalytics(month: month);
});

final yearlyAnalyticsProvider =
    FutureProvider.autoDispose.family<YearlyAnalytics, int?>((ref, year) async {
  return ref.watch(dhikrRepositoryProvider).yearlyAnalytics(year: year);
});

final streakInfoProvider =
    FutureProvider.autoDispose<StreakInfo>((ref) async {
  return ref.watch(dhikrRepositoryProvider).streakInfo();
});
