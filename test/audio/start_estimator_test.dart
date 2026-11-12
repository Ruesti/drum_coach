import 'dart:math';

import 'package:drum_coach/audio/start_estimator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('empty samples → null', () {
    expect(estimateStartMs(const []), isNull);
  });

  test('takes the minimum of now − position', () {
    expect(
        estimateStartMs(const [
          (nowMs: 105, positionMs: 0),
          (nowMs: 150, positionMs: 48),
          (nowMs: 160, positionMs: 48),
        ]),
        102);
  });

  test(
      'positions quantised to 2048/48000 s, random scheduling delay → '
      'estimate within one quantum of the true start, never earlier', () {
    const quantumMs = 2048 / 48000 * 1000; // ≈ 42.67 ms
    for (var seed = 0; seed < 200; seed++) {
      final rnd = Random(seed);
      final trueStart = 1.7e12 + rnd.nextDouble() * 1000;
      // play() returns somewhere inside the first buffer.
      var now = trueStart + rnd.nextDouble() * quantumMs;
      final samples = <({double nowMs, double positionMs})>[];
      while (now < trueStart + 250) {
        // Position advances in whole buffers and lags behind wall time.
        final pos = ((now - trueStart) / quantumMs).floor() * quantumMs;
        samples.add((nowMs: now, positionMs: pos));
        now += 5 + rnd.nextDouble() * 5 + (rnd.nextInt(10) == 0 ? 20 : 0);
      }
      final est = estimateStartMs(samples)!;
      expect(est, greaterThanOrEqualTo(trueStart - 0.01), reason: 'seed $seed');
      expect(est, lessThan(trueStart + quantumMs), reason: 'seed $seed');
    }
  });
}
