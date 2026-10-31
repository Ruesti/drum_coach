import 'package:drum_coach/data/local/settings_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('legacy program prefs do not crash and are cleared', () async {
    // Prefs as an installed build with a running training program left them,
    // one value even of an unexpected type.
    SharedPreferences.setMockInitialValues({
      'program_start_date': '2026-09-01T00:00:00.000',
      'program_duration_weeks': 12,
      'program_start_difficulty': 'nonsense',
      'program_pool': 42,
      'program_stage_index': 3,
      'onboarding_done': true,
      'practice_target_min': 25,
    });
    await SettingsService.init();

    final prefs = await SharedPreferences.getInstance();
    for (final key in const [
      'program_start_date',
      'program_duration_weeks',
      'program_start_difficulty',
      'program_pool',
      'program_stage_index',
    ]) {
      expect(prefs.containsKey(key), isFalse, reason: key);
    }
    // Everything else stays.
    expect(SettingsService.isOnboardingDone, isTrue);
    expect(SettingsService.practiceTargetMinutes, 25);

    // Running it again (every start) is harmless.
    await SettingsService.clearLegacyProgramKeys();
    expect(SettingsService.isOnboardingDone, isTrue);
  });
}
