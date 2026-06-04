import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../providers/category_providers.dart';
import '../../providers/counter_provider.dart';
import '../../providers/settings_provider.dart';
import '../categories/category_form_screen.dart';

class CounterScreen extends ConsumerStatefulWidget {
  const CounterScreen({super.key, required this.categoryId});

  final String categoryId;

  @override
  ConsumerState<CounterScreen> createState() => _CounterScreenState();
}

class _CounterScreenState extends ConsumerState<CounterScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 140),
      lowerBound: 0.0,
      upperBound: 0.06,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (ref.read(settingsProvider).keepScreenOn) {
        // Keeping the screen awake during active counting.
        _setWakelock(true);
      }
    });
  }

  @override
  void dispose() {
    _pulse.dispose();
    _setWakelock(false);
    super.dispose();
  }

  // Wakelock is optional; guarded so the app builds without the plugin.
  void _setWakelock(bool enable) {
    // Intentionally a no-op hook. Add `wakelock_plus` and call it here if the
    // keep-screen-on preference should physically hold the screen awake.
  }

  Future<void> _onTap(BuildContext context) async {
    final settings = ref.read(settingsProvider);
    final notifier =
        ref.read(counterProvider(widget.categoryId).notifier);
    await notifier.increment();

    _pulse.forward().then((_) => _pulse.reverse());

    final state = ref.read(counterProvider(widget.categoryId)).valueOrNull;
    if (settings.hapticsEnabled) {
      final milestone = state?.justHitMilestone ?? false;
      if (milestone && settings.vibrateAtTarget) {
        HapticFeedback.heavyImpact();
      } else {
        HapticFeedback.selectionClick();
      }
    }
  }

  Future<void> _confirmReset() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset session?'),
        content: const Text(
          'This clears the current session counter. Your today and lifetime '
          'totals are kept safe.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(counterProvider(widget.categoryId).notifier).resetSession();
      if (ref.read(settingsProvider).hapticsEnabled) {
        HapticFeedback.mediumImpact();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final category = ref.watch(categoryByIdProvider(widget.categoryId));
    final counterAsync = ref.watch(counterProvider(widget.categoryId));

    if (category == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final color = category.color;
    final target = category.dailyTarget;

    return Scaffold(
      appBar: AppBar(
        title: Text(category.name),
        actions: [
          IconButton(
            tooltip: 'Edit',
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => CategoryFormScreen(existing: category),
              ),
            ),
          ),
        ],
      ),
      body: counterAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (state) {
          final sessionCount = state.sessionCount;
          final cycle = target != null && target > 0
              ? sessionCount % target
              : sessionCount % AppConstants.defaultMilestone;
          final cycleTarget = (target != null && target > 0)
              ? target
              : AppConstants.defaultMilestone;

          return SafeArea(
            child: Column(
              children: [
                if (category.arabic != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                        Gap.lg, Gap.sm, Gap.lg, 0),
                    child: Text(
                      category.arabic!,
                      textAlign: TextAlign.center,
                      style: AppTheme.arabic(context, fontSize: 30),
                    ),
                  ),
                const SizedBox(height: Gap.md),
                _StatsRow(
                  color: color,
                  sessionCount: sessionCount,
                  todayCount: state.todayCount,
                  lifetimeCount: state.lifetimeCount,
                ),
                const SizedBox(height: Gap.md),
                Expanded(
                  child: Center(
                    child: AnimatedBuilder(
                      animation: _pulse,
                      builder: (context, child) => Transform.scale(
                        scale: 1 - _pulse.value,
                        child: child,
                      ),
                      child: _TapArea(
                        color: color,
                        count: sessionCount,
                        cycle: cycle,
                        cycleTarget: cycleTarget,
                        onTap: () => _onTap(context),
                      ),
                    ),
                  ),
                ),
                _Controls(
                  color: color,
                  canUndo: state.canUndo,
                  onUndo: state.canUndo
                      ? () => ref
                          .read(counterProvider(widget.categoryId).notifier)
                          .undo()
                      : null,
                  onReset: sessionCount > 0 ? _confirmReset : null,
                ),
                const SizedBox(height: Gap.lg),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({
    required this.color,
    required this.sessionCount,
    required this.todayCount,
    required this.lifetimeCount,
  });

  final Color color;
  final int sessionCount;
  final int todayCount;
  final int lifetimeCount;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Gap.lg),
      child: Row(
        children: [
          _pill(context, 'Session', Formatters.number(sessionCount), color),
          _pill(context, 'Today', Formatters.number(todayCount), color),
          _pill(context, 'Lifetime', Formatters.compact(lifetimeCount), color),
        ],
      ),
    );
  }

  Widget _pill(
      BuildContext context, String label, String value, Color color) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: context.extras.surfaceAlt,
          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: context.text.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
            Text(
              label,
              style: context.text.labelSmall
                  ?.copyWith(color: context.extras.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

class _TapArea extends StatelessWidget {
  const _TapArea({
    required this.color,
    required this.count,
    required this.cycle,
    required this.cycleTarget,
    required this.onTap,
  });

  final Color color;
  final int count;
  final int cycle;
  final int cycleTarget;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final progress = cycleTarget == 0 ? 0.0 : cycle / cycleTarget;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 260,
        height: 260,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              color.withValues(alpha: 0.16),
              color.withValues(alpha: 0.06),
            ],
          ),
          border: Border.all(color: color.withValues(alpha: 0.35), width: 2),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 260,
              height: 260,
              child: CircularProgressIndicator(
                value: progress,
                strokeWidth: 8,
                backgroundColor: color.withValues(alpha: 0.12),
                valueColor: AlwaysStoppedAnimation(color),
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  Formatters.number(count),
                  style: context.text.displayLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: context.colors.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$cycle / $cycleTarget',
                  style: context.text.titleMedium?.copyWith(color: color),
                ),
                const SizedBox(height: 2),
                Text(
                  'tap to count',
                  style: context.text.labelSmall
                      ?.copyWith(color: context.extras.textSecondary),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Controls extends StatelessWidget {
  const _Controls({
    required this.color,
    required this.canUndo,
    required this.onUndo,
    required this.onReset,
  });

  final Color color;
  final bool canUndo;
  final VoidCallback? onUndo;
  final VoidCallback? onReset;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Gap.lg),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _circleButton(
            context,
            icon: Icons.undo_rounded,
            label: 'Undo',
            onTap: onUndo,
          ),
          const SizedBox(width: Gap.xl),
          _circleButton(
            context,
            icon: Icons.refresh_rounded,
            label: 'Reset',
            onTap: onReset,
            danger: true,
          ),
        ],
      ),
    );
  }

  Widget _circleButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback? onTap,
    bool danger = false,
  }) {
    final enabled = onTap != null;
    final base = danger ? context.colors.error : context.colors.primary;
    final tint = enabled ? base : context.extras.textSecondary;
    return Column(
      children: [
        Material(
          color: tint.withValues(alpha: enabled ? 0.12 : 0.06),
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Icon(icon, color: tint),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: context.text.labelSmall?.copyWith(color: tint),
        ),
      ],
    );
  }
}
