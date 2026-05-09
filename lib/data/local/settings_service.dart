import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  SettingsService._();

  static late SharedPreferences _prefs;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  static bool get isOnboardingDone => _prefs.getBool('onboarding_done') ?? false;
  static Future<void> setOnboardingDone() => _prefs.setBool('onboarding_done', true);

  static int get practiceTargetMinutes => _prefs.getInt('practice_target_min') ?? 20;
  static Future<void> setPracticeTargetMinutes(int v) =>
      _prefs.setInt('practice_target_min', v);

  static bool get hapticsEnabled => _prefs.getBool('haptics_enabled') ?? true;
  static Future<void> setHapticsEnabled(bool v) =>
      _prefs.setBool('haptics_enabled', v);

  static int get reminderHour => _prefs.getInt('reminder_hour') ?? 18;
  static int get reminderMinute => _prefs.getInt('reminder_minute') ?? 0;
  static Future<void> setReminderTime(int hour, int minute) async {
    await _prefs.setInt('reminder_hour', hour);
    await _prefs.setInt('reminder_minute', minute);
  }

  static bool get reminderEnabled => _prefs.getBool('reminder_enabled') ?? true;
  static Future<void> setReminderEnabled(bool v) =>
      _prefs.setBool('reminder_enabled', v);
}
