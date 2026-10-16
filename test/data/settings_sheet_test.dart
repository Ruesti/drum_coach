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
  test('the last line is remembered per exercise', () async {
    expect(SettingsService.lastLineFor('x'), isNull);
    await SettingsService.setLastLine('x', 3);
    expect(SettingsService.lastLineFor('x'), 3);
    expect(SettingsService.lastLineFor('y'), isNull);
  });
  test('sequence repeats default to 2 and are clamped to 1–4', () async {
    expect(SettingsService.sequenceRepeats, 2);
    await SettingsService.setSequenceRepeats(9);
    expect(SettingsService.sequenceRepeats, 4);
    await SettingsService.setSequenceRepeats(0);
    expect(SettingsService.sequenceRepeats, 1);
  });
  test('the practice snapshot carries lines and start', () async {
    await SettingsService.savePracticeSnapshot(
        rudimentId: 'x', elapsedSeconds: 30, lines: [0, 2, 4], start: 1);
    final snap = SettingsService.practiceSnapshotFor('x')!;
    expect(snap.lines, [0, 2, 4]);
    expect(snap.start, 1);
    expect(snap.elapsedSeconds, 30);
    await SettingsService.savePracticeSnapshot(
        rudimentId: 'x', elapsedSeconds: 30);
    final plain = SettingsService.practiceSnapshotFor('x')!;
    expect(plain.lines, [0]);
    expect(plain.start, 0);
    await SettingsService.clearPracticeSnapshot();
    expect(SettingsService.practiceSnapshotFor('x'), isNull);
  });
  test('an old snapshot (single line) still restores', () async {
    SharedPreferences.setMockInitialValues({
      'practice_snap_id': 'x',
      'practice_snap_elapsed': 30,
      'practice_snap_time': DateTime.now().toIso8601String(),
      'practice_snap_line': 5,
    });
    await SettingsService.init();
    final snap = SettingsService.practiceSnapshotFor('x')!;
    expect(snap.lines, [5]);
    expect(snap.start, 0);
  });
}
