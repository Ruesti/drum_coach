import 'dart:async';

import 'package:drum_coach/app/platform_support.dart';
import 'package:drum_coach/data/local/settings_service.dart';
import 'package:drum_coach/features/coaching/midi/kit_instrument.dart';
import 'package:drum_coach/features/coaching/services/stroke_source.dart';
import 'package:drum_coach/features/lessons/data/rudiments_seed.dart';
import 'package:drum_coach/features/lessons/lessons_provider.dart';
import 'package:drum_coach/features/lessons/models/pattern_playback.dart';
import 'package:drum_coach/features/lessons/models/rudiment.dart';
import 'package:drum_coach/features/lessons/models/sheet_plan.dart';
import 'package:drum_coach/features/metronome/backing_styles.dart';
import 'package:drum_coach/features/metronome/loop_voices.dart';
import 'package:drum_coach/features/metronome/metronome_engine.dart';
import 'package:drum_coach/features/metronome/metronome_provider.dart';
import 'package:drum_coach/features/practice/backdrop.dart';
import 'package:drum_coach/features/practice/practice_provider.dart';
import 'package:drum_coach/features/practice/practice_session_screen.dart';
import 'package:drum_coach/features/practice/widgets/pulse_bar.dart';
import 'package:drum_coach/features/practice/widgets/line_view.dart';
import 'package:drum_coach/features/practice/widgets/tempo_row.dart';
import 'package:drum_coach/features/room/lesson_voice.dart';
import 'package:drum_coach/features/room/round_verdict.dart';
import 'package:drum_coach/features/room/tempo_ladder.dart';
import 'package:drum_coach/shared/widgets/app_badge.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/kit_fixtures.dart';
import '../../helpers/midi_fakes.dart';

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

/// Idle metronome that records the last backing call's mute flags.
class _BackingFlagsMetronomeNotifier extends MetronomeNotifier {
  ({bool kick, bool hihat})? last;
  String? lastStyleId;
  List<KitSoundTrack> lastKitTracks = const [];
  List<double>? lastPatternSound;
  @override
  MetronomeState build() => const MetronomeState();
  @override
  void setBacking(String? styleId,
      {required int beatsPerBar,
      bool backingKick = true,
      bool backingHihat = true,
      List<KitSoundTrack> kitTracks = const [],
      List<double>? patternSound}) {
    last = (kick: backingKick, hihat: backingHihat);
    lastStyleId = styleId;
    lastKitTracks = kitTracks;
    lastPatternSound = patternSound;
    super.setBacking(styleId,
        beatsPerBar: beatsPerBar,
        backingKick: backingKick,
        backingHihat: backingHihat,
        kitTracks: kitTracks,
        patternSound: patternSound);
  }
}

/// Playing metronome the test moves tick by tick.
class _TickingMetronomeNotifier extends MetronomeNotifier {
  @override
  MetronomeState build() => const MetronomeState(isPlaying: true);
  void tickTo(int tick) => state = state.copyWith(currentBeatIndex: tick);
}

/// Records saves instead of writing to Isar (no database in widget tests).
/// The ratings go into a list the TEST owns: the provider is autoDispose, so
/// the notifier instance is thrown away right after the screen's call and a
/// later `container.read` would hand back a fresh, empty one.
class _FakePracticeNotifier extends PracticeNotifier {
  _FakePracticeNotifier(this.saves, [this.roomSaves]);
  final List<int> saves;
  final List<List<LadderRound>>? roomSaves;
  @override
  Future<void> saveRoomSession({
    required String rudimentId,
    required int durationSeconds,
    required int achievedBpm,
    required int rating,
    required List<LadderRound> rounds,
    required int targetBpm,
    required int minBpm,
  }) async {
    saves.add(rating);
    roomSaves?.add(rounds);
  }

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

/// A stroke source the test fills by hand (Trainingsraum rounds).
class _FakeStrokeSource implements StrokeSource {
  _FakeStrokeSource(this.kind);
  @override
  final StrokeSourceKind kind;
  @override
  final List<StrokeEvent> events = [];
  @override
  bool get velocityExact => kind == StrokeSourceKind.midi;
  @override
  StrokeSourceStatus get status => StrokeSourceStatus.ready;
  @override
  Stream<StrokeSourceStatus> get statusChanges => const Stream.empty();
  @override
  String? get deviceName => null;
  @override
  Future<void> start() async {}
  @override
  Future<void> stop() async {}
  @override
  Map<String, Object>? describeSetup() => null;
  @override
  void dispose() {}
}

/// Idle until Start; the test then moves it tick by tick with planned
/// instants (the beat log takes those as the expected times).
class _RoomMetronomeNotifier extends MetronomeNotifier {
  @override
  MetronomeState build() => const MetronomeState();
  void tickTo(int tick, DateTime at) =>
      state = state.copyWith(currentBeatIndex: tick, lastBeatPlannedAt: at);
}

/// Records what "How to play" asks of the voice.
class _FakeLessonVoice implements LessonVoice {
  _FakeLessonVoice({this.clips = const {}});
  final Set<String> clips;
  final played = <String>[];
  @override
  Future<bool> has(String clipId) async => clips.contains(clipId);
  @override
  Future<void> play(String clipId) async => played.add(clipId);
  @override
  Future<void> stop() async {}
}

Future<ProviderContainer> _pumpScreen(
  WidgetTester tester, {
  required PracticeSessionScreen screen,
  MetronomeNotifier Function()? metronome,
  List<int>? saves,
  List<List<LadderRound>>? roomSaves,
  List<Override> extraOverrides = const [],
}) async {
  final container = ProviderContainer(overrides: [
    metronomeNotifierProvider
        .overrideWith(metronome ?? () => _IdleMetronomeNotifier()),
    practiceNotifierProvider.overrideWith(
        () => _FakePracticeNotifier(saves ?? <int>[], roomSaves)),
    ...extraOverrides,
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
  bool room = false,
  String? contextLine,
  int? phase,
  int? line,
  String? lines,
  StrokeSource Function()? strokeSource,
  LessonVoice? lessonVoice,
}) =>
    PracticeSessionScreen(
      rudimentId: id ?? rudimentsSeedData.first.id,
      isFromRoutine: false,
      targetBpm: targetBpm,
      targetMinutes: targetMinutes,
      room: room,
      contextLine: contextLine,
      phase: phase,
      line: line,
      lines: lines,
      strokeSource: strokeSource,
      lessonVoice: lessonVoice,
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

  group('lines and sequences', () {
    const sheetId = 'single_paradiddle';
    Rudiment sheetRudiment() =>
        rudimentsSeedData.firstWhere((r) => r.id == sheetId);

    testWidgets('a one-line exercise shows no line bar', (tester) async {
      // A legacy basic rudiment without authored lines (Katalog 3a turned
      // the first twelve into sheets).
      await _pumpScreen(tester, screen: _screen(id: 'multiple_bounce_roll'));
      expect(find.byKey(const ValueKey('line-bar')), findsNothing);
      expect(find.byType(LineView), findsOneWidget);
      // Uli 10.10.: the card nearly fills the width — 6 px margins.
      final rect = tester.getRect(find.byType(LineView));
      expect(rect.left, 6);
      expect(rect.right, 360 - 6);
    });

    testWidgets(
        'a sheet opens on the remembered line, › moves to line 2 and reloads',
        (tester) async {
      final rec = _RecordingMetronomeNotifier();
      await _pumpScreen(tester,
          screen: _screen(id: sheetId), metronome: () => rec);
      expect(find.text('Line 1 of 8'), findsOneWidget);
      final line2 = SheetPlan.line(sheetRudiment(), 1);
      await tester.tap(find.byKey(const ValueKey('line-next')));
      await tester.pump();
      expect(find.text('Line 2 of 8'), findsOneWidget);
      expect(
          rec.volumes.last,
          PatternPlayback.forRudiment(sheetRudiment().withSticking(line2.beats))
              .totalTicks);
      expect(SettingsService.lastLineFor(sheetId), 1);
    });

    testWidgets('?lines=1,3 plays a sequence: each line twice', (tester) async {
      final rec = _RecordingMetronomeNotifier();
      await _pumpScreen(tester,
          screen: _screen(id: sheetId, lines: '1,3'), metronome: () => rec);
      // Two 2-bar lines, each twice.
      expect(rec.volumes.last, 2 * 2 * 2 * 96);
      expect(find.text('Line 1 · 1 of 2 · 1/2'), findsOneWidget);
      expect(find.byKey(const ValueKey('mode-line')), findsNothing);
      expect(find.byKey(const ValueKey('mode-sheet')), findsNothing);
    });

    testWidgets('the sequence advances with the cursor', (tester) async {
      final metronome = _TickingMetronomeNotifier();
      await _pumpScreen(tester,
          screen: _screen(id: sheetId, lines: '1,3'),
          metronome: () => metronome);
      metronome.tickTo(2 * 192);
      await tester.pump();
      expect(find.text('Line 3 · 2 of 2 · 1/2'), findsOneWidget);
      metronome.tickTo(3 * 192);
      await tester.pump();
      expect(find.text('Line 3 · 2 of 2 · 2/2'), findsOneWidget);
    });

    testWidgets('one-line view: only the current line is drawn',
        (tester) async {
      final metronome = _TickingMetronomeNotifier();
      await _pumpScreen(tester,
          screen: _screen(id: sheetId, lines: '1,3'),
          metronome: () => metronome);
      LineView view() => tester.widget<LineView>(find.byType(LineView));
      expect(
          find.descendant(
              of: find.byType(LineView), matching: find.byType(CustomPaint)),
          findsOneWidget);
      expect(view().line, 0);
      metronome.tickTo(2 * 192);
      await tester.pump();
      expect(view().line, 2);
      expect(
          find.descendant(
              of: find.byType(LineView), matching: find.byType(CustomPaint)),
          findsOneWidget);
    });

    testWidgets('› in a running sequence wraps and reloads', (tester) async {
      final rec = _RecordingPlayingMetronomeNotifier();
      await _pumpScreen(tester,
          screen: _screen(id: sheetId, lines: '1,3'), metronome: () => rec);
      final before = rec.volumes.length;
      await tester.tap(find.byKey(const ValueKey('line-next')));
      await tester.pump();
      expect(find.text('Line 3 · 2 of 2 · 1/2'), findsOneWidget);
      expect(rec.volumes.length, before + 1);
      await tester.tap(find.byKey(const ValueKey('line-next')));
      await tester.pump();
      expect(find.text('Line 1 · 1 of 2 · 1/2'), findsOneWidget);
      expect(find.text('Stop'), findsOneWidget);
    });

    testWidgets('the repeats setting is used and capped', (tester) async {
      await SettingsService.setSequenceRepeats(3);
      final rec = _RecordingMetronomeNotifier();
      await _pumpScreen(tester,
          screen: _screen(id: 'fill_sixteenth_singles', lines: 'all'),
          metronome: () => rec);
      // 8 lines × 4 bars × 3 = 96 bars > 64: two passes each.
      expect(rec.volumes.last, 64 * 96);
      expect(find.textContaining(RegExp(r'· 1/2$')), findsOneWidget);
    });

    testWidgets('lines=all on a one-line exercise plays it alone',
        (tester) async {
      await _pumpScreen(tester,
          screen: _screen(id: 'multiple_bounce_roll', lines: 'all'));
      expect(find.byKey(const ValueKey('line-bar')), findsNothing);
      expect(
          find.textContaining(RegExp(r'^Line \d+ · \d+ of')), findsNothing);
    });

    testWidgets('?line=3 opens line 3; ?mode=sheet is ignored', (tester) async {
      final a =
          await _pumpScreen(tester, screen: _screen(id: sheetId, line: 3));
      expect(find.text('Line 3 of 8'), findsOneWidget);
      a.dispose();
      // A fresh State: the same widget type in the same place would keep
      // the old one (and its line) alive.
      await tester.pumpWidget(const SizedBox());
      await SettingsService.setLastLine(sheetId, 4);
      final b = await _pumpScreen(tester,
          screen: const PracticeSessionScreen(
              rudimentId: sheetId,
              isFromRoutine: false,
              lines: null,
              line: null));
      expect(find.text('Line 5 of 8'), findsOneWidget);
      b.dispose();
    });

    testWidgets('opening one line remembers it; a sequence remembers nothing', (
      tester,
    ) async {
      final a = await _pumpScreen(
        tester,
        screen: _screen(id: sheetId, lines: '3'),
      );
      expect(SettingsService.lastLineFor(sheetId), 2);
      a.dispose();
      await tester.pumpWidget(const SizedBox());
      await SettingsService.setLastLine(sheetId, 6);
      final b = await _pumpScreen(
        tester,
        screen: _screen(id: sheetId, lines: '1,3'),
      );
      expect(SettingsService.lastLineFor(sheetId), 6);
      b.dispose();
    });

    testWidgets('› inside a sequence leaves the stored line alone', (
      tester,
    ) async {
      await SettingsService.setLastLine(sheetId, 6);
      await _pumpScreen(tester, screen: _screen(id: sheetId, lines: '1,3'));
      await tester.tap(find.byKey(const ValueKey('line-next')));
      await tester.pump();
      expect(find.text('Line 3 · 2 of 2 · 1/2'), findsOneWidget);
      expect(SettingsService.lastLineFor(sheetId), 6);
    });

    testWidgets('a one-line exercise stores no line', (tester) async {
      await _pumpScreen(tester, screen: _screen(id: 'multiple_bounce_roll'));
      expect(SettingsService.lastLineFor('multiple_bounce_roll'), isNull);
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
      expect(find.text('Line 2 of 8'), findsOneWidget);
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
    // These tests assume the microphone is off unless a test enables it.
    await SettingsService.setMeasurementSource(MeasurementSource.off);
    debugDesktopOverride = false; // phone semantics: auto falls back to mic
    // Phone-sized surface so a layout that overflows on a device fails here.
    final binding = TestWidgetsFlutterBinding.ensureInitialized();
    binding.platformDispatcher.views.first.physicalSize = const Size(1080, 2340);
    binding.platformDispatcher.views.first.devicePixelRatio = 3.0;
  });

  tearDown(() {
    debugDesktopOverride = null;
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
    // The one-line view's paper card is what the eye sees.
    final sheet = tester.getRect(find.byType(LineView));
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

    await SettingsService.setMeasurementSource(MeasurementSource.auto);
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
        screen: _screen(targetBpm: 60, targetMinutes: 8, room: true));
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
    await SettingsService.setMeasurementSource(MeasurementSource.auto);

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
    await SettingsService.setMeasurementSource(MeasurementSource.auto);

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
    await SettingsService.setMeasurementSource(MeasurementSource.auto);
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
    await SettingsService.setMeasurementSource(MeasurementSource.auto);
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
            of: find.byType(LineView),
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

  group('measurement source (Etappe 2 fixes)', () {
    test('extrasAllowed: only the listening mic without headphones mutes '
        'the click in analysis mode', () {
      expect(
          extrasAllowed(
              analysisMode: true, headphones: false, micListens: true),
          isFalse);
      expect(
          extrasAllowed(
              analysisMode: true, headphones: false, micListens: false),
          isTrue);
      expect(
          extrasAllowed(
              analysisMode: true, headphones: true, micListens: true),
          isTrue);
      expect(
          extrasAllowed(
              analysisMode: false, headphones: false, micListens: true),
          isTrue);
    });

    test('measurementStatusText', () {
      String? text({
        bool opening = false,
        StrokeSourceKind? source,
        String? name,
        bool lost = false,
        bool calibrated = true,
      }) =>
          measurementStatusText(
              opening: opening,
              source: source,
              midiDeviceName: name,
              lost: lost,
              latencyCalibrated: calibrated);
      expect(text(opening: true), isNull);
      expect(text(), 'NOT MEASURABLE');
      expect(text(source: StrokeSourceKind.mic), 'MIC');
      expect(text(source: StrokeSourceKind.mic, lost: true), 'NOT MEASURABLE');
      expect(text(source: StrokeSourceKind.midi, name: 'TD-17'), 'MIDI · TD-17');
      expect(
          text(source: StrokeSourceKind.midi, name: 'TD-17', calibrated: false),
          'MIDI · TD-17 · not calibrated');
      expect(text(source: StrokeSourceKind.midi, name: 'TD-17', lost: true),
          'NOT MEASURABLE');
    });

    PracticeSessionScreen midiScreen(FakeMidiPorts ports) =>
        PracticeSessionScreen(
          rudimentId: rudimentsSeedData.first.id,
          isFromRoutine: false,
          ports: ports,
        );

    String statusText(WidgetTester tester) => tester
        .widget<Text>(find.byKey(const ValueKey('measurement-status')))
        .data!;

    testWidgets(
        'MIDI device present: the status line names it and warns about the '
        'missing calibration; analysis mode keeps the click track',
        (tester) async {
      _mockHeadphones(tester, 'none');
      await SettingsService.setMeasurementSource(MeasurementSource.auto);
      final port = FakeMidiPort(deviceName: 'TD-17');
      final container =
          await _pumpScreen(tester, screen: midiScreen(FakeMidiPorts(port: port)));
      await tester.pump();
      expect(statusText(tester), 'MIDI · TD-17 · not calibrated');
      expect(SettingsService.midiLastDeviceId, port.deviceId);

      // Analysis mode, no headphones: MIDI cannot hear the speaker, the
      // click track stays (A1).
      await tester.tap(find.text('LEARN'));
      await tester.pump();
      expect(find.text('ANALYSIS'), findsOneWidget);
      expect(container.read(metronomeNotifierProvider).clickTrack, isTrue);
      expect(container.read(metronomeNotifierProvider).backingStyleId, 'rock8');
      await tester.pumpWidget(const SizedBox());
      container.dispose();
    });

    testWidgets('a calibrated MIDI device shows no warning', (tester) async {
      _mockHeadphones(tester, 'none');
      await SettingsService.setMeasurementSource(MeasurementSource.midi);
      await SettingsService.setMidiLatencyOffsetMsFor('TD-17', 18);
      final container = await _pumpScreen(tester,
          screen: midiScreen(
              FakeMidiPorts(port: FakeMidiPort(deviceName: 'TD-17'))));
      await tester.pump();
      expect(statusText(tester), 'MIDI · TD-17');
      await tester.pumpWidget(const SizedBox());
      container.dispose();
    });

    testWidgets('device lost mid-session: NOT MEASURABLE', (tester) async {
      _mockHeadphones(tester, 'none');
      await SettingsService.setMeasurementSource(MeasurementSource.midi);
      final port = FakeMidiPort(deviceName: 'TD-17');
      final container = await _pumpScreen(tester,
          screen: midiScreen(FakeMidiPorts(port: port)));
      await tester.pump();
      await tester.tap(find.text('Start'));
      await tester.pump();
      port.hit(38);
      port.conn.add(false);
      await tester.pump();
      await tester.pump();
      expect(statusText(tester), 'NOT MEASURABLE');
      await tester.tap(find.text('Stop'));
      await tester.pump();
      await tester.pumpWidget(const SizedBox());
      container.dispose();
    });

    testWidgets('a failing MIDI plugin counts as no source, not a crash',
        (tester) async {
      _mockHeadphones(tester, 'none');
      await SettingsService.setMeasurementSource(MeasurementSource.midi);
      final container = await _pumpScreen(tester,
          screen: midiScreen(FakeMidiPorts(
              port: FakeMidiPort(), openError: StateError('plugin'))));
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(statusText(tester), 'NOT MEASURABLE');
      // Extras were re-applied after the failure: MIDI-only, no mic.
      expect(container.read(metronomeNotifierProvider).backingStyleId, 'rock8');
      await tester.pumpWidget(const SizedBox());
      container.dispose();
    });

    testWidgets('the microphone on the phone: MIC', (tester) async {
      _mockMicPermission(tester);
      _mockHeadphones(tester, 'none');
      await SettingsService.setMeasurementSource(MeasurementSource.auto);
      final container = await _pumpScreen(tester,
          screen: midiScreen(FakeMidiPorts()));
      await tester.pump();
      expect(statusText(tester), 'MIC');
      await tester.pumpWidget(const SizedBox());
      container.dispose();
    });
  });

  group('kit exercises (Etappe 2, Phase B.1)', () {
    List<Override> kitCatalog() => [
          rudimentsProvider
              .overrideWithValue([...rudimentsSeedData, kitShowcase()]),
        ];

    testWidgets('loads the mixed unit: one cycle of every voice', (tester) async {
      final rec = _RecordingMetronomeNotifier();
      await _pumpScreen(tester,
          screen: _screen(id: 'kit_showcase'),
          metronome: () => rec,
          extraOverrides: kitCatalog());
      expect(rec.volumes.last, 2 * 96); // line 1: two bars
      expect(find.byType(LineView), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('a running kit session puts the cursor on a column',
        (tester) async {
      final metronome = _TickingMetronomeNotifier();
      await _pumpScreen(tester,
          screen: _screen(id: 'kit_showcase'),
          metronome: () => metronome,
          extraOverrides: kitCatalog());
      LineView view() => tester.widget<LineView>(find.byType(LineView));
      metronome.tickTo(0);
      await tester.pump();
      expect((view().line, view().activeTick), (0, 0));
      expect(view().activeIndex, isNull);
      metronome.tickTo(96); // bar 2, beat 1 (24 ticks per quarter)
      await tester.pump();
      expect((view().line, view().activeTick), (0, 96));
      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'Backing on: the band plays the line\'s own kick and hi-hat, '
        'no style; off: nothing (S23 test 16.10.)', (tester) async {
      Future<_BackingFlagsMetronomeNotifier> run(bool on) async {
        await SettingsService.setBackingEnabled(on);
        final rec = _BackingFlagsMetronomeNotifier();
        await _pumpScreen(tester,
            screen: _screen(id: 'kit_showcase'),
            metronome: () => rec,
            extraOverrides: kitCatalog());
        await tester.pump();
        await tester.pumpWidget(const SizedBox());
        return rec;
      }

      final on = await run(true);
      expect(on.lastStyleId, isNull);
      // Line 1 of the showcase: hi-hat, snare, kick → hi-hat + kick.
      expect(on.lastKitTracks.map((t) => t.sound),
          unorderedEquals([KitSound.hihat, KitSound.kick]));
      // The pattern sound keeps only the snare: hat/kick ticks are silent.
      expect(on.lastPatternSound![0], 0.0); // hat + kick
      expect(on.lastPatternSound![12], 0.0); // hat alone
      expect(on.lastPatternSound![24], greaterThan(0)); // snare on 2
      final off = await run(false);
      expect(off.lastStyleId, isNull);
      expect(off.lastKitTracks, isEmpty);
      expect(off.lastPatternSound, isNull);
    });

    testWidgets('no microphone listens: the band plays on a phone without '
        'headphones (auto source) — pad exercises keep the mic rule',
        (tester) async {
      _mockMicPermission(tester);
      _mockHeadphones(tester, 'none');
      await SettingsService.setMeasurementSource(MeasurementSource.auto);
      await SettingsService.setBackingEnabled(true);
      Future<_BackingFlagsMetronomeNotifier> run(String id) async {
        final rec = _BackingFlagsMetronomeNotifier();
        await _pumpScreen(tester,
            screen: PracticeSessionScreen(
                rudimentId: id, isFromRoutine: false, ports: FakeMidiPorts()),
            metronome: () => rec,
            extraOverrides: kitCatalog());
        await tester.pump();
        await tester.pumpWidget(const SizedBox());
        return rec;
      }

      final kit = await run('kit_showcase');
      expect(kit.lastKitTracks, isNotEmpty);
      final pad = await run(rudimentsSeedData.first.id);
      expect(pad.lastStyleId, isNull);
      expect(tester.takeException(), isNull);
    });

    testWidgets('the mode chip does not toggle for kit exercises',
        (tester) async {
      await SettingsService.setMeasurementSource(MeasurementSource.midi);
      await _pumpScreen(tester,
          screen: _screen(id: 'kit_showcase'), extraOverrides: kitCatalog());
      await tester.pump();
      final chip = find.byTooltip('Full-kit measurement is not available yet');
      final ink = find.descendant(of: chip, matching: find.byType(InkWell));
      expect(tester.widget<InkWell>(ink).onTap, isNull);
    });

    testWidgets('opens no stroke source even with a MIDI module at hand',
        (tester) async {
      SharedPreferences.setMockInitialValues({'measurement_source': 'midi'});
      await SettingsService.init();
      final port = FakeMidiPort();
      final ports = FakeMidiPorts(port: port);
      await _pumpScreen(tester,
          screen: PracticeSessionScreen(
              rudimentId: 'kit_showcase', isFromRoutine: false, ports: ports),
          extraOverrides: kitCatalog());
      await tester.pump();
      expect(ports.opened, 0);
      expect(find.text('NOT MEASURABLE'), findsOneWidget);
      expect(find.textContaining('MIDI ·'), findsNothing);
    });

    testWidgets('the mode chip explains why: full-kit measurement is not '
        'available yet', (tester) async {
      // The chip shows only with a measurement source chosen (setUp: off).
      await SettingsService.setMeasurementSource(MeasurementSource.midi);
      await _pumpScreen(tester,
          screen: _screen(id: 'kit_showcase'), extraOverrides: kitCatalog());
      await tester.pump();
      expect(find.byTooltip('Full-kit measurement is not available yet'),
          findsOneWidget);
    });

    testWidgets(
        'options: Backing on = the band plays kick and hi-hat with you, '
        'off = click only', (tester) async {
      await _pumpScreen(tester,
          screen: _screen(id: 'kit_showcase'), extraOverrides: kitCatalog());
      await tester.tap(find.byIcon(Icons.more_horiz));
      await tester.pumpAndSettle();
      expect(find.text('Band plays kick and hi-hat with you'), findsOneWidget);
      await tester.tap(find.widgetWithText(SwitchListTile, 'Backing'));
      await tester.pumpAndSettle();
      expect(find.text('Click only'), findsOneWidget);
      expect(SettingsService.backingEnabled, isFalse);
    });
  });

  group('Trainingsraum mode (?room=1)', () {
    final rudiment = rudimentsSeedData.first;
    // The room plays the selected lines once per round.
    final playback = PatternPlayback.forRudiment(rudiment.withSticking(
        SheetPlan.sequence(rudiment, const [0], repeats: 1, start: 0).beats));
    final base = DateTime(2026, 10, 31, 12);

    DateTime at(int globalTick, int bpm) => base.add(Duration(
        microseconds:
            (globalTick * 60000000 / bpm / playback.ticksPerQuarter).round()));

    /// Plays round [round] note by note; [hit] puts a stroke on every note.
    Future<void> playRound(
      WidgetTester tester,
      _RoomMetronomeNotifier met,
      _FakeStrokeSource? src,
      int round, {
      bool hit = true,
      bool everyOther = false,
      double velocity = 1.0,
      int? fromNote,
      int? toNote,
    }) async {
      final bpm = met.state.bpm;
      final onsets = playback.onsetTicks;
      for (var i = fromNote ?? 0; i < (toNote ?? onsets.length); i++) {
        final g = round * playback.totalTicks + onsets[i];
        final t = at(g, bpm);
        if (hit && src != null && (!everyOther || i.isEven)) {
          src.events.add(StrokeEvent(
            timeMs: t.microsecondsSinceEpoch / 1000.0,
            instrument: src.kind == StrokeSourceKind.midi
                ? SettingsService.padRoleInstrument
                : KitInstrument.pad,
            velocity: velocity,
            rawNote: src.kind == StrokeSourceKind.midi ? 38 : null,
            source: src.kind,
          ));
        }
        met.tickTo(g, t);
      }
      await tester.pump();
    }

    /// The first beat of the next round closes round [round].
    Future<void> closeRound(
        WidgetTester tester, _RoomMetronomeNotifier met, int round) async {
      final g = (round + 1) * playback.totalTicks;
      met.tickTo(g, at(g, met.state.bpm));
      await tester.pump();
    }

    Future<({_RoomMetronomeNotifier met, ProviderContainer c})> start(
      WidgetTester tester, {
      required bool room,
      _FakeStrokeSource? src,
      List<int>? saves,
      List<List<LadderRound>>? roomSaves,
      LessonVoice? voice,
      int bpm = 80,
    }) async {
      _mockHeadphones(tester, 'none');
      final met = _RoomMetronomeNotifier();
      final c = await _pumpScreen(tester,
          screen: _screen(
              targetBpm: bpm,
              room: room,
              strokeSource: src == null ? null : () => src,
              lessonVoice: voice ?? _FakeLessonVoice()),
          metronome: () => met,
          saves: saves,
          roomSaves: roomSaves);
      await tester.pump();
      await tester.tap(find.text('Start'));
      await tester.pump();
      await tester.pump();
      return (met: met, c: c);
    }

    Future<void> tearDownScreen(WidgetTester tester) async {
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 5));
    }

    String chipText(WidgetTester tester) => tester
        .widget<Text>(find.descendant(
            of: find.byKey(const Key('room-round-chip')),
            matching: find.byType(Text)))
        .data!;

    testWidgets('room mode raises tempo by 4 after a clean measured round',
        (tester) async {
      final src = _FakeStrokeSource(StrokeSourceKind.midi);
      final s = await start(tester, room: true, src: src);
      await playRound(tester, s.met, src, 0);
      await closeRound(tester, s.met, 0);
      expect(s.c.read(metronomeNotifierProvider).bpm, 84);
      expect(chipText(tester), 'Clean · +4');
      await tearDownScreen(tester);
    });

    testWidgets('room mode keeps tempo when signal too weak', (tester) async {
      final src = _FakeStrokeSource(StrokeSourceKind.mic);
      final s = await start(tester, room: true, src: src);
      await playRound(tester, s.met, src, 0, velocity: 0.001);
      await closeRound(tester, s.met, 0);
      expect(s.c.read(metronomeNotifierProvider).bpm, 80);
      expect(chipText(tester), 'Hold');
      await tearDownScreen(tester);
    });

    testWidgets('a missed round steps down by 4', (tester) async {
      final src = _FakeStrokeSource(StrokeSourceKind.midi);
      final s = await start(tester, room: true, src: src);
      // Every other note missed: hit rate far below 80 %.
      await playRound(tester, s.met, src, 0, everyOther: true);
      await closeRound(tester, s.met, 0);
      expect(s.c.read(metronomeNotifierProvider).bpm, 76);
      expect(chipText(tester), 'Slower · −4');
      await tearDownScreen(tester);
    });

    testWidgets(
        'room mode without measurement asks rating at the end and stores '
        'one round', (tester) async {
      final saves = <int>[];
      final roomSaves = <List<LadderRound>>[];
      final s = await start(tester,
          room: true, saves: saves, roomSaves: roomSaves);
      await playRound(tester, s.met, null, 0);
      await closeRound(tester, s.met, 0);
      await playRound(tester, s.met, null, 1);
      await closeRound(tester, s.met, 1);
      // No measurement: no verdict per round, the tempo stays.
      expect(find.byKey(const Key('room-round-chip')), findsNothing);
      expect(s.c.read(metronomeNotifierProvider).bpm, 80);
      await tester.pump(const Duration(seconds: 2));
      await tester.tap(find.text('Stop'));
      await tester.pump();
      await tester.tap(find.text('Finish'));
      await tester.pumpAndSettle();
      expect(find.text('HOW DID IT FEEL?'), findsOneWidget);
      await tester.tap(find.text('Solid'));
      await tester.pumpAndSettle();
      expect(saves, [3]);
      expect(roomSaves.single.length, 1);
      expect(roomSaves.single.single.bpm, 80);
      expect(roomSaves.single.single.verdict, RoundVerdict.clean);
      await tearDownScreen(tester);
    });

    testWidgets('measured rounds are stored, not the rating', (tester) async {
      final roomSaves = <List<LadderRound>>[];
      final src = _FakeStrokeSource(StrokeSourceKind.midi);
      final s =
          await start(tester, room: true, src: src, roomSaves: roomSaves);
      await playRound(tester, s.met, src, 0);
      await closeRound(tester, s.met, 0);
      await tester.pump(const Duration(seconds: 2));
      await tester.tap(find.text('Stop'));
      await tester.pump();
      await tester.tap(find.text('Finish'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Struggled'));
      await tester.pumpAndSettle();
      expect(roomSaves.single.single.bpm, 80);
      expect(roomSaves.single.single.verdict, RoundVerdict.clean);
      await tearDownScreen(tester);
    });

    testWidgets('manual tempo change mid-round does not count the round',
        (tester) async {
      final src = _FakeStrokeSource(StrokeSourceKind.midi);
      final s = await start(tester, room: true, src: src);
      final half = playback.onsetTicks.length ~/ 2;
      await playRound(tester, s.met, src, 0, toNote: half);
      await tester.tap(find.byIcon(Icons.add));
      await tester.pump();
      final manual = s.c.read(metronomeNotifierProvider).bpm;
      expect(manual, greaterThan(80));
      await playRound(tester, s.met, src, 0, fromNote: half);
      await closeRound(tester, s.met, 0);
      expect(find.byKey(const Key('room-round-chip')), findsNothing);
      expect(s.c.read(metronomeNotifierProvider).bpm, manual);
      // The next full round counts again.
      await playRound(tester, s.met, src, 1);
      await closeRound(tester, s.met, 1);
      expect(chipText(tester), 'Clean · +4');
      expect(s.c.read(metronomeNotifierProvider).bpm, manual + 4);
      await tearDownScreen(tester);
    });

    testWidgets('two clean rounds at the target: Nailed it', (tester) async {
      final src = _FakeStrokeSource(StrokeSourceKind.midi);
      final s = await start(tester,
          room: true, src: src, bpm: rudiment.targetBpm);
      await playRound(tester, s.met, src, 0);
      await closeRound(tester, s.met, 0);
      expect(chipText(tester), 'Clean · +4');
      // The engine restarts the loop at the new tempo on the next "1": the
      // round begun meanwhile (1) is cut short and does not count.
      await playRound(tester, s.met, src, 2);
      await closeRound(tester, s.met, 2);
      expect(chipText(tester), 'Nailed it');
      await tester.pump(const Duration(seconds: 2));
      await tester.tap(find.text('Stop'));
      await tester.pump();
      await tester.tap(find.text('Finish'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Nailed it'), findsOneWidget);
      await tearDownScreen(tester);
    });

    testWidgets('how to play never opens by itself', (tester) async {
      final voice = _FakeLessonVoice(clips: {lessonClipId(rudiment.id)});
      final src = _FakeStrokeSource(StrokeSourceKind.midi);
      final s = await start(tester, room: true, src: src, voice: voice);
      final title = rudiment.technique.first.title;
      await playRound(tester, s.met, src, 0);
      await closeRound(tester, s.met, 0);
      await tester.pump(const Duration(seconds: 5));
      expect(find.text(title), findsNothing);
      expect(voice.played, isEmpty);

      await tester.tap(find.byKey(const Key('room-how-to')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text(title), findsOneWidget);
      expect(voice.played, isEmpty, reason: 'the voice waits for its button');
      await tester.tap(find.byKey(const Key('room-how-to-play')));
      await tester.pump();
      expect(voice.played, [lessonClipId(rudiment.id)]);
      await tearDownScreen(tester);
    });

    testWidgets('how to play without a clip shows only the text',
        (tester) async {
      await start(tester, room: true);
      await tester.tap(find.byKey(const Key('room-how-to')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text(rudiment.technique.first.title), findsOneWidget);
      expect(find.byKey(const Key('room-how-to-play')), findsNothing);
      await tearDownScreen(tester);
    });

    testWidgets('normal mode has no round chip', (tester) async {
      final src = _FakeStrokeSource(StrokeSourceKind.midi);
      final s = await start(tester, room: false, src: src);
      await playRound(tester, s.met, src, 0);
      await closeRound(tester, s.met, 0);
      expect(find.byKey(const Key('room-round-chip')), findsNothing);
      expect(find.byKey(const Key('room-how-to')), findsNothing);
      expect(s.c.read(metronomeNotifierProvider).bpm, 80);
      await tearDownScreen(tester);
    });
  });
}
