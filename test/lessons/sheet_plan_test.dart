import 'package:drum_coach/features/coaching/midi/kit_instrument.dart';
import 'package:drum_coach/features/lessons/data/etude_dsl.dart';
import 'package:drum_coach/features/lessons/models/rudiment.dart';
import 'package:drum_coach/features/lessons/models/sheet_plan.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final l1 = line(eighths([R, L, R, L, R, L, R, L])); // 1 bar, 8 notes
  final l2 = line(
      sixteenths([R, L, R, R, L, R, L, L, R, L, R, R, L, R, L, L])); // 1 bar, 16
  final l3 = line([
    ...eighths([R, L, R, L, R, L, R, L]),
    ...eighths([L, R, L, R, L, R, L, R]),
  ], repeat: false); // 2 bars, 16
  final r = Rudiment(
      id: 't',
      name: 'T',
      description: '',
      minBpm: 60,
      targetBpm: 100,
      difficulty: Difficulty.beginner,
      sticking: eighths([R, L]),
      lines: [l1, l2, l3]);

  test('line plan is exactly that line', () {
    final p = SheetPlan.line(r, 1);
    expect(p.beats, same(l2.beats));
    expect(p.lines, [1]);
    expect(p.lineStarts, [0]);
    expect(p.wholeSheet, isFalse);
    expect(p.lineIndex, 1);
    expect(p.locate(5), (line: 1, index: 5));
  });

  test('whole-sheet plan concatenates all lines once', () {
    final p = SheetPlan.wholeSheet(r);
    expect(p.beats.length, 8 + 16 + 16);
    expect(p.lines, [0, 1, 2]);
    expect(p.lineStarts, [0, 8, 24]);
    expect(p.wholeSheet, isTrue);
    expect(p.lineIndex, 0);
    expect(p.locate(0), (line: 0, index: 0));
    expect(p.locate(7), (line: 0, index: 7));
    expect(p.locate(8), (line: 1, index: 0));
    expect(p.locate(39), (line: 2, index: 15));
  });

  test('legacy exercise without lines is a one-line sheet plan', () {
    final legacy = Rudiment(
        id: 'l',
        name: 'L',
        description: '',
        minBpm: 60,
        targetBpm: 100,
        difficulty: Difficulty.beginner,
        sticking: eighths([R, L, R, L]));
    expect(SheetPlan.line(legacy, 0).beats, same(legacy.sticking));
    expect(SheetPlan.wholeSheet(legacy).beats.length, 4);
  });

  test('line index is clamped into the sheet', () {
    expect(SheetPlan.line(r, 7).lineIndex, 2);
    expect(SheetPlan.line(r, -1).lineIndex, 0);
  });

  test('barsOf and sheetBars count whole bars, never throw', () {
    expect(barsOf(l3.beats, grid: NoteGrid.eighth, beatsPerBar: 4), 2);
    expect(barsOf(eighths([R, L, R]), grid: NoteGrid.eighth, beatsPerBar: 4), 1);
    expect(barsOf(const [], grid: NoteGrid.eighth, beatsPerBar: 4), 0);
    expect(sheetBars(r), 4);
  });

  group('kit units (Brief B.1)', () {
    List<StrokeBeat> hh8() => eighths([R, R, R, R, R, R, R, R]);
    List<StrokeBeat> q4(StrokeBeat Function() b) =>
        [b(), rest(NoteValue.quarter), b(), rest(NoteValue.quarter)];
    final groove = kitLine([
      voice(KitInstrument.hiHatClosed, hh8()),
      voice(KitInstrument.snare, q4(() => note(L, NoteValue.quarter))),
      voice(KitInstrument.kick, q4(() => foot(NoteValue.quarter))),
    ]);
    // Line 2 adds a tom and drops the kick.
    final fill = kitLine([
      voice(KitInstrument.hiHatClosed, hh8()),
      voice(KitInstrument.snare, q4(() => note(L, NoteValue.quarter))),
      voice(KitInstrument.tom1, q4(() => note(R, NoteValue.quarter)),
          accepts: InstrumentClass.anyTom),
    ], repeat: false);
    final kit = Rudiment(
        id: 'k',
        name: 'K',
        description: '',
        minBpm: 60,
        targetBpm: 100,
        difficulty: Difficulty.beginner,
        sticking: hh8(),
        voicing: ExerciseVoicing.kit,
        lines: [groove, fill]);

    test('a pad plan is one pad voice and not a kit', () {
      final p = SheetPlan.line(r, 0);
      expect(p.isKit, isFalse);
      expect(p.voices.single.instrument, KitInstrument.pad);
      expect(p.voices.single.beats, same(l1.beats));
      expect(p.totalTicks, 96);
      expect(p.lineTickStarts, [0]);
      expect(p.playsKick, isFalse);
      expect(p.playsHihat, isFalse);
    });

    test('a kit line plan carries the voices, ticks and band flags', () {
      final p = SheetPlan.line(kit, 0);
      expect(p.isKit, isTrue);
      expect(p.beats, same(groove.beats));
      expect(p.voices.map((v) => v.instrument), [
        KitInstrument.hiHatClosed,
        KitInstrument.snare,
        KitInstrument.kick,
      ]);
      expect(p.totalTicks, 96);
      expect(p.playsKick, isTrue);
      expect(p.playsHihat, isTrue);
      expect(SheetPlan.line(kit, 1).playsKick, isFalse);
    });

    test('whole sheet: one voice per instrument, missing voices filled with '
        'rests, accepts kept', () {
      final p = SheetPlan.wholeSheet(kit);
      expect(p.isKit, isTrue);
      expect(p.totalTicks, 192);
      expect(p.lineTickStarts, [0, 96]);
      expect(p.voices.map((v) => v.instrument), [
        KitInstrument.hiHatClosed,
        KitInstrument.snare,
        KitInstrument.kick,
        KitInstrument.tom1,
      ]);
      final kick = p.voices[2];
      expect(kick.beats.length, 4 + 4); // its line + four quarter rests
      expect(kick.beats.sublist(4).every((b) => b.isRest), isTrue);
      final tom = p.voices[3];
      expect(tom.accepts, InstrumentClass.anyTom);
      expect(tom.beats.take(4).every((b) => b.isRest), isTrue);
      expect(tom.beats.length, 8);
      expect(p.playsKick, isTrue);
    });

    test('locateTick maps a unit tick to line and tick in line', () {
      final p = SheetPlan.wholeSheet(kit);
      expect(p.locateTick(0), (line: 0, tick: 0));
      expect(p.locateTick(95), (line: 0, tick: 95));
      expect(p.locateTick(96), (line: 1, tick: 0));
      expect(p.locateTick(150), (line: 1, tick: 54));
      expect(SheetPlan.line(kit, 1).locateTick(30), (line: 1, tick: 30));
    });
  });
}
