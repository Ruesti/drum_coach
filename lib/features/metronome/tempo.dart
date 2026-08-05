import '../lessons/models/rudiment.dart';

/// Onsets per quarter note for a notation [grid]. BPM is always the
/// quarter-note pulse, so this is exactly the grid's cells-per-quarter —
/// with NO cap (the old `_subdivisionFor` capped 6/8 down to 4, Bug 1).
int onsetFactorFor(NoteGrid grid) => grid.cellsPerQuarter;

/// Microseconds of one quarter-note pulse. Grid-independent.
int quarterPulseMicros(int bpm) => 60000000 ~/ bpm;

/// Microseconds between consecutive note onsets at [bpm] for a grid of
/// [cellsPerQuarter].
int onsetIntervalMicros(int bpm, int cellsPerQuarter) =>
    60000000 ~/ bpm ~/ cellsPerQuarter;

/// Duration one grid cell occupies — the notation cursor's per-cell time and
/// the audio onset interval are the SAME quantity.
Duration cellDuration(int bpm, int cellsPerQuarter) =>
    Duration(microseconds: onsetIntervalMicros(bpm, cellsPerQuarter));

/// Fractional cell position of the playback cursor: [anchorIndex] plus how far
/// we've progressed toward the next cell (0..1), given [elapsed] since the
/// anchor beat and the [perCell] cell duration. Clamped to
/// `[anchorIndex, anchorIndex + 1]`.
double cursorFraction(int anchorIndex, Duration elapsed, Duration perCell) {
  if (perCell.inMicroseconds <= 0) return anchorIndex.toDouble();
  final t = (elapsed.inMicroseconds / perCell.inMicroseconds).clamp(0.0, 1.0);
  return anchorIndex + t;
}
