import '../../features/lessons/models/rudiment.dart';

/// Count syllables under a line (spec §4d): the beat number on the beat,
/// "e + a" on binary sixteenth positions, "+ a" on ternary positions
/// (tuplets or a triplet grid). Rests and positions off the syllable grid
/// (32nds, dotted remainders) get null. One entry per note, same order.
List<String?> countLabelsFor(
    List<StrokeBeat> beats, NoteGrid grid, int beatsPerBar) {
  const tpq = 24;
  final ternaryGrid =
      grid == NoteGrid.triplet || grid == NoteGrid.sixteenthTriplet;
  final out = <String?>[];
  var tick = 0;
  for (final b in beats) {
    final r = resolveNote(b, grid);
    final ticks = (r.quarters * tpq).round();
    if (b.isRest) {
      out.add(null);
      tick += ticks;
      continue;
    }
    final inBar = tick % (beatsPerBar * tpq);
    final beat = inBar ~/ tpq + 1;
    final t = inBar % tpq;
    final ternary = ternaryGrid || r.tuplet != Tuplet.none;
    final String? label;
    if (t == 0) {
      label = '$beat';
    } else if (ternary) {
      label = switch (t) { 8 => '+', 16 => 'a', _ => null };
    } else {
      label = switch (t) { 6 => 'e', 12 => '+', 18 => 'a', _ => null };
    }
    out.add(label);
    tick += ticks;
  }
  return out;
}
