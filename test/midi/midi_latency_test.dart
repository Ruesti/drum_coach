import 'package:drum_coach/features/coaching/midi/midi_latency.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final clicks = [for (var i = 0; i < 16; i++) 1000.0 + i * 600];

  test('steady player 18 ms late: offset 18, small spread, sure', () {
    final r = estimateMidiLatency(
      clickMs: clicks,
      strokeMs: [for (final c in clicks) c + 18 + (c % 2 == 0 ? 1 : -1)],
    )!;
    expect(r.offsetMs, closeTo(18, 1.5));
    expect(r.spreadMs, lessThan(10));
    expect(r.unsure, isFalse);
    expect(r.matched, 16);
    expect(r.clicks, 16);
  });

  test('wobbly player: spread above 10 ms flags unsure', () {
    final r = estimateMidiLatency(
      clickMs: clicks,
      strokeMs: [
        for (var i = 0; i < 16; i++) clicks[i] + 18 + (i < 8 ? -12 : 12)
      ],
    )!;
    expect(r.unsure, isTrue);
  });

  test('nothing played: null', () {
    expect(estimateMidiLatency(clickMs: clicks, strokeMs: const []), isNull);
  });
}
