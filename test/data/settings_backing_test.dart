import 'package:drum_coach/data/local/settings_service.dart';
import 'package:drum_coach/features/metronome/backing_styles.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await SettingsService.init();
  });
  test('backing style is remembered per exercise, off is explicit', () async {
    expect(SettingsService.backingStyleFor('a'), isNull);
    await SettingsService.setBackingStyleFor('a', 'rock8');
    expect(SettingsService.backingStyleFor('a'), 'rock8');
    expect(SettingsService.backingStyleFor('b'), isNull);
    await SettingsService.setBackingStyleFor('a', backingOff);
    expect(SettingsService.backingStyleFor('a'), backingOff);
    await SettingsService.setBackingStyleFor('a', null);
    expect(SettingsService.backingStyleFor('a'), isNull);
  });
  test('backing level defaults to 0.7 and clamps', () async {
    expect(SettingsService.backingLevel, 0.7);
    await SettingsService.setBackingLevel(0.4);
    expect(SettingsService.backingLevel, 0.4);
    await SettingsService.setBackingLevel(3);
    expect(SettingsService.backingLevel, 1.0);
  });
}
