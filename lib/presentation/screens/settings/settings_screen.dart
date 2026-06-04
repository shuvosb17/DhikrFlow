import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/di/providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../providers/analytics_providers.dart';
import '../../providers/category_providers.dart';
import '../../providers/settings_provider.dart';
import '../../widgets/app_card.dart';
import '../../widgets/section_header.dart';
import '../categories/reorder_categories_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(Gap.md),
        children: [
          const SectionHeader(title: 'Appearance'),
          AppCard(
            padding: const EdgeInsets.symmetric(
                horizontal: Gap.md, vertical: Gap.sm),
            child: Column(
              children: [
                _ThemeSelector(
                  current: settings.themeMode,
                  onChanged: notifier.setThemeMode,
                ),
              ],
            ),
          ),
          const SizedBox(height: Gap.lg),
          const SectionHeader(title: 'Counter feedback'),
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('Haptic feedback'),
                  subtitle: const Text('Vibrate on every count'),
                  value: settings.hapticsEnabled,
                  onChanged: notifier.toggleHaptics,
                ),
                const Divider(height: 1),
                SwitchListTile(
                  title: const Text('Stronger pulse at milestones'),
                  subtitle:
                      const Text('Heavier vibration when a cycle completes'),
                  value: settings.vibrateAtTarget,
                  onChanged: notifier.toggleVibrateAtTarget,
                ),
                const Divider(height: 1),
                SwitchListTile(
                  title: const Text('Keep screen on while counting'),
                  value: settings.keepScreenOn,
                  onChanged: notifier.toggleKeepScreenOn,
                ),
              ],
            ),
          ),
          const SizedBox(height: Gap.lg),
          const SectionHeader(title: 'Categories'),
          AppCard(
            padding: EdgeInsets.zero,
            child: ListTile(
              leading: const Icon(Icons.reorder_rounded),
              title: const Text('Reorder categories'),
              subtitle: const Text('Arrange your home screen order'),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                    builder: (_) => const ReorderCategoriesScreen()),
              ),
            ),
          ),
          const SizedBox(height: Gap.lg),
          const SectionHeader(
            title: 'Backup & sync',
            subtitle: 'Your data is stored safely on this device',
          ),
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                const ListTile(
                  leading: Icon(Icons.cloud_outlined),
                  title: Text('Cloud sync'),
                  subtitle: Text('Google Sign-In · coming soon'),
                  trailing: _SoonBadge(),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.delete_sweep_outlined),
                  title: const Text('Reset all data'),
                  subtitle: const Text('Remove every category and record'),
                  onTap: () => _confirmReset(context, ref),
                ),
              ],
            ),
          ),
          const SizedBox(height: Gap.lg),
          const SectionHeader(title: 'About'),
          const AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(AppConstants.appName,
                    style: TextStyle(fontWeight: FontWeight.w700)),
                SizedBox(height: 4),
                Text(AppConstants.appTagline),
                SizedBox(height: 8),
                Text('Version 1.0.0', style: TextStyle(fontSize: 12)),
              ],
            ),
          ),
          const SizedBox(height: Gap.xxl),
        ],
      ),
    );
  }

  Future<void> _confirmReset(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset all data?'),
        content: const Text(
          'This permanently deletes every category, count and record. '
          'Default categories will be recreated. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style:
                FilledButton.styleFrom(backgroundColor: context.colors.error),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(appDatabaseProvider).clearAll();
      ref.invalidate(categoriesProvider);
      ref.invalidate(todayTotalProvider);
      ref.invalidate(streakInfoProvider);
      ref.invalidate(weeklyAnalyticsProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('All data has been reset.')),
        );
      }
    }
  }
}

class _ThemeSelector extends StatelessWidget {
  const _ThemeSelector({required this.current, required this.onChanged});

  final ThemeMode current;
  final ValueChanged<ThemeMode> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Gap.sm),
      child: SegmentedButton<ThemeMode>(
        segments: const [
          ButtonSegment(
            value: ThemeMode.light,
            icon: Icon(Icons.light_mode_outlined),
            label: Text('Light'),
          ),
          ButtonSegment(
            value: ThemeMode.system,
            icon: Icon(Icons.brightness_auto_outlined),
            label: Text('Auto'),
          ),
          ButtonSegment(
            value: ThemeMode.dark,
            icon: Icon(Icons.dark_mode_outlined),
            label: Text('Dark'),
          ),
        ],
        selected: {current},
        showSelectedIcon: false,
        onSelectionChanged: (s) => onChanged(s.first),
      ),
    );
  }
}

class _SoonBadge extends StatelessWidget {
  const _SoonBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: context.extras.accent.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        'Soon',
        style: context.text.labelSmall?.copyWith(
          color: context.extras.accent,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
