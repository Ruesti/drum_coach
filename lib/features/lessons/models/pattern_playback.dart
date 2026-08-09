import 'rudiment.dart';

/// Playback volume for a stroke: rest silent, accent loud, ghost quiet.
/// (Mirrors the old practice-screen `_volumesFor` mapping.)
double defaultBeatVolume(StrokeBeat b) {
  if (b.isRest) return 0.0;
  if (b.isAccent) return 2.0;
  if (b.isGhost) return 0.25;
  return 0.85;
}

/// A pattern expanded onto a fixed fine grid ([ticksPerQuarter] ticks per
/// quarter). Each note sounds only on its onset tick; every other tick is
/// silent (volume 0). This drives the metronome's per-tick volume array and
/// the playback cursor without changing the timing isolate.
class PatternPlayback {
  final int ticksPerQuarter;
  final int totalTicks;

  /// Length [totalTicks]. Onset ticks carry the note's volume; others are 0.
  final List<double> tickVolumes;

  /// Onset tick per note index (same length/order as the source beats).
  final List<int> onsetTicks;

  const PatternPlayback({
    required this.ticksPerQuarter,
    required this.totalTicks,
    required this.tickVolumes,
    required this.onsetTicks,
  });

  /// Note index sounding at [tick] = the last onset ≤ tick (clamped).
  int noteIndexAtTick(int tick) {
    if (onsetTicks.isEmpty) return 0;
    if (tick <= onsetTicks.first) return 0;
    var idx = 0;
    for (var i = 0; i < onsetTicks.length; i++) {
      if (onsetTicks[i] <= tick) {
        idx = i;
      } else {
        break;
      }
    }
    return idx;
  }

  factory PatternPlayback.forRudiment(Rudiment r, {int ticksPerQuarter = 24}) =>
      buildPatternPlayback(r.sticking, r.gridUnit,
          ticksPerQuarter: ticksPerQuarter);
}

PatternPlayback buildPatternPlayback(
  List<StrokeBeat> beats,
  NoteGrid grid, {
  int ticksPerQuarter = 24,
  double Function(StrokeBeat) volumeOf = defaultBeatVolume,
}) {
  final onsetTicks = <int>[];
  var cursor = 0;
  for (final b in beats) {
    onsetTicks.add(cursor);
    final quarters = resolveNote(b, grid).quarters;
    cursor += (quarters * ticksPerQuarter).round();
  }
  final total = cursor;
  final vols = List<double>.filled(total, 0.0);
  for (var i = 0; i < beats.length; i++) {
    vols[onsetTicks[i]] = volumeOf(beats[i]);
  }
  return PatternPlayback(
    ticksPerQuarter: ticksPerQuarter,
    totalTicks: total,
    tickVolumes: vols,
    onsetTicks: onsetTicks,
  );
}
