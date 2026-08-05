# Notation Engraving, Smooth Cursor & Unified Tempo — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make the single-line drum notation look engraved (Bravura glyphs), give it a smoothly gliding playback cursor, and fix the tempo model so BPM means the same thing everywhere — plus instrument audio jitter for a later fix.

**Architecture:** Keep the existing `CustomPainter` layout engine; swap hand-drawn shapes for Bravura (SMuFL) font glyphs. Make note-onset timing a pure function of `(bpm, gridUnit.cellsPerQuarter)` — BPM is always the quarter-note pulse — and route exercise playback through a raw integer grid-factor instead of the 4-capped `Subdivision` enum. Drive the cursor with an `AnimationController` that free-runs at the cell tempo and re-syncs on each beat event.

**Tech Stack:** Flutter, Dart 3, Riverpod (`@riverpod` codegen), `flutter_soloud` (metronome audio, dedicated timing isolate), Bravura OTF (SIL OFL 1.1).

## Global Constraints

- Dart 3, null-safe; Material 3 dark theme only.
- Metronome audio MUST use `flutter_soloud` — never `just_audio`/`audioplayers`.
- **Tempo invariant:** BPM is always the quarter-note pulse. Onset rate = `bpm × gridUnit.cellsPerQuarter`. Nothing else may scale playback speed.
- Bravura sizing: `em = 4 staff spaces`, i.e. glyph `fontSize = 4 × _lineGap`. Font family string is exactly `'Bravura'`; asset at `assets/fonts/Bravura.otf` (already committed).
- `NotationStaffWidget` public API stays backward-compatible: every new parameter is optional and defaults to today's behavior.
- No `Ticker`/`AnimationController` may run while `isPlaying == false` (otherwise widget tests fail with pending timers).
- `NoteGrid.cellsPerQuarter`: quarter=1, eighth=2, triplet=3, sixteenth=4, sixteenthTriplet=6, thirtySecond=8.
- Run `flutter analyze` before every commit; it must be clean.

## File Structure

- **Create** `lib/features/metronome/tempo.dart` — pure timing helpers (onset factor, cell/quarter durations, cursor fraction). No Flutter/audio deps except `Duration`.
- **Create** `test/tempo_test.dart` — unit tests for the helpers.
- **Modify** `lib/features/metronome/metronome_engine.dart` — add `setGridFactor(int)`; add optional jitter instrumentation.
- **Modify** `lib/features/metronome/metronome_provider.dart` — add `setGridFactor(int)` + `reassertSubdivision()`.
- **Modify** `lib/features/practice/practice_session_screen.dart` — derive onset factor + `perCellDuration` from `gridUnit`; remove `_subdivisionFor`; fix dispose.
- **Modify** `lib/shared/widgets/notation_staff_widget.dart` — beat counter, Bravura glyphs, smooth cursor (Stateless→Stateful).
- **Modify** `pubspec.yaml` — declare Bravura font + `assets/fonts/`.
- **Modify** `test/notation_staff_test.dart` — keep green; extend for the smooth-cursor params.

---

### Task 1: Pure tempo helpers (fixes the tempo model in isolation)

**Files:**
- Create: `lib/features/metronome/tempo.dart`
- Test: `test/tempo_test.dart`

**Interfaces:**
- Produces:
  - `int onsetFactorFor(NoteGrid grid)` → `grid.cellsPerQuarter` (no cap).
  - `int onsetIntervalMicros(int bpm, int cellsPerQuarter)`
  - `int quarterPulseMicros(int bpm)`
  - `Duration cellDuration(int bpm, int cellsPerQuarter)`
  - `double cursorFraction(int anchorIndex, Duration elapsed, Duration perCell)`

- [ ] **Step 1: Write the failing test**

```dart
// test/tempo_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:drum_coach/features/lessons/models/rudiment.dart';
import 'package:drum_coach/features/metronome/tempo.dart';

void main() {
  group('onsetFactorFor (no factor-4 cap — Bug 1)', () {
    test('dense grids keep their true cells-per-quarter', () {
      expect(onsetFactorFor(NoteGrid.eighth), 2);
      expect(onsetFactorFor(NoteGrid.sixteenth), 4);
      expect(onsetFactorFor(NoteGrid.sixteenthTriplet), 6); // was capped to 4
      expect(onsetFactorFor(NoteGrid.thirtySecond), 8);     // was capped to 4
    });
  });

  group('tempo reference is the quarter pulse for every grid', () {
    test('same BPM => same quarter pulse regardless of grid', () {
      expect(quarterPulseMicros(140), 428571);
      // eighth vs sixteenth exercise at 140 share the quarter pulse...
      expect(onsetIntervalMicros(140, 2) * 2, closeTo(428571, 3));
      expect(onsetIntervalMicros(140, 4) * 4, closeTo(428571, 4));
    });

    test('onset interval halves when the grid doubles', () {
      expect(onsetIntervalMicros(140, 2), 214285);
      expect(onsetIntervalMicros(140, 4), 107142);
    });

    test('cellDuration mirrors onsetIntervalMicros', () {
      expect(cellDuration(140, 2).inMicroseconds, 214285);
    });
  });

  group('cursorFraction', () {
    test('starts at the anchor and advances linearly, clamped', () {
      const per = Duration(microseconds: 214285);
      expect(cursorFraction(2, Duration.zero, per), 2.0);
      expect(cursorFraction(2, const Duration(microseconds: 107142), per),
          closeTo(2.5, 0.01));
      expect(cursorFraction(2, per, per), 3.0);
      expect(cursorFraction(2, per * 2, per), 3.0); // clamped
    });

    test('degenerate perCell returns the anchor', () {
      expect(cursorFraction(5, const Duration(milliseconds: 10), Duration.zero),
          5.0);
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/tempo_test.dart`
Expected: FAIL — `tempo.dart` / functions not defined.

- [ ] **Step 3: Write minimal implementation**

```dart
// lib/features/metronome/tempo.dart
import '../lessons/models/rudiment.dart';

/// Onsets per quarter note for a notation [grid]. BPM is always the
/// quarter-note pulse, so this is exactly the grid's cells-per-quarter —
/// with NO cap (the old `_subdivisionFor` capped 6/8 down to 4, Bug 1).
int onsetFactorFor(NoteGrid grid) => grid.cellsPerQuarter;

/// Microseconds of one quarter-note pulse. Grid-independent.
int quarterPulseMicros(int bpm) => 60000000 ~/ bpm;

/// Microseconds between consecutive note onsets at [bpm] for a grid of
/// [cellsPerQuarter].
int onsetIntervalMicros(int bpm, int cellsPerQuarter) =>
    60000000 ~/ bpm ~/ cellsPerQuarter;

/// Duration one grid cell occupies — the notation cursor's per-cell time and
/// the audio onset interval are the SAME quantity.
Duration cellDuration(int bpm, int cellsPerQuarter) =>
    Duration(microseconds: onsetIntervalMicros(bpm, cellsPerQuarter));

/// Fractional cell position of the playback cursor: [anchorIndex] plus how far
/// we've progressed toward the next cell (0..1), given [elapsed] since the
/// anchor beat and the [perCell] cell duration. Clamped to
/// `[anchorIndex, anchorIndex + 1]`.
double cursorFraction(int anchorIndex, Duration elapsed, Duration perCell) {
  if (perCell.inMicroseconds <= 0) return anchorIndex.toDouble();
  final t = (elapsed.inMicroseconds / perCell.inMicroseconds).clamp(0.0, 1.0);
  return anchorIndex + t;
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/tempo_test.dart`
Expected: PASS (all 6 tests).

- [ ] **Step 5: Analyze + commit**

```bash
flutter analyze lib/features/metronome/tempo.dart test/tempo_test.dart
git add lib/features/metronome/tempo.dart test/tempo_test.dart
git commit -m "Add pure tempo helpers: onset factor (uncapped), cell/quarter durations, cursor fraction"
```

---

### Task 2: Engine + provider accept an arbitrary grid factor

**Files:**
- Modify: `lib/features/metronome/metronome_engine.dart`
- Modify: `lib/features/metronome/metronome_provider.dart`
- Test: `test/metronome_delay_test.dart` (create)

**Interfaces:**
- Consumes: `computeNextBeatDelayUs(...)` (existing, already factor-agnostic).
- Produces:
  - `MetronomeEngine.setGridFactor(int cellsPerQuarter)` — sends the raw factor to the timing isolate; does NOT touch the `Subdivision` state.
  - `MetronomeNotifier.setGridFactor(int cellsPerQuarter)` — stop/restart-if-playing wrapper; leaves `state.subdivision` untouched.
  - `MetronomeNotifier.reassertSubdivision()` — re-sends `state.subdivision` to the engine (used to restore the plain-metronome factor after exercise playback).

- [ ] **Step 1: Write the failing test** (guards that the engine math handles 6/8, which the old cap hid)

```dart
// test/metronome_delay_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:drum_coach/features/metronome/metronome_engine.dart';

void main() {
  group('computeNextBeatDelayUs handles dense grids (factor 6 & 8)', () {
    int delay(int factor) => computeNextBeatDelayUs(
          bpm: 140,
          factor: factor,
          idx: 1,
          anchorUs: 0,
          anchorIdx: 0,
          elapsedUs: 0,
        );

    test('factor 6 => one sixteenth-triplet interval', () {
      // 60_000_000 / 140 / 6 = 71428.57 -> rounded 71429
      expect(delay(6), 71429);
    });

    test('factor 8 => one thirty-second interval', () {
      // 60_000_000 / 140 / 8 = 53571.4 -> rounded 53571
      expect(delay(8), 53571);
    });
  });
}
```

- [ ] **Step 2: Run test to verify it passes as a characterization guard**

Run: `flutter test test/metronome_delay_test.dart`
Expected: PASS. (The pure function already supports any factor; this test locks that in so a future cap can't silently return.)

- [ ] **Step 3: Add `setGridFactor` to the engine**

In `lib/features/metronome/metronome_engine.dart`, inside `class MetronomeEngine`, directly below `setSubdivision(...)`:

```dart
  /// Sets the onset rate directly as onsets-per-quarter (e.g. an exercise's
  /// `gridUnit.cellsPerQuarter`, which may be 6 or 8 — beyond the Subdivision
  /// enum's range). Leaves the [Subdivision] state alone so the plain
  /// metronome's selector is unaffected.
  void setGridFactor(int cellsPerQuarter) {
    _controlPort?.send([_cmdFactor, cellsPerQuarter]);
  }
```

- [ ] **Step 4: Add `setGridFactor` + `reassertSubdivision` to the provider**

In `lib/features/metronome/metronome_provider.dart`, inside `class MetronomeNotifier`, below `setSubdivision(...)`:

```dart
  /// Exercise playback: drive the onset rate from the pattern's grid, not the
  /// user-facing Subdivision. Does not change [MetronomeState.subdivision].
  void setGridFactor(int cellsPerQuarter) {
    final wasPlaying = state.isPlaying;
    if (wasPlaying) _engine?.stop();
    _engine?.setGridFactor(cellsPerQuarter);
    if (wasPlaying) _engine?.start();
  }

  /// Restore the isolate's onset factor to the plain-metronome subdivision
  /// (call when leaving exercise playback).
  void reassertSubdivision() {
    _engine?.setSubdivision(state.subdivision);
  }
```

- [ ] **Step 5: Analyze + commit**

```bash
flutter analyze lib/features/metronome/ test/metronome_delay_test.dart
git add lib/features/metronome/metronome_engine.dart lib/features/metronome/metronome_provider.dart test/metronome_delay_test.dart
git commit -m "Engine/provider: setGridFactor for uncapped grid-driven onset rate + reassertSubdivision"
```

---

### Task 3: Practice screen drives timing from gridUnit (removes the cap + wires perCellDuration)

**Files:**
- Modify: `lib/features/practice/practice_session_screen.dart`

**Interfaces:**
- Consumes: `onsetFactorFor`, `cellDuration` (Task 1); `setGridFactor`, `reassertSubdivision` (Task 2).
- Produces: `NotationStaffWidget` now receives `perCellDuration` + `isPlaying` (consumed in Task 6).

- [ ] **Step 1: Add the tempo import**

At the top of `lib/features/practice/practice_session_screen.dart`, with the other imports:

```dart
import '../metronome/tempo.dart';
```

- [ ] **Step 2: Replace the capped subdivision setup in `initState`**

Find in the `addPostFrameCallback` (currently):

```dart
      final metronome = _metronomeNotifier
        ..setSubdivision(_subdivisionFor(rudiment.gridUnit))
        ..setPatternVolumes(_volumesFor(rudiment.sticking));
```

Replace with:

```dart
      final metronome = _metronomeNotifier
        ..setGridFactor(onsetFactorFor(rudiment.gridUnit))
        ..setPatternVolumes(_volumesFor(rudiment.sticking));
```

- [ ] **Step 3: Delete the now-unused `_subdivisionFor` helper**

Remove the whole method (currently lines ~84–90):

```dart
  static Subdivision _subdivisionFor(NoteGrid grid) => switch (grid) {
        NoteGrid.quarter => Subdivision.quarter,
        NoteGrid.eighth => Subdivision.eighth,
        NoteGrid.triplet => Subdivision.triplet,
        NoteGrid.sixteenth => Subdivision.sixteenth,
        NoteGrid.sixteenthTriplet => Subdivision.sixteenth,
        NoteGrid.thirtySecond => Subdivision.sixteenth,
      };
```

- [ ] **Step 4: Fix `dispose` to restore the plain-metronome factor (not force quarter)**

In `dispose`, change the deferred block from:

```dart
      _metronomeNotifier
        ..stop()
        ..setPatternVolumes(null)
        ..setSubdivision(Subdivision.quarter);
```

to:

```dart
      _metronomeNotifier
        ..stop()
        ..setPatternVolumes(null)
        ..reassertSubdivision();
```

- [ ] **Step 5: Pass per-cell timing to the notation widget**

Locate the `NotationStaffWidget(...)` call (currently `rudiment: rudiment, activeIndex: activeBeat`). Just before the `return Scaffold(...)` you already compute `activeBeat`; add next to it:

```dart
    final perCell = cellDuration(metState.bpm, rudiment.gridUnit.cellsPerQuarter);
```

Then update the widget call to:

```dart
                    child: NotationStaffWidget(
                      rudiment: rudiment,
                      activeIndex: activeBeat,
                      perCellDuration: perCell,
                      isPlaying: metState.isPlaying,
                    ),
```

- [ ] **Step 6: Verify the codebase still analyzes and the notation test is green**

Run: `flutter analyze lib/features/practice/practice_session_screen.dart`
Expected: clean (no unused `_subdivisionFor`, no missing symbols). Note: `NotationStaffWidget`'s new params are added in Task 6; if executing strictly in order, add the optional params to the widget's constructor FIRST (see Task 6 Step 3) or expect an "undefined named parameter" error here — resolve by doing Task 6 before re-analyzing. See Step 7.

- [ ] **Step 7: Commit**

```bash
git add lib/features/practice/practice_session_screen.dart
git commit -m "Practice: drive onset rate + cursor timing from gridUnit (fix Bug 1 cap + split-brain)"
```

> **Sequencing note:** Tasks 3 and 6 both touch the `NotationStaffWidget` contract. If a reviewer runs `flutter analyze` on the whole app between them it will flag the not-yet-added params. Either (a) run Task 6 Step 3 (add the optional constructor params) immediately after Task 3 Step 5, then analyze; or (b) treat Tasks 3+6 as one review gate. The recommended order is: Task 3 Steps 1–5 → Task 6 (full) → then app-wide `flutter analyze`.

---

### Task 4: Beat counter under the staff (visible 4/4 reference)

**Files:**
- Modify: `lib/shared/widgets/notation_staff_widget.dart`
- Test: `test/notation_staff_test.dart` (existing — keep green)

**Interfaces:**
- Consumes: existing `_StaffPainter` metrics (`_cellsPerBeat`, `beatsPerBar`, `_xForPosInRow`).
- Produces: beat numbers `1 2 3 4` drawn at each quarter position below the R/L letters.

- [ ] **Step 1: Add metrics for the beat-number row**

In `_StaffPainter`, near the other vertical positions, change `_rowH` and add `_beatNumY`:

```dart
  static const double _rowH = 120; // was 104 — room for the beat-number row
```
```dart
  static const double _beatNumY = 104; // beat numbers, below the R/L letters
```

Add a colour near the other colours:

```dart
  static const _beatNumColor = Color(0x77FFC107); // dim amber, the pulse anchor
```

- [ ] **Step 2: Draw the beat numbers in `_paintRow`**

At the end of `_paintRow`, after `_paintBeamsAndNotes(...)`, add:

```dart
    // Beat-counter row: one number per quarter-note pulse (the 4/4 reference).
    for (var i = 0; i < count; i++) {
      if (i % _cellsPerBeat != 0) continue;
      final beatInBar = (i ~/ _cellsPerBeat) % beatsPerBar + 1;
      _drawText(canvas, '$beatInBar', Offset(_xForPosInRow(i), baseY + _beatNumY),
          _beatNumColor, 11, bold: true);
    }
```

- [ ] **Step 3: Run the existing widget test (renders without throwing, height > 0)**

Run: `flutter test test/notation_staff_test.dart`
Expected: PASS. (Height grows with the larger `_rowH`; the test only asserts `height > 0`.)

- [ ] **Step 4: Commit**

```bash
git add lib/shared/widgets/notation_staff_widget.dart
git commit -m "Notation: add beat-counter row under the staff (visible 4/4 reference)"
```

---

### Task 5: Bravura (SMuFL) glyph rendering

**Files:**
- Modify: `pubspec.yaml`
- Modify: `lib/shared/widgets/notation_staff_widget.dart`
- Test: `test/notation_staff_test.dart` (keep green)

**Interfaces:**
- Consumes: font asset `assets/fonts/Bravura.otf` (already committed).
- Produces: `_drawGlyph(...)` + `_Smufl` codepoints; notehead/clef/rest/flag/accent/time-signature/ghost drawn from the font.

- [ ] **Step 1: Declare the font + assets in `pubspec.yaml`**

Under the existing `flutter:` section, add (keep 2-space nesting exactly):

```yaml
  assets:
    - assets/fonts/OFL.txt
  fonts:
    - family: Bravura
      fonts:
        - asset: assets/fonts/Bravura.otf
```

- [ ] **Step 2: Fetch dependencies**

Run: `flutter pub get`
Expected: success; no manifest errors.

- [ ] **Step 3: Add the SMuFL codepoints + a glyph-draw helper**

In `notation_staff_widget.dart`, above `class NotationStaffWidget`, add:

```dart
/// Bravura (SMuFL) codepoints used by the drum staff. See smufl.org.
class _Smufl {
  static const clefPerc     = ''; // unpitchedPercussionClef1
  static const noteheadBlack = '';
  static const parenLeft    = ''; // noteheadParenthesisLeft
  static const parenRight   = ''; // noteheadParenthesisRight
  static const flag8Up      = '';
  static const flag16Up     = '';
  static const flag32Up     = '';
  static const accent       = ''; // articAccentAbove
  static const restQuarter  = '';
  static const rest8        = '';
  static const rest16       = '';
  static const rest32       = '';
  static String timeSig(int digit) => String.fromCharCode(0xE080 + digit);
}
```

Inside `_StaffPainter`, add the glyph helper (near `_drawText`):

```dart
  /// Draws a Bravura glyph centred horizontally on [center].x, with its
  /// alphabetic baseline placed on [center].y (SMuFL noteheads/rests register
  /// on the baseline). [dyStaffSpaces] nudges per-glyph; [emScale] overrides
  /// the default staff-scaled em (4 staff spaces).
  void _drawGlyph(Canvas canvas, String glyph, Offset center, Color color,
      {double dyStaffSpaces = 0, double emScale = 4}) {
    final tp = TextPainter(
      text: TextSpan(
        text: glyph,
        style: TextStyle(
          fontFamily: 'Bravura',
          fontSize: emScale * _lineGap,
          color: color,
          height: 1.0,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    final baseline = tp.computeDistanceToActualBaseline(TextBaseline.alphabetic)
        ?? tp.height;
    tp.paint(
      canvas,
      Offset(center.dx - tp.width / 2,
          center.dy - baseline + dyStaffSpaces * _lineGap),
    );
  }
```

- [ ] **Step 4: Replace the notehead, clef, time signature, rest, flag, accent, and ghost drawing**

Swap the hand-drawn calls for glyph calls. Concretely:

`_drawClef` body → replace the two-bar loop with:
```dart
  void _drawClef(Canvas canvas, double staffY) {
    _drawGlyph(canvas, _Smufl.clefPerc, Offset(_leftPad + 18, staffY),
        _inkColor.withValues(alpha: 0.9));
  }
```

`_drawTimeSignature` → stack two glyph digits:
```dart
  void _drawTimeSignature(Canvas canvas, double staffY) {
    const x = _leftPad + 32.0;
    _drawGlyph(canvas, _Smufl.timeSig(beatsPerBar),
        Offset(x, staffY - _lineGap), _inkColor);
    _drawGlyph(canvas, _Smufl.timeSig(4), Offset(x, staffY + _lineGap), _inkColor);
  }
```

`_drawHead` → for the normal (non-ghost) head use the glyph; keep the small stroked oval for ghosts OR use parenthesis glyphs (Step 6). Replace the filled branch:
```dart
  void _drawHead(Canvas canvas, Offset c, Color color,
      {bool ghost = false, bool active = false}) {
    if (ghost) {
      final rect = Rect.fromCenter(
          center: c, width: _headRx * 1.56, height: _headRy * 1.56);
      canvas.drawOval(
          rect,
          Paint()
            ..color = color
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.4);
    } else {
      _drawGlyph(canvas, _Smufl.noteheadBlack, c, color);
    }
    if (active) {
      _drawGlyph(canvas, _Smufl.noteheadBlack, c,
          color.withValues(alpha: 0.35), emScale: 4.6);
    }
  }
```

`_drawAccent` → glyph:
```dart
  void _drawAccent(Canvas canvas, Offset c, Color color) {
    _drawGlyph(canvas, _Smufl.accent, c, _accentColor);
  }
```

`_drawRest` → map grid to a rest glyph:
```dart
  void _drawRest(Canvas canvas, Offset c) {
    final glyph = switch (grid) {
      NoteGrid.quarter => _Smufl.restQuarter,
      NoteGrid.eighth || NoteGrid.triplet => _Smufl.rest8,
      NoteGrid.sixteenth || NoteGrid.sixteenthTriplet => _Smufl.rest16,
      NoteGrid.thirtySecond => _Smufl.rest32,
    };
    _drawGlyph(canvas, glyph, c, _ghostColor);
  }
```

Flags: in `_paintBeamsAndNotes`, replace the `_drawFlags(...)` call with a glyph flag. Replace `_drawFlags` with:
```dart
  void _drawFlags(Canvas canvas, double stemX, double stemTopY, Color color) {
    final glyph = switch (_beamCount) {
      1 => _Smufl.flag8Up,
      2 => _Smufl.flag16Up,
      _ => _Smufl.flag32Up,
    };
    // Flag hangs off the stem top; register near the notehead line then lift.
    _drawGlyph(canvas, glyph, Offset(stemX + 3, stemTopY), color,
        dyStaffSpaces: -1.5);
  }
```

- [ ] **Step 5: Replace ghost parentheses text with parenthesis glyphs**

In `_paintBeamsAndNotes`, the ghost branch currently draws `'('` and `')'` via `_drawText`. Replace with:
```dart
      if (beat.isGhost) {
        _drawGlyph(canvas, _Smufl.parenLeft,
            Offset(x - _headRx - 3, staffY), _ghostColor);
        _drawGlyph(canvas, _Smufl.parenRight,
            Offset(x + _headRx + 3, staffY), _ghostColor);
      }
```

- [ ] **Step 6: Run the widget test (font falls back silently in test env; must not throw)**

Run: `flutter test test/notation_staff_test.dart`
Expected: PASS. (Bravura is not loaded in the test harness; Flutter substitutes a fallback glyph — rendering must still not throw and height stays > 0.)

- [ ] **Step 7: Commit**

```bash
git add pubspec.yaml lib/shared/widgets/notation_staff_widget.dart
git commit -m "Notation: render clef/notes/rests/flags/accents/time-sig with Bravura glyphs"
```

> **On-device calibration (record, do not skip):** The `dyStaffSpaces` nudges and the flag offset are first estimates. Visual vertical alignment can only be judged with Bravura actually loaded — verify + tune on PC/phone via the `cross-machine-test-deploy` skill. Adjust the per-glyph `dyStaffSpaces` constants until noteheads sit centred on the middle line and rests/flags align.

---

### Task 6: Smooth interpolating cursor

**Files:**
- Modify: `lib/shared/widgets/notation_staff_widget.dart`
- Test: `test/notation_staff_test.dart`

**Interfaces:**
- Consumes: `cursorFraction` (Task 1); `perCellDuration` + `isPlaying` from the practice screen (Task 3).
- Produces: `NotationStaffWidget({..., Duration? perCellDuration, bool isPlaying})`; painter takes a `double? cursorPos` fractional position.

- [ ] **Step 1: Write a widget test for the new params (must not throw, no pending timers)**

Add to `test/notation_staff_test.dart`, inside the group:

```dart
    testWidgets('accepts playback params and settles without pending timers',
        (tester) async {
      final rudiment = rudimentsSeedData.first;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 360,
              child: NotationStaffWidget(
                rudiment: rudiment,
                activeIndex: 1,
                perCellDuration: const Duration(milliseconds: 200),
                isPlaying: true,
              ),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));
      // Stop playback -> controller must stop (no pending-timer failure on end).
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 360,
              child: NotationStaffWidget(
                rudiment: rudiment,
                activeIndex: 1,
                isPlaying: false,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
```

- [ ] **Step 2: Run to verify it fails**

Run: `flutter test test/notation_staff_test.dart`
Expected: FAIL — `perCellDuration`/`isPlaying` are undefined named parameters.

- [ ] **Step 3: Convert the widget to Stateful with an AnimationController**

Replace the `NotationStaffWidget` class (Stateless) with:

```dart
class NotationStaffWidget extends StatefulWidget {
  final Rudiment rudiment;
  final int? activeIndex;
  final Duration? perCellDuration;
  final bool isPlaying;

  const NotationStaffWidget({
    super.key,
    required this.rudiment,
    this.activeIndex,
    this.perCellDuration,
    this.isPlaying = false,
  });

  @override
  State<NotationStaffWidget> createState() => _NotationStaffWidgetState();
}

class _NotationStaffWidgetState extends State<NotationStaffWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this);
    _syncController();
  }

  @override
  void didUpdateWidget(NotationStaffWidget old) {
    super.didUpdateWidget(old);
    if (old.activeIndex != widget.activeIndex ||
        old.isPlaying != widget.isPlaying ||
        old.perCellDuration != widget.perCellDuration) {
      _syncController();
    }
  }

  /// Re-anchor: whenever a new beat arrives, run the controller 0->1 over one
  /// cell so the cursor glides from this cell to the next. Never run while
  /// stopped (keeps widget tests free of pending timers).
  void _syncController() {
    final per = widget.perCellDuration;
    if (widget.isPlaying && widget.activeIndex != null && per != null &&
        per.inMicroseconds > 0) {
      _ctrl
        ..duration = per
        ..forward(from: 0);
    } else {
      _ctrl.stop();
      _ctrl.value = 0;
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.of(context).size.width;
        return AnimatedBuilder(
          animation: _ctrl,
          builder: (context, _) {
            final anchor = widget.activeIndex;
            final cursorPos = (widget.isPlaying && anchor != null)
                ? anchor + _ctrl.value
                : anchor?.toDouble();
            return CustomPaint(
              size: Size(
                  width,
                  _StaffPainter(
                    beats: widget.rudiment.sticking,
                    grid: widget.rudiment.gridUnit,
                    beatsPerBar: widget.rudiment.beatsPerBar,
                    activeIndex: anchor,
                    cursorPos: cursorPos,
                    maxWidth: width,
                  ).computeHeight()),
              painter: _StaffPainter(
                beats: widget.rudiment.sticking,
                grid: widget.rudiment.gridUnit,
                beatsPerBar: widget.rudiment.beatsPerBar,
                activeIndex: anchor,
                cursorPos: cursorPos,
                maxWidth: width,
              ),
            );
          },
        );
      },
    );
  }
}
```

- [ ] **Step 4: Add `cursorPos` to `_StaffPainter` and paint the cursor at the fractional x**

Add the field + constructor param:
```dart
  final double? cursorPos; // fractional cell position for the gliding cursor
```
```dart
    required this.cursorPos,
```

Add a fractional-x helper next to `_xForPosInRow`:
```dart
  double _xForFracInRow(double posInRow) {
    final base = posInRow.floor();
    final frac = posInRow - base;
    final x0 = _xForPosInRow(base);
    final x1 = _xForPosInRow(base + 1);
    return x0 + (x1 - x0) * frac;
  }
```

In `_paintRow`, replace the "Active cursor band" block's `cx` computation. Currently it uses `activeIndex`. Change it to prefer the fractional position:
```dart
    // Active cursor band (glides between cells when cursorPos is set).
    final cp = cursorPos;
    if (cp != null && cp >= start && cp < end) {
      final cx = _xForFracInRow(cp - start);
      final cursorPaint = Paint()..color = _activeColor.withValues(alpha: 0.14);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
              center: Offset(cx, baseY + _rowH / 2),
              width: _cellW - 4,
              height: _rowH - 16),
          const Radius.circular(8),
        ),
        cursorPaint,
      );
      final linePaint = Paint()
        ..color = _activeColor.withValues(alpha: 0.55)
        ..strokeWidth = 1.5;
      canvas.drawLine(Offset(cx, baseY + 10),
          Offset(cx, baseY + _rowH - 10), linePaint);
    }
```
(The `activeIndex`-based notehead highlight in `_paintBeamsAndNotes` stays — the head lights up on the discrete anchor while the band glides.)

- [ ] **Step 5: Update `shouldRepaint` for the new field**

```dart
  @override
  bool shouldRepaint(_StaffPainter old) =>
      old.activeIndex != activeIndex ||
      old.cursorPos != cursorPos ||
      old.beats != beats ||
      old.grid != grid ||
      old.beatsPerBar != beatsPerBar ||
      old.maxWidth != maxWidth;
```

- [ ] **Step 6: Run the tests**

Run: `flutter test test/notation_staff_test.dart test/tempo_test.dart`
Expected: PASS (including the new no-pending-timer test).

- [ ] **Step 7: App-wide analyze (now the Task 3 wiring resolves) + commit**

Run: `flutter analyze`
Expected: clean across the app (practice screen's new params now exist).

```bash
git add lib/shared/widgets/notation_staff_widget.dart test/notation_staff_test.dart
git commit -m "Notation: smooth interpolating playback cursor (AnimationController + resync)"
```

---

### Task 7: Jitter instrumentation (measure-first for Bug 2)

**Files:**
- Modify: `lib/features/metronome/metronome_engine.dart`

**Interfaces:**
- Produces: behind a compile-time-ish debug flag, logs each beat's scheduled-vs-actual delta so on-device measurement can locate the dominant jitter source. No behavioural change when the flag is off.

- [ ] **Step 1: Add a debug flag + scheduled timestamp in the isolate message**

In `metronome_engine.dart`, add near the top-level command constants:

```dart
/// Toggle to log per-beat scheduling jitter (scheduled vs. actual play time).
/// Keep false in commits; flip locally when measuring on-device.
const bool kLogBeatJitter = false;
```

In `_timingIsolateMain`, change the beat message to include the scheduled microsecond time. In `onBeat`:

```dart
  void onBeat() {
    if (!playing) return;
    replyPort.send([idx, idx % factor == 0 ? 1 : 0, sw.elapsedMicroseconds]);
    idx++;
    sched();
  }
```

- [ ] **Step 2: Read the scheduled time on the main isolate and log the delta**

The main-isolate listener currently reads `msg[0]`, `msg[1]`. Update `_onBeat` call site and add logging. In `init()`'s `_receivePort!.listen`:

```dart
      } else if (msg is List<int> && _isPlaying) {
        if (kLogBeatJitter && msg.length >= 3) {
          _logJitter(msg[0], msg[2]);
        }
        _onBeat(msg[0], msg[1] == 1);
      }
```

Add the helper + a monotonic clock field to `MetronomeEngine`:

```dart
  final Stopwatch _wall = Stopwatch()..start();
  int _lastScheduledUs = 0;
  int _lastActualUs = 0;

  void _logJitter(int index, int scheduledUs) {
    final actualUs = _wall.elapsedMicroseconds;
    if (index > 0) {
      final schedGap = scheduledUs - _lastScheduledUs;
      final actualGap = actualUs - _lastActualUs;
      final jitterUs = actualGap - schedGap;
      // ignore: avoid_print
      print('[beat $index] sched_gap=${schedGap}us actual_gap=${actualGap}us '
          'jitter=${jitterUs}us');
    }
    _lastScheduledUs = scheduledUs;
    _lastActualUs = actualUs;
  }
```

- [ ] **Step 3: Verify existing metronome delay test still passes (message shape guarded)**

Run: `flutter test test/metronome_delay_test.dart`
Expected: PASS (the pure delay function is unchanged; the message now carries a third element, consumed only under the flag).

- [ ] **Step 4: Analyze + commit**

Run: `flutter analyze lib/features/metronome/metronome_engine.dart`
Expected: clean.

```bash
git add lib/features/metronome/metronome_engine.dart
git commit -m "Metronome: opt-in per-beat jitter instrumentation (scheduled vs actual)"
```

- [ ] **Step 5: Measurement run (on-device, produces data — not a code change)**

Set `kLogBeatJitter = true` locally, deploy to PC/phone via `cross-machine-test-deploy`, play a pattern (e.g. Single Stroke Roll @ 140 BPM) for ~30 s, capture the `[beat N] ... jitter=...us` log. Summarise stddev/max and the dominant gap pattern. This dataset drives the follow-up jitter-fix spec. Revert the flag to `false` before any further commit.

---

## Self-Review

**Spec coverage:**
- Teil A (Bravura) → Task 5 ✓ (+ font asset already committed).
- Teil B (smooth cursor) → Task 6 ✓ (+ `cursorFraction` in Task 1).
- Teil C (unified tempo: uncapped factor, single reference, remove split-brain) → Tasks 1–3 ✓.
- Teil C (4/4 visible = beat counter) → Task 4 ✓.
- Teil D (jitter: instrument first, fix deferred) → Task 7 ✓ (measurement in Step 5; fix intentionally out of scope).
- Headless unit tests (timing, factor 6/8, cursor) → Tasks 1, 2, 6 ✓. Existing widget test kept green → Tasks 4, 5, 6 ✓.

**Placeholder scan:** No TBD/TODO in steps. The only deferred item (jitter fix) is an explicit spec decision, and Task 7 delivers the concrete instrumentation + measurement that precedes it. Bravura `dyStaffSpaces` values are first estimates with an explicit on-device calibration step (Task 5) — not a placeholder, a real value to tune.

**Type consistency:** `onsetFactorFor`, `onsetIntervalMicros`, `quarterPulseMicros`, `cellDuration`, `cursorFraction` (Task 1) are consumed with matching signatures in Tasks 3 and 6. `setGridFactor(int)` / `reassertSubdivision()` (Task 2) are called with matching signatures in Task 3. `_StaffPainter` gains `cursorPos` (Task 6) and every constructor call in the widget passes it. `NotationStaffWidget` new params (`perCellDuration`, `isPlaying`) are defined in Task 6 and passed in Task 3 (sequencing note included).

**Known cross-task sequencing:** Tasks 3 and 6 share the `NotationStaffWidget` contract; recommended order Task 3 (Steps 1–5) → Task 6 (full) → app-wide `flutter analyze`. Documented in Task 3's sequencing note and Task 6 Step 7.
