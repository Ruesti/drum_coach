# Exercise source/voicing fields Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [x]`) syntax for tracking.

**Goal:** Add `source` (`generated | authored | excerpt`) and `voicing` (`pad | kit`) fields to the existing `Rudiment` model, per Migration Step 1 in `docs/AUDIT.md` — the first move toward the brief's unified `Exercise` type, done by extending `Rudiment` rather than replacing it.

**Architecture:** `Rudiment` stays the single exercise type (per `docs/AUDIT.md` §6: "erweitern statt ersetzen"). Two new enums (`ExerciseSource`, `ExerciseVoicing`) and two new `Rudiment` fields are added with defaults that match the current reality with zero data migration: `source: ExerciseSource.authored` (today's ~46 seed rudiments are all hand-authored) and `voicing: ExerciseVoicing.pad` (today's single-voice `NotationStaffWidget` is already pad-shaped, per `docs/AUDIT.md` §5g). The one place that already synthesizes an exercise programmatically — the Phase 8 AI free-text generator — is updated to tag its output `source: ExerciseSource.generated`, giving the new field real, observable meaning instead of being inert scaffolding.

**Tech Stack:** Dart 3 (null-safe), Flutter, `flutter_test` for unit tests.

## Global Constraints

- Extend existing code, don't rewrite it (brief: "Bestehenden Code respektieren: erweitern statt neu schreiben, wo möglich").
- No new dependencies (brief: "Keine stillen Abhängigkeiten auf schwergewichtige Bibliotheken ohne Rückfrage") — this plan adds zero packages.
- Every step individually functional and testable (brief: "Jeder Schritt einzeln lauffähig und abnehmbar").
- Do not touch `category`, tag axes, `practicePlanProvider`, `rudimentId` FK naming, or any renderer code in this plan — those are later migration steps (`docs/AUDIT.md` §6, steps 2–3) and out of scope here.
- Existing test suite (`flutter test`) must stay green throughout.

---

### Task 1: Add `ExerciseSource`/`ExerciseVoicing` enums and fields to `Rudiment`

**Files:**
- Modify: `lib/features/lessons/models/rudiment.dart`
- Test: `test/lessons/rudiment_model_test.dart` (create)

**Interfaces:**
- Produces: `enum ExerciseSource { generated, authored, excerpt }`, `enum ExerciseVoicing { pad, kit }`, `Rudiment.source` (`ExerciseSource`, defaults to `ExerciseSource.authored`), `Rudiment.voicing` (`ExerciseVoicing`, defaults to `ExerciseVoicing.pad`) — both new named constructor params on the existing `Rudiment` class at `lib/features/lessons/models/rudiment.dart:63-101`.

- [x] **Step 1: Write the failing test**

Create `test/lessons/rudiment_model_test.dart`:

```dart
import 'package:drum_coach/features/lessons/models/rudiment.dart';
import 'package:flutter_test/flutter_test.dart';

Rudiment _makeRudiment({ExerciseSource? source, ExerciseVoicing? voicing}) {
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
}
```

- [x] **Step 2: Run test to verify it fails**

Run: `flutter test test/lessons/rudiment_model_test.dart`
Expected: FAIL to compile — `ExerciseSource`, `ExerciseVoicing`, the `source` and `voicing` named parameters don't exist yet on `Rudiment`.

- [x] **Step 3: Write minimal implementation**

In `lib/features/lessons/models/rudiment.dart`, add the two enums after the existing `Difficulty` enum (after line 27, before the `StrokeBeat` class doc comment on line 29):

```dart
/// Where an exercise came from. `generated` = built from the sticking
/// grammar at runtime; `authored` = hand-notated (today's seed data);
/// `excerpt` = a pointer into an imported score (bar range, not a copy).
enum ExerciseSource { generated, authored, excerpt }

/// Which renderer/playback mode an exercise targets. `pad` = single-line
/// sticking notation + click, fully offline (practice pad, on the go).
/// `kit` = full kit notation with per-instrument voicing and synthetic
/// drum sounds (at home).
enum ExerciseVoicing { pad, kit }
```

Then in the `Rudiment` class (`lib/features/lessons/models/rudiment.dart:63-101`), add the two fields after `level` (line 84) and the two constructor params after `this.level,` (line 99):

```dart
class Rudiment {
  final String id;
  final String name;
  final String category;
  final String description;
  final int minBpm;
  final int targetBpm;
  final Difficulty difficulty;
  final List<StrokeBeat> sticking;
  final NoteGrid gridUnit;
  final int beatsPerBar;
  final List<TechniqueSection> technique;
  final String? svgAssetPath;
  final int? level;

  /// Origin of this exercise. Defaults to [ExerciseSource.authored] since
  /// today's seed catalog is entirely hand-notated.
  final ExerciseSource source;

  /// Presentation/playback mode. Defaults to [ExerciseVoicing.pad] since
  /// the current single-voice [NotationStaffWidget] is pad-shaped.
  final ExerciseVoicing voicing;

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
  });
}
```

- [x] **Step 4: Run test to verify it passes**

Run: `flutter test test/lessons/rudiment_model_test.dart`
Expected: PASS, 4/4 tests green.

- [x] **Step 5: Run the full test suite to confirm no regressions**

Run: `flutter test`
Expected: All existing tests (20 previously + 4 new = 24) PASS. The 46 seed rudiments in `rudiments_seed.dart` use named-parameter construction with no `source`/`voicing` args, so they compile unchanged and pick up the new defaults.

- [x] **Step 6: Commit**

```bash
git add lib/features/lessons/models/rudiment.dart test/lessons/rudiment_model_test.dart
git commit -m "Add ExerciseSource/ExerciseVoicing fields to Rudiment

Migration step 1 from docs/AUDIT.md: extend the existing Rudiment
model with source (generated/authored/excerpt) and voicing (pad/kit)
instead of introducing a parallel Exercise type. Defaults match
today's reality (authored, pad) so the 46 seed rudiments need no
changes."
```

---

### Task 2: Tag the AI-generated exercise with `source: ExerciseSource.generated`

**Files:**
- Modify: `lib/features/coaching/exercise_generator_screen.dart:149-161`
- Test: `test/coaching/exercise_generator_rudiment_test.dart` (create)

**Interfaces:**
- Consumes: `Rudiment`, `ExerciseSource` from Task 1 (`lib/features/lessons/models/rudiment.dart`); `StrokeBeat`, `Hand`, `Difficulty`, `NoteGrid` (already imported in `exercise_generator_screen.dart`).
- Produces: top-level function `Rudiment buildGeneratedRudiment(List<StrokeBeat> pattern)` in `lib/features/coaching/exercise_generator_screen.dart`, usable standalone in tests without pumping the widget or mocking `AICoachingService`'s network call.

**Context:** `docs/AUDIT.md` §5h / Phase 0.5 decision: the Phase 8 AI free-text generator (`exercise_generator_screen.dart` + `AICoachingService.generateExercise`) stays as a separate, complementary generator alongside the future grammar-based one — both produce the same `Rudiment`/score output. This task makes that origin explicit in the data instead of implicit in "which screen built it."

- [x] **Step 1: Write the failing test**

Create `test/coaching/exercise_generator_rudiment_test.dart`:

```dart
import 'package:drum_coach/features/coaching/exercise_generator_screen.dart';
import 'package:drum_coach/features/lessons/models/rudiment.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('buildGeneratedRudiment', () {
    test('tags the result as ExerciseSource.generated', () {
      const pattern = [
        StrokeBeat(hand: Hand.right, isAccent: true),
        StrokeBeat(hand: Hand.left),
      ];
      final rudiment = buildGeneratedRudiment(pattern);
      expect(rudiment.source, ExerciseSource.generated);
    });

    test('carries the given pattern through as sticking', () {
      const pattern = [
        StrokeBeat(hand: Hand.right),
        StrokeBeat(hand: Hand.left),
        StrokeBeat(hand: Hand.right),
      ];
      final rudiment = buildGeneratedRudiment(pattern);
      expect(rudiment.sticking, pattern);
    });
  });
}
```

- [x] **Step 2: Run test to verify it fails**

Run: `flutter test test/coaching/exercise_generator_rudiment_test.dart`
Expected: FAIL to compile — `buildGeneratedRudiment` doesn't exist yet in `exercise_generator_screen.dart`.

- [x] **Step 3: Write minimal implementation**

In `lib/features/coaching/exercise_generator_screen.dart`, add a top-level function (place it near the top of the file, after the imports and before the first class/widget declaration):

```dart
/// Builds the [Rudiment] shown for a freshly AI-generated sticking
/// [pattern]. Extracted from the widget so it's unit-testable without
/// pumping the screen or mocking the network call.
Rudiment buildGeneratedRudiment(List<StrokeBeat> pattern) {
  return Rudiment(
    id: 'generated',
    name: 'Generated',
    category: '',
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

Then replace the inline construction at `lib/features/coaching/exercise_generator_screen.dart:149-161`:

```dart
                    child: NotationStaffWidget(
                      rudiment: Rudiment(
                        id: 'generated',
                        name: 'Generated',
                        category: '',
                        description: '',
                        minBpm: 80,
                        targetBpm: 120,
                        difficulty: Difficulty.beginner,
                        sticking: _pattern!,
                        gridUnit: NoteGrid.eighth,
                        beatsPerBar: 4,
                      ),
                    ),
```

with:

```dart
                    child: NotationStaffWidget(
                      rudiment: buildGeneratedRudiment(_pattern!),
                    ),
```

- [x] **Step 4: Run test to verify it passes**

Run: `flutter test test/coaching/exercise_generator_rudiment_test.dart`
Expected: PASS, 2/2 tests green.

- [x] **Step 5: Run the full test suite to confirm no regressions**

Run: `flutter test`
Expected: All tests (24 previously + 2 new = 26) PASS.

- [x] **Step 6: Run static analysis**

Run: `flutter analyze`
Expected: Same 5 pre-existing warnings as documented in `docs/AUDIT.md` (unrelated `buildQuery` experimental-API usage), zero new issues.

- [x] **Step 7: Commit**

```bash
git add lib/features/coaching/exercise_generator_screen.dart test/coaching/exercise_generator_rudiment_test.dart
git commit -m "Tag AI-generated exercises with ExerciseSource.generated

Extracts the ad-hoc Rudiment construction in the Phase 8 AI exercise
generator into a standalone buildGeneratedRudiment() function and
marks its output source: ExerciseSource.generated, per the Phase 0.5
decision in docs/AUDIT.md to keep this generator complementary to the
planned grammar-based one rather than superseding it."
```

---

## Self-Review

**Spec coverage:** Covers `docs/AUDIT.md` §6 Step 1's "Exercise-Typ vereinheitlichen ... source/voicing ergänzen" for the `source`/`voicing` fields themselves. Explicitly does **not** cover the `RudimentProgress`/`PracticeSession` FK rename mentioned in the same audit step — deferred because the ID values already stay stable without a Dart field rename (audit: "Risiko: niedrig-mittel — keine Schema-Migration nötig, wenn IDs ... stabil bleiben"), and bundling a ~15-callsite mechanical rename into this plan would blow past a single reviewable task. That rename belongs with the later step that actually renames `Rudiment` → `Exercise` (docs/AUDIT.md §6 step "Kit-mode..." range), where the FK name will need to change anyway for consistency — flag this explicitly when planning that step.

**Placeholder scan:** No TBD/TODO markers; every step has complete, runnable code.

**Type consistency:** `ExerciseSource`/`ExerciseVoicing` defined once in Task 1, imported and reused as-is in Task 2 (`ExerciseSource.generated`). `buildGeneratedRudiment(List<StrokeBeat> pattern)` signature matches both its Task 2 test call sites and its use inside the widget (`_pattern!` is already `List<StrokeBeat>` per the existing code at line 157).
