import 'package:drum_coach/features/metronome/metronome_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// No engine (no SoLoud) — the setters are engine-null-safe.
class _IdleMetronomeNotifier extends MetronomeNotifier {
  @override
  MetronomeState build() => const MetronomeState();
}

void main() {
  test('click track is off until a screen asks for it, then toggles', () {
    final container = ProviderContainer(overrides: [
      metronomeNotifierProvider.overrideWith(() => _IdleMetronomeNotifier()),
    ]);
    addTearDown(container.dispose);

    expect(container.read(metronomeNotifierProvider).clickTrack, isFalse);
    container.read(metronomeNotifierProvider.notifier).setClickTrack(true);
    expect(container.read(metronomeNotifierProvider).clickTrack, isTrue);
    container.read(metronomeNotifierProvider.notifier).setClickTrack(false);
    expect(container.read(metronomeNotifierProvider).clickTrack, isFalse);
  });
}
