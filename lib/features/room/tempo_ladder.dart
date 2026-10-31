import 'round_verdict.dart';

const int kLadderStep = 4;
const int kLadderAbsMinBpm = 40;
const int kLadderAbsMaxBpm = 240;

class LadderRound {
  final int bpm;
  final RoundVerdict verdict;
  const LadderRound({required this.bpm, required this.verdict});
}

/// Next round's tempo: +4 after clean, same after close, -4 after off;
/// never below [minBpm] (or 40), never above 240.
int nextLadderBpm(int bpm, RoundVerdict v, {required int minBpm}) {
  final next = switch (v) {
    RoundVerdict.clean => bpm + kLadderStep,
    RoundVerdict.close => bpm,
    RoundVerdict.off => bpm - kLadderStep,
  };
  final floor = minBpm > kLadderAbsMinBpm ? minBpm : kLadderAbsMinBpm;
  return next.clamp(floor, kLadderAbsMaxBpm);
}

/// "Sits": the last two rounds are both clean and both at/above [targetBpm].
bool sitsAt(List<LadderRound> rounds, int targetBpm) {
  if (rounds.length < 2) return false;
  return rounds
      .sublist(rounds.length - 2)
      .every((r) => r.verdict == RoundVerdict.clean && r.bpm >= targetBpm);
}
