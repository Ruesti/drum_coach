import 'package:drum_coach/data/local/settings_service.dart';
import 'package:drum_coach/features/lessons/data/rudiments_seed.dart';
import 'package:drum_coach/features/metronome/metronome_provider.dart';
import 'package:drum_coach/features/practice/practice_session_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Overrides [MetronomeNotifier] so its very first `build()` already reports
/// the metronome as playing mid-pattern — exactly the state a real device
/// hits when [PracticeSessionScreen] is pushed while the keep-alive metronome
/// provider is already running from an earlier screen. The real engine is
/// never touched (no SoLoud / isolate), so this stays a fast, hermetic
/// widget test.
class _AlreadyPlayingMetronomeNotifier extends MetronomeNotifier {
  @override
  MetronomeState build() {
    return const MetronomeState(isPlaying: true, currentBeatIndex: 0);
  }
}

/// Idle metronome without engine/SoLoud so preset logic runs hermetically.
class _IdleMetronomeNotifier extends MetronomeNotifier {
  @override
  MetronomeState build() => const MetronomeState();
}

Future<void> _pumpScreen(
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
}

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await SettingsService.init();
  });

  testWidgets(
      'does not throw LateInitializationError when the metronome is already '
      'playing on first build (regression for _playback being set only in a '
      'postFrameCallback)', (tester) async {
    final container = ProviderContainer(overrides: [
      metronomeNotifierProvider
          .overrideWith(() => _AlreadyPlayingMetronomeNotifier()),
    ]);
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: PracticeSessionScreen(
            rudimentId: rudimentsSeedData.first.id,
            isFromRoutine: false,
          ),
        ),
      ),
    );

    // The first build() must read `_playback` while the provider already
    // reports isPlaying == true and currentBeatIndex == 0 — before this
    // fix, `_playback` was still unset at this point and build() threw a
    // LateInitializationError.
    expect(tester.takeException(), isNull);
    expect(find.byType(PracticeSessionScreen), findsOneWidget);

    // Let the postFrameCallback (metronome clock/volume setup) run too.
    await tester.pump();
    expect(tester.takeException(), isNull);

    // Dispose before the test ends, not just via addTearDown — the session
    // timer's real Timer.periodic (started in initState) must be cancelled
    // inside the test body, or flutter_test's "no pending timers" invariant
    // check (which runs before tearDowns) fails.
    container.dispose();
  });

  testWidgets('übernimmt die vorgeschlagene Blockdauer als Countdown-Ziel',
      (tester) async {
    await _pumpScreen(
      tester,
      screen: PracticeSessionScreen(
        rudimentId: rudimentsSeedData.first.id,
        isFromRoutine: false,
        targetMinutes: 4,
      ),
    );
    await tester.pump();
    // Countdown preset to 4 min and offered as an explicit chip.
    expect(find.text('04:00'), findsOneWidget);
    expect(find.text('4 min ✦'), findsOneWidget);
  });

  testWidgets('Leiter-Modus zeigt die Stufen und startet auf der untersten',
      (tester) async {
    await _pumpScreen(
      tester,
      screen: PracticeSessionScreen(
        rudimentId: rudimentsSeedData.first.id,
        isFromRoutine: false,
        targetBpm: 80,
        targetMinutes: 4,
        isLadder: true,
      ),
    );
    await tester.pump();
    expect(find.text('Tempo-Leiter'), findsOneWidget);
    for (final bpm in ['76', '80', '84']) {
      expect(find.text(bpm), findsOneWidget);
    }
    // Metronome preset to the lowest ladder step — 72 appears in the BPM
    // display AND its step chip.
    expect(find.text('72'), findsNWidgets(2));
  });

  testWidgets('stellt eine unterbrochene Session aus dem Snapshot wieder her',
      (tester) async {
    SharedPreferences.setMockInitialValues({
      'practice_snap_id': rudimentsSeedData.first.id,
      'practice_snap_elapsed': 200,
      'practice_snap_time': DateTime.now().toIso8601String(),
    });
    await SettingsService.init();

    await _pumpScreen(
      tester,
      screen: PracticeSessionScreen(
        rudimentId: rudimentsSeedData.first.id,
        isFromRoutine: false,
      ),
    );
    await tester.pump();
    // Elapsed timer restored (03:20 count-up) + hint shown.
    expect(find.text('03:20'), findsOneWidget);
    expect(find.textContaining('fortgesetzt'), findsOneWidget);
  });

  testWidgets('abgelaufener Snapshot wird ignoriert', (tester) async {
    SharedPreferences.setMockInitialValues({
      'practice_snap_id': rudimentsSeedData.first.id,
      'practice_snap_elapsed': 200,
      'practice_snap_time': DateTime.now()
          .subtract(const Duration(hours: 2))
          .toIso8601String(),
    });
    await SettingsService.init();

    await _pumpScreen(
      tester,
      screen: PracticeSessionScreen(
        rudimentId: rudimentsSeedData.first.id,
        isFromRoutine: false,
      ),
    );
    await tester.pump();
    expect(find.text('00:00'), findsOneWidget);
  });
}
