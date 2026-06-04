import 'package:flutter/foundation.dart';

/// Aggregated count for a single (category, day) pair. Mirrors the
/// `daily_records` table and is the basis for all analytics.
@immutable
class DailyRecord {
  const DailyRecord({
    required this.id,
    required this.categoryId,
    required this.date,
    required this.count,
  });

  final String id;
  final String categoryId;

  /// Local midnight for the record's day.
  final DateTime date;
  final int count;

  DailyRecord copyWith({int? count}) => DailyRecord(
        id: id,
        categoryId: categoryId,
        date: date,
        count: count ?? this.count,
      );
}
