import 'package:intl/intl.dart';

/// Date utilities used by tracking and analytics. All persisted dates use the
/// `yyyy-MM-dd` key format so that records group correctly by local day.
class DateHelpers {
  DateHelpers._();

  static final DateFormat _dayKeyFormat = DateFormat('yyyy-MM-dd');
  static final DateFormat _readableFormat = DateFormat('EEE, d MMM yyyy');
  static final DateFormat _shortDay = DateFormat('E'); // Mon, Tue
  static final DateFormat _monthLabel = DateFormat('MMM');
  static final DateFormat _monthYear = DateFormat('MMMM yyyy');

  /// Returns midnight for the given date in local time.
  static DateTime dayOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  static DateTime get today => dayOnly(DateTime.now());

  static DateTime get yesterday => today.subtract(const Duration(days: 1));

  /// Persisted day key, e.g. `2026-06-04`.
  static String dayKey(DateTime date) => _dayKeyFormat.format(dayOnly(date));

  static DateTime parseDayKey(String key) => _dayKeyFormat.parse(key);

  static String readable(DateTime date) => _readableFormat.format(date);

  static String shortDayLabel(DateTime date) => _shortDay.format(date);

  static String monthLabel(DateTime date) => _monthLabel.format(date);

  static String monthYear(DateTime date) => _monthYear.format(date);

  static bool isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  static bool isToday(DateTime date) => isSameDay(date, DateTime.now());

  /// Returns the [count] most recent days ending today, oldest first.
  static List<DateTime> lastNDays(int count, {DateTime? from}) {
    final end = dayOnly(from ?? DateTime.now());
    return List.generate(
      count,
      (i) => end.subtract(Duration(days: count - 1 - i)),
    );
  }

  /// The first day (Monday) of the week containing [date].
  static DateTime startOfWeek(DateTime date) {
    final d = dayOnly(date);
    return d.subtract(Duration(days: d.weekday - 1));
  }

  static DateTime startOfMonth(DateTime date) =>
      DateTime(date.year, date.month, 1);

  static DateTime endOfMonth(DateTime date) =>
      DateTime(date.year, date.month + 1, 0);

  static DateTime startOfYear(DateTime date) => DateTime(date.year, 1, 1);

  /// All days within a month.
  static List<DateTime> daysInMonth(DateTime date) {
    final last = endOfMonth(date).day;
    return List.generate(last, (i) => DateTime(date.year, date.month, i + 1));
  }

  /// Friendly relative label for a day key.
  static String relativeLabel(DateTime date) {
    if (isToday(date)) return 'Today';
    if (isSameDay(date, today.subtract(const Duration(days: 1)))) {
      return 'Yesterday';
    }
    return readable(date);
  }
}
