import 'package:drum_coach/data/local/settings_service.dart';
import 'package:drum_coach/features/lessons/data/rudiments_seed.dart';
import 'package:drum_coach/features/metronome/metronome_engine.dart';
import 'package:drum_coach/features/metronome/metronome_provider.dart';
import 'package:drum_coach/features/practice/practice_session_screen.dart';
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

Future<ProviderContainer> _pumpScreen(
  WidgetTester tester, {
  required PracticeSessionScreen screen,
  MetronomeNotifier Function()? metronome,
}) async {
  final container = ProviderContainer(overrides: [
    metronomeNotifierProvider
        .overrideWith(metronome ?? () => _IdleMetronomeNotifier()),
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
}) =>
    PracticeSessionScreen(
      rudimentId: rudimentsSeedData.first.id,
      isFromRoutine: false,
      targetBpm: targetBpm,
      targetMinutes: targetMinutes,
      isLadder: isLadder,
      contextLine: contextLine,
    );

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
    expect(find.text('How did it feel?'), findsOneWidget);
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
    await tester.pumpAndSettle();
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
    await tester.pumpAndSettle();
    expect(find.text('Options'), findsOneWidget);

    // The goal expires while the sheet is open: the rating must not stack on
    // top of it, or the final pop leaves the user on a dead practice screen.
    await tester.pump(const Duration(seconds: 61));
    await tester.pumpAndSettle();
    expect(find.text('Options'), findsNothing);
    expect(find.text('How did it feel?'), findsOneWidget);
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
    await tester.tap(find.byType(Switch));
    await tester.pump();
    expect(container.read(metronomeNotifierProvider).clickTrack, isFalse);
    expect(SettingsService.clickTrackEnabled, isFalse);
  });

  testWidgets('analysis mode silences the click track, learn mode restores it',
      (tester) async {
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
}
