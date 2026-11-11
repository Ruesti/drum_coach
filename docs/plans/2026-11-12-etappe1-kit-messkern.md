# Etappe 1 — Kit-Messkern + ein Gate: Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** A Flutter app (Linux, Android, Windows) that reads an E-drum kit via MIDI, plays a click, measures every hit against the target pattern (timing in ms latency-compensated, velocity, right/wrong instrument, missing/extra) and decides two gates from those numbers: the entry exercise and "Basic Rock Beat".

**Architecture:** Three layers, built from the bottom. `lib/measure/` (pure Dart: kit, strokes, targets, alignment, latency, session records), `lib/skill/` (pure Dart: metrics + gates), `lib/content/` (pure Dart: the two exercises). Flutter/plugin code lives only in `lib/midi/`, `lib/audio/`, `lib/run/`, `lib/ui/`, `lib/app/`. Analysis is a pure function of a recorded session (`SessionRecord` → `SessionAnalysis`), so every result can be replayed from its JSONL file.

**Tech Stack:** Flutter (Dart ≥ 3.4), `flutter_midi_command` 1.4.0 with the patched Linux plugin from `legacy-v0-stapel`, `flutter_soloud` (click), `flutter_riverpod` (no codegen), `shared_preferences`, `path_provider`.

**Spec:** `docs/KONZEPT.md` (Abschnitte 1–6) and `docs/BERICHT_KIT_ETAPPE1_§0.md` (module reuse table, Abschnitt 4 numbers, Abschnitt 5 decisions). Legacy code is taken from tag `legacy-v0-stapel` (`6c754a9`) with `git show legacy-v0-stapel:<path> > <newpath>`. Old paths below are relative to that tag.

## Global Constraints

- Platforms: Linux, Android, Windows (E4). No platform-only code outside `lib/midi/` and `lib/audio/`.
- `lib/measure/`, `lib/skill/`, `lib/content/` import nothing from `package:flutter` or plugins (enforced by Task 1's architecture test).
- Instrument: E-drum kit via MIDI. No microphone, no pad mode, no self-rating, no AI coaching, no notifications.
- Per-hit quantities (KONZEPT §5): timing deviation in ms (latency-compensated), velocity, instrument right/wrong, hit missing/extra. **Hands are never measured or shown.**
- "No number is better than a wrong one": without a latency calibration for the active device, no gate verdict is produced.
- Gate "Basic Rock Beat" (E3): 16 bars at 80 BPM; hit rate per voice ≥ 0.95; wrong instrument ≤ 0.02 of targets; extra ≤ 0.05 of targets; |timing median| ≤ 15 ms; timing spread (population SD) ≤ 20 ms; snare velocity population SD ≤ 12 (MIDI 0–127, placeholder).
- Entry exercise (KONZEPT §3 + E3): quarter hi-hat, kick on 1 and 3, 8 bars at 70 BPM; pass = hit rate per voice ≥ 0.80 and no gap between hits longer than one bar; no timing criterion. Fail text: "Start with the basics first" (KONZEPT: „erst Grundlagen").
- Latency (E3, fallback while E2 is open): play-along calibration; two calibrations in a row on the same device must differ by ≤ 3 ms. The calibration screen shows that difference.
- Timestamps: Linux = patched plugin µs epoch stamp from the receive isolate; Android = `android.media.midi` monotonic ns; Windows = WinMM `dwParam2` ms since `midiInStart`. Never use main-isolate arrival time when a driver stamp exists.
- Reproducibility (E3): the same session file gives byte-identical analysis output; synthetic deviations are recovered to ±0.1 ms.
- One count-in bar (4 clicks) before every run. UI strings in English.

## Review Focus

1. **MIDI device unplugged mid-run** → run ends in phase `deviceLost`, nothing is saved as a gate attempt, screen says the device is gone. Test in Task 11.
2. **No latency calibration for this device** → analysis still shows per-hit values (marked "uncalibrated"), but the gate is `notMeasurable` with reason `uncalibrated`. Test in Task 6.
3. **Hits during the count-in or after the last bar** (player warms up / keeps playing) → ignored, not counted as extra. Test in Task 5.
4. **Double trigger** (MegaDrum retrigger: two snare notes 3 ms apart) → one hit + one extra, both visible; no silent de-duplication. Test in Task 5.
5. **Unmapped notes** (e.g. a tom hit during the rock beat, or a raw note the mapping does not know) → counted as extra (or wrong instrument when it sits on a target), shown with its raw note number. Test in Task 5.

---

## File Map

| Path | Responsibility |
|---|---|
| `lib/measure/kit.dart` | `KitInstrument`, `KitMapping` (ported), `Voice`, `voiceOf` |
| `lib/measure/stroke.dart` | `Stroke` (one received hit) |
| `lib/measure/targets.dart` | `TargetHit`, `Exercise`, `TargetTime`, `Exercise.targetTimes` |
| `lib/measure/sequence_aligner.dart` | ported Needleman-Wunsch alignment |
| `lib/measure/latency.dart` | ported latency estimator + `estimateMidiLatency` |
| `lib/measure/hit_matcher.dart` | per-voice matching → `MatchResult` |
| `lib/measure/session_record.dart` | `SessionRecord`, JSONL encode/decode |
| `lib/measure/timestamp_mapper.dart` | ported mapper + Windows unit |
| `lib/skill/metrics.dart` | `SessionMetrics computeMetrics(...)` |
| `lib/skill/gate.dart` | `GateSpec`, `GateCriterion`, `GateResult`, `evaluateGate` |
| `lib/skill/analysis.dart` | `SessionAnalysis analyzeSession(SessionRecord)` + JSON for goldens |
| `lib/content/exercises.dart` | `entryExercise`, `basicRockBeat`, gate specs, `exerciseById` |
| `lib/midi/` | ported port service, stroke source, kit learn session |
| `lib/audio/click_track.dart` | pure WAV renderer for count-in + bars |
| `lib/audio/click_player.dart` | SoLoud playback, returns start time |
| `lib/run/` | `DeviceSettings`, `SessionStore`, `CalibrationController`, `RunController` |
| `lib/ui/` | Home, Setup, KitLearn, Calibration, Run, Feedback screens; `LaneView` |
| `lib/app/` | `main.dart` wiring, router, theme |
| `packages/flutter_midi_command_linux/` | patched plugin (copied unchanged) |
| `tool/midi/send_pattern.py` | virmidi sender (ported) |
| `test/fixtures/sessions/` | reference JSONL + expected analysis JSON |
| `docs/ABNAHME_ETAPPE1.md` | acceptance checklist at the kit |

---

### Task 1: Clean slate and skeleton

**Files:**
- Delete: `lib/`, `test/`, `tool/`, `assets/` (all of it; preserved in `legacy-v0` / `legacy-v0-stapel`)
- Rewrite: `pubspec.yaml`, `README.md` (Stack section), `docs/CLAUDE.md` (replace with a short file, see step 4)
- Create: `lib/main.dart`, `test/architecture_test.dart`
- Copy: `packages/flutter_midi_command_linux/` from `legacy-v0-stapel`

**Interfaces:**
- Produces: empty app that starts and shows "Drum Coach"; the package layout above.

- [ ] **Step 1:** `git rm -r -q lib test tool assets` and `git checkout legacy-v0-stapel -- packages/flutter_midi_command_linux`.
- [ ] **Step 2:** Write `pubspec.yaml`: name `drum_coach`, description `"E-drum trainer: measures every hit via MIDI and decides gates from the numbers."`, sdk `>=3.4.0 <4.0.0`. Dependencies: `flutter`, `flutter_riverpod: ^2.6.1`, `go_router: ^14.6.2`, `flutter_soloud: ^3.2.0`, `shared_preferences: ^2.3.0`, `path_provider: ^2.1.0`, `flutter_midi_command: 1.4.0`. Dev: `flutter_test`, `flutter_lints: ^5.0.0`, `flutter_midi_command_platform_interface: 1.4.0`, `flutter_midi_command_linux: {path: packages/flutter_midi_command_linux}`. `dependency_overrides: flutter_midi_command_linux: {path: packages/flutter_midi_command_linux}`. No assets.
- [ ] **Step 3:** `lib/main.dart`: `MaterialApp` (Material 3, dark, seed `Colors.amber`) with a `Scaffold` body `Text('Drum Coach')`.
- [ ] **Step 4:** `docs/CLAUDE.md` becomes ~25 lines: pointer to `docs/KONZEPT.md` (only valid concept), the layer rule from Global Constraints, the file map above, test commands (`flutter test`, `tool/midi/virtual_port_test.sh`). README "Stack" lists the new dependencies.
- [ ] **Step 5: Write the architecture test** `test/architecture_test.dart`:

```dart
test('pure layers import no flutter or plugins', () {
  for (final dir in ['lib/measure', 'lib/skill', 'lib/content']) {
    for (final f in Directory(dir).listSync(recursive: true).whereType<File>()) {
      final src = f.readAsStringSync();
      expect(src.contains("package:flutter"), isFalse, reason: f.path);
      expect(src.contains("package:flutter_midi_command"), isFalse, reason: f.path);
      expect(src.contains("dart:ui"), isFalse, reason: f.path);
    }
  }
});
```
Create the three directories with a placeholder `lib/measure/kit.dart` (empty library) so the test runs.
- [ ] **Step 6:** `flutter pub get && flutter analyze && flutter test` → no issues, 1 test passes. `flutter build linux --debug` succeeds.
- [ ] **Step 7:** Commit `chore: Etappe 1 — Neustart, Altcode entfernt (gesichert in legacy-v0/legacy-v0-stapel)`.

### Task 2: Kit, mapping, strokes

**Files:**
- Create: `lib/measure/kit.dart` (from old `lib/features/coaching/midi/kit_instrument.dart`), `lib/measure/stroke.dart`
- Test: `test/measure/kit_test.dart` (port old `test/midi/kit_instrument_test.dart`, drop `pad` cases)

**Interfaces:**
- Produces:
  - `enum KitInstrument` as old, **without `pad`**; keeps `gmNote`, `label`, `unknown`.
  - `class KitMapping` as old (`gm()`, `instrumentFor(int note) → KitInstrument?`, `assign`, `remove`, `toJson()/fromJson`, `notes`).
  - `enum Voice { hiHat, snare, kick }` and `Voice? voiceOf(KitInstrument i)`: `hiHatClosed`, `hiHatOpen` → `hiHat`; `snare` → `snare`; `kick` → `kick`; everything else → `null`.
  - `class Stroke { final double timeMs; final int note; final int velocity; final KitInstrument instrument; }` with `const` constructor, `==`/`hashCode`. `instrument` is `KitInstrument.unknown` when the mapping has no entry.

- [ ] **Step 1:** Port the old kit tests and add:

```dart
test('voiceOf groups hi-hat zones, ignores toms', () {
  expect(voiceOf(KitInstrument.hiHatOpen), Voice.hiHat);
  expect(voiceOf(KitInstrument.snare), Voice.snare);
  expect(voiceOf(KitInstrument.snareRim), isNull);
  expect(voiceOf(KitInstrument.unknown), isNull);
});
test('gm mapping: 38 and 40 are snare, 42 hi-hat closed, 36 kick', () { ... });
```
- [ ] **Step 2:** Run `flutter test test/measure/kit_test.dart` → FAIL (missing symbols).
- [ ] **Step 3:** Port `kit_instrument.dart` into `lib/measure/kit.dart` (drop `pad`, keep `learnOrder` but without `pad`), add `Voice`/`voiceOf`; write `stroke.dart`.
- [ ] **Step 4:** Tests + architecture test pass.
- [ ] **Step 5:** Commit `feat(measure): Kit-Instrumente, Mapping, Stroke`.

### Task 3: Exercises and target times

**Files:**
- Create: `lib/measure/targets.dart`, `lib/content/exercises.dart`
- Test: `test/measure/targets_test.dart`, `test/content/exercises_test.dart`

**Interfaces:**
- Produces:
  - `const int ticksPerQuarter = 24;`
  - `class TargetHit { final Voice voice; final int tick; }` — tick inside one bar (`0 ≤ tick < beatsPerBar * 24`).
  - `class Exercise { final String id; final String title; final int bpm; final int bars; final int beatsPerBar; final List<TargetHit> barHits; }` — Task 6 adds `final GateSpec gate`.
  - `double Exercise.barMs` = `beatsPerBar * 60000 / bpm`.
  - `class TargetTime { final int index; final Voice voice; final int bar; final double timeMs; }`
  - `List<TargetTime> Exercise.targetTimes({required double firstBeatMs})` — all bars, sorted by `timeMs`, then by `voice.index`; `index` is the position in that list.
  - `entryExercise` (id `entry`, 70 BPM, 8 bars, hi-hat ticks 0/24/48/72, kick 0/48) and `basicRockBeat` (id `rock8`, 80 BPM, 16 bars, hi-hat every 12 ticks, snare 24/72, kick 0/48); `Exercise exerciseById(String id)` throws `ArgumentError` on unknown id.

- [ ] **Step 1: Tests:**

```dart
test('rock beat: 16 bars × (8 hh + 2 sn + 2 kick) = 192 targets', () {
  final t = basicRockBeat.targetTimes(firstBeatMs: 1000);
  expect(t.length, 192);
  expect(t.where((x) => x.voice == Voice.snare).first.timeMs, 1000 + 750); // beat 2 at 80 BPM
  expect(t.last.timeMs, closeTo(1000 + 15 * 3000 + 3.5 * 750, 1e-9));
});
test('entry: 8 bars × (4 hh + 2 kick) = 48 targets, bar 1 at 70 BPM', () {
  final t = entryExercise.targetTimes(firstBeatMs: 0);
  expect(t.length, 48);
  expect(t.where((x) => x.bar == 1).first.timeMs, closeTo(4 * 60000 / 70, 1e-9));
});
test('simultaneous targets sorted hiHat, snare, kick', ...);
```
- [ ] **Step 2:** Run → FAIL. **Step 3:** Implement. **Step 4:** Run → PASS.
- [ ] **Step 5:** Commit `feat(content): Einstiegsübung und Basic Rock Beat als Soll-Zeiten`.

### Task 4: Port aligner and latency estimator

**Files:**
- Create: `lib/measure/sequence_aligner.dart` (old `lib/features/coaching/services/sequence_aligner.dart`), `lib/measure/latency.dart` (old `services/latency_estimator.dart` + `midi/midi_latency.dart` merged)
- Test: port old `test/coaching/sequence_aligner_test.dart`, `latency_estimator_test.dart`, `test/midi/midi_latency_test.dart` into `test/measure/`

**Interfaces:**
- Produces (unchanged from legacy): `AlignmentResult alignSequences({required List<double> expectedMs, required List<double> onsetMs, double maxMatchDevMs = 250, double gapCostMs = 200})` with `AlignedNote{noteIndex, expectedMs, onsetIndex, deviationMs, hit}`, `extraOnsetIndices`; `LatencyEstimate? estimateLatencyOffset({plannedClickMs, onsetMs})`; `MidiLatencyResult? estimateMidiLatency({clickMs, strokeMs, unsureAboveMs = 10})` with `offsetMs`, `spreadMs`, `matched`, `clicks`, `unsure`.
- Remove `handValuesAllowed` (hands are not measured).

- [ ] **Step 1:** Copy tests, fix imports, delete hand-related cases. Run → FAIL.
- [ ] **Step 2:** Copy sources, fix imports. Run → PASS (all ported cases).
- [ ] **Step 3:** Commit `feat(measure): Abgleich und Latenzschätzung übernommen`.

### Task 5: Per-voice hit matcher

**Files:**
- Create: `lib/measure/hit_matcher.dart`
- Test: `test/measure/hit_matcher_test.dart`

**Interfaces:**
- Consumes: `TargetTime`, `Stroke`, `voiceOf`, `alignSequences`.
- Produces:
  - `enum HitKind { hit, missed, wrongInstrument }`
  - `class TargetOutcome { final TargetTime target; final HitKind kind; final int? strokeIndex; final double? deviationMs; }` — `deviationMs` set for `hit` and `wrongInstrument`.
  - `class MatchResult { final List<TargetOutcome> targets; final List<int> extraStrokeIndices; final List<int> ignoredStrokeIndices; }`
  - `MatchResult matchHits({required List<TargetTime> targets, required List<Stroke> strokes, required double latencyOffsetMs})`

Algorithm (not determined by the signature):
1. Corrected time of stroke *i* = `strokes[i].timeMs − latencyOffsetMs`.
2. `w` = min(250, 0.5 × smallest gap between two consecutive targets of the same voice). Strokes with corrected time outside `[firstTarget − w, lastTarget + w]` go to `ignoredStrokeIndices` (count-in, after the end).
3. For each voice: `alignSequences(expectedMs: that voice's targets, onsetMs: corrected times of in-window strokes whose voiceOf == voice, maxMatchDevMs: w)`. Matched → `hit` with deviation.
4. For each target still `missed`, in time order: the nearest unused in-window stroke whose voice differs (or is `null`), with |corrected − target| ≤ w → `wrongInstrument`, stroke consumed.
5. Every in-window stroke not consumed → `extraStrokeIndices` (sorted).

- [ ] **Step 1: Tests** (helper `strokesFor(targets, {...})` builds perfect strokes):

```dart
test('perfect play: all hit, deviation 0, no extras', ...);
test('latency offset is subtracted: strokes +12 ms, offset 12 → deviation 0', ...);
test('+7 ms on every snare → snare deviations 7.0, others 0', ...);
test('missing snare on bar 3 beat 2 → that target missed, nothing else changes', ...);
test('crash (note 49) instead of hi-hat on one 8th → wrongInstrument, not extra', ...);
test('double trigger: two snare notes 3 ms apart → 1 hit + 1 extra', ...);        // Review Focus 4
test('unmapped raw note 99 between targets → extra; on a target → wrongInstrument', ...); // Review Focus 5
test('strokes during count-in and 2 s after the end → ignored, not extra', ...);   // Review Focus 3
test('hi-hat open counts as hi-hat hit', ...);
```
- [ ] **Step 2:** Run → FAIL. **Step 3:** Implement. **Step 4:** Run → PASS.
- [ ] **Step 5:** Commit `feat(measure): Abgleich je Stimme mit falschem Instrument, Extra, Ignoriert`.

### Task 6: Metrics and gates

**Files:**
- Create: `lib/skill/metrics.dart`, `lib/skill/gate.dart`; modify `lib/measure/targets.dart` + `lib/content/exercises.dart` (add `gate` field)
- Test: `test/skill/metrics_test.dart`, `test/skill/gate_test.dart`

**Interfaces:**
- Consumes: `MatchResult`, `Exercise`, `Stroke`.
- Produces:
  - `class SessionMetrics { final Map<Voice, double> hitRate; final double wrongRate; final double extraRate; final double? timingMedianMs; final double? timingSpreadMs; final double? snareVelocitySd; final double maxHitGapMs; final int targetCount; }`
    - rates are per **target count**; median and population SD over deviations of `hit` outcomes only; `snareVelocitySd` = population SD of velocities of strokes matched as snare `hit` (null if < 2); `maxHitGapMs` = largest time between consecutive `hit` targets (time order), including first target → first hit and last hit → last target (no hit at all → whole run length).
  - `SessionMetrics computeMetrics({required MatchResult match, required List<Stroke> strokes, required Exercise exercise})`
  - `class GateSpec { final double minHitRatePerVoice; final double? maxWrongRate; final double? maxExtraRate; final double? maxAbsMedianMs; final double? maxSpreadMs; final double? maxSnareVelocitySd; final double? maxHitGapBars; }`
  - `class GateCriterion { final String id; final String label; final double? actual; final double threshold; final bool atMost; final bool passed; }`
  - `enum GateStatus { passed, failed, notMeasurable }`
  - `class GateResult { final GateStatus status; final List<GateCriterion> criteria; final String? reason; }` — `reason` is `'uncalibrated'` or `'no-strokes'` when not measurable.
  - `GateResult evaluateGate({required GateSpec spec, required SessionMetrics metrics, required Exercise exercise, required bool calibrated})`
  - In `exercises.dart`: rock gate = `GateSpec(minHitRatePerVoice: 0.95, maxWrongRate: 0.02, maxExtraRate: 0.05, maxAbsMedianMs: 15, maxSpreadMs: 20, maxSnareVelocitySd: 12)`; entry gate = `GateSpec(minHitRatePerVoice: 0.80, maxHitGapBars: 1)`.

- [ ] **Step 1: Tests:**

```dart
test('rock, perfect play → passed, every criterion listed with actual + threshold', ...);
test('rock, hi-hat hit rate 0.94 → failed on hitRate.hiHat only', ...);
test('rock, spread exactly 20 ms → passes (thresholds inclusive)', ...);
test('rock, snare velocities alternating 80/110 → velocity SD 15 → failed', ...);
test('entry, player stops after bar 4 of 8 → maxHitGap > 1 bar → failed', ...);
test('entry, 80 % hits, gaps ≤ 1 bar, timing off by 60 ms → passed (no timing criterion)', ...);
test('not calibrated → notMeasurable, reason uncalibrated, criteria still filled', ...); // Review Focus 2
test('zero strokes → notMeasurable, reason no-strokes', ...);
```
- [ ] **Step 2:** Run → FAIL. **Step 3:** Implement. **Step 4:** Run → PASS.
- [ ] **Step 5:** Commit `feat(skill): Messgrößen und Gates mit Schwellen je Übung`.

### Task 7: Session records, analysis pipeline, reference files

**Files:**
- Create: `lib/measure/session_record.dart`, `lib/skill/analysis.dart`, `test/support/synthetic.dart`, `test/fixtures/sessions/*.jsonl` + `*.expected.json`
- Test: `test/measure/session_record_test.dart`, `test/skill/reference_sessions_test.dart`

**Interfaces:**
- Produces:
  - `class SessionRecord { final int version; final String exerciseId; final int bpm; final double firstBeatMs; final double? latencyOffsetMs; final String deviceName; final KitMapping mapping; final String platform; final DateTime recordedAt; final List<Stroke> strokes; }` (`version` = 1)
  - `String encodeSessionJsonl(SessionRecord r)` — line 1 `{"type":"header",...}` with all fields except strokes; then one line per stroke `{"type":"stroke","t":<ms>,"note":n,"vel":v,"instrument":"<name>"}`. Keys in fixed order, doubles via `toString()`.
  - `SessionRecord decodeSessionJsonl(String text)` — throws `FormatException` on unknown `version` or missing header.
  - `class SessionAnalysis { final Exercise exercise; final List<TargetTime> targets; final MatchResult match; final SessionMetrics metrics; final GateResult gate; }`
  - `SessionAnalysis analyzeSession(SessionRecord r)` — `latencyOffsetMs ?? 0` for matching, `calibrated: r.latencyOffsetMs != null`.
  - `String analysisToJson(SessionAnalysis a)` — deterministic, pretty, numbers rounded to 3 decimals, used for goldens.
  - `SessionRecord syntheticSession(Exercise e, {double latencyMs = 0, Map<int, double> shiftMs = const {}, Set<int> drop = const {}, Map<int, int> replaceNote = const {}, List<Stroke> extra = const [], int velocity = 100})` (test support; indices are `TargetTime.index`).

- [ ] **Step 1: Tests:**

```dart
test('encode → decode → encode is byte-identical', ...);
test('decode rejects version 2', ...);
test('synthetic +7.0 ms on index 10 → deviation 7.0 ± 0.1 for that target', ...);
test('every fixture: analysisToJson(analyzeSession(decode(file))) == expected file', () {
  // UPDATE_GOLDENS=1 writes the expected files instead of comparing.
});
test('analyzing the same file twice gives identical JSON', ...);
```
- [ ] **Step 2:** Run → FAIL. **Step 3:** Implement; then generate fixtures with `UPDATE_GOLDENS=1 flutter test test/skill/reference_sessions_test.dart` from a test-only builder for these cases: `rock_perfect`, `rock_plus7ms`, `rock_missing_snare`, `rock_crash_for_hihat`, `rock_double_trigger`, `rock_countin_noise`, `rock_uncalibrated`, `entry_pass_sloppy`, `entry_stops_bar4`. **Read every expected file once** and check the gate status matches the case name.
- [ ] **Step 4:** Run without `UPDATE_GOLDENS` → PASS.
- [ ] **Step 5:** Commit `feat(measure): Sitzungsdatei, Analyse-Pipeline, Referenzsitzungen`.

### Task 8: Timestamp mapper with Windows unit

**Files:**
- Create: `lib/measure/timestamp_mapper.dart` (old `midi/midi_timestamp_mapper.dart`)
- Test: `test/measure/timestamp_mapper_test.dart` (port old 5 tests + new)

**Interfaces:**
- Produces: `enum MidiTimestampUnit { epochMicros, monotonicNanos, relativeMillis, none }`; `MidiTimestampUnit midiTimestampUnitForPlatform({required bool isAndroid, required bool isLinux, required bool isWindows})`; `MidiTimestampMapper` unchanged API (`observe`, `toEpochMsWith`, `toEpochMs`, `offsetUs`).
- `relativeMillis` behaves like `monotonicNanos` (minimum-arrival-delay offset) with lib µs = `libTimestamp * 1000`.

- [ ] **Step 1: Tests:**

```dart
test('windows: ms stamps 1000 and 1010 map 10.0 ms apart regardless of arrival jitter', ...);
test('windows: offset learned as minimum delay', ...);
test('platform → unit: linux epochMicros, android monotonicNanos, windows relativeMillis', ...);
```
- [ ] **Step 2:** FAIL. **Step 3:** Port + extend. **Step 4:** PASS.
- [ ] **Step 5:** Commit `feat(measure): Zeitstempel-Umrechner inkl. Windows (WinMM ms)`.

### Task 9: MIDI layer and Linux integration test

**Files:**
- Create: `lib/midi/midi_port_service.dart`, `lib/midi/midi_stroke_source.dart`, `lib/midi/kit_learn_session.dart` (old `lib/features/coaching/midi/*`), `tool/midi/send_pattern.py` (old `tool/midi/spike/send_pattern.py`), `tool/midi/virtual_port_test.sh`, `test/helpers/midi_fakes.dart`
- Test: port `test/midi/midi_parse_test.dart`, `midi_stroke_source_test.dart`, `kit_learn_session_test.dart`, `vendored_plugin_test.dart`; `test/integration_linux/midi_virtual_port_test.dart`

**Interfaces:**
- Consumes: `KitMapping`, `Stroke`, `MidiTimestampMapper`.
- Produces:
  - `MidiNoteOn`, `MidiPort` (`noteOns`, `connection`, `deviceName`, `deviceId`, `close()`), `MidiPortService` (`inputDevices()`, `open(id)`) — as legacy.
  - `abstract class StrokeSource { Future<void> start(); Future<void> stop(); List<Stroke> get strokes; Stream<bool> get connection; String get deviceName; void dispose(); }` (lean replacement of the old interface, no mic fields).
  - `class MidiStrokeSource implements StrokeSource { MidiStrokeSource({required MidiPort port, required KitMapping mapping, required MidiTimestampMapper mapper}); }` — converts with the session-final `offsetUs` when `strokes` is read after `stop()`.
  - `KitLearnSession({required KitMapping start, List<KitInstrument> order = const [KitInstrument.kick, KitInstrument.snare, KitInstrument.hiHatClosed, KitInstrument.hiHatOpen]})`.
  - `int? virmidiCard(List<String> deviceNames)` in the integration test helper: parses `^Virtual Raw MIDI (\d+)-0$`.

- [ ] **Step 1:** Port unit tests, adapt to `Stroke`. Run → FAIL.
- [ ] **Step 2:** Port sources. Run unit tests → PASS.
- [ ] **Step 3:** Port the integration test; replace the hard-coded `Virtual Raw MIDI 1-0` / `/dev/snd/midiC1D0` by `virmidiCard(...)`; assertions unchanged (64 of 64 notes, p95 jitter < 0.5 ms, flams 25 ± 1 ms).
- [ ] **Step 4:** `bash tool/midi/virtual_port_test.sh` on the NUC (virmidi is card 0 there) → PASS.
- [ ] **Step 5:** Commit `feat(midi): MIDI-Schicht übernommen, Integrationstest erkennt virmidi-Karte`.

### Task 10: Click track and player

**Files:**
- Create: `lib/audio/click_track.dart` (pure Dart, but lives in `audio/`), `lib/audio/click_player.dart`
- Test: `test/audio/click_track_test.dart`

**Interfaces:**
- Produces:
  - `class ClickTrack { final Uint8List wav; final List<double> clickOffsetsMs; final double firstBeatOffsetMs; final double durationMs; }`
  - `ClickTrack renderClickTrack({required int bpm, required int bars, int beatsPerBar = 4, int countInBars = 1, int sampleRate = 48000})` — 16-bit mono PCM WAV; click = 20 ms decaying 1.5 kHz sine, beat 1 of each bar 2.0 kHz and louder; `firstBeatOffsetMs = countInBars * beatsPerBar * 60000 / bpm`; 500 ms silence at the end.
  - `abstract class ClickOut { Future<void> init(); Future<double> play(ClickTrack t); Future<void> stop(); }` — `play` returns the epoch ms taken right after SoLoud's `play()` returned. `class SoloudClickOut implements ClickOut`.
  - Rule (doc comment on `play`): the constant error of this stamp is part of the calibrated latency, so calibration and runs must use the same `ClickOut`.

- [ ] **Step 1: Tests:**

```dart
test('80 BPM, 16 bars + 1 count-in bar → 68 clicks, offsets every 750 ms', ...);
test('first click sample is at offset 0 and has the accent frequency', ...);
test('wav header: RIFF, 48000 Hz, mono, 16 bit, data length matches duration', ...);
```
- [ ] **Step 2:** FAIL. **Step 3:** Implement. **Step 4:** PASS.
- [ ] **Step 5:** Commit `feat(audio): Klickspur mit Einzähltakt`.

### Task 11: Device settings, session store, calibration, run controller

**Files:**
- Create: `lib/run/device_settings.dart`, `lib/run/session_store.dart`, `lib/run/calibration_controller.dart`, `lib/run/run_controller.dart`
- Test: `test/run/calibration_controller_test.dart`, `test/run/run_controller_test.dart`, `test/run/device_settings_test.dart`

**Interfaces:**
- Consumes: `StrokeSource`, `ClickOut`, `renderClickTrack`, `estimateMidiLatency`, `SessionRecord`, `encodeSessionJsonl`, `analyzeSession`.
- Produces:
  - `class DeviceSettings { DeviceSettings(SharedPreferences p); KitMapping mappingFor(String device); Future<void> saveMapping(String device, KitMapping m); ({double offsetMs, double spreadMs})? latencyFor(String device); Future<void> saveLatency(String device, double offsetMs, double spreadMs); }` — saving a latency keeps the previous one as `previousLatencyFor(device)`.
  - `class SessionStore { SessionStore(Directory root); Future<File> save(SessionRecord r); Future<List<SessionRecord>> recent(String exerciseId, {int limit = 10}); }` — files `sessions/<exerciseId>-<yyyyMMdd-HHmmss>.jsonl`.
  - `class CalibrationController extends ChangeNotifier { CalibrationController({required StrokeSource source, required ClickOut out}); Future<void> run(); MidiLatencyResult? get result; double? differenceToPreviousMs(DeviceSettings s, String device); }` — 4 count-in + 20 quarter clicks at 100 BPM; strokes compared to clicks after the count-in.
  - `enum RunPhase { idle, countIn, playing, finished, deviceLost }`
  - `class RunController extends ChangeNotifier { RunController({required Exercise exercise, required StrokeSource source, required ClickOut out, required KitMapping mapping, required double? latencyOffsetMs, required String platform}); RunPhase get phase; int get currentBar; Future<void> start(); SessionRecord? get record; }` — `start` starts the source, plays `renderClickTrack(bpm, bars)`, sets `firstBeatMs = startMs + firstBeatOffsetMs`, ends after `durationMs`, stops the source and builds `record`. A `false` on `source.connection` → `deviceLost`, `record` stays null.

- [ ] **Step 1: Tests** (fakes for `StrokeSource` and `ClickOut` with a controllable clock):

```dart
test('calibration: strokes 23 ms after every click → offset 23 ± 0.1, not unsure', ...);
test('calibration difference to previous: 23 vs 21 → 2.0', ...);
test('run: perfect fake strokes → record with firstBeatMs = start + 3000 (80 BPM)', ...);
test('run: device disconnect while playing → deviceLost, record null', ...); // Review Focus 1
test('settings: mapping and latency persist per device name', ...);
```
- [ ] **Step 2:** FAIL. **Step 3:** Implement. **Step 4:** PASS.
- [ ] **Step 5:** Commit `feat(run): Kalibrierung, Durchlauf, Ablage je Gerät`.

### Task 12: Screens, lane view, app wiring

**Files:**
- Create: `lib/app/app.dart` (router + theme + providers), `lib/ui/home_screen.dart`, `lib/ui/setup_screen.dart`, `lib/ui/kit_learn_screen.dart`, `lib/ui/calibration_screen.dart`, `lib/ui/run_screen.dart`, `lib/ui/feedback_screen.dart`, `lib/ui/lane_view.dart`; modify `lib/main.dart`
- Test: `test/ui/lane_view_test.dart`, `test/ui/feedback_screen_test.dart`, `test/ui/home_screen_test.dart`

**Interfaces:**
- Consumes: everything above.
- Produces routes: `/` Home, `/setup`, `/setup/kit`, `/setup/calibrate`, `/run/:exerciseId`, `/feedback` (gets `SessionAnalysis` via `extra`).
- Home: device line (name or "No MIDI device"), "Setup", two exercise tiles with last gate status from `SessionStore.recent`. Exercise tiles disabled without a device.
- Run: shows count-in number, then "Bar n / N"; on `finished` saves the record and opens Feedback; on `deviceLost` shows "MIDI device disconnected — run discarded".
- Feedback = **the one feedback view** (KONZEPT §6):
  - Banner: `PASSED` / `NOT PASSED` / `NOT MEASURABLE (calibrate first)`; entry exercise failed adds "Start with the basics first".
  - `LaneView(analysis)`: three rows hi-hat / snare / kick, x = time; target = thin vertical tick; hit = filled dot shifted by `deviationMs` (scale: 1 bar = full width / bars, deviation scaled ×4 so ±15 ms is visible), color early (blue) / on time ≤ 15 ms (green) / late (orange), dot radius grows with velocity (3–8 px for 1–127), tap on a dot shows "bar n · voice · +x.x ms · vel v"; missed = hollow red circle; wrong instrument = orange square + instrument label; extra = grey ×; uncalibrated → grey overlay text "uncalibrated".
  - Gate table: one row per `GateCriterion` with label, actual (1 decimal), threshold with `≤`/`≥`, ✓/✗.
  - Footer: session file path.

- [ ] **Step 1: Tests:**

```dart
testWidgets('feedback: rock_plus7ms fixture → PASSED, 8 rows (3 hit rates, wrong, extra, median, spread, velocity), median 7.0', ...);
testWidgets('feedback: tapping a hit dot shows bar, voice, deviation and velocity', ...);
testWidgets('feedback: rock_uncalibrated → NOT MEASURABLE banner', ...);
testWidgets('feedback: entry_stops_bar4 → NOT PASSED + basics hint', ...);
testWidgets('lane view paints one marker per target and per extra (CustomPainter spy)', ...);
testWidgets('home without device: exercise tiles disabled', ...);
```
- [ ] **Step 2:** FAIL. **Step 3:** Implement (port `KitLearnSession` UI idea from old `lib/features/settings/kit_learn_screen.dart`, calibration UI from old `midi_calibration_screen.dart`, both trimmed to the new controllers). **Step 4:** PASS; `flutter analyze` clean.
- [ ] **Step 5:** Commit `feat(ui): Übungen, Einrichtung, Kalibrierung, Feedback-Ansicht`.

### Task 13: Platforms and acceptance checklist

**Files:**
- Modify: `android/app/src/main/AndroidManifest.xml` (`<uses-feature android:name="android.software.midi" android:required="true"/>`), `android/app/build.gradle*` (`minSdk` ≥ 23), `lib/app/app.dart` (unit via `midiTimestampUnitForPlatform`)
- Create: `docs/ABNAHME_ETAPPE1.md`

**Interfaces:**
- Consumes: all tasks.

- [ ] **Step 1:** `flutter build linux --release` (NUC; Linux bundle for the laptop is built **on the laptop**, glibc), `flutter build apk --release` (NUC), `flutter build windows --release` on `laptop-win` (`ssh laptop-win`, folder `C:\Users\ulrich\...`). All three succeed; note versions in the checklist.
- [ ] **Step 2:** On the NUC: `flutter test` all green, `bash tool/midi/virtual_port_test.sh` green.
- [ ] **Step 3:** Write `docs/ABNAHME_ETAPPE1.md` with one table per item (Erwartung | Befund | Datum), filled at the kit:
  1. MegaDrum per USB recognized on Linux, Android (OTG), Windows; kit learn for kick/snare/hi-hat < 2 min; mapping survives restart.
  2. Timestamp spread per platform: 64 quarter notes from the MegaDrum (or a steady pad roll) → stamp spread < 1 ms (Windows < 1.5 ms).
  3. Latency: two calibrations in a row differ ≤ 3 ms; value, device, audio output documented.
  4. Two real sessions per exercise saved as `test/fixtures/sessions/megadrum_*.jsonl` + expected JSON; reproducible (golden test green).
  5. Gate "Basic Rock Beat": pass/fail traceable from the gate table; one deliberately sloppy run fails on the expected criterion.
  6. Entry exercise: a run stopped after bar 4 shows "Start with the basics first".
  7. E2 (open): loopback cable click → MegaDrum trigger input fires cleanly? If yes, follow-up plan for objective latency measurement.
- [ ] **Step 4:** Commit `chore: Plattformen Linux/Android/Windows, Abnahmeliste Etappe 1`.
