# Blattform — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Eine Übung ist ein Blatt aus nummerierten Zeilen. Der Übungs-Screen spielt eine Zeile im Kreis oder das ganze Blatt, zeigt ein Notenfenster von vier Reihen (oben wird gespielt, am Reihenende rutscht es hoch), die Notation bekommt Nummern-Kästchen, Wiederholungszeichen, Schlussstrich, Überschrift und Zählhilfe. Die Lektion gibt es nur auf der Info-Seite. Alle 127 alten Übungen laufen als Ein-Zeilen-Blätter; ein Probestück (Single Paradiddle, 10 Zeilen + Challenge) zeigt die neue Form.

**Architecture:** Das Modell bekommt `ExerciseLine` und `Rudiment.lines`; `Rudiment.sheet` liefert immer mindestens eine Zeile. Eine reine `SheetPlan` macht aus dem Blatt die **Einheit** (eine Zeile oder alle Zeilen als flache Notenliste), und `Rudiment.withSticking(...)` reicht sie als gewöhnliches `Rudiment` an Wiedergabe, Backing-Wahl und Messung weiter — Engine und Analyse bleiben unangetastet. Der Notenmaler wird um Zeilen-Wissen erweitert (`SheetStaffWidget`, ein `CustomPaint` je Zeile, gleiche Reihenhöhe), eine reine `SheetGeometry` kennt die Reihenfolge der Reihen, und `SheetWindow` legt darüber ein Fenster fester Höhe mit animiertem Versatz.

**Tech Stack:** Flutter/Dart (SDK ≥ 3.4), Riverpod codegen (keine neuen Provider), Isar (zwei optionale Felder, `build_runner` einmal auf der GPU-Box), shared_preferences, flutter_test, GoogleFonts gebündelt (IBM Plex Mono = Label-Schrift).

**Spec:** `docs/superpowers/specs/2026-09-30-blattform-design.md`

## Global Constraints

- Branch `blattform` (von `main` 2d4cd3a, Spec 6c27f8b). Worktree `/home/uli/projects/drum_coach/.claude/worktrees/k2-result`. Nie auf `main`/`main-local` committen; der lokale `main` im Haupt-Checkout ist veraltet, Basis ist `origin/main`.
- Tests und Analyzer laufen auf der GPU-Box (vorher `wakegpu`, für lange Läufe `ssh pc touch ~/.no-idle-suspend`, danach entfernen): `.superpowers/tmp/pctest.sh <pfad>` (rsync + `flutter test`, Log `.superpowers/tmp/pctest.log`), Analyzer via `ssh pc 'cd ~/agent-test-checkouts/drum_coach-k2-result && ~/development/flutter/bin/flutter analyze'`. Erwartet: nur die 12 bekannten `experimental_member_use`-Warnungen.
- UI-Texte Englisch; Kommentare Englisch; Doku Deutsch. Katalog-Texte (Probestück) Englisch.
- Tick-Raster 24 je Viertel. Blatt ≤ 64 Takte (`maxBackingCycleBars`).
- Alle Reihen eines Blatts gleich hoch (`rowPitch`), sonst kann das Fenster nicht reihenweise schieben.
- Buchstaben, Nummern, Zählhilfe im Notenmaler in der Label-Schrift (`AppTypography.label`), nie in der Systemschrift.
- Commit-Nachrichten enden mit `Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>` und `Claude-Session: https://claude.ai/code/session_016aeTD3Yv9A4FgYFJEcFidV`; Nachricht per `-F .superpowers/tmp/<datei>.txt`. Plain git commands only (keine Heredocs mit git, keine `$(...)`).
- Keine Änderung an Engine, Renderer (`buildLoopWav`), Messung, Ergebnis-Blatt, Backing-Regeln.

## Review Focus

1. Zeilenwechsel im Lauf: `setPatternVolumes` mit der neuen Einheit, Beat-Log geleert, Cursor und Fenster springen auf die erste Reihe der Einheit — Tests in Task 8c (Wechsel bei spielendem Metronom) + Gerätetest.
2. Alte Übungen (leere `lines`): Ein-Zeilen-Blatt, keine Zeilenleiste, Notation wie heute plus Wiederholungszeichen — Tests in Task 1 (`sheet`), Task 5 (alle 127 zeichnen), Task 8c (keine Leiste).
3. Fenster-Versatz: Reihe +1 → animiert, Sprung zurück (Loop-Anfang, Wechsel) → sofort; Blatt-Modus zeigt nach der letzten Reihe die erste — Tests in Task 6.
4. Gemerkte Zeile größer als das Blatt, `?line=` außerhalb, nicht numerisch → Zeile 1 ohne Fehler — Tests in Task 8c.
5. Messung bekommt die Einheit (`_unit.sticking`), nicht das Muster; Session-Log trägt `sheetLine`/`sheetMode` — Test in Task 7 (Builder) und Task 8c (Analyse-Aufruf per Mock).

---

## Dateistruktur

- `lib/features/lessons/models/rudiment.dart` — **ändern**: `ExerciseLine`, `Rudiment.lines`, `sheet`, `withSticking`.
- `lib/features/lessons/data/etude_dsl.dart` — **ändern**: `line(...)`.
- `lib/features/lessons/models/sheet_plan.dart` — **neu**: `SheetPlan`, `barsOf`.
- `lib/shared/widgets/count_labels.dart` — **neu**: `countLabelsFor`.
- `lib/features/lessons/data/sheets/single_paradiddle_sheet.dart` — **neu**: Probestück (Zeilen + Lektionsabschnitte).
- `lib/features/lessons/data/rudiments_seed.dart` — **ändern**: `final` statt `const`, `single_paradiddle` bekommt `lines` und neue `technique`.
- `lib/shared/widgets/sheet_geometry.dart` — **neu**: `SheetGeometry`, `computeSheetGeometry`, Maß-Konstanten.
- `lib/shared/widgets/notation_staff_widget.dart` — **ändern**: Maler mit Zeilen-Wissen, `SheetStaffWidget`, `NotationStaffWidget` als Ein-Zeilen-Hülle.
- `lib/features/practice/widgets/sheet_window.dart` — **neu**: `SheetWindow`, `slidesUp`.
- `lib/data/local/settings_service.dart` — **ändern**: `sheetPositionFor`/`setSheetPosition`, `showSticking`, `showCounts`, Snapshot mit Zeile/Modus.
- `lib/data/local/models/session_log.dart` (+ `.g.dart` regeneriert), `session_log_service.dart`, `session_log_codec.dart` — **ändern**: `sheetLine`, `sheetMode`.
- `lib/features/practice/practice_session_screen.dart` — **ändern**: Einheit, Zeilenleiste, Fenster, Optionen, Parameter.
- `lib/app/router.dart` — **ändern**: `?line=`, `?mode=`.
- `lib/features/lessons/lesson_detail_screen.dart`, `lessons_screen.dart` — **ändern**: Blatt auf der Info-Seite, Meta-Zeile.
- Tests: `test/lessons/rudiment_model_test.dart`, `etude_dsl_test.dart`, `etudes_integrity_test.dart` (erweitert); `test/lessons/sheet_plan_test.dart`, `test/shared/count_labels_test.dart`, `test/shared/sheet_geometry_test.dart`, `test/features/practice/sheet_window_test.dart`, `test/lessons/lesson_detail_sheet_test.dart`, `test/data/settings_sheet_test.dart` (neu); `test/notation_staff_test.dart`, `test/data/session_log_builder_test.dart`, `test/features/practice/practice_session_screen_test.dart`, `test/lessons/lessons_screen_*` (erweitert).
- Doku: `docs/CLAUDE.md`, `docs/BERICHT_BLATTFORM.md`.

---

### Task 1: Modell — `ExerciseLine`, `Rudiment.lines/sheet/withSticking`, DSL `line`

**Files:**
- Modify: `lib/features/lessons/models/rudiment.dart:199-272`
- Modify: `lib/features/lessons/data/etude_dsl.dart`
- Test: `test/lessons/rudiment_model_test.dart`, `test/lessons/etude_dsl_test.dart`

**Interfaces:**
- Produces: `class ExerciseLine { List<StrokeBeat> beats; bool repeat = true; String? title; bool counts = false; }`; `Rudiment.lines` (`const []`), `List<ExerciseLine> get sheet`, `Rudiment withSticking(List<StrokeBeat> beats)`; DSL `ExerciseLine line(List<StrokeBeat> beats, {bool repeat = true, String? title, bool counts = false})`.

- [ ] **Step 1: Write the failing tests** (append to both files; `rudiment_model_test.dart` has a `main()` with groups — add a group)

```dart
// test/lessons/rudiment_model_test.dart — neue Gruppe
  group('sheet (Blattform)', () {
    const a = StrokeBeat(hand: Hand.right);
    const b = StrokeBeat(hand: Hand.left);
    const plain = Rudiment(
        id: 'p', name: 'P', description: '', minBpm: 60, targetBpm: 100,
        difficulty: Difficulty.beginner, sticking: [a, b]);
    test('without lines the sheet is one repeating line made of the sticking', () {
      expect(plain.lines, isEmpty);
      expect(plain.sheet.length, 1);
      expect(plain.sheet.first.beats, same(plain.sticking));
      expect(plain.sheet.first.repeat, isTrue);
      expect(plain.sheet.first.title, isNull);
      expect(plain.sheet.first.counts, isFalse);
    });
    test('with lines the sheet is exactly those lines', () {
      const r = Rudiment(
          id: 's', name: 'S', description: '', minBpm: 60, targetBpm: 100,
          difficulty: Difficulty.beginner, sticking: [a, b],
          lines: [ExerciseLine([a, b]), ExerciseLine([b, a], repeat: false, title: 'Challenge', counts: true)]);
      expect(r.sheet.length, 2);
      expect(r.sheet[1].repeat, isFalse);
      expect(r.sheet[1].title, 'Challenge');
      expect(r.sheet[1].counts, isTrue);
    });
    test('withSticking swaps only the notes and drops the lines', () {
      const r = Rudiment(
          id: 's', name: 'S', description: 'd', minBpm: 60, targetBpm: 100,
          difficulty: Difficulty.advanced, sticking: [a, b],
          gridUnit: NoteGrid.sixteenth, beatsPerBar: 2, backing: 'swing',
          skills: {Skill.fill}, lines: [ExerciseLine([a]), ExerciseLine([b])]);
      final u = r.withSticking(const [b, b, b]);
      expect(u.sticking.length, 3);
      expect(u.id, 's');
      expect(u.gridUnit, NoteGrid.sixteenth);
      expect(u.beatsPerBar, 2);
      expect(u.backing, 'swing');
      expect(u.skills, {Skill.fill});
      expect(u.difficulty, Difficulty.advanced);
      expect(u.lines, isEmpty);
      expect(u.sheet.first.beats.length, 3);
    });
  });
```

```dart
// test/lessons/etude_dsl_test.dart — neuer Test
  test('line() wraps beats with repeat by default', () {
    final l = line(eighths([R, L, R, L]));
    expect(l.beats.length, 4);
    expect(l.repeat, isTrue);
    final c = line(eighths([R, L]), repeat: false, title: 'Challenge', counts: true);
    expect(c.repeat, isFalse);
    expect(c.title, 'Challenge');
    expect(c.counts, isTrue);
  });
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `.superpowers/tmp/pctest.sh test/lessons/rudiment_model_test.dart test/lessons/etude_dsl_test.dart`
Expected: FAIL — `ExerciseLine`/`line` undefined (compile error).

- [ ] **Step 3: Implement the model**

In `rudiment.dart` before `class Rudiment`:

```dart
/// One line of a sheet (Blattform, 30.09.): a phrase of whole bars, drawn
/// with a number box, repeat signs when [repeat], an optional [title] above
/// the staff ("Challenge") and, when [counts], the count syllables under the
/// sticking letters.
class ExerciseLine {
  final List<StrokeBeat> beats;
  final bool repeat;
  final String? title;
  final bool counts;
  const ExerciseLine(this.beats,
      {this.repeat = true, this.title, this.counts = false});
}
```

In `Rudiment`: add the field + constructor param (default `const []`) after `backing`, and after the constructor:

```dart
  /// The sheet: [lines] when authored, else the plain [sticking] as one
  /// repeating line — every legacy exercise is a one-line sheet.
  List<ExerciseLine> get sheet =>
      lines.isNotEmpty ? lines : [ExerciseLine(sticking)];

  /// A copy carrying [beats] as its sticking and no lines: the practice
  /// screen hands the currently played unit (one line or the whole sheet) to
  /// playback, backing choice and analysis as an ordinary exercise.
  Rudiment withSticking(List<StrokeBeat> beats) => Rudiment(
        id: id, name: name, description: description, minBpm: minBpm,
        targetBpm: targetBpm, difficulty: difficulty, sticking: beats,
        gridUnit: gridUnit, beatsPerBar: beatsPerBar, technique: technique,
        svgAssetPath: svgAssetPath, source: source, voicing: voicing,
        skills: skills, genres: genres, limbs: limbs, collection: collection,
        collectionGroup: collectionGroup, backing: backing,
      );
```

In `etude_dsl.dart` (end of file):

```dart
/// One sheet line (Blattform). Whole bars — `barCountOrThrow` guards it in
/// the integrity test.
ExerciseLine line(List<StrokeBeat> beats,
        {bool repeat = true, String? title, bool counts = false}) =>
    ExerciseLine(beats, repeat: repeat, title: title, counts: counts);
```

- [ ] **Step 4: Run the tests to verify they pass**

Run: `.superpowers/tmp/pctest.sh test/lessons/`
Expected: all passed.

- [ ] **Step 5: Commit**

```bash
git add lib/features/lessons/models/rudiment.dart lib/features/lessons/data/etude_dsl.dart test/lessons/rudiment_model_test.dart test/lessons/etude_dsl_test.dart
git commit -F .superpowers/tmp/commit_bf_t1.txt   # "feat(Blattform): ExerciseLine, Rudiment.lines/sheet/withSticking, DSL line()"
```

---

### Task 2: `SheetPlan` — die Einheit

**Files:**
- Create: `lib/features/lessons/models/sheet_plan.dart`
- Test: `test/lessons/sheet_plan_test.dart`

**Interfaces:**
- Produces: `class SheetPlan { final List<StrokeBeat> beats; final List<int> lineStarts; final List<int> lines; final bool wholeSheet; factory SheetPlan.line(Rudiment r, int lineIndex); factory SheetPlan.wholeSheet(Rudiment r); ({int line, int index}) locate(int noteIndex); int get lineIndex; }`; `int barsOf(List<StrokeBeat> beats, {required NoteGrid grid, required int beatsPerBar})` (ceil, never throws); `int sheetBars(Rudiment r)`.

- [ ] **Step 1: Write the failing tests**

```dart
// test/lessons/sheet_plan_test.dart
import 'package:drum_coach/features/lessons/data/etude_dsl.dart';
import 'package:drum_coach/features/lessons/models/rudiment.dart';
import 'package:drum_coach/features/lessons/models/sheet_plan.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final l1 = line(eighths([R, L, R, L, R, L, R, L]));            // 1 bar, 8 notes
  final l2 = line(sixteenths([R, L, R, R, L, R, L, L, R, L, R, R, L, R, L, L])); // 1 bar, 16
  final l3 = line([...eighths([R, L, R, L, R, L, R, L]), ...eighths([L, R, L, R, L, R, L, R])], repeat: false); // 2 bars, 16
  final r = Rudiment(
      id: 't', name: 'T', description: '', minBpm: 60, targetBpm: 100,
      difficulty: Difficulty.beginner, sticking: eighths([R, L]),
      lines: [l1, l2, l3]);

  test('line plan is exactly that line', () {
    final p = SheetPlan.line(r, 1);
    expect(p.beats, same(l2.beats));
    expect(p.lines, [1]);
    expect(p.lineStarts, [0]);
    expect(p.wholeSheet, isFalse);
    expect(p.lineIndex, 1);
    expect(p.locate(5), (line: 1, index: 5));
  });

  test('whole-sheet plan concatenates all lines once', () {
    final p = SheetPlan.wholeSheet(r);
    expect(p.beats.length, 8 + 16 + 16);
    expect(p.lines, [0, 1, 2]);
    expect(p.lineStarts, [0, 8, 24]);
    expect(p.wholeSheet, isTrue);
    expect(p.lineIndex, 0);
    expect(p.locate(0), (line: 0, index: 0));
    expect(p.locate(7), (line: 0, index: 7));
    expect(p.locate(8), (line: 1, index: 0));
    expect(p.locate(39), (line: 2, index: 15));
  });

  test('legacy exercise without lines is a one-line sheet plan', () {
    final legacy = Rudiment(
        id: 'l', name: 'L', description: '', minBpm: 60, targetBpm: 100,
        difficulty: Difficulty.beginner, sticking: eighths([R, L, R, L]));
    expect(SheetPlan.line(legacy, 0).beats, same(legacy.sticking));
    expect(SheetPlan.wholeSheet(legacy).beats, same(legacy.sticking));
  });

  test('line index is clamped into the sheet', () {
    expect(SheetPlan.line(r, 7).lineIndex, 2);
    expect(SheetPlan.line(r, -1).lineIndex, 0);
  });

  test('barsOf and sheetBars count whole bars, never throw', () {
    expect(barsOf(l3.beats, grid: NoteGrid.eighth, beatsPerBar: 4), 2);
    expect(barsOf(eighths([R, L, R]), grid: NoteGrid.eighth, beatsPerBar: 4), 1);
    expect(barsOf(const [], grid: NoteGrid.eighth, beatsPerBar: 4), 0);
    expect(sheetBars(r), 4);
  });
}
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `.superpowers/tmp/pctest.sh test/lessons/sheet_plan_test.dart`
Expected: FAIL — file not found.

- [ ] **Step 3: Implement**

```dart
// lib/features/lessons/models/sheet_plan.dart
import 'rudiment.dart';

/// What the practice screen plays and measures: one line of the sheet, or
/// all lines in order (each once). A flat note list plus the map back to
/// (line, index in line) for the cursor. Pure.
class SheetPlan {
  final List<StrokeBeat> beats;

  /// Note index at which each covered line starts (parallel to [lines]).
  final List<int> lineStarts;

  /// Sheet line indices covered, in play order.
  final List<int> lines;
  final bool wholeSheet;

  const SheetPlan._({
    required this.beats,
    required this.lineStarts,
    required this.lines,
    required this.wholeSheet,
  });

  /// The one line [lineIndex] (clamped into the sheet).
  factory SheetPlan.line(Rudiment r, int lineIndex) {
    final sheet = r.sheet;
    final i = lineIndex.clamp(0, sheet.length - 1);
    return SheetPlan._(
        beats: sheet[i].beats, lineStarts: const [0], lines: [i], wholeSheet: false);
  }

  /// Every line once, in order.
  factory SheetPlan.wholeSheet(Rudiment r) {
    final sheet = r.sheet;
    final beats = <StrokeBeat>[];
    final starts = <int>[];
    for (final l in sheet) {
      starts.add(beats.length);
      beats.addAll(l.beats);
    }
    return SheetPlan._(
        beats: beats,
        lineStarts: starts,
        lines: [for (var i = 0; i < sheet.length; i++) i],
        wholeSheet: true);
  }

  /// The selected line (line mode) or the first line (sheet mode).
  int get lineIndex => lines.first;

  /// Sheet line and index within it for a note index of [beats].
  ({int line, int index}) locate(int noteIndex) {
    var k = 0;
    while (k + 1 < lineStarts.length && lineStarts[k + 1] <= noteIndex) {
      k++;
    }
    return (line: lines[k], index: noteIndex - lineStarts[k]);
  }
}

/// Whole bars a note list spans (ceil; 0 for nothing). Never throws — for
/// labels, not for validation (`barCountOrThrow` does that).
int barsOf(List<StrokeBeat> beats,
    {required NoteGrid grid, required int beatsPerBar}) {
  var quarters = 0.0;
  for (final b in beats) {
    quarters += resolveNote(b, grid).quarters;
  }
  return (quarters / beatsPerBar - 1e-9).ceil().clamp(0, 1 << 30);
}

/// Bars of the whole sheet (each line once).
int sheetBars(Rudiment r) => r.sheet.fold(
    0, (n, l) => n + barsOf(l.beats, grid: r.gridUnit, beatsPerBar: r.beatsPerBar));
```

- [ ] **Step 4: Run the tests** — `.superpowers/tmp/pctest.sh test/lessons/sheet_plan_test.dart` → `+5: All tests passed!`

- [ ] **Step 5: Commit** — `git add lib/features/lessons/models/sheet_plan.dart test/lessons/sheet_plan_test.dart && git commit -F .superpowers/tmp/commit_bf_t2.txt` ("feat(Blattform): SheetPlan — Einheit aus Zeile oder ganzem Blatt")

---

### Task 3: Zählhilfe — `countLabelsFor`

**Files:**
- Create: `lib/shared/widgets/count_labels.dart`
- Test: `test/shared/count_labels_test.dart`

**Interfaces:**
- Produces: `List<String?> countLabelsFor(List<StrokeBeat> beats, NoteGrid grid, int beatsPerBar)` — ein Eintrag je Note (Pausen und Zwischenpositionen null).

- [ ] **Step 1: Write the failing tests**

```dart
// test/shared/count_labels_test.dart
import 'package:drum_coach/features/lessons/data/etude_dsl.dart';
import 'package:drum_coach/features/lessons/models/rudiment.dart';
import 'package:drum_coach/shared/widgets/count_labels.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('eighths count 1 + 2 + 3 + 4 +', () {
    final c = countLabelsFor(eighths([R, L, R, L, R, L, R, L]), NoteGrid.eighth, 4);
    expect(c, ['1', '+', '2', '+', '3', '+', '4', '+']);
  });
  test('sixteenths count 1 e + a', () {
    final c = countLabelsFor(sixteenths([R, L, R, L, R, L, R, L]), NoteGrid.sixteenth, 4);
    expect(c, ['1', 'e', '+', 'a', '2', 'e', '+', 'a']);
  });
  test('eighth triplets count 1 + a', () {
    final c = countLabelsFor(triplet8([R, L, R, L, R, L]), NoteGrid.eighth, 4);
    expect(c, ['1', '+', 'a', '2', '+', 'a']);
  });
  test('legacy triplet grid counts ternary too', () {
    const beats = [StrokeBeat(hand: Hand.right), StrokeBeat(hand: Hand.left), StrokeBeat(hand: Hand.right)];
    expect(countLabelsFor(beats, NoteGrid.triplet, 4), ['1', '+', 'a']);
  });
  test('mixed values: quarter, two eighths, a sixteenth group, rests get null', () {
    final beats = [
      note(R, NoteValue.quarter),
      note(L, NoteValue.eighth), note(R, NoteValue.eighth),
      ...sixteenths([L, R, L, R]),
      rest(NoteValue.quarter),
    ];
    expect(countLabelsFor(beats, NoteGrid.eighth, 4),
        ['1', '2', '+', '3', 'e', '+', 'a', null]);
  });
  test('second bar starts at 1 again; 32nds off the syllables get null', () {
    final beats = [
      ...eighths([R, L, R, L, R, L, R, L]),
      note(R, NoteValue.thirtySecond), note(L, NoteValue.thirtySecond),
      note(R, NoteValue.thirtySecond), note(L, NoteValue.thirtySecond),
      note(R, NoteValue.eighth), note(L, NoteValue.quarter), note(R, NoteValue.half),
    ];
    final c = countLabelsFor(beats, NoteGrid.eighth, 4);
    expect(c.sublist(8), ['1', null, 'e', null, '+', '2', '3']);
  });
}
```

- [ ] **Step 2: Run** — `.superpowers/tmp/pctest.sh test/shared/count_labels_test.dart` → FAIL (file not found).

- [ ] **Step 3: Implement**

```dart
// lib/shared/widgets/count_labels.dart
import '../../features/lessons/models/rudiment.dart';

/// Count syllables under a line (spec §4d): the beat number on the beat,
/// "e + a" on binary sixteenth positions, "+ a" on ternary positions
/// (tuplets or a triplet grid). Rests and positions off the syllable grid
/// (32nds, dotted remainders) get null. One entry per note, same order.
List<String?> countLabelsFor(
    List<StrokeBeat> beats, NoteGrid grid, int beatsPerBar) {
  const tpq = 24;
  final ternaryGrid =
      grid == NoteGrid.triplet || grid == NoteGrid.sixteenthTriplet;
  final out = <String?>[];
  var tick = 0;
  for (final b in beats) {
    final r = resolveNote(b, grid);
    final ticks = (r.quarters * tpq).round();
    if (b.isRest) {
      out.add(null);
      tick += ticks;
      continue;
    }
    final inBar = tick % (beatsPerBar * tpq);
    final beat = inBar ~/ tpq + 1;
    final t = inBar % tpq;
    final ternary = ternaryGrid || r.tuplet != Tuplet.none;
    final String? label;
    if (t == 0) {
      label = '$beat';
    } else if (ternary) {
      label = switch (t) { 8 => '+', 16 => 'a', _ => null };
    } else {
      label = switch (t) { 6 => 'e', 12 => '+', 18 => 'a', _ => null };
    }
    out.add(label);
    tick += ticks;
  }
  return out;
}
```

- [ ] **Step 4: Run** → `+6: All tests passed!`

- [ ] **Step 5: Commit** — "feat(Blattform): Zählhilfe countLabelsFor"

---

### Task 4: Probestück Single Paradiddle + Integritätsregeln

**Files:**
- Create: `lib/features/lessons/data/sheets/single_paradiddle_sheet.dart`
- Modify: `lib/features/lessons/data/rudiments_seed.dart` (Listenkopf; Eintrag `single_paradiddle` ab Zeile 161)
- Test: `test/lessons/etudes_integrity_test.dart` (erweitert)

**Interfaces:**
- Produces: `final List<ExerciseLine> singleParadiddleSheet` (11 Zeilen: 10 × 2 Takte mit Wiederholung, Zeilen 1–3 mit Zählhilfe, Zeile 11 „Challenge" 8 Takte ohne), `final List<TechniqueSection> singleParadiddleLesson` (Why it matters / How to play it / Practice tips / Song examples); `rudimentsSeedData` wird `final List<Rudiment>`.

- [ ] **Step 1: Write the failing tests** (append to `etudes_integrity_test.dart`)

```dart
  group('sheets (Blattform)', () {
    final all = [...rudimentsSeedData, ...allEtudes];
    test('every line of every sheet is 1..8 whole bars, sheet ≤ 64 bars', () {
      for (final r in all) {
        var total = 0;
        for (var i = 0; i < r.sheet.length; i++) {
          final l = r.sheet[i];
          expect(l.beats, isNotEmpty, reason: '${r.id} line ${i + 1} empty');
          final bars = barCountOrThrow(l.beats,
              beatsPerBar: r.beatsPerBar, grid: r.gridUnit);
          expect(bars, inInclusiveRange(1, 8),
              reason: '${r.id} line ${i + 1} has $bars bars');
          total += bars;
        }
        expect(total, lessThanOrEqualTo(64), reason: '${r.id} sheet too long');
      }
    });
    test('the sample sheet: 11 lines, challenge last without repeat', () {
      final r = rudimentsSeedData.firstWhere((r) => r.id == 'single_paradiddle');
      expect(r.sheet.length, 11);
      expect(r.sheet.take(10).every((l) => l.repeat), isTrue);
      expect(r.sheet.last.repeat, isFalse);
      expect(r.sheet.last.title, 'Challenge');
      expect(r.sheet.first.counts, isTrue);
      expect(r.sticking.length, 8, reason: 'the plain pattern stays for the How box');
      expect(r.technique.map((s) => s.title),
          ['Why it matters', 'How to play it', 'Practice tips', 'Song examples']);
    });
  });
```

- [ ] **Step 2: Run** — `.superpowers/tmp/pctest.sh test/lessons/etudes_integrity_test.dart` → FAIL (sheet length 1, titles differ).

- [ ] **Step 3: Author the sheet** (frei komponiert nach der Muster-Seite Blatt 4; nichts aus den PDFs)

```dart
// lib/features/lessons/data/sheets/single_paradiddle_sheet.dart
import '../../models/rudiment.dart';
import '../etude_dsl.dart';

// Sample sheet for the sheet format (30.09.). Placeholder content: the
// catalog step recomposes every sheet by the rule "as varied and groovy as
// possible". Each line is two bars; the challenge is eight bars straight.

List<StrokeBeat> _pd8() => eighths([R, L, R, R, L, R, L, L]);
List<StrokeBeat> _pd16() =>
    sixteenths([R, L, R, R, L, R, L, L, R, L, R, R, L, R, L, L]);
List<StrokeBeat> _pd16acc() => sixteenths(
    [R, L, R, R, L, R, L, L, R, L, R, R, L, R, L, L],
    accents: {0, 4, 8, 12});

final List<ExerciseLine> singleParadiddleSheet = [
  // 1 · plain eighths, two bars
  line([..._pd8(), ..._pd8()], counts: true),
  // 2 · eighths, then the pattern lands on quarters
  line([..._pd8(), ...eighths([R, L, R, R]), note(L, NoteValue.quarter), note(R, NoteValue.quarter)], counts: true),
  // 3 · sixteenth group + quarter, mirrored in bar 2
  line([
    ...sixteenths([R, L, R, R]), note(L, NoteValue.quarter),
    ...sixteenths([R, L, R, R]), note(L, NoteValue.quarter),
    ...sixteenths([L, R, L, L]), note(R, NoteValue.quarter),
    ...sixteenths([L, R, L, L]), note(R, NoteValue.quarter),
  ], counts: true),
  // 4 · sixteenths, bar 2 ends on a quarter and a rest
  line([..._pd16(), ...sixteenths([R, L, R, R, L, R, L, L]), note(R, NoteValue.quarter), rest(NoteValue.quarter)]),
  // 5 · eighths into sixteenths
  line([..._pd8(), ..._pd16()]),
  // 6 · paradiddle, then doubles
  line([..._pd8(), ...eighths([R, R, L, L, R, R, L, L])]),
  // 7 · paradiddle, then singles
  line([..._pd8(), ...sixteenths([R, L, R, L, R, L, R, L]), note(R, NoteValue.quarter), rest(NoteValue.quarter)]),
  // 8 · accent on the lead of every group
  line([
    ..._pd16acc(),
    ...sixteenths([R, L, R, R, L, R, L, L], accents: {0, 4}),
    note(R, NoteValue.eighth, accent: true), rest(NoteValue.eighth),
    note(L, NoteValue.quarter, accent: true),
  ]),
  // 9 · groups with rests between
  line([
    ...sixteenths([R, L, R, R]), rest(NoteValue.eighth), note(L, NoteValue.eighth),
    ...sixteenths([R, L, R, R]), rest(NoteValue.eighth), note(L, NoteValue.eighth),
    ...sixteenths([L, R, L, L]), rest(NoteValue.eighth), note(R, NoteValue.eighth),
    ...sixteenths([L, R, L, L]), note(R, NoteValue.quarter),
  ]),
  // 10 · inverted paradiddle
  line([...eighths([R, R, L, R, L, L, R, L]), ...sixteenths([R, R, L, R, L, L, R, L, R, R, L, R, L, L, R, L])]),
  // Challenge · eight bars, everything mixed, no repeat
  line([
    ..._pd8(),
    ...sixteenths([R, L, R, R, L, R, L, L]), note(R, NoteValue.quarter), rest(NoteValue.quarter),
    ...sixteenths([R, L, R, R]), note(L, NoteValue.quarter), ...sixteenths([R, L, R, R]), note(L, NoteValue.quarter),
    ..._pd16acc(),
    ..._pd8(),
    ...eighths([R, R, L, L, R, R, L, L]),
    ...sixteenths([R, L, R, R]), rest(NoteValue.eighth), note(L, NoteValue.eighth),
    ...sixteenths([R, L, R, R]), rest(NoteValue.eighth), note(L, NoteValue.eighth),
    ...sixteenths([R, L, R, R, L, R, L, L]), note(R, NoteValue.quarter), rest(NoteValue.quarter),
  ], repeat: false, title: 'Challenge'),
];

const List<TechniqueSection> singleParadiddleLesson = [
  TechniqueSection(
    title: 'Why it matters',
    body: 'The paradiddle joins the two building blocks, single and double '
        'strokes. Because the lead hand switches every group, it moves you '
        'freely between the hands on the kit: the base for fills, grooves '
        'between snare and toms, and everything later called "mixed".',
  ),
  TechniqueSection(
    title: 'How to play it',
    body: 'One stroke right, one left, then two right: R L R R. Then the '
        'mirror image: L R L L. Say it out loud — pa-ra-did-dle.',
  ),
  TechniqueSection(
    title: 'Practice tips',
    body: 'The double must not get quieter than the singles: play both '
        'strokes from the wrist and let the stick bounce only when the tempo '
        'demands it. First put a light accent on the first stroke of each '
        'group, then play everything even. If you tense up, drop back one '
        'tempo step.',
  ),
  TechniqueSection(
    title: 'Song examples',
    body: '• 50 Ways to Leave Your Lover — Paul Simon (Steve Gadd builds the '
        'groove from paradiddles)\n• more places later from your song analysis',
  ),
];
```

- [ ] **Step 4: Wire it into the seed**

In `rudiments_seed.dart`: `import 'sheets/single_paradiddle_sheet.dart';`, change the list head from `const rudimentsSeedData = [` (or `const List<Rudiment> rudimentsSeedData = [`) to `final List<Rudiment> rudimentsSeedData = [` (entries stay as they are; check with `grep -rn "const rudimentsSeedData\|rudimentsSeedData" lib test | grep -v "rudimentsSeedData\." ` that nothing needs it const). In the `single_paradiddle` entry add `lines: singleParadiddleSheet,` and replace `technique: [ … ]` by `technique: singleParadiddleLesson,`.

- [ ] **Step 5: Run** — `.superpowers/tmp/pctest.sh test/lessons/ test/notation_staff_test.dart` → all passed (renders every seeded pattern still uses `sticking`).

- [ ] **Step 6: Commit** — "feat(Blattform): Probestück Single Paradiddle als Blatt (11 Zeilen) + Blatt-Integritätsregeln"

---

### Task 5: Notation — Geometrie, Maler mit Zeilen-Wissen, `SheetStaffWidget`

**Files:**
- Create: `lib/shared/widgets/sheet_geometry.dart`
- Modify: `lib/shared/widgets/notation_staff_widget.dart` (ganze Datei)
- Test: `test/shared/sheet_geometry_test.dart` (neu), `test/notation_staff_test.dart` (erweitert)

**Interfaces:**
- Produces (`sheet_geometry.dart`): `const double sheetRowPitch = 104; const double sheetRowPitchWithCounts = 118; const double sheetLeftPad = 8; const double sheetNumberBoxW = 26; const double sheetRightPad = 12; const double sheetRepeatW = 10; const double sheetSystemPad = 26; const double sheetRepeatSystemPad = 12; const double sheetBarGap = 12;` `class SheetGeometry { List<StaffLayout> layouts; double rowPitch; List<int> rowStart; int totalRows; int rowOf(int line, int index); int lineOfRow(int row); double get height; }`; `SheetGeometry computeSheetGeometry(Rudiment r, double maxWidth, {required bool showCounts})`.
- Produces (`notation_staff_widget.dart`): `SheetStaffWidget({required Rudiment rudiment, int? activeLine, int? activeIndex, bool showSticking = true, bool showCounts = true, ValueChanged<int>? onLineTap, Key? key})`; `NotationStaffWidget({required Rudiment rudiment, int? activeIndex, bool autoScroll = false})` unverändert von außen (zeichnet `sticking` als eine Zeile ohne Kästchen und ohne Wiederholung, Schlussstrich — der „How"-Kasten und der Generator).

- [ ] **Step 1: Write the failing tests**

```dart
// test/shared/sheet_geometry_test.dart
import 'package:drum_coach/features/lessons/data/etude_dsl.dart';
import 'package:drum_coach/features/lessons/models/rudiment.dart';
import 'package:drum_coach/shared/widgets/sheet_geometry.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  List<StrokeBeat> bar() => eighths([R, L, R, L, R, L, R, L]);
  final r = Rudiment(
      id: 'g', name: 'G', description: '', minBpm: 60, targetBpm: 100,
      difficulty: Difficulty.beginner, sticking: bar(),
      lines: [
        line([...bar(), ...bar()]),                     // 2 bars → 1 row
        line([...bar(), ...bar()], counts: true),       // 1 row
        line([...bar(), ...bar(), ...bar(), ...bar(), ...bar(), ...bar(), ...bar(), ...bar()], repeat: false), // 8 bars → 4 rows
      ]);

  test('rows per line, row starts and total rows', () {
    final g = computeSheetGeometry(r, 360, showCounts: true);
    expect(g.layouts.map((l) => l.rowCount), [1, 1, 4]);
    expect(g.rowStart, [0, 1, 2]);
    expect(g.totalRows, 6);
    expect(g.rowOf(0, 3), 0);
    expect(g.rowOf(2, 0), 2);
    expect(g.rowOf(2, 16), 3);   // bar 3 of the challenge = second row
    expect(g.rowOf(2, 63), 5);
    expect(g.lineOfRow(4), 2);
  });

  test('row pitch is uniform: taller for the whole sheet when any line counts', () {
    expect(computeSheetGeometry(r, 360, showCounts: true).rowPitch, sheetRowPitchWithCounts);
    expect(computeSheetGeometry(r, 360, showCounts: false).rowPitch, sheetRowPitch);
    final plain = r.withSticking(bar());
    expect(computeSheetGeometry(plain, 360, showCounts: true).rowPitch, sheetRowPitch);
  });

  test('height is rows × pitch', () {
    final g = computeSheetGeometry(r, 360, showCounts: false);
    expect(g.height, 6 * sheetRowPitch);
  });
}
```

```dart
// test/notation_staff_test.dart — neue Gruppe (Imports: etude_dsl, sheet_geometry)
  group('SheetStaffWidget (Blattform)', () {
    List<StrokeBeat> bar() => eighths([R, L, R, L, R, L, R, L]);
    final sheet = Rudiment(
        id: 'sheet', name: 'Sheet', description: '', minBpm: 60, targetBpm: 100,
        difficulty: Difficulty.beginner, sticking: bar(),
        lines: [
          line([...bar(), ...bar()], counts: true),
          line([...bar(), ...bar()], title: 'Accents'),
          line([...bar(), ...bar(), ...bar(), ...bar()], repeat: false, title: 'Challenge'),
        ]);

    testWidgets('draws a three-line sheet, one CustomPaint per line, uniform pitch',
        (tester) async {
      await tester.pumpWidget(MaterialApp(
          home: Scaffold(body: SizedBox(width: 360, child: SheetStaffWidget(rudiment: sheet)))));
      expect(tester.takeException(), isNull);
      final paints = find.descendant(of: find.byType(SheetStaffWidget), matching: find.byType(CustomPaint));
      expect(paints, findsNWidgets(3));
      final h = [for (final e in paints.evaluate()) (e.widget as CustomPaint).size.height];
      expect(h[0], sheetRowPitchWithCounts);
      expect(h[1], sheetRowPitchWithCounts);
      expect(h[2], 2 * sheetRowPitchWithCounts);
    });

    testWidgets('every seeded exercise renders as a sheet without throwing', (tester) async {
      for (final r in [...rudimentsSeedData, ...allEtudes]) {
        await tester.pumpWidget(MaterialApp(
            home: Scaffold(body: SizedBox(width: 360, child: SheetStaffWidget(rudiment: r)))));
        expect(tester.takeException(), isNull, reason: r.id);
      }
    });

    testWidgets('tapping a line reports its index', (tester) async {
      final taps = <int>[];
      await tester.pumpWidget(MaterialApp(
          home: Scaffold(body: SizedBox(width: 360,
              child: SheetStaffWidget(rudiment: sheet, activeLine: 0, onLineTap: taps.add)))));
      final paints = find.descendant(of: find.byType(SheetStaffWidget), matching: find.byType(CustomPaint));
      await tester.tap(paints.at(1));
      expect(taps, [1]);
    });

    testWidgets('active line and index render a cursor without throwing', (tester) async {
      await tester.pumpWidget(MaterialApp(
          home: Scaffold(body: SizedBox(width: 360,
              child: SheetStaffWidget(rudiment: sheet, activeLine: 2, activeIndex: 17)))));
      expect(tester.takeException(), isNull);
    });

    testWidgets('golden: number boxes, repeat signs, title, counts, final barline',
        (tester) async {
      await tester.pumpWidget(MaterialApp(
          home: Scaffold(body: SizedBox(width: 360, child: SheetStaffWidget(rudiment: sheet)))));
      await expectLater(find.byType(SheetStaffWidget),
          matchesGoldenFile('goldens/sheet_staff_three_lines.png'));
    });
  });
```

(Golden: erstmalig mit `flutter test --update-goldens test/notation_staff_test.dart` auf der GPU-Box erzeugen, PNG per rsync zurückholen — `rsync -a pc:~/agent-test-checkouts/drum_coach-k2-result/test/goldens/ test/goldens/` — und sichten, dann committen; `result_sheet_golden_test.dart` macht es genauso.)

- [ ] **Step 2: Run** — `.superpowers/tmp/pctest.sh test/shared/sheet_geometry_test.dart test/notation_staff_test.dart` → FAIL (compile).

- [ ] **Step 3: Implement the geometry**

```dart
// lib/shared/widgets/sheet_geometry.dart
import '../../features/lessons/models/rudiment.dart';
import 'staff_layout.dart';

// Row and margin metrics shared by the painter, the sheet widget and the
// practice window. All rows of a sheet share one pitch so the window can
// slide by whole rows (spec §4b/§4c).
const double sheetRowPitch = 104;
const double sheetRowPitchWithCounts = 118;
const double sheetLeftPad = 8;
const double sheetNumberBoxW = 26;   // number box 22 px + 4 px gap
const double sheetRightPad = 12;
const double sheetRepeatW = 10;      // room for ":|" at the row end
const double sheetSystemPad = 26;    // clef (+ time signature)
const double sheetRepeatSystemPad = 12; // extra room for "|:" after the clef
const double sheetBarGap = 12;

/// Layout of every line of a sheet at one width, plus the global row order.
class SheetGeometry {
  final List<StaffLayout> layouts;
  final double rowPitch;

  /// Global index of each line's first row.
  final List<int> rowStart;
  final int totalRows;
  const SheetGeometry(this.layouts, this.rowPitch, this.rowStart, this.totalRows);

  int rowOf(int line, int index) =>
      rowStart[line] + layouts[line].placements[index].row;

  int lineOfRow(int row) {
    var l = 0;
    while (l + 1 < rowStart.length && rowStart[l + 1] <= row) {
      l++;
    }
    return l;
  }

  double get height => totalRows * rowPitch;
}

double leftPadFor({required bool numbered}) =>
    sheetLeftPad + (numbered ? sheetNumberBoxW : 0);
double rightPadFor({required bool repeat}) =>
    sheetRightPad + (repeat ? sheetRepeatW : 0);
double systemPadFor({required bool repeat}) =>
    sheetSystemPad + (repeat ? sheetRepeatSystemPad : 0);

SheetGeometry computeSheetGeometry(Rudiment r, double maxWidth,
    {required bool showCounts}) {
  final sheet = r.sheet;
  final counts = showCounts && sheet.any((l) => l.counts);
  final layouts = <StaffLayout>[];
  final starts = <int>[];
  var rows = 0;
  for (final l in sheet) {
    starts.add(rows);
    final layout = computeStaffLayout(
      beats: l.beats,
      grid: r.gridUnit,
      beatsPerBar: r.beatsPerBar,
      maxWidth: maxWidth,
      leftPad: leftPadFor(numbered: true),
      rightPad: rightPadFor(repeat: l.repeat),
      systemPad: systemPadFor(repeat: l.repeat),
      barGap: sheetBarGap,
    );
    layouts.add(layout);
    rows += layout.rowCount;
  }
  return SheetGeometry(
      layouts, counts ? sheetRowPitchWithCounts : sheetRowPitch, starts, rows);
}
```

- [ ] **Step 4: Rework the painter and add `SheetStaffWidget`** (in `notation_staff_widget.dart`)

Painter constructor becomes line-aware; it no longer takes a `Rudiment`:

```dart
class _StaffPainter extends CustomPainter {
  _StaffPainter({
    required this.beats,
    required this.grid,
    required this.beatsPerBar,
    required this.maxWidth,
    required this.rowPitch,
    this.activeIndex,
    this.lineNumber,          // null = no box (plain pattern)
    this.repeat = false,
    this.finalBar = true,     // thin+thick at the very end (last line / plain)
    this.showTimeSig = true,
    this.title,
    this.countLabels,         // per note, null = no count row
    this.dimmed = false,
    this.showSticking = true,
  });
  // fields …
  late final double _leftPad = leftPadFor(numbered: lineNumber != null);
  late final double _rightPad = rightPadFor(repeat: repeat);
  late final double _systemPad = systemPadFor(repeat: repeat);
  late final StaffLayout _layout = computeStaffLayout(
    beats: beats, grid: grid, beatsPerBar: beatsPerBar, maxWidth: maxWidth,
    leftPad: _leftPad, rightPad: _rightPad, systemPad: _systemPad, barGap: sheetBarGap);
  double computeHeight() => _layout.rowCount * rowPitch;
```

Änderungen im Zeichnen (alle `_leftPad`/`_systemPad`/`_rowH`-Konstanten durch die Instanzwerte bzw. `rowPitch` ersetzen; `_forBar` entfällt):

- `Color _dim(Color c) => dimmed ? c.withValues(alpha: c.a * 0.45) : c;` — überall statt `_forBar(c, bar)`.
- `_paintRow`: Notenreihe wie heute; Taktstriche wie heute. **Reihenende:** `final isLastRow = row == _layout.rowCount - 1;` → `if (isLastRow && repeat) _drawEndRepeat(...)` sonst `if (isLastRow && finalBar) _drawFinalBarline(...)` sonst `_drawSingleBarline(...)` (dünn). `_drawDoubleBarline` entfällt.
- **Reihenanfang, Reihe 0:** Nummern-Kästchen (`lineNumber != null`): `Rect.fromLTWH(sheetLeftPad / 2, baseY + _midY - 11, 22, 22)`, 1-px-Rahmen `_inkColor` (gedimmt), Zahl mit `_drawText(.., 12, bold: true)`; danach Schlüssel bei `_leftPad + 10`, Taktart (nur `row == 0 && showTimeSig`) bei `_leftPad + 20`; **Start-Wiederholung** bei `repeat && row == 0`: `_drawStartRepeat(canvas, _leftPad + _systemPad - 8, topLineY, bottomLineY)` = dicker Strich 2,2 px bei x−3, dünner bei x+1, zwei Punkte r 1,6 bei x+5 auf `staffY ± _lineGap/2`... (Punkte im 2. und 3. Zwischenraum: y = staffY − _lineGap/2 und staffY + _lineGap/2).
- **Überschrift** (`title != null`, Reihe 0): `_drawTextLeft(canvas, title!, Offset(_leftPad + _systemPad, baseY + 6), _dim(_inkColor), 11, bold: true)` (neue Hilfsfunktion, linksbündig, vertikal an der Oberkante).
- **Handsatz** nur wenn `showSticking`; **Zählhilfe**: wenn `countLabels != null` und Eintrag ≠ null → `_drawText(label, Offset(x, baseY + _letterY + 14), _dim(_letterColor), 10)`.
- `_drawText`/`_drawTextLeft` benutzen `AppTypography.label.copyWith(color: color, fontSize: size, fontWeight: bold ? FontWeight.w700 : FontWeight.w500, fontStyle: …, letterSpacing: 0, height: 1.0)`.
- `shouldRepaint`: alle Felder vergleichen (`beats`, `activeIndex`, `maxWidth`, `lineNumber`, `repeat`, `finalBar`, `title`, `dimmed`, `showSticking`, `countLabels`, `rowPitch`).

Neue Widgets:

```dart
/// A whole sheet: one CustomPaint per line, stacked, uniform row pitch.
class SheetStaffWidget extends StatelessWidget {
  final Rudiment rudiment;
  final int? activeLine;
  final int? activeIndex;
  final bool showSticking;
  final bool showCounts;
  final ValueChanged<int>? onLineTap;
  const SheetStaffWidget({super.key, required this.rudiment, this.activeLine,
      this.activeIndex, this.showSticking = true, this.showCounts = true, this.onLineTap});

  static const _hPad = 4.0;
  static const _vPad = 16.0;

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, c) {
        final width = c.maxWidth.isFinite ? c.maxWidth : MediaQuery.of(context).size.width;
        final contentWidth = width - 2 * _hPad;
        final geo = computeSheetGeometry(rudiment, contentWidth, showCounts: showCounts);
        final sheet = rudiment.sheet;
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: _hPad, vertical: _vPad),
          decoration: BoxDecoration(color: AppColors.paper, borderRadius: BorderRadius.circular(AppRadius.card)),
          child: Column(children: [
            for (var i = 0; i < sheet.length; i++)
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onLineTap == null ? null : () => onLineTap!(i),
                child: CustomPaint(
                  size: Size(contentWidth, geo.layouts[i].rowCount * geo.rowPitch),
                  painter: _StaffPainter(
                    beats: sheet[i].beats, grid: rudiment.gridUnit, beatsPerBar: rudiment.beatsPerBar,
                    maxWidth: contentWidth, rowPitch: geo.rowPitch,
                    activeIndex: activeLine == i ? activeIndex : null,
                    lineNumber: i + 1, repeat: sheet[i].repeat, finalBar: i == sheet.length - 1,
                    showTimeSig: i == 0, title: sheet[i].title,
                    countLabels: showCounts && sheet[i].counts
                        ? countLabelsFor(sheet[i].beats, rudiment.gridUnit, rudiment.beatsPerBar) : null,
                    dimmed: activeLine != null && activeLine != i,
                    showSticking: showSticking,
                  ),
                ),
              ),
          ]),
        );
      });
}
```

`NotationStaffWidget` bleibt (Konstruktor wie heute); sein State baut `_StaffPainter(beats: rudiment.sticking, …, rowPitch: sheetRowPitch, lineNumber: null, repeat: false, finalBar: true)`; `autoScroll` bleibt für den Generator (der Übungs-Screen nutzt es nicht mehr). `import 'count_labels.dart'; import 'sheet_geometry.dart';`.

- [ ] **Step 5: Run** — `.superpowers/tmp/pctest.sh test/shared/ test/notation_staff_test.dart test/lessons/` → all passed (Golden nach Erzeugung + Sichtung).

- [ ] **Step 6: Commit** — "feat(Blattform): SheetStaffWidget — Kästchen, Wiederholungszeichen, Schlussstrich, Überschrift, Zählhilfe, Label-Schrift"

---

### Task 6: Notenfenster — `SheetWindow`

**Files:**
- Create: `lib/features/practice/widgets/sheet_window.dart`
- Test: `test/features/practice/sheet_window_test.dart`

**Interfaces:**
- Produces: `bool slidesUp(int oldTop, int newTop) => newTop == oldTop + 1`; `int visibleRowsFor({required double maxHeight, required double rowPitch, required int totalRows, int preferred = 4, int minimum = 2})`; `class SheetWindow extends StatefulWidget { rudiment, activeLine (int, required), activeIndex (int?), sheetMode (bool), showSticking, showCounts, onLineTap, preferredRows = 4 }` — Höhe = `visibleRows × rowPitch + 2 × 16` (Paper-Padding), Inhalt = `SheetStaffWidget` in `ClipRect`, Versatz `−topRow × rowPitch` (animiert 180 ms `easeOutCubic` bei +1, sonst sofort), im Blatt-Modus eine zweite Kopie darunter für den Umlauf.

- [ ] **Step 1: Write the failing tests**

```dart
// test/features/practice/sheet_window_test.dart
import 'package:drum_coach/features/lessons/data/etude_dsl.dart';
import 'package:drum_coach/features/lessons/models/rudiment.dart';
import 'package:drum_coach/features/practice/widgets/sheet_window.dart';
import 'package:drum_coach/shared/widgets/notation_staff_widget.dart';
import 'package:drum_coach/shared/widgets/sheet_geometry.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  List<StrokeBeat> bar() => eighths([R, L, R, L, R, L, R, L]);
  final six = Rudiment(
      id: 'w', name: 'W', description: '', minBpm: 60, targetBpm: 100,
      difficulty: Difficulty.beginner, sticking: bar(),
      lines: [
        line([...bar(), ...bar()]),
        line([...bar(), ...bar()]),
        line([...bar(), ...bar(), ...bar(), ...bar(), ...bar(), ...bar(), ...bar(), ...bar()], repeat: false),
      ]); // rows: 1 + 1 + 4 = 6
  final one = six.withSticking(bar());

  Future<void> pump(WidgetTester tester, Widget w, {double height = 800}) =>
      tester.pumpWidget(MaterialApp(home: Scaffold(body: SizedBox(width: 360, height: height, child: Center(child: w)))));

  double offsetOf(WidgetTester tester) =>
      tester.getTopLeft(find.byType(SheetStaffWidget).first).dy -
      tester.getTopLeft(find.byType(ClipRect).first).dy;

  test('slidesUp only for the next row', () {
    expect(slidesUp(0, 1), isTrue);
    expect(slidesUp(3, 4), isTrue);
    expect(slidesUp(4, 0), isFalse);
    expect(slidesUp(1, 3), isFalse);
    expect(slidesUp(2, 2), isFalse);
  });

  test('visibleRowsFor: up to 4, never more than the sheet, at least 2', () {
    expect(visibleRowsFor(maxHeight: 800, rowPitch: 104, totalRows: 6), 4);
    expect(visibleRowsFor(maxHeight: 800, rowPitch: 104, totalRows: 1), 1);
    expect(visibleRowsFor(maxHeight: 300, rowPitch: 104, totalRows: 6), 2);
    expect(visibleRowsFor(maxHeight: 100, rowPitch: 104, totalRows: 6), 2);
    expect(visibleRowsFor(maxHeight: 350, rowPitch: 104, totalRows: 6), 3);
  });

  testWidgets('a one-row sheet is one row high, a long sheet four rows', (tester) async {
    await pump(tester, SheetWindow(rudiment: one, activeLine: 0));
    expect(tester.getSize(find.byType(ClipRect).first).height, sheetRowPitch);
    await pump(tester, SheetWindow(rudiment: six, activeLine: 0));
    expect(tester.getSize(find.byType(ClipRect).first).height, 4 * sheetRowPitch);
  });

  testWidgets('the active row is on top; the next row slides up, animated', (tester) async {
    await pump(tester, SheetWindow(rudiment: six, activeLine: 0, activeIndex: 0));
    expect(offsetOf(tester), 0);
    // line 1 = row 1
    await pump(tester, SheetWindow(rudiment: six, activeLine: 1, activeIndex: 0));
    await tester.pump(const Duration(milliseconds: 90));
    final mid = offsetOf(tester);
    expect(mid, lessThan(0));
    expect(mid, greaterThan(-sheetRowPitch));
    await tester.pump(const Duration(milliseconds: 200));
    expect(offsetOf(tester), -sheetRowPitch);
    // challenge, bar 3 = row 3 (line 2 starts at row 2)
    await pump(tester, SheetWindow(rudiment: six, activeLine: 2, activeIndex: 16));
    await tester.pumpAndSettle();
    expect(offsetOf(tester), -3 * sheetRowPitch);
  });

  testWidgets('jumping back to the start is immediate', (tester) async {
    await pump(tester, SheetWindow(rudiment: six, activeLine: 2, activeIndex: 63));
    await tester.pumpAndSettle();
    expect(offsetOf(tester), -5 * sheetRowPitch);
    await pump(tester, SheetWindow(rudiment: six, activeLine: 2, activeIndex: 0));
    await tester.pump();
    expect(offsetOf(tester), -2 * sheetRowPitch);
  });

  testWidgets('before the start the selected line sits on top', (tester) async {
    await pump(tester, SheetWindow(rudiment: six, activeLine: 2));
    await tester.pump();
    expect(offsetOf(tester), -2 * sheetRowPitch);
  });

  testWidgets('sheet mode wraps: a second copy follows the last row; line mode does not',
      (tester) async {
    await pump(tester, SheetWindow(rudiment: six, activeLine: 2, activeIndex: 63, sheetMode: true));
    await tester.pumpAndSettle();
    expect(find.byType(SheetStaffWidget), findsNWidgets(2));
    final second = tester.getTopLeft(find.byType(SheetStaffWidget).at(1)).dy -
        tester.getTopLeft(find.byType(ClipRect).first).dy;
    expect(second, closeTo(sheetRowPitch, 0.5)); // row 0 right under the last row
    await pump(tester, SheetWindow(rudiment: six, activeLine: 2, activeIndex: 63));
    await tester.pumpAndSettle();
    expect(find.byType(SheetStaffWidget), findsOneWidget);
  });

  testWidgets('tapping a visible line reports it', (tester) async {
    final taps = <int>[];
    await pump(tester, SheetWindow(rudiment: six, activeLine: 0, onLineTap: taps.add));
    final clip = tester.getRect(find.byType(ClipRect).first);
    await tester.tapAt(Offset(clip.center.dx, clip.top + 16 + 1.5 * sheetRowPitch)); // row 1 = line 1
    expect(taps, [1]);
  });
}
```

- [ ] **Step 2: Run** → FAIL (file not found).

- [ ] **Step 3: Implement**

```dart
// lib/features/practice/widgets/sheet_window.dart
import 'package:flutter/material.dart';

import '../../../app/design_tokens.dart';
import '../../../shared/widgets/notation_staff_widget.dart';
import '../../../shared/widgets/sheet_geometry.dart';
import '../../lessons/models/rudiment.dart';

/// The row just below the old top slides up; anything else (loop restart,
/// line change, mode change) is a new page and jumps.
bool slidesUp(int oldTop, int newTop) => newTop == oldTop + 1;

/// Rows the window shows: up to [preferred], never more than the sheet has,
/// at least [minimum] when the sheet has that many.
int visibleRowsFor({
  required double maxHeight,
  required double rowPitch,
  required int totalRows,
  int preferred = 4,
  int minimum = 2,
}) {
  if (totalRows <= minimum) return totalRows;
  final fit = ((maxHeight - 2 * _vPad) / rowPitch).floor();
  return fit.clamp(minimum, preferred).clamp(minimum, totalRows);
}

const double _vPad = 16; // the sheet's own paper padding

/// Fixed-height window over a sheet (spec §4c): the active row is always the
/// top row, the next rows wait below (dimmed by the sheet widget), and the
/// content slides up one row at every row boundary. Sheet mode shows the
/// first rows again after the last one — the loop goes on.
class SheetWindow extends StatefulWidget {
  final Rudiment rudiment;
  final int activeLine;
  final int? activeIndex;
  final bool sheetMode;
  final bool showSticking;
  final bool showCounts;
  final ValueChanged<int>? onLineTap;
  final int preferredRows;
  const SheetWindow({super.key, required this.rudiment, required this.activeLine,
      this.activeIndex, this.sheetMode = false, this.showSticking = true,
      this.showCounts = true, this.onLineTap, this.preferredRows = 4});

  @override
  State<SheetWindow> createState() => _SheetWindowState();
}

class _SheetWindowState extends State<SheetWindow>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 180));
  int _topRow = 0;
  double _fromRow = 0; // row offset the slide starts at

  SheetGeometry? _geo;

  int _rowFor(SheetGeometry geo) =>
      geo.rowOf(widget.activeLine, widget.activeIndex ?? 0);

  @override
  void didUpdateWidget(covariant SheetWindow old) {
    super.didUpdateWidget(old);
    final geo = _geo;
    if (geo == null || old.rudiment != widget.rudiment ||
        old.showCounts != widget.showCounts) {
      return; // geometry changes: build recomputes and jumps
    }
    final next = _rowFor(geo);
    if (next == _topRow) return;
    if (slidesUp(_topRow, next)) {
      _fromRow = _topRow.toDouble();
      _topRow = next;
      _anim.forward(from: 0);
    } else {
      _topRow = next;
      _anim.value = 1;
    }
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, c) {
        final width = c.maxWidth.isFinite ? c.maxWidth : MediaQuery.of(context).size.width;
        final geo = computeSheetGeometry(widget.rudiment, width - 8, showCounts: widget.showCounts);
        if (_geo == null || _geo!.totalRows != geo.totalRows || _geo!.rowPitch != geo.rowPitch) {
          _topRow = _rowFor(geo);
          _anim.value = 1;
        }
        _geo = geo;
        final rows = visibleRowsFor(
            maxHeight: c.maxHeight.isFinite ? c.maxHeight : double.infinity,
            rowPitch: geo.rowPitch, totalRows: geo.totalRows, preferred: widget.preferredRows);
        final height = rows * geo.rowPitch + 2 * _vPad;
        final sheet = SheetStaffWidget(
          rudiment: widget.rudiment, activeLine: widget.activeLine,
          activeIndex: widget.activeIndex, showSticking: widget.showSticking,
          showCounts: widget.showCounts, onLineTap: widget.onLineTap);
        return ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.card),
          child: ClipRect(
            child: SizedBox(
              height: height,
              child: AnimatedBuilder(
                animation: _anim,
                builder: (context, _) {
                  final t = Curves.easeOutCubic.transform(_anim.value);
                  final row = _fromRow + (_topRow - _fromRow) * t;
                  final dy = -row * geo.rowPitch;
                  return Stack(clipBehavior: Clip.none, children: [
                    Positioned(top: dy, left: 0, right: 0, child: sheet),
                    if (widget.sheetMode)
                      Positioned(top: dy + geo.height, left: 0, right: 0,
                          child: SheetStaffWidget(rudiment: widget.rudiment,
                              activeLine: -1, showSticking: widget.showSticking,
                              showCounts: widget.showCounts)),
                  ]);
                },
              ),
            ),
          ),
        );
      });
}
```

Hinweis: die zweite Kopie bekommt `activeLine: -1`, damit alle ihre Zeilen gedämpft sind (Vorschau). Die Paper-Ecken oben/unten: das Fenster beschneidet die Karte; die obere Kopie liefert das Papier bis zur Kante, unten schließt die zweite Kopie oder der Leerraum ab — im Zeilen-Modus ohne Umlauf endet die Karte mit dem Blatt (Leerraum ist dann Screen-Hintergrund; gewollt, §4c).

- [ ] **Step 4: Run** → all passed.

- [ ] **Step 5: Commit** — "feat(Blattform): SheetWindow — vier Reihen, oben wird gespielt, am Reihenende rutscht es hoch"

---

### Task 7: Einstellungen, Schnappschuss, Session-Log

**Files:**
- Modify: `lib/data/local/settings_service.dart` (nach `backingLevel`; Snapshot-Block 134–178)
- Modify: `lib/data/local/models/session_log.dart`, `session_log_service.dart` (`buildSessionLog`), `session_log_codec.dart` (JSONL-Felder)
- Regenerate: `lib/data/local/models/session_log.g.dart`
- Test: `test/data/settings_sheet_test.dart` (neu), `test/data/session_log_builder_test.dart` (erweitert)

**Interfaces:**
- Produces: `SettingsService.showSticking` (bool, Standard true) / `setShowSticking`; `showCounts` (true) / `setShowCounts`; `({int line, bool sheet}) sheetPositionFor(String id)` (Standard `(line: 0, sheet: false)`) / `setSheetPosition(String id, {required int line, required bool sheet})`; `savePracticeSnapshot(..., int line = 0, bool sheet = false)` und `practiceSnapshotFor` liefert zusätzlich `line`, `sheet`; `SessionLog.sheetLine` (`int?`), `sheetMode` (`String?`); `buildSessionLog(..., int? sheetLine, String? sheetMode)`.

- [ ] **Step 1: Write the failing tests**

```dart
// test/data/settings_sheet_test.dart
import 'package:drum_coach/data/local/settings_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await SettingsService.init();
  });
  test('sticking letters and count hints default on and round-trip', () async {
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
    await SettingsService.savePracticeSnapshot(rudimentId: 'x', elapsedSeconds: 30);
    expect(SettingsService.practiceSnapshotFor('x')!.line, 0);
  });
}
```

`session_log_builder_test.dart`: einen Test ergänzen — `buildSessionLog(... sheetLine: 3, sheetMode: 'line')` → Felder gesetzt; ohne Angabe → null; `sessionLogToJsonl` enthält `"sheetLine":3` (Codec-Test analog, falls vorhanden: `session_log_codec_test.dart`).

- [ ] **Step 2: Run** → FAIL.

- [ ] **Step 3: Implement**

`settings_service.dart` (nach `setBackingLevel`):

```dart
  // ── Sheet (Blattform, 30.09.) ──────────────────────────────────────────
  static bool get showSticking => _prefs.getBool('show_sticking') ?? true;
  static Future<void> setShowSticking(bool v) => _prefs.setBool('show_sticking', v);
  static bool get showCounts => _prefs.getBool('show_counts') ?? true;
  static Future<void> setShowCounts(bool v) => _prefs.setBool('show_counts', v);

  /// Last line and mode played per exercise; the screen resumes there.
  static ({int line, bool sheet}) sheetPositionFor(String exerciseId) => (
        line: _prefs.getInt('sheet_line_$exerciseId') ?? 0,
        sheet: _prefs.getBool('sheet_mode_$exerciseId') ?? false,
      );
  static Future<void> setSheetPosition(String exerciseId,
      {required int line, required bool sheet}) async {
    await _prefs.setInt('sheet_line_$exerciseId', line);
    await _prefs.setBool('sheet_mode_$exerciseId', sheet);
  }
```

Snapshot: Parameter `int line = 0, bool sheet = false` → Keys `practice_snap_line`, `practice_snap_sheet`; Rückgabetyp `({int elapsedSeconds, int? goalSeconds, int sessionSeconds, int line, bool sheet})`; `clearPracticeSnapshot` entfernt beide Keys.

`session_log.dart`: nach `int? rating;` → `/// Sheet line played (1-based) or null for the whole sheet / legacy. \n int? sheetLine; \n /// `line` | `sheet` | null (legacy). \n String? sheetMode;`. `buildSessionLog`: Parameter `int? sheetLine, String? sheetMode` → `..sheetLine = sheetLine ..sheetMode = sheetMode`. Codec: beide Felder in die JSONL-Zeile (Schlüssel `sheetLine`, `sheetMode`) und beim Lesen zurück.

- [ ] **Step 4: Regenerate Isar code on the GPU box** (die Datei wird committet):

```bash
.superpowers/tmp/pctest.sh test/data/settings_sheet_test.dart   # rsync + erster Lauf (Isar-Test scheitert noch)
ssh pc 'cd ~/agent-test-checkouts/drum_coach-k2-result && ~/development/flutter/bin/dart run build_runner build --delete-conflicting-outputs 2>&1 | tail -3'
rsync -a pc:~/agent-test-checkouts/drum_coach-k2-result/lib/data/local/models/session_log.g.dart lib/data/local/models/session_log.g.dart
```

- [ ] **Step 5: Run** — `.superpowers/tmp/pctest.sh test/data/` → all passed.

- [ ] **Step 6: Commit** — "feat(Blattform): Einstellungen (Position je Übung, Schalter), Schnappschuss und Session-Log mit Zeile/Modus"

---

### Task 8a: Übungs-Screen — Einheit, Zeilenwechsel, Parameter, Gedächtnis

**Files:**
- Modify: `lib/features/practice/practice_session_screen.dart` (Klasse + State bis `_applyExtras`, `_finishSession`, `_afterSave`, `didChangeAppLifecycleState`)
- Modify: `lib/app/router.dart:135-146`

**Interfaces:**
- Produces: `PracticeSessionScreen({…, int? line, String? mode})` (line 1-basiert, mode `'line'|'sheet'`); State `_lineIndex`, `_sheetMode`, `_plan`, `_unit`; `void _selectLine(int i)`, `void _setSheetMode(bool on)`; `static ({int line, bool sheet}) initialSheetPosition({required int lineCount, int? paramLine, String? paramMode, required ({int line, bool sheet}) remembered})` (rein, testbar, in der Datei als Top-Level-Funktion `initialSheetPosition`).

- [ ] **Step 1: Write the failing unit test** (in `practice_session_screen_test.dart`, eigene Gruppe, rein):

```dart
  group('initialSheetPosition', () {
    const none = (line: 0, sheet: false);
    test('route params win, clamped and parsed leniently', () {
      expect(initialSheetPosition(lineCount: 11, paramLine: 3, paramMode: 'sheet', remembered: none),
          (line: 2, sheet: true));
      expect(initialSheetPosition(lineCount: 11, paramLine: 99, paramMode: null, remembered: none).line, 0);
      expect(initialSheetPosition(lineCount: 11, paramLine: 0, paramMode: 'bogus', remembered: none),
          (line: 0, sheet: false));
    });
    test('else the remembered position, clamped into the sheet', () {
      expect(initialSheetPosition(lineCount: 11, paramLine: null, paramMode: null,
          remembered: (line: 4, sheet: false)), (line: 4, sheet: false));
      expect(initialSheetPosition(lineCount: 3, paramLine: null, paramMode: null,
          remembered: (line: 7, sheet: true)), (line: 0, sheet: true));
    });
  });
```

- [ ] **Step 2: Implement**

Top-level in `practice_session_screen.dart`:

```dart
/// Where a sheet opens: route params (`?line=` 1-based, `?mode=`) win, else
/// the remembered position, else line 1 in line mode. Anything outside the
/// sheet falls back to line 1 — never an error (spec §10).
({int line, bool sheet}) initialSheetPosition({
  required int lineCount,
  required int? paramLine,
  required String? paramMode,
  required ({int line, bool sheet}) remembered,
}) {
  int clampLine(int l) => (l >= 0 && l < lineCount) ? l : 0;
  if (paramLine != null || paramMode != null) {
    return (
      line: clampLine((paramLine ?? 1) - 1),
      sheet: paramMode == 'sheet',
    );
  }
  return (line: clampLine(remembered.line), sheet: remembered.sheet);
}
```

Widget: Felder `final int? line; final String? mode;` + Konstruktor. Router: `line: int.tryParse(state.uri.queryParameters['line'] ?? ''), mode: state.uri.queryParameters['mode']` (beide Routen `/practice/:rudimentId` und `/routine/:rudimentId`).

State:

```dart
  late int _lineIndex;
  late bool _sheetMode;
  late SheetPlan _plan;
  /// The played unit as an ordinary exercise: playback, backing choice and
  /// analysis see only this (spec §2).
  late Rudiment _unit;

  void _buildUnit(Rudiment rudiment) {
    _plan = _sheetMode ? SheetPlan.wholeSheet(rudiment) : SheetPlan.line(rudiment, _lineIndex);
    _unit = rudiment.withSticking(_plan.beats);
    _playback = PatternPlayback.forRudiment(_unit);
  }
```

`initState`: vor `_playback = …`:

```dart
    final rudiment = ref.read(rudimentByIdProvider(widget.rudimentId));
    final pos = initialSheetPosition(
        lineCount: rudiment.sheet.length, paramLine: widget.line, paramMode: widget.mode,
        remembered: SettingsService.sheetPositionFor(widget.rudimentId));
    _lineIndex = pos.line;
    _sheetMode = pos.sheet;
    // (snapshot restore below may override both)
    _buildUnit(rudiment);
```

Snapshot-Restore: `if (snap != null) { …; _lineIndex = snap.line.clamp(0, rudiment.sheet.length - 1); _sheetMode = snap.sheet; _buildUnit(rudiment); }`. `savePracticeSnapshot(... line: _lineIndex, sheet: _sheetMode)`.

Wechsel:

```dart
  /// Line or mode change: new unit, new loop, fresh beat log. While playing
  /// the engine rebuilds and the new unit starts on its "1" (spec §5).
  void _applyUnitChange() {
    final rudiment = ref.read(rudimentByIdProvider(widget.rudimentId));
    setState(() => _buildUnit(rudiment));
    _beatLog.clear();
    _metronomeNotifier.setPatternVolumes(_playback.tickVolumes);
    _applyExtras();
    SettingsService.setSheetPosition(widget.rudimentId, line: _lineIndex, sheet: _sheetMode);
  }

  void _selectLine(int i) {
    final count = ref.read(rudimentByIdProvider(widget.rudimentId)).sheet.length;
    if (i < 0 || i >= count || (i == _lineIndex && !_sheetMode)) return;
    _lineIndex = i;
    _sheetMode = false;
    _applyUnitChange();
  }

  void _setSheetMode(bool on) {
    if (on == _sheetMode) return;
    _sheetMode = on;
    _applyUnitChange();
  }
```

`_applyExtras`: `autoBackingStyle(_unit, bpm: bpm)`, `beatsPerBar: _unit.beatsPerBar`. `_finishSession`: `sticking: _unit.sticking`. `_afterSave` → `buildSessionLog(..., sheetLine: _sheetMode ? null : _lineIndex + 1, sheetMode: _sheetMode ? 'sheet' : 'line')`. `dispose`: `SettingsService.setSheetPosition(...)` nicht nötig (bei jedem Wechsel gespeichert).

- [ ] **Step 3: Run** — `.superpowers/tmp/pctest.sh test/features/practice/practice_session_screen_test.dart test/app/` → all passed (bestehende Tests unverändert grün; das Probestück ist nicht `rudimentsSeedData.first`).

- [ ] **Step 4: Commit** — "feat(Blattform): Übungs-Screen spielt die Einheit (Zeile oder Blatt), Routen-Parameter line/mode, Position gemerkt"

---

### Task 8b: Übungs-Screen — Notenfenster, Zeilenleiste, Optionen

**Files:**
- Modify: `lib/features/practice/practice_session_screen.dart` (`build` ab Zeile 750, `_OptionsSheet`, `_showOptionsSheet`)

**Interfaces:**
- Produces: `_LineBar({lineIndex, lineCount, sheetMode, sheetBars, onPrev, onNext, onMode})` mit Keys `line-bar`, `line-prev`, `line-next`, `mode-line`, `mode-sheet`; Texte `'Line 3 / 11'`, `'Sheet · 28 bars'`; `_OptionsSheet` Abschnitt `SHEET` mit `SwitchListTile` „Sticking letters" (Key `opt-sticking`) und „Count hints" (Key `opt-counts`).

- [ ] **Step 1: Write the failing widget tests** (in `practice_session_screen_test.dart`; Helfer `_screen` bekommt `String? id, int? line, String? mode`; neuer Fake `_RecordingMetronomeNotifier` zeichnet `setPatternVolumes`-Aufrufe auf — `volumes.add(v?.length)` — und ruft `super`)

```dart
  group('sheet (Blattform)', () {
    const sheetId = 'single_paradiddle';
    testWidgets('a one-line exercise shows no line bar', (tester) async {
      await _pumpScreen(tester, screen: _screen());
      expect(find.byKey(const ValueKey('line-bar')), findsNothing);
      expect(find.byType(SheetWindow), findsOneWidget);
    });

    testWidgets('a sheet opens on line 1 with the line bar; › moves to line 2 and reloads the loop',
        (tester) async {
      final rec = _RecordingMetronomeNotifier();
      await _pumpScreen(tester, screen: _screen(id: sheetId), metronome: () => rec);
      expect(find.text('Line 1 / 11'), findsOneWidget);
      final line2 = SheetPlan.line(rudimentsSeedData.firstWhere((r) => r.id == sheetId), 1);
      await tester.tap(find.byKey(const ValueKey('line-next')));
      await tester.pump();
      expect(find.text('Line 2 / 11'), findsOneWidget);
      expect(rec.volumes.last, PatternPlayback.forRudiment(
          rudimentsSeedData.firstWhere((r) => r.id == sheetId).withSticking(line2.beats)).totalTicks);
      expect(SettingsService.sheetPositionFor(sheetId), (line: 1, sheet: false));
    });

    testWidgets('Sheet mode plays every line once and shows the bar count', (tester) async {
      final rec = _RecordingMetronomeNotifier();
      await _pumpScreen(tester, screen: _screen(id: sheetId), metronome: () => rec);
      await tester.tap(find.byKey(const ValueKey('mode-sheet')));
      await tester.pump();
      expect(find.text('Sheet · 28 bars'), findsOneWidget);
      expect(find.byKey(const ValueKey('line-next')), findsNothing);
      expect(rec.volumes.last, 28 * 96);
    });

    testWidgets('?line=3 opens line 3; out of range opens line 1', (tester) async {
      final a = await _pumpScreen(tester, screen: _screen(id: sheetId, line: 3));
      expect(find.text('Line 3 / 11'), findsOneWidget);
      a.dispose();
      final b = await _pumpScreen(tester, screen: _screen(id: sheetId, line: 40));
      expect(find.text('Line 1 / 11'), findsOneWidget);
      b.dispose();
    });

    testWidgets('the remembered position is restored', (tester) async {
      await SettingsService.setSheetPosition(sheetId, line: 4, sheet: false);
      await _pumpScreen(tester, screen: _screen(id: sheetId));
      expect(find.text('Line 5 / 11'), findsOneWidget);
    });

    testWidgets('tapping a line in the window selects it', (tester) async {
      await _pumpScreen(tester, screen: _screen(id: sheetId));
      final clip = tester.getRect(find.byType(ClipRect).first);
      await tester.tapAt(Offset(clip.center.dx, clip.top + 16 + 1.5 * sheetRowPitchWithCounts));
      await tester.pump();
      expect(find.text('Line 2 / 11'), findsOneWidget);
    });

    testWidgets('switching lines while playing reloads the loop at once', (tester) async {
      final rec = _RecordingPlayingMetronomeNotifier();
      await _pumpScreen(tester, screen: _screen(id: sheetId), metronome: () => rec);
      final before = rec.volumes.length;
      await tester.tap(find.byKey(const ValueKey('line-next')));
      await tester.pump();
      expect(rec.volumes.length, before + 1);
      expect(find.text('Stop'), findsOneWidget);
    });

    testWidgets('options: sticking letters and count hints switches', (tester) async {
      await _pumpScreen(tester, screen: _screen(id: sheetId));
      await tester.tap(find.byIcon(Icons.more_horiz));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const ValueKey('opt-counts')));
      await tester.tap(find.byKey(const ValueKey('opt-sticking')));
      await tester.tap(find.byKey(const ValueKey('opt-counts')));
      await tester.pump();
      expect(SettingsService.showSticking, isFalse);
      expect(SettingsService.showCounts, isFalse);
    });
  });
```

(Der ⋯-Knopf: Icon prüfen — `_MoreButton` nutzt `Icons.more_horiz`; sonst `find.byType(_MoreButton)` über den Text „⋯". Vorhandene Tests des Optionen-Blatts zeigen den Weg.)

- [ ] **Step 2: Run** → FAIL.

- [ ] **Step 3: Implement**

`build`: nach `activeBeat` → `final loc = activeBeat == null ? null : _plan.locate(activeBeat);` Notation-Bereich:

```dart
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                    child: Center(
                      child: AnimatedOpacity(
                        opacity: isPlaying || _elapsedSeconds > 0 ? 1.0 : 0.6,
                        duration: const Duration(milliseconds: 350),
                        curve: Curves.easeOut,
                        child: SheetWindow(
                          rudiment: rudiment,
                          activeLine: loc?.line ?? _plan.lineIndex,
                          activeIndex: loc?.index,
                          sheetMode: _sheetMode,
                          showSticking: SettingsService.showSticking,
                          showCounts: SettingsService.showCounts,
                          onLineTap: _sheetMode ? null : _selectLine,
                        ),
                      ),
                    ),
                  ),
                ),
                if (rudiment.sheet.length > 1)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                    child: _LineBar(
                      lineIndex: _lineIndex,
                      lineCount: rudiment.sheet.length,
                      sheetMode: _sheetMode,
                      sheetBars: sheetBars(rudiment),
                      onPrev: () => _selectLine(_lineIndex - 1),
                      onNext: () => _selectLine(_lineIndex + 1),
                      onMode: _setSheetMode,
                    ),
                  ),
```

`_LineBar` (44 px, dunkles Theme): links `IconButton(key: line-prev, Icons.chevron_left)` (deaktiviert bei 0 oder Blatt-Modus → im Blatt-Modus ausgeblendet), Mitte `Text(sheetMode ? 'Sheet · $sheetBars bars' : 'Line ${lineIndex + 1} / $lineCount', style: PracticeTypography.label)`, rechts `IconButton(key: line-next)`, dann ein `SegmentedButton<bool>` oder zwei `AppSelectableChip`s mit Keys `mode-line`/`mode-sheet` („Line", „Sheet").

Optionen: `_OptionsSheet` bekommt `showSticking`, `showCounts`, `onShowSticking`, `onShowCounts`; Abschnitt `SHEET` zwischen `SOUND` und „About": zwei `SwitchListTile` mit Keys; im Screen `onShowSticking: (v) async { await SettingsService.setShowSticking(v); setState(() {}); }` (analog counts).

- [ ] **Step 4: Run** — `.superpowers/tmp/pctest.sh test/features/practice/` → all passed.

- [ ] **Step 5: Commit** — "feat(Blattform): Notenfenster, Zeilenleiste ‹ Line n / m › + Line|Sheet, Schalter Sticking/Count hints"

---

### Task 8c: Übungs-Screen — Messung mit der Einheit (Test) + Analyzer

**Files:**
- Test: `test/features/practice/practice_session_screen_test.dart`

- [ ] **Step 1: Write the test** — vorhandene Mikro-Mock-Helfer (`_mockMicPermission`, `_mockHeadphones`) nutzen: Blatt öffnen, Zeile 2 wählen, Start, Beat-Ereignisse über einen Fake-Notifier mit `currentBeatIndex` (wie der Routenwechsel-Test mit `Completer`) einspeisen, Finish → `analyze(sticking:)` bekommt `line2.beats.length` Noten. Falls `MicAnalysisService` im Test nicht ersetzbar ist (heute wird er im Screen konstruiert): stattdessen prüfen, dass das Beat-Log nach dem Wechsel neu beginnt — `_RecordingPlayingMetronomeNotifier` liefert Ticks 0..k, dann Wechsel, dann Ticks; der Test liest über `SessionLog` (`_sessionLogN`) die `clickNoteIndices` nach Finish + Rating: alle Indizes < `line2.beats.length`. Einen der beiden Wege umsetzen, den anderen als Gerätetest-Punkt notieren.

- [ ] **Step 2: Run the whole practice folder and the analyzer**

```bash
.superpowers/tmp/pctest.sh test/features/practice/ test/app/
ssh pc 'cd ~/agent-test-checkouts/drum_coach-k2-result && ~/development/flutter/bin/flutter analyze 2>&1 | tail -5'
```
Expected: all passed; nur die 12 bekannten Warnungen.

- [ ] **Step 3: Commit** — "test(Blattform): Messung sieht die Einheit"

---

### Task 9: Info-Seite mit Blatt + Library-Meta

**Files:**
- Modify: `lib/features/lessons/lesson_detail_screen.dart:30-86`, `lib/features/lessons/lessons_screen.dart:241-244`
- Test: `test/lessons/lesson_detail_sheet_test.dart` (neu), `test/lessons/lessons_screen_filter_test.dart` oder neuer `lessons_screen_meta_test.dart`

- [ ] **Step 1: Write the failing tests**

```dart
// test/lessons/lesson_detail_sheet_test.dart
// Aufbau wie test/lessons/lessons_screen_navigation_test.dart (ProviderScope +
// MaterialApp.router mit einem kleinen GoRouter: '/library/:id' → LessonDetailScreen,
// '/practice/:id' → Placeholder mit dem uri-String).
  testWidgets('the sample sheet page shows the lesson sections, the pattern box and THE SHEET',
      (tester) async {
    // …pump '/library/single_paradiddle'
    expect(find.text('THE SHEET'), findsOneWidget);
    expect(find.byType(SheetStaffWidget), findsOneWidget);
    expect(find.text('PATTERN'), findsOneWidget);          // the plain sticking box
    expect(find.byType(NotationStaffWidget), findsOneWidget);
    for (final t in ['Why it matters', 'How to play it', 'Practice tips', 'Song examples']) {
      expect(find.text(t), findsOneWidget);
    }
  });
  testWidgets('a one-line exercise shows the sheet only, no pattern box', (tester) async {
    // …pump '/library/single_stroke_roll'
    expect(find.text('THE SHEET'), findsOneWidget);
    expect(find.text('PATTERN'), findsNothing);
  });
  testWidgets('tapping line 3 of the sheet starts practice on it', (tester) async {
    // scroll to the sheet, tap its third CustomPaint → route '/practice/single_paradiddle?line=3'
  });
```

Library: `_RudimentTile` Untertitel → `'60–120 BPM · 11 lines · 28 bars'` für das Probestück, `'…BPM'` für Ein-Zeilen (Test: `find.textContaining('11 lines')`).

- [ ] **Step 2: Run** → FAIL.

- [ ] **Step 3: Implement**

Detail-Screen: `_MetaRow`, Beschreibung, dann `if (rudiment.lines.isNotEmpty) [_Label('PATTERN'), NotationStaffWidget(rudiment: rudiment)]`, dann `_Label('THE SHEET')`, `SheetStaffWidget(rudiment: rudiment, onLineTap: (i) => context.push('/practice/${rudiment.id}?line=${i + 1}'))`, `_Legend()`, dann die `technique`-Karten unter `LESSON` (statt `TECHNIQUE`; Karten wie heute), „Start Practice" wie heute (ohne `?line`, die gemerkte Position greift). `_Label` = die vorhandene Label-Text-Zeile als kleines Widget.

Library-Tile: `subtitle: Text(rudiment.sheet.length > 1 ? '${rudiment.minBpm}–${rudiment.targetBpm} BPM · ${rudiment.sheet.length} lines · ${sheetBars(rudiment)} bars' : '${rudiment.minBpm}–${rudiment.targetBpm} BPM', …)`.

- [ ] **Step 4: Run** — `.superpowers/tmp/pctest.sh test/lessons/ test/app/` → all passed.

- [ ] **Step 5: Commit** — "feat(Blattform): Info-Seite zeigt Muster-Kasten, ganzes Blatt (Tipp startet die Zeile) und Lektion; Library-Meta mit Zeilen/Takten"

---

### Task 10: Doku, ganze Suite, Analyzer, Review, Draft-PR

**Files:**
- Modify: `docs/CLAUDE.md` (Theme-Abschnitt: Übungs-Screen-Absatz um Fenster/Zeilenleiste; neuer Absatz „Sheets (Blattform)" unter Data Models)
- Create: `docs/BERICHT_BLATTFORM.md`

- [ ] **Step 1: Docs** — CLAUDE.md: `Rudiment.lines`/`sheet`/`withSticking`, `SheetPlan`, `SheetStaffWidget` (Kästchen, `|: :|`, Schlussstrich, Zählhilfe, Label-Schrift), `SheetWindow` (vier Reihen, oben spielt, +1 animiert, sonst Sprung), Zeilenleiste, `?line=&mode=`, Position je Übung, Lektion nur auf der Info-Seite, Regel ≤ 64 Takte. Bericht: Was gebaut, Entscheidungen 30.09. (inkl. Kommando zurück und Notenfenster), Tests (Zahlen), Sichtprüfung (Emulator-Seite), offene Punkte (§12 der Spec), Gerätetest-Liste.

- [ ] **Step 2: Whole suite + analyzer**

```bash
ssh pc 'touch ~/.no-idle-suspend'
.superpowers/tmp/pctest.sh
ssh pc 'cd ~/agent-test-checkouts/drum_coach-k2-result && ~/development/flutter/bin/flutter analyze 2>&1 | tail -5'
ssh pc 'rm -f ~/.no-idle-suspend'
```
Expected: `All tests passed!` (≈ 395 + ~40 neue), nur die 12 bekannten Warnungen.

- [ ] **Step 3: Emulator-Sichtprüfung** (AVD `s23` auf pc, Skript `/home/uli/.claude/jobs/27b654de/tmp/emu.sh`; APK dort bauen): Screens — Probestück Zeile 1 vor Start (Fenster 4 Reihen, Kästchen, `|: :|`, Zählhilfe), im Lauf Zeile 3 (Cursor oben, Vorschau gedämpft), Blatt-Modus mitten in der Challenge (Fenster verschoben), Info-Seite (PATTERN + THE SHEET + LESSON), Alt-Übung (eine Zeile, `|: :|`, keine Leiste), Optionen-Blatt mit SHEET. Als Seite veröffentlichen (Artifact, nur Bilder + kurze Bildunterschriften).

- [ ] **Step 4: Frischer Review** (superpowers `requesting-code-review` mit dem Review-Focus oben) → Findings fixen (TDD), Suite erneut.

- [ ] **Step 5: Draft-PR** `blattform` → `main`: Body mit Kurzbeschreibung, Bericht-Link, Test-Zahlen, Sichtprüfungs-Link, dann die Attribution. Push. Kopien: `~/BERICHT_BLATTFORM.md`, `~/PLAN_BLATTFORM.md`.

---

### Task 11: Gerätetest S23 (nach Ulis Freigabe der Sichtprüfung)

- Laptop einschalten lassen, S23 anstecken (Uli sagt Bescheid); APK **auf dem Laptop** bauen (`~/agent-test-checkouts/drum_coach-main`, Signatur-Falle), Skript `/home/uli/.claude/jobs/27b654de/tmp/s23.sh`. **Nie blind tippen**: vor jedem adb-Tipp den Vordergrund prüfen; sobald Uli selbst spielt, das Handy nicht anfassen.
- Punkte (Spec §11): Zeile im Kreis mit Backing; ‹ › im Lauf (Eins sitzt, Fenster springt); Blatt-Modus bei 60 BPM — **Zeit bis zum ersten Klick messen** (Grenze 1 s, `adb logcat` Zeitstempel Start-Tipp → erstes Beat-Event) und bei 140 BPM; Fenster rutscht an jeder Reihengrenze, Challenge über vier Reihen, Umlauf springt; vier Reihen passen zwischen Kopfzeile und Zeilenleiste (S23 1080×2316); Mikro-Messung auf einer Zwei-Takt-Zeile (Kopfhörer); Info-Seite; Alt-Übung unverändert.
- Ergebnis in den Bericht, Uli entscheidet Merge.
