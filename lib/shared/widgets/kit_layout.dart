import 'dart:collection';

import '../../features/lessons/models/rudiment.dart';
import 'staff_layout.dart';

/// Geometry of a kit line (Brief B.2): the voices are merged into two
/// layers — hands (stems up) and feet (stems down) — each a rhythm track
/// `computeStaffLayout` can beam like a pad line, both on one [StaffScale]
/// so equal ticks land on equal x. Pure, no Flutter.
const int kitTicksPerQuarter = 24;

const List<({int ticks, ResolvedNote note})> _gapValues = [
  (ticks: 24, note: ResolvedNote(NoteValue.quarter, false, Tuplet.none)),
  (ticks: 18, note: ResolvedNote(NoteValue.eighth, true, Tuplet.none)),
  (ticks: 16, note: ResolvedNote(NoteValue.quarter, false, Tuplet.triplet)),
  (ticks: 12, note: ResolvedNote(NoteValue.eighth, false, Tuplet.none)),
  (ticks: 9, note: ResolvedNote(NoteValue.sixteenth, true, Tuplet.none)),
  (ticks: 8, note: ResolvedNote(NoteValue.eighth, false, Tuplet.triplet)),
  (ticks: 6, note: ResolvedNote(NoteValue.sixteenth, false, Tuplet.none)),
  (ticks: 4, note: ResolvedNote(NoteValue.sixteenth, false, Tuplet.sextuplet)),
  (ticks: 3, note: ResolvedNote(NoteValue.thirtySecond, false, Tuplet.none)),
  (ticks: 2, note: ResolvedNote(NoteValue.thirtySecond, false, Tuplet.triplet)),
];

/// Drawn value for a gap of [ticks] inside one beat: the time from an onset
/// of a layer to the layer's next onset, capped at the beat. The largest
/// drawable value that fits; null for 0 or 1 tick.
ResolvedNote? valueForGap(int ticks) {
  for (final e in _gapValues) {
    if (e.ticks <= ticks) return e.note;
  }
  return null;
}

int ticksOfNote(ResolvedNote r) => (r.quarters * kitTicksPerQuarter).round();

int ticksOf(List<StrokeBeat> beats, NoteGrid grid) {
  var t = 0;
  for (final b in beats) {
    t += ticksOfNote(resolveNote(b, grid));
  }
  return t;
}

/// Onsets of [beats] (rests excluded) with their tick.
List<({int tick, StrokeBeat beat})> onsetsOf(
    List<StrokeBeat> beats, NoteGrid grid) {
  final out = <({int tick, StrokeBeat beat})>[];
  var cursor = 0;
  for (final b in beats) {
    if (!b.isRest) out.add((tick: cursor, beat: b));
    cursor += ticksOfNote(resolveNote(b, grid));
  }
  return out;
}

/// A sounding note of one voice at a column.
typedef KitNote = ({Voice voice, StrokeBeat beat});

/// Every voice that sounds at one tick of a kit line.
class KitColumn {
  final int tick;
  final List<KitNote> notes;
  const KitColumn(this.tick, this.notes);
  Iterable<KitNote> get hands => notes.where((n) => !n.voice.isFoot);
  Iterable<KitNote> get feet => notes.where((n) => n.voice.isFoot);
}

/// One layer merged into a rhythm track plus the track index of each onset.
class KitLayer {
  final List<StrokeBeat> track;
  final Map<int, int> indexOfTick;
  const KitLayer(this.track, this.indexOfTick);
}

SplayTreeMap<int, List<KitNote>> _columnsOf(List<Voice> voices, NoteGrid grid) {
  final byTick = SplayTreeMap<int, List<KitNote>>();
  for (final v in voices) {
    for (final o in onsetsOf(v.beats, grid)) {
      (byTick[o.tick] ??= []).add((voice: v, beat: o.beat));
    }
  }
  return byTick;
}

/// Merges the [voices] of one layer (hands or feet) into one rhythm track:
/// every onset becomes a note whose drawn value is the gap to the layer's
/// next onset, capped at the beat; the rest of the gap is rests, beat by
/// beat, so the track's ticks add up exactly and nothing drifts. The note
/// carries the one hand of the column (null when the hands differ or
/// there is none), an accent if any voice accents, the first hand voice's
/// graces. Throws whenever the greedy fill cannot complete a gap (a single
/// tick, but also 5, 7, 10 or 13 ticks, which arise when 32nd and
/// 32nd-triplet voices mix).
KitLayer layerTrack(List<Voice> voices,
    {required NoteGrid grid,
    required int totalTicks,
    int ticksPerBeat = kitTicksPerQuarter}) {
  final byTick = _columnsOf(voices, grid);
  final ticks = byTick.keys.toList(growable: false);
  final track = <StrokeBeat>[];
  final index = <int, int>{};
  var cursor = 0;

  void restsUpTo(int upTo) {
    while (cursor < upTo) {
      final beatEnd = (cursor ~/ ticksPerBeat + 1) * ticksPerBeat;
      final end = upTo < beatEnd ? upTo : beatEnd;
      final r = valueForGap(end - cursor);
      if (r == null) {
        throw ArgumentError(
            'gap of ${end - cursor} tick(s) at tick $cursor is not drawable');
      }
      track.add(
          StrokeBeat.rest(value: r.value, dotted: r.dotted, tuplet: r.tuplet));
      cursor += ticksOfNote(r);
    }
  }

  for (var i = 0; i < ticks.length; i++) {
    final tick = ticks[i];
    restsUpTo(tick);
    final next = i + 1 < ticks.length ? ticks[i + 1] : totalTicks;
    final beatEnd = (tick ~/ ticksPerBeat + 1) * ticksPerBeat;
    final gap = (next < beatEnd ? next : beatEnd) - tick;
    final r = valueForGap(gap);
    if (r == null) {
      throw ArgumentError('gap of $gap tick(s) at tick $tick is not drawable');
    }
    final notes = byTick[tick]!;
    final hands = {
      for (final n in notes)
        if (n.beat.hand != null) n.beat.hand!
    };
    final lead =
        notes.firstWhere((n) => n.beat.hand != null, orElse: () => notes.first);
    index[tick] = track.length;
    track.add(StrokeBeat(
      hand: hands.length == 1 ? hands.first : null,
      value: r.value,
      dotted: r.dotted,
      tuplet: r.tuplet,
      isAccent: notes.any((n) => n.beat.isAccent),
      isGhost: notes.every((n) => n.beat.isGhost),
      graces: lead.beat.graces,
    ));
    cursor = tick + ticksOfNote(r);
  }
  restsUpTo(totalTicks);
  return KitLayer(track, index);
}

/// Whether [v] alternates its limb pair somewhere in the line: any right
/// and any left among its onsets (graces excluded — they live in
/// `StrokeBeat.graces`, not in `hand`). A hand voice played by one hand
/// only (hat all R, snare all L) or a foot voice with one side only
/// carries no letters (Uli, S23 test 16.10.: "R/L only where it changes").
bool voiceAlternates(Voice v) {
  var right = false;
  var left = false;
  for (final b in v.beats) {
    if (b.isRest) continue;
    if (b.hand == Hand.right) right = true;
    if (b.hand == Hand.left) left = true;
    if (right && left) return true;
  }
  return false;
}

/// Sticking letters of one layer per tick: at each column the hand of the
/// first note (layer order = voice order) whose voice alternates; columns
/// without such a note get none. Computed once per line.
Map<int, Hand> kitLettersOf(List<KitColumn> columns, {required bool feet}) {
  final carries = <Voice, bool>{};
  final out = <int, Hand>{};
  for (final col in columns) {
    for (final n in feet ? col.feet : col.hands) {
      final hand = n.beat.hand;
      if (hand == null) continue;
      if (!(carries[n.voice] ??= voiceAlternates(n.voice))) continue;
      out[col.tick] = hand;
      break;
    }
  }
  return out;
}

/// Layout of one kit line: both layers, their shared scale, the columns.
class KitLineLayout {
  final StaffScale scale;
  final int beatsPerBar;
  final int totalTicks;
  final int rowCount;
  final StaffLayout hands;
  final StaffLayout feet;
  final List<StrokeBeat> handsTrack;
  final List<StrokeBeat> feetTrack;
  final Map<int, int> handsIndexOfTick;
  final Map<int, int> feetIndexOfTick;
  final List<KitColumn> columns;

  /// Sticking letters (hands) and foot sides (feet) per tick, only for
  /// voices that alternate in this line (`kitLettersOf`).
  final Map<int, Hand> handLetters;
  final Map<int, Hand> footLetters;
  const KitLineLayout({
    required this.scale,
    required this.beatsPerBar,
    required this.totalTicks,
    required this.rowCount,
    required this.hands,
    required this.feet,
    required this.handsTrack,
    required this.feetTrack,
    required this.handsIndexOfTick,
    required this.feetIndexOfTick,
    required this.columns,
    required this.handLetters,
    required this.footLetters,
  });

  double xOfTick(int tick) => hands.xOfTick(tick);
  int rowOfTick(int tick) => hands.rowOfTick(tick);
}

KitLineLayout computeKitLineLayout({
  required List<Voice> voices,
  required NoteGrid grid,
  required int beatsPerBar,
  required double maxWidth,
  double leftPad = 8,
  double rightPad = 12,
  double systemPad = 26,
  double barGap = 12,
}) {
  if (voices.isEmpty) throw ArgumentError('kit line without voices');
  final lengths = [for (final v in voices) ticksOf(v.beats, grid)];
  if (lengths.any((l) => l != lengths.first)) {
    throw ArgumentError('voices differ in length: $lengths ticks');
  }
  final totalTicks = lengths.first;
  final ticksPerBar = beatsPerBar * kitTicksPerQuarter;
  final totalBars = (totalTicks / ticksPerBar).ceil().clamp(1, 1 << 30);
  double? finest;
  for (final v in voices) {
    for (final b in v.beats) {
      final q = resolveNote(b, grid).quarters;
      if (q > 0 && (finest == null || q < finest)) finest = q;
    }
  }
  final scale = chooseStaffScale(
    finestQuarters: finest,
    totalBars: totalBars,
    beatsPerBar: beatsPerBar,
    maxWidth: maxWidth,
    leftPad: leftPad,
    rightPad: rightPad,
    systemPad: systemPad,
    barGap: barGap,
  );
  final handsLayer = layerTrack([
    for (final v in voices)
      if (!v.isFoot) v
  ], grid: grid, totalTicks: totalTicks);
  final feetLayer = layerTrack([
    for (final v in voices)
      if (v.isFoot) v
  ], grid: grid, totalTicks: totalTicks);
  StaffLayout lay(List<StrokeBeat> track) => computeStaffLayout(
        beats: track,
        grid: grid,
        beatsPerBar: beatsPerBar,
        maxWidth: maxWidth,
        leftPad: leftPad,
        rightPad: rightPad,
        systemPad: systemPad,
        barGap: barGap,
        scale: scale,
      );
  final columns = [
    for (final e in _columnsOf(voices, grid).entries)
      KitColumn(e.key, List.unmodifiable(e.value)),
  ];
  return KitLineLayout(
    scale: scale,
    beatsPerBar: beatsPerBar,
    totalTicks: totalTicks,
    rowCount: ((totalBars - 1) ~/ scale.barsPerRow) + 1,
    hands: lay(handsLayer.track),
    feet: lay(feetLayer.track),
    handsTrack: handsLayer.track,
    feetTrack: feetLayer.track,
    handsIndexOfTick: handsLayer.indexOfTick,
    feetIndexOfTick: feetLayer.indexOfTick,
    columns: columns,
    handLetters: kitLettersOf(columns, feet: false),
    footLetters: kitLettersOf(columns, feet: true),
  );
}
