import 'package:drum_coach/features/coaching/midi/kit_instrument.dart';
import 'package:drum_coach/features/coaching/services/stroke_source.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('SensorLevel: midi satisfies mic, mic does not satisfy midi', () {
    expect(SensorLevel.none.satisfiedBy(null), isTrue);
    expect(SensorLevel.mic.satisfiedBy(null), isFalse);
    expect(SensorLevel.mic.satisfiedBy(StrokeSourceKind.mic), isTrue);
    expect(SensorLevel.mic.satisfiedBy(StrokeSourceKind.midi), isTrue);
    expect(SensorLevel.midi.satisfiedBy(StrokeSourceKind.mic), isFalse);
    expect(SensorLevel.midi.satisfiedBy(StrokeSourceKind.midi), isTrue);
  });

  test('StrokeEvent is a plain value with raw epoch time', () {
    const e = StrokeEvent(
      timeMs: 1700000000000.25,
      instrument: KitInstrument.snare,
      velocity: 0.8,
      rawNote: 38,
      source: StrokeSourceKind.midi,
    );
    expect(e.timeMs, 1700000000000.25);
    expect(e.instrument, KitInstrument.snare);
    expect(e.source, StrokeSourceKind.midi);
    expect(e.toString(), contains('snare'));
  });
}
