# Übungs-Sammlung (SP3 + SP2) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax.

**Goal:** Add a browsable, named collection of ~50 rudiment études (10 rudiments × 5, rising in complexity and tempo) plus ~6 technique studies, authored on the SP1 note-value engine via a readable DSL.

**Architecture:** New content lives in one file per rudiment/group under `lib/features/lessons/data/etudes/`, each exporting a `List<Rudiment>`, aggregated in `etudes.dart` and appended to `rudimentsProvider` (progress/SR/program all key off `id`). A `collection`/`collectionGroup` field on `Rudiment` + a browse screen surface them. A pure DSL builds the `StrokeBeat` lists readably; test gates enforce whole-bar fill, integer-24-tick, and unique ids across the combined catalog.

**Tech Stack:** Flutter/Dart (SDK >=3.4.0), Riverpod (codegen), go_router, flutter_test.

## Global Constraints

- Backward compatible: new `Rudiment` fields default to null; existing 41 seed entries + SP1 behavior unchanged.
- New content is built with the SP1 model (`NoteValue`, `Tuplet`, `dotted`, `graces`, `isAccent`, `isGhost`). Only triplet/sextuplet tuplets; every note must land on an integer 24-tick (no dotted 32nds).
- **Every étude fills whole bars**: sum of note durations == n × beatsPerBar (unlike some legacy seeds; this is required for new content).
- Every new `id` is globally unique across `rudimentsSeedData` + `allEtudes`.
- 10 rudiments: single_stroke_roll, double_stroke_roll, single_paradiddle, double_paradiddle, paradiddle_diddle, flam, drag, flam_accent, five_stroke_roll, swiss_army_triplet.
- 5 études per rudiment; difficulty AND minBpm/targetBpm rise across the 5.
- Tests: `flutter test`; analyze: `flutter analyze`. Run from the worktree root `/home/uli/projects/drum_coach/.claude/worktrees/drum-etudes`. Commit after each task with the project trailer:
  `Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>` /
  `Claude-Session: https://claude.ai/code/session_01MaUau8L3orqhR57QvKubqC`.

## File Structure

- `lib/features/lessons/models/rudiment.dart` — `ExerciseCollection` enum + `collection`/`collectionGroup` fields.
- `lib/features/lessons/data/etude_dsl.dart` — DSL helpers + `barCountOrThrow`.
- `lib/features/lessons/data/etudes/<slug>_etudes.dart` — 10 rudiment files + `technique_studies.dart`.
- `lib/features/lessons/data/etudes.dart` — aggregator `allEtudes`.
- `lib/features/lessons/lessons_provider.dart` — append `allEtudes`.
- `lib/features/lessons/collection_screen.dart` — browse.
- `lib/app/router.dart`, `lib/features/dashboard/dashboard_screen.dart` — route + entry.
- Tests: `test/lessons/etude_dsl_test.dart`, `test/lessons/etudes_integrity_test.dart`, `test/lessons/collection_screen_test.dart`.

---

### Task 1: Collection model fields

**Files:** Modify `lib/features/lessons/models/rudiment.dart`; Test `test/lessons/collection_model_test.dart`.

**Produces:** `enum ExerciseCollection { rudimentEtudes, techniqueStudies }` with `String get label`; `Rudiment.collection` (`ExerciseCollection?`, default null) and `Rudiment.collectionGroup` (`String?`, default null).

- [ ] **Step 1: Failing test** — `test/lessons/collection_model_test.dart`:
```dart
import 'package:drum_coach/features/lessons/models/rudiment.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('collection defaults to null (base catalog)', () {
    const r = Rudiment(
      id: 'x', name: 'x', description: 'x', minBpm: 60, targetBpm: 120,
      difficulty: Difficulty.beginner, sticking: [StrokeBeat(hand: Hand.right)]);
    expect(r.collection, isNull);
    expect(r.collectionGroup, isNull);
  });
  test('accepts an explicit collection + group', () {
    const r = Rudiment(
      id: 'x', name: 'x', description: 'x', minBpm: 60, targetBpm: 120,
      difficulty: Difficulty.beginner, sticking: [StrokeBeat(hand: Hand.right)],
      collection: ExerciseCollection.rudimentEtudes,
      collectionGroup: 'Single Paradiddle');
    expect(r.collection, ExerciseCollection.rudimentEtudes);
    expect(r.collection!.label, 'Rudiment-Étüden');
    expect(r.collectionGroup, 'Single Paradiddle');
  });
}
```
- [ ] **Step 2:** `flutter test test/lessons/collection_model_test.dart` → FAIL (undefined).
- [ ] **Step 3:** Add to `rudiment.dart` (near the other tag enums):
```dart
/// A named, browsable set of exercises (distinct from the base catalog).
enum ExerciseCollection {
  rudimentEtudes(label: 'Rudiment-Étüden'),
  techniqueStudies(label: 'Technik-Studien');

  final String label;
  const ExerciseCollection({required this.label});
}
```
Add the fields + constructor params to `Rudiment` (after `limbs`):
```dart
  /// Optional named collection this exercise belongs to (null = base catalog).
  final ExerciseCollection? collection;

  /// Optional sub-heading within the collection (e.g. the rudiment name).
  final String? collectionGroup;
```
and in the `const Rudiment({...})` parameter list: `this.collection, this.collectionGroup,`.
- [ ] **Step 4:** `flutter test test/lessons/collection_model_test.dart` → PASS.
- [ ] **Step 5:** `flutter analyze lib/features/lessons/models/rudiment.dart` clean; commit `feat(model): add ExerciseCollection + collection fields`.

---

### Task 2: Authoring DSL

**Files:** Create `lib/features/lessons/data/etude_dsl.dart`; Test `test/lessons/etude_dsl_test.dart`.

**Produces (exact signatures):**
```dart
const Hand R = Hand.right;
const Hand L = Hand.left;
StrokeBeat note(Hand h, NoteValue v, {bool accent = false, bool ghost = false, bool dotted = false, Tuplet tuplet = Tuplet.none, List<Hand> graces = const []});
StrokeBeat rest(NoteValue v, {bool dotted = false, Tuplet tuplet = Tuplet.none});
StrokeBeat flam(Hand h, NoteValue v, {bool accent = false});   // graces:[opposite(h)]
StrokeBeat drag(Hand h, NoteValue v, {bool accent = false});   // graces:[opposite(h), opposite(h)]
List<StrokeBeat> run(List<Hand> hands, NoteValue v, {Tuplet tuplet = Tuplet.none, Set<int> accents = const {}});
List<StrokeBeat> eighths(List<Hand> h, {Set<int> accents = const {}});     // run(h, eighth)
List<StrokeBeat> sixteenths(List<Hand> h, {Set<int> accents = const {}});  // run(h, sixteenth)
List<StrokeBeat> triplet8(List<Hand> h, {Set<int> accents = const {}});    // run(h, eighth, triplet)
List<StrokeBeat> sextuplet16(List<Hand> h, {Set<int> accents = const {}}); // run(h, sixteenth, sextuplet)
int barCountOrThrow(List<StrokeBeat> beats, {required int beatsPerBar, required NoteGrid grid});
```
`opposite(Hand)` is a private helper. `run` applies `accents` by index. `barCountOrThrow` sums `resolveNote(b, grid).quarters`, throws `ArgumentError` if the total isn't a positive integer multiple of `beatsPerBar`, else returns the bar count.

- [ ] **Step 1: Failing test** — `test/lessons/etude_dsl_test.dart`:
```dart
import 'package:drum_coach/features/lessons/data/etude_dsl.dart';
import 'package:drum_coach/features/lessons/models/rudiment.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('note applies flags', () {
    final n = note(R, NoteValue.eighth, accent: true);
    expect(n.hand, Hand.right);
    expect(n.value, NoteValue.eighth);
    expect(n.isAccent, isTrue);
  });
  test('flam / drag graces', () {
    expect(flam(R, NoteValue.quarter).graces, [Hand.left]);
    expect(drag(L, NoteValue.quarter).graces, [Hand.right, Hand.right]);
  });
  test('run applies accents by index', () {
    final r = run([R, L, R, L], NoteValue.sixteenth, accents: {0, 2});
    expect(r.length, 4);
    expect(r[0].isAccent, isTrue);
    expect(r[1].isAccent, isFalse);
    expect(r[2].isAccent, isTrue);
    expect(r.every((b) => b.value == NoteValue.sixteenth), isTrue);
  });
  test('triplet8 marks the tuplet', () {
    final t = triplet8([R, L, R]);
    expect(t.length, 3);
    expect(t.every((b) => b.tuplet == Tuplet.triplet && b.value == NoteValue.eighth), isTrue);
  });
  test('barCountOrThrow returns whole-bar count', () {
    final oneBar = [...eighths([R, L, R, L, R, L, R, L])]; // 8×0.5 = 4q
    expect(barCountOrThrow(oneBar, beatsPerBar: 4, grid: NoteGrid.eighth), 1);
  });
  test('barCountOrThrow throws on a partial bar', () {
    final partial = eighths([R, L, R]); // 1.5q
    expect(() => barCountOrThrow(partial, beatsPerBar: 4, grid: NoteGrid.eighth),
        throwsArgumentError);
  });
}
```
- [ ] **Step 2:** run → FAIL (file missing).
- [ ] **Step 3:** Create `lib/features/lessons/data/etude_dsl.dart`:
```dart
import '../models/rudiment.dart';

const Hand R = Hand.right;
const Hand L = Hand.left;

Hand _opposite(Hand h) => h == Hand.right ? Hand.left : Hand.right;

StrokeBeat note(Hand h, NoteValue v,
        {bool accent = false,
        bool ghost = false,
        bool dotted = false,
        Tuplet tuplet = Tuplet.none,
        List<Hand> graces = const []}) =>
    StrokeBeat(
        hand: h,
        value: v,
        isAccent: accent,
        isGhost: ghost,
        dotted: dotted,
        tuplet: tuplet,
        graces: graces);

StrokeBeat rest(NoteValue v, {bool dotted = false, Tuplet tuplet = Tuplet.none}) =>
    StrokeBeat.rest(value: v, dotted: dotted, tuplet: tuplet);

StrokeBeat flam(Hand h, NoteValue v, {bool accent = false}) =>
    note(h, v, accent: accent, graces: [_opposite(h)]);

StrokeBeat drag(Hand h, NoteValue v, {bool accent = false}) =>
    note(h, v, accent: accent, graces: [_opposite(h), _opposite(h)]);

List<StrokeBeat> run(List<Hand> hands, NoteValue v,
        {Tuplet tuplet = Tuplet.none, Set<int> accents = const {}}) =>
    [
      for (var i = 0; i < hands.length; i++)
        note(hands[i], v, tuplet: tuplet, accent: accents.contains(i)),
    ];

List<StrokeBeat> eighths(List<Hand> h, {Set<int> accents = const {}}) =>
    run(h, NoteValue.eighth, accents: accents);
List<StrokeBeat> sixteenths(List<Hand> h, {Set<int> accents = const {}}) =>
    run(h, NoteValue.sixteenth, accents: accents);
List<StrokeBeat> triplet8(List<Hand> h, {Set<int> accents = const {}}) =>
    run(h, NoteValue.eighth, tuplet: Tuplet.triplet, accents: accents);
List<StrokeBeat> sextuplet16(List<Hand> h, {Set<int> accents = const {}}) =>
    run(h, NoteValue.sixteenth, tuplet: Tuplet.sextuplet, accents: accents);

/// Sum note durations; throw if not a positive whole number of [beatsPerBar]
/// bars, else return the bar count. Guards new étude content.
int barCountOrThrow(List<StrokeBeat> beats,
    {required int beatsPerBar, required NoteGrid grid}) {
  var quarters = 0.0;
  for (final b in beats) {
    quarters += resolveNote(b, grid).quarters;
  }
  final bars = quarters / beatsPerBar;
  final rounded = bars.round();
  if (rounded < 1 || (bars - rounded).abs() > 1e-6) {
    throw ArgumentError(
        '$quarters quarters is not a whole number of $beatsPerBar/4 bars');
  }
  return rounded;
}
```
- [ ] **Step 4:** run → PASS.
- [ ] **Step 5:** analyze clean; commit `feat(lessons): étude authoring DSL`.

---

### Task 3: Aggregator + stubs + provider wiring + integrity tests

**Files:** Create `lib/features/lessons/data/etudes.dart`; create 11 stub files `lib/features/lessons/data/etudes/<slug>_etudes.dart`; modify `lib/features/lessons/lessons_provider.dart`; Test `test/lessons/etudes_integrity_test.dart`.

The 11 slugs (var names): `singleStrokeRoll, doubleStrokeRoll, singleParadiddle, doubleParadiddle, paradiddleDiddle, flam, drag, flamAccent, fiveStrokeRoll, swissArmyTriplet, technique`.

- [ ] **Step 1:** Create each stub `lib/features/lessons/data/etudes/<slug>_etudes.dart` (example for the first):
```dart
import '../../models/rudiment.dart';

/// Filled in a later task. Kept as an empty list so the aggregator compiles.
final List<Rudiment> singleStrokeRollEtudes = <Rudiment>[];
```
(Repeat with the matching variable name per slug; the technique file is `final List<Rudiment> techniqueStudies = <Rudiment>[];` in `technique_studies.dart`.)
- [ ] **Step 2:** Create `lib/features/lessons/data/etudes.dart`:
```dart
import '../models/rudiment.dart';
import 'etudes/double_paradiddle_etudes.dart';
import 'etudes/double_stroke_roll_etudes.dart';
import 'etudes/drag_etudes.dart';
import 'etudes/five_stroke_roll_etudes.dart';
import 'etudes/flam_accent_etudes.dart';
import 'etudes/flam_etudes.dart';
import 'etudes/paradiddle_diddle_etudes.dart';
import 'etudes/single_paradiddle_etudes.dart';
import 'etudes/single_stroke_roll_etudes.dart';
import 'etudes/swiss_army_triplet_etudes.dart';
import 'etudes/technique_studies.dart';

/// All curated étude/study content, appended to the base catalog by
/// `rudimentsProvider`. One file per rudiment/group keeps authoring focused.
final List<Rudiment> allEtudes = <Rudiment>[
  ...singleStrokeRollEtudes,
  ...doubleStrokeRollEtudes,
  ...singleParadiddleEtudes,
  ...doubleParadiddleEtudes,
  ...paradiddleDiddleEtudes,
  ...flamEtudes,
  ...dragEtudes,
  ...flamAccentEtudes,
  ...fiveStrokeRollEtudes,
  ...swissArmyTripletEtudes,
  ...techniqueStudies,
];
```
- [ ] **Step 3:** Wire the provider in `lessons_provider.dart` — change the body of `rudiments` to append: `List<Rudiment> rudiments(RudimentsRef ref) => [...rudimentsSeedData, ...allEtudes];` (add `import 'data/etudes.dart';`). No codegen rerun needed.
- [ ] **Step 4:** Create `test/lessons/etudes_integrity_test.dart` (passes with empty stubs; guards content as it lands):
```dart
import 'package:drum_coach/features/lessons/data/etudes.dart';
import 'package:drum_coach/features/lessons/data/rudiments_seed.dart';
import 'package:drum_coach/features/lessons/models/rudiment.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('étude ids are unique across the whole catalog', () {
    final all = [...rudimentsSeedData, ...allEtudes];
    final seen = <String>{};
    final dupes = <String>{};
    for (final r in all) {
      if (!seen.add(r.id)) dupes.add(r.id);
    }
    expect(dupes, isEmpty, reason: 'duplicate ids: $dupes');
  });

  test('every étude fills whole bars and is a rudimentEtudes/techniqueStudies member', () {
    for (final r in allEtudes) {
      expect(r.collection, isNotNull, reason: '${r.id} has no collection');
      var quarters = 0.0;
      for (final b in r.sticking) {
        quarters += resolveNote(b, r.gridUnit).quarters;
      }
      final bars = quarters / r.beatsPerBar;
      expect((bars - bars.round()).abs() < 1e-6 && bars.round() >= 1, isTrue,
          reason: '${r.id}: ${quarters}q not whole ${r.beatsPerBar}/4 bars');
    }
  });

  test('every étude note lands on an integer 24-tick', () {
    for (final r in allEtudes) {
      for (var i = 0; i < r.sticking.length; i++) {
        final ticks = resolveNote(r.sticking[i], r.gridUnit).quarters * 24;
        expect((ticks - ticks.round()).abs() < 1e-6, isTrue,
            reason: '${r.id} note $i = $ticks ticks not integer');
      }
    }
  });

  test('every étude renders without throwing', () {
    // Structural smoke: all étude entries have a non-empty sticking + rising bpm.
    for (final r in allEtudes) {
      expect(r.sticking, isNotEmpty, reason: '${r.id} empty');
      expect(r.minBpm <= r.targetBpm, isTrue, reason: '${r.id} bpm range');
    }
  });
}
```
- [ ] **Step 5:** `flutter test test/lessons/etudes_integrity_test.dart` → PASS (empty). Extend `test/notation_staff_test.dart`'s existing "renders every seeded pattern" loop to also iterate `allEtudes` (import `etudes.dart`; loop `[...rudimentsSeedData, ...allEtudes]`) so future content gets no-throw render coverage.
- [ ] **Step 6:** `flutter test` full + `flutter analyze lib` (no new errors); commit `feat(lessons): étude aggregator, stubs, provider wiring, integrity tests`.

---

## Content authoring (Tasks 4–14) — template + parameters

Each content task FILLS one stub file with 5 `Rudiment` étude entries (or the technique studies), using the DSL. It must NOT edit the aggregator or other files. After authoring, run `flutter test test/lessons/etudes_integrity_test.dart test/notation_staff_test.dart` — these enforce whole-bar fill, integer ticks, unique ids, and no-throw render. Fix until green, then commit `content(etudes): <rudiment> études`.

### Étude entry template (verbatim shape)
```dart
import '../../models/rudiment.dart';
import '../etude_dsl.dart';

final List<Rudiment> singleParadiddleEtudes = <Rudiment>[
  Rudiment(
    id: 'etude_single_paradiddle_1',
    name: 'Single Paradiddle · Étude 1',
    description: 'RLRR LRLL über 2 Takte — sauber und gleichmäßig.',
    collection: ExerciseCollection.rudimentEtudes,
    collectionGroup: 'Single Paradiddle',
    difficulty: Difficulty.beginner,
    minBpm: 60, targetBpm: 90,
    gridUnit: NoteGrid.sixteenth, beatsPerBar: 4,
    skills: {Skill.control, Skill.coordination},
    sticking: [
      ...sixteenths([R, L, R, R, L, R, L, L], accents: {0, 4}),
      ...sixteenths([R, L, R, R, L, R, L, L], accents: {0, 4}),
      ...sixteenths([R, L, R, R, L, R, L, L], accents: {0, 4}),
      ...sixteenths([R, L, R, R, L, R, L, L], accents: {0, 4}),
    ], // 4 beats × 4 sixteenths = 16 cells = 1 bar; ×? → author fills to whole bars
  ),
  // … Étüden 2–5, rising difficulty + bpm
];
```
Rules for every entry: unique `id` `etude_<slug>_<n>`; `name` `'<Rudiment> · Étude <n>'`; `collection: ExerciseCollection.rudimentEtudes`; `collectionGroup` = the rudiment display name; `difficulty` rises across 1→5 (beginner, beginner, intermediate, advanced, professional); `minBpm`/`targetBpm` rise across 1→5; each `sticking` fills whole bars (verify mentally: cells ÷ (beatsPerBar × grid.cellsPerQuarter) is a whole number). Use `flam(...)`/`drag(...)` for flam/drag rudiments; `triplet8`/`sextuplet16` for triplet-family; `rest(...)` for phrasing; `accents:`/`ghost` for dynamics.

### 5-étude progression (apply per rudiment)
1. Pure rudiment, 2 bars, slow — cleanliness (natural accents only).
2. Add accents on the downbeats / rudiment starts.
3. Phrased: insert rests / orchestrate around the pulse (still whole bars).
4. Mix a second subdivision or feel (e.g. straight ↔ triplet across bars — separate bars, since one grid per exercise).
5. "Challenge": 4 bars, syncopation / accent migration, highest tempo.

### Per-rudiment parameters (Tasks 4–13)

| Task | slug (file) | var | display group | base pattern | grid | engine features | bpm arc (min→target across 1..5) |
|------|-------------|-----|---------------|--------------|------|-----------------|-----------------------------------|
| 4 | single_stroke_roll | singleStrokeRollEtudes | Single Stroke Roll | RLRL… | sixteenth | accents, ghost, rests | 60→90 … 120→200 |
| 5 | double_stroke_roll | doubleStrokeRollEtudes | Double Stroke Roll | RRLL… | sixteenth | accents, rests | 50→80 … 110→180 |
| 6 | single_paradiddle | singleParadiddleEtudes | Single Paradiddle | RLRR LRLL | sixteenth | accents, ghost | 60→90 … 120→160 |
| 7 | double_paradiddle | doubleParadiddleEtudes | Double Paradiddle | RLRLRR LRLRLL | eighth-triplet (triplet8) | accents | 50→80 … 100→150 |
| 8 | paradiddle_diddle | paradiddleDiddleEtudes | Paradiddle-diddle | RLRRLL | eighth-triplet / sixteenth | accents | 50→80 … 100→150 |
| 9 | flam | flamEtudes | Flam | flam accents | eighth/quarter | flam(), accents | 50→80 … 90→150 |
| 10 | drag | dragEtudes | Drag | drag taps | eighth/sixteenth | drag(), accents | 50→80 … 90→140 |
| 11 | flam_accent | flamAccentEtudes | Flam Accent | flam + RL per triplet | eighth-triplet | flam(), accents | 60→90 … 100→150 |
| 12 | five_stroke_roll | fiveStrokeRollEtudes | Five Stroke Roll | RRLL R (accented) | sixteenth | doubles + accent | 50→80 … 100→140 |
| 13 | swiss_army_triplet | swissArmyTripletEtudes | Swiss Army Triplet | flam + RR/LL per triplet | eighth-triplet | flam(), accents | 60→90 … 100→140 |

### Task 14: Technique studies (`technique_studies.dart`, var `techniqueStudies`)
6 entries, `collection: ExerciseCollection.techniqueStudies`, `collectionGroup` per type:
- 2 × "Akzent-Studien" (skills {control}): moving single-stroke accents (accent walks 1→2→3→4 across bars); accent+ghost interplay.
- 2 × "Kombinations-Studien" (skills {coordination, fill}): a phrase joining 2–3 rudiments (e.g. paradiddle → single-stroke-four → flam) over 4 bars.
- 2 × "Roll-/Endurance-Studien" (skills {endurance, control}): sustained doubles with a crescendo (ghost→normal→accent); long single-stroke endurance.
Ids `etude_study_<n>`; difficulty/bpm rising within each pair.

---

### Task 15: Collection browse screen + routing + entry

**Files:** Create `lib/features/lessons/collection_screen.dart`; modify `lib/app/router.dart`, `lib/features/dashboard/dashboard_screen.dart`; Test `test/lessons/collection_screen_test.dart`.

- [ ] **Step 1: Failing widget test** — pump `CollectionScreen(collection: ExerciseCollection.rudimentEtudes)` inside a `ProviderScope` + `MaterialApp`, expect the group headings (e.g. finds text 'Single Paradiddle') and one tappable tile per étude. (Use `find.text`, `find.byType(ListTile)`.)
- [ ] **Step 2:** run → FAIL (missing).
- [ ] **Step 3:** Implement `CollectionScreen` (ConsumerWidget): read `rudimentsProvider`, filter `r.collection == collection`, group by `collectionGroup` (LinkedHashMap preserving order), render sticky group headers + `ListTile`s (title = name, subtitle = difficulty + bpm range) that `context.push('/practice/${r.id}')`. Match existing screen styling (dark theme, see `program_screen.dart`/`lessons_screen.dart`).
- [ ] **Step 4:** Add route in `router.dart`: `GoRoute(path: '/collection/:name', builder: (_, s) => CollectionScreen(collection: ExerciseCollection.values.byName(s.pathParameters['name']!)))`. Add a dashboard `_DashCard` ("Übungs-Sammlung") that pushes `/collection/rudimentEtudes` (mirror the existing program entry at `dashboard_screen.dart`).
- [ ] **Step 5:** run the widget test → PASS; `flutter test` full; `flutter analyze lib` no new errors; commit `feat(lessons): collection browse screen + route + dashboard entry`.

---

### Task 16: Verification pass

- [ ] `flutter test` — all green (incl. étude integrity + render over `allEtudes`).
- [ ] `flutter analyze` — no new errors.
- [ ] Count check: `allEtudes` has 50 rudiment études (10×5) + 6 studies = 56; every id unique.
- [ ] Device/visual pass (bundled with SP1, via cross-machine-test-deploy): open the collection, spot-check several études' notation + playback on PC/phone; confirm grouping and navigation.
- [ ] Update PR #8 description to note SP2+SP3 landed.

## Self-Review

- Model/collection → Task 1. DSL → Task 2. Aggregator/provider/integrity → Task 3. Content → Tasks 4–14 (test-gated). Browse/route/entry → Task 15. Verify → Task 16.
- Content "complete code" is delegated to test-gated authoring by design (56 creative patterns); the template, per-rudiment params, and integrity tests are the contract.
- Type consistency: `ExerciseCollection`, `collection`/`collectionGroup`, `allEtudes`, `barCountOrThrow(beats, beatsPerBar:, grid:)`, DSL signatures — consistent across tasks.
