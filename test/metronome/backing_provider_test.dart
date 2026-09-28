import 'package:drum_coach/features/metronome/metronome_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// No engine (no SoLoud) — the setters are engine-null-safe.
class _IdleMetronomeNotifier extends MetronomeNotifier {
  @override
  MetronomeState build() => const MetronomeState();
}

void main() {
  late ProviderContainer container;
  setUp(() {
    container = ProviderContainer(overrides: [
      metronomeNotifierProvider.overrideWith(() => _IdleMetronomeNotifier()),
    ]);
    addTearDown(container.dispose);
  });

  test('backing is off with level 0.7 until a screen chooses a style', () {
    final s = container.read(metronomeNotifierProvider);
    expect(s.backingStyleId, isNull);
    expect(s.backingLevel, 0.7);
  });

  test('setBacking stores the style id, unknown ids become off', () {
    final n = container.read(metronomeNotifierProvider.notifier);
    n.setBacking('rock8', beatsPerBar: 4);
    expect(container.read(metronomeNotifierProvider).backingStyleId, 'rock8');
    n.setBacking('bossa', beatsPerBar: 4);
    expect(container.read(metronomeNotifierProvider).backingStyleId, isNull);
    n.setBacking(null, beatsPerBar: 4);
    expect(container.read(metronomeNotifierProvider).backingStyleId, isNull);
  });

  test('setBackingLevel clamps to 0..1', () {
    final n = container.read(metronomeNotifierProvider.notifier);
    n.setBackingLevel(0.3);
    expect(container.read(metronomeNotifierProvider).backingLevel, 0.3);
    n.setBackingLevel(1.7);
    expect(container.read(metronomeNotifierProvider).backingLevel, 1.0);
    n.setBackingLevel(-1);
    expect(container.read(metronomeNotifierProvider).backingLevel, 0.0);
  });

  test('an audio route change bumps a counter screens can listen to', () {
    final n = container.read(metronomeNotifierProvider.notifier);
    expect(container.read(metronomeNotifierProvider).audioRouteChanges, 0);
    n.notifyAudioRouteChanged();
    n.notifyAudioRouteChanged();
    expect(container.read(metronomeNotifierProvider).audioRouteChanges, 2);
  });
}
