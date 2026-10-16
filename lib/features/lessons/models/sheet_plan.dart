import '../../coaching/midi/kit_instrument.dart';
import 'rudiment.dart';

/// Longest sequence in bars (the backing engine's cycle limit,
/// `maxBackingCycleBars`); longer sequences play each line fewer times.
const int maxSequenceBars = 64;

/// Most passes per line in a sequence.
const int maxSequenceRepeats = 4;

/// What the practice screen plays and measures: one line of the sheet, or a
/// sequence of selected lines, each played [repeats] times in selection
/// order, starting at [start] and looping round. A flat note list plus the
/// map back to (line, index in line, slot) for the cursor. Pure.
///
/// A *slot* is one played pass of one line; [lines], [lineStarts] and
/// [lineTickStarts] run parallel per slot.
class SheetPlan {
  final List<StrokeBeat> beats;

  /// Note index at which each slot starts (parallel to [lines]).
  final List<int> lineStarts;

  /// Sheet line index of each slot, in play order.
  final List<int> lines;

  /// The cleaned selection of sheet lines, in its original order.
  final List<int> selection;

  /// Index into [selection] at which the loop begins.
  final int start;

  /// Passes per line actually used (capped to [maxSequenceBars]).
  final int repeats;

  /// The unit's voices (Brief B.1): one per instrument across the slots,
  /// a voice missing in a line filled with that line's length of rests; a
  /// pad unit is one `pad` voice carrying [beats].
  final List<Voice> voices;

  /// Tick at which each slot starts (parallel to [lines]).
  final List<int> lineTickStarts;
  final int totalTicks;

  const SheetPlan._({
    required this.beats,
    required this.lineStarts,
    required this.lines,
    required this.selection,
    required this.start,
    required this.repeats,
    required this.voices,
    required this.lineTickStarts,
    required this.totalTicks,
  });

  /// The one line [lineIndex] (clamped into the sheet), looping alone.
  factory SheetPlan.line(Rudiment r, int lineIndex) =>
      SheetPlan.sequence(r, [lineIndex.clamp(0, r.sheet.length - 1)]);

  /// The lines of [selection] in its order, each [repeats] times, beginning
  /// at selection index [start] (modulo). Out-of-range and duplicate
  /// indices are dropped; an empty selection is line 1. One line plays once
  /// per pass (repeats 1); repeats shrink silently until the sequence fits
  /// [maxSequenceBars].
  factory SheetPlan.sequence(Rudiment r, List<int> selection,
      {int repeats = 2, int start = 0}) {
    final sheet = r.sheet;
    final sel = <int>[];
    for (final i in selection) {
      if (i >= 0 && i < sheet.length && !sel.contains(i)) sel.add(i);
    }
    if (sel.isEmpty) sel.add(0);
    var reps = 1;
    if (sel.length > 1) {
      reps = repeats.clamp(1, maxSequenceRepeats);
      final bars = sel.fold<int>(
          0,
          (n, i) =>
              n +
              barsOf(sheet[i].beats,
                  grid: r.gridUnit, beatsPerBar: r.beatsPerBar));
      while (reps > 1 && reps * bars > maxSequenceBars) {
        reps--;
      }
    }
    final first = start % sel.length;
    final slots = [
      for (var k = 0; k < sel.length; k++)
        for (var p = 0; p < reps; p++) sel[(first + k) % sel.length],
    ];

    if (slots.length == 1) {
      // A single line keeps its own lists unchanged.
      final l = sheet[slots.first];
      return SheetPlan._(
        beats: l.beats,
        lineStarts: const [0],
        lines: slots,
        selection: sel,
        start: first,
        repeats: reps,
        voices: l.voices,
        lineTickStarts: const [0],
        totalTicks: _ticks(l.beats, r.gridUnit),
      );
    }

    final beats = <StrokeBeat>[];
    final starts = <int>[];
    final tickStarts = <int>[];
    var ticks = 0;
    for (final i in slots) {
      final l = sheet[i];
      starts.add(beats.length);
      tickStarts.add(ticks);
      beats.addAll(l.beats);
      ticks += _ticks(l.beats, r.gridUnit);
    }
    // Instruments in order of first appearance; accepts from the first
    // slot that carries the voice.
    final order = <KitInstrument>[];
    final accepts = <KitInstrument, InstrumentClass?>{};
    for (final i in slots) {
      for (final v in sheet[i].voices) {
        if (!order.contains(v.instrument)) {
          order.add(v.instrument);
          accepts[v.instrument] = v.accepts;
        }
      }
    }
    final voices = <Voice>[];
    for (final inst in order) {
      final all = <StrokeBeat>[];
      for (final i in slots) {
        final l = sheet[i];
        Voice? own;
        for (final v in l.voices) {
          if (v.instrument == inst) {
            own = v;
            break;
          }
        }
        all.addAll(own?.beats ?? _rests(_ticks(l.beats, r.gridUnit)));
      }
      voices.add(Voice(inst, all, accepts: accepts[inst]));
    }
    return SheetPlan._(
      beats: beats,
      lineStarts: starts,
      lines: slots,
      selection: sel,
      start: first,
      repeats: reps,
      voices: voices,
      lineTickStarts: tickStarts,
      totalTicks: ticks,
    );
  }

  /// More than one line selected.
  bool get isSequence => selection.length > 1;

  /// The line of the first slot (the selected line in line mode).
  int get lineIndex => lines.first;

  /// A kit unit: anything but the single pad voice.
  bool get isKit =>
      voices.length != 1 || voices.first.instrument != KitInstrument.pad;

  /// Band voices the player covers (Brief B.4): the band keeps quiet there.
  bool get playsKick => voices.any((v) => v.instrument == KitInstrument.kick);
  bool get playsHihat => voices.any((v) => const {
        KitInstrument.hiHatClosed,
        KitInstrument.hiHatOpen,
        KitInstrument.hiHatPedal,
      }.contains(v.instrument));

  /// Selection step (index into [selection]) and pass (0-based) of [slot].
  ({int step, int pass}) stepOf(int slot) => (
        step: (start + slot ~/ repeats) % selection.length,
        pass: slot % repeats,
      );

  /// Sheet line, index within it and slot for a note index of [beats].
  ({int line, int index, int slot}) locate(int noteIndex) {
    var k = 0;
    while (k + 1 < lineStarts.length && lineStarts[k + 1] <= noteIndex) {
      k++;
    }
    return (line: lines[k], index: noteIndex - lineStarts[k], slot: k);
  }

  /// Sheet line, tick within it and slot for a tick of the unit.
  ({int line, int tick, int slot}) locateTick(int tick) {
    var k = 0;
    while (k + 1 < lineTickStarts.length && lineTickStarts[k + 1] <= tick) {
      k++;
    }
    return (line: lines[k], tick: tick - lineTickStarts[k], slot: k);
  }
}

int _ticks(List<StrokeBeat> beats, NoteGrid grid) {
  var t = 0;
  for (final b in beats) {
    t += (resolveNote(b, grid).quarters * 24).round();
  }
  return t;
}

/// Quarter rests covering [ticks] (lines are whole bars, so a multiple of 24).
List<StrokeBeat> _rests(int ticks) {
  if (ticks % 24 != 0) throw ArgumentError('$ticks ticks is not whole beats');
  return [
    for (var t = 0; t < ticks; t += 24)
      const StrokeBeat.rest(value: NoteValue.quarter),
  ];
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
