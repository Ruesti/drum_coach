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
}) {
  final ticksPerBar = beatsPerBar * _ticksPerQuarter;
  final usable = maxWidth - leftPad - rightPad - systemPad;

  double barWidthAt(double pxq) => beatsPerBar * pxq + barGap;
  var pxPerQuarter = preferredPxPerQuarter;
  var barsPerRow = (usable / barWidthAt(pxPerQuarter)).floor();
  if (barsPerRow < 1) {
    barsPerRow = 1;
    final minPx = preferredPxPerQuarter < 8.0 ? preferredPxPerQuarter : 8.0;
    pxPerQuarter = ((usable - barGap) / beatsPerBar).clamp(minPx, preferredPxPerQuarter);
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
    _emitBeamRuns(beats, placements, beamCountFor, beams, row, p, q);
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
  List<StrokeBeat> beats,
  List<NotePlacement> placements,
  int Function(NoteValue) beamCountFor,
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
