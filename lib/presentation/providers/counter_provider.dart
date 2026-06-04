import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/di/providers.dart';
import '../../domain/entities/dhikr_session.dart';
import '../../domain/repositories/dhikr_repository.dart';
import 'analytics_providers.dart';
import 'category_providers.dart';

/// Live counting state for a single category screen.
@immutable
class CounterState {
  const CounterState({
    required this.sessionCount,
    required this.todayCount,
    required this.lifetimeCount,
    required this.canUndo,
    this.justHitMilestone = false,
  });

  final int sessionCount;
  final int todayCount;
  final int lifetimeCount;
  final bool canUndo;

  /// True for one emission after crossing a milestone (UI feedback hook).
  final bool justHitMilestone;

  CounterState copyWith({
    int? sessionCount,
    int? todayCount,
    int? lifetimeCount,
    bool? canUndo,
    bool? justHitMilestone,
  }) {
    return CounterState(
      sessionCount: sessionCount ?? this.sessionCount,
      todayCount: todayCount ?? this.todayCount,
      lifetimeCount: lifetimeCount ?? this.lifetimeCount,
      canUndo: canUndo ?? this.canUndo,
      justHitMilestone: justHitMilestone ?? this.justHitMilestone,
    );
  }
}

class CounterNotifier
    extends AutoDisposeFamilyAsyncNotifier<CounterState, String> {
  late String _categoryId;
  late DhikrRepository _repo;
  DhikrSession? _session;
  int _milestone = 33;

  @override
  Future<CounterState> build(String categoryId) async {
    _categoryId = categoryId;
    // Captured so dispose-time finalization never touches a disposed ref.
    _repo = ref.read(dhikrRepositoryProvider);
    final category = ref.read(categoryByIdProvider(categoryId));
    _milestone = category?.dailyTarget ?? 33;

    final today = await _repo.todayCount(categoryId);
    final lifetime = category?.lifetimeCount ?? 0;

    _session = await _repo.startSession(categoryId);
    ref.onDispose(_finalize);

    return CounterState(
      sessionCount: 0,
      todayCount: today,
      lifetimeCount: lifetime,
      canUndo: false,
    );
  }

  Future<void> _finalize() async {
    final session = _session;
    final current = state.valueOrNull;
    if (session == null || current == null) return;
    await _repo.finalizeSession(session.id, current.sessionCount);
  }

  Future<void> increment() async {
    final current = state.valueOrNull;
    if (current == null) return;
    await _repo.addCount(categoryId: _categoryId, delta: 1);

    final newSession = current.sessionCount + 1;
    final hitMilestone =
        _milestone > 0 && newSession % _milestone == 0;

    state = AsyncData(current.copyWith(
      sessionCount: newSession,
      todayCount: current.todayCount + 1,
      lifetimeCount: current.lifetimeCount + 1,
      canUndo: true,
      justHitMilestone: hitMilestone,
    ));
    _invalidateAnalytics();
  }

  Future<void> undo() async {
    final current = state.valueOrNull;
    if (current == null || current.sessionCount <= 0) return;
    await _repo.addCount(categoryId: _categoryId, delta: -1);

    final newSession = current.sessionCount - 1;
    state = AsyncData(current.copyWith(
      sessionCount: newSession,
      todayCount: (current.todayCount - 1).clamp(0, 1 << 31),
      lifetimeCount: (current.lifetimeCount - 1).clamp(0, 1 << 31),
      canUndo: newSession > 0,
      justHitMilestone: false,
    ));
    _invalidateAnalytics();
  }

  /// Resets the on-screen session tally only. Today/lifetime totals persist.
  Future<void> resetSession() async {
    final current = state.valueOrNull;
    if (current == null) return;
    await _finalize();
    _session = await _repo.startSession(_categoryId);
    state = AsyncData(current.copyWith(
      sessionCount: 0,
      canUndo: false,
      justHitMilestone: false,
    ));
  }

  void _invalidateAnalytics() {
    ref.invalidate(categoriesProvider);
    ref.invalidate(todayTotalProvider);
    ref.invalidate(weeklyAnalyticsProvider);
    ref.invalidate(monthlyAnalyticsProvider);
    ref.invalidate(streakInfoProvider);
  }
}

final counterProvider = AsyncNotifierProvider.autoDispose
    .family<CounterNotifier, CounterState, String>(
  CounterNotifier.new,
);
