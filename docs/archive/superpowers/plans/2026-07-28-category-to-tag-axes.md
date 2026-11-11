# Category → Tag Axes Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace `Rudiment.category` (a flat, one-per-exercise category string) with four multi-select tag axes (`Skill`, `Genre`, `Limb`, plus `Subdivision` derived from the existing `NoteGrid`/`gridUnit`), retag all 41 seed rudiments, and rebuild the Lessons screen as a multi-axis filter UI — per `docs/superpowers/specs/2026-07-28-category-to-tag-axes-design.md`.

**Architecture:** Additive-first, cutover-last. Task 1 adds the new tag fields to `Rudiment` with safe defaults so nothing breaks. Task 2 populates real tag values on the 41 seed entries via a small, reviewable Python script (mechanical category→tag mapping, not 41 manual edits). Task 3 builds and unit-tests the pure filter-combination function in isolation. Task 4 is the single cutover: remove `category`/`level`/`practicePlanProvider`/`groupedRudiments`, rewrite the Lessons screen on the new filter function, and fix every remaining call site in one atomic, testable step (splitting it further would leave the app non-compiling between commits).

**Tech Stack:** Dart 3 (null-safe), Flutter, Riverpod (`@riverpod` codegen), `flutter_test`, Python 3 (one-off codemod scripts, not a project dependency).

## Global Constraints

- Extend existing code, don't rewrite what doesn't need to change (brief: "Bestehenden Code respektieren: erweitern statt neu schreiben, wo möglich").
- No new dependencies (brief: "Keine stillen Abhängigkeiten auf schwergewichtige Bibliotheken ohne Rückfrage") — this plan adds zero packages. The Python scripts are one-off local tools, not shipped or added to `pubspec.yaml`.
- Existing test suite (`flutter test`) must stay green at the end of every task.
- Do not touch `docs/AUDIT.md` §6 steps 3+ (renderer interface, sticking generator, kit mode, song import, sync map) — out of scope here.
- Do not "fix" the three pre-existing duplicate rudiment IDs (`flam_accent`, `flam_paradiddle`, `paradiddle_diddle`) found during spec research — documented in the spec, not this plan's concern.
- Do not build Tempo-Zone or Modus-Eignung as tags (spec decision: redundant with runtime BPM-zone logic and the existing `voicing` field, respectively).

---

### Task 1: Add `Skill`/`Genre`/`Limb` tag fields and extend `NoteGrid`

**Files:**
- Modify: `lib/features/lessons/models/rudiment.dart`
- Test: `test/lessons/rudiment_model_test.dart`

**Interfaces:**
- Produces: `enum Skill { control, coordination, endurance, groove, fill, independence }` (each with a `label` getter), `enum Genre { rock, funk, jazz, latin, metal, drumCorps }` (with `label`), `enum Limb { hands, feet, doubleBass, allFour }` (with `label`), `extension NoteGridLabel on NoteGrid { String get label }`, `NoteGrid.sixteenthTriplet`, `NoteGrid.thirtySecond`, `Rudiment.skills` (`Set<Skill>`, default `const {}`), `Rudiment.genres` (`Set<Genre>`, default `const {}`), `Rudiment.limbs` (`Set<Limb>`, default `const {Limb.hands}`) — all new named constructor params on the existing `Rudiment` class.

- [ ] **Step 1: Write the failing test**

Read the current `test/lessons/rudiment_model_test.dart` first (it already has a `_makeRudiment` helper and a `Rudiment.source / Rudiment.voicing` group from the prior migration step — do not remove those). Add the new imports/helper params and two new test groups. Replace the whole file with:

```dart
import 'package:drum_coach/features/lessons/models/rudiment.dart';
import 'package:flutter_test/flutter_test.dart';

Rudiment _makeRudiment({
  ExerciseSource? source,
  ExerciseVoicing? voicing,
  Set<Skill>? skills,
  Set<Genre>? genres,
  Set<Limb>? limbs,
}) {
  return Rudiment(
    id: 'test_rudiment',
    name: 'Test',
    category: 'Rolls',
    description: 'desc',
    minBpm: 60,
    targetBpm: 120,
    difficulty: Difficulty.beginner,
    sticking: const [StrokeBeat(hand: Hand.right)],
    source: source ?? ExerciseSource.authored,
    voicing: voicing ?? ExerciseVoicing.pad,
    skills: skills ?? const {},
    genres: genres ?? const {},
    limbs: limbs ?? const {Limb.hands},
  );
}

void main() {
  group('Rudiment.source / Rudiment.voicing', () {
    test('defaults to authored + pad when not specified', () {
      final r = Rudiment(
        id: 'defaults',
        name: 'Defaults',
        category: 'Rolls',
        description: 'desc',
        minBpm: 60,
        targetBpm: 120,
        difficulty: Difficulty.beginner,
        sticking: const [StrokeBeat(hand: Hand.right)],
      );
      expect(r.source, ExerciseSource.authored);
      expect(r.voicing, ExerciseVoicing.pad);
    });

    test('accepts an explicit generated source', () {
      final r = _makeRudiment(source: ExerciseSource.generated);
      expect(r.source, ExerciseSource.generated);
    });

    test('accepts an explicit excerpt source', () {
      final r = _makeRudiment(source: ExerciseSource.excerpt);
      expect(r.source, ExerciseSource.excerpt);
    });

    test('accepts an explicit kit voicing', () {
      final r = _makeRudiment(voicing: ExerciseVoicing.kit);
      expect(r.voicing, ExerciseVoicing.kit);
    });
  });

  group('Rudiment.skills / genres / limbs', () {
    test('defaults to empty skills/genres and hands-only limbs', () {
      final r = Rudiment(
        id: 'defaults',
        name: 'Defaults',
        category: 'Rolls',
        description: 'desc',
        minBpm: 60,
        targetBpm: 120,
        difficulty: Difficulty.beginner,
        sticking: const [StrokeBeat(hand: Hand.right)],
      );
      expect(r.skills, isEmpty);
      expect(r.genres, isEmpty);
      expect(r.limbs, {Limb.hands});
    });

    test('accepts explicit skills, genres, and limbs', () {
      final r = _makeRudiment(
        skills: {Skill.control, Skill.coordination},
        genres: {Genre.drumCorps},
        limbs: {Limb.feet},
      );
      expect(r.skills, {Skill.control, Skill.coordination});
      expect(r.genres, {Genre.drumCorps});
      expect(r.limbs, {Limb.feet});
    });
  });

  group('NoteGrid.label', () {
    test('labels every subdivision value', () {
      expect(NoteGrid.eighth.label, '8tel');
      expect(NoteGrid.triplet.label, 'Triolen');
      expect(NoteGrid.sixteenth.label, '16tel');
      expect(NoteGrid.sixteenthTriplet.label, '16tel-Triolen');
      expect(NoteGrid.thirtySecond.label, '32tel');
    });

    test('extends cellsPerQuarter for the two new brief-required values', () {
      expect(NoteGrid.sixteenthTriplet.cellsPerQuarter, 6);
      expect(NoteGrid.thirtySecond.cellsPerQuarter, 8);
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/lessons/rudiment_model_test.dart`
Expected: FAIL to compile — `Skill`, `Genre`, `Limb`, `NoteGrid.sixteenthTriplet`, `NoteGrid.thirtySecond`, the `skills`/`genres`/`limbs` named parameters, and `.label` on `NoteGrid` don't exist yet.

- [ ] **Step 3: Write minimal implementation**

In `lib/features/lessons/models/rudiment.dart`, replace the `NoteGrid` enum with:

```dart
enum NoteGrid {
  quarter(cellsPerQuarter: 1),
  eighth(cellsPerQuarter: 2),
  triplet(cellsPerQuarter: 3),
  sixteenth(cellsPerQuarter: 4),
  sixteenthTriplet(cellsPerQuarter: 6),
  thirtySecond(cellsPerQuarter: 8);

  final int cellsPerQuarter;
  const NoteGrid({required this.cellsPerQuarter});
}

/// Display label for the Subdivision filter axis (brief: "Subdivision").
extension NoteGridLabel on NoteGrid {
  String get label => switch (this) {
        NoteGrid.quarter => 'Viertel',
        NoteGrid.eighth => '8tel',
        NoteGrid.triplet => 'Triolen',
        NoteGrid.sixteenth => '16tel',
        NoteGrid.sixteenthTriplet => '16tel-Triolen',
        NoteGrid.thirtySecond => '32tel',
      };
}
```

Directly after the existing `ExerciseVoicing` enum, add:

```dart
/// Tag axis: what the exercise trains. Multiple values per exercise are
/// normal — e.g. a linear fill trains both fill and coordination.
enum Skill {
  control(label: 'Kontrolle'),
  coordination(label: 'Koordination'),
  endurance(label: 'Ausdauer'),
  groove(label: 'Groove'),
  fill(label: 'Fill'),
  independence(label: 'Independence');

  final String label;
  const Skill({required this.label});
}

/// Tag axis: stylistic context. Empty for most of today's pure-technique
/// catalog — populated as genre-specific groove/fill content is added.
enum Genre {
  rock(label: 'Rock'),
  funk(label: 'Funk'),
  jazz(label: 'Jazz'),
  latin(label: 'Latin'),
  metal(label: 'Metal'),
  drumCorps(label: 'Drum Corps');

  final String label;
  const Genre({required this.label});
}

/// Tag axis: which limbs the exercise engages.
enum Limb {
  hands(label: 'Hände'),
  feet(label: 'Füße'),
  doubleBass(label: 'Doublebass'),
  allFour(label: 'Alle vier');

  final String label;
  const Limb({required this.label});
}
```

In the `Rudiment` class, add three fields after `voicing` and three constructor params after `this.voicing = ExerciseVoicing.pad,`:

```dart
  /// Tag axis: what this exercise trains. See [Skill].
  final Set<Skill> skills;

  /// Tag axis: stylistic context. See [Genre]. Empty for most technique
  /// exercises; populated for genre-specific content (e.g. drum corps).
  final Set<Genre> genres;

  /// Tag axis: which limbs this exercise engages. See [Limb].
  final Set<Limb> limbs;
```

```dart
    this.skills = const {},
    this.genres = const {},
    this.limbs = const {Limb.hands},
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/lessons/rudiment_model_test.dart`
Expected: PASS, 8/8 tests green.

- [ ] **Step 5: Run the full test suite to confirm no regressions**

Run: `flutter test`
Expected: All tests pass. No other file references `Skill`/`Genre`/`Limb`/`sixteenthTriplet`/`thirtySecond` yet, so nothing else is affected by this purely additive change.

- [ ] **Step 6: Run static analysis**

Run: `flutter analyze`
Expected: Same pre-existing `buildQuery`-experimental warnings as before this task, zero new issues.

- [ ] **Step 7: Commit**

```bash
git add lib/features/lessons/models/rudiment.dart test/lessons/rudiment_model_test.dart
git commit -m "Add Skill/Genre/Limb tag fields to Rudiment, extend NoteGrid

Migration step 2 from docs/AUDIT.md, task 1 of 4: additive-only —
new fields default to empty (or {Limb.hands}) so no existing
construction site breaks. NoteGrid gains sixteenthTriplet and
thirtySecond, the two brief-listed subdivision values missing today,
plus a display label extension. Subdivision itself stays derived from
gridUnit rather than becoming a separate tag field, per the design
spec's redundancy-avoidance rule."
```

---

### Task 2: Retag the 41 seed rudiments

**Files:**
- Modify: `lib/features/lessons/data/rudiments_seed.dart` (via script, not manual edits)
- Test: `test/lessons/rudiment_tags_test.dart` (create)
- Temporary script: `.claude/worktrees/exercise-fk-rename/tmp_retag_rudiments.py` (not committed — delete after use)

**Interfaces:**
- Consumes: `Skill`, `Genre` from Task 1 (`lib/features/lessons/models/rudiment.dart`).
- Produces: no new symbols — populates `skills`/`genres` on every `rudimentsSeedData` entry. `category` and `level` stay untouched in this task (removed in Task 4).

**Context:** 41 entries is too many to hand-edit reliably in a plan a fresh engineer executes. The category→tag mapping is fixed and mechanical (see the spec's mapping table), so a small, asserting Python script is more reliable than 41 manual `Edit` calls.

- [ ] **Step 1: Write the failing test**

Create `test/lessons/rudiment_tags_test.dart`:

```dart
import 'package:drum_coach/features/lessons/data/rudiments_seed.dart';
import 'package:drum_coach/features/lessons/models/rudiment.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('seed rudiment tags', () {
    test('every seed rudiment has at least one skill tag', () {
      for (final r in rudimentsSeedData) {
        expect(r.skills, isNotEmpty, reason: '${r.id} has no skill tag');
      }
    });

    test('exactly 7 rudiments carry the drumCorps genre tag', () {
      final count = rudimentsSeedData
          .where((r) => r.genres.contains(Genre.drumCorps))
          .length;
      expect(count, 7);
    });

    test('at least 3 rudiments are tagged both control and coordination', () {
      final count = rudimentsSeedData
          .where((r) =>
              r.skills.contains(Skill.control) &&
              r.skills.contains(Skill.coordination))
          .length;
      expect(count, greaterThanOrEqualTo(3));
    });

    test('at least 2 rudiments are tagged endurance', () {
      final count = rudimentsSeedData
          .where((r) => r.skills.contains(Skill.endurance))
          .length;
      expect(count, greaterThanOrEqualTo(2));
    });

    test('linear-pattern-family rudiments are tagged fill', () {
      final linear =
          rudimentsSeedData.where((r) => r.id.startsWith('linear_beat_'));
      expect(linear, isNotEmpty);
      for (final r in linear) {
        expect(r.skills, contains(Skill.fill), reason: r.id);
      }
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/lessons/rudiment_tags_test.dart`
Expected: FAIL — every `skills`/`genres` set is still empty (Task 1's defaults), so all five assertions fail (`isNotEmpty` fails, counts are `0`).

- [ ] **Step 3: Write and run the retagging script**

Create `tmp_retag_rudiments.py` in the repo root (worktree root, i.e. `/home/uli/projects/drum_coach/.claude/worktrees/exercise-fk-rename/tmp_retag_rudiments.py`):

```python
import re

MAPPING = {
    "Rolls": (["Skill.control"], []),
    "Paradiddles": (["Skill.control", "Skill.coordination"], []),
    "Flams": (["Skill.control"], []),
    "Ruffs": (["Skill.control"], []),
    "Ghost Notes": (["Skill.control"], []),
    "Linear Patterns": (["Skill.coordination", "Skill.fill"], []),
    "Marching Snare": (["Skill.control"], ["Genre.drumCorps"]),
    "Geschwindigkeit": (["Skill.control"], []),
    "Stockkontrolle": (["Skill.control"], []),
    "Ausdauer": (["Skill.endurance"], []),
    "Akzente": (["Skill.control"], []),
    "Dynamik & Ghost Notes": (["Skill.control"], []),
    "Timing & Gleichmäßigkeit": (["Skill.control"], []),
}

PATH = "lib/features/lessons/data/rudiments_seed.dart"

with open(PATH, encoding="utf-8") as f:
    text = f.read()

pattern = re.compile(r"(    category: '([^']+)',\n)")


def replace(match):
    full, category = match.group(1), match.group(2)
    skills, genres = MAPPING[category]
    out = full + f"    skills: {{{', '.join(skills)}}},\n"
    if genres:
        out += f"    genres: {{{', '.join(genres)}}},\n"
    return out


new_text, count = pattern.subn(replace, text)
assert count == 41, f"expected 41 category lines, matched {count}"

with open(PATH, "w", encoding="utf-8") as f:
    f.write(new_text)

print(f"tagged {count} entries")
```

Run it from the worktree root:

```bash
python3 tmp_retag_rudiments.py
```

Expected output: `tagged 41 entries`. If the `assert` fires instead, stop and inspect — it means a `category:` line didn't match the expected indentation/quoting and the mapping table is incomplete or the file changed shape; do not proceed until the count is exactly 41.

- [ ] **Step 4: Spot-check the diff**

Run: `git diff lib/features/lessons/data/rudiments_seed.dart | head -60`
Expected: each `category: '...',` line is now immediately followed by a `skills: {...},` line (and a `genres: {...},` line for the 7 Marching Snare entries), with no other lines touched.

- [ ] **Step 5: Delete the temporary script**

```bash
rm tmp_retag_rudiments.py
```

- [ ] **Step 6: Run test to verify it passes**

Run: `flutter test test/lessons/rudiment_tags_test.dart`
Expected: PASS, 5/5 tests green.

- [ ] **Step 7: Run the full test suite to confirm no regressions**

Run: `flutter test`
Expected: All tests pass, including `test/notation_staff_test.dart`'s "renders every seeded pattern" test (it iterates `rudimentsSeedData` and doesn't care about the new fields).

- [ ] **Step 8: Run static analysis**

Run: `flutter analyze`
Expected: Same pre-existing warnings, zero new issues.

- [ ] **Step 9: Commit**

```bash
git add lib/features/lessons/data/rudiments_seed.dart test/lessons/rudiment_tags_test.dart
git commit -m "Retag the 41 seed rudiments with Skill/Genre axes

Migration step 2 from docs/AUDIT.md, task 2 of 4: mechanical
category-to-tag mapping (see docs/superpowers/specs/2026-07-28-
category-to-tag-axes-design.md), applied via a one-off script rather
than 41 manual edits. category/level fields are untouched here —
removed in task 4 once nothing depends on them."
```

---

### Task 3: Build and test the multi-axis filter function

**Files:**
- Create: `lib/features/lessons/rudiment_filter.dart`
- Test: `test/lessons/rudiment_filter_test.dart`

**Interfaces:**
- Consumes: `Rudiment`, `Skill`, `Genre`, `Limb`, `NoteGrid` (`lib/features/lessons/models/rudiment.dart`).
- Produces: `class RudimentFilters` (fields `skills`, `genres`, `limbs`, `subdivisions`, all `Set<...>` defaulting to `const {}`; getter `isEmpty`), `List<Rudiment> filterRudiments(List<Rudiment> all, RudimentFilters filters)` — both used by Task 4's Lessons-screen rewrite.

- [ ] **Step 1: Write the failing test**

Create `test/lessons/rudiment_filter_test.dart`:

```dart
import 'package:drum_coach/features/lessons/models/rudiment.dart';
import 'package:drum_coach/features/lessons/rudiment_filter.dart';
import 'package:flutter_test/flutter_test.dart';

Rudiment _r(
  String id, {
  Set<Skill> skills = const {},
  Set<Genre> genres = const {},
  Set<Limb> limbs = const {Limb.hands},
  NoteGrid gridUnit = NoteGrid.eighth,
}) {
  return Rudiment(
    id: id,
    name: id,
    category: 'Test',
    description: '',
    minBpm: 60,
    targetBpm: 120,
    difficulty: Difficulty.beginner,
    sticking: const [StrokeBeat(hand: Hand.right)],
    skills: skills,
    genres: genres,
    limbs: limbs,
    gridUnit: gridUnit,
  );
}

void main() {
  final control = _r('control', skills: {Skill.control});
  final coordination =
      _r('coordination', skills: {Skill.coordination}, gridUnit: NoteGrid.sixteenth);
  final drumCorps = _r('drumCorps',
      skills: {Skill.control}, genres: {Genre.drumCorps});
  final feetEndurance =
      _r('feetEndurance', skills: {Skill.endurance}, limbs: {Limb.feet});
  final all = [control, coordination, drumCorps, feetEndurance];

  group('filterRudiments', () {
    test('empty filters returns everything', () {
      expect(filterRudiments(all, const RudimentFilters()), all);
    });

    test('single skill filter matches any rudiment with that skill', () {
      final result =
          filterRudiments(all, const RudimentFilters(skills: {Skill.control}));
      expect(result, [control, drumCorps]);
    });

    test('two skills selected match rudiments with either (OR within axis)', () {
      final result = filterRudiments(
        all,
        const RudimentFilters(skills: {Skill.control, Skill.endurance}),
      );
      expect(result, [control, drumCorps, feetEndurance]);
    });

    test('skill + genre filter requires both (AND across axes)', () {
      final result = filterRudiments(
        all,
        const RudimentFilters(
          skills: {Skill.control},
          genres: {Genre.drumCorps},
        ),
      );
      expect(result, [drumCorps]);
    });

    test('subdivision filter matches gridUnit', () {
      final result = filterRudiments(
        all,
        const RudimentFilters(subdivisions: {NoteGrid.sixteenth}),
      );
      expect(result, [coordination]);
    });

    test('limb filter narrows to matching limb set', () {
      final result =
          filterRudiments(all, const RudimentFilters(limbs: {Limb.feet}));
      expect(result, [feetEndurance]);
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/lessons/rudiment_filter_test.dart`
Expected: FAIL to compile — `lib/features/lessons/rudiment_filter.dart` doesn't exist yet.

- [ ] **Step 3: Write minimal implementation**

Create `lib/features/lessons/rudiment_filter.dart`:

```dart
import 'models/rudiment.dart';

/// Selected values per tag axis for the Lessons-screen filter UI. Empty sets
/// mean "no restriction on this axis" — matches everything.
class RudimentFilters {
  final Set<Skill> skills;
  final Set<Genre> genres;
  final Set<Limb> limbs;
  final Set<NoteGrid> subdivisions;

  const RudimentFilters({
    this.skills = const {},
    this.genres = const {},
    this.limbs = const {},
    this.subdivisions = const {},
  });

  bool get isEmpty =>
      skills.isEmpty && genres.isEmpty && limbs.isEmpty && subdivisions.isEmpty;
}

/// Filters [all] by [filters]: within one axis, a selected value matches if
/// the rudiment has ANY of the selected values (OR); across axes, a
/// rudiment must satisfy EVERY axis that has a selection (AND). An axis
/// with no selection does not restrict the result.
List<Rudiment> filterRudiments(List<Rudiment> all, RudimentFilters filters) {
  if (filters.isEmpty) return all;
  return all.where((r) {
    if (filters.skills.isNotEmpty &&
        r.skills.intersection(filters.skills).isEmpty) {
      return false;
    }
    if (filters.genres.isNotEmpty &&
        r.genres.intersection(filters.genres).isEmpty) {
      return false;
    }
    if (filters.limbs.isNotEmpty &&
        r.limbs.intersection(filters.limbs).isEmpty) {
      return false;
    }
    if (filters.subdivisions.isNotEmpty &&
        !filters.subdivisions.contains(r.gridUnit)) {
      return false;
    }
    return true;
  }).toList();
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/lessons/rudiment_filter_test.dart`
Expected: PASS, 6/6 tests green.

- [ ] **Step 5: Run the full test suite to confirm no regressions**

Run: `flutter test`
Expected: All tests pass. Nothing calls `filterRudiments` yet outside this test.

- [ ] **Step 6: Run static analysis**

Run: `flutter analyze`
Expected: Same pre-existing warnings, zero new issues.

- [ ] **Step 7: Commit**

```bash
git add lib/features/lessons/rudiment_filter.dart test/lessons/rudiment_filter_test.dart
git commit -m "Add filterRudiments: pure multi-axis tag filter function

Migration step 2 from docs/AUDIT.md, task 3 of 4. Within one axis,
selected values OR-match; across axes, every axis with a selection
must be satisfied (AND). Built and tested standalone before wiring
into the Lessons screen in task 4, so the combination logic has its
own regression net independent of widget tests."
```

---

### Task 4: Cutover — remove category/level, rewrite Lessons screen on tag filters

**Files:**
- Modify: `lib/features/lessons/models/rudiment.dart` (remove `category`, `level`)
- Modify: `lib/features/lessons/data/rudiments_seed.dart` (via script: remove `category:`/`level:` lines and the two category-list consts)
- Modify: `lib/features/lessons/lessons_provider.dart` (remove `groupedRudiments`, `practicePlanProvider`)
- Modify: `lib/features/lessons/lessons_screen.dart` (full rewrite: filter-chip UI)
- Modify: `lib/features/lessons/lesson_detail_screen.dart` (`_MetaRow`: skill/genre chips instead of category)
- Modify: `lib/features/coaching/exercise_generator_screen.dart` (drop `category: ''`)
- Modify: `test/lessons/rudiment_model_test.dart` (drop `category:` args)
- Modify: `test/notation_staff_test.dart` (remove the `practice plan` test group)
- Create: `test/lessons/lessons_screen_filter_test.dart`
- Temporary script: `tmp_strip_category_level.py` (not committed — delete after use)

**Interfaces:**
- Consumes: `filterRudiments`, `RudimentFilters` (Task 3, `lib/features/lessons/rudiment_filter.dart`); `Skill`, `Genre`, `Limb`, `NoteGrid.label` (Task 1); tagged `rudimentsSeedData` (Task 2).
- Produces: nothing new consumed elsewhere — this is the terminal cutover for `docs/AUDIT.md` §6 step 2.

This task is one atomic unit: `category`/`level` cannot be removed from `Rudiment` while `rudiments_seed.dart`, `lessons_provider.dart`, and `lessons_screen.dart` still reference them, so every file above must land together for the app to compile and tests to pass. Steps are ordered RED (test edits that will fail to compile against today's code) → GREEN (implementation edits, in dependency order) → verify.

- [ ] **Step 1 (RED): Update `test/lessons/rudiment_model_test.dart`**

Remove every `category: 'Rolls',` line from the file (there are three: in `_makeRudiment` and in the two inline `Rudiment(...)` constructions in the `defaults` tests). The file's structure otherwise stays exactly as Task 1 left it. Full replacement:

```dart
import 'package:drum_coach/features/lessons/models/rudiment.dart';
import 'package:flutter_test/flutter_test.dart';

Rudiment _makeRudiment({
  ExerciseSource? source,
  ExerciseVoicing? voicing,
  Set<Skill>? skills,
  Set<Genre>? genres,
  Set<Limb>? limbs,
}) {
  return Rudiment(
    id: 'test_rudiment',
    name: 'Test',
    description: 'desc',
    minBpm: 60,
    targetBpm: 120,
    difficulty: Difficulty.beginner,
    sticking: const [StrokeBeat(hand: Hand.right)],
    source: source ?? ExerciseSource.authored,
    voicing: voicing ?? ExerciseVoicing.pad,
    skills: skills ?? const {},
    genres: genres ?? const {},
    limbs: limbs ?? const {Limb.hands},
  );
}

void main() {
  group('Rudiment.source / Rudiment.voicing', () {
    test('defaults to authored + pad when not specified', () {
      final r = Rudiment(
        id: 'defaults',
        name: 'Defaults',
        description: 'desc',
        minBpm: 60,
        targetBpm: 120,
        difficulty: Difficulty.beginner,
        sticking: const [StrokeBeat(hand: Hand.right)],
      );
      expect(r.source, ExerciseSource.authored);
      expect(r.voicing, ExerciseVoicing.pad);
    });

    test('accepts an explicit generated source', () {
      final r = _makeRudiment(source: ExerciseSource.generated);
      expect(r.source, ExerciseSource.generated);
    });

    test('accepts an explicit excerpt source', () {
      final r = _makeRudiment(source: ExerciseSource.excerpt);
      expect(r.source, ExerciseSource.excerpt);
    });

    test('accepts an explicit kit voicing', () {
      final r = _makeRudiment(voicing: ExerciseVoicing.kit);
      expect(r.voicing, ExerciseVoicing.kit);
    });
  });

  group('Rudiment.skills / genres / limbs', () {
    test('defaults to empty skills/genres and hands-only limbs', () {
      final r = Rudiment(
        id: 'defaults',
        name: 'Defaults',
        description: 'desc',
        minBpm: 60,
        targetBpm: 120,
        difficulty: Difficulty.beginner,
        sticking: const [StrokeBeat(hand: Hand.right)],
      );
      expect(r.skills, isEmpty);
      expect(r.genres, isEmpty);
      expect(r.limbs, {Limb.hands});
    });

    test('accepts explicit skills, genres, and limbs', () {
      final r = _makeRudiment(
        skills: {Skill.control, Skill.coordination},
        genres: {Genre.drumCorps},
        limbs: {Limb.feet},
      );
      expect(r.skills, {Skill.control, Skill.coordination});
      expect(r.genres, {Genre.drumCorps});
      expect(r.limbs, {Limb.feet});
    });
  });

  group('NoteGrid.label', () {
    test('labels every subdivision value', () {
      expect(NoteGrid.eighth.label, '8tel');
      expect(NoteGrid.triplet.label, 'Triolen');
      expect(NoteGrid.sixteenth.label, '16tel');
      expect(NoteGrid.sixteenthTriplet.label, '16tel-Triolen');
      expect(NoteGrid.thirtySecond.label, '32tel');
    });

    test('extends cellsPerQuarter for the two new brief-required values', () {
      expect(NoteGrid.sixteenthTriplet.cellsPerQuarter, 6);
      expect(NoteGrid.thirtySecond.cellsPerQuarter, 8);
    });
  });
}
```

- [ ] **Step 2 (RED): Remove the obsolete `practice plan` test group**

In `test/notation_staff_test.dart`, delete the entire `group('practice plan', () { ... });` block (both its tests, `is ordered by level then difficulty` and `every focus category has at least one exercise`) — `practicePlanProvider` and `exerciseCategories` are being deleted in this task. The file's `group('NotationStaffWidget (5-line staff)', ...)` block stays untouched. The file ends right after that group's closing `});`.

- [ ] **Step 3: Verify the RED state**

Run: `flutter test test/lessons/rudiment_model_test.dart`
Expected: FAIL to compile — `Rudiment(...)` calls in `_makeRudiment` and the defaults tests are missing the still-required `category` argument.

(`test/notation_staff_test.dart` still compiles at this point since `practicePlanProvider`/`exerciseCategories` still exist — its remaining `NotationStaffWidget` group still passes. That's expected; the point of step 2 was deleting the group that will reference removed symbols in step 5, not creating a new RED signal.)

- [ ] **Step 4 (GREEN): Remove `category` and `level` from `Rudiment`**

In `lib/features/lessons/models/rudiment.dart`, remove the field `final String category;` and the field `final int? level;` (with its doc comment "Position in the curated practice-plan progression..."), and remove `required this.category,` and `this.level,` from the constructor parameter list.

- [ ] **Step 5 (GREEN): Strip `category`/`level` from the seed data**

Create `tmp_strip_category_level.py` in the worktree root:

```python
import re

PATH = "lib/features/lessons/data/rudiments_seed.dart"

with open(PATH, encoding="utf-8") as f:
    text = f.read()

text, n_cat = re.subn(r"    category: '[^']*',\n", "", text)
text, n_level = re.subn(r"    level: \d+,\n", "", text)
assert n_cat == 41, f"expected 41 category lines removed, got {n_cat}"
assert n_level == 18, f"expected 18 level lines removed, got {n_level}"

# The two category-list consts are the last thing in the file — drop
# everything from their leading doc comment to EOF.
text, n_tail = re.subn(
    r"\n/// Ordered list of all categories.*",
    "\n",
    text,
    flags=re.S,
)
assert n_tail == 1, "expected to find and strip the trailing category consts"

with open(PATH, "w", encoding="utf-8") as f:
    f.write(text)

print(f"removed {n_cat} category lines, {n_level} level lines, trailing consts stripped")
```

Run it and then delete it:

```bash
python3 tmp_strip_category_level.py
rm tmp_strip_category_level.py
```

Expected output before deleting: `removed 41 category lines, 18 level lines, trailing consts stripped`.

- [ ] **Step 6: Spot-check the diff**

Run: `git diff lib/features/lessons/data/rudiments_seed.dart | tail -30`
Expected: the file now ends right after the last rudiment's closing `),` and `];`, with no `exerciseCategories`/`rudimentCategories` consts left.

- [ ] **Step 7 (GREEN): Rewrite `lessons_provider.dart`**

Replace the full contents of `lib/features/lessons/lessons_provider.dart` with:

```dart
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'data/rudiments_seed.dart';
import 'models/rudiment.dart';

part 'lessons_provider.g.dart';

@riverpod
List<Rudiment> rudiments(RudimentsRef ref) => rudimentsSeedData;

@riverpod
Rudiment rudimentById(RudimentByIdRef ref, String id) {
  return ref.watch(rudimentsProvider).firstWhere(
        (r) => r.id == id,
        orElse: () => throw ArgumentError('Unknown rudiment id: $id'),
      );
}
```

- [ ] **Step 8 (GREEN): Regenerate Riverpod codegen**

```bash
dart run build_runner build --delete-conflicting-outputs
```

Expected: succeeds; `lib/features/lessons/lessons_provider.g.dart` no longer defines `groupedRudimentsProvider`/`practicePlanProvider`.

- [ ] **Step 9 (GREEN): Rewrite `lessons_screen.dart`**

Replace the full contents of `lib/features/lessons/lessons_screen.dart` with:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'lessons_provider.dart';
import 'models/rudiment.dart';
import 'rudiment_filter.dart';

class LessonsScreen extends ConsumerStatefulWidget {
  const LessonsScreen({super.key});

  @override
  ConsumerState<LessonsScreen> createState() => _LessonsScreenState();
}

class _LessonsScreenState extends ConsumerState<LessonsScreen> {
  Set<Skill> _selectedSkills = {};
  Set<Genre> _selectedGenres = {};
  Set<Limb> _selectedLimbs = {};
  Set<NoteGrid> _selectedSubdivisions = {};

  @override
  Widget build(BuildContext context) {
    final all = ref.watch(rudimentsProvider);
    final filtered = filterRudiments(
      all,
      RudimentFilters(
        skills: _selectedSkills,
        genres: _selectedGenres,
        limbs: _selectedLimbs,
        subdivisions: _selectedSubdivisions,
      ),
    );

    final presentGenres = all.expand((r) => r.genres).toSet();
    final presentSubdivisions = all.map((r) => r.gridUnit).toSet();

    return Scaffold(
      appBar: AppBar(title: const Text('Lessons')),
      body: Column(
        children: [
          _FilterAxisRow<Skill>(
            label: 'Skill',
            values: Skill.values,
            selected: _selectedSkills,
            labelOf: (s) => s.label,
            onChanged: (v) => setState(() => _selectedSkills = v),
          ),
          if (presentGenres.isNotEmpty)
            _FilterAxisRow<Genre>(
              label: 'Genre',
              values: Genre.values.where(presentGenres.contains).toList(),
              selected: _selectedGenres,
              labelOf: (g) => g.label,
              onChanged: (v) => setState(() => _selectedGenres = v),
            ),
          _FilterAxisRow<Limb>(
            label: 'Gliedmaßen',
            values: Limb.values,
            selected: _selectedLimbs,
            labelOf: (l) => l.label,
            onChanged: (v) => setState(() => _selectedLimbs = v),
          ),
          if (presentSubdivisions.isNotEmpty)
            _FilterAxisRow<NoteGrid>(
              label: 'Subdivision',
              values:
                  NoteGrid.values.where(presentSubdivisions.contains).toList(),
              selected: _selectedSubdivisions,
              labelOf: (g) => g.label,
              onChanged: (v) => setState(() => _selectedSubdivisions = v),
            ),
          const Divider(height: 1, color: Colors.white12),
          Expanded(
            child: filtered.isEmpty
                ? const _EmptyFilterState()
                : ListView(
                    padding: const EdgeInsets.only(bottom: 24, top: 8),
                    children: [
                      for (final rudiment in filtered)
                        _RudimentTile(rudiment: rudiment),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _FilterAxisRow<T> extends StatelessWidget {
  final String label;
  final List<T> values;
  final Set<T> selected;
  final String Function(T) labelOf;
  final ValueChanged<Set<T>> onChanged;

  const _FilterAxisRow({
    required this.label,
    required this.values,
    required this.selected,
    required this.labelOf,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Colors.white38,
                  letterSpacing: 1.5,
                ),
          ),
          const SizedBox(height: 4),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final value in values) ...[
                  _FilterChip(
                    label: labelOf(value),
                    selected: selected.contains(value),
                    onTap: () {
                      final next = Set<T>.from(selected);
                      if (!next.remove(value)) next.add(value);
                      onChanged(next);
                    },
                  ),
                  const SizedBox(width: 8),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyFilterState extends StatelessWidget {
  const _EmptyFilterState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'Keine Übungen für diese Filterkombination.',
        style: TextStyle(color: Colors.white.withValues(alpha: 0.45)),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected
              ? Colors.deepOrange.withValues(alpha: 0.18)
              : Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? Colors.deepOrange : Colors.white24,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.deepOrange : Colors.white54,
          ),
        ),
      ),
    );
  }
}

class _RudimentTile extends StatelessWidget {
  final Rudiment rudiment;
  const _RudimentTile({required this.rudiment});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      title: Text(
        rudiment.name,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        '${rudiment.minBpm}–${rudiment.targetBpm} BPM',
        style: TextStyle(
            color: Colors.white.withValues(alpha: 0.45), fontSize: 12),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _DifficultyChip(difficulty: rudiment.difficulty),
          const SizedBox(width: 4),
          const Icon(Icons.chevron_right, color: Colors.white24),
        ],
      ),
      onTap: () => context.push('/lessons/${rudiment.id}'),
    );
  }
}

class _DifficultyChip extends StatelessWidget {
  final Difficulty difficulty;
  const _DifficultyChip({required this.difficulty});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: difficulty.color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: difficulty.color.withValues(alpha: 0.4)),
      ),
      child: Text(
        difficulty.label,
        style: TextStyle(
          fontSize: 11,
          color: difficulty.color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
```

- [ ] **Step 10 (GREEN): Update `lesson_detail_screen.dart`'s `_MetaRow`**

In `lib/features/lessons/lesson_detail_screen.dart`, find the `_MetaRow` widget's `build` method. Replace the single category `_InfoChip`:

```dart
        _InfoChip(
          icon: Icons.folder_outlined,
          label: rudiment.category,
          color: Colors.white38,
        ),
```

with one chip per skill and genre tag:

```dart
        for (final skill in rudiment.skills)
          _InfoChip(
            icon: Icons.label_outline,
            label: skill.label,
            color: Colors.white38,
          ),
        for (final genre in rudiment.genres)
          _InfoChip(
            icon: Icons.public,
            label: genre.label,
            color: Colors.white38,
          ),
```

- [ ] **Step 11 (GREEN): Update `exercise_generator_screen.dart`**

In `lib/features/coaching/exercise_generator_screen.dart`, remove the line `category: '',` from `buildGeneratedRudiment`. (`skills`/`genres`/`limbs` stay at their defaults — the AI free-text generator doesn't classify by skill; this is a documented gap, not this task's concern.)

- [ ] **Step 12: Run the full test suite**

Run: `flutter test`
Expected: All tests pass, including the updated `test/lessons/rudiment_model_test.dart`, `test/lessons/rudiment_tags_test.dart` (Task 2), `test/lessons/rudiment_filter_test.dart` (Task 3), and the trimmed `test/notation_staff_test.dart`.

- [ ] **Step 13: Write the Lessons-screen filter widget test**

Create `test/lessons/lessons_screen_filter_test.dart`:

```dart
import 'package:drum_coach/features/lessons/lessons_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('selecting the Ausdauer skill chip narrows the list', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: LessonsScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Single Stroke Roll'), findsOneWidget);

    await tester.tap(find.text('Ausdauer'));
    await tester.pumpAndSettle();

    expect(find.text('Single Stroke Roll'), findsNothing);
    expect(find.text('Sechzehntel-Dauerlauf'), findsOneWidget);
  });

  testWidgets('deselecting the chip restores the full list', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: LessonsScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Ausdauer'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ausdauer'));
    await tester.pumpAndSettle();

    expect(find.text('Single Stroke Roll'), findsOneWidget);
  });
}
```

- [ ] **Step 14: Run test to verify it passes**

Run: `flutter test test/lessons/lessons_screen_filter_test.dart`
Expected: PASS, 2/2 tests green. (This is verifying already-written implementation rather than driving new code — acceptable here since the filter UI's logic was already TDD'd in Task 3; this widget test is a regression net for the wiring, not a design driver.)

- [ ] **Step 15: Run the full test suite one more time**

Run: `flutter test`
Expected: All tests pass.

- [ ] **Step 16: Run static analysis**

Run: `flutter analyze`
Expected: Same pre-existing `buildQuery`-experimental warnings, zero new issues. In particular, confirm no unused-import or unused-element warnings from the deleted `_CategoryHeader`/`_PracticePlanList`/`_LevelBadge` widgets (they were fully removed, not left dangling).

- [ ] **Step 17: Manual smoke check (optional but recommended)**

If a device/emulator is available, run the app (`flutter run`) and confirm: the Lessons tab shows filter chip rows instead of the old 5 tabs, tapping a Skill chip narrows the list, tapping it again restores it, and the "Plan" tab is gone (its content is now solely `dailyRoutineProvider`'s `/routine` screen). If no device is available, state explicitly that this step was skipped — `flutter test`/`flutter analyze` verify correctness, not that the UI reads well on a real screen.

- [ ] **Step 18: Commit**

```bash
git add lib/features/lessons/models/rudiment.dart \
        lib/features/lessons/data/rudiments_seed.dart \
        lib/features/lessons/lessons_provider.dart \
        lib/features/lessons/lessons_provider.g.dart \
        lib/features/lessons/lessons_screen.dart \
        lib/features/lessons/lesson_detail_screen.dart \
        lib/features/coaching/exercise_generator_screen.dart \
        test/lessons/rudiment_model_test.dart \
        test/lessons/lessons_screen_filter_test.dart \
        test/notation_staff_test.dart
git commit -m "Cut over Lessons screen to tag-axis filtering

Migration step 2 from docs/AUDIT.md, task 4 of 4 (final). Removes
category/level from Rudiment, the two category-list consts,
groupedRudimentsProvider, and practicePlanProvider — per the Phase
0.5 decision, dailyRoutineProvider is now the sole planning track.
Replaces the 5-tab Lessons screen with a multi-axis filter UI
(Skill/Genre/Gliedmaßen/Subdivision, OR within an axis, AND across
axes) built on filterRudiments from the previous task."
```

---

## Self-Review

**Spec coverage:**
- Skill/Genre/Limb tag fields + NoteGrid extension → Task 1.
- 41-entry retagging per the mapping table → Task 2.
- Filter combination semantics (OR within axis, AND across axes) → Task 3, directly testing the rule stated in the spec.
- Removal of `category`/`level`/`practicePlanProvider`/`groupedRudiments`/category-list consts → Task 4, steps 4–8.
- Multi-axis filter UI (Skill always shown, Genre/Subdivision only-if-present, Limb always shown) → Task 4, step 9.
- `lesson_detail_screen.dart` chip replacement → Task 4, step 10.
- `exercise_generator_screen.dart` gap (no skill classification for AI-generated exercises) → Task 4, step 11, explicitly left as-is per spec's "Nicht im Scope".
- Duplicate rudiment IDs found during spec research → explicitly called out as out of scope in Global Constraints, not touched by any task.
- Tempo-Zone/Modus-Eignung exclusion → no task builds them; called out in Global Constraints.

**Placeholder scan:** No TBD/TODO markers. Every step has complete, runnable code or an exact command with expected output.

**Type consistency:** `RudimentFilters`/`filterRudiments` signatures introduced in Task 3 are used unchanged in Task 4 step 9. `Skill`/`Genre`/`Limb`/`.label` introduced in Task 1 are used identically in Tasks 2–4 (enum values and the `label` getter name never change). The Task 2 mapping table's skill/genre value names (`Skill.control`, `Skill.coordination`, `Skill.endurance`, `Skill.fill`, `Genre.drumCorps`) are exactly the enum members defined in Task 1 — no typos introduced between the two tasks.
