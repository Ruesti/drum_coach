# Notation Engine — Real Note Values (SP1) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Extend the exercise model so each note carries its own value (NoteValue + triplet/sextuplet), render duration-proportional notation, and play mixed rhythms on a fine 24-tick/quarter grid — all backward-compatible with the 41 existing seed rudiments and without touching the timing isolate.

**Architecture:** A note's rhythm becomes a resolved `(NoteValue, dotted, Tuplet)` → a rational duration in quarters. Rendering places notes by cumulative duration (proportional layout). Playback expands the pattern onto a fixed 24-ticks-per-quarter grid, feeding the existing `setPatternVolumes` path with per-tick volumes (0 on silent ticks); the cursor maps a tick back to a note index. Old uniform-grid entries resolve their value from `gridUnit`, so they behave identically.

**Tech Stack:** Flutter/Dart (SDK `>=3.4.0 <4.0.0`), Riverpod (codegen), `flutter_soloud` audio in a timing isolate, `flutter_test`.

## Global Constraints

- Backward compatibility: the 41 existing `Rudiment` entries in `lib/features/lessons/data/rudiments_seed.dart` must render and play identically. New `StrokeBeat` fields default so old `const` entries compile unchanged.
- Do NOT modify the timing isolate logic in `metronome_engine.dart` (`_timingIsolateMain`, `computeNextBeatDelayUs`). Only add an arbitrary integer tick factor path.
- Fine-grid resolution is fixed at **24 ticks/quarter** (covers quarter=24, eighth=12, sixteenth=6, thirty-second=3, eighth-triplet=8, sixteenth-sextuplet=4, dotted-eighth=18 — all integers).
- Supported tuplets: triplet and sextuplet only (no quintuplets in v1).
- Mic analysis (`lib/features/coaching/services/mic_analysis_service.dart`) is NOT updated here; leave its call sites unchanged (they still assume one-hit-per-tick and are gated behind the mic-analysis setting).
- Run tests with `flutter test <path>` and static checks with `flutter analyze` from the worktree root `/home/uli/projects/drum_coach/.claude/worktrees/drum-etudes`.
- Commit after every task with the project trailer:
  `Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>` and
  `Claude-Session: https://claude.ai/code/session_01MaUau8L3orqhR57QvKubqC`.

## File Structure

- `lib/features/lessons/models/rudiment.dart` — add `NoteValue`, `Tuplet`, `ResolvedNote`, `gridToNote`, `resolveNote`; extend `StrokeBeat`.
- `lib/features/lessons/models/pattern_playback.dart` — NEW: `PatternPlayback` + `buildPatternPlayback` + `defaultBeatVolume` (pure playback derivation).
- `lib/features/metronome/metronome_engine.dart` — introduce single `_factor` field + `setPatternClock(int)`.
- `lib/features/metronome/metronome_provider.dart` — expose `setPatternClock(int)`.
- `lib/features/practice/practice_session_screen.dart` — wire `PatternPlayback` (clock + volumes + cursor).
- `lib/shared/widgets/staff_layout.dart` — NEW: pure `computeStaffLayout` + `NotePlacement` + `BeamGroup` + `StaffLayout`.
- `lib/shared/widgets/notation_staff_widget.dart` — repaint from `StaffLayout` (duration-proportional).
- `lib/features/lessons/data/rudiments_seed.dart` — dedupe duplicate ids.
- Tests: `test/lessons/note_value_test.dart`, `test/lessons/pattern_playback_test.dart`, `test/shared/staff_layout_test.dart`, `test/lessons/seed_integrity_test.dart`; extend `test/notation_staff_test.dart` and `test/metronome/metronome_engine_test.dart`.

**Out of scope for SP1 (deferred to SP3):** the authoring DSL helpers (`eighths`/`triplet8`/…). Tests here use explicit `StrokeBeat` lists.

---

### Task 1: Note-value model

**Files:**
- Modify: `lib/features/lessons/models/rudiment.dart`
- Test: `test/lessons/note_value_test.dart`

**Interfaces:**
- Produces:
  - `enum NoteValue { whole, half, quarter, eighth, sixteenth, thirtySecond }` with `double get quarters`.
  - `enum Tuplet { none, triplet, sextuplet }` with `double get factor`.
  - `StrokeBeat` gains `final NoteValue? value; final bool dotted; final Tuplet tuplet;` (defaults `null`, `false`, `Tuplet.none`) on both constructors.
  - `class ResolvedNote { final NoteValue value; final bool dotted; final Tuplet tuplet; double get quarters; }`
  - `ResolvedNote gridToNote(NoteGrid grid)`
  - `ResolvedNote resolveNote(StrokeBeat beat, NoteGrid grid)`

- [ ] **Step 1: Write the failing test**

```dart
// test/lessons/note_value_test.dart
import 'package:drum_coach/features/lessons/models/rudiment.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('NoteValue / Tuplet duration', () {
    test('quarters per value', () {
      expect(NoteValue.whole.quarters, 4.0);
      expect(NoteValue.quarter.quarters, 1.0);
      expect(NoteValue.eighth.quarters, 0.5);
      expect(NoteValue.sixteenth.quarters, 0.25);
      expect(NoteValue.thirtySecond.quarters, 0.125);
    });

    test('ResolvedNote applies dot and tuplet', () {
      expect(const ResolvedNote(NoteValue.eighth, false, Tuplet.none).quarters, 0.5);
      expect(const ResolvedNote(NoteValue.eighth, true, Tuplet.none).quarters, 0.75);
      expect(const ResolvedNote(NoteValue.eighth, false, Tuplet.triplet).quarters,
          closeTo(1 / 3, 1e-9));
      expect(const ResolvedNote(NoteValue.sixteenth, false, Tuplet.sextuplet).quarters,
          closeTo(1 / 6, 1e-9));
    });
  });

  group('resolveNote backward-compat', () {
    test('null value resolves from gridUnit (uniform old data)', () {
      const beat = StrokeBeat(hand: Hand.right); // value == null
      expect(resolveNote(beat, NoteGrid.eighth).quarters, 0.5);
      expect(resolveNote(beat, NoteGrid.triplet).quarters, closeTo(1 / 3, 1e-9));
      expect(resolveNote(beat, NoteGrid.sixteenthTriplet).quarters,
          closeTo(1 / 6, 1e-9));
      expect(resolveNote(beat, NoteGrid.thirtySecond).quarters, 0.125);
    });

    test('explicit value overrides gridUnit', () {
      const beat = StrokeBeat(
          hand: Hand.left, value: NoteValue.quarter, tuplet: Tuplet.none);
      expect(resolveNote(beat, NoteGrid.sixteenth).quarters, 1.0);
    });

    test('rest keeps its resolved duration', () {
      const rest = StrokeBeat.rest();
      expect(resolveNote(rest, NoteGrid.eighth).quarters, 0.5);
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/lessons/note_value_test.dart`
Expected: FAIL — `NoteValue`, `Tuplet`, `ResolvedNote`, `resolveNote` undefined; `StrokeBeat` has no `value`.

- [ ] **Step 3: Add the types to `rudiment.dart`**

Add near the top (after the existing `NoteGrid` enum block, before `Difficulty`):

```dart
/// A drawn note value (independent of the pattern's [NoteGrid]). Duration is
/// expressed in quarter-note units so renderer and player share one source.
enum NoteValue {
  whole(quarters: 4.0),
  half(quarters: 2.0),
  quarter(quarters: 1.0),
  eighth(quarters: 0.5),
  sixteenth(quarters: 0.25),
  thirtySecond(quarters: 0.125);

  final double quarters;
  const NoteValue({required this.quarters});
}

/// Tuplet marker. `triplet` = 3 in the space of 2, `sextuplet` = 6 in the
/// space of 4 — both scale a note's duration by 2/3.
enum Tuplet {
  none(factor: 1.0),
  triplet(factor: 2 / 3),
  sextuplet(factor: 2 / 3);

  final double factor;
  const Tuplet({required this.factor});
}

/// A fully-resolved note value: base value with an optional dot and tuplet.
class ResolvedNote {
  final NoteValue value;
  final bool dotted;
  final Tuplet tuplet;
  const ResolvedNote(this.value, this.dotted, this.tuplet);

  /// Duration in quarter-note units.
  double get quarters => value.quarters * (dotted ? 1.5 : 1.0) * tuplet.factor;
}

/// Maps an old uniform [NoteGrid] cell to its equivalent note value, so
/// pre-existing patterns (whose [StrokeBeat.value] is null) resolve unchanged.
ResolvedNote gridToNote(NoteGrid grid) => switch (grid) {
      NoteGrid.quarter => const ResolvedNote(NoteValue.quarter, false, Tuplet.none),
      NoteGrid.eighth => const ResolvedNote(NoteValue.eighth, false, Tuplet.none),
      NoteGrid.triplet => const ResolvedNote(NoteValue.eighth, false, Tuplet.triplet),
      NoteGrid.sixteenth => const ResolvedNote(NoteValue.sixteenth, false, Tuplet.none),
      NoteGrid.sixteenthTriplet =>
        const ResolvedNote(NoteValue.sixteenth, false, Tuplet.sextuplet),
      NoteGrid.thirtySecond =>
        const ResolvedNote(NoteValue.thirtySecond, false, Tuplet.none),
    };

/// Resolves a [StrokeBeat] to its note value: explicit [StrokeBeat.value] when
/// set (new content), otherwise derived from [grid] (legacy uniform patterns).
ResolvedNote resolveNote(StrokeBeat beat, NoteGrid grid) => beat.value != null
    ? ResolvedNote(beat.value!, beat.dotted, beat.tuplet)
    : gridToNote(grid);
```

Then extend `StrokeBeat` — add the three fields and constructor params (keep existing fields/`.rest()`):

```dart
class StrokeBeat {
  final Hand hand;
  final bool isAccent;
  final bool isGhost;
  final bool isRest;
  final List<Hand> graces;

  /// Drawn note value. `null` ⇒ derive from the pattern's [Rudiment.gridUnit]
  /// (legacy uniform patterns). Set explicitly for mixed-value content.
  final NoteValue? value;
  final bool dotted;
  final Tuplet tuplet;

  const StrokeBeat({
    required this.hand,
    this.isAccent = false,
    this.isGhost = false,
    this.isRest = false,
    this.graces = const [],
    this.value,
    this.dotted = false,
    this.tuplet = Tuplet.none,
  });

  const StrokeBeat.rest({
    this.value,
    this.dotted = false,
    this.tuplet = Tuplet.none,
  })  : hand = Hand.right,
        isAccent = false,
        isGhost = false,
        isRest = true,
        graces = const [];
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/lessons/note_value_test.dart`
Expected: PASS (all groups).

- [ ] **Step 5: Analyze + commit**

```bash
flutter analyze lib/features/lessons/models/rudiment.dart
git add lib/features/lessons/models/rudiment.dart test/lessons/note_value_test.dart
git commit -m "feat(model): add NoteValue/Tuplet and per-note value resolution

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01MaUau8L3orqhR57QvKubqC"
```

---

### Task 2: PatternPlayback (fine-grid derivation)

**Files:**
- Create: `lib/features/lessons/models/pattern_playback.dart`
- Test: `test/lessons/pattern_playback_test.dart`

**Interfaces:**
- Consumes: `NoteValue`, `Tuplet`, `resolveNote`, `StrokeBeat`, `Rudiment`, `NoteGrid` (Task 1 / existing).
- Produces:
  - `double defaultBeatVolume(StrokeBeat b)` — rest→0.0, accent→2.0, ghost→0.25, else 0.85.
  - `PatternPlayback buildPatternPlayback(List<StrokeBeat> beats, NoteGrid grid, {int ticksPerQuarter = 24, double Function(StrokeBeat) volumeOf = defaultBeatVolume})`
  - `class PatternPlayback { final int ticksPerQuarter; final int totalTicks; final List<double> tickVolumes; final List<int> onsetTicks; int noteIndexAtTick(int tick); factory PatternPlayback.forRudiment(Rudiment r, {int ticksPerQuarter}); }`

- [ ] **Step 1: Write the failing test**

```dart
// test/lessons/pattern_playback_test.dart
import 'package:drum_coach/features/lessons/models/pattern_playback.dart';
import 'package:drum_coach/features/lessons/models/rudiment.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('buildPatternPlayback — uniform legacy pattern', () {
    // 4 eighth notes at eighth grid => onsets every 12 ticks, total 48.
    final beats = List.generate(4, (_) => const StrokeBeat(hand: Hand.right));
    final pp = buildPatternPlayback(beats, NoteGrid.eighth);

    test('24 ticks/quarter, onsets spaced by note duration', () {
      expect(pp.ticksPerQuarter, 24);
      expect(pp.onsetTicks, [0, 12, 24, 36]);
      expect(pp.totalTicks, 48);
      expect(pp.tickVolumes.length, 48);
    });

    test('volume only on onset ticks', () {
      expect(pp.tickVolumes[0], 0.85);
      expect(pp.tickVolumes[1], 0.0);
      expect(pp.tickVolumes[12], 0.85);
    });

    test('noteIndexAtTick maps a tick to the sounding note', () {
      expect(pp.noteIndexAtTick(0), 0);
      expect(pp.noteIndexAtTick(11), 0);
      expect(pp.noteIndexAtTick(12), 1);
      expect(pp.noteIndexAtTick(47), 3);
    });
  });

  group('buildPatternPlayback — mixed values + tuplet', () {
    // quarter, then an eighth-triplet (3x 1/3 quarter). total = 1 + 1 = 2 quarters.
    const beats = [
      StrokeBeat(hand: Hand.right, value: NoteValue.quarter),
      StrokeBeat(hand: Hand.left, value: NoteValue.eighth, tuplet: Tuplet.triplet),
      StrokeBeat(hand: Hand.right, value: NoteValue.eighth, tuplet: Tuplet.triplet),
      StrokeBeat(hand: Hand.left, value: NoteValue.eighth, tuplet: Tuplet.triplet),
    ];
    final pp = buildPatternPlayback(beats, NoteGrid.eighth);

    test('onset ticks land exactly on the 24-grid', () {
      // quarter=24 ticks; each triplet-eighth=8 ticks.
      expect(pp.onsetTicks, [0, 24, 32, 40]);
      expect(pp.totalTicks, 48);
    });
  });

  group('volume + accents', () {
    test('accent and ghost volumes', () {
      const beats = [
        StrokeBeat(hand: Hand.right, isAccent: true),
        StrokeBeat(hand: Hand.left, isGhost: true),
        StrokeBeat.rest(),
      ];
      final pp = buildPatternPlayback(beats, NoteGrid.quarter);
      expect(pp.tickVolumes[0], 2.0);   // accent, onset tick 0
      expect(pp.tickVolumes[24], 0.25); // ghost, onset tick 24
      expect(pp.tickVolumes[48], 0.0);  // rest, onset tick 48
    });
  });

  group('PatternPlayback.forRudiment', () {
    test('derives from the rudiment grid + sticking', () {
      const r = Rudiment(
        id: 'x', name: 'x', description: 'x', minBpm: 60, targetBpm: 120,
        difficulty: Difficulty.beginner, gridUnit: NoteGrid.eighth,
        sticking: [StrokeBeat(hand: Hand.right), StrokeBeat(hand: Hand.left)],
      );
      final pp = PatternPlayback.forRudiment(r);
      expect(pp.onsetTicks, [0, 12]);
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/lessons/pattern_playback_test.dart`
Expected: FAIL — `pattern_playback.dart` does not exist.

- [ ] **Step 3: Create `pattern_playback.dart`**

```dart
// lib/features/lessons/models/pattern_playback.dart
import 'rudiment.dart';

/// Playback volume for a stroke: rest silent, accent loud, ghost quiet.
/// (Mirrors the old practice-screen `_volumesFor` mapping.)
double defaultBeatVolume(StrokeBeat b) {
  if (b.isRest) return 0.0;
  if (b.isAccent) return 2.0;
  if (b.isGhost) return 0.25;
  return 0.85;
}

/// A pattern expanded onto a fixed fine grid ([ticksPerQuarter] ticks per
/// quarter). Each note sounds only on its onset tick; every other tick is
/// silent (volume 0). This drives the metronome's per-tick volume array and
/// the playback cursor without changing the timing isolate.
class PatternPlayback {
  final int ticksPerQuarter;
  final int totalTicks;

  /// Length [totalTicks]. Onset ticks carry the note's volume; others are 0.
  final List<double> tickVolumes;

  /// Onset tick per note index (same length/order as the source beats).
  final List<int> onsetTicks;

  const PatternPlayback({
    required this.ticksPerQuarter,
    required this.totalTicks,
    required this.tickVolumes,
    required this.onsetTicks,
  });

  /// Note index sounding at [tick] = the last onset ≤ tick (clamped).
  int noteIndexAtTick(int tick) {
    if (onsetTicks.isEmpty) return 0;
    if (tick <= onsetTicks.first) return 0;
    var idx = 0;
    for (var i = 0; i < onsetTicks.length; i++) {
      if (onsetTicks[i] <= tick) {
        idx = i;
      } else {
        break;
      }
    }
    return idx;
  }

  factory PatternPlayback.forRudiment(Rudiment r, {int ticksPerQuarter = 24}) =>
      buildPatternPlayback(r.sticking, r.gridUnit,
          ticksPerQuarter: ticksPerQuarter);
}

PatternPlayback buildPatternPlayback(
  List<StrokeBeat> beats,
  NoteGrid grid, {
  int ticksPerQuarter = 24,
  double Function(StrokeBeat) volumeOf = defaultBeatVolume,
}) {
  final onsetTicks = <int>[];
  var cursor = 0;
  for (final b in beats) {
    onsetTicks.add(cursor);
    final quarters = resolveNote(b, grid).quarters;
    cursor += (quarters * ticksPerQuarter).round();
  }
  final total = cursor;
  final vols = List<double>.filled(total, 0.0);
  for (var i = 0; i < beats.length; i++) {
    vols[onsetTicks[i]] = volumeOf(beats[i]);
  }
  return PatternPlayback(
    ticksPerQuarter: ticksPerQuarter,
    totalTicks: total,
    tickVolumes: vols,
    onsetTicks: onsetTicks,
  );
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/lessons/pattern_playback_test.dart`
Expected: PASS (all groups).

- [ ] **Step 5: Analyze + commit**

```bash
flutter analyze lib/features/lessons/models/pattern_playback.dart
git add lib/features/lessons/models/pattern_playback.dart test/lessons/pattern_playback_test.dart
git commit -m "feat(playback): fine-grid PatternPlayback derivation

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01MaUau8L3orqhR57QvKubqC"
```

---

### Task 3: Metronome arbitrary tick factor

**Files:**
- Modify: `lib/features/metronome/metronome_engine.dart`
- Modify: `lib/features/metronome/metronome_provider.dart`
- Test: `test/metronome/metronome_engine_test.dart` (extend)

**Interfaces:**
- Produces: `MetronomeEngine.setPatternClock(int ticksPerQuarter)` and `MetronomeNotifier.setPatternClock(int ticksPerQuarter)`. The engine tracks the active factor in a single `int _factor` used by `start()`.
- Consumes: existing `_cmdFactor`, `computeNextBeatDelayUs` (unchanged).

- [ ] **Step 1: Write the failing test**

Append to `test/metronome/metronome_engine_test.dart` (inside its `main`, add a new group). This locks the delay math for a fine factor without needing audio/isolate:

```dart
  group('fine-grid factor', () {
    test('computeNextBeatDelayUs works at 24 ticks/quarter', () {
      // 120 bpm, factor 24 => 500000us/quarter / 24 = 20833.33us/tick.
      final d = computeNextBeatDelayUs(
        bpm: 120, factor: 24, idx: 1,
        anchorUs: 0, anchorIdx: 0, elapsedUs: 0,
      );
      expect(d, closeTo(20833, 2));
    });
  });
```

- [ ] **Step 2: Run test to verify it fails or passes**

Run: `flutter test test/metronome/metronome_engine_test.dart`
Expected: this specific test PASSES already (the math is generic) — it guards the fine factor. If the file lacks an import for `computeNextBeatDelayUs`, add `import 'package:drum_coach/features/metronome/metronome_engine.dart';` (match the existing import). Proceed to add the API below (verified by analyze + device).

- [ ] **Step 3: Introduce a single `_factor` in the engine**

In `metronome_engine.dart`, replace the `_subdivision.factor` usage with a tracked `_factor`. Change the field block and `start()`:

Find:
```dart
  Subdivision  _subdivision = Subdivision.quarter;
```
Add directly below it:
```dart
  int          _factor      = 1; // active ticks-per-quarter (subdivision or pattern clock)
```

In `start()`, change:
```dart
    _controlPort?.send([_cmdStart, _bpm, _subdivision.factor]);
```
to:
```dart
    _controlPort?.send([_cmdStart, _bpm, _factor]);
```

In `setSubdivision`, keep it authoritative for the factor:
```dart
  void setSubdivision(Subdivision subdivision) {
    _subdivision = subdivision;
    _factor = subdivision.factor;
    _controlPort?.send([_cmdFactor, _factor]);
  }
```

Add a new method right after `setSubdivision`:
```dart
  /// Set an arbitrary integer tick factor for pattern playback (e.g. 24
  /// ticks/quarter), bypassing the [Subdivision] enum. The timing isolate
  /// already treats `factor` generically.
  void setPatternClock(int ticksPerQuarter) {
    _factor = ticksPerQuarter;
    _controlPort?.send([_cmdFactor, _factor]);
  }
```

- [ ] **Step 4: Expose it on the provider**

In `metronome_provider.dart`, add after `setSubdivision` (mirror its restart handling):

```dart
  void setPatternClock(int ticksPerQuarter) {
    final wasPlaying = state.isPlaying;
    if (wasPlaying) _engine?.stop();
    _engine?.setPatternClock(ticksPerQuarter);
    if (wasPlaying) _engine?.start();
    state = state.copyWith(currentBeatIndex: -1);
  }
```

- [ ] **Step 5: Run tests + analyze**

Run: `flutter test test/metronome/metronome_engine_test.dart`
Expected: PASS (existing + new fine-grid test).
Run: `flutter analyze lib/features/metronome/`
Expected: no issues.

- [ ] **Step 6: Commit**

```bash
git add lib/features/metronome/metronome_engine.dart lib/features/metronome/metronome_provider.dart test/metronome/metronome_engine_test.dart
git commit -m "feat(metronome): arbitrary tick factor for pattern playback

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01MaUau8L3orqhR57QvKubqC"
```

---

### Task 4: Wire PatternPlayback into the practice screen

**Files:**
- Modify: `lib/features/practice/practice_session_screen.dart`
- Test: covered by Task 2 (pure mapping); this task is verified by `flutter analyze` + device.

**Interfaces:**
- Consumes: `PatternPlayback.forRudiment`, `MetronomeNotifier.setPatternClock`, `setPatternVolumes` (Tasks 2 & 3).

- [ ] **Step 1: Compute a PatternPlayback for the exercise**

Add the import:
```dart
import '../lessons/models/pattern_playback.dart';
```

In `_PracticeSessionScreenState`, add a cached field and build it once the rudiment is known. Near the other fields:
```dart
  late PatternPlayback _playback;
```

In `initState`'s `addPostFrameCallback`, replace the metronome setup:

Find:
```dart
      final metronome = _metronomeNotifier
        ..setSubdivision(_subdivisionFor(rudiment.gridUnit))
        ..setPatternVolumes(_volumesFor(rudiment.sticking));
```
Replace with:
```dart
      _playback = PatternPlayback.forRudiment(rudiment);
      final metronome = _metronomeNotifier
        ..setPatternClock(_playback.ticksPerQuarter)
        ..setPatternVolumes(_playback.tickVolumes);
```

- [ ] **Step 2: Map the cursor through onset ticks**

Find:
```dart
    final activeBeat = metState.isPlaying
        ? metState.currentBeatIndex % rudiment.sticking.length
        : null;
```
Replace with:
```dart
    final activeBeat = metState.isPlaying && metState.currentBeatIndex >= 0
        ? _playback.noteIndexAtTick(
            metState.currentBeatIndex % _playback.totalTicks)
        : null;
```

- [ ] **Step 3: Remove the now-unused helpers**

Delete `_subdivisionFor` (lines defining the `static Subdivision _subdivisionFor(...)`) and `_volumesFor` (`static List<double> _volumesFor(...)`). In `dispose`, the existing reset:
```dart
      _metronomeNotifier
        ..stop()
        ..setPatternVolumes(null)
        ..setSubdivision(Subdivision.quarter);
```
is fine to keep (it restores a normal metronome factor). Keep the `Subdivision` import only if still referenced there; otherwise remove it.

- [ ] **Step 4: Analyze**

Run: `flutter analyze lib/features/practice/practice_session_screen.dart`
Expected: no issues (no unused `_subdivisionFor`/`_volumesFor`/imports).

- [ ] **Step 5: Commit**

```bash
git add lib/features/practice/practice_session_screen.dart
git commit -m "feat(practice): drive playback+cursor from PatternPlayback fine grid

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01MaUau8L3orqhR57QvKubqC"
```

---

### Task 5: Staff layout — proportional geometry

**Files:**
- Create: `lib/shared/widgets/staff_layout.dart`
- Test: `test/shared/staff_layout_test.dart`

**Interfaces:**
- Consumes: `StrokeBeat`, `NoteGrid`, `resolveNote`, `ResolvedNote` (Task 1).
- Produces:
  - `class NotePlacement { final int index; final int row; final int bar; final double xCenter; final ResolvedNote resolved; final bool isRest; }`
  - `class BeamGroup { final int row; final int startIndex; final int endIndex; final int beamCount; final Tuplet tuplet; }`
  - `class StaffLayout { final int rowCount; final double pxPerQuarter; final int beatsPerBar; final int barsPerRow; final List<NotePlacement> placements; final List<BeamGroup> beams; }`
  - `int beamCountFor(NoteValue v)` (eighth→1, sixteenth→2, thirtySecond→3, else 0).
  - `StaffLayout computeStaffLayout({required List<StrokeBeat> beats, required NoteGrid grid, required int beatsPerBar, required double maxWidth, double leftPad, double rightPad, double systemPad, double barGap, double preferredPxPerQuarter})`

- [ ] **Step 1: Write the failing test (geometry only; beams come in Task 6)**

```dart
// test/shared/staff_layout_test.dart
import 'package:drum_coach/features/lessons/models/rudiment.dart';
import 'package:drum_coach/shared/widgets/staff_layout.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('computeStaffLayout — bars, rows, x', () {
    // Two 4/4 bars of quarter notes (8 notes). Wide canvas => one row.
    final beats =
        List.generate(8, (_) => const StrokeBeat(hand: Hand.right, value: NoteValue.quarter));
    final layout = computeStaffLayout(
      beats: beats, grid: NoteGrid.quarter, beatsPerBar: 4, maxWidth: 2000,
    );

    test('assigns notes to correct bars', () {
      expect(layout.placements[0].bar, 0);
      expect(layout.placements[3].bar, 0);
      expect(layout.placements[4].bar, 1);
      expect(layout.placements[7].bar, 1);
    });

    test('x increases within a bar by pxPerQuarter', () {
      final p0 = layout.placements[0];
      final p1 = layout.placements[1];
      expect(p1.xCenter - p0.xCenter, closeTo(layout.pxPerQuarter, 0.001));
    });

    test('single row when everything fits', () {
      expect(layout.rowCount, 1);
      expect(layout.placements.every((p) => p.row == 0), isTrue);
    });
  });

  group('computeStaffLayout — wrapping', () {
    // 4 bars of quarters on a narrow canvas => multiple rows, whole bars only.
    final beats =
        List.generate(16, (_) => const StrokeBeat(hand: Hand.right, value: NoteValue.quarter));

    test('wraps at bar boundaries', () {
      final layout = computeStaffLayout(
        beats: beats, grid: NoteGrid.quarter, beatsPerBar: 4, maxWidth: 360,
      );
      expect(layout.barsPerRow, greaterThanOrEqualTo(1));
      // every note's row == its bar ~/ barsPerRow
      for (final p in layout.placements) {
        expect(p.row, p.bar ~/ layout.barsPerRow);
      }
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/shared/staff_layout_test.dart`
Expected: FAIL — `staff_layout.dart` does not exist.

- [ ] **Step 3: Create `staff_layout.dart` (geometry + placeholder empty beams)**

```dart
// lib/shared/widgets/staff_layout.dart
import '../../features/lessons/models/rudiment.dart';

/// Beam/flag count for a note value (0 = stem only, no beam/flag).
int beamCountFor(NoteValue v) => switch (v) {
      NoteValue.eighth => 1,
      NoteValue.sixteenth => 2,
      NoteValue.thirtySecond => 3,
      _ => 0,
    };

class NotePlacement {
  final int index;
  final int row;
  final int bar;
  final double xCenter; // px within the row's coordinate space
  final ResolvedNote resolved;
  final bool isRest;
  const NotePlacement({
    required this.index,
    required this.row,
    required this.bar,
    required this.xCenter,
    required this.resolved,
    required this.isRest,
  });
}

class BeamGroup {
  final int row;
  final int startIndex; // inclusive, into beats
  final int endIndex;   // inclusive
  final int beamCount;
  final Tuplet tuplet;
  const BeamGroup({
    required this.row,
    required this.startIndex,
    required this.endIndex,
    required this.beamCount,
    required this.tuplet,
  });
}

class StaffLayout {
  final int rowCount;
  final double pxPerQuarter;
  final int beatsPerBar;
  final int barsPerRow;
  final List<NotePlacement> placements;
  final List<BeamGroup> beams;
  const StaffLayout({
    required this.rowCount,
    required this.pxPerQuarter,
    required this.beatsPerBar,
    required this.barsPerRow,
    required this.placements,
    required this.beams,
  });
}

const int _ticksPerQuarter = 24; // integer layout math, matches PatternPlayback

StaffLayout computeStaffLayout({
  required List<StrokeBeat> beats,
  required NoteGrid grid,
  required int beatsPerBar,
  required double maxWidth,
  double leftPad = 10,
  double rightPad = 14,
  double systemPad = 40,
  double barGap = 14,
  double preferredPxPerQuarter = 56,
}) {
  final ticksPerBar = beatsPerBar * _ticksPerQuarter;
  final usable = maxWidth - leftPad - rightPad - systemPad;

  double barWidthAt(double pxq) => beatsPerBar * pxq + barGap;
  var pxPerQuarter = preferredPxPerQuarter;
  var barsPerRow = (usable / barWidthAt(pxPerQuarter)).floor();
  if (barsPerRow < 1) {
    barsPerRow = 1;
    pxPerQuarter = ((usable - barGap) / beatsPerBar).clamp(8.0, preferredPxPerQuarter);
  }

  final placements = <NotePlacement>[];
  var tickCursor = 0;
  for (var i = 0; i < beats.length; i++) {
    final resolved = resolveNote(beats[i], grid);
    final bar = tickCursor ~/ ticksPerBar;
    final tickInBar = tickCursor - bar * ticksPerBar;
    final quartersInBar = tickInBar / _ticksPerQuarter;
    final row = bar ~/ barsPerRow;
    final barInRow = bar % barsPerRow;
    final x = leftPad +
        systemPad +
        barInRow * (beatsPerBar * pxPerQuarter + barGap) +
        quartersInBar * pxPerQuarter;
    placements.add(NotePlacement(
      index: i,
      row: row,
      bar: bar,
      xCenter: x,
      resolved: resolved,
      isRest: beats[i].isRest,
    ));
    tickCursor += (resolved.quarters * _ticksPerQuarter).round();
  }

  final totalBars = (tickCursor / ticksPerBar).ceil().clamp(1, 1 << 30);
  final rowCount = ((totalBars - 1) ~/ barsPerRow) + 1;

  return StaffLayout(
    rowCount: rowCount,
    pxPerQuarter: pxPerQuarter,
    beatsPerBar: beatsPerBar,
    barsPerRow: barsPerRow,
    placements: placements,
    beams: const [], // filled in Task 6
  );
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/shared/staff_layout_test.dart`
Expected: PASS.

- [ ] **Step 5: Analyze + commit**

```bash
flutter analyze lib/shared/widgets/staff_layout.dart
git add lib/shared/widgets/staff_layout.dart test/shared/staff_layout_test.dart
git commit -m "feat(notation): proportional staff layout geometry

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01MaUau8L3orqhR57QvKubqC"
```

---

### Task 6: Staff layout — beam & tuplet grouping

**Files:**
- Modify: `lib/shared/widgets/staff_layout.dart`
- Test: `test/shared/staff_layout_test.dart` (extend)

**Interfaces:**
- Produces: `StaffLayout.beams` populated. Grouping rule: within one quarter-beat of a bar, a **beam run** is a maximal sequence of ≥2 consecutive non-rest notes with the **same** `beamCount` (>0). A tuplet run is a maximal sequence of consecutive non-rest notes in a beat sharing the same non-`none` `Tuplet` (emitted as a `BeamGroup` with that tuplet; used for the bracket even if beamCount differs).

- [ ] **Step 1: Write the failing test**

Add to `test/shared/staff_layout_test.dart`:

```dart
  group('computeStaffLayout — beams & tuplets', () {
    test('groups four sixteenths in a beat into one 2-beam run', () {
      final beats = List.generate(
          4, (_) => const StrokeBeat(hand: Hand.right, value: NoteValue.sixteenth));
      final layout = computeStaffLayout(
        beats: beats, grid: NoteGrid.sixteenth, beatsPerBar: 4, maxWidth: 2000,
      );
      final runs = layout.beams.where((b) => b.beamCount == 2).toList();
      expect(runs.length, 1);
      expect(runs.first.startIndex, 0);
      expect(runs.first.endIndex, 3);
    });

    test('emits a triplet group for an eighth-triplet beat', () {
      const beats = [
        StrokeBeat(hand: Hand.right, value: NoteValue.eighth, tuplet: Tuplet.triplet),
        StrokeBeat(hand: Hand.left, value: NoteValue.eighth, tuplet: Tuplet.triplet),
        StrokeBeat(hand: Hand.right, value: NoteValue.eighth, tuplet: Tuplet.triplet),
      ];
      final layout = computeStaffLayout(
        beats: beats, grid: NoteGrid.eighth, beatsPerBar: 4, maxWidth: 2000,
      );
      expect(layout.beams.any((b) => b.tuplet == Tuplet.triplet
          && b.startIndex == 0 && b.endIndex == 2), isTrue);
    });

    test('a rest breaks a beam run', () {
      const beats = [
        StrokeBeat(hand: Hand.right, value: NoteValue.sixteenth),
        StrokeBeat.rest(value: NoteValue.sixteenth),
        StrokeBeat(hand: Hand.left, value: NoteValue.sixteenth),
        StrokeBeat(hand: Hand.right, value: NoteValue.sixteenth),
      ];
      final layout = computeStaffLayout(
        beats: beats, grid: NoteGrid.sixteenth, beatsPerBar: 4, maxWidth: 2000,
      );
      // only the last two sixteenths form a >=2 beam run
      final runs = layout.beams.where((b) => b.beamCount == 2).toList();
      expect(runs.length, 1);
      expect(runs.first.startIndex, 2);
      expect(runs.first.endIndex, 3);
    });
  });
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/shared/staff_layout_test.dart`
Expected: FAIL — `beams` is still empty.

- [ ] **Step 3: Compute groups in `computeStaffLayout`**

Replace `beams: const [],` with `beams: beams,` and, just before the `return`, build `beams` from the placements. Add:

```dart
  final beams = <BeamGroup>[];
  // Walk placements; group by (row, bar, beat).
  int beatOf(NotePlacement p) {
    final tickInBar = ((p.xCenter)); // not used; recomputed below
    return 0; // placeholder replaced below
  }

  // Recompute beat index per placement from cumulative ticks for grouping.
  // (Cheap second pass keeps grouping independent of pixel math.)
  final beatIndex = <int>[];
  {
    var t = 0;
    for (var i = 0; i < beats.length; i++) {
      final r = resolveNote(beats[i], grid);
      beatIndex.add((t % ticksPerBar) ~/ _ticksPerQuarter);
      t += (r.quarters * _ticksPerQuarter).round();
    }
  }

  int p = 0;
  while (p < placements.length) {
    final row = placements[p].row;
    final bar = placements[p].bar;
    final beat = beatIndex[placements[p].index];

    // Extent of this (row,bar,beat) window.
    var q = p;
    while (q < placements.length &&
        placements[q].row == row &&
        placements[q].bar == bar &&
        beatIndex[placements[q].index] == beat) {
      q++;
    }

    // Within [p, q): beam runs (same beamCount, non-rest, >=2) and tuplet runs.
    _emitBeamRuns(beats, placements, beamCountFor, beams, row, p, q);
    _emitTupletRuns(placements, beams, row, p, q);

    p = q;
  }
```

Then remove the unused `beatOf` stub and add the two helpers at the bottom of the file:

```dart
void _emitBeamRuns(
  List<StrokeBeat> beats,
  List<NotePlacement> placements,
  int Function(NoteValue) beamCountFor,
  List<BeamGroup> out,
  int row,
  int lo,
  int hi,
) {
  var i = lo;
  while (i < hi) {
    final pi = placements[i];
    final bc = pi.isRest ? 0 : beamCountFor(pi.resolved.value);
    if (bc == 0) {
      i++;
      continue;
    }
    var j = i;
    while (j + 1 < hi &&
        !placements[j + 1].isRest &&
        beamCountFor(placements[j + 1].resolved.value) == bc) {
      j++;
    }
    if (j > i) {
      out.add(BeamGroup(
        row: row,
        startIndex: placements[i].index,
        endIndex: placements[j].index,
        beamCount: bc,
        tuplet: Tuplet.none,
      ));
    }
    i = j + 1;
  }
}

void _emitTupletRuns(
  List<NotePlacement> placements,
  List<BeamGroup> out,
  int row,
  int lo,
  int hi,
) {
  var i = lo;
  while (i < hi) {
    final t = placements[i].resolved.tuplet;
    if (t == Tuplet.none || placements[i].isRest) {
      i++;
      continue;
    }
    var j = i;
    while (j + 1 < hi &&
        !placements[j + 1].isRest &&
        placements[j + 1].resolved.tuplet == t) {
      j++;
    }
    out.add(BeamGroup(
      row: row,
      startIndex: placements[i].index,
      endIndex: placements[j].index,
      beamCount: 0, // marker: this entry is a tuplet bracket, not a beam
      tuplet: t,
    ));
    i = j + 1;
  }
}
```

Note: also declare `final ticksPerBar = beatsPerBar * _ticksPerQuarter;` is already in scope from Task 5. Remove the placeholder `beatOf` function entirely.

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/shared/staff_layout_test.dart`
Expected: PASS (geometry + beams/tuplets).

- [ ] **Step 5: Analyze + commit**

```bash
flutter analyze lib/shared/widgets/staff_layout.dart
git add lib/shared/widgets/staff_layout.dart test/shared/staff_layout_test.dart
git commit -m "feat(notation): beam runs and tuplet groups in staff layout

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01MaUau8L3orqhR57QvKubqC"
```

---

### Task 7: Repaint the staff from StaffLayout

**Files:**
- Modify: `lib/shared/widgets/notation_staff_widget.dart`
- Test: `test/notation_staff_test.dart` (extend — regression + mixed fixture)

**Interfaces:**
- Consumes: `computeStaffLayout`, `StaffLayout`, `NotePlacement`, `BeamGroup`, `beamCountFor` (Tasks 5–6). Keeps the widget's public API (`NotationStaffWidget({rudiment, activeIndex})`).

- [ ] **Step 1: Extend the render test with a mixed-value fixture**

Add to `test/notation_staff_test.dart` inside the group:

```dart
    testWidgets('renders a mixed-value multi-bar étude without throwing',
        (tester) async {
      const etude = Rudiment(
        id: 'etude_mixed', name: 'Mixed', description: 'x',
        minBpm: 60, targetBpm: 120, difficulty: Difficulty.intermediate,
        gridUnit: NoteGrid.eighth, beatsPerBar: 4,
        sticking: [
          StrokeBeat(hand: Hand.right, value: NoteValue.quarter, isAccent: true),
          StrokeBeat(hand: Hand.left, value: NoteValue.eighth),
          StrokeBeat(hand: Hand.right, value: NoteValue.eighth),
          StrokeBeat(hand: Hand.left, value: NoteValue.sixteenth),
          StrokeBeat(hand: Hand.right, value: NoteValue.sixteenth),
          StrokeBeat(hand: Hand.left, value: NoteValue.eighth),
          StrokeBeat(hand: Hand.right, value: NoteValue.eighth, tuplet: Tuplet.triplet),
          StrokeBeat(hand: Hand.left, value: NoteValue.eighth, tuplet: Tuplet.triplet),
          StrokeBeat(hand: Hand.right, value: NoteValue.eighth, tuplet: Tuplet.triplet),
          StrokeBeat(hand: Hand.left, value: NoteValue.quarter),
        ],
      );
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SizedBox(width: 360, child: NotationStaffWidget(rudiment: etude)),
        ),
      ));
      expect(tester.takeException(), isNull);
    });
```

Add the imports the fixture needs at the top of the test file:
```dart
import 'package:drum_coach/features/lessons/models/rudiment.dart';
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/notation_staff_test.dart`
Expected: FAIL — the current cell-based `_StaffPainter` mis-sizes/ignores per-note values (existing "renders every seeded pattern" must keep passing; the mixed fixture exposes the gap). If it happens to not throw, it still asserts nothing about correctness — proceed to rebuild the painter so both the regression and mixed fixture are meaningful.

- [ ] **Step 3: Rewrite `_StaffPainter` to consume `StaffLayout`**

Replace the body of `_StaffPainter` so it computes a `StaffLayout` and paints from it, reusing the existing glyph helpers (`_drawHead`, `_drawAccent`, `_drawGraces`, `_drawFlags`, `_drawRest`, `_drawClef`, `_drawTimeSignature`, `_drawText`) unchanged. Key changes:

- Add `import 'staff_layout.dart';` at the top.
- In `NotationStaffWidget.build`, pass the same inputs; the painter now builds the layout internally:

```dart
        final painter = _StaffPainter(
          rudiment: rudiment,
          activeIndex: activeIndex,
          maxWidth: width,
        );
```

- Painter fields become:
```dart
  final Rudiment rudiment;
  final int? activeIndex;
  final double maxWidth;
  late final StaffLayout _layout = computeStaffLayout(
    beats: rudiment.sticking,
    grid: rudiment.gridUnit,
    beatsPerBar: rudiment.beatsPerBar,
    maxWidth: maxWidth,
    leftPad: _leftPad,
    rightPad: _rightPad,
    systemPad: _systemPad,
    barGap: _barGap,
  );
```

- `computeHeight()` → `_layout.rowCount * _rowH + 8`.
- `paint`: for each row, draw the five staff lines across the row's used width (max `xCenter` of that row's placements + a margin), the clef, the time signature on row 0, barlines at each bar boundary in the row (x = leftPad + systemPad + barInRow*(beatsPerBar*pxPerQuarter+barGap) - barGap/2), the cursor band at the active note's `xCenter` (find the placement whose `index == activeIndex`), then notes and beams:
  - For each `BeamGroup` with `beamCount>0` in the row: draw `beamCount` beam lines from the first to last placement's stem x at `stemTopY`.
  - For each `BeamGroup` with `tuplet != none`: draw the bracket + number ("3" for triplet, "6" for sextuplet) centered over the group at `_accentY`.
  - For each `NotePlacement`: if rest → `_drawRest` sized by `beamCountFor(resolved.value)`; else `_drawHead` (open head for `whole`/`half`), stem, `_drawFlags` when the note carries beams (beamCount>0) but is not inside any beam-run BeamGroup, accent, ghost parens, grace notes, and the R/L letter. Use `resolved.dotted` to draw a dot to the right of the head.

Concretely, replace the `_beamCount`/`_cellsPerBar`/`_cellsPerRow`/`_xForPosInRow` cell math and the `_paintBeamsAndNotes` beam-run detection with iteration over `_layout`. The per-note drawing loop mirrors the existing one but reads `placement.xCenter`, `placement.resolved`, and the active flag via `placement.index == activeIndex`. Keep `_rowH`, `_midY`, `_stemTopY`, `_accentY`, `_letterY`, `_headRx`, `_headRy`, colors, and all `_draw*` helpers.

Add a dotted-note dot helper (small filled circle right of the head) and open-notehead support in `_drawHead` (stroke instead of fill for `whole`/`half`):

```dart
  void _drawDot(Canvas canvas, Offset headCenter, Color color) {
    canvas.drawCircle(
        Offset(headCenter.dx + _headRx + 4, headCenter.dy), 1.6,
        Paint()..color = color);
  }
```

Update `shouldRepaint` to compare `rudiment`, `activeIndex`, `maxWidth`.

> Implementation note for the executor: this is the largest step. Keep every existing `_draw*` helper. The only structural change is *where coordinates come from* (the `StaffLayout` instead of uniform cells) and adding open heads + dots + a "6" tuplet label. Do not change audio, model, or playback here.

- [ ] **Step 4: Run tests to verify they pass**

Run: `flutter test test/notation_staff_test.dart`
Expected: PASS — both "renders every seeded pattern without throwing" (regression) and the new mixed-value fixture.

- [ ] **Step 5: Full suite + analyze**

Run: `flutter test`
Expected: PASS (all suites).
Run: `flutter analyze lib/shared/widgets/`
Expected: no issues.

- [ ] **Step 6: Commit**

```bash
git add lib/shared/widgets/notation_staff_widget.dart test/notation_staff_test.dart
git commit -m "feat(notation): render duration-proportional staff from StaffLayout

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01MaUau8L3orqhR57QvKubqC"
```

---

### Task 8: Seed integrity — dedupe ids + bar-sum validation

**Files:**
- Modify: `lib/features/lessons/data/rudiments_seed.dart`
- Test: `test/lessons/seed_integrity_test.dart`

**Interfaces:**
- Consumes: `rudimentsSeedData`, `resolveNote`, `rudiment.gridUnit`, `rudiment.beatsPerBar` (existing / Task 1).

- [ ] **Step 1: Write the failing test**

```dart
// test/lessons/seed_integrity_test.dart
import 'package:drum_coach/features/lessons/data/rudiments_seed.dart';
import 'package:drum_coach/features/lessons/models/rudiment.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('all rudiment ids are unique', () {
    final ids = rudimentsSeedData.map((r) => r.id).toList();
    final dupes = <String>{};
    final seen = <String>{};
    for (final id in ids) {
      if (!seen.add(id)) dupes.add(id);
    }
    expect(dupes, isEmpty, reason: 'duplicate ids: $dupes');
  });

  test('each pattern fills whole bars (sum of durations == n * beatsPerBar)', () {
    for (final r in rudimentsSeedData) {
      var quarters = 0.0;
      for (final b in r.sticking) {
        quarters += resolveNote(b, r.gridUnit).quarters;
      }
      final bars = quarters / r.beatsPerBar;
      expect((bars - bars.roundToDouble()).abs() < 1e-6, isTrue,
          reason: '${r.id}: ${quarters}q is not a whole number of '
              '${r.beatsPerBar}/4 bars');
    }
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/lessons/seed_integrity_test.dart`
Expected: FAIL on the uniqueness test — duplicates `paradiddle_diddle`, `flam_accent`, `flam_paradiddle`. (The bar-sum test should already pass for the uniform legacy data; if any entry fails it, that pre-existing data bug is surfaced here — fix by correcting that entry's `beatsPerBar`/sticking.)

- [ ] **Step 3: Rename the later duplicate ids**

In `rudiments_seed.dart`, the marching-snare block (later in the file) re-declares three ids that already exist earlier. Rename the **marching-block** occurrences to unique ids and keep the earlier ones:
- second `paradiddle_diddle` (~line 1012) → `paradiddle_diddle_corps`
- second `flam_accent` (~line 1641) → `flam_accent_corps`
- second `flam_paradiddle` (~line 1738) → `flam_paradiddle_corps`

Verify no other code references those ids as string literals:
Run: `grep -rn "paradiddle_diddle\|flam_accent\|flam_paradiddle" lib test | grep -v rudiments_seed.dart`
Expected: no program/routine code depends on the renamed corps entries (the program uses `single_stroke_roll`/`double_stroke_roll`/`single_paradiddle`). If a reference exists, point it at the intended id.

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/lessons/seed_integrity_test.dart`
Expected: PASS (unique ids + whole-bar patterns).

- [ ] **Step 5: Commit**

```bash
git add lib/features/lessons/data/rudiments_seed.dart test/lessons/seed_integrity_test.dart
git commit -m "fix(seed): dedupe rudiment ids + add bar-sum integrity test

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01MaUau8L3orqhR57QvKubqC"
```

---

### Task 9: Full verification pass

**Files:** none (verification only).

- [ ] **Step 1: Whole suite green**

Run: `flutter test`
Expected: all suites PASS, including the pre-existing tests.

- [ ] **Step 2: Analyzer clean**

Run: `flutter analyze`
Expected: no issues.

- [ ] **Step 3: Device/visual verification (via cross-machine-test-deploy)**

Deploy to PC/Laptop or the Android device and check:
1. A mixed-value étude (like the Task 7 fixture) renders with correct note values, beams, a triplet bracket, accents, and multi-bar wrapping.
2. Playback: the cursor sits on the sounding note; the rhythm is audibly correct at several BPMs.
3. A legacy entry (`single_paradiddle`, `flam_tap`, a `triplet`-grid one) looks and plays exactly as before.

Record the result (screenshots + any timing/jitter note) in the PR description.

- [ ] **Step 4: Update the PR**

Push and open/update the draft PR for `feature/drum-etudes`; note SP1 complete, device verification attached, mic-analysis deferred.

---

## Self-Review

**Spec coverage:**
- NoteValue + tuplets + StrokeBeat fields → Task 1. ✓
- Duration derivation / backward-compat → Task 1 (`resolveNote`, `gridToNote`). ✓
- Fine-grid playback (24/quarter) + reuse `setPatternVolumes` → Tasks 2–4. ✓
- Isolate untouched, arbitrary factor → Task 3. ✓
- Cursor mapping → Tasks 2 & 4 (`noteIndexAtTick`). ✓
- Duration-proportional renderer, beams, tuplet brackets, rests, dotted/open heads → Tasks 5–7. ✓
- Migration of 41 entries (auto via `gridToNote`) + duplicate-id cleanup → Tasks 1 & 8. ✓
- Bar-sum validation test → Task 8. ✓
- Mic-analysis untouched/deferred → Global Constraints (no task modifies it). ✓
- Device verification → Task 9. ✓

**Placeholder scan:** DSL explicitly deferred to SP3 (scope note), not a placeholder. Task 7 carries an implementation note but every coordinate source, helper reuse, and new helper (`_drawDot`, open heads) is specified. No TBD/TODO.

**Type consistency:** `resolveNote(StrokeBeat, NoteGrid) → ResolvedNote`; `ResolvedNote(value, dotted, tuplet)` positional; `beamCountFor(NoteValue)→int`; `PatternPlayback.{ticksPerQuarter,totalTicks,tickVolumes,onsetTicks,noteIndexAtTick,forRudiment}`; `computeStaffLayout(...)→StaffLayout{rowCount,pxPerQuarter,beatsPerBar,barsPerRow,placements,beams}`; `NotePlacement{index,row,bar,xCenter,resolved,isRest}`; `BeamGroup{row,startIndex,endIndex,beamCount,tuplet}`. Names are consistent across tasks.
