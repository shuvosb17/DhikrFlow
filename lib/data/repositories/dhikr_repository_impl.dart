import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import '../../core/utils/date_helpers.dart';
import '../../domain/entities/analytics.dart';
import '../../domain/entities/daily_record.dart';
import '../../domain/entities/dhikr_category.dart';
import '../../domain/entities/dhikr_session.dart';
import '../../domain/repositories/dhikr_repository.dart';
import '../datasources/app_database.dart';
import '../models/category_mapper.dart';
import '../models/record_mapper.dart';

class DhikrRepositoryImpl implements DhikrRepository {
  DhikrRepositoryImpl(this._db, {Uuid? uuid}) : _uuid = uuid ?? const Uuid();

  final AppDatabase _db;
  final Uuid _uuid;

  @override
  Future<int> addCount({
    required String categoryId,
    int delta = 1,
    DateTime? day,
  }) async {
    final db = await _db.database;
    final key = DateHelpers.dayKey(day ?? DateTime.now());

    return db.transaction<int>((txn) async {
      final existing = await txn.query(
        'daily_records',
        where: 'category_id = ? AND day = ?',
        whereArgs: [categoryId, key],
        limit: 1,
      );

      int newCount;
      if (existing.isEmpty) {
        newCount = delta < 0 ? 0 : delta;
        await txn.insert('daily_records', {
          'id': _uuid.v4(),
          'category_id': categoryId,
          'day': key,
          'count': newCount,
        });
      } else {
        final current = (existing.first['count'] as int?) ?? 0;
        newCount = (current + delta).clamp(0, 1 << 31);
        await txn.update(
          'daily_records',
          {'count': newCount},
          where: 'id = ?',
          whereArgs: [existing.first['id']],
        );
      }

      // Keep denormalized lifetime_count in sync (never below 0).
      await txn.rawUpdate(
        'UPDATE categories SET lifetime_count = MAX(0, lifetime_count + ?) WHERE id = ?',
        [delta, categoryId],
      );

      return newCount;
    });
  }

  @override
  Future<int> todayCount(String categoryId) async {
    final db = await _db.database;
    final rows = await db.query(
      'daily_records',
      columns: ['count'],
      where: 'category_id = ? AND day = ?',
      whereArgs: [categoryId, DateHelpers.dayKey(DateTime.now())],
      limit: 1,
    );
    if (rows.isEmpty) return 0;
    return (rows.first['count'] as int?) ?? 0;
  }

  @override
  Future<int> todayTotal() async {
    final db = await _db.database;
    final result = await db.rawQuery(
      'SELECT SUM(count) AS total FROM daily_records WHERE day = ?',
      [DateHelpers.dayKey(DateTime.now())],
    );
    return (result.first['total'] as int?) ?? 0;
  }

  @override
  Future<List<DailyRecord>> recordsForCategory(
    String categoryId, {
    required DateTime start,
    required DateTime end,
  }) async {
    final db = await _db.database;
    final rows = await db.query(
      'daily_records',
      where: 'category_id = ? AND day >= ? AND day <= ?',
      whereArgs: [
        categoryId,
        DateHelpers.dayKey(start),
        DateHelpers.dayKey(end),
      ],
      orderBy: 'day ASC',
    );
    return rows.map(RecordMapper.fromRow).toList();
  }

  @override
  Future<List<DailyRecord>> recordsInRange({
    required DateTime start,
    required DateTime end,
  }) async {
    final db = await _db.database;
    final rows = await db.query(
      'daily_records',
      where: 'day >= ? AND day <= ?',
      whereArgs: [DateHelpers.dayKey(start), DateHelpers.dayKey(end)],
      orderBy: 'day ASC',
    );
    return rows.map(RecordMapper.fromRow).toList();
  }

  // ---------------------------------------------------------------- Sessions

  @override
  Future<DhikrSession> startSession(String categoryId) async {
    final db = await _db.database;
    final session = DhikrSession(
      id: _uuid.v4(),
      categoryId: categoryId,
      count: 0,
      startedAt: DateTime.now(),
      endedAt: null,
    );
    await db.insert('sessions', SessionMapper.toRow(session));
    return session;
  }

  @override
  Future<void> finalizeSession(String sessionId, int count) async {
    final db = await _db.database;
    if (count <= 0) {
      // Discard empty sessions to keep history meaningful.
      await db.delete('sessions', where: 'id = ?', whereArgs: [sessionId]);
      return;
    }
    await db.update(
      'sessions',
      {'count': count, 'ended_at': DateTime.now().millisecondsSinceEpoch},
      where: 'id = ?',
      whereArgs: [sessionId],
    );
  }

  @override
  Future<List<DhikrSession>> recentSessions({int limit = 20}) async {
    final db = await _db.database;
    final rows = await db.query(
      'sessions',
      where: 'count > 0',
      orderBy: 'started_at DESC',
      limit: limit,
    );
    return rows.map(SessionMapper.fromRow).toList();
  }

  // --------------------------------------------------------------- Analytics

  Future<List<DhikrCategory>> _categories() async {
    final db = await _db.database;
    final rows = await db.query('categories', orderBy: 'sort_order ASC');
    return rows.map(CategoryMapper.fromRow).toList();
  }

  /// Sums records into a `dayKey -> total` map.
  Map<String, int> _sumByDay(List<DailyRecord> records) {
    final map = <String, int>{};
    for (final r in records) {
      final k = DateHelpers.dayKey(r.date);
      map[k] = (map[k] ?? 0) + r.count;
    }
    return map;
  }

  Map<String, int> _sumByCategory(List<DailyRecord> records) {
    final map = <String, int>{};
    for (final r in records) {
      map[r.categoryId] = (map[r.categoryId] ?? 0) + r.count;
    }
    return map;
  }

  @override
  Future<WeeklyAnalytics> weeklyAnalytics({DateTime? endDay}) async {
    final days = DateHelpers.lastNDays(7, from: endDay);
    final records = await recordsInRange(start: days.first, end: days.last);
    final byDay = _sumByDay(records);

    final dailyCounts = days
        .map((d) => DayCount(d, byDay[DateHelpers.dayKey(d)] ?? 0))
        .toList();
    final total = dailyCounts.fold<int>(0, (s, e) => s + e.count);
    final average = dailyCounts.isEmpty ? 0.0 : total / dailyCounts.length;

    final byCat = _sumByCategory(records);
    final topCategory = await _topCategory(byCat);

    return WeeklyAnalytics(
      dailyCounts: dailyCounts,
      total: total,
      average: average,
      topCategory: topCategory,
    );
  }

  @override
  Future<MonthlyAnalytics> monthlyAnalytics({DateTime? month}) async {
    final target = month ?? DateTime.now();
    final start = DateHelpers.startOfMonth(target);
    final end = DateHelpers.endOfMonth(target);
    final records = await recordsInRange(start: start, end: end);
    final byDay = _sumByDay(records);

    final dailyCounts = DateHelpers.daysInMonth(target)
        .map((d) => DayCount(d, byDay[DateHelpers.dayKey(d)] ?? 0))
        .toList();
    final total = dailyCounts.fold<int>(0, (s, e) => s + e.count);

    final byCat = _sumByCategory(records);
    final categories = await _categories();
    final categoryTotals = categories
        .map((c) => CategoryTotal(c, byCat[c.id] ?? 0))
        .where((e) => e.count > 0)
        .toList()
      ..sort((a, b) => b.count.compareTo(a.count));

    final streak = await streakInfo();

    return MonthlyAnalytics(
      month: start,
      dailyCounts: dailyCounts,
      categoryTotals: categoryTotals,
      total: total,
      streak: streak,
    );
  }

  @override
  Future<YearlyAnalytics> yearlyAnalytics({int? year}) async {
    final y = year ?? DateTime.now().year;
    final start = DateTime(y, 1, 1);
    final end = DateTime(y, 12, 31);
    final records = await recordsInRange(start: start, end: end);

    final byMonth = <int, int>{};
    for (final r in records) {
      byMonth[r.date.month] = (byMonth[r.date.month] ?? 0) + r.count;
    }
    final monthlyCounts =
        List.generate(12, (i) => MonthCount(i + 1, byMonth[i + 1] ?? 0));
    final total = monthlyCounts.fold<int>(0, (s, e) => s + e.count);

    MonthCount? best;
    for (final m in monthlyCounts) {
      if (m.count > 0 && (best == null || m.count > best.count)) best = m;
    }

    final streak = await streakInfo();

    return YearlyAnalytics(
      year: y,
      monthlyCounts: monthlyCounts,
      total: total,
      bestMonth: best,
      longestStreak: streak.longestStreak,
    );
  }

  @override
  Future<StreakInfo> streakInfo() async {
    final db = await _db.database;
    // Days that had any activity.
    final dayRows = await db.rawQuery(
      'SELECT day, SUM(count) AS total FROM daily_records GROUP BY day HAVING total > 0 ORDER BY day ASC',
    );
    if (dayRows.isEmpty) return StreakInfo.empty;

    final activeDayKeys = <DateTime>[];
    final totalsByDay = <DateTime, int>{};
    for (final row in dayRows) {
      final d = DateHelpers.parseDayKey(row['day'] as String);
      activeDayKeys.add(d);
      totalsByDay[d] = (row['total'] as int?) ?? 0;
    }

    // Longest streak: scan sorted active days for consecutive runs.
    int longest = 1;
    int run = 1;
    for (var i = 1; i < activeDayKeys.length; i++) {
      final diff = activeDayKeys[i].difference(activeDayKeys[i - 1]).inDays;
      if (diff == 1) {
        run++;
        if (run > longest) longest = run;
      } else {
        run = 1;
      }
    }

    // Current streak: count back from today (or yesterday) while days active.
    final activeSet = activeDayKeys.map(DateHelpers.dayKey).toSet();
    int current = 0;
    var cursor = DateHelpers.today;
    if (!activeSet.contains(DateHelpers.dayKey(cursor))) {
      // Allow streak to persist if yesterday was active (today not yet logged).
      cursor = cursor.subtract(const Duration(days: 1));
    }
    while (activeSet.contains(DateHelpers.dayKey(cursor))) {
      current++;
      cursor = cursor.subtract(const Duration(days: 1));
    }

    // Days that met the combined daily target.
    final categories = await _categories();
    final totalTarget = categories
        .where((c) => c.hasTarget)
        .fold<int>(0, (s, c) => s + (c.dailyTarget ?? 0));
    int completedTargetDays = 0;
    if (totalTarget > 0) {
      completedTargetDays =
          totalsByDay.values.where((t) => t >= totalTarget).length;
    }

    return StreakInfo(
      currentStreak: current,
      longestStreak: longest,
      completedTargetDays: completedTargetDays,
      activeDays: activeDayKeys.length,
    );
  }

  @override
  Future<List<DailyRecord>> allRecords() async {
    final db = await _db.database;
    final rows = await db.query('daily_records', orderBy: 'day ASC');
    return rows.map(RecordMapper.fromRow).toList();
  }

  Future<CategoryTotal?> _topCategory(Map<String, int> byCat) async {
    if (byCat.isEmpty) return null;
    String? topId;
    int topCount = -1;
    byCat.forEach((id, count) {
      if (count > topCount) {
        topCount = count;
        topId = id;
      }
    });
    if (topId == null || topCount <= 0) return null;
    final categories = await _categories();
    final match = categories.where((c) => c.id == topId).toList();
    if (match.isEmpty) return null;
    return CategoryTotal(match.first, topCount);
  }
}
