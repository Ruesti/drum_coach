import 'package:drum_coach/features/room/round_verdict.dart';
import 'package:drum_coach/features/room/tempo_ladder.dart';
import 'package:flutter_test/flutter_test.dart';

LadderRound r(int bpm, RoundVerdict v) => LadderRound(bpm: bpm, verdict: v);

void main() {
  test('ladder +4/0/-4', () {
    expect(nextLadderBpm(80, RoundVerdict.clean, minBpm: 60), 84);
    expect(nextLadderBpm(80, RoundVerdict.close, minBpm: 60), 80);
    expect(nextLadderBpm(80, RoundVerdict.off, minBpm: 60), 76);
  });
  test('ladder never below minBpm nor 40', () {
    expect(nextLadderBpm(62, RoundVerdict.off, minBpm: 60), 60);
    expect(nextLadderBpm(42, RoundVerdict.off, minBpm: 20), 40);
  });
  test('ladder never above 240', () {
    expect(nextLadderBpm(238, RoundVerdict.clean, minBpm: 60), 240);
  });
  test('sits after two clean rounds at target', () {
    expect(
        sitsAt([r(100, RoundVerdict.clean), r(104, RoundVerdict.clean)], 100),
        isTrue);
  });
  test('does not sit when one of the two is below target', () {
    expect(
        sitsAt([r(96, RoundVerdict.clean), r(100, RoundVerdict.clean)], 100),
        isFalse);
  });
  test('does not sit after clean-close-clean', () {
    expect(
        sitsAt([
          r(100, RoundVerdict.clean),
          r(100, RoundVerdict.close),
          r(100, RoundVerdict.clean)
        ], 100),
        isFalse);
  });
  test('does not sit with fewer than two rounds', () {
    expect(sitsAt([r(100, RoundVerdict.clean)], 100), isFalse);
  });
}
