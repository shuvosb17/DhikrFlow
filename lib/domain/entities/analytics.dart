import 'package:flutter/foundation.dart';

import 'dhikr_category.dart';

/// A single (day -> count) point used by charts.
@immutable
class DayCount {
  const DayCount(this.date, this.count);
  final DateTime date;
  final int count;
}

/// A category total used by pie / distribution charts.
@immutable
class CategoryTotal {
  const CategoryTotal(this.category, this.count);
  final DhikrCategory category;
  final int count;
}

/// A (month index -> count) point for yearly trends. [monthIndex] is 1..12.
@immutable
class MonthCount {
  const MonthCount(this.monthIndex, this.count);
  final int monthIndex;
  final int count;
}

/// Streak information derived from days with activity / completed targets.
@immutable
class StreakInfo {
  const StreakInfo({
    required this.currentStreak,
    required this.longestStreak,
    required this.completedTargetDays,
    required this.activeDays,
  });

  final int currentStreak;
  final int longestStreak;
  final int completedTargetDays;
  final int activeDays;

  static const empty = StreakInfo(
    currentStreak: 0,
    longestStreak: 0,
    completedTargetDays: 0,
    activeDays: 0,
  );
}

/// Weekly analytics bundle (last 7 days).
@immutable
class WeeklyAnalytics {
  const WeeklyAnalytics({
    required this.dailyCounts,
    required this.total,
    required this.average,
    required this.topCategory,
  });

  final List<DayCount> dailyCounts;
  final int total;
  final double average;
  final CategoryTotal? topCategory;

  static const empty = WeeklyAnalytics(
    dailyCounts: [],
    total: 0,
    average: 0,
    topCategory: null,
  );
}

/// Monthly analytics bundle.
@immutable
class MonthlyAnalytics {
  const MonthlyAnalytics({
    required this.month,
    required this.dailyCounts,
    required this.categoryTotals,
    required this.total,
    required this.streak,
  });

  final DateTime month;
  final List<DayCount> dailyCounts; // heatmap source
  final List<CategoryTotal> categoryTotals; // pie chart source
  final int total;
  final StreakInfo streak;

  static final empty = MonthlyAnalytics(
    month: DateTime.now(),
    dailyCounts: const [],
    categoryTotals: const [],
    total: 0,
    streak: StreakInfo.empty,
  );
}

/// Yearly analytics bundle.
@immutable
class YearlyAnalytics {
  const YearlyAnalytics({
    required this.year,
    required this.monthlyCounts,
    required this.total,
    required this.bestMonth,
    required this.longestStreak,
  });

  final int year;
  final List<MonthCount> monthlyCounts;
  final int total;
  final MonthCount? bestMonth;
  final int longestStreak;

  static final empty = YearlyAnalytics(
    year: DateTime.now().year,
    monthlyCounts: const [],
    total: 0,
    bestMonth: null,
    longestStreak: 0,
  );
}
