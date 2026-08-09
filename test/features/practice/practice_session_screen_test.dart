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
  });
}
