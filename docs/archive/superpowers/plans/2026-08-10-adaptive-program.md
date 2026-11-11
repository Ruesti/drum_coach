# Adaptive Training Program (SP4) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax.

**Goal:** Replace the fixed 84-day program with a configurable (duration / start-difficulty / pool), readiness-driven adaptive program: difficulty stages advance when the user is ready; the chosen duration is a pacing reference, not a calendar.

**Architecture:** A `ProgramConfig` (persisted in SharedPreferences via `SettingsService`) drives a pure generator. Difficulty **stages** run from the start difficulty upward; the user's **stage index** (persisted) advances via a pure **readiness gate** (clean tempo at target OR mastery ≥ proficient), reusing `CleanTempo` + `RudimentProgress`. The exercise **pool** filters the catalog by the SP3 `collection` field. Existing `ProgramDay`/`ExerciseBlock`/`DayType` structures + the clean-pass tempo ladder are reused. Providers keep their signatures (only bodies change + methods added) and config is read statically — **no build_runner regeneration is required**.

**Tech Stack:** Flutter/Dart, Riverpod (codegen — do NOT add new @riverpod providers), Isar (reuse), SharedPreferences, go_router, flutter_test.

## Global Constraints

- Do NOT add new `@riverpod` providers or change existing provider signatures (avoids a build_runner run). Change provider **bodies** and add **methods** only. Read `ProgramConfig` statically from `SettingsService`.
- Backward compatible: a legacy start (only `program_start_date`, no config) is treated as "not configured" → the setup screen shows (see Task 8/9). New fields/keys default cleanly.
- Reuse existing signals: `CleanTempo` (clean tempo per exercise id), `RudimentProgress.mastery`/`bestBpm`, `Difficulty` enum, the SP3 `Rudiment.collection` field, `rudimentsProvider` (base catalog + `allEtudes`).
- Difficulty order: `Difficulty.values` = [beginner, intermediate, advanced, professional] (indices 0..3).
- Keep pure generator functions I/O-free and unit-tested (mirrors the existing `program_provider.dart` style).
- Tests: `flutter test`; analyze: `flutter analyze`. Run from the worktree root. Commit after each task with the project trailer (`Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>` / `Claude-Session: https://claude.ai/code/session_01MaUau8L3orqhR57QvKubqC`).

## File Structure

- `lib/features/program/models/program_config.dart` — NEW: `ProgramConfig`, `ProgramPool`.
- `lib/features/program/program_generator.dart` — NEW: pure `programPoolExercises`, `effectiveStages`, `exercisesForStage`, `stageFocus`, `isStageComplete`, `buildAdaptiveProgramDay`, `programPacing` (+ `PacingStatus`).
- `lib/data/local/settings_service.dart` — config + stage-index persistence.
- `lib/features/program/program_provider.dart` — rewire bodies (`trainingProgram`, `currentProgramDay`) + `ProgramController` methods (`startWithConfig`, `advanceStageIfReady`); make `dayNumberOn`/`isScheduledRestDay` take `totalDays`.
- `lib/features/program/program_setup_screen.dart` — NEW: setup UI.
- `lib/features/program/program_screen.dart` — `_NotStarted` → setup; `_DayView` header (stage + pacing); level-up moment.
- `lib/app/router.dart` — `/program/setup` route.
- Tests: `program_config_test.dart`, `program_generator_test.dart` (rewrite the existing one), `program_setup_screen_test.dart`, and update `test/features/stats/streak_rest_test.dart` for the `totalDays` param.

---

### Task 1: ProgramConfig + ProgramPool model

**Files:** Create `lib/features/program/models/program_config.dart`; Test `test/features/program/program_config_test.dart`.

**Produces:**
```dart
enum ProgramPool { basicStrokes, newExercises, mixed }
extension ProgramPoolLabel on ProgramPool { String get label; }  // 'Klassische Schlagübungen' / 'Neue Übungen' / 'Gemischt'
class ProgramConfig {
  final int durationWeeks;
  final Difficulty startDifficulty;
  final ProgramPool pool;
  const ProgramConfig({required this.durationWeeks, required this.startDifficulty, required this.pool});
  int get totalDays => durationWeeks * 7;
}
```

- [ ] **Step 1: Failing test** `test/features/program/program_config_test.dart`:
```dart
import 'package:drum_coach/features/lessons/models/rudiment.dart';
import 'package:drum_coach/features/program/models/program_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('totalDays = weeks × 7', () {
    const c = ProgramConfig(durationWeeks: 8, startDifficulty: Difficulty.beginner, pool: ProgramPool.mixed);
    expect(c.totalDays, 56);
  });
  test('pool labels', () {
    expect(ProgramPool.basicStrokes.label, 'Klassische Schlagübungen');
    expect(ProgramPool.newExercises.label, 'Neue Übungen');
    expect(ProgramPool.mixed.label, 'Gemischt');
  });
}
```
- [ ] **Step 2:** run → FAIL.
- [ ] **Step 3:** Create the file:
```dart
import '../../lessons/models/rudiment.dart';

/// Which exercises the program draws from.
enum ProgramPool { basicStrokes, newExercises, mixed }

extension ProgramPoolLabel on ProgramPool {
  String get label => switch (this) {
        ProgramPool.basicStrokes => 'Klassische Schlagübungen',
        ProgramPool.newExercises => 'Neue Übungen',
        ProgramPool.mixed => 'Gemischt',
      };
}

/// User-chosen program configuration (persisted).
class ProgramConfig {
  final int durationWeeks; // pacing target
  final Difficulty startDifficulty;
  final ProgramPool pool;
  const ProgramConfig({
    required this.durationWeeks,
    required this.startDifficulty,
    required this.pool,
  });

  int get totalDays => durationWeeks * 7;
}
```
- [ ] **Step 4:** run → PASS.
- [ ] **Step 5:** analyze clean; commit `feat(program): ProgramConfig + ProgramPool`.

---

### Task 2: Config persistence in SettingsService

**Files:** Modify `lib/data/local/settings_service.dart`; Test `test/data/settings_program_config_test.dart`.

**Produces:** `SettingsService.programConfig` (getter → `ProgramConfig?`, null if not configured), `setProgramConfig(ProgramConfig)`, `clearProgramConfig()`, `programStageIndex` (getter → int, default 0), `setProgramStageIndex(int)`. Keys: `program_duration_weeks`, `program_start_difficulty` (enum `.name`), `program_pool` (enum `.name`), `program_stage_index`.

- [ ] **Step 1: Failing test** — use `SharedPreferences.setMockInitialValues({})` then `SettingsService.init()`:
```dart
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
        durationWeeks: 8, startDifficulty: Difficulty.intermediate, pool: ProgramPool.newExercises));
    final c = SettingsService.programConfig!;
    expect(c.durationWeeks, 8);
    expect(c.startDifficulty, Difficulty.intermediate);
    expect(c.pool, ProgramPool.newExercises);
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
```
- [ ] **Step 2:** run → FAIL.
- [ ] **Step 3:** Add to `SettingsService` (import `program_config.dart` + `rudiment.dart`):
```dart
  static ProgramConfig? get programConfig {
    final weeks = _prefs.getInt('program_duration_weeks');
    final diff = _prefs.getString('program_start_difficulty');
    final pool = _prefs.getString('program_pool');
    if (weeks == null || diff == null || pool == null) return null;
    return ProgramConfig(
      durationWeeks: weeks,
      startDifficulty: Difficulty.values.firstWhere((d) => d.name == diff,
          orElse: () => Difficulty.beginner),
      pool: ProgramPool.values.firstWhere((p) => p.name == pool,
          orElse: () => ProgramPool.mixed),
    );
  }

  static Future<void> setProgramConfig(ProgramConfig c) async {
    await _prefs.setInt('program_duration_weeks', c.durationWeeks);
    await _prefs.setString('program_start_difficulty', c.startDifficulty.name);
    await _prefs.setString('program_pool', c.pool.name);
  }

  static Future<void> clearProgramConfig() async {
    await _prefs.remove('program_duration_weeks');
    await _prefs.remove('program_start_difficulty');
    await _prefs.remove('program_pool');
    await _prefs.remove('program_stage_index');
  }

  static int get programStageIndex => _prefs.getInt('program_stage_index') ?? 0;
  static Future<void> setProgramStageIndex(int i) =>
      _prefs.setInt('program_stage_index', i);
```
- [ ] **Step 4:** run → PASS.
- [ ] **Step 5:** analyze clean; commit `feat(settings): persist ProgramConfig + stage index`.

---

### Task 3: Pool selection + stages (pure)

**Files:** Create `lib/features/program/program_generator.dart`; Test `test/features/program/program_generator_test.dart` (REWRITE the existing file — the old fixed-program tests are replaced).

**Produces:**
```dart
List<Rudiment> programPoolExercises(List<Rudiment> all, ProgramPool pool);
List<Rudiment> exercisesForStage(List<Rudiment> poolExercises, Difficulty stage);
List<Difficulty> effectiveStages(List<Rudiment> poolExercises, Difficulty start); // start..professional with content
Rudiment stageFocus(List<Rudiment> stageExercises); // the first (stable) exercise
```

- [ ] **Step 1: Failing test** (create fixtures — a few `Rudiment`s with/without `collection` and varied `difficulty`):
```dart
import 'package:drum_coach/features/lessons/models/rudiment.dart';
import 'package:drum_coach/features/program/models/program_config.dart';
import 'package:drum_coach/features/program/program_generator.dart';
import 'package:flutter_test/flutter_test.dart';

Rudiment _r(String id, Difficulty d, {ExerciseCollection? c}) => Rudiment(
    id: id, name: id, description: '', minBpm: 60, targetBpm: 120,
    difficulty: d, sticking: const [StrokeBeat(hand: Hand.right)], collection: c);

void main() {
  final all = [
    _r('base_b', Difficulty.beginner),
    _r('base_i', Difficulty.intermediate),
    _r('etu_b', Difficulty.beginner, c: ExerciseCollection.rudimentEtudes),
    _r('etu_a', Difficulty.advanced, c: ExerciseCollection.rudimentEtudes),
  ];
  test('pool filtering', () {
    expect(programPoolExercises(all, ProgramPool.basicStrokes).map((r) => r.id), ['base_b', 'base_i']);
    expect(programPoolExercises(all, ProgramPool.newExercises).map((r) => r.id), ['etu_b', 'etu_a']);
    expect(programPoolExercises(all, ProgramPool.mixed).length, 4);
  });
  test('exercisesForStage filters by difficulty', () {
    final pool = programPoolExercises(all, ProgramPool.mixed);
    expect(exercisesForStage(pool, Difficulty.beginner).map((r) => r.id), ['base_b', 'etu_b']);
  });
  test('effectiveStages skips empty tiers', () {
    final pool = programPoolExercises(all, ProgramPool.newExercises); // beginner + advanced only
    expect(effectiveStages(pool, Difficulty.beginner),
        [Difficulty.beginner, Difficulty.advanced]); // intermediate + professional empty → skipped
  });
  test('stageFocus is the first exercise', () {
    final pool = programPoolExercises(all, ProgramPool.mixed);
    expect(stageFocus(exercisesForStage(pool, Difficulty.beginner)).id, 'base_b');
  });
}
```
- [ ] **Step 2:** run → FAIL.
- [ ] **Step 3:** Create `program_generator.dart`:
```dart
import '../lessons/models/rudiment.dart';
import 'models/program_config.dart';

List<Rudiment> programPoolExercises(List<Rudiment> all, ProgramPool pool) =>
    switch (pool) {
      ProgramPool.basicStrokes => all.where((r) => r.collection == null).toList(),
      ProgramPool.newExercises => all.where((r) => r.collection != null).toList(),
      ProgramPool.mixed => List<Rudiment>.of(all),
    };

List<Rudiment> exercisesForStage(List<Rudiment> poolExercises, Difficulty stage) =>
    poolExercises.where((r) => r.difficulty == stage).toList();

/// Difficulty tiers from [start] up to professional that actually have
/// exercises in [poolExercises] (empty tiers are skipped).
List<Difficulty> effectiveStages(List<Rudiment> poolExercises, Difficulty start) {
  final out = <Difficulty>[];
  for (final d in Difficulty.values) {
    if (d.index < start.index) continue;
    if (exercisesForStage(poolExercises, d).isNotEmpty) out.add(d);
  }
  return out;
}

/// The stable focus exercise of a stage (first in list).
Rudiment stageFocus(List<Rudiment> stageExercises) => stageExercises.first;
```
- [ ] **Step 4:** run → PASS.
- [ ] **Step 5:** analyze clean; commit `feat(program): pool selection + difficulty stages`.

---

### Task 4: Readiness gate (pure)

**Files:** Modify `lib/features/program/program_generator.dart`; Test extend `program_generator_test.dart`.

**Produces:**
```dart
bool isStageComplete(Rudiment focus, {required int? cleanBpm, required MasteryLevel? mastery});
```
Complete when `cleanBpm != null && cleanBpm >= focus.targetBpm` OR `mastery != null && mastery.index >= MasteryLevel.proficient.index`.

- [ ] **Step 1: Failing test** (import `MasteryLevel` from `lib/data/local/models/rudiment_progress.dart`):
```dart
  group('isStageComplete', () {
    final focus = _r('f', Difficulty.beginner)..noSuchMethod; // use a fixture with targetBpm 120
    final f = _r('f', Difficulty.beginner); // targetBpm 120
    test('ready when clean tempo reached target', () {
      expect(isStageComplete(f, cleanBpm: 120, mastery: null), isTrue);
      expect(isStageComplete(f, cleanBpm: 119, mastery: null), isFalse);
    });
    test('ready when mastery proficient+', () {
      expect(isStageComplete(f, cleanBpm: null, mastery: MasteryLevel.proficient), isTrue);
      expect(isStageComplete(f, cleanBpm: null, mastery: MasteryLevel.developing), isFalse);
    });
    test('not ready with no signals', () {
      expect(isStageComplete(f, cleanBpm: null, mastery: null), isFalse);
    });
  });
```
(Remove the bogus `noSuchMethod` line — use the `_r` helper; confirm `MasteryLevel` values include `proficient`/`developing` by reading `rudiment_progress.dart` first.)
- [ ] **Step 2:** run → FAIL.
- [ ] **Step 3:** Add to `program_generator.dart` (import `../../data/local/models/rudiment_progress.dart`):
```dart
bool isStageComplete(Rudiment focus,
        {required int? cleanBpm, required MasteryLevel? mastery}) =>
    (cleanBpm != null && cleanBpm >= focus.targetBpm) ||
    (mastery != null && mastery.index >= MasteryLevel.proficient.index);
```
- [ ] **Step 4:** run → PASS.
- [ ] **Step 5:** analyze clean; commit `feat(program): stage readiness gate`.

---

### Task 5: buildAdaptiveProgramDay + pacing (pure)

**Files:** Modify `lib/features/program/program_generator.dart`; Test extend `program_generator_test.dart`.

**Produces:**
```dart
enum PacingStatus { behind, onTrack, ahead }
class ProgramPacing { final int nominalWeek; final int totalStages; final int expectedStageIndex; final PacingStatus status; }
ProgramPacing programPacing({required int durationWeeks, required int totalStages, required int stageIndex, required int dayNumber});
ProgramDay buildAdaptiveProgramDay({
  required List<Rudiment> stageExercises, // exercises of the current stage
  required Difficulty stage,
  required int dayNumber,
  required int totalDays,
  int? Function(String id)? cleanBpmFor,
});
```
`buildAdaptiveProgramDay`: uses `dayTypeForDayNumber` (existing weekly rhythm); focus = `stageFocus(stageExercises)`; technique line rotates `stageExercises[dayNumber % stageExercises.length]`; warmup uses `'single_stroke_roll'`; tempo ladder on the focus with `startBpm = cleanBpmFor?.call(focus.id) ?? focus.minBpm`, `cleanPassRequired: true`. Builds a `ProgramPhase` from the stage (name = `stage.label`, focus text = a per-stage hint, weekStart/End derived, startBpm = focus.minBpm) so `ProgramDay.phase` is populated. `pacing`: `nominalWeek = ((dayNumber-1)~/7)+1`; `expectedStageIndex = ((nominalWeek-1) * totalStages ~/ durationWeeks).clamp(0, totalStages-1)`; status by comparing `stageIndex` to `expectedStageIndex`.

- [ ] **Step 1: Failing test** covering: pacing (ahead/onTrack/behind for representative inputs), and `buildAdaptiveProgramDay` producing warmup+technique+tempoLadder on a practice day with the focus as the ladder line and startBpm from cleanBpmFor. (Write concrete assertions; keep the `dayTypeForDayNumber` import from `program_provider.dart`.)
- [ ] **Step 2:** run → FAIL.
- [ ] **Step 3:** Implement (reuse `dayTypeForDayNumber` from `program_provider.dart`; `ExerciseBlock`/`ProgramDay`/`ProgramPhase`/`BlockType`/`Variant` from `models/training_program.dart`). Add a small `_stageHint(Difficulty)` for the focus text.
- [ ] **Step 4:** run → PASS.
- [ ] **Step 5:** analyze clean; commit `feat(program): adaptive day builder + pacing`.

---

### Task 6: Make dayNumberOn/isScheduledRestDay duration-aware

**Files:** Modify `lib/features/program/program_provider.dart`; update `test/features/stats/streak_rest_test.dart` and any caller.

- [ ] **Step 1:** Read `streak_rest_test.dart` and grep callers of `isScheduledRestDay` / `dayNumberOn` / `programTotalDays` (`grep -rn "isScheduledRestDay\|dayNumberOn\|programTotalDays" lib test`).
- [ ] **Step 2:** Change signatures to accept the window length: `int? dayNumberOn(DateTime start, DateTime date, int totalDays)` and `bool isScheduledRestDay(DateTime start, DateTime date, int totalDays)`. Keep the const `programTotalDays = 84` ONLY as a fallback default the callers pass when no config exists. Update every caller to pass `SettingsService.programConfig?.totalDays ?? programTotalDays`.
- [ ] **Step 3:** Update `streak_rest_test.dart` to pass the `totalDays` argument.
- [ ] **Step 4:** `flutter test test/features/stats/streak_rest_test.dart` + `flutter test test/features/program/program_generator_test.dart` → PASS.
- [ ] **Step 5:** analyze clean; commit `refactor(program): duration-aware day-window helpers`.

---

### Task 7: Rewire providers to config + adaptive stage

**Files:** Modify `lib/features/program/program_provider.dart`. Do NOT change provider signatures or add @riverpod providers (no build_runner).

- [ ] **Step 1:** `trainingProgram` body → build a lightweight `TrainingProgram` (name 'Adaptives Programm', description, totalWeeks from config or a default) from `SettingsService.programConfig`. If no config, return a minimal placeholder (the screen shows setup anyway).
- [ ] **Step 2:** `currentProgramDay` body → read `config = SettingsService.programConfig`; if null OR `programStartDate == null` return null. Compute `dayNumber = dayNumberOn(start, now, config.totalDays)`; if null return null (finished). Build the pool: `pool = programPoolExercises(ref.watch(rudimentsProvider), config.pool)`; `stages = effectiveStages(pool, config.startDifficulty)`; clamp `stageIndex = SettingsService.programStageIndex` to stages; `stageExercises = exercisesForStage(pool, stages[stageIndex])`; return `buildAdaptiveProgramDay(stageExercises: stageExercises, stage: stages[stageIndex], dayNumber: dayNumber, totalDays: config.totalDays, cleanBpmFor: (k) => clean[k])` (fold in `cleanTempoNotifierProvider`).
- [ ] **Step 3:** `ProgramController`: add `Future<void> startWithConfig(ProgramConfig c)` (setProgramConfig + setProgramStageIndex(0) + setProgramStartDate(now) + invalidate currentProgramDay); change `reset()` to also `clearProgramConfig()`. Add `Future<void> advanceStageIfReady()`: read config + pool + stages + stageIndex; if `stageIndex < stages.length-1` and `isStageComplete(stageFocus(currentStageExercises), cleanBpm: clean[focus.id], mastery: <RudimentProgress.mastery for focus.id from IsarService>)` → `setProgramStageIndex(stageIndex+1)` and invalidate. Return whether it advanced (for the level-up UI).
- [ ] **Step 4:** Ensure `programDay(dayNumber)` provider still compiles (it's used elsewhere) — either keep it delegating to the adaptive builder for the current stage, or leave it for the current day only. Simplest: keep `currentProgramDay` as the single source; if `programDay` is only used by `currentProgramDay`, inline it. Grep usages first.
- [ ] **Step 5:** `flutter test` (program + streak + full) → green; `flutter analyze lib/features/program` clean. Commit `feat(program): config-driven adaptive providers + stage advance`.

> Note: no `.g.dart` regeneration — only bodies/methods changed. If the analyzer reports a generated-provider mismatch, STOP and report (do not run build_runner without escalating).

---

### Task 8: Setup screen + route

**Files:** Create `lib/features/program/program_setup_screen.dart`; modify `lib/app/router.dart`; Test `test/features/program/program_setup_screen_test.dart`.

- [ ] **Step 1: Failing widget test** — pump `ProgramSetupScreen` in `ProviderScope` + `MaterialApp`; expect the three choice groups render (duration chips 4/8/12, difficulty options, pool options) and a "Programm starten" button.
- [ ] **Step 2:** run → FAIL.
- [ ] **Step 3:** Implement `ProgramSetupScreen` (ConsumerStatefulWidget): three selectors (duration 4/8/12 weeks; startDifficulty beginner/intermediate/advanced; pool via `ProgramPool.values` labels), a start button that calls `ref.read(programControllerProvider.notifier).startWithConfig(ProgramConfig(...))` then `context.pop()` (or navigates to `/program`). Match the dark styling of `program_screen.dart`/`practice_session_screen.dart` (chips like `_TimerGoalRow`).
- [ ] **Step 4:** Route in `router.dart`: `GoRoute(path: '/program/setup', builder: (_, __) => const ProgramSetupScreen())`.
- [ ] **Step 5:** widget test → PASS; `flutter test` full; analyze clean. Commit `feat(program): setup screen + route`.

---

### Task 9: Program screen — setup entry, stage header, level-up

**Files:** Modify `lib/features/program/program_screen.dart`.

- [ ] **Step 1:** `_NotStarted` (shown when `programConfig == null`): replace the direct `start()` button with a "Programm einrichten" button that `context.push('/program/setup')`. Keep a short intro.
- [ ] **Step 2:** `_DayView` / `_DayHeader`: show the current stage + pacing. Read pacing via a small helper (compute from config + stageIndex + day.dayNumber using `programPacing`), render "Woche X/N · Stufe: <difficulty.label> · <voraus|im Plan|hinterher>". Replace the hardcoded `programTotalDays` in the header with `config.totalDays`.
- [ ] **Step 3:** Level-up moment: after a clean pass (`_askCleanPass` → `recordCleanPass`), call `ref.read(programControllerProvider.notifier).advanceStageIfReady()`; if it returns true, show a SnackBar/dialog "Level up! Stufe: <new difficulty>".
- [ ] **Step 4:** `flutter test` full (existing program widget tests may need light updates); analyze clean. Commit `feat(program): setup entry, stage/pacing header, level-up`.

---

### Task 10: Verification pass

- [ ] `flutter test` — all green.
- [ ] `flutter analyze` — no new errors.
- [ ] Manual data-flow check: start with each pool + start difficulty; confirm the day builds a valid focus from the right pool; simulate a clean pass to target → stage advances.
- [ ] Device pass (bundled): setup flow, a session, a stage advance, pool switch.
- [ ] Update PR #8 to note SP4 landed.

## Self-Review

- Config → Task 1; persistence → Task 2; pool/stages → Task 3; readiness → Task 4; day builder + pacing → Task 5; duration-aware helpers → Task 6; provider rewire + advance → Task 7; setup screen → Task 8; screen updates → Task 9; verify → Task 10.
- No new @riverpod providers; config read statically → no build_runner. Streak seam handled in Task 6. Existing `program_generator_test.dart` rewritten (Task 3).
- Type consistency: `ProgramConfig{durationWeeks,startDifficulty,pool,totalDays}`, `ProgramPool`, `programPoolExercises`/`exercisesForStage`/`effectiveStages`/`stageFocus`/`isStageComplete(focus, cleanBpm:, mastery:)`/`buildAdaptiveProgramDay(...)`/`programPacing(...)`/`PacingStatus` — consistent across tasks.
```
