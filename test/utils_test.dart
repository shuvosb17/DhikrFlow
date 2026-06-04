import 'package:dhikrflow/core/utils/date_helpers.dart';
import 'package:dhikrflow/core/utils/formatters.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Formatters', () {
    test('number adds grouping separators', () {
      expect(Formatters.number(1234), '1,234');
    });

    test('percent clamps and rounds', () {
      expect(Formatters.percent(0.625), '63%');
      expect(Formatters.percent(1.5), '100%');
      expect(Formatters.percent(-0.2), '0%');
    });

    test('pluralize handles singular and plural', () {
      expect(Formatters.pluralize(1, 'day'), '1 day');
      expect(Formatters.pluralize(3, 'day'), '3 days');
    });
  });

  group('DateHelpers', () {
    test('dayKey is stable yyyy-MM-dd', () {
      final d = DateTime(2026, 6, 4, 23, 59);
      expect(DateHelpers.dayKey(d), '2026-06-04');
    });

    test('parseDayKey round-trips', () {
      const key = '2026-01-15';
      expect(DateHelpers.dayKey(DateHelpers.parseDayKey(key)), key);
    });

    test('lastNDays returns ordered, inclusive range', () {
      final days = DateHelpers.lastNDays(7, from: DateTime(2026, 6, 4));
      expect(days.length, 7);
      expect(DateHelpers.dayKey(days.first), '2026-05-29');
      expect(DateHelpers.dayKey(days.last), '2026-06-04');
    });

    test('startOfWeek returns Monday', () {
      // 2026-06-04 is a Thursday.
      final monday = DateHelpers.startOfWeek(DateTime(2026, 6, 4));
      expect(monday.weekday, DateTime.monday);
      expect(DateHelpers.dayKey(monday), '2026-06-01');
    });

    test('daysInMonth covers full month', () {
      final days = DateHelpers.daysInMonth(DateTime(2026, 2, 10));
      expect(days.length, 28); // Feb 2026
    });
  });
}
