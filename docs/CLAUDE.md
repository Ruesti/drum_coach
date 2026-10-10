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
│   └── today/                        # start screen (K2): path step + library door
│       ├── today_screen.dart
│       ├── next_step.dart            # pure: first open program block / routine item
│       └── next_step_provider.dart
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

### Sheets (Blattform, 2026-09-30)
- An exercise is a **sheet** of numbered lines: `Rudiment.lines`
  (`ExerciseLine(beats, {repeat, title, counts})`, each 1–8 whole bars);
  `Rudiment.sheet` never is empty — legacy exercises are one-line sheets
  made of their plain `sticking`. A sheet stays ≤ 64 bars
  (`maxBackingCycleBars`; integrity test). Author lines with the étude DSL
  (`line(...)`), e.g. `data/sheets/single_paradiddle_sheet.dart`.
- `SheetPlan` (`models/sheet_plan.dart`, pure) turns the sheet into the
  **unit** the practice screen plays: one line or the whole sheet (each
  line once), a flat note list plus `locate(noteIndex)` for the cursor.
  `Rudiment.withSticking(unit.beats)` hands that unit to playback, backing
  choice and analysis as an ordinary exercise — engine and analysis know
  nothing about lines.
- Notation: `SheetStaffWidget` (one `CustomPaint` per line, uniform row
  pitch from `computeSheetGeometry`) draws number boxes, `|: :|`, a final
  barline, titles above and count syllables (`countLabelsFor`) below;
  letters/numbers/counts use the label font (IBM Plex Mono).
  `NotationStaffWidget` stays the plain one-line box for the pattern.
- Practice screen: `SheetWindow` shows up to four rows, the played row
  always on top, slides up one row at every row boundary (180 ms), jumps
  on loop restart and line changes; sheet mode wraps the preview. Line bar
  `‹ Line n / m ›` + `Line | Sheet` on multi-line sheets; `?line=` (1-based)
  and `?mode=line|sheet` route params; position remembered per exercise
  (`SettingsService.sheetPositionFor`); switches "Sticking letters" /
  "Count hints" in the ⋯ sheet. `SessionLog.sheetLine/sheetMode` record it.
- The lesson text (`technique` sections: Why it matters / How to play it /
  Practice tips / Song examples) appears only on the Library info page
  (PATTERN · THE SHEET · LESSON) and behind "About this exercise" — never on
  the practice screen (Uli, 30.09.: "Lektion nur auf Abruf, als Übung nur
  Noten"). Catalog rule: every exercise as varied and groovy as possible.
- Catalog content (Katalog 3a, 2026-10): the twelve rudiment sheets live
  ONCE in `tool/katalog/rudimente.py` (small token notation, see
  `tool/katalog/README.md`); `gen_dart.py` writes
  `data/sheets/<id>_sheet.dart` (pattern, lines, lesson) and
  `patch_seed.py` wires them into `rudiments_seed.dart`. Never edit the
  generated sheet files by hand. Five/seven stroke roll and Swiss army
  triplet are base rudiments since then.
- Katalog 3b (2026-10-10): the eight fill-sticking sheets live in
  `tool/katalog/fills.py` (ids `fill_*`; 8 lines of four bars = three bars
  of single-voice time + one bar of fill, Challenge 8 bars = 40 bars; the
  first note of every line is accented — the one after the fill, Brief
  §3.2). `blatt.py` holds the `Sheet` class (`line_bars`, `backing`,
  `grid`), `katalog.py` the registry of sets; every generator takes an
  optional set name. The band is per exercise ("one sheet, one feel"): the
  sextuplet sheet sets `backing: 'rock8'` explicitly, the triplet sheet
  lives in the shuffle, paradiddle and six-note groups are funk.

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

### Navigation (K2, 2026-09)
```
Bottom nav: /  Today  ·  /library  Library  ·  /progress  Progress
/routine              → DailyRoutineScreen   (top-level, no tab anymore)
/routine/:rudimentId  → PracticeSessionScreen (from routine context)
/lessons, /lessons/:id, /stats → redirect to /library, /library/:id, /progress
```

### Today shows
- A random portrait photo (`nextBackdrop()`, the practice pool) filling the
  whole screen; "TODAY" and the greeting in white on it, the doors on paper
  below a fade (29.09.). Status bar icons light.
- "Continue the path": the next step — first open block of today's program
  day, or the first routine item without a program — with one Start button
- "Practice freely": one button into the Library
- Streak and minutes today, compact
- Library: borderless photo header (a third of the screen, title on it),
  filters and list below. Progress: dark (`drumCoachPracticeTheme`), the
  bottom bar follows that tab (`_ScaffoldWithNavBar`).

### Theme (K2)
- App is light ("paper", `AppColors`); `PracticeSessionScreen` and (since
  29.09.) `StatsScreen` are dark (`PracticeColors`, wrapped in
  `drumCoachPracticeTheme`). Shared widgets
  read `AppPalette.of(context)`. Fonts are bundled under `assets/google_fonts/`
  — never rely on runtime fetching (tests would break).
- `PracticeSessionScreen` (K2 step 2): no AppBar — header row (back, name,
  context line from `?ctx=`, mode chip), the sheet window (`SheetWindow`,
  up to four rows, the played row on top; line bar below it on multi-line
  sheets), the `PulseBar`
  (running marker + volume pulses; the click track is a second voice in the
  loop, off in analysis mode), `TempoRow` (±4 BPM, tap the number for exact
  entry), one primary button Start/Stop/Resume with the time, Finish on its
  own row while paused, options (duration, sound, backing on/off + level —
  the style is automatic, `autoBackingStyle`, click track, about) behind
  "⋯". Backdrop photo: random from `practiceBackdrops` (`backdrop.dart`, the
  36 portrait photos in `assets/illustrations/practice/`) on every open,
  never the previous one; scrim 15/40/85 % while configuring,
  30/60/88 % once started; the notation sheet is 60 % translucent until the
  session starts, then solid (`AnimatedOpacity`).
- Result (K2 step 3): one light `ResultSheet` after the session — verdict
  banner, rating chips (save on tap, once), three plain-language `coreValues`
  (hits, timing, hands/evenness), details folded, Done. Ladder dialog and
  coach feedback arrive via `ValueNotifier`s after the rating.

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
- Loop rendering (Engine part 1): `buildLoopPlan` (`loop_voices.dart`) turns
  pattern, click track and a `BackingStyle` (kick + hi-hat, `backing_styles.dart`,
  synthesised in `backing_sounds.dart`) into `LoopVoice`s over one cycle of
  `lcm(pattern, bar)` ticks; `buildLoopWav` mixes them with a soft limiter
  (knee 0.8, ceiling 0.98). Backing only on the 24-tick pattern clock.
  Analysis-mode rule: click track and backing sound only with headphones
  (the mic would hear them); the practice screen re-checks on the
  metronome's `audioRouteChanges`. Sound gate:
  `dart run tool/render_backing_demo.dart <dir>` renders every style.
- Measurement takes main-note onsets only (`PatternPlayback.isOnsetTick`);
  grace ticks (flam/drag) sound but are not expected strokes.

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
