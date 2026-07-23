# Tag Axes Migration (category -> skill/family/genre/limbs) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace `Rudiment.category` (a single free-text string) with the multi-axis tag model from `docs/AUDIT.md` Phase 0.5b — `skill` (multi-value), `family` (nullable PAS rudiment family), `genre` (defaulted), `limbs` (defaulted) — and rebuild `LessonsScreen`/`LessonDetailScreen` on top of tag filters instead of category tabs, per the approved mapping table.

**Architecture:** Additive-first, TDD, four tasks that each leave `flutter test`/`flutter analyze` green:
1. Add the new enums + `Rudiment` fields, defaulted to match today's reality (mirrors the Step-1 pattern already used for `source`/`voicing`).
2. Mechanically retag all 41 seed rudiments per the approved `docs/AUDIT.md` Phase 0.5b mapping table, via a scripted find/insert (category-driven, so no per-entry hand-editing).
3. Replace `groupedRudimentsProvider`/`practicePlanProvider` with tag-based filtering (`filterRudiments` pure function + a `LessonsFilter` notifier), and rebuild `LessonsScreen`/`LessonDetailScreen` on top of it. This is the point where `category`/`level` stop being read by any screen.
4. Remove the now-dead `category`/`level` fields, the `rudimentCategories`/`exerciseCategories` consts, and update the handful of remaining call sites — completing the migration so there is exactly one organization system left (tags), per the Phase 0.5 decision in `docs/AUDIT.md`.

**Tech Stack:** Dart 3 (null-safe), Flutter, Riverpod `@riverpod` codegen, `flutter_test`.

## Global Constraints

- Extend existing code, don't rewrite it wholesale — `LessonsScreen`/`LessonDetailScreen` keep their existing `_FilterChip`/`_DifficultyChip`/`_InfoChip`/`_Legend` helper widgets unchanged; only the parts that read `category`/`level` change.
- No new dependencies.
- Every task individually functional and testable; `flutter test` and `flutter analyze` must stay green after every task's commit.
- Do not touch the metronome engine, Isar collections, or `docs/superpowers/plans/2026-07-21-exercise-source-voicing.md`'s deferred FK rename (`RudimentProgress`/`PracticeSession.rudimentId` -> `exerciseId`) — that is still deferred to the future `Rudiment` -> `Exercise` rename step per that plan's Self-Review.
- Mapping source of truth: `docs/AUDIT.md` § "Phase 0.5b — Tag-Achsen-Mapping-Vorschlag", approved by Uli 2026-07-23 ("Mapping sieht gut aus, leg los mit dem Plan").

---

### Task 1: Add `Skill`/`Genre`/`Limb`/`RudimentFamily` enums and fields to `Rudiment`

**Files:**
- Modify: `lib/features/lessons/models/rudiment.dart`
- Test: `test/lessons/rudiment_model_test.dart` (append to existing file)

**Interfaces:**
- Produces: `enum Skill { groove, fill, koordination, ausdauer, kontrolle, independence }` (each with a `label` getter), `enum Genre { general, drumCorps }` (with `label`), `enum Limb { hands, feet, doublebass, allFour }`, `enum RudimentFamily { roll, paradiddle, flam, ruff }` (with `label`). `Rudiment.skill` (`List<Skill>`, defaults `const []`), `Rudiment.family` (`RudimentFamily?`, defaults `null`), `Rudiment.genre` (`Genre`, defaults `Genre.general`), `Rudiment.limbs` (`List<Limb>`, defaults `const [Limb.hands]`) — four new named constructor params on `Rudiment` (`lib/features/lessons/models/rudiment.dart:74-121`).

- [ ] **Step 1: Write the failing test**

Append to `test/lessons/rudiment_model_test.dart` (add this `group` after the existing `Rudiment.source / Rudiment.voicing` group, before the final closing `}` of `main()`):

```dart
  group('Rudiment.skill / .family / .genre / .limbs', () {
    test('defaults to no skill, no family, general genre, hands', () {
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
      expect(r.skill, isEmpty);
      expect(r.family, isNull);
      expect(r.genre, Genre.general);
      expect(r.limbs, [Limb.hands]);
    });

    test('accepts explicit skill, family, genre, limbs', () {
      final r = Rudiment(
        id: 'explicit',
        name: 'Explicit',
        category: 'Rolls',
        description: 'desc',
        minBpm: 60,
        targetBpm: 120,
        difficulty: Difficulty.beginner,
        sticking: const [StrokeBeat(hand: Hand.right)],
        skill: const [Skill.koordination, Skill.kontrolle],
        family: RudimentFamily.paradiddle,
        genre: Genre.drumCorps,
        limbs: const [Limb.hands, Limb.feet],
      );
      expect(r.skill, [Skill.koordination, Skill.kontrolle]);
      expect(r.family, RudimentFamily.paradiddle);
      expect(r.genre, Genre.drumCorps);
      expect(r.limbs, [Limb.hands, Limb.feet]);
    });

    test('enum labels are human-readable', () {
      expect(Skill.kontrolle.label, 'Kontrolle');
      expect(Genre.drumCorps.label, 'Drum Corps');
      expect(RudimentFamily.paradiddle.label, 'Paradiddles');
    });
  });
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/lessons/rudiment_model_test.dart`
Expected: FAIL to compile — `Skill`, `Genre`, `Limb`, `RudimentFamily`, and the `skill`/`family`/`genre`/`limbs` named parameters don't exist yet on `Rudiment`.

- [ ] **Step 3: Write minimal implementation**

In `lib/features/lessons/models/rudiment.dart`, add the four enums after the existing `ExerciseVoicing` enum (after line 38, before the `StrokeBeat` class doc comment on line 40):

```dart
/// What an exercise trains. Mirrors the brief's "Skill" axis
/// (`docs/AUDIT.md` Phase 0.5b) — multi-value, since one exercise can train
/// several things at once (e.g. a linear fill trains both `koordination`
/// and `independence`).
enum Skill {
  groove(label: 'Groove'),
  fill(label: 'Fill'),
  koordination(label: 'Koordination'),
  ausdauer(label: 'Ausdauer'),
  kontrolle(label: 'Kontrolle'),
  independence(label: 'Independence');

  final String label;
  const Skill({required this.label});
}

/// Musical/stylistic context. `general` covers today's pure hand-technique
/// catalog (no groove content exists yet); `drumCorps` is the one genre
/// value with real meaning today (Marching Snare rudiments).
enum Genre {
  general(label: 'Allgemein'),
  drumCorps(label: 'Drum Corps');

  final String label;
  const Genre({required this.label});
}

/// Which limbs an exercise is played with. All of today's catalog is
/// `hands` (no foot notation exists yet) — this exists so future kit-mode
/// content (bass drum, doublebass, four-limb coordination) has somewhere
/// to go without a model change.
enum Limb { hands, feet, doublebass, allFour }

/// The classic PAS rudiment family, for the four rudiment groups that have
/// one. `null` on [Rudiment.family] means "not a classic PAS rudiment"
/// (e.g. a Linear Pattern or a focused technique exercise).
enum RudimentFamily {
  roll(label: 'Rolls'),
  paradiddle(label: 'Paradiddles'),
  flam(label: 'Flams'),
  ruff(label: 'Ruffs');

  final String label;
  const RudimentFamily({required this.label});
}
```

Then in the `Rudiment` class, add the four fields after `voicing` and the four constructor params after `this.voicing = ExerciseVoicing.pad,`:

```dart
  /// Origin of this exercise. Defaults to [ExerciseSource.authored] since
  /// today's seed catalog is entirely hand-notated.
  final ExerciseSource source;

  /// Presentation/playback mode. Defaults to [ExerciseVoicing.pad] since
  /// the current single-voice [NotationStaffWidget] is pad-shaped.
  final ExerciseVoicing voicing;

  /// What this exercise trains. See [Skill]. Empty by default — only the
  /// seed catalog (`rudiments_seed.dart`) is expected to populate this.
  final List<Skill> skill;

  /// Classic PAS rudiment family, if this is one. See [RudimentFamily].
  final RudimentFamily? family;

  /// Musical/stylistic context. See [Genre].
  final Genre genre;

  /// Which limbs this exercise is played with. See [Limb].
  final List<Limb> limbs;

  const Rudiment({
    required this.id,
    required this.name,
    required this.category,
    required this.description,
    required this.minBpm,
    required this.targetBpm,
    required this.difficulty,
    required this.sticking,
    this.gridUnit = NoteGrid.eighth,
    this.beatsPerBar = 4,
    this.technique = const [],
    this.svgAssetPath,
    this.level,
    this.source = ExerciseSource.authored,
    this.voicing = ExerciseVoicing.pad,
    this.skill = const [],
    this.family,
    this.genre = Genre.general,
    this.limbs = const [Limb.hands],
  });
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/lessons/rudiment_model_test.dart`
Expected: PASS, 7/7 tests green (4 previous + 3 new).

- [ ] **Step 5: Run the full test suite to confirm no regressions**

Run: `flutter test`
Expected: All 45 previous tests + 3 new = 48 PASS. The 41 seed rudiments construct without `skill`/`family`/`genre`/`limbs` args, so they compile unchanged and pick up the new defaults.

- [ ] **Step 6: Run static analysis**

Run: `flutter analyze`
Expected: Same 7 pre-existing `buildQuery experimental_member_use` warnings, 0 errors.

- [ ] **Step 7: Commit**

```bash
git add lib/features/lessons/models/rudiment.dart test/lessons/rudiment_model_test.dart
git commit -m "Add Skill/Genre/Limb/RudimentFamily enums and fields to Rudiment

Migration step 2 (docs/AUDIT.md Phase 0.5b) part 1: additive tag-axis
fields alongside the existing category/level, defaulted to match
today's reality (no skill tag, no family, general genre, hands-only)
so the 41 seed rudiments need no changes yet."
```

---

### Task 2: Retag all 41 seed rudiments per the approved mapping table

**Files:**
- Modify: `lib/features/lessons/data/rudiments_seed.dart`
- Test: `test/lessons/rudiments_seed_tags_test.dart` (create)

**Interfaces:**
- Consumes: `Skill`, `Genre`, `RudimentFamily` from Task 1 (`lib/features/lessons/models/rudiment.dart`).
- Produces: no new public API — this task only changes the data values of the existing `rudimentsSeedData` list.

**Context:** Applies the 13-row mapping table from `docs/AUDIT.md` Phase 0.5b, approved by Uli. `category` and `level` are left untouched in this task (removed in Task 4) — this is purely additive tagging.

- [ ] **Step 1: Write the failing test**

Create `test/lessons/rudiments_seed_tags_test.dart`:

```dart
import 'package:drum_coach/features/lessons/data/rudiments_seed.dart';
import 'package:drum_coach/features/lessons/models/rudiment.dart';
import 'package:flutter_test/flutter_test.dart';

Rudiment _byId(String id) => rudimentsSeedData.firstWhere((r) => r.id == id);

void main() {
  group('rudimentsSeedData tag axes', () {
    test('every seeded rudiment has at least one skill tag', () {
      for (final r in rudimentsSeedData) {
        expect(r.skill, isNotEmpty, reason: '${r.id} has no skill tag');
      }
    });

    test('classic PAS rudiment families are tagged', () {
      expect(_byId('single_stroke_roll').family, RudimentFamily.roll);
      expect(_byId('single_paradiddle').family, RudimentFamily.paradiddle);
      expect(_byId('flam').family, RudimentFamily.flam);
      expect(_byId('single_drag').family, RudimentFamily.ruff);
    });

    test('non-PAS exercises have no family tag', () {
      expect(_byId('ghost_note_groove').family, isNull);
      expect(_byId('linear_beat_1').family, isNull);
      expect(_byId('speed_singles_basis').family, isNull);
      expect(_byId('ausdauer_dauerlauf').family, isNull);
    });

    test('paradiddles are tagged koordination + kontrolle', () {
      expect(_byId('single_paradiddle').skill,
          containsAll([Skill.koordination, Skill.kontrolle]));
    });

    test('linear patterns are tagged koordination + independence', () {
      expect(_byId('linear_beat_1').skill,
          containsAll([Skill.koordination, Skill.independence]));
    });

    test('ausdauer exercises are tagged Skill.ausdauer', () {
      expect(_byId('ausdauer_dauerlauf').skill, [Skill.ausdauer]);
    });

    test('Marching Snare entries are tagged genre drumCorps, others general',
        () {
      final marching = _byId('eight_on_a_hand');
      expect(marching.genre, Genre.drumCorps);
      expect(marching.skill, containsAll([Skill.ausdauer, Skill.kontrolle]));

      expect(_byId('single_stroke_roll').genre, Genre.general);
      expect(_byId('speed_singles_basis').genre, Genre.general);
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/lessons/rudiments_seed_tags_test.dart`
Expected: FAIL — every rudiment's `skill` is still empty (Task 1 default), so the first test fails; the family/genre assertions fail too since nothing is tagged yet.

- [ ] **Step 3: Write minimal implementation**

Create a one-off script `/tmp/retag_seed.py` (run once, not committed):

```python
import re

path = "lib/features/lessons/data/rudiments_seed.dart"
text = open(path, encoding="utf-8").read()

TAGS = {
    "Rolls": "    skill: const [Skill.kontrolle],\n    family: RudimentFamily.roll,\n",
    "Paradiddles": "    skill: const [Skill.koordination, Skill.kontrolle],\n    family: RudimentFamily.paradiddle,\n",
    "Flams": "    skill: const [Skill.kontrolle],\n    family: RudimentFamily.flam,\n",
    "Ruffs": "    skill: const [Skill.kontrolle],\n    family: RudimentFamily.ruff,\n",
    "Ghost Notes": "    skill: const [Skill.kontrolle],\n",
    "Linear Patterns": "    skill: const [Skill.koordination, Skill.independence],\n",
    "Marching Snare": "    skill: const [Skill.ausdauer, Skill.kontrolle],\n    genre: Genre.drumCorps,\n",
    "Geschwindigkeit": "    skill: const [Skill.kontrolle],\n",
    "Stockkontrolle": "    skill: const [Skill.kontrolle],\n",
    "Ausdauer": "    skill: const [Skill.ausdauer],\n",
    "Akzente": "    skill: const [Skill.kontrolle],\n",
    "Dynamik & Ghost Notes": "    skill: const [Skill.kontrolle],\n",
    "Timing & Gleichmäßigkeit": "    skill: const [Skill.kontrolle],\n",
}


def repl(m):
    cat = m.group(1)
    return m.group(0) + TAGS[cat]


new_text, n = re.subn(r"    category: '([^']+)',\n", repl, text)
assert n == 41, f"expected 41 category lines, got {n}"
open(path, "w", encoding="utf-8").write(new_text)
print("patched", n, "entries")
```

Run it: `python3 /tmp/retag_seed.py` — expected output `patched 41 entries`.

This inserts the mapped `skill`/`family`/`genre` fields directly after each entry's (unchanged) `category:` line — e.g. a `Rolls` entry goes from:

```dart
    id: 'single_stroke_roll',
    name: 'Single Stroke Roll',
    category: 'Rolls',
    description:
```

to:

```dart
    id: 'single_stroke_roll',
    name: 'Single Stroke Roll',
    category: 'Rolls',
    skill: const [Skill.kontrolle],
    family: RudimentFamily.roll,
    description:
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/lessons/rudiments_seed_tags_test.dart`
Expected: PASS, 7/7 tests green.

- [ ] **Step 5: Run the full test suite to confirm no regressions**

Run: `flutter test`
Expected: All 48 previous tests + 7 new = 55 PASS.

- [ ] **Step 6: Run static analysis**

Run: `flutter analyze`
Expected: Same 7 pre-existing warnings, 0 errors.

- [ ] **Step 7: Commit**

```bash
git add lib/features/lessons/data/rudiments_seed.dart test/lessons/rudiments_seed_tags_test.dart
git commit -m "Retag all 41 seed rudiments with skill/family/genre

Migration step 2 (docs/AUDIT.md Phase 0.5b) part 2: applies the
approved category -> {skill, family, genre} mapping table to every
seed rudiment via a scripted insert keyed on the (unchanged) category
value. category/level are left in place; removed in the next step
once no screen reads them anymore."
```

---

### Task 3: Replace category-based providers/screens with tag-based filtering

**Files:**
- Modify: `lib/features/lessons/lessons_provider.dart`
- Modify: `lib/features/lessons/lessons_screen.dart`
- Modify: `lib/features/lessons/lesson_detail_screen.dart`
- Modify: `test/notation_staff_test.dart` (remove the retired `practice plan` test group)
- Test: `test/lessons/lessons_provider_test.dart` (create)

**Interfaces:**
- Consumes: `Skill`, `Genre`, `RudimentFamily` (Task 1); `rudimentsSeedData` tags (Task 2).
- Produces: top-level function `List<Rudiment> filterRudiments(List<Rudiment> all, {RudimentFamily? family, Set<Skill> skills})` in `lib/features/lessons/lessons_provider.dart`; `typedef LessonsFilterState = ({RudimentFamily? family, Set<Skill> skills})`; `@riverpod class LessonsFilter extends _$LessonsFilter` with methods `setFamily(RudimentFamily? family)` and `toggleSkill(Skill skill)`, generating `lessonsFilterProvider`; `@riverpod List<Rudiment> filteredRudiments(...)` generating `filteredRudimentsProvider`. Removes `groupedRudimentsProvider` and `practicePlanProvider` (and the `Map<String, List<Rudiment>> groupedRudiments` function). `rudimentsProvider` and `rudimentByIdProvider` are unchanged.

**Context:** This is the point where `LessonsScreen`/`LessonDetailScreen` stop reading `category`/`level` — Task 4 can then delete those fields with no remaining consumers.

- [ ] **Step 1: Write the failing test**

Create `test/lessons/lessons_provider_test.dart`:

```dart
import 'package:drum_coach/features/lessons/lessons_provider.dart';
import 'package:drum_coach/features/lessons/models/rudiment.dart';
import 'package:flutter_test/flutter_test.dart';

Rudiment _r(String id, {RudimentFamily? family, List<Skill> skill = const []}) {
  return Rudiment(
    id: id,
    name: id,
    category: 'x',
    description: '',
    minBpm: 60,
    targetBpm: 120,
    difficulty: Difficulty.beginner,
    sticking: const [StrokeBeat(hand: Hand.right)],
    family: family,
    skill: skill,
  );
}

void main() {
  group('filterRudiments', () {
    final all = [
      _r('a', family: RudimentFamily.roll, skill: const [Skill.kontrolle]),
      _r('b', family: RudimentFamily.paradiddle, skill: const [Skill.koordination, Skill.kontrolle]),
      _r('c', skill: const [Skill.ausdauer]),
    ];

    test('with no filter, returns all rudiments sorted by name', () {
      final result = filterRudiments(all);
      expect(result.map((r) => r.id), ['a', 'b', 'c']);
    });

    test('family filter narrows to that family only', () {
      final result = filterRudiments(all, family: RudimentFamily.roll);
      expect(result.map((r) => r.id), ['a']);
    });

    test('skill filter uses OR semantics across selected skills', () {
      final result = filterRudiments(
        all,
        skills: {Skill.kontrolle, Skill.ausdauer},
      );
      expect(result.map((r) => r.id), ['a', 'b', 'c']);
    });

    test('family and skill filters combine with AND semantics', () {
      final result = filterRudiments(
        all,
        family: RudimentFamily.paradiddle,
        skills: {Skill.ausdauer},
      );
      expect(result, isEmpty);
    });

    test('empty skills set means no skill filter applied', () {
      final result = filterRudiments(all, skills: const {});
      expect(result.map((r) => r.id), ['a', 'b', 'c']);
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/lessons/lessons_provider_test.dart`
Expected: FAIL to compile — `filterRudiments` doesn't exist yet.

- [ ] **Step 3: Write minimal implementation**

Replace the full contents of `lib/features/lessons/lessons_provider.dart`:

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

/// Pure filter used by [LessonsScreen] — no widget/provider dependency, so
/// it's directly unit-testable. [family] narrows to one PAS rudiment
/// family (`null` = no family filter). [skills] narrows to rudiments
/// carrying at least one of the given skill tags (OR semantics within the
/// set; empty set = no skill filter). Family and skill filters combine
/// with AND semantics. Result is sorted by name.
List<Rudiment> filterRudiments(
  List<Rudiment> all, {
  RudimentFamily? family,
  Set<Skill> skills = const {},
}) {
  return all.where((r) {
    if (family != null && r.family != family) return false;
    if (skills.isNotEmpty && !r.skill.any(skills.contains)) return false;
    return true;
  }).toList()
    ..sort((a, b) => a.name.compareTo(b.name));
}

typedef LessonsFilterState = ({RudimentFamily? family, Set<Skill> skills});

@riverpod
class LessonsFilter extends _$LessonsFilter {
  @override
  LessonsFilterState build() => (family: null, skills: const {});

  void setFamily(RudimentFamily? family) =>
      state = (family: family, skills: state.skills);

  void toggleSkill(Skill skill) {
    final next = {...state.skills};
    if (!next.remove(skill)) next.add(skill);
    state = (family: state.family, skills: next);
  }
}

@riverpod
List<Rudiment> filteredRudiments(FilteredRudimentsRef ref) {
  final all = ref.watch(rudimentsProvider);
  final filter = ref.watch(lessonsFilterProvider);
  return filterRudiments(all, family: filter.family, skills: filter.skills);
}
```

Run codegen: `dart run build_runner build --delete-conflicting-outputs`
Expected: succeeds, regenerates `lib/features/lessons/lessons_provider.g.dart`.

Replace the full contents of `lib/features/lessons/lessons_screen.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'lessons_provider.dart';
import 'models/rudiment.dart';

class LessonsScreen extends ConsumerWidget {
  const LessonsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(lessonsFilterProvider);
    final notifier = ref.read(lessonsFilterProvider.notifier);
    final rudiments = ref.watch(filteredRudimentsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Lessons')),
      body: Column(
        children: [
          _FamilyFilterRow(
            selected: filter.family,
            onSelect: notifier.setFamily,
          ),
          _SkillFilterRow(
            selected: filter.skills,
            onToggle: notifier.toggleSkill,
          ),
          const Divider(height: 1, color: Colors.white12),
          Expanded(
            child: rudiments.isEmpty
                ? const _EmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.only(bottom: 24, top: 8),
                    itemCount: rudiments.length,
                    itemBuilder: (context, i) =>
                        _RudimentTile(rudiment: rudiments[i]),
                  ),
          ),
        ],
      ),
    );
  }
}

class _FamilyFilterRow extends StatelessWidget {
  final RudimentFamily? selected;
  final ValueChanged<RudimentFamily?> onSelect;

  const _FamilyFilterRow({required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final options = <RudimentFamily?>[null, ...RudimentFamily.values];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        children: [
          for (final option in options) ...[
            _FilterChip(
              label: option?.label ?? 'Alle',
              selected: selected == option,
              onTap: () => onSelect(option),
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }
}

class _SkillFilterRow extends StatelessWidget {
  final Set<Skill> selected;
  final ValueChanged<Skill> onToggle;

  const _SkillFilterRow({required this.selected, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Row(
        children: [
          for (final skill in Skill.values) ...[
            _FilterChip(
              label: skill.label,
              selected: selected.contains(skill),
              onTap: () => onToggle(skill),
            ),
            const SizedBox(width: 8),
          ],
        ],
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

class _EmptyState extends StatelessWidget {
  const _EmptyState();

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

In `lib/features/lessons/lesson_detail_screen.dart`, replace the `_MetaRow` class:

```dart
class _MetaRow extends StatelessWidget {
  final Rudiment rudiment;
  const _MetaRow({required this.rudiment});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _InfoChip(
          icon: Icons.speed_outlined,
          label: '${rudiment.minBpm}–${rudiment.targetBpm} BPM',
          color: Colors.white54,
        ),
        _InfoChip(
          icon: Icons.bar_chart_outlined,
          label: rudiment.difficulty.label,
          color: rudiment.difficulty.color,
        ),
        if (rudiment.family != null)
          _InfoChip(
            icon: Icons.folder_outlined,
            label: rudiment.family!.label,
            color: Colors.white38,
          ),
        for (final skill in rudiment.skill)
          _InfoChip(
            icon: Icons.local_fire_department_outlined,
            label: skill.label,
            color: Colors.white38,
          ),
        if (rudiment.genre != Genre.general)
          _InfoChip(
            icon: Icons.military_tech_outlined,
            label: rudiment.genre.label,
            color: Colors.white38,
          ),
      ],
    );
  }
}
```

In `test/notation_staff_test.dart`, delete the entire `group('practice plan', ...)` block (lines 48-77, from `group('practice plan', () {` through its matching closing `});`) — the practice-plan feature it tests was retired per the `docs/AUDIT.md` Phase 0.5 decision (`practicePlanProvider`/`exerciseCategories` no longer exist). Also remove the now-unused imports `package:drum_coach/features/lessons/lessons_provider.dart` and `package:flutter_riverpod/flutter_riverpod.dart` from the top of that file if nothing else in it uses them (check: only the deleted group used `ProviderContainer`/`practicePlanProvider`/`exerciseCategories` — the `NotationStaffWidget` group only uses `rudimentsSeedData`, so both imports become unused and must be removed to keep `flutter analyze` clean).

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/lessons/lessons_provider_test.dart`
Expected: PASS, 5/5 tests green.

- [ ] **Step 5: Run the full test suite to confirm no regressions**

Run: `flutter test`
Expected: 55 previous - 2 removed (`practice plan` group) + 5 new = 58 PASS.

- [ ] **Step 6: Run static analysis**

Run: `flutter analyze`
Expected: Same 7 pre-existing warnings, 0 errors, 0 unused-import warnings.

- [ ] **Step 7: Commit**

```bash
git add lib/features/lessons/lessons_provider.dart lib/features/lessons/lessons_provider.g.dart \
        lib/features/lessons/lessons_screen.dart lib/features/lessons/lesson_detail_screen.dart \
        test/lessons/lessons_provider_test.dart test/notation_staff_test.dart
git commit -m "Replace category-based Lessons UI with tag-based filtering

Migration step 2 (docs/AUDIT.md Phase 0.5b) part 3: groupedRudiments/
practicePlanProvider retired in favor of filterRudiments() + a
LessonsFilter notifier (family single-select + skill multi-select,
AND across axes). LessonsScreen and LessonDetailScreen rebuilt on top
of the new providers; the retired practice-plan test group in
notation_staff_test.dart is removed. category/level are no longer
read by any screen after this commit."
```

---

### Task 4: Remove the now-dead `category`/`level` fields

**Files:**
- Modify: `lib/features/lessons/models/rudiment.dart`
- Modify: `lib/features/lessons/data/rudiments_seed.dart`
- Modify: `lib/features/coaching/exercise_generator_screen.dart`
- Modify: `test/lessons/rudiment_model_test.dart`

**Interfaces:**
- Removes: `Rudiment.category`, `Rudiment.level`, the `rudimentCategories`/`exerciseCategories` top-level consts in `rudiments_seed.dart`. No new public API.

**Context:** After Task 3, no screen or provider reads `category`/`level`/`rudimentCategories`/`exerciseCategories` anymore — this task deletes them so there is exactly one organization system left (tags), completing the Phase 0.5 decision in `docs/AUDIT.md`.

- [ ] **Step 1: Confirm no remaining consumers (this task has no new failing test — it's a removal, verified by "still compiles and all tests pass" at the end)**

Run: `grep -rn "\.category\b\|\.level\b\|rudimentCategories\|exerciseCategories" lib/ test/ --include=*.dart`
Expected output: only the definition sites about to be removed:
```
lib/features/lessons/models/rudiment.dart:<N>:  final String category;
lib/features/lessons/models/rudiment.dart:<N>:  final int? level;
lib/features/lessons/models/rudiment.dart:<N>:    required this.category,
lib/features/lessons/models/rudiment.dart:<N>:    this.level,
lib/features/lessons/data/rudiments_seed.dart:<N>:    category: '...',   (x41)
lib/features/lessons/data/rudiments_seed.dart:<N>:    level: N,          (x18)
lib/features/lessons/data/rudiments_seed.dart:<N>:const exerciseCategories = [...]
lib/features/lessons/data/rudiments_seed.dart:<N>:const rudimentCategories = [...]
lib/features/coaching/exercise_generator_screen.dart:<N>:    category: '',
test/lessons/rudiment_model_test.dart:<N>:    category: 'Rolls',        (x2)
```
If anything else shows up, stop and investigate before proceeding — it means Task 3 missed a consumer.

- [ ] **Step 2: Remove the fields from `Rudiment`**

In `lib/features/lessons/models/rudiment.dart`, remove the `category` field, the `level` field, and their doc comment/constructor params:

```dart
class Rudiment {
  final String id;
  final String name;
  final String description;
  final int minBpm;
  final int targetBpm;
  final Difficulty difficulty;
  final List<StrokeBeat> sticking;

  /// Duration of one [sticking] cell. Drives note values + metronome subdivision.
  final NoteGrid gridUnit;

  /// Quarter-note beats per bar — used for barlines and beam grouping.
  final int beatsPerBar;

  final List<TechniqueSection> technique;
  final String? svgAssetPath;

  /// Origin of this exercise. Defaults to [ExerciseSource.authored] since
  /// today's seed catalog is entirely hand-notated.
  final ExerciseSource source;

  /// Presentation/playback mode. Defaults to [ExerciseVoicing.pad] since
  /// the current single-voice [NotationStaffWidget] is pad-shaped.
  final ExerciseVoicing voicing;

  /// What this exercise trains. See [Skill]. Empty by default — only the
  /// seed catalog (`rudiments_seed.dart`) is expected to populate this.
  final List<Skill> skill;

  /// Classic PAS rudiment family, if this is one. See [RudimentFamily].
  final RudimentFamily? family;

  /// Musical/stylistic context. See [Genre].
  final Genre genre;

  /// Which limbs this exercise is played with. See [Limb].
  final List<Limb> limbs;

  const Rudiment({
    required this.id,
    required this.name,
    required this.description,
    required this.minBpm,
    required this.targetBpm,
    required this.difficulty,
    required this.sticking,
    this.gridUnit = NoteGrid.eighth,
    this.beatsPerBar = 4,
    this.technique = const [],
    this.svgAssetPath,
    this.source = ExerciseSource.authored,
    this.voicing = ExerciseVoicing.pad,
    this.skill = const [],
    this.family,
    this.genre = Genre.general,
    this.limbs = const [Limb.hands],
  });
}
```

- [ ] **Step 3: Strip `category`/`level` from all seed entries and remove the category consts**

Create a one-off script `/tmp/strip_category_level.py` (run once, not committed):

```python
path = "lib/features/lessons/data/rudiments_seed.dart"
text = open(path, encoding="utf-8").read()

import re

text, n_cat = re.subn(r"    category: '[^']+',\n", "", text)
assert n_cat == 41, f"expected 41 category lines removed, got {n_cat}"

text, n_lvl = re.subn(r"    level: \d+,\n", "", text)
assert n_lvl == 18, f"expected 18 level lines removed, got {n_lvl}"

old_block = """/// Ordered list of all categories for consistent display.
/// Focus areas for the free practice exercises (\"Übungen\"), ordered as the
/// guided practice plan presents them.
const exerciseCategories = [
  'Geschwindigkeit',
  'Stockkontrolle',
  'Ausdauer',
  'Akzente',
  'Dynamik & Ghost Notes',
  'Timing & Gleichmäßigkeit',
];

const rudimentCategories = [
  'Rolls',
  'Paradiddles',
  'Flams',
  'Ruffs',
  'Ghost Notes',
  'Linear Patterns',
  'Marching Snare',
  ...exerciseCategories,
];
"""
assert old_block in text, "category consts block not found verbatim"
text = text.replace(old_block, "")

open(path, "w", encoding="utf-8").write(text)
print("stripped", n_cat, "category lines,", n_lvl, "level lines, and the consts block")
```

Run it: `python3 /tmp/strip_category_level.py` — expected output `stripped 41 category lines, 18 level lines, and the consts block`.

- [ ] **Step 4: Update the two remaining call sites**

In `lib/features/coaching/exercise_generator_screen.dart`, remove the `category: '',` line from `buildGeneratedRudiment`:

```dart
Rudiment buildGeneratedRudiment(List<StrokeBeat> pattern) {
  return Rudiment(
    id: 'generated',
    name: 'Generated',
    description: '',
    minBpm: 80,
    targetBpm: 120,
    difficulty: Difficulty.beginner,
    sticking: pattern,
    gridUnit: NoteGrid.eighth,
    beatsPerBar: 4,
    source: ExerciseSource.generated,
  );
}
```

In `test/lessons/rudiment_model_test.dart`, remove the two `category: 'Rolls',` lines (in `_makeRudiment` and in the `'defaults to no skill...'`-adjacent `'defaults to authored + pad...'` test's inline `Rudiment(...)`).

- [ ] **Step 5: Run the full test suite**

Run: `flutter test`
Expected: All 58 tests still PASS (this task removes fields, not behavior — no test asserted on `category`/`level` anymore after Task 3).

- [ ] **Step 6: Run static analysis**

Run: `flutter analyze`
Expected: Same 7 pre-existing warnings, 0 errors.

- [ ] **Step 7: Commit**

```bash
git add lib/features/lessons/models/rudiment.dart lib/features/lessons/data/rudiments_seed.dart \
        lib/features/coaching/exercise_generator_screen.dart test/lessons/rudiment_model_test.dart
git commit -m "Remove legacy category/level fields from Rudiment

Migration step 2 (docs/AUDIT.md Phase 0.5b) part 4, final: category
and level are fully replaced by skill/family/genre (Tasks 1-3) with
no remaining consumers (verified by grep before removal). Completes
the Phase 0.5 decision: exactly one organization system (tags) left,
no parallel category-based system alongside it."
```

---

## Self-Review

**Spec coverage:** Covers all four "Offen zur Freigabe" points from `docs/AUDIT.md` Phase 0.5b (simplifications confirmed via the earlier approved proposal; `family` axis addition; the 13-row mapping table applied verbatim in Task 2's script; UI rebuilt in Task 3 per Uli's "UI jetzt mit umbauen" answer). Does not cover the deferred `RudimentProgress`/`PracticeSession` FK rename (explicitly out of scope per Global Constraints, deferred to the future `Rudiment` -> `Exercise` rename).

**Placeholder scan:** No TBD/TODO markers. Every code step has complete, runnable code; both Python scripts are complete and include assertions that fail loudly on a mismatch instead of silently patching the wrong count.

**Type consistency:** `Skill`/`Genre`/`RudimentFamily`/`Limb` defined once in Task 1, reused as-is in Tasks 2-4. `filterRudiments(List<Rudiment>, {RudimentFamily? family, Set<Skill> skills})` signature in Task 3 matches its test call sites in the same task and its use inside `filteredRudiments`. `LessonsFilterState` used consistently in `LessonsFilter.build()`/`setFamily`/`toggleSkill` and in `LessonsScreen`'s `filter.family`/`filter.skills` reads.
