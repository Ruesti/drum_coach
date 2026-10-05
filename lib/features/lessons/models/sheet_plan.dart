import 'rudiment.dart';

/// What the practice screen plays and measures: one line of the sheet, or
/// all lines in order (each once). A flat note list plus the map back to
/// (line, index in line) for the cursor. Pure.
class SheetPlan {
  final List<StrokeBeat> beats;

  /// Note index at which each covered line starts (parallel to [lines]).
  final List<int> lineStarts;

  /// Sheet line indices covered, in play order.
  final List<int> lines;
  final bool wholeSheet;

  const SheetPlan._({
    required this.beats,
    required this.lineStarts,
    required this.lines,
    required this.wholeSheet,
  });

  /// The one line [lineIndex] (clamped into the sheet).
  factory SheetPlan.line(Rudiment r, int lineIndex) {
    final sheet = r.sheet;
    final i = lineIndex.clamp(0, sheet.length - 1);
    return SheetPlan._(
      beats: sheet[i].beats,
      lineStarts: const [0],
      lines: [i],
      wholeSheet: false,
    );
  }

  /// Every line once, in order.
  factory SheetPlan.wholeSheet(Rudiment r) {
    final sheet = r.sheet;
    final beats = <StrokeBeat>[];
    final starts = <int>[];
    for (final l in sheet) {
      starts.add(beats.length);
      beats.addAll(l.beats);
    }
    return SheetPlan._(
      beats: beats,
      lineStarts: starts,
      lines: [for (var i = 0; i < sheet.length; i++) i],
      wholeSheet: true,
    );
  }

  /// The selected line (line mode) or the first line (sheet mode).
  int get lineIndex => lines.first;

  /// Sheet line and index within it for a note index of [beats].
  ({int line, int index}) locate(int noteIndex) {
    var k = 0;
    while (k + 1 < lineStarts.length && lineStarts[k + 1] <= noteIndex) {
      k++;
    }
    return (line: lines[k], index: noteIndex - lineStarts[k]);
  }
}

/// Whole bars a note list spans (ceil; 0 for nothing). Never throws — for
/// labels, not for validation (`barCountOrThrow` does that).
int barsOf(List<StrokeBeat> beats,
    {required NoteGrid grid, required int beatsPerBar}) {
  var quarters = 0.0;
  for (final b in beats) {
    quarters += resolveNote(b, grid).quarters;
  }
  return (quarters / beatsPerBar - 1e-9).ceil().clamp(0, 1 << 30);
}

/// Bars of the whole sheet (each line once).
int sheetBars(Rudiment r) => r.sheet.fold(
    0,
    (n, l) =>
        n + barsOf(l.beats, grid: r.gridUnit, beatsPerBar: r.beatsPerBar));
