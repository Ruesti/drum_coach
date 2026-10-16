import '../../coaching/midi/kit_instrument.dart';
import 'rudiment.dart';

/// What the practice screen plays and measures: one line of the sheet, or
/// all lines in order (each once). A flat note list plus the map back to
/// (line, index in line) for the cursor. Pure.
class SheetPlan {
  final List<StrokeBeat> beats;

  /// Note index at which each covered line starts (parallel to [lines]).
  final List<int> lineStarts;

  /// Sheet line indices covered, in play order.
  final List<int> lines;
  final bool wholeSheet;

  /// The unit's voices (Brief B.1): one per instrument across the covered
  /// lines, a voice missing in a line filled with that line's length of
  /// rests; a pad unit is one `pad` voice carrying [beats].
  final List<Voice> voices;

  /// Tick at which each covered line starts (parallel to [lines]).
  final List<int> lineTickStarts;
  final int totalTicks;

  const SheetPlan._({
    required this.beats,
    required this.lineStarts,
    required this.lines,
    required this.wholeSheet,
    required this.voices,
    required this.lineTickStarts,
    required this.totalTicks,
  });

  /// The one line [lineIndex] (clamped into the sheet).
  factory SheetPlan.line(Rudiment r, int lineIndex) {
    final sheet = r.sheet;
    final i = lineIndex.clamp(0, sheet.length - 1);
    final l = sheet[i];
    return SheetPlan._(
      beats: l.beats,
      lineStarts: const [0],
      lines: [i],
      wholeSheet: false,
      voices: l.voices,
      lineTickStarts: const [0],
      totalTicks: _ticks(l.beats, r.gridUnit),
    );
  }

  /// Every line once, in order.
  factory SheetPlan.wholeSheet(Rudiment r) {
    final sheet = r.sheet;
    final beats = <StrokeBeat>[];
    final starts = <int>[];
    final tickStarts = <int>[];
    var ticks = 0;
    for (final l in sheet) {
      starts.add(beats.length);
      tickStarts.add(ticks);
      beats.addAll(l.beats);
      ticks += _ticks(l.beats, r.gridUnit);
    }
    // Instruments in order of first appearance; accepts from the first
    // line that carries the voice.
    final order = <KitInstrument>[];
    final accepts = <KitInstrument, InstrumentClass?>{};
    for (final l in sheet) {
      for (final v in l.voices) {
        if (!order.contains(v.instrument)) {
          order.add(v.instrument);
          accepts[v.instrument] = v.accepts;
        }
      }
    }
    final voices = <Voice>[];
    for (final inst in order) {
      final all = <StrokeBeat>[];
      for (final l in sheet) {
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
      lines: [for (var i = 0; i < sheet.length; i++) i],
      wholeSheet: true,
      voices: voices,
      lineTickStarts: tickStarts,
      totalTicks: ticks,
    );
  }

  /// The selected line (line mode) or the first line (sheet mode).
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

  /// Sheet line and index within it for a note index of [beats].
  /// Sheet line and index within it for a note index of [beats].
  ({int line, int index}) locate(int noteIndex) {
    var k = 0;
    while (k + 1 < lineStarts.length && lineStarts[k + 1] <= noteIndex) {
      k++;
    }
    return (line: lines[k], index: noteIndex - lineStarts[k]);
  }

  /// Sheet line and tick within it for a tick of the unit.
  ({int line, int tick}) locateTick(int tick) {
    var k = 0;
    while (k + 1 < lineTickStarts.length && lineTickStarts[k + 1] <= tick) {
      k++;
    }
    return (line: lines[k], tick: tick - lineTickStarts[k]);
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
