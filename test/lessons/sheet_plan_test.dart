import 'package:drum_coach/features/coaching/midi/kit_instrument.dart';
import 'package:drum_coach/features/lessons/data/etude_dsl.dart';
import 'package:drum_coach/features/lessons/models/rudiment.dart';
import 'package:drum_coach/features/lessons/models/sheet_plan.dart';
import 'package:drum_coach/features/metronome/loop_voices.dart';
import 'package:flutter_test/flutter_test.dart';

int ticksOf(List<StrokeBeat> beats) => beats.fold(
    0, (t, b) => t + (resolveNote(b, NoteGrid.eighth).quarters * 24).round());

void main() {
  final l1 = line(eighths([R, L, R, L, R, L, R, L])); // 1 bar, 8 notes
  final l2 = line(sixteenths(
      [R, L, R, R, L, R, L, L, R, L, R, R, L, R, L, L])); // 1 bar, 16
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
    expect(p.isSequence, isFalse);
    expect(p.lineIndex, 1);
    expect(p.locate(5), (line: 1, index: 5, slot: 0));
  });

  test('sequence of all lines once concatenates them, locate maps back', () {
    final p = SheetPlan.sequence(r, [0, 1, 2], repeats: 1);
    expect(p.beats.length, 8 + 16 + 16);
    expect(p.lines, [0, 1, 2]);
    expect(p.lineStarts, [0, 8, 24]);
    expect(p.isSequence, isTrue);
    expect(p.lineIndex, 0);
    expect(p.locate(0), (line: 0, index: 0, slot: 0));
    expect(p.locate(7), (line: 0, index: 7, slot: 0));
    expect(p.locate(8), (line: 1, index: 0, slot: 1));
    expect(p.locate(39), (line: 2, index: 15, slot: 2));
  });

  group('sequence (three 2-bar lines A, B, C)', () {
    List<StrokeBeat> bars2(Hand h) =>
        eighths([for (var i = 0; i < 16; i++) i.isEven ? h : (h == R ? L : R)]);
    final a = bars2(R);
    final b = sixteenths([for (var i = 0; i < 32; i++) i.isEven ? R : L]);
    final c = bars2(L);
    final r = Rudiment(
        id: 's',
        name: 'S',
        description: '',
        minBpm: 60,
        targetBpm: 100,
        difficulty: Difficulty.beginner,
        sticking: eighths([R, L]),
        lines: [
          line(a, repeat: false),
          line(b, repeat: false),
          line(c, repeat: false),
        ]);
    List<StrokeBeat> bars4() =>
        eighths([for (var i = 0; i < 32; i++) i.isEven ? R : L]);
    final fill8 = Rudiment(
        id: 'f',
        name: 'F',
        description: '',
        minBpm: 60,
        targetBpm: 100,
        difficulty: Difficulty.beginner,
        sticking: eighths([R, L]),
        lines: [for (var i = 0; i < 8; i++) line(bars4(), repeat: false)]);

    test('sequence plays every line `repeats` times in order', () {
      final p = SheetPlan.sequence(r, [0, 2], repeats: 2);
      expect(p.lines, [0, 0, 2, 2]);
      expect(p.beats, [...a, ...a, ...c, ...c]);
      expect(p.totalTicks, 4 * 192);
      expect(p.isSequence, isTrue);
      expect(p.repeats, 2);
    });
    test(
        'locateTick maps to line, tick in line and slot; stepOf gives step '
        'and pass', () {
      final p = SheetPlan.sequence(r, [0, 2], repeats: 2);
      expect(p.locateTick(0), (line: 0, tick: 0, slot: 0));
      expect(p.locateTick(192 + 30), (line: 0, tick: 30, slot: 1));
      expect(p.locateTick(2 * 192), (line: 2, tick: 0, slot: 2));
      expect(p.stepOf(1), (step: 0, pass: 1));
      expect(p.stepOf(2), (step: 1, pass: 0));
    });
    test('start rotates the loop; steps keep the selection order (Rundlauf)',
        () {
      final p = SheetPlan.sequence(r, [0, 1, 2], repeats: 1, start: 1);
      expect(p.lines, [1, 2, 0]);
      expect(p.stepOf(0).step, 1);
      expect(p.stepOf(2).step, 0);
      expect(SheetPlan.sequence(r, [0, 1, 2], start: 4).start, 1); // modulo
    });
    test('one line loops alone: repeats 1, no sequence', () {
      final p = SheetPlan.sequence(r, [1], repeats: 3);
      // (records compare lists by identity, so field by field)
      expect(p.lines, [1]);
      expect((p.repeats, p.isSequence), (1, false));
      expect(SheetPlan.line(r, 7).lineIndex, 2);
      expect(SheetPlan.line(r, -1).lineIndex, 0);
    });
    test(
        'selection is cleaned: out of range and duplicates dropped, '
        'empty = line 1', () {
      expect(SheetPlan.sequence(r, [5, -1, 1, 1, 0]).selection, [1, 0]);
      expect(SheetPlan.sequence(r, []).selection, [0]);
    });
    test('sequence caps repeats at 64 bars', () {
      // eight four-bar lines (fill sheet shape)
      expect(
          SheetPlan.sequence(fill8, [0, 1, 2, 3, 4, 5, 6, 7], repeats: 4)
              .repeats,
          2);
      expect(SheetPlan.sequence(fill8, [0, 1], repeats: 4).repeats, 4);
      expect(SheetPlan.sequence(r, [0, 1, 2], repeats: 9).repeats,
          maxSequenceRepeats);
      expect(maxSequenceBars, maxBackingCycleBars);
    });
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
    expect(SheetPlan.sequence(legacy, [0]).beats.length, 4);
  });

  test('line index is clamped into the sheet', () {
    expect(SheetPlan.line(r, 7).lineIndex, 2);
    expect(SheetPlan.line(r, -1).lineIndex, 0);
  });

  test('barsOf and sheetBars count whole bars, never throw', () {
    expect(barsOf(l3.beats, grid: NoteGrid.eighth, beatsPerBar: 4), 2);
    expect(
        barsOf(eighths([R, L, R]), grid: NoteGrid.eighth, beatsPerBar: 4), 1);
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

    test(
        'sequence once: one voice per instrument, missing voices filled '
        'with rests, accepts kept', () {
      final p = SheetPlan.sequence(kit, [0, 1], repeats: 1);
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
      final p = SheetPlan.sequence(kit, [0, 1], repeats: 1);
      expect(p.locateTick(0), (line: 0, tick: 0, slot: 0));
      expect(p.locateTick(95), (line: 0, tick: 95, slot: 0));
      expect(p.locateTick(96), (line: 1, tick: 0, slot: 1));
      expect(p.locateTick(150), (line: 1, tick: 54, slot: 1));
      expect(
          SheetPlan.line(kit, 1).locateTick(30), (line: 1, tick: 30, slot: 0));
    });

    test(
        'kit sequence: a voice missing in a line is filled with rests per '
        'slot', () {
      // port of the old wholeSheet kit test: line 1 has no kick
      final p = SheetPlan.sequence(kit, [0, 1], repeats: 2);
      final kick =
          p.voices.firstWhere((v) => v.instrument == KitInstrument.kick);
      expect(ticksOf(kick.beats), p.totalTicks);
      expect(p.totalTicks, 4 * 96);
      expect(p.lines, [0, 0, 1, 1]);
      expect(p.playsKick, isTrue);
      for (final v in p.voices) {
        expect(ticksOf(v.beats), p.totalTicks, reason: '${v.instrument}');
      }
    });
  });
}
