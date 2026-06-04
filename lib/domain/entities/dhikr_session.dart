import 'package:flutter/foundation.dart';

/// A discrete counting session. Created when the user starts counting in a
/// category and finalized when they leave or reset. Useful for history detail.
@immutable
class DhikrSession {
  const DhikrSession({
    required this.id,
    required this.categoryId,
    required this.count,
    required this.startedAt,
    required this.endedAt,
  });

  final String id;
  final String categoryId;
  final int count;
  final DateTime startedAt;
  final DateTime? endedAt;

  DhikrSession copyWith({int? count, DateTime? endedAt}) => DhikrSession(
        id: id,
        categoryId: categoryId,
        count: count ?? this.count,
        startedAt: startedAt,
        endedAt: endedAt ?? this.endedAt,
      );
}
