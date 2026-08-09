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
    pxPerQuarter = ((usable - barGap) / beatsPerBar).clamp(8.0, preferredPxPerQuarter);
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
        barInRow * (beatsPerBar * pxPerQuarter + barGap) +
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

  return StaffLayout(
    rowCount: rowCount,
    pxPerQuarter: pxPerQuarter,
    beatsPerBar: beatsPerBar,
    barsPerRow: barsPerRow,
    placements: placements,
    beams: const [], // filled in Task 6
  );
}
