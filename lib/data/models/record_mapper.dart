import '../../core/utils/date_helpers.dart';
import '../../domain/entities/daily_record.dart';
import '../../domain/entities/dhikr_session.dart';

/// Maps between `daily_records` rows and [DailyRecord] entities.
class RecordMapper {
  RecordMapper._();

  static DailyRecord fromRow(Map<String, Object?> row) {
    return DailyRecord(
      id: row['id'] as String,
      categoryId: row['category_id'] as String,
      date: DateHelpers.parseDayKey(row['day'] as String),
      count: (row['count'] as int?) ?? 0,
    );
  }

  static Map<String, Object?> toRow(DailyRecord r) {
    return {
      'id': r.id,
      'category_id': r.categoryId,
      'day': DateHelpers.dayKey(r.date),
      'count': r.count,
    };
  }
}

/// Maps between `sessions` rows and [DhikrSession] entities.
class SessionMapper {
  SessionMapper._();

  static DhikrSession fromRow(Map<String, Object?> row) {
    final ended = row['ended_at'] as int?;
    return DhikrSession(
      id: row['id'] as String,
      categoryId: row['category_id'] as String,
      count: (row['count'] as int?) ?? 0,
      startedAt:
          DateTime.fromMillisecondsSinceEpoch(row['started_at'] as int),
      endedAt:
          ended == null ? null : DateTime.fromMillisecondsSinceEpoch(ended),
    );
  }

  static Map<String, Object?> toRow(DhikrSession s) {
    return {
      'id': s.id,
      'category_id': s.categoryId,
      'count': s.count,
      'started_at': s.startedAt.millisecondsSinceEpoch,
      'ended_at': s.endedAt?.millisecondsSinceEpoch,
    };
  }
}
