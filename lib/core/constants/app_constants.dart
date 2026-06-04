/// App-wide constant values.
class AppConstants {
  AppConstants._();

  static const String appName = 'DhikrFlow';
  static const String appTagline = 'Digital Tasbih & Remembrance';

  // Shared preferences keys
  static const String prefThemeMode = 'pref_theme_mode';
  static const String prefHapticsEnabled = 'pref_haptics_enabled';
  static const String prefSoundEnabled = 'pref_sound_enabled';
  static const String prefKeepScreenOn = 'pref_keep_screen_on';
  static const String prefOnboardingDone = 'pref_onboarding_done';
  static const String prefVibrateAtTarget = 'pref_vibrate_at_target';
  static const String prefCounterMilestone = 'pref_counter_milestone';

  // Database
  static const String dbName = 'dhikr_counter.db';
  static const int dbVersion = 1;

  // Defaults
  static const int defaultMilestone = 33; // common tasbih cycle
  static const int defaultDailyTarget = 100;
}

/// Spacing scale used throughout the UI for consistent rhythm.
class Gap {
  Gap._();
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
}
