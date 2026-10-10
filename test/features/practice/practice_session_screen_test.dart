import 'dart:async';

import 'package:drum_coach/data/local/settings_service.dart';
import 'package:drum_coach/features/lessons/data/rudiments_seed.dart';
import 'package:drum_coach/features/lessons/models/pattern_playback.dart';
import 'package:drum_coach/features/lessons/models/rudiment.dart';
import 'package:drum_coach/features/lessons/models/sheet_plan.dart';
import 'package:drum_coach/features/metronome/backing_styles.dart';
import 'package:drum_coach/features/metronome/metronome_engine.dart';
import 'package:drum_coach/features/metronome/metronome_provider.dart';
import 'package:drum_coach/features/practice/backdrop.dart';
import 'package:drum_coach/features/practice/practice_provider.dart';
import 'package:drum_coach/features/practice/practice_session_screen.dart';
import 'package:drum_coach/features/practice/widgets/pulse_bar.dart';
import 'package:drum_coach/features/practice/widgets/sheet_window.dart';
import 'package:drum_coach/features/practice/widgets/tempo_row.dart';
import 'package:drum_coach/shared/widgets/app_badge.dart';
import 'package:drum_coach/shared/widgets/sheet_geometry.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Overrides [MetronomeNotifier] so its very first `build()` already reports
/// the metronome as playing mid-pattern — the state a real device hits when
/// the screen is pushed while the keep-alive metronome is already running.
/// No SoLoud / isolate is touched, so the tests stay hermetic.
class _AlreadyPlayingMetronomeNotifier extends MetronomeNotifier {
  @override
  MetronomeState build() {
    return const MetronomeState(isPlaying: true, currentBeatIndex: 0);
  }
}

/// Idle metronome without engine/SoLoud. start/stop/setBpm of the real
/// notifier are engine-null-safe, so tapping Start/Stop works in tests.
class _IdleMetronomeNotifier extends MetronomeNotifier {
  @override
  MetronomeState build() => const MetronomeState();
}

/// Idle metronome that records the length of every pattern handed to it —
/// the sheet tests read which unit the screen loaded.
class _RecordingMetronomeNotifier extends MetronomeNotifier {
  final volumes = <int?>[];
  @override
  MetronomeState build() => const MetronomeState();
  @override
  void setPatternVolumes(List<double>? v) {
    volumes.add(v?.length);
    super.setPatternVolumes(v);
  }
}

/// Same, but already playing on first build (a line change mid-session).
class _RecordingPlayingMetronomeNotifier extends _RecordingMetronomeNotifier {
  @override
  MetronomeState build() =>
      const MetronomeState(isPlaying: true, currentBeatIndex: 0);
}

/// Records saves instead of writing to Isar (no database in widget tests).
/// The ratings go into a list the TEST owns: the provider is autoDispose, so
/// the notifier instance is thrown away right after the screen's call and a
/// later `container.read` would hand back a fresh, empty one.
class _FakePracticeNotifier extends PracticeNotifier {
  _FakePracticeNotifier(this.saves);
  final List<int> saves;
  @override
  Future<void> saveSession({
    required String rudimentId,
    required int durationSeconds,
    required int achievedBpm,
    required int rating,
    required int targetBpm,
  }) async {
    saves.add(rating);
  }
}

Future<ProviderContainer> _pumpScreen(
  WidgetTester tester, {
  required PracticeSessionScreen screen,
  MetronomeNotifier Function()? metronome,
  List<int>? saves,
}) async {
  final container = ProviderContainer(overrides: [
    metronomeNotifierProvider
        .overrideWith(metronome ?? () => _IdleMetronomeNotifier()),
    practiceNotifierProvider
        .overrideWith(() => _FakePracticeNotifier(saves ?? <int>[])),
  ]);
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(home: screen),
    ),
  );
  await tester.pump();
  return container;
}

PracticeSessionScreen _screen({
  String? id,
  int? targetBpm,
  int? targetMinutes,
  bool isLadder = false,
  String? contextLine,
  int? phase,
  int? line,
  String? mode,
}) =>
    PracticeSessionScreen(
      rudimentId: id ?? rudimentsSeedData.first.id,
      isFromRoutine: false,
      targetBpm: targetBpm,
      targetMinutes: targetMinutes,
      isLadder: isLadder,
      contextLine: contextLine,
      phase: phase,
      line: line,
      mode: mode,
    );

String _backdropOf(WidgetTester tester) => (tester
        .widget<Image>(find.byType(Image).first)
        .image as AssetImage)
    .assetName;

/// Mocks the native audio channel: headphone type for the analysis-mode
/// rule. Returns a handle to change the answer mid-test.
({void Function(String) set}) _mockHeadphones(WidgetTester tester, String type) {
  var current = type;
  const channel = MethodChannel('drum_coach/audio');
  tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel,
      (call) async {
    if (call.method == 'headphonesType') return current;
    return null;
  });
  addTearDown(() => tester.binding.defaultBinaryMessenger
      .setMockMethodCallHandler(channel, null));
  return (set: (t) => current = t);
}

void _mockMicPermission(WidgetTester tester) {
  const channel = MethodChannel('flutter.baseflow.com/permissions/methods');
  tester.binding.defaultBinaryMessenger
      .setMockMethodCallHandler(channel, (call) async {
    if (call.method == 'requestPermissions') return <int, int>{7: 1};
    if (call.method == 'checkPermissionStatus') return 1;
    return null;
  });
  addTearDown(() => tester.binding.defaultBinaryMessenger
      .setMockMethodCallHandler(channel, null));
}

void main() {
  group('initialSheetPosition', () {
    const none = (line: 0, sheet: false);
    test('route params win, clamped and parsed leniently', () {
      expect(
          initialSheetPosition(
              lineCount: 11, paramLine: 3, paramMode: 'sheet', remembered: none),
          (line: 2, sheet: true));
      expect(
          initialSheetPosition(
                  lineCount: 11, paramLine: 99, paramMode: null, remembered: none)
              .line,
          0);
      expect(
          initialSheetPosition(
              lineCount: 11, paramLine: 0, paramMode: 'bogus', remembered: none),
          (line: 0, sheet: false));
    });
    test('else the remembered position, clamped into the sheet', () {
      expect(
          initialSheetPosition(
              lineCount: 11,
              paramLine: null,
              paramMode: null,
              remembered: (line: 4, sheet: false)),
          (line: 4, sheet: false));
      expect(
          initialSheetPosition(
              lineCount: 3,
              paramLine: null,
              paramMode: null,
              remembered: (line: 7, sheet: true)),
          (line: 0, sheet: true));
    });
  });

  group('staleTickAfterUnitChange', () {
    final changed = DateTime(2026, 10, 1, 12, 0, 0);
    test('every tick of the old loop is stale until a downbeat after the '
        'engine rebuild', () {
      final soon = changed.add(const Duration(milliseconds: 40));
      final later = changed.add(const Duration(milliseconds: 400));
      expect(
          staleTickAfterUnitChange(tick: 0, changedAt: changed, plannedAt: soon),
          isTrue);
      expect(
          staleTickAfterUnitChange(
              tick: 12, changedAt: changed, plannedAt: later),
          isTrue);
      expect(
          staleTickAfterUnitChange(tick: 0, changedAt: changed, plannedAt: later),
          isFalse);
      expect(
          staleTickAfterUnitChange(
              tick: 0,
              changedAt: changed,
              plannedAt:
                  changed.add(const Duration(milliseconds: engineRebuildMs))),
          isFalse);
    });
  });

  group('sheet (Blattform)', () {
    const sheetId = 'single_paradiddle';
    Rudiment sheetRudiment() =>
        rudimentsSeedData.firstWhere((r) => r.id == sheetId);

    testWidgets('a one-line exercise shows no line bar', (tester) async {
      // A legacy basic rudiment without authored lines (Katalog 3a turned
      // the first twelve into sheets).
      await _pumpScreen(tester, screen: _screen(id: 'multiple_bounce_roll'));
      expect(find.byKey(const ValueKey('line-bar')), findsNothing);
      expect(find.byType(SheetWindow), findsOneWidget);
      // Uli 10.10.: the card nearly fills the width — 6 px margins.
      final rect = tester.getRect(find.byType(SheetWindow));
      expect(rect.left, 6);
      expect(rect.right, 360 - 6);
    });

    testWidgets(
        'a sheet opens on line 1 with the line bar; › moves to line 2 and '
        'reloads the loop', (tester) async {
      final rec = _RecordingMetronomeNotifier();
      await _pumpScreen(tester,
          screen: _screen(id: sheetId), metronome: () => rec);
      expect(find.text('Line 1 / 9'), findsOneWidget);
      final line2 = SheetPlan.line(sheetRudiment(), 1);
      await tester.tap(find.byKey(const ValueKey('line-next')));
      await tester.pump();
      expect(find.text('Line 2 / 9'), findsOneWidget);
      expect(
          rec.volumes.last,
          PatternPlayback.forRudiment(sheetRudiment().withSticking(line2.beats))
              .totalTicks);
      expect(SettingsService.sheetPositionFor(sheetId),
          (line: 1, sheet: false));
    });

    testWidgets('Sheet mode plays every line once and shows the bar count',
        (tester) async {
      final rec = _RecordingMetronomeNotifier();
      await _pumpScreen(tester,
          screen: _screen(id: sheetId), metronome: () => rec);
      await tester.tap(find.byKey(const ValueKey('mode-sheet')));
      await tester.pump();
      expect(find.text('Sheet · 24 bars'), findsOneWidget);
      expect(find.byKey(const ValueKey('line-next')), findsNothing);
      expect(rec.volumes.last, 24 * 96);
      expect(
          SettingsService.sheetPositionFor(sheetId), (line: 0, sheet: true));
    });

    testWidgets('?line=3 opens line 3; out of range opens line 1',
        (tester) async {
      final a =
          await _pumpScreen(tester, screen: _screen(id: sheetId, line: 3));
      expect(find.text('Line 3 / 9'), findsOneWidget);
      a.dispose();
      // A fresh State: the same widget type in the same place would keep
      // the old one (and its line) alive.
      await tester.pumpWidget(const SizedBox());
      final b =
          await _pumpScreen(tester, screen: _screen(id: sheetId, line: 40));
      expect(find.text('Line 1 / 9'), findsOneWidget);
      b.dispose();
    });

    testWidgets('the remembered position is restored', (tester) async {
      await SettingsService.setSheetPosition(sheetId, line: 4, sheet: false);
      await _pumpScreen(tester, screen: _screen(id: sheetId));
      expect(find.text('Line 5 / 9'), findsOneWidget);
    });

    testWidgets('tapping a line in the window selects it', (tester) async {
      await _pumpScreen(tester, screen: _screen(id: sheetId));
      final clip = tester.getRect(find.byType(ClipRect).first);
      // Row 1 of the window = line 2 (line 1 is one row).
      await tester.tapAt(Offset(clip.center.dx,
          clip.top + sheetWindowPad + 1.5 * sheetRowPitchWithCounts));
      await tester.pump();
      expect(find.text('Line 2 / 9'), findsOneWidget);
    });

    testWidgets('switching lines while playing reloads the loop at once',
        (tester) async {
      final rec = _RecordingPlayingMetronomeNotifier();
      await _pumpScreen(tester,
          screen: _screen(id: sheetId), metronome: () => rec);
      final before = rec.volumes.length;
      await tester.tap(find.byKey(const ValueKey('line-next')));
      await tester.pump();
      expect(rec.volumes.length, before + 1);
      expect(find.text('Stop'), findsOneWidget);
      expect(find.text('Line 2 / 9'), findsOneWidget);
    });

    testWidgets('options: sticking letters and count hints switches',
        (tester) async {
      await _pumpScreen(tester, screen: _screen(id: sheetId));
      await tester.tap(find.byIcon(Icons.more_horiz));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const ValueKey('opt-counts')));
      await tester.tap(find.byKey(const ValueKey('opt-sticking')));
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('opt-counts')));
      await tester.pump();
      expect(SettingsService.showSticking, isFalse);
      expect(SettingsService.showCounts, isFalse);
    });
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await SettingsService.init();
    // Phone-sized surface so a layout that overflows on a device fails here.
    final binding = TestWidgetsFlutterBinding.ensureInitialized();
    binding.platformDispatcher.views.first.physicalSize = const Size(1080, 2340);
    binding.platformDispatcher.views.first.devicePixelRatio = 3.0;
  });

  tearDown(() {
    final view = TestWidgetsFlutterBinding.ensureInitialized()
        .platformDispatcher
        .views
        .first;
    view.resetPhysicalSize();
    view.resetDevicePixelRatio();
  });

  testWidgets(
      'does not throw LateInitializationError when the metronome is already '
      'playing on first build', (tester) async {
    final container = await _pumpScreen(
      tester,
      screen: _screen(),
      metronome: () => _AlreadyPlayingMetronomeNotifier(),
    );
    expect(tester.takeException(), isNull);
    expect(find.byType(PracticeSessionScreen), findsOneWidget);
    // Running state: Stop is the primary action, no Finish yet.
    expect(find.text('Stop'), findsOneWidget);
    expect(find.text('Finish'), findsNothing);
    container.dispose();
  });

  testWidgets('ready: Start shows the suggested block length', (tester) async {
    await _pumpScreen(tester, screen: _screen(targetMinutes: 4));
    expect(find.text('Start'), findsOneWidget);
    expect(find.text('4 min'), findsOneWidget);
    expect(find.text('Finish'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('ready without a length: plain Start, no time', (tester) async {
    await _pumpScreen(tester, screen: _screen());
    expect(find.text('Start'), findsOneWidget);
    expect(find.text('00:00'), findsNothing);
    expect(find.text('Finish'), findsNothing);
  });

  testWidgets('header shows the context line, or the difficulty without one',
      (tester) async {
    final first = await _pumpScreen(tester,
        screen: _screen(contextLine: 'Day 9 · Step 2 of 3 · 84 BPM'));
    expect(find.text('Day 9 · Step 2 of 3 · 84 BPM'), findsOneWidget);
    // Uli 28.09.: a light shadow so the header reads on bright photos.
    final line =
        tester.widget<Text>(find.text('Day 9 · Step 2 of 3 · 84 BPM'));
    expect(line.style?.shadows, isNotEmpty);
    final name = tester.widget<Text>(find.text(rudimentsSeedData.first.name));
    expect(name.style?.shadows, isNotEmpty);
    // Close the first container before the second screen: its session
    // timer must not survive into the pending-timers check.
    first.dispose();

    final second = await _pumpScreen(tester, screen: _screen());
    expect(
        find.text(rudimentsSeedData.first.difficulty.label), findsOneWidget);
    second.dispose();
  });

  testWidgets('backdrop photo: a random one from the practice pool, full screen',
      (tester) async {
    // Decided 27.09.: a dimmed photo behind the whole screen, like a stage.
    // 28.09. (Uli): random from a big pool instead of the program phase.
    final fromToday = await _pumpScreen(tester, screen: _screen(phase: 3));
    expect(practiceBackdrops, contains(_backdropOf(tester)));
    final rect = tester.getRect(find.byType(Image).first);
    expect(rect.width, 360);
    expect(rect.height, 780);
    fromToday.dispose();
  });

  testWidgets('the scrim over the photo is lighter while configuring and '
      'darkens with the start', (tester) async {
    // Uli 28.09.: "das Bild könnte noch ein bisschen heller bei
    // durchsichtigen Noten" — 15/40/85 % before the start, 30/60/88 % after.
    await _pumpScreen(tester, screen: _screen());
    LinearGradient scrim() => (tester
            .widget<AnimatedContainer>(
                find.byKey(const ValueKey('backdrop-scrim')))
            .decoration as BoxDecoration)
        .gradient as LinearGradient;
    List<int> alphas() =>
        scrim().colors.map((c) => (c.a * 255).round()).toList();
    expect(alphas(), [0x26, 0x66, 0xD9]);
    await tester.tap(find.text('Start'));
    await tester.pump();
    expect(alphas(), [0x4D, 0x99, 0xE0]);
  });

  testWidgets('pulse bar sits under the sheet and follows the loop',
      (tester) async {
    final container = await _pumpScreen(tester, screen: _screen());
    expect(find.byType(PulseBar), findsOneWidget);
    final bar = tester.widget<PulseBar>(find.byType(PulseBar));
    expect(bar.playing, isFalse);
    expect(bar.totalTicks, greaterThan(0));
    expect(bar.ticksPerQuarter, 24);
    container.dispose();
  });

  testWidgets('a short sheet sits centred between header and tempo row, not '
      'glued to the top', (tester) async {
    // Seen on the emulator: a one-bar exercise left the card at the top with
    // a big hole under it. The design centres the card in its area.
    // Six Stroke Roll is a single short row, so the card cannot fill the area.
    await _pumpScreen(
        tester,
        screen: const PracticeSessionScreen(
            rudimentId: 'six_stroke_roll', isFromRoutine: false));
    // The window's clipped paper card is what the eye sees.
    final sheet = tester.getRect(find
        .descendant(
            of: find.byType(SheetWindow), matching: find.byType(ClipRect))
        .first);
    final header = tester.getRect(find.text('Six Stroke Roll'));
    final tempo = tester.getRect(find.byType(TempoRow));
    final above = sheet.top - header.bottom;
    final below = tempo.top - sheet.bottom;
    expect(below - above, lessThan(40),
        reason: 'gap above $above, gap below $below');
  });

  testWidgets('running: Stop with the remaining time; paused: Resume + Finish',
      (tester) async {
    final container =
        await _pumpScreen(tester, screen: _screen(targetMinutes: 4));
    await tester.tap(find.text('Start'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 40));
    expect(find.text('Stop'), findsOneWidget);
    expect(find.text('03:20'), findsOneWidget);
    expect(find.text('Finish'), findsNothing);

    await tester.tap(find.text('Stop'));
    await tester.pump();
    expect(find.text('Resume'), findsOneWidget);
    expect(find.text('03:20'), findsOneWidget);
    expect(find.text('Finish'), findsOneWidget);

    await tester.tap(find.text('Finish'));
    await tester.pumpAndSettle();
    // One result sheet (K2 step 3), not the old rating sheet.
    expect(find.text('How did it feel?'), findsNothing);
    expect(find.text('HOW DID IT FEEL?'), findsOneWidget);
    expect(find.text('SESSION COMPLETE'), findsOneWidget);
    expect(find.text('No mic analysis this time'), findsOneWidget);
    container.dispose();
  });

  testWidgets('restored session starts paused with Resume and Finish',
      (tester) async {
    SharedPreferences.setMockInitialValues({
      'practice_snap_id': rudimentsSeedData.first.id,
      'practice_snap_elapsed': 200,
      'practice_snap_time': DateTime.now().toIso8601String(),
    });
    await SettingsService.init();

    final container = await _pumpScreen(tester, screen: _screen());
    expect(find.text('Resume'), findsOneWidget);
    expect(find.text('03:20'), findsOneWidget);
    expect(find.text('Finish'), findsOneWidget);
    expect(find.textContaining('Resumed'), findsOneWidget);
    container.dispose();
  });

  testWidgets('expired snapshot is ignored', (tester) async {
    SharedPreferences.setMockInitialValues({
      'practice_snap_id': rudimentsSeedData.first.id,
      'practice_snap_elapsed': 200,
      'practice_snap_time':
          DateTime.now().subtract(const Duration(hours: 2)).toIso8601String(),
    });
    await SettingsService.init();

    await _pumpScreen(tester, screen: _screen());
    expect(find.text('Start'), findsOneWidget);
    expect(find.text('Resume'), findsNothing);
    expect(find.text('Finish'), findsNothing);
  });

  testWidgets('ladder mode shows the steps and starts on the lowest',
      (tester) async {
    await _pumpScreen(tester,
        screen: _screen(targetBpm: 80, targetMinutes: 4, isLadder: true));
    expect(find.text('LADDER'), findsOneWidget);
    for (final bpm in ['76', '80', '84']) {
      expect(find.text(bpm), findsOneWidget);
    }
    // Lowest step both in the tempo display and its chip.
    expect(find.text('72'), findsNWidgets(2));
  });

  testWidgets('manual +4 rebases the ladder instead of the program tempo',
      (tester) async {
    await _pumpScreen(tester,
        screen: _screen(targetBpm: 60, targetMinutes: 4, isLadder: true));
    // Gate 60 → steps 52/56/60/64, metronome on the lowest (52).
    expect(find.text('52'), findsNWidgets(2));
    expect(find.text('64'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();
    // Current step becomes 56, the ladder follows (56/60/64/68).
    expect(find.text('56'), findsNWidgets(2));
    expect(find.text('68'), findsOneWidget);
    expect(find.text('52'), findsNothing);
  });

  testWidgets('mode chip only with mic analysis, tap toggles it',
      (tester) async {
    final withoutMic = await _pumpScreen(tester, screen: _screen());
    expect(find.text('LEARN'), findsNothing);
    expect(find.text('ANALYSIS'), findsNothing);
    withoutMic.dispose();

    // With mic analysis on, initState asks permission_handler for the
    // microphone. There is no platform in a widget test, so answer the
    // method channel ourselves: 7 = Permission.microphone, 1 = granted.
    const channel = MethodChannel('flutter.baseflow.com/permissions/methods');
    tester.binding.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      if (call.method == 'requestPermissions') return <int, int>{7: 1};
      if (call.method == 'checkPermissionStatus') return 1;
      return null;
    });
    addTearDown(() => tester.binding.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null));

    await SettingsService.setMicAnalysisEnabled(true);
    final withMic = await _pumpScreen(tester, screen: _screen());
    expect(find.text('LEARN'), findsOneWidget);
    await tester.tap(find.text('LEARN'));
    await tester.pump();
    expect(find.text('ANALYSIS'), findsOneWidget);
    expect(
        SettingsService.analysisModeFor(rudimentsSeedData.first.id), isTrue);
    withMic.dispose();
  });

  testWidgets('no overflow in ready, running and paused state',
      (tester) async {
    final container = await _pumpScreen(tester,
        screen: _screen(targetBpm: 60, targetMinutes: 8, isLadder: true));
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('Start'));
    await tester.pump();
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('Stop'));
    await tester.pump();
    expect(tester.takeException(), isNull);
    container.dispose();
  });

  testWidgets('options: duration chip sets the length on the Start button',
      (tester) async {
    await _pumpScreen(tester, screen: _screen(targetMinutes: 4));
    await tester.tap(find.byIcon(Icons.more_horiz));
    await tester.pumpAndSettle();
    expect(find.text('Options'), findsOneWidget);
    expect(find.text('4 min ✦'), findsOneWidget);

    await tester.tap(find.text('10 min'));
    await tester.pump();
    // The sheet scrolls (BACKING section since Engine part 1): bring Done in.
    await tester.ensureVisible(find.text('Done'));
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();
    expect(find.text('Start'), findsOneWidget);
    expect(find.text('10 min'), findsOneWidget);
  });

  testWidgets('options: sound chip switches the click sound', (tester) async {
    final container = await _pumpScreen(tester, screen: _screen());
    await tester.tap(find.byIcon(Icons.more_horiz));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Rim'));
    await tester.pump();
    expect(container.read(metronomeNotifierProvider).soundType, SoundType.rim);
  });

  testWidgets('options: duration is locked once the session runs',
      (tester) async {
    final container =
        await _pumpScreen(tester, screen: _screen(targetMinutes: 4));
    await tester.tap(find.text('Start'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 5));
    await tester.tap(find.byIcon(Icons.more_horiz));
    // Fixed pumps, not pumpAndSettle: while playing, the pulse bar's ticker
    // keeps scheduling frames and pumpAndSettle would run the clock until
    // the session's goal expires.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    expect(find.text('Duration is set once the session runs'), findsOneWidget);
    expect(find.text('10 min'), findsNothing);
    container.dispose();
  });

  testWidgets('auto-finish closes an open options sheet first',
      (tester) async {
    final container =
        await _pumpScreen(tester, screen: _screen(targetMinutes: 1));
    await tester.tap(find.text('Start'));
    await tester.pump();
    await tester.tap(find.byIcon(Icons.more_horiz));
    // Fixed pumps while playing (see the duration-lock test).
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    expect(find.text('Options'), findsOneWidget);

    // The goal expires while the sheet is open: the rating must not stack on
    // top of it, or the final pop leaves the user on a dead practice screen.
    await tester.pump(const Duration(seconds: 61));
    await tester.pumpAndSettle();
    expect(find.text('Options'), findsNothing);
    expect(find.text('HOW DID IT FEEL?'), findsOneWidget);
    container.dispose();
  });

  testWidgets('rating on the result sheet saves once and unlocks Done',
      (tester) async {
    final saves = <int>[];
    final container = await _pumpScreen(tester,
        screen: _screen(targetMinutes: 1), saves: saves);
    await tester.tap(find.text('Start'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 3));
    await tester.tap(find.text('Stop'));
    await tester.pump();
    // An interrupted-session snapshot, as the app writes it when it goes to
    // the background — saving the rating must clear it.
    await SettingsService.savePracticeSnapshot(
        rudimentId: rudimentsSeedData.first.id, elapsedSeconds: 3);
    expect(SettingsService.practiceSnapshotFor(rudimentsSeedData.first.id),
        isNotNull);
    await tester.tap(find.text('Finish'));
    await tester.pumpAndSettle();
    FilledButton done() => tester
        .widget<FilledButton>(find.widgetWithText(FilledButton, 'Done'));
    expect(done().onPressed, isNull);

    // The back button must not close the sheet before a rating is saved.
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('HOW DID IT FEEL?'), findsOneWidget);

    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(saves, [2]);
    // Saved: the interrupted-session snapshot is gone and Done is live.
    expect(SettingsService.practiceSnapshotFor(rudimentsSeedData.first.id),
        isNull);
    expect(done().onPressed, isNotNull);

    // A second chip does not save again.
    await tester.tap(find.text('Solid'));
    await tester.pumpAndSettle();
    expect(saves, [2]);
    container.dispose();
  });

  testWidgets('click track runs by default and is switchable in the options',
      (tester) async {
    // Decided 27.09.: no digit counter — a quarter-note pulse next to the
    // exercise instead, on by default, remembered in the settings.
    final container = await _pumpScreen(tester, screen: _screen());
    expect(container.read(metronomeNotifierProvider).clickTrack, isTrue);

    await tester.tap(find.byIcon(Icons.more_horiz));
    await tester.pumpAndSettle();
    expect(find.text('Click track'), findsOneWidget);
    // Several switches since Engine part 1 and the sheet options: pick the
    // click track by key.
    await tester.ensureVisible(find.byKey(const ValueKey('opt-click')));
    await tester.tap(find.byKey(const ValueKey('opt-click')));
    await tester.pump();
    expect(container.read(metronomeNotifierProvider).clickTrack, isFalse);
    expect(SettingsService.clickTrackEnabled, isFalse);
  });

  testWidgets('analysis mode silences the click track, learn mode restores it',
      (tester) async {
    _mockHeadphones(tester, 'none');
    const channel = MethodChannel('flutter.baseflow.com/permissions/methods');
    tester.binding.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      if (call.method == 'requestPermissions') return <int, int>{7: 1};
      if (call.method == 'checkPermissionStatus') return 1;
      return null;
    });
    addTearDown(() => tester.binding.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null));
    await SettingsService.setMicAnalysisEnabled(true);

    final container = await _pumpScreen(tester, screen: _screen());
    expect(container.read(metronomeNotifierProvider).clickTrack, isTrue);
    await tester.tap(find.text('LEARN'));
    await tester.pump();
    expect(container.read(metronomeNotifierProvider).clickTrack, isFalse);
    // The preference itself is untouched — only the mode mutes the pulse.
    expect(SettingsService.clickTrackEnabled, isTrue);
    await tester.tap(find.text('ANALYSIS'));
    await tester.pump();
    expect(container.read(metronomeNotifierProvider).clickTrack, isTrue);
    container.dispose();
  });

  testWidgets(
      'backing is automatic: the sheet shows the chosen style, a switch and '
      'the level slider, no chips', (tester) async {
    _mockHeadphones(tester, 'none');
    final container = await _pumpScreen(tester, screen: _screen());
    // First seed exercise is an eighth-note pattern → Rock 8ths.
    expect(container.read(metronomeNotifierProvider).backingStyleId, 'rock8');

    await tester.tap(find.byIcon(Icons.more_horiz));
    await tester.pumpAndSettle();
    expect(find.text('BACKING'), findsNothing);
    expect(find.text('Backing'), findsOneWidget);
    expect(find.text('Rock 8ths · automatic'), findsOneWidget);
    for (final s in backingStyles) {
      expect(find.widgetWithText(AppSelectableChip, s.label), findsNothing);
    }
    expect(tester.widget<Slider>(find.byType(Slider)).onChanged, isNotNull);

    // Two switches now: Backing (first) and Click track.
    await tester.ensureVisible(find.byType(Switch).first);
    await tester.tap(find.byType(Switch).first);
    await tester.pump();
    expect(container.read(metronomeNotifierProvider).backingStyleId, isNull);
    expect(SettingsService.backingEnabled, isFalse);
    expect(tester.widget<Slider>(find.byType(Slider)).onChanged, isNull);
    expect(tester.takeException(), isNull);
    container.dispose();
  });

  testWidgets('the level slider writes the backing level', (tester) async {
    _mockHeadphones(tester, 'none');
    final container = await _pumpScreen(tester, screen: _screen());
    await tester.tap(find.byIcon(Icons.more_horiz));
    await tester.pumpAndSettle();
    final slider = tester.widget<Slider>(find.byType(Slider));
    expect(slider.value, closeTo(0.7, 1e-9));
    slider.onChanged!(0.0);
    await tester.pump();
    expect(SettingsService.backingLevel, 0.0);
    expect(container.read(metronomeNotifierProvider).backingLevel, 0.0);
    container.dispose();
  });

  testWidgets('the automatic style follows the tempo: sixteenths relax to '
      'eighths from 140 BPM', (tester) async {
    _mockHeadphones(tester, 'none');
    final sixteenths = rudimentsSeedData
        .firstWhere((r) => r.gridUnit == NoteGrid.sixteenth);
    final container = await _pumpScreen(tester,
        screen: PracticeSessionScreen(
            rudimentId: sixteenths.id, isFromRoutine: false, targetBpm: 100));
    await tester.pump();
    expect(container.read(metronomeNotifierProvider).backingStyleId, 'rock16');
    container.read(metronomeNotifierProvider.notifier).setBpm(150);
    await tester.pump();
    expect(container.read(metronomeNotifierProvider).backingStyleId, 'rock8');
    container.dispose();
  });

  testWidgets(
      'analysis mode without headphones mutes backing and click track, '
      'with headphones both stay on', (tester) async {
    _mockMicPermission(tester);
    final phones = _mockHeadphones(tester, 'none');
    await SettingsService.setMicAnalysisEnabled(true);

    final container = await _pumpScreen(tester, screen: _screen());
    await tester.pump(); // headphone query answered
    // Learn mode, mic listening, no headphones: the band would reach the mic
    // and pollute the learn-mode result — backing muted, click track (quiet,
    // rule of 27.09.) still on.
    expect(container.read(metronomeNotifierProvider).backingStyleId, isNull);
    expect(container.read(metronomeNotifierProvider).clickTrack, isTrue);

    await tester.tap(find.text('LEARN'));
    await tester.pump();
    expect(container.read(metronomeNotifierProvider).backingStyleId, isNull);
    expect(container.read(metronomeNotifierProvider).clickTrack, isFalse);

    await tester.tap(find.byIcon(Icons.more_horiz));
    await tester.pumpAndSettle();
    expect(
        find.text(
            'Off while analysing without headphones — the mic would hear it'),
        findsWidgets);
    expect(
        find.text(
            'Off while the mic listens without headphones — it would hear the band'),
        findsOneWidget);
    await tester.tapAt(const Offset(10, 10)); // close the sheet
    await tester.pumpAndSettle();

    // Headphones plugged in: the metronome reports a route change.
    phones.set('wired');
    container
        .read(metronomeNotifierProvider.notifier)
        .notifyAudioRouteChanged();
    await tester.pump();
    await tester.pump();
    expect(container.read(metronomeNotifierProvider).backingStyleId, 'rock8');
    expect(container.read(metronomeNotifierProvider).clickTrack, isTrue);

    // Unplugged again: muted again before the mic hears the band.
    phones.set('none');
    container
        .read(metronomeNotifierProvider.notifier)
        .notifyAudioRouteChanged();
    await tester.pump();
    await tester.pump();
    expect(container.read(metronomeNotifierProvider).backingStyleId, isNull);
    expect(container.read(metronomeNotifierProvider).clickTrack, isFalse);
    container.dispose();
  });

  testWidgets(
      'backing needs headphones whenever the mic listens, even in learn mode; '
      'with the mic off it plays freely', (tester) async {
    _mockMicPermission(tester);
    final phones = _mockHeadphones(tester, 'none');

    // Mic analysis off (the default): band plays through the speaker.
    var container = await _pumpScreen(tester, screen: _screen());
    await tester.pump();
    expect(container.read(metronomeNotifierProvider).backingStyleId, 'rock8');
    // Tear the first screen down: a second pump of the same widget type
    // would keep the old State (and its old, disposed notifier).
    await tester.pumpWidget(const SizedBox());
    container.dispose();

    // Mic analysis on, learn mode, no headphones: muted.
    await SettingsService.setMicAnalysisEnabled(true);
    container = await _pumpScreen(tester, screen: _screen());
    await tester.pump();
    expect(container.read(metronomeNotifierProvider).backingStyleId, isNull);
    expect(container.read(metronomeNotifierProvider).clickTrack, isTrue);

    // Headphones: allowed again.
    phones.set('wired');
    container
        .read(metronomeNotifierProvider.notifier)
        .notifyAudioRouteChanged();
    await tester.pump();
    await tester.pump();
    expect(container.read(metronomeNotifierProvider).backingStyleId, 'rock8');
    container.dispose();
  });

  testWidgets(
      'a route change mutes the backing at once, before the headphone answer '
      'arrives', (tester) async {
    _mockMicPermission(tester);
    await SettingsService.setMicAnalysisEnabled(true);
    // First answer immediate ("wired"); the answer after the route change
    // is held back until the test releases it.
    const channel = MethodChannel('drum_coach/audio');
    var calls = 0;
    final held = Completer<String>();
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel,
        (call) async {
      if (call.method != 'headphonesType') return null;
      calls++;
      return calls == 1 ? 'wired' : await held.future;
    });
    addTearDown(() => tester.binding.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null));

    final container = await _pumpScreen(tester, screen: _screen());
    await tester.pump();
    expect(container.read(metronomeNotifierProvider).backingStyleId, 'rock8');

    container
        .read(metronomeNotifierProvider.notifier)
        .notifyAudioRouteChanged();
    await tester.pump();
    // Pessimistic: muted while the answer is still pending.
    expect(container.read(metronomeNotifierProvider).backingStyleId, isNull);

    held.complete('wired');
    await tester.pump();
    await tester.pump();
    expect(container.read(metronomeNotifierProvider).backingStyleId, 'rock8');
    container.dispose();
  });

  testWidgets(
      'the notation sheet is translucent while configuring and opaque once '
      'the session has started', (tester) async {
    // Uli 28.09.: the sheet hid the backdrop photo — see through it while
    // setting tempo and options, solid once you play.
    await _pumpScreen(tester, screen: _screen());
    AnimatedOpacity sheet() => tester.widget<AnimatedOpacity>(find
        .ancestor(
            of: find.byType(SheetWindow),
            matching: find.byType(AnimatedOpacity))
        .first);
    expect(sheet().opacity, 0.6);
    await tester.tap(find.text('Start'));
    await tester.pump();
    expect(sheet().opacity, 1.0);
    // Paused after a stop: the session has started, the sheet stays solid.
    await tester.pump(const Duration(seconds: 2));
    await tester.tap(find.text('Stop'));
    await tester.pump();
    expect(sheet().opacity, 1.0);
  });
}
