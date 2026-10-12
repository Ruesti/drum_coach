import 'package:drum_coach/features/coaching/services/stroke_source.dart';
import 'package:drum_coach/features/lessons/models/rudiment.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const r = Rudiment(
    id: 'x',
    name: 'X',
    description: '',
    minBpm: 60,
    targetBpm: 120,
    difficulty: Difficulty.beginner,
    sticking: [StrokeBeat(hand: Hand.right), StrokeBeat(hand: Hand.left)],
  );

  test('pad exercises require the microphone level by default', () {
    expect(r.requiredSensor, SensorLevel.mic);
  });

  test('withSticking keeps the sensor level', () {
    const kit = Rudiment(
      id: 'k',
      name: 'K',
      description: '',
      minBpm: 60,
      targetBpm: 120,
      difficulty: Difficulty.beginner,
      sticking: [StrokeBeat(hand: Hand.right)],
      requiredSensor: SensorLevel.midi,
    );
    expect(kit.withSticking(const [StrokeBeat(hand: Hand.left)]).requiredSensor,
        SensorLevel.midi);
  });
}
