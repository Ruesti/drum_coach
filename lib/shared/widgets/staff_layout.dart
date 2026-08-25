import '../../features/lessons/models/rudiment.dart';

/// Beam/flag count for a note value (0 = stem only, no beam/flag).
int beamCountFor(NoteValue v) => switch (v) {
      NoteValue.eighth => 1,
      NoteValue.sixteenth => 2,
      NoteValue.thirtySecond => 3,
      _ => 0,
    };

class NotePlacement {
  final int index;
  final int row;
  final int bar;
  final double xCenter; // px within the row's coordinate space
  final ResolvedNote resolved;
  final bool isRest;
  const NotePlacement({
    required this.index,
    required this.row,
    required this.bar,
    required this.xCenter,
    required this.resolved,
    required this.isRest,
  });
}

class BeamGroup {
  final int row;
  final int startIndex; // inclusive, into beats
  final int endIndex;   // inclusive
  final int beamCount;
  final Tuplet tuplet;
  const BeamGroup({
    required this.row,
    required this.startIndex,
    required this.endIndex,
    required this.beamCount,
    required this.tuplet,
  });
}

class StaffLayout {
  final int rowCount;
  final double pxPerQuarter;
  final int beatsPerBar;
  final int barsPerRow;
  final List<NotePlacement> placements;
  final List<BeamGroup> beams;
  const StaffLayout({
    required this.rowCount,
    required this.pxPerQuarter,
    required this.beatsPerBar,
    required this.barsPerRow,
    required this.placements,
    required this.beams,
  });
}

const int _ticksPerQuarter = 24; // integer layout math, matches PatternPlayback

StaffLayout computeStaffLayout({
  required List<StrokeBeat> beats,
  required NoteGrid grid,
  required int beatsPerBar,
  required double maxWidth,
  double leftPad = 10,
  double rightPad = 14,
  double systemPad = 40,
  double barGap = 14,
  double preferredPxPerQuarter = 56,
  int targetBarsPerRow = 2,
}) {
  final ticksPerBar = beatsPerBar * _ticksPerQuarter;
  final usable = maxWidth - leftPad - rightPad - systemPad;

  double barWidthAt(double pxq) => beatsPerBar * pxq + barGap;

  // Rows are a fixed [targetBarsPerRow] bars wide — note width flexes to
  // fit, rather than note width staying fixed and the bar count per row
  // flexing. Matches printed sheet music: a consistent line length instead
  // of "however many bars happen to fit at a comfortable size".
  var barsPerRow = targetBarsPerRow;
  const minPxPerQuarter = 8.0;
  var pxPerQuarter =
      ((usable / barsPerRow - barGap) / beatsPerBar).clamp(0.0, preferredPxPerQuarter);
  if (pxPerQuarter < minPxPerQuarter) {
    // Even at the minimum readable size, [targetBarsPerRow] bars don't fit
    // (very narrow viewport) — fall back to one bar per row.
    barsPerRow = 1;
    pxPerQuarter = ((usable - barGap) / beatsPerBar).clamp(minPxPerQuarter, preferredPxPerQuarter);
  }

  final placements = <NotePlacement>[];
  var tickCursor = 0;
  for (var i = 0; i < beats.length; i++) {
    final resolved = resolveNote(beats[i], grid);
    final bar = tickCursor ~/ ticksPerBar;
    final tickInBar = tickCursor - bar * ticksPerBar;
    final quartersInBar = tickInBar / _ticksPerQuarter;
    final row = bar ~/ barsPerRow;
    final barInRow = bar % barsPerRow;
    final x = leftPad +
        systemPad +
        barInRow * barWidthAt(pxPerQuarter) +
        quartersInBar * pxPerQuarter;
    placements.add(NotePlacement(
      index: i,
      row: row,
      bar: bar,
      xCenter: x,
      resolved: resolved,
      isRest: beats[i].isRest,
    ));
    tickCursor += (resolved.quarters * _ticksPerQuarter).round();
  }

  final totalBars = (tickCursor / ticksPerBar).ceil().clamp(1, 1 << 30);
  final rowCount = ((totalBars - 1) ~/ barsPerRow) + 1;

  final beams = <BeamGroup>[];

  // Recompute beat index per placement from cumulative ticks for grouping.
  // (Cheap second pass keeps grouping independent of pixel math.)
  final beatIndex = <int>[];
  {
    var t = 0;
    for (var i = 0; i < beats.length; i++) {
      final r = resolveNote(beats[i], grid);
      beatIndex.add((t % ticksPerBar) ~/ _ticksPerQuarter);
      t += (r.quarters * _ticksPerQuarter).round();
    }
  }

  var p = 0;
  while (p < placements.length) {
    final row = placements[p].row;
    final bar = placements[p].bar;
    final beat = beatIndex[placements[p].index];

    // Extent of this (row,bar,beat) window.
    var q = p;
    while (q < placements.length &&
        placements[q].row == row &&
        placements[q].bar == bar &&
        beatIndex[placements[q].index] == beat) {
      q++;
    }

    // Within [p, q): beam runs (same beamCount, non-rest, >=2) and tuplet runs.
    _emitBeamRuns(placements, beams, row, p, q);
    _emitTupletRuns(placements, beams, row, p, q);

    p = q;
  }

  return StaffLayout(
    rowCount: rowCount,
    pxPerQuarter: pxPerQuarter,
    beatsPerBar: beatsPerBar,
    barsPerRow: barsPerRow,
    placements: placements,
    beams: beams,
  );
}

void _emitBeamRuns(
  List<NotePlacement> placements,
  List<BeamGroup> out,
  int row,
  int lo,
  int hi,
) {
  var i = lo;
  while (i < hi) {
    final pi = placements[i];
    final bc = pi.isRest ? 0 : beamCountFor(pi.resolved.value);
    if (bc == 0) {
      i++;
      continue;
    }
    var j = i;
    while (j + 1 < hi &&
        !placements[j + 1].isRest &&
        beamCountFor(placements[j + 1].resolved.value) == bc) {
      j++;
    }
    if (j > i) {
      out.add(BeamGroup(
        row: row,
        startIndex: placements[i].index,
        endIndex: placements[j].index,
        beamCount: bc,
        tuplet: Tuplet.none,
      ));
    }
    i = j + 1;
  }
}

void _emitTupletRuns(
  List<NotePlacement> placements,
  List<BeamGroup> out,
  int row,
  int lo,
  int hi,
) {
  var i = lo;
  while (i < hi) {
    final t = placements[i].resolved.tuplet;
    if (t == Tuplet.none || placements[i].isRest) {
      i++;
      continue;
    }
    var j = i;
    while (j + 1 < hi &&
        !placements[j + 1].isRest &&
        placements[j + 1].resolved.tuplet == t) {
      j++;
    }
    out.add(BeamGroup(
      row: row,
      startIndex: placements[i].index,
      endIndex: placements[j].index,
      beamCount: 0, // marker: this entry is a tuplet bracket, not a beam
      tuplet: t,
    ));
    i = j + 1;
  }
}
