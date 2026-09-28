import 'dart:async';

import 'package:drum_coach/data/local/settings_service.dart';
import 'package:drum_coach/features/lessons/data/rudiments_seed.dart';
import 'package:drum_coach/features/metronome/backing_styles.dart';
import 'package:drum_coach/features/metronome/metronome_engine.dart';
import 'package:drum_coach/features/metronome/metronome_provider.dart';
import 'package:drum_coach/features/practice/practice_provider.dart';
import 'package:drum_coach/features/practice/practice_session_screen.dart';
import 'package:drum_coach/features/practice/widgets/pulse_bar.dart';
import 'package:drum_coach/features/practice/widgets/tempo_row.dart';
import 'package:drum_coach/shared/widgets/notation_staff_widget.dart';
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
  int? targetBpm,
  int? targetMinutes,
  bool isLadder = false,
  String? contextLine,
  int? phase,
}) =>
    PracticeSessionScreen(
      rudimentId: rudimentsSeedData.first.id,
      isFromRoutine: false,
      targetBpm: targetBpm,
      targetMinutes: targetMinutes,
      isLadder: isLadder,
      contextLine: contextLine,
      phase: phase,
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
    // Close the first container before the second screen: its session
    // timer must not survive into the pending-timers check.
    first.dispose();

    final second = await _pumpScreen(tester, screen: _screen());
    expect(
        find.text(rudimentsSeedData.first.difficulty.label), findsOneWidget);
    second.dispose();
  });

  testWidgets('backdrop photo: the program phase from Today, else by difficulty',
      (tester) async {
    // Decided 27.09.: a dimmed photo behind the whole screen, like a stage.
    final fromToday = await _pumpScreen(tester, screen: _screen(phase: 3));
    expect(_backdropOf(tester), 'assets/illustrations/today/phase3.jpg');
    final rect = tester.getRect(find.byType(Image).first);
    expect(rect.width, 360);
    expect(rect.height, 780);
    fromToday.dispose();

    // Free practice: Single Stroke Roll is a beginner exercise → phase 1.
    final free = await _pumpScreen(tester, screen: _screen());
    expect(_backdropOf(tester), 'assets/illustrations/today/phase1.jpg');
    free.dispose();
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
    // The widget's scroll view fills the area; the painted card inside it is
    // what the eye sees.
    final sheet = tester.getRect(find
        .descendant(
            of: find.byType(NotationStaffWidget),
            matching: find.byType(CustomPaint))
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
    await tester.ensureVisible(find.byType(Switch));
    await tester.tap(find.byType(Switch));
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
      'options sheet offers backing styles, remembers the choice per '
      'exercise and enables the level slider only with a style',
      (tester) async {
    _mockHeadphones(tester, 'none');
    final container = await _pumpScreen(tester, screen: _screen());
    expect(container.read(metronomeNotifierProvider).backingStyleId, isNull);

    await tester.tap(find.byIcon(Icons.more_horiz));
    await tester.pumpAndSettle();
    expect(find.text('BACKING'), findsOneWidget);
    expect(find.text('Off'), findsOneWidget);
    for (final s in backingStyles) {
      expect(find.text(s.label), findsOneWidget);
    }
    expect(tester.widget<Slider>(find.byType(Slider)).onChanged, isNull);

    await tester.tap(find.text('Rock 8ths'));
    await tester.pump();
    expect(container.read(metronomeNotifierProvider).backingStyleId, 'rock8');
    expect(
        SettingsService.backingStyleFor(rudimentsSeedData.first.id), 'rock8');
    expect(tester.widget<Slider>(find.byType(Slider)).onChanged, isNotNull);

    await tester.tap(find.text('Off'));
    await tester.pump();
    expect(container.read(metronomeNotifierProvider).backingStyleId, isNull);
    expect(SettingsService.backingStyleFor(rudimentsSeedData.first.id),
        backingOff);
    expect(tester.takeException(), isNull);
    container.dispose();
  });

  testWidgets('the level slider writes the backing level', (tester) async {
    _mockHeadphones(tester, 'none');
    await SettingsService.setBackingStyleFor(
        rudimentsSeedData.first.id, 'swing');
    final container = await _pumpScreen(tester, screen: _screen());
    expect(container.read(metronomeNotifierProvider).backingStyleId, 'swing');
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

  testWidgets(
      'analysis mode without headphones mutes backing and click track, '
      'with headphones both stay on', (tester) async {
    _mockMicPermission(tester);
    final phones = _mockHeadphones(tester, 'none');
    await SettingsService.setMicAnalysisEnabled(true);
    await SettingsService.setBackingStyleFor(
        rudimentsSeedData.first.id, 'rock8');

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
    // The remembered choice itself is untouched.
    expect(
        SettingsService.backingStyleFor(rudimentsSeedData.first.id), 'rock8');

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
    await tester.tap(find.text('Rock 16ths'));
    await tester.pump();
    // Choice is stored, but stays muted while the mic listens.
    expect(
        SettingsService.backingStyleFor(rudimentsSeedData.first.id), 'rock16');
    expect(container.read(metronomeNotifierProvider).backingStyleId, isNull);
    await tester.tapAt(const Offset(10, 10)); // close the sheet
    await tester.pumpAndSettle();

    // Headphones plugged in: the metronome reports a route change.
    phones.set('wired');
    container
        .read(metronomeNotifierProvider.notifier)
        .notifyAudioRouteChanged();
    await tester.pump();
    await tester.pump();
    expect(container.read(metronomeNotifierProvider).backingStyleId, 'rock16');
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
    await SettingsService.setBackingStyleFor(
        rudimentsSeedData.first.id, 'rock8');

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
    await SettingsService.setBackingStyleFor(
        rudimentsSeedData.first.id, 'rock8');
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
}
