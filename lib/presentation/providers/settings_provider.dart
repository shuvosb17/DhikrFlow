import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/app_constants.dart';
import '../../core/di/providers.dart';

/// Immutable bundle of user preferences.
@immutable
class AppSettings {
  const AppSettings({
    this.themeMode = ThemeMode.system,
    this.hapticsEnabled = true,
    this.soundEnabled = false,
    this.keepScreenOn = true,
    this.vibrateAtTarget = true,
    this.milestone = AppConstants.defaultMilestone,
  });

  final ThemeMode themeMode;
  final bool hapticsEnabled;
  final bool soundEnabled;
  final bool keepScreenOn;
  final bool vibrateAtTarget;

  /// Counter milestone for stronger haptic / visual feedback (e.g. every 33).
  final int milestone;

  AppSettings copyWith({
    ThemeMode? themeMode,
    bool? hapticsEnabled,
    bool? soundEnabled,
    bool? keepScreenOn,
    bool? vibrateAtTarget,
    int? milestone,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      hapticsEnabled: hapticsEnabled ?? this.hapticsEnabled,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      keepScreenOn: keepScreenOn ?? this.keepScreenOn,
      vibrateAtTarget: vibrateAtTarget ?? this.vibrateAtTarget,
      milestone: milestone ?? this.milestone,
    );
  }
}

class SettingsNotifier extends StateNotifier<AppSettings> {
  SettingsNotifier(this._prefs) : super(_load(_prefs));

  final SharedPreferences _prefs;

  static AppSettings _load(SharedPreferences prefs) {
    final modeIndex = prefs.getInt(AppConstants.prefThemeMode);
    return AppSettings(
      themeMode: modeIndex == null
          ? ThemeMode.system
          : ThemeMode.values[modeIndex.clamp(0, ThemeMode.values.length - 1)],
      hapticsEnabled: prefs.getBool(AppConstants.prefHapticsEnabled) ?? true,
      soundEnabled: prefs.getBool(AppConstants.prefSoundEnabled) ?? false,
      keepScreenOn: prefs.getBool(AppConstants.prefKeepScreenOn) ?? true,
      vibrateAtTarget: prefs.getBool(AppConstants.prefVibrateAtTarget) ?? true,
      milestone: prefs.getInt(AppConstants.prefCounterMilestone) ??
          AppConstants.defaultMilestone,
    );
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = state.copyWith(themeMode: mode);
    await _prefs.setInt(AppConstants.prefThemeMode, mode.index);
  }

  Future<void> toggleHaptics(bool value) async {
    state = state.copyWith(hapticsEnabled: value);
    await _prefs.setBool(AppConstants.prefHapticsEnabled, value);
  }

  Future<void> toggleSound(bool value) async {
    state = state.copyWith(soundEnabled: value);
    await _prefs.setBool(AppConstants.prefSoundEnabled, value);
  }

  Future<void> toggleKeepScreenOn(bool value) async {
    state = state.copyWith(keepScreenOn: value);
    await _prefs.setBool(AppConstants.prefKeepScreenOn, value);
  }

  Future<void> toggleVibrateAtTarget(bool value) async {
    state = state.copyWith(vibrateAtTarget: value);
    await _prefs.setBool(AppConstants.prefVibrateAtTarget, value);
  }

  Future<void> setMilestone(int value) async {
    state = state.copyWith(milestone: value);
    await _prefs.setInt(AppConstants.prefCounterMilestone, value);
  }
}

final settingsProvider =
    StateNotifierProvider<SettingsNotifier, AppSettings>((ref) {
  return SettingsNotifier(ref.watch(sharedPreferencesProvider));
});
