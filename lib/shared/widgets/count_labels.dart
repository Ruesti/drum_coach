import '../../features/lessons/models/rudiment.dart';
import 'kit_layout.dart';

const int _tpq = 24;

bool _ternaryGrid(NoteGrid grid) =>
    grid == NoteGrid.triplet || grid == NoteGrid.sixteenthTriplet;

/// Count syllable at [tickInBar] (24 ticks per quarter): the beat number on
/// the beat, "e + a" on binary sixteenth positions, "+ a" on [ternary]
/// positions; null off the syllable grid.
String? countLabelAtTick(int tickInBar, {required bool ternary}) {
  final beat = tickInBar ~/ _tpq + 1;
  final t = tickInBar % _tpq;
  if (t == 0) return '$beat';
  if (ternary) return switch (t) { 8 => '+', 16 => 'a', _ => null };
  return switch (t) { 6 => 'e', 12 => '+', 18 => 'a', _ => null };
}

/// Count syllables under a line (spec §4d): the beat number on the beat,
/// "e + a" on binary sixteenth positions, "+ a" on ternary positions
/// (tuplets or a triplet grid). Rests and positions off the syllable grid
/// (32nds, dotted remainders) get null. One entry per note, same order.
List<String?> countLabelsFor(
    List<StrokeBeat> beats, NoteGrid grid, int beatsPerBar) {
  final ternaryGrid = _ternaryGrid(grid);
  final out = <String?>[];
  var tick = 0;
  for (final b in beats) {
    final r = resolveNote(b, grid);
    final ticks = (r.quarters * _tpq).round();
    out.add(b.isRest
        ? null
        : countLabelAtTick(tick % (beatsPerBar * _tpq),
            ternary: ternaryGrid || r.tuplet != Tuplet.none));
    tick += ticks;
  }
  return out;
}

/// Count syllables at absolute [ticks] of a line, one per tick, same order.
/// Ternary on a triplet grid or where [ternaryAt] says so.
List<String?> countLabelsForTicks(
    Iterable<int> ticks, NoteGrid grid, int beatsPerBar,
    {bool Function(int tick)? ternaryAt}) {
  final ternaryGrid = _ternaryGrid(grid);
  return [
    for (final t in ticks)
      countLabelAtTick(t % (beatsPerBar * _tpq),
          ternary: ternaryGrid || (ternaryAt?.call(t) ?? false)),
  ];
}

/// Count syllables of a kit line: one per column (parallel to
/// [KitLineLayout.columns]), so a beat only the feet play is counted too.
/// A column counts ternary when its hands or feet note is a tuplet.
List<String?> kitCountLabelsFor(KitLineLayout kit, NoteGrid grid) {
  bool tupletIn(List<StrokeBeat> track, int? index) =>
      index != null && resolveNote(track[index], grid).tuplet != Tuplet.none;
  return countLabelsForTicks(
      [for (final c in kit.columns) c.tick], grid, kit.beatsPerBar,
      ternaryAt: (t) =>
          tupletIn(kit.handsTrack, kit.handsIndexOfTick[t]) ||
          tupletIn(kit.feetTrack, kit.feetIndexOfTick[t]));
}
