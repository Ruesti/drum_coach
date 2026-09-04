/// Pure in-session tempo-ladder plan (§6): a ladder block climbs in equal
/// time steps from below the gate tempo up to gate + 4 — the tempo the clean
/// pass would establish as the next stored clean tempo.
library;

/// BPM offsets of the ladder steps relative to the gate tempo.
const _stepOffsets = [-8, -4, 0, 4];

class LadderPlan {
  /// Ascending step tempos (deduplicated after clamping to the 40–240 range).
  final List<int> bpms;
  final int totalSeconds;

  const LadderPlan({required this.bpms, required this.totalSeconds});

  int get stepSeconds => totalSeconds ~/ bpms.length;

  int stepIndexAt(int elapsedSeconds) {
    if (stepSeconds <= 0) return bpms.length - 1;
    return (elapsedSeconds ~/ stepSeconds).clamp(0, bpms.length - 1);
  }

  int bpmAt(int elapsedSeconds) => bpms[stepIndexAt(elapsedSeconds)];
}

LadderPlan buildLadderPlan({required int startBpm, required int totalSeconds}) {
  final bpms = <int>[];
  for (final offset in _stepOffsets) {
    final bpm = (startBpm + offset).clamp(40, 240);
    if (bpms.isEmpty || bpms.last != bpm) bpms.add(bpm);
  }
  return LadderPlan(bpms: bpms, totalSeconds: totalSeconds);
}
