# Desktop-UX (P4) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Give DrumCoach a real desktop layout on Windows/macOS/Linux — a left NavigationRail, a three-zone practice screen (Info | Notation | Controls), full keyboard shortcuts and mouse affordances — while leaving the mobile UI untouched.

**Architecture:** Platform-gated presentation only. A single gate `isDesktopPlatform` (from P1, `lib/app/platform_support.dart`) selects between a mobile branch (unchanged) and a desktop branch at two seams: the app shell (bottom-nav vs. NavigationRail) and the practice screen (vertical stack vs. three-zone Row). Shared practice sub-widgets are extracted into pure, provider-free widgets so both layouts reuse them and both are widget-testable headless. No changes to metronome timing, providers, or data models.

**Tech Stack:** Flutter 3.44 (stable), Dart 3, Riverpod, go_router, `window_manager` (new, desktop-only).

## Global Constraints

- Flutter stable 3.44.x; Dart 3.
- Desktop gate is `isDesktopPlatform` from `lib/app/platform_support.dart`; tests flip it via `debugIsDesktopOverride` (set in `setUp`, reset to `null` in `tearDown`).
- **Platform-gated, NOT width-adaptive.** Never switch layout on `MediaQuery` width.
- Mobile layout, behavior, and the 560px content cap (`AppLayout.maxContentWidth`) stay **exactly** as today.
- No changes to metronome timing, audio, providers, or data models — presentation layer only.
- Minimum desktop window size: **900×600**.
- Practice screen zone widths (desktop): Info flex **22**, Notation flex **53**, Controls flex **25**.
- Keyboard shortcuts (desktop practice only): `Space`=toggle, `↑`/`+`=BPM+1 (Shift +5), `↓`/`-`=BPM−1 (Shift −5) clamped 40–240, `1`/`2`/`3`=rate, `←`/`→`=prev/next exercise (no-op when no exercise list is supplied), `Esc`=exit.
- No AI coaching on desktop (stays hidden per P1); desktop rating must NOT open the AI `_FeedbackSheet`.
- Enum display uses existing `.label` getters: `Difficulty.label`, `Skill.label`, `Limb.label`.

---

### Task 1: Minimum desktop window size

**Files:**
- Create: `lib/app/window_setup.dart`
- Modify: `lib/main.dart:11-18` (the `main()` body)
- Modify: `pubspec.yaml` (add `window_manager`)
- Test: `test/app/window_setup_test.dart`

**Interfaces:**
- Consumes: `isDesktopPlatform`, `debugIsDesktopOverride` from `lib/app/platform_support.dart`.
- Produces: `Future<void> applyDesktopWindowSetup()` — on desktop sets a 900×600 minimum window size; on mobile/web it is a no-op that returns without touching `window_manager`.

- [ ] **Step 1: Add the dependency**

Run: `flutter pub add window_manager`
Expected: `pubspec.yaml` gains `window_manager:` under dependencies; `flutter pub get` succeeds.

- [ ] **Step 2: Write the failing test**

```dart
// test/app/window_setup_test.dart
import 'package:drum_coach/app/platform_support.dart';
import 'package:drum_coach/app/window_setup.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // No plugin handlers are registered, so any real window_manager call would
  // throw MissingPluginException. On non-desktop the function must not call it.
  TestWidgetsFlutterBinding.ensureInitialized();
  tearDown(() => debugIsDesktopOverride = null);

  test('applyDesktopWindowSetup is a no-op on non-desktop', () {
    debugIsDesktopOverride = false;
    expect(applyDesktopWindowSetup(), completes);
  });
}
```

- [ ] **Step 3: Run test to verify it fails**

Run: `flutter test test/app/window_setup_test.dart`
Expected: FAIL — `Error: Not found: package:drum_coach/app/window_setup.dart`.

- [ ] **Step 4: Write minimal implementation**

```dart
// lib/app/window_setup.dart
import 'package:flutter/widgets.dart';
import 'package:window_manager/window_manager.dart';

import 'platform_support.dart';

/// On desktop, constrain the window so the sidebar + content never crush.
/// No-op on mobile/web (never touches window_manager there).
Future<void> applyDesktopWindowSetup() async {
  if (!isDesktopPlatform) return;
  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();
  await windowManager.setMinimumSize(const Size(900, 600));
}
```

- [ ] **Step 5: Run test to verify it passes**

Run: `flutter test test/app/window_setup_test.dart`
Expected: PASS (1 test).

- [ ] **Step 6: Wire into main()**

In `lib/main.dart`, add the import and call it after `WidgetsFlutterBinding.ensureInitialized()` and before `runApp`. The body becomes:

```dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await applyDesktopWindowSetup();
  await Future.wait([
    SoLoud.instance.init(),
    IsarService.init(),
    SettingsService.init(),
  ]);
  await NotificationService.init();
  runApp(
    const ProviderScope(
      child: DrumCoachApp(),
    ),
  );
}
```

Add near the other imports:

```dart
import 'app/window_setup.dart';
```

- [ ] **Step 7: Analyze + full suite**

Run: `flutter analyze --no-fatal-warnings && flutter test`
Expected: no analyzer errors (the 8 pre-existing Isar `experimental_member_use` warnings are the accepted baseline); all tests green.

- [ ] **Step 8: Commit**

```bash
git add pubspec.yaml pubspec.lock lib/app/window_setup.dart lib/main.dart test/app/window_setup_test.dart
git commit -m "feat(desktop): minimum 900x600 window size via window_manager"
```

---

### Task 2: App shell with NavigationRail on desktop

**Files:**
- Create: `lib/app/shell.dart`
- Modify: `lib/app/router.dart:128-168` (`_ScaffoldWithNavBar`)
- Test: `test/app/app_shell_test.dart`

**Interfaces:**
- Consumes: `isDesktopPlatform`, `debugIsDesktopOverride`; `AppLayout.maxContentWidth`, `AppColors.accent` from `lib/app/design_tokens.dart`.
- Produces: `AppShell` — a `StatelessWidget` with constructor
  `AppShell({required Widget body, required int currentIndex, required ValueChanged<int> onSelectIndex, required VoidCallback onOpenSettings})`.
  Desktop: `Row[ NavigationRail, VerticalDivider, Expanded(body) ]`, no width cap, settings as the rail's trailing action. Mobile: `Scaffold` with the existing `BottomNavigationBar` and the 560px `ConstrainedBox` cap around `body`.

- [ ] **Step 1: Write the failing test**

```dart
// test/app/app_shell_test.dart
import 'package:drum_coach/app/app_shell.dart' show AppShell;
import 'package:drum_coach/app/platform_support.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _host() => MaterialApp(
      home: AppShell(
        body: const Text('BODY'),
        currentIndex: 0,
        onSelectIndex: (_) {},
        onOpenSettings: () {},
      ),
    );

void main() {
  tearDown(() => debugIsDesktopOverride = null);

  testWidgets('desktop shows NavigationRail, no BottomNavigationBar',
      (tester) async {
    debugIsDesktopOverride = true;
    await tester.pumpWidget(_host());
    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.byType(BottomNavigationBar), findsNothing);
  });

  testWidgets('mobile shows BottomNavigationBar, no NavigationRail',
      (tester) async {
    debugIsDesktopOverride = false;
    await tester.pumpWidget(_host());
    expect(find.byType(BottomNavigationBar), findsOneWidget);
    expect(find.byType(NavigationRail), findsNothing);
  });
}
```

Note the import path: the file is `lib/app/shell.dart` but the test imports `package:drum_coach/app/app_shell.dart` — **create the file at `lib/app/app_shell.dart`** (rename from the Files list; keep one consistent path). Use `lib/app/app_shell.dart` everywhere.

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/app/app_shell_test.dart`
Expected: FAIL — `app_shell.dart` not found.

- [ ] **Step 3: Write minimal implementation**

```dart
// lib/app/app_shell.dart
import 'package:flutter/material.dart';

import 'design_tokens.dart';
import 'platform_support.dart';

class _Dest {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  const _Dest(this.icon, this.activeIcon, this.label);
}

const _destinations = <_Dest>[
  _Dest(Icons.dashboard_outlined, Icons.dashboard, 'Dashboard'),
  _Dest(Icons.today_outlined, Icons.today, 'Routine'),
  _Dest(Icons.library_books_outlined, Icons.library_books, 'Lessons'),
  _Dest(Icons.bar_chart_outlined, Icons.bar_chart, 'Stats'),
];

/// Platform-gated app shell. Desktop: left NavigationRail, full-width content.
/// Mobile: unchanged BottomNavigationBar + 560px centered content cap.
class AppShell extends StatelessWidget {
  final Widget body;
  final int currentIndex;
  final ValueChanged<int> onSelectIndex;
  final VoidCallback onOpenSettings;

  const AppShell({
    super.key,
    required this.body,
    required this.currentIndex,
    required this.onSelectIndex,
    required this.onOpenSettings,
  });

  @override
  Widget build(BuildContext context) {
    if (isDesktopPlatform) return _desktop(context);
    return _mobile(context);
  }

  Widget _desktop(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: currentIndex,
            onDestinationSelected: onSelectIndex,
            labelType: NavigationRailLabelType.all,
            selectedIconTheme: const IconThemeData(color: AppColors.accent),
            selectedLabelTextStyle: const TextStyle(color: AppColors.accent),
            destinations: _destinations
                .map((d) => NavigationRailDestination(
                      icon: Icon(d.icon),
                      selectedIcon: Icon(d.activeIcon),
                      label: Text(d.label),
                    ))
                .toList(),
            trailing: Expanded(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: IconButton(
                    icon: const Icon(Icons.settings_outlined),
                    tooltip: 'Einstellungen',
                    onPressed: onOpenSettings,
                  ),
                ),
              ),
            ),
          ),
          const VerticalDivider(width: 1),
          Expanded(child: body),
        ],
      ),
    );
  }

  Widget _mobile(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints:
              const BoxConstraints(maxWidth: AppLayout.maxContentWidth),
          child: body,
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: onSelectIndex,
        items: _destinations
            .map((d) => BottomNavigationBarItem(
                  icon: Icon(d.icon),
                  activeIcon: Icon(d.activeIcon),
                  label: d.label,
                ))
            .toList(),
      ),
    );
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/app/app_shell_test.dart`
Expected: PASS (2 tests).

- [ ] **Step 5: Rewire the router to use AppShell**

In `lib/app/router.dart`, replace the whole `_ScaffoldWithNavBar` class (currently lines 128-168) with a thin adapter, and add the import. Add near the top:

```dart
import 'app_shell.dart';
```

Replace the class with:

```dart
class _ScaffoldWithNavBar extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const _ScaffoldWithNavBar({required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    return AppShell(
      body: navigationShell,
      currentIndex: navigationShell.currentIndex,
      onSelectIndex: (index) => navigationShell.goBranch(
        index,
        initialLocation: index == navigationShell.currentIndex,
      ),
      onOpenSettings: () => context.push('/settings'),
    );
  }
}
```

(The 560px cap that used to live here now lives inside `AppShell._mobile`, so behavior on mobile is identical; desktop drops the cap.)

- [ ] **Step 6: Analyze + full suite**

Run: `flutter analyze --no-fatal-warnings && flutter test`
Expected: no analyzer errors; all tests green (including the P1 content-width and existing shell-adjacent tests).

- [ ] **Step 7: Commit**

```bash
git add lib/app/app_shell.dart lib/app/router.dart test/app/app_shell_test.dart
git commit -m "feat(desktop): NavigationRail shell on desktop, bottom-nav on mobile"
```

---

### Task 3: Extract pure, reusable practice sub-widgets

**Files:**
- Create: `lib/features/practice/widgets/bpm_transport.dart`
- Create: `lib/features/practice/widgets/subdivision_selector.dart`
- Create: `lib/features/practice/widgets/timer_goal_row.dart`
- Create: `lib/features/practice/widgets/rating_selector.dart`
- Modify: `lib/features/practice/practice_session_screen.dart` (use the extracted widgets; behavior unchanged)
- Test: `test/features/practice/practice_widgets_test.dart`

**Interfaces:**
- Consumes: `AppColors`, `AppRadius`, `AppTypography` from design_tokens; `BeatIndicator` (existing, imported where `_CompactMetronome` imports it — reuse the same import); `SoundType` (existing enum with `.label` and `.values`); `AppSelectableChip` (existing).
- Produces:
  - `BpmTransport({required int bpm, required bool isPlaying, required bool isAccent, required int currentBeatIndex, required ValueChanged<int> onBpmChanged, required VoidCallback onToggle, double diameter = 64})`
  - `SubdivisionSelector({required SoundType soundType, required ValueChanged<SoundType> onChanged})`
  - `TimerGoalRow({required int? selected, required ValueChanged<int?> onSelected})`
  - `RatingSelector({required void Function(int rating) onRating})` — renders the three rating buttons (Struggled=1, OK=2, Solid=3) exactly as `_RatingSheet` does today, but WITHOUT the drag handle / "How did it feel?" header (those stay in the mobile sheet wrapper) and WITHOUT calling `Navigator.pop` (the caller decides).

- [ ] **Step 1: Write the failing test**

```dart
// test/features/practice/practice_widgets_test.dart
import 'package:drum_coach/features/practice/widgets/bpm_transport.dart';
import 'package:drum_coach/features/practice/widgets/rating_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('BpmTransport shows the BPM number', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: BpmTransport(
          bpm: 137,
          isPlaying: false,
          isAccent: false,
          currentBeatIndex: -1,
          onBpmChanged: (_) {},
          onToggle: () {},
        ),
      ),
    ));
    expect(find.text('137'), findsOneWidget);
  });

  testWidgets('RatingSelector reports 1/2/3 on tap', (tester) async {
    final taps = <int>[];
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: RatingSelector(onRating: taps.add)),
    ));
    await tester.tap(find.text('Struggled'));
    await tester.tap(find.text('OK'));
    await tester.tap(find.text('Solid'));
    expect(taps, [1, 2, 3]);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/practice/practice_widgets_test.dart`
Expected: FAIL — the new widget files don't exist.

- [ ] **Step 3: Create the extracted widgets**

Create `bpm_transport.dart` by lifting the first `Row` of `_CompactMetronome` (the `BeatIndicator` + `$bpm` text + `BPM` label + `Slider`) into a standalone widget with the interface above. Copy the exact child code from `practice_session_screen.dart:409-438`, replacing the field references with the new constructor params (`diameter` replaces the hard-coded `64`). Keep the same imports (`BeatIndicator`, `AppTypography`, `AppColors`).

Create `subdivision_selector.dart` by lifting the second `Row` of `_CompactMetronome` (`practice_session_screen.dart:440-452`) — the `SoundType.values.map(... AppSelectableChip ...)` row — into a widget with `soundType` + `onChanged`.

Create `timer_goal_row.dart` by moving `_TimerGoalRow` (`practice_session_screen.dart:343-374`) verbatim, renamed to public `TimerGoalRow`.

Create `rating_selector.dart` by moving `_RatingButton` (`practice_session_screen.dart:524-570`) verbatim into this file (make it private `_RatingButton` there) and adding a public `RatingSelector` that renders the three `_RatingButton`s from `_RatingSheet` (`practice_session_screen.dart:486-517`) but calls `onRating(1|2|3)` directly (no `Navigator.pop`):

```dart
// lib/features/practice/widgets/rating_selector.dart
import 'package:flutter/material.dart';
import '../../../app/design_tokens.dart';

class RatingSelector extends StatelessWidget {
  final void Function(int rating) onRating;
  const RatingSelector({super.key, required this.onRating});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _RatingButton(
          emoji: '😓', label: 'Struggled', subtitle: 'Keep the same BPM',
          color: AppColors.struggled, onTap: () => onRating(1),
        ),
        const SizedBox(height: 10),
        _RatingButton(
          emoji: '😐', label: 'OK', subtitle: '+2 BPM next time',
          color: AppColors.ok, onTap: () => onRating(2),
        ),
        const SizedBox(height: 10),
        _RatingButton(
          emoji: '💪', label: 'Solid', subtitle: '+5 BPM next time',
          color: AppColors.solidStreak, onTap: () => onRating(3),
        ),
      ],
    );
  }
}

// _RatingButton: moved verbatim from practice_session_screen.dart:524-570.
```

- [ ] **Step 4: Rewire the mobile screen to use the extracted widgets (no behavior change)**

In `practice_session_screen.dart`:
- Add imports for the four new widget files.
- Replace `_CompactMetronome`'s body with a composition of `BpmTransport` + `SubdivisionSelector` inside the same `Container` styling — OR keep `_CompactMetronome` as a thin wrapper that returns that Container wrapping `Column[BpmTransport(...), const SizedBox(height: 8), SubdivisionSelector(...)]`. Keep `_CompactMetronome`'s public props identical so its call site (`practice_session_screen.dart:308-317`) is unchanged.
- Replace the private `_TimerGoalRow` usages with the public `TimerGoalRow` (identical API) and delete the old private class.
- In `_RatingSheet.build`, replace the three inline `_RatingButton`s with `RatingSelector(onRating: (r) { Navigator.pop(context); onRating(r); })`. Delete the now-unused private `_RatingButton` from the screen file (it now lives in `rating_selector.dart`).

- [ ] **Step 5: Run the new + full suite**

Run: `flutter test test/features/practice/practice_widgets_test.dart && flutter analyze --no-fatal-warnings && flutter test`
Expected: new test PASS; no analyzer errors; the existing `practice_session_screen_test.dart` and all others still green (behavior unchanged).

- [ ] **Step 6: Commit**

```bash
git add lib/features/practice/widgets/ lib/features/practice/practice_session_screen.dart test/features/practice/practice_widgets_test.dart
git commit -m "refactor(practice): extract BpmTransport/Subdivision/TimerGoal/RatingSelector"
```

---

### Task 4: Desktop three-zone practice layout

**Files:**
- Create: `lib/features/practice/widgets/practice_info_panel.dart`
- Create: `lib/features/practice/widgets/practice_control_panel.dart`
- Create: `lib/features/practice/widgets/practice_desktop_body.dart`
- Modify: `lib/features/practice/practice_session_screen.dart` (gate mobile vs desktop body; add desktop save-finish)
- Test: `test/features/practice/practice_desktop_body_test.dart`

**Interfaces:**
- Consumes: `Rudiment` (fields `name`, `minBpm`, `targetBpm`, `difficulty` [`.label`,`.color`], `skills` [`Set<Skill>`, `.label`], `limbs` [`Set<Limb>`, `.label`]); `NotationStaffWidget({required Rudiment rudiment, int? activeIndex})`; `BpmTransport`, `SubdivisionSelector`, `TimerGoalRow`, `RatingSelector` from Task 3; `SoundType`; design tokens.
- Produces:
  - `PracticeInfoPanel({required Rudiment rudiment})`
  - `PracticeControlPanel({...bpm/transport/subdivision/timer/goal fields..., required bool showRating, required void Function(int) onRating})`
  - `PracticeDesktopBody({required Rudiment rudiment, required int? activeBeat, required int bpm, required bool isPlaying, required bool isAccent, required int currentBeatIndex, required SoundType soundType, required ValueChanged<int> onBpmChanged, required VoidCallback onToggle, required ValueChanged<SoundType> onSoundTypeChanged, required int? goalSeconds, required ValueChanged<int?> onGoalSelected, required String timerLabel, required bool showGoalPicker, required bool showRating, required void Function(int) onRating})` — the three-zone `Row`.

- [ ] **Step 1: Write the failing test**

```dart
// test/features/practice/practice_desktop_body_test.dart
import 'package:drum_coach/features/lessons/data/rudiments_seed.dart';
import 'package:drum_coach/features/practice/widgets/practice_desktop_body.dart';
import 'package:drum_coach/features/practice/widgets/practice_info_panel.dart';
import 'package:drum_coach/features/practice/widgets/bpm_transport.dart';
import 'package:drum_coach/features/metronome/metronome_engine.dart'
    show SoundType;
import 'package:drum_coach/shared/widgets/notation_staff_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('desktop body renders all three zones', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1200, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final rudiment = rudimentsSeedData.first;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: PracticeDesktopBody(
          rudiment: rudiment,
          activeBeat: null,
          bpm: 100,
          isPlaying: false,
          isAccent: false,
          currentBeatIndex: -1,
          soundType: SoundType.values.first,
          onBpmChanged: (_) {},
          onToggle: () {},
          onSoundTypeChanged: (_) {},
          goalSeconds: null,
          onGoalSelected: (_) {},
          timerLabel: '00:00',
          showGoalPicker: true,
          showRating: false,
          onRating: (_) {},
        ),
      ),
    ));
    expect(find.byType(PracticeInfoPanel), findsOneWidget);      // Info zone
    expect(find.byType(NotationStaffWidget), findsOneWidget);    // Notation zone
    expect(find.byType(BpmTransport), findsOneWidget);           // Controls zone
  });
}
```

(Verify the exact import path of `NotationStaffWidget`, `SoundType`, and `rudimentsSeedData` against the repo before running; adjust the `import` lines to the real paths — grep for `class NotationStaffWidget`, `enum SoundType`, `rudimentsSeedData`. Do not change the widget/type names.)

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/practice/practice_desktop_body_test.dart`
Expected: FAIL — the new widget files don't exist.

- [ ] **Step 3: Create `PracticeInfoPanel`**

```dart
// lib/features/practice/widgets/practice_info_panel.dart
import 'package:flutter/material.dart';
import '../../../app/design_tokens.dart';
import '../../lessons/models/rudiment.dart';

/// Left zone of the desktop practice screen: static exercise context.
class PracticeInfoPanel extends StatelessWidget {
  final Rudiment rudiment;
  const PracticeInfoPanel({super.key, required this.rudiment});

  @override
  Widget build(BuildContext context) {
    final tags = <String>[
      ...rudiment.skills.map((s) => s.label),
      ...rudiment.limbs.map((l) => l.label),
    ];
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(rudiment.name,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(rudiment.difficulty.label,
              style: TextStyle(color: rudiment.difficulty.color, fontSize: 13,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text('${rudiment.minBpm}–${rudiment.targetBpm} BPM',
              style: const TextStyle(color: AppColors.textMuted, fontSize: 13)),
          const SizedBox(height: 16),
          if (tags.isNotEmpty)
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: tags
                  .map((t) => Chip(label: Text(t, style: const TextStyle(fontSize: 11))))
                  .toList(),
            ),
          const SizedBox(height: 20),
          const Text('Sticking',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          const SizedBox(height: 6),
          const Text('R = rechts   L = links\n● = Akzent   gedimmt = Ghost',
              style: TextStyle(color: AppColors.textMuted, fontSize: 12,
                  height: 1.4)),
        ],
      ),
    );
  }
}
```

- [ ] **Step 4: Create `PracticeControlPanel`**

Right zone: a scrollable `Column` composing (in order) `BpmTransport`, `SubdivisionSelector`, the two timers (`timerLabel` big text + a session/goal line), the `TimerGoalRow` (only when `showGoalPicker`), and — when `showRating` — a "How did it feel?" heading + `RatingSelector(onRating: onRating)`. Full field list per the Interfaces block. Reuse the Task-3 widgets verbatim; no new behavior. Wrap in a `Container` with `color: AppColors.raised`, `borderRadius: AppRadius.card`, padding `12`.

- [ ] **Step 5: Create `PracticeDesktopBody`**

```dart
// lib/features/practice/widgets/practice_desktop_body.dart
import 'package:flutter/material.dart';
import '../../lessons/models/rudiment.dart';
import '../../metronome/metronome_engine.dart' show SoundType;
import '../../../shared/widgets/notation_staff_widget.dart';
import 'practice_info_panel.dart';
import 'practice_control_panel.dart';

class PracticeDesktopBody extends StatelessWidget {
  final Rudiment rudiment;
  final int? activeBeat;
  final int bpm;
  final bool isPlaying;
  final bool isAccent;
  final int currentBeatIndex;
  final SoundType soundType;
  final ValueChanged<int> onBpmChanged;
  final VoidCallback onToggle;
  final ValueChanged<SoundType> onSoundTypeChanged;
  final int? goalSeconds;
  final ValueChanged<int?> onGoalSelected;
  final String timerLabel;
  final bool showGoalPicker;
  final bool showRating;
  final void Function(int) onRating;

  const PracticeDesktopBody({
    super.key,
    required this.rudiment,
    required this.activeBeat,
    required this.bpm,
    required this.isPlaying,
    required this.isAccent,
    required this.currentBeatIndex,
    required this.soundType,
    required this.onBpmChanged,
    required this.onToggle,
    required this.onSoundTypeChanged,
    required this.goalSeconds,
    required this.onGoalSelected,
    required this.timerLabel,
    required this.showGoalPicker,
    required this.showRating,
    required this.onRating,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(flex: 22, child: PracticeInfoPanel(rudiment: rudiment)),
          const SizedBox(width: 16),
          Expanded(
            flex: 53,
            child: SingleChildScrollView(
              child: NotationStaffWidget(
                rudiment: rudiment,
                activeIndex: activeBeat,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 25,
            child: PracticeControlPanel(
              bpm: bpm,
              isPlaying: isPlaying,
              isAccent: isAccent,
              currentBeatIndex: currentBeatIndex,
              soundType: soundType,
              onBpmChanged: onBpmChanged,
              onToggle: onToggle,
              onSoundTypeChanged: onSoundTypeChanged,
              goalSeconds: goalSeconds,
              onGoalSelected: onGoalSelected,
              timerLabel: timerLabel,
              showGoalPicker: showGoalPicker,
              showRating: showRating,
              onRating: onRating,
            ),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 6: Gate the screen + add desktop save-finish**

In `practice_session_screen.dart`:
- Add `import '../../app/platform_support.dart';` and the three new widget imports.
- Add a desktop-only finish method that saves the session and pops WITHOUT the AI `_FeedbackSheet`:

```dart
  Future<void> _saveAndFinishDesktop(int rating) async {
    if (_sessionFinished) return;
    _sessionFinished = true;
    final rudiment = ref.read(rudimentByIdProvider(widget.rudimentId));
    final metState = ref.read(metronomeNotifierProvider);
    await ref.read(practiceNotifierProvider.notifier).saveSession(
          rudimentId: widget.rudimentId,
          durationSeconds: _elapsedSeconds,
          achievedBpm: metState.bpm,
          rating: rating,
          targetBpm: rudiment.targetBpm,
        );
    if (mounted) context.pop();
  }
```

- Add desktop rating state: a `bool _showRating = false;` field. On desktop, "Finish Session" sets `_showRating = true` and stops the metronome/ticker (reuse the stop logic from `_showRatingSheet` minus the modal); the control panel then shows the inline `RatingSelector` whose `onRating` calls `_saveAndFinishDesktop`.
- In `build`, branch the body:

```dart
      body: SafeArea(
        child: isDesktopPlatform
            ? PracticeDesktopBody(
                rudiment: rudiment,
                activeBeat: activeBeat,
                bpm: metState.bpm,
                isPlaying: metState.isPlaying,
                isAccent: metState.isAccent,
                currentBeatIndex: metState.currentBeatIndex,
                soundType: metState.soundType,
                onBpmChanged: notifier.setBpm,
                onToggle: notifier.toggle,
                onSoundTypeChanged: notifier.setSoundType,
                goalSeconds: _goalSeconds,
                onGoalSelected: (s) => setState(() => _goalSeconds = s),
                timerLabel: _timerLabel,
                showGoalPicker: !metState.isPlaying && _elapsedSeconds == 0,
                showRating: _showRating,
                onRating: _saveAndFinishDesktop,
              )
            : _mobileBody(context, rudiment, metState, notifier, activeBeat),
      ),
```

Move the current `Padding`→`Column` body (lines 295-335) into a `_mobileBody(...)` helper returning the identical tree. On desktop the "Finish Session" button lives inside `PracticeControlPanel` (add a button there that calls a passed `onFinish` → set `_showRating=true` + stop); on mobile it stays as-is calling `_showRatingSheet`.

- [ ] **Step 7: Run test to verify it passes + full suite**

Run: `flutter test test/features/practice/practice_desktop_body_test.dart && flutter analyze --no-fatal-warnings && flutter test`
Expected: PASS; no analyzer errors; existing practice/mobile tests green.

- [ ] **Step 8: Commit**

```bash
git add lib/features/practice/widgets/practice_info_panel.dart lib/features/practice/widgets/practice_control_panel.dart lib/features/practice/widgets/practice_desktop_body.dart lib/features/practice/practice_session_screen.dart test/features/practice/practice_desktop_body_test.dart
git commit -m "feat(desktop): three-zone practice layout (info | notation | controls)"
```

---

### Task 5: Keyboard shortcuts + shortcut legend

**Files:**
- Create: `lib/features/practice/widgets/practice_shortcuts.dart`
- Modify: `lib/features/practice/practice_session_screen.dart` (wrap the desktop body in shortcuts; add legend to header)
- Test: `test/features/practice/practice_shortcuts_test.dart`

**Interfaces:**
- Consumes: nothing from other tasks except the screen's own callbacks.
- Produces: `PracticeShortcuts({required Widget child, required VoidCallback onToggle, required void Function(int delta) onBpmDelta, required void Function(int rating) onRate, required VoidCallback onExit, required void Function(int dir) onAdjacentExercise})` — a `FocusableActionDetector`/`CallbackShortcuts` wrapper. `onBpmDelta` receives ±1 or ±5 (Shift), and the screen clamps to 40–240 via the notifier.

- [ ] **Step 1: Write the failing test**

```dart
// test/features/practice/practice_shortcuts_test.dart
import 'package:drum_coach/features/practice/widgets/practice_shortcuts.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Space toggles, arrows change BPM by ±1', (tester) async {
    var toggles = 0;
    final deltas = <int>[];
    await tester.pumpWidget(MaterialApp(
      home: PracticeShortcuts(
        onToggle: () => toggles++,
        onBpmDelta: deltas.add,
        onRate: (_) {},
        onExit: () {},
        onAdjacentExercise: (_) {},
        child: const Focus(autofocus: true, child: SizedBox.expand()),
      ),
    ));
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    expect(toggles, 1);
    expect(deltas, [1, -1]);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/practice/practice_shortcuts_test.dart`
Expected: FAIL — `practice_shortcuts.dart` not found.

- [ ] **Step 3: Write the implementation**

```dart
// lib/features/practice/widgets/practice_shortcuts.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Desktop keyboard shortcuts for the practice screen. Wrap the practice body.
class PracticeShortcuts extends StatelessWidget {
  final Widget child;
  final VoidCallback onToggle;
  final void Function(int delta) onBpmDelta;
  final void Function(int rating) onRate;
  final VoidCallback onExit;
  final void Function(int dir) onAdjacentExercise;

  const PracticeShortcuts({
    super.key,
    required this.child,
    required this.onToggle,
    required this.onBpmDelta,
    required this.onRate,
    required this.onExit,
    required this.onAdjacentExercise,
  });

  @override
  Widget build(BuildContext context) {
    final shift = HardwareKeyboard.instance.isShiftPressed;
    return CallbackShortcuts(
      bindings: <ShortcutActivator, VoidCallback>{
        const SingleActivator(LogicalKeyboardKey.space): onToggle,
        const SingleActivator(LogicalKeyboardKey.arrowUp): () => onBpmDelta(shift ? 5 : 1),
        const SingleActivator(LogicalKeyboardKey.equal): () => onBpmDelta(shift ? 5 : 1),
        const SingleActivator(LogicalKeyboardKey.add): () => onBpmDelta(shift ? 5 : 1),
        const SingleActivator(LogicalKeyboardKey.arrowDown): () => onBpmDelta(shift ? -5 : -1),
        const SingleActivator(LogicalKeyboardKey.minus): () => onBpmDelta(shift ? -5 : -1),
        const SingleActivator(LogicalKeyboardKey.digit1): () => onRate(1),
        const SingleActivator(LogicalKeyboardKey.digit2): () => onRate(2),
        const SingleActivator(LogicalKeyboardKey.digit3): () => onRate(3),
        const SingleActivator(LogicalKeyboardKey.arrowLeft): () => onAdjacentExercise(-1),
        const SingleActivator(LogicalKeyboardKey.arrowRight): () => onAdjacentExercise(1),
        const SingleActivator(LogicalKeyboardKey.escape): onExit,
      },
      child: Focus(autofocus: true, child: child),
    );
  }
}
```

Note: `shift` is read at build; the arrow bindings recompute per rebuild. For correct Shift handling at press time, read `HardwareKeyboard.instance.isShiftPressed` inside each callback instead (move the `final shift = ...` line into each closure). Do that so ±5 works without a rebuild.

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/features/practice/practice_shortcuts_test.dart`
Expected: PASS.

- [ ] **Step 5: Wire into the screen (desktop only) + legend**

In `practice_session_screen.dart`, on the desktop branch wrap `PracticeDesktopBody` in `PracticeShortcuts`:
- `onToggle: notifier.toggle`
- `onBpmDelta: (d) => notifier.setBpm((metState.bpm + d).clamp(40, 240))`
- `onRate: (r) { if (_showRating || !metState.isPlaying) _saveAndFinishDesktop(r); }` (only rate when a session has been played/stopped)
- `onExit: () => context.pop()`
- `onAdjacentExercise: (_) {}` — **no-op stub**: the screen receives no exercise list today, so prev/next resolves to nothing. Leave a `// TODO(P4+): wire prev/next when an exercise list is passed to the route.` — this is the one place a stub is acceptable because the spec scoped it as no-op without context.

Add a small legend to the desktop header: an `IconButton(icon: Icon(Icons.keyboard_outlined))` in the desktop title row that opens a simple `showDialog` / popover listing the shortcuts (Space, ↑↓/±, 1/2/3, ←→, Esc). Keep it static text.

- [ ] **Step 6: Full suite + analyze**

Run: `flutter analyze --no-fatal-warnings && flutter test`
Expected: no analyzer errors; all tests green.

- [ ] **Step 7: Commit**

```bash
git add lib/features/practice/widgets/practice_shortcuts.dart lib/features/practice/practice_session_screen.dart test/features/practice/practice_shortcuts_test.dart
git commit -m "feat(desktop): keyboard shortcuts + shortcut legend for practice screen"
```

---

## Device Verification (after implementation, outside the tasks)

Not on the NUC. Via `cross-machine-test-deploy` on the Linux laptop (Flutter SDK + checkout from P1 already present at `~/agent-test-checkouts/drum_coach-desktop-p1`): `git pull`, `flutter build linux --release`, run the bundle, confirm the NavigationRail sidebar, the three-zone practice screen, and the keyboard shortcuts (Space/↑↓/1-2-3/Esc). Capture a screenshot. CI stays green on all three OS (the workflow already builds + uploads artifacts).

## Self-Review Notes (author)

- **Spec coverage:** platform-gated shell (T2), min window size (T1), three-zone practice (T4), extracted reusable widgets enabling both layouts (T3), all keyboard shortcuts + legend + hover-via-Material (T5). Mobile-unchanged is guaranteed by gating and by T3 keeping `_CompactMetronome`/rating behavior identical.
- **Prev/next exercise** is a deliberate no-op stub (T5) — the spec scoped it as no-op without an exercise list, and the current route passes none. Flagged as the single allowed stub.
- **Hover affordances:** Material widgets (NavigationRail, BottomNavigationBar, InkWell, buttons) already render hover highlights + click cursor on desktop; no separate task. Add `SystemMouseCursors.click` only if a custom `GestureDetector` lacks it (none introduced here).
- **Type consistency:** `AppShell`, `BpmTransport`, `SubdivisionSelector`, `TimerGoalRow`, `RatingSelector`, `PracticeInfoPanel`, `PracticeControlPanel`, `PracticeDesktopBody`, `PracticeShortcuts` names are used identically across tasks. Import paths for `NotationStaffWidget`/`SoundType`/`rudimentsSeedData` must be grep-verified in T4 before running (names unchanged).
- **AI-coaching** stays off desktop: desktop rating calls `_saveAndFinishDesktop` (no `_FeedbackSheet`).
