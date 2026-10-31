import '../../data/local/models/rudiment_progress.dart';
import '../learning/spaced_repetition_service.dart';
import 'round_verdict.dart';
import 'tempo_ladder.dart';

/// Whether two clean rounds at [targetBpm] followed each other anywhere in
/// [rounds] (the session may go on faster afterwards).
bool sitsInSession(List<LadderRound> rounds, int targetBpm) {
  for (var i = 2; i <= rounds.length; i++) {
    if (sitsAt(rounds.sublist(0, i), targetBpm)) return true;
  }
  return false;
}

/// Progress after a Trainingsraum session: the tempo ladder replaces the
/// old +5 / +2 progression; old rows stay valid (same fields).
class RoomProgressService {
  const RoomProgressService();

  /// Mutates [p] in place and returns it. No rounds: unchanged.
  RudimentProgress applyRounds(
    RudimentProgress p,
    List<LadderRound> rounds, {
    required int targetBpm,
    required int minBpm,
  }) {
    if (rounds.isEmpty) return p;
    final last = rounds.last;
    p.currentBpm = nextLadderBpm(last.bpm, last.verdict, minBpm: minBpm);
    for (final r in rounds) {
      if (r.verdict == RoundVerdict.clean && r.bpm > p.bestBpm) {
        p.bestBpm = r.bpm;
      }
    }
    final sits = sitsInSession(rounds, targetBpm);
    p.mastery = sits ? MasteryLevel.mastered : _mastery(p.bestBpm, targetBpm);
    final rating = sits
        ? 3
        : last.verdict == RoundVerdict.off
            ? 1
            : 2;
    const SpacedRepetitionService().updateAfterSession(p, rating);
    return p;
  }

  /// Same steps as `BpmProgressionService` (best tempo / target).
  MasteryLevel _mastery(int bestBpm, int targetBpm) {
    final ratio = bestBpm / targetBpm;
    if (ratio >= 1.0) return MasteryLevel.mastered;
    if (ratio >= 0.85) return MasteryLevel.proficient;
    if (ratio >= 0.65) return MasteryLevel.competent;
    if (ratio >= 0.40) return MasteryLevel.developing;
    return MasteryLevel.beginner;
  }
}
