import 'package:drum_coach/data/local/settings_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await SettingsService.init();
  });
  test('sticking letters and count hints default on and round-trip',
      () async {
    expect(SettingsService.showSticking, isTrue);
    expect(SettingsService.showCounts, isTrue);
    await SettingsService.setShowSticking(false);
    await SettingsService.setShowCounts(false);
    expect(SettingsService.showSticking, isFalse);
    expect(SettingsService.showCounts, isFalse);
  });
  test('sheet position is remembered per exercise', () async {
    expect(SettingsService.sheetPositionFor('x'), (line: 0, sheet: false));
    await SettingsService.setSheetPosition('x', line: 3, sheet: true);
    expect(SettingsService.sheetPositionFor('x'), (line: 3, sheet: true));
    expect(SettingsService.sheetPositionFor('y'), (line: 0, sheet: false));
  });
  test('the practice snapshot carries line and mode', () async {
    await SettingsService.savePracticeSnapshot(
        rudimentId: 'x', elapsedSeconds: 30, line: 4, sheet: true);
    final snap = SettingsService.practiceSnapshotFor('x')!;
    expect(snap.line, 4);
    expect(snap.sheet, isTrue);
    expect(snap.elapsedSeconds, 30);
    await SettingsService.savePracticeSnapshot(
        rudimentId: 'x', elapsedSeconds: 30);
    final plain = SettingsService.practiceSnapshotFor('x')!;
    expect(plain.line, 0);
    expect(plain.sheet, isFalse);
    await SettingsService.clearPracticeSnapshot();
    expect(SettingsService.practiceSnapshotFor('x'), isNull);
  });
}
