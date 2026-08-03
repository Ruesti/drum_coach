# DrumCoach – Claude Code Context

## Project Overview
Android app for training and improving drum rudiments on a practice pad.
Flutter, Android-first. iOS support may follow later.

## Core Features
1. **Metronome** – BPM slider, tap tempo, subdivisions, accent patterns, visual beat indicator
2. **Lessons Library** – Drum rudiments with descriptions, difficulty, target BPM range, embedded metronome
3. **Practice Session Tracking** – Log duration + BPM per session, stored locally
4. **Stats & Progress** – Daily practice time, BPM progress per rudiment, streak calendar
5. **Learning System** – BPM Progression + Spaced Repetition + Daily Routine Generator (see below)

## Tech Stack
| Concern | Package |
|---|---|
| State management | `riverpod` (with `@riverpod` codegen) |
| Navigation | `go_router` |
| Local storage | `isar` (offline-first, no auth required yet) |
| Audio (metronome) | `flutter_soloud` (low-latency, avoids drift) |
| Charts | `fl_chart` |
| UI | Material 3, dark theme |

> **No backend / auth yet.** Supabase may be added later for cloud sync.
> When adding Supabase, follow the same pattern used in FocusPilot.

## Folder Structure
```
lib/
├── main.dart
├── app/
│   ├── router.dart          # go_router route definitions
│   └── theme.dart           # Material 3 dark theme
├── features/
│   ├── metronome/
│   │   ├── metronome_screen.dart
│   │   ├── metronome_provider.dart
│   │   └── widgets/
│   ├── lessons/
│   │   ├── lessons_screen.dart
│   │   ├── lesson_detail_screen.dart
│   │   ├── lessons_provider.dart
│   │   └── data/rudiments_seed.dart
│   ├── practice/
│   │   ├── practice_session_screen.dart
│   │   └── practice_provider.dart
│   ├── stats/
│   │   ├── stats_screen.dart
│   │   └── stats_provider.dart
│   ├── learning/
│   │   ├── daily_routine_screen.dart
│   │   ├── routine_provider.dart         # generates today's plan
│   │   ├── spaced_repetition_service.dart
│   │   └── bpm_progression_service.dart
│   └── dashboard/
│       └── dashboard_screen.dart
├── shared/
│   ├── widgets/             # Reusable UI components
│   └── extensions/
└── data/
    ├── local/
    │   ├── isar_service.dart
    │   └── models/          # Isar @collection models
    └── remote/              # Empty for now, Supabase later
```

## Data Models

### `RudimentProgress` (Isar collection)
```dart
@collection
class RudimentProgress {
  Id id = Isar.autoIncrement;
  late String rudimentId;
  late int currentBpm;          // where the user currently practices
  late int bestBpm;             // personal best achieved
  late MasteryLevel mastery;    // enum, derived from bestBpm vs targetBpm
  late int srInterval;          // days until next review (SR)
  late int srRepetitions;       // how many successful reviews in a row
  late DateTime lastPracticed;
  late DateTime nextReviewDate;
}

enum MasteryLevel { beginner, developing, competent, proficient, mastered }
// beginner   = bestBpm < 40% of targetBpm
// developing = 40–65%
// competent  = 65–85%
// proficient = 85–99%
// mastered   = ≥ 100%
```

### `PracticeSession` (Isar collection)
```dart
@collection
class PracticeSession {
  Id id = Isar.autoIncrement;
  late String rudimentId;   // e.g. "single_stroke_roll"
  late int durationSeconds;
  late int achievedBpm;
  late DateTime date;
}
```

### `Rudiment` (in-memory seed data, not persisted)
```dart
class Rudiment {
  final String id;
  final String name;
  final String description;
  final int minBpm;
  final int targetBpm;
  final Difficulty difficulty;
  final List<StrokeBeat> sticking;   // R/L pattern definition
  final String? svgAssetPath;
  final Set<Skill> skills;           // tag axis, see below
  final Set<Genre> genres;           // tag axis, see below
  final Set<Limb> limbs;             // tag axis, see below
}

class StrokeBeat {
  final Hand hand;       // enum: right, left
  final bool isAccent;   // shown as ● above the beat
  final bool isGhost;    // shown smaller and dimmed
}

enum Hand { right, left }

// Example – Single Paradiddle:
// [R●, L, R, R, L●, R, L, L]
// R● = StrokeBeat(hand: right, isAccent: true)
```

## Rudiment Tag Axes & Seed Data
Rudiments are no longer organized in a single category tree — a rudiment can
carry multiple tags across independent axes (see
`docs/superpowers/specs/2026-07-28-category-to-tag-axes-design.md`):
- **Skill**: control, coordination, endurance, groove, fill, independence
- **Genre**: rock, funk, jazz, latin, metal, drumCorps
- **Gliedmaßen (Limb)**: hands, feet, doubleBass, allFour
- **Subdivision**: derived from `gridUnit` (`NoteGrid`), not a separate field

The Lessons screen filters by these axes (OR within an axis, AND across
axes) instead of grouping by category.

### `PracticeSession` (Isar collection)
```dart
@collection
class PracticeSession {
  Id id = Isar.autoIncrement;
  late String rudimentId;
  late int durationSeconds;
  late int achievedBpm;
  late int rating;          // 1 = struggled, 2 = ok, 3 = solid (user input)
  late DateTime date;
}
```

## Learning System

### BPM Progression
- After each session the user rates themselves: **1 Struggled / 2 OK / 3 Solid**
- `bpm_progression_service.dart` calculates the next suggested BPM:
  - Rating 3 (Solid) → +5 BPM
  - Rating 2 (OK)    → +2 BPM
  - Rating 1 (Struggled) → stay at current BPM
- Never exceed the rudiment's `targetBpm`; mark as **Mastered** when reached
- Update `RudimentProgress.currentBpm` and `bestBpm` after every session

### Spaced Repetition (simplified SM-2)
Implemented in `spaced_repetition_service.dart`:

```
Rating 1 (Struggled) → interval = 1 day,  repetitions reset to 0
Rating 2 (OK)        → interval = max(1, previous interval)
Rating 3 (Solid)     → repetitions++
                        interval: 1 → 3 → 7 → 14 → 30 → 60 days
```

- Update `RudimentProgress.srInterval`, `srRepetitions`, `nextReviewDate` after session
- A rudiment is **due for review** when `nextReviewDate <= today`

### Daily Routine Generator
`routine_provider.dart` generates today's plan at app launch:

**Selection algorithm (in priority order):**
1. All rudiments with `nextReviewDate <= today` (overdue reviews first)
2. Active rudiments (started but not mastered, not yet due for review)
3. 1 new rudiment (lowest difficulty not yet started), if total time < target

**Time budgeting:**
- Default target: 20–30 min (user can set in settings)
- Each rudiment slot: 5–8 min depending on difficulty
- Cap at 5 rudiments per day to avoid overwhelm

**Output – `DailyRoutine` model:**
```dart
class DailyRoutineItem {
  final String rudimentId;
  final RoutineItemType type;   // enum: review, progression, newRudiment
  final int suggestedBpm;
  final int suggestedDurationMinutes;
}
```

### Navigation additions
```
/routine              → DailyRoutineScreen   (today's plan)
/routine/:rudimentId  → PracticeSessionScreen (from routine context)
```

### Dashboard shows
- Today's routine summary (X rudiments, ~Y min)
- How many are reviews vs progression vs new
- Tap to go to `/routine`

## Sticking Pattern Widget

Reusable widget used in **LessonDetailScreen** and **PracticeSessionScreen**.

### Visual design
```
 ●              ●
 R   L   R   R   L   R   L   L
         ↑
  (current beat, highlighted)
```
- Each beat = a rounded box with **R** or **L** label
- Accent (●) = small dot rendered above the box
- Ghost note = same box but 60% opacity and smaller font
- Active beat = amber/orange highlight + subtle scale animation (1.0 → 1.15)
- Inactive beats = muted foreground color

### Behavior
- Receives `currentBeatIndex` from the metronome provider (stream)
- Scrolls horizontally if pattern exceeds screen width (e.g. 16-beat patterns)
- Tapping a beat has no action – display only
- Works in both static mode (lesson view, no animation) and live mode (practice, animated)

### Implementation
```
shared/widgets/sticking_pattern_widget.dart
```

Props:
```dart
StickingPatternWidget({
  required List<StrokeBeat> pattern,
  int? activeBeatIndex,     // null = static display
  double beatBoxSize = 48,
})
```

## Metronome Implementation Rules
- Use `flutter_soloud` – **never** `just_audio` or `audioplayers` for the metronome (latency issues)
- Run the tick logic in an **Isolate** or via a platform timer to avoid UI jank
- Supported subdivisions: quarter, eighth, triplet, sixteenth
- BPM range: 40–240
- Tap Tempo: average of last 4 taps, reset after 3s of inactivity
- Visual beat indicator must sync with audio, not with UI frame rate

## UI & Theme Guidelines
- **Dark theme only** – optimized for low-light practice environments
- Primary color: deep orange / amber accent (energy, drumming feel)
- Keep screens uncluttered – large touch targets (practice pad users have sticks in hand)
- Bottom navigation: Dashboard | Lessons | Metronome | Stats
- Metronome screen: BPM front and center, large and readable from a distance

## State Management Conventions
- Use `@riverpod` codegen for all providers
- Run `dart run build_runner watch` during development
- Providers live in their feature folder (`features/x/x_provider.dart`)
- Never put business logic in widgets

## Navigation (go_router)
```
/                       → DashboardScreen
/routine                → DailyRoutineScreen
/routine/:rudimentId    → PracticeSessionScreen (routine context)
/lessons                → LessonsScreen
/lessons/:id            → LessonDetailScreen
/practice/:rudimentId   → PracticeSessionScreen (free practice)
/metronome              → MetronomeScreen
/stats                  → StatsScreen
```

Bottom navigation: **Dashboard | Routine | Lessons | Stats**

## Code Style
- Dart 3, null-safe, use `sealed class` / pattern matching where appropriate
- No `setState` outside of truly local ephemeral UI state
- Prefer named constructors and factory methods for models
- All strings in English (UI may be localized later via `flutter_localizations`)

## Known Constraints
- Audio timing is critical – any metronome regression must be caught immediately
- App must work fully offline – never block UI waiting for network
- Isar DB initialization must complete before `runApp()`

## Future Roadmap (do not implement yet)
- Supabase cloud sync for sessions and progress
- Microphone analysis (tap detection, tempo tracking)
- Custom routine builder (user defines their own sequence)
- Adjustable daily practice target duration (currently hardcoded 20–30 min)
- iOS support
