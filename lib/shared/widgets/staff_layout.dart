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
  final int endIndex; // inclusive
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

/// Horizontal scale of a staff: px per quarter and bars per row. Chosen
/// once per line so that every voice of a kit line shares it and equal
/// ticks land on equal x (Brief B.2).
class StaffScale {
  final double pxPerQuarter;
  final int barsPerRow;
  const StaffScale({required this.pxPerQuarter, required this.barsPerRow});
}

class StaffLayout {
  final int rowCount;
  final double pxPerQuarter;
  final int beatsPerBar;
  final int barsPerRow;
  final List<NotePlacement> placements;
  final List<BeamGroup> beams;

  /// Horizontal shift that centres a single short row in the available
  /// width (0 for multi-row pieces and rows that fill the width). The
  /// painter translates the whole row by it; placements stay unshifted.
  final double xOffset;

  /// x of the first tick of a row (left pad + system pad), and the gap
  /// between bars — what [xOfTick] needs.
  final double originX;
  final double barGap;
  const StaffLayout({
    required this.rowCount,
    required this.pxPerQuarter,
    required this.beatsPerBar,
    required this.barsPerRow,
    required this.placements,
    required this.beams,
    this.xOffset = 0,
    this.originX = 0,
    this.barGap = 12,
  });

  /// x centre of [tick] in its row's coordinate space — the same formula
  /// the placements use, so a column of several voices lines up.
  double xOfTick(int tick) {
    final ticksPerBar = beatsPerBar * _ticksPerQuarter;
    final bar = tick ~/ ticksPerBar;
    final barInRow = bar % barsPerRow;
    final quartersInBar = (tick - bar * ticksPerBar) / _ticksPerQuarter;
    return originX +
        barInRow * (beatsPerBar * pxPerQuarter + barGap) +
        quartersInBar * pxPerQuarter;
  }

  int rowOfTick(int tick) =>
      (tick ~/ (beatsPerBar * _ticksPerQuarter)) ~/ barsPerRow;
}

const int _ticksPerQuarter = 24; // integer layout math, matches PatternPlayback

/// Minimum on-screen width (in px) a single note gets, so consecutive
/// noteheads (≈12px wide) never visually merge into a solid bar — a fixed
/// px-per-quarter floor let very fast pieces (32nd notes) collapse into an
/// unreadable smear regardless of how sparse the rest of the piece was.
const double _minNoteWidthPx = 9.0;

/// The smallest note duration (in quarters) actually present in [beats], or
/// `null` if there are no notes at all.
double? _finestDurationQuarters(List<StrokeBeat> beats, NoteGrid grid) {
  double? min;
  for (final b in beats) {
    final q = resolveNote(b, grid).quarters;
    if (q > 0 && (min == null || q < min)) min = q;
  }
  return min;
}

/// Chooses the scale of a line: rows are [targetBarsPerRow] bars wide and
/// the note width flexes to fit; short pieces take the whole row; a piece
/// too dense for that falls back to one bar per row, and legibility of its
/// finest note ([finestQuarters], null = no notes) wins over the width.
StaffScale chooseStaffScale({
  required double? finestQuarters,
  required int totalBars,
  required int beatsPerBar,
  required double maxWidth,
  double leftPad = 8,
  double rightPad = 12,
  double systemPad = 26,
  double barGap = 12,
  double preferredPxPerQuarter = 56,
  int targetBarsPerRow = 2,
}) {
  final usable = maxWidth - leftPad - rightPad - systemPad;
  // Legibility floor derives from the piece's own fastest note — a 16th-note
  // piece and a 32nd-note piece need very different minimums.
  final minPxPerQuarter =
      finestQuarters == null ? 8.0 : _minNoteWidthPx / finestQuarters;
  // Rows are a fixed [targetBarsPerRow] bars wide — note width flexes to
  // fit, rather than note width staying fixed and the bar count per row
  // flexing. Matches printed sheet music: a consistent line length instead
  // of "however many bars happen to fit at a comfortable size".
  // Short pieces (fewer bars than a full row — most rudiments are one bar)
  // take the whole row instead of sitting in its left half (Uli 29.09.),
  // spreading up to 1.5× the two-bar comfort size.
  final shortPiece = totalBars < targetBarsPerRow;
  final cap = shortPiece ? preferredPxPerQuarter * 1.5 : preferredPxPerQuarter;
  var barsPerRow = shortPiece ? totalBars : targetBarsPerRow;
  // No trailing gap after the last bar of a row: the row ends on its final
  // barline, flush with the right margin (Uli 10.10.: the right margin was
  // wider than the left one).
  var pxPerQuarter = ((usable + barGap) / barsPerRow - barGap) / beatsPerBar;
  if (pxPerQuarter > cap) pxPerQuarter = cap;
  if (pxPerQuarter < minPxPerQuarter) {
    // Even at the preferred size, [targetBarsPerRow] bars don't comfortably
    // fit this piece's note density — fall back to one bar per row.
    barsPerRow = 1;
    pxPerQuarter = usable / beatsPerBar;
    if (pxPerQuarter > preferredPxPerQuarter) {
      pxPerQuarter = preferredPxPerQuarter;
    }
    if (pxPerQuarter < minPxPerQuarter) {
      // Extreme case (very fast notes on a narrow viewport, e.g. 32nd notes
      // on a phone): legibility wins over fitting the viewport width — the
      // row may need a hair more than [maxWidth] to stay readable.
      pxPerQuarter = minPxPerQuarter;
    }
  }
  return StaffScale(pxPerQuarter: pxPerQuarter, barsPerRow: barsPerRow);
}

StaffLayout computeStaffLayout({
  required List<StrokeBeat> beats,
  required NoteGrid grid,
  required int beatsPerBar,
  required double maxWidth,
  double leftPad = 8,
  double rightPad = 12,
  double systemPad = 26,
  double barGap = 12,
  double preferredPxPerQuarter = 56,
  int targetBarsPerRow = 2,
  StaffScale? scale,
}) {
  final ticksPerBar = beatsPerBar * _ticksPerQuarter;
  final usable = maxWidth - leftPad - rightPad - systemPad;

  double barWidthAt(double pxq) => beatsPerBar * pxq + barGap;

  var totalTicksAll = 0;
  for (final b in beats) {
    totalTicksAll += (resolveNote(b, grid).quarters * _ticksPerQuarter).round();
  }
  final totalBarsAll = (totalTicksAll / ticksPerBar).ceil().clamp(1, 1 << 30);
  final chosen = scale ??
      chooseStaffScale(
        finestQuarters: _finestDurationQuarters(beats, grid),
        totalBars: totalBarsAll,
        beatsPerBar: beatsPerBar,
        maxWidth: maxWidth,
        leftPad: leftPad,
        rightPad: rightPad,
        systemPad: systemPad,
        barGap: barGap,
        preferredPxPerQuarter: preferredPxPerQuarter,
        targetBarsPerRow: targetBarsPerRow,
      );
  final barsPerRow = chosen.barsPerRow;
  final pxPerQuarter = chosen.pxPerQuarter;

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

  // A lone row narrower than the width is centred; multi-row pieces keep
  // their last, shorter row left-aligned like printed music.
  final rowWidth = barsPerRow * barWidthAt(pxPerQuarter) - barGap;
  final xOffset =
      rowCount == 1 && rowWidth < usable ? (usable - rowWidth) / 2 : 0.0;

  return StaffLayout(
    rowCount: rowCount,
    pxPerQuarter: pxPerQuarter,
    beatsPerBar: beatsPerBar,
    barsPerRow: barsPerRow,
    placements: placements,
    beams: beams,
    xOffset: xOffset,
    originX: leftPad + systemPad,
    barGap: barGap,
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
