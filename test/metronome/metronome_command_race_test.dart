import 'package:drum_coach/features/metronome/metronome_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
      'commands sent before the engine finished initializing are not lost '
      '(cold-start race: UI shows 197 BPM, isolate keeps ticking at 100)',
      () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final notifier = container.read(metronomeNotifierProvider.notifier);
    // Simulate the practice screen's post-frame callback firing before the
    // async engine init completes (app cold start, fast navigation).
    notifier
      ..setPatternClock(24)
      ..setBpm(197);

    // Let the deferred init run (SoLoud is unavailable in tests, so init
    // aborts early — the engine object must exist and carry the values
    // regardless).
    await pumpEventQueue();

    final engine = notifier.debugEngine;
    expect(engine, isNotNull,
        reason: 'engine must exist as soon as the notifier is built');
    expect(engine!.debugBpm, 197,
        reason: 'BPM sent before init-completion must not be dropped');
    expect(engine.debugFactor, 24,
        reason: 'pattern clock sent before init-completion must not be dropped');
  });
}
