import '../entities/analytics.dart';
import '../entities/daily_record.dart';
import '../entities/dhikr_session.dart';

/// Contract for counting, daily tracking and analytics.
abstract interface class DhikrRepository {
  /// Increments the count for [categoryId] on [day] (defaults to today) by
  /// [delta] (may be negative for undo). Returns the new daily count.
  Future<int> addCount({
    required String categoryId,
    int delta = 1,
    DateTime? day,
  });

  /// Today's count for a single category.
  Future<int> todayCount(String categoryId);

  /// Today's count across all categories.
  Future<int> todayTotal();

  /// Daily records for a category in an inclusive [start, end] range.
  Future<List<DailyRecord>> recordsForCategory(
    String categoryId, {
    required DateTime start,
    required DateTime end,
  });

  /// All daily records in an inclusive [start, end] range (all categories).
  Future<List<DailyRecord>> recordsInRange({
    required DateTime start,
    required DateTime end,
  });

  // ----- Sessions -----
  Future<DhikrSession> startSession(String categoryId);
  Future<void> finalizeSession(String sessionId, int count);
  Future<List<DhikrSession>> recentSessions({int limit = 20});

  // ----- Analytics -----
  Future<WeeklyAnalytics> weeklyAnalytics({DateTime? endDay});
  Future<MonthlyAnalytics> monthlyAnalytics({DateTime? month});
  Future<YearlyAnalytics> yearlyAnalytics({int? year});
  Future<StreakInfo> streakInfo();

  // ----- Export -----
  Future<List<DailyRecord>> allRecords();
}
