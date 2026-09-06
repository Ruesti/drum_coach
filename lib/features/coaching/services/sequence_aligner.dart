/// Global sequence alignment of expected note times against detected onsets
/// (Brief Etappe 1, §1.2): replaces nearest-neighbor matching so omissions,
/// insertions and early/late strokes are recognized as such.
library;

/// One expected note after alignment: either hit by exactly one onset or
/// missed.
class AlignedNote {
  final int noteIndex;
  final double expectedMs;
  final int? onsetIndex;
  final double? deviationMs;

  const AlignedNote({
    required this.noteIndex,
    required this.expectedMs,
    this.onsetIndex,
    this.deviationMs,
  });

  bool get hit => onsetIndex != null;
}

class AlignmentResult {
  final List<AlignedNote> notes;
  final List<int> extraOnsetIndices;

  const AlignmentResult({required this.notes, required this.extraOnsetIndices});

  int get hitCount => notes.where((n) => n.hit).length;
  int get missedCount => notes.length - hitCount;
  int get extraCount => extraOnsetIndices.length;

  double get hitRate => notes.isEmpty ? 0 : hitCount / notes.length;
  double get extraRate => notes.isEmpty ? 0 : extraCount / notes.length;

  /// Confidence gate from §1.2: below this, no per-hand values are reported.
  bool get handValuesAllowed => hitRate >= 0.9 && extraRate < 0.05;
}

/// Needleman-Wunsch-style alignment. Match cost is the absolute time
/// deviation (only allowed within [maxMatchDevMs]); leaving a note unmatched
/// (omission) or an onset unmatched (insertion) costs [gapCostMs] each.
/// Monotone and one-to-one by construction: an early stroke stays on its own
/// note instead of stealing the temporally nearer neighbor.
AlignmentResult alignSequences({
  required List<double> expectedMs,
  required List<double> onsetMs,
  double maxMatchDevMs = 250,
  double gapCostMs = 200,
}) {
  final n = expectedMs.length;
  final m = onsetMs.length;

  const infinity = double.infinity;
  final cost = List.generate(n + 1, (_) => List.filled(m + 1, infinity));
  // 0 = start, 1 = match (diagonal), 2 = miss note (up), 3 = extra onset (left)
  final step = List.generate(n + 1, (_) => List.filled(m + 1, 0));

  cost[0][0] = 0;
  for (var i = 1; i <= n; i++) {
    cost[i][0] = i * gapCostMs;
    step[i][0] = 2;
  }
  for (var j = 1; j <= m; j++) {
    cost[0][j] = j * gapCostMs;
    step[0][j] = 3;
  }

  for (var i = 1; i <= n; i++) {
    for (var j = 1; j <= m; j++) {
      final dev = (onsetMs[j - 1] - expectedMs[i - 1]).abs();
      var best = cost[i - 1][j] + gapCostMs;
      var bestStep = 2;
      final extra = cost[i][j - 1] + gapCostMs;
      if (extra < best) {
        best = extra;
        bestStep = 3;
      }
      if (dev <= maxMatchDevMs) {
        final match = cost[i - 1][j - 1] + dev;
        if (match < best) {
          best = match;
          bestStep = 1;
        }
      }
      cost[i][j] = best;
      step[i][j] = bestStep;
    }
  }

  final matchedOnsetByNote = List<int?>.filled(n, null);
  final matchedOnsets = <int>{};
  var i = n, j = m;
  while (i > 0 || j > 0) {
    switch (step[i][j]) {
      case 1:
        matchedOnsetByNote[i - 1] = j - 1;
        matchedOnsets.add(j - 1);
        i--;
        j--;
      case 2:
        i--;
      default:
        j--;
    }
  }

  final notes = [
    for (var k = 0; k < n; k++)
      AlignedNote(
        noteIndex: k,
        expectedMs: expectedMs[k],
        onsetIndex: matchedOnsetByNote[k],
        deviationMs: matchedOnsetByNote[k] == null
            ? null
            : onsetMs[matchedOnsetByNote[k]!] - expectedMs[k],
      ),
  ];
  final extras = [
    for (var k = 0; k < m; k++)
      if (!matchedOnsets.contains(k)) k,
  ];
  return AlignmentResult(notes: notes, extraOnsetIndices: extras);
}
