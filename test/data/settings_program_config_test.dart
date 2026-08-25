import 'package:drum_coach/data/local/settings_service.dart';
import 'package:drum_coach/features/lessons/models/rudiment.dart';
import 'package:drum_coach/features/program/models/program_config.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await SettingsService.init();
  });
  test('config round-trips', () async {
    expect(SettingsService.programConfig, isNull);
    await SettingsService.setProgramConfig(const ProgramConfig(
        durationWeeks: 8, startDifficulty: Difficulty.intermediate, pool: ProgramPool.padWorkouts));
    final c = SettingsService.programConfig!;
    expect(c.durationWeeks, 8);
    expect(c.startDifficulty, Difficulty.intermediate);
    expect(c.pool, ProgramPool.padWorkouts);
  });
  test('stage index round-trips + defaults to 0', () async {
    expect(SettingsService.programStageIndex, 0);
    await SettingsService.setProgramStageIndex(2);
    expect(SettingsService.programStageIndex, 2);
  });
  test('clear removes config', () async {
    await SettingsService.setProgramConfig(const ProgramConfig(
        durationWeeks: 4, startDifficulty: Difficulty.beginner, pool: ProgramPool.mixed));
    await SettingsService.clearProgramConfig();
    expect(SettingsService.programConfig, isNull);
  });
}
