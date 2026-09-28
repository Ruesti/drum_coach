import 'package:drum_coach/data/local/settings_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await SettingsService.init();
  });
  test('backing is on by default and the switch round-trips', () async {
    expect(SettingsService.backingEnabled, isTrue);
    await SettingsService.setBackingEnabled(false);
    expect(SettingsService.backingEnabled, isFalse);
    await SettingsService.setBackingEnabled(true);
    expect(SettingsService.backingEnabled, isTrue);
  });
  test('backing level defaults to 0.7 and clamps', () async {
    expect(SettingsService.backingLevel, 0.7);
    await SettingsService.setBackingLevel(0.4);
    expect(SettingsService.backingLevel, 0.4);
    await SettingsService.setBackingLevel(3);
    expect(SettingsService.backingLevel, 1.0);
  });
}
