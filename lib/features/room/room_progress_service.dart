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
  ///
  /// `mastered` comes ONLY from "sitting" (two clean rounds in a row at
  /// [targetBpm]); the best-tempo ratio stops at `proficient`, and a row
  /// that is mastered stays so. [sits] overrides the check over [rounds]
  /// (the screen knows where a streak was broken by an unmeasured or
  /// dropped round). [fromRating]: the round is a self rating (no
  /// measurement) — then it sits across sessions: Solid at the target now
  /// while the stored best tempo already reached it before.
  RudimentProgress applyRounds(
    RudimentProgress p,
    List<LadderRound> rounds, {
    required int targetBpm,
    required int minBpm,
    bool? sits,
    bool fromRating = false,
  }) {
    if (rounds.isEmpty) return p;
    final last = rounds.last;
    final previousBest = p.bestBpm;
    p.currentBpm = nextLadderBpm(last.bpm, last.verdict, minBpm: minBpm);
    for (final r in rounds) {
      if (r.verdict == RoundVerdict.clean && r.bpm > p.bestBpm) {
        p.bestBpm = r.bpm;
      }
    }
    final sat = (sits ?? sitsInSession(rounds, targetBpm)) ||
        (fromRating &&
            last.verdict == RoundVerdict.clean &&
            last.bpm >= targetBpm &&
            previousBest >= targetBpm);
    p.mastery = sat || p.mastery == MasteryLevel.mastered
        ? MasteryLevel.mastered
        : _mastery(p.bestBpm, targetBpm);
    final rating = sat
        ? 3
        : last.verdict == RoundVerdict.off
            ? 1
            : 2;
    const SpacedRepetitionService().updateAfterSession(p, rating);
    return p;
  }

  /// The steps of `BpmProgressionService` (best tempo / target), capped
  /// at `proficient`: reaching the target once is not sitting.
  MasteryLevel _mastery(int bestBpm, int targetBpm) {
    final ratio = bestBpm / targetBpm;
    if (ratio >= 0.85) return MasteryLevel.proficient;
    if (ratio >= 0.65) return MasteryLevel.competent;
    if (ratio >= 0.40) return MasteryLevel.developing;
    return MasteryLevel.beginner;
  }
}
