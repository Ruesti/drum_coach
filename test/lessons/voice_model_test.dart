import 'package:drum_coach/features/coaching/midi/kit_instrument.dart';
import 'package:drum_coach/features/coaching/services/stroke_source.dart';
import 'package:drum_coach/features/lessons/data/etude_dsl.dart';
import 'package:drum_coach/features/lessons/models/rudiment.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Hand is optional (Brief B.1)', () {
    test('foot() carries no hand, rests carry none either', () {
      expect(foot(NoteValue.quarter).hand, isNull);
      expect(foot(NoteValue.eighth, accent: true).isAccent, isTrue);
      expect(rest(NoteValue.quarter).hand, isNull);
      expect(note(R, NoteValue.quarter).hand, Hand.right);
    });
  });

  group('InstrumentClass', () {
    test('members per class, every class has a label', () {
      expect(InstrumentClass.anyTom.members, {
        KitInstrument.tom1,
        KitInstrument.tom2,
        KitInstrument.floorTom1,
        KitInstrument.floorTom2,
      });
      expect(InstrumentClass.anyCrash.members, {
        KitInstrument.crash1,
        KitInstrument.crash2,
        KitInstrument.china,
        KitInstrument.splash,
      });
      expect(InstrumentClass.anyCymbal.members.contains(KitInstrument.ride),
          isTrue);
      expect(InstrumentClass.anyCymbal.members.contains(KitInstrument.snare),
          isFalse);
      for (final c in InstrumentClass.values) {
        expect(c.label, isNotEmpty);
      }
    });
    test('kick and hi-hat pedal are foot instruments', () {
      expect(KitInstrument.kick.isFoot, isTrue);
      expect(KitInstrument.hiHatPedal.isFoot, isTrue);
      expect(KitInstrument.hiHatClosed.isFoot, isFalse);
      expect(KitInstrument.snare.isFoot, isFalse);
    });
  });

  group('Voice', () {
    final kick = voice(KitInstrument.kick, [foot(NoteValue.quarter)]);
    final tom = voice(KitInstrument.tom1, [note(R, NoteValue.quarter)],
        accepts: InstrumentClass.anyTom);
    test('isFoot follows the instrument', () {
      expect(kick.isFoot, isTrue);
      expect(tom.isFoot, isFalse);
    });
    test('matches: the instrument itself, or any member of the class', () {
      expect(kick.matches(KitInstrument.kick), isTrue);
      expect(kick.matches(KitInstrument.snare), isFalse);
      expect(tom.matches(KitInstrument.tom1), isTrue);
      expect(tom.matches(KitInstrument.floorTom2), isTrue);
      expect(tom.matches(KitInstrument.crash1), isFalse);
    });
  });

  group('ExerciseLine', () {
    final hh =
        voice(KitInstrument.hiHatClosed, eighths([R, R, R, R, R, R, R, R]));
    final sn = voice(KitInstrument.snare, [
      rest(NoteValue.quarter),
      note(L, NoteValue.quarter, accent: true),
      rest(NoteValue.quarter),
      note(L, NoteValue.quarter, accent: true),
    ]);
    final bd = voice(KitInstrument.kick, [
      foot(NoteValue.quarter),
      rest(NoteValue.quarter),
      foot(NoteValue.quarter),
      rest(NoteValue.quarter),
    ]);
    test('a pad line is one pad voice', () {
      final l = line(eighths([R, L, R, L, R, L, R, L]));
      expect(l.isKit, isFalse);
      expect(l.kitVoices, isEmpty);
      expect(l.voices.length, 1);
      expect(l.voices.single.instrument, KitInstrument.pad);
      expect(l.voices.single.beats, same(l.beats));
    });
    test('a kit line: beats are the first voice, voices as given', () {
      final l = kitLine([hh, sn, bd], counts: true, title: 'Groove');
      expect(l.isKit, isTrue);
      expect(l.beats, same(hh.beats));
      expect(l.voices.map((v) => v.instrument), [
        KitInstrument.hiHatClosed,
        KitInstrument.snare,
        KitInstrument.kick,
      ]);
      expect(l.counts, isTrue);
      expect(l.title, 'Groove');
      expect(l.repeat, isTrue);
    });
    test('kitLine() with no voices throws', () {
      expect(() => kitLine(const []), throwsA(isA<AssertionError>()));
    });
    test('kitBarsOrThrow: equal whole bars pass, unequal lengths throw', () {
      expect(
          kitBarsOrThrow([hh, sn, bd], beatsPerBar: 4, grid: NoteGrid.eighth),
          1);
      final short = voice(KitInstrument.tom1, [note(R, NoteValue.half)]);
      expect(
          () => kitBarsOrThrow([hh, short],
              beatsPerBar: 4, grid: NoteGrid.eighth),
          throwsArgumentError);
    });
  });

  group('Rudiment', () {
    test(
        'isKit follows voicing; patternVoices default empty; withSticking '
        'keeps both', () {
      final pad = Rudiment(
          id: 'p',
          name: 'P',
          description: '',
          minBpm: 60,
          targetBpm: 100,
          difficulty: Difficulty.beginner,
          sticking: eighths([R, L]));
      expect(pad.isKit, isFalse);
      expect(pad.patternVoices, isEmpty);
      final kit = Rudiment(
          id: 'k',
          name: 'K',
          description: '',
          minBpm: 60,
          targetBpm: 100,
          difficulty: Difficulty.beginner,
          sticking: eighths([R, R, R, R, R, R, R, R]),
          voicing: ExerciseVoicing.kit,
          requiredSensor: SensorLevel.midi,
          patternVoices: [
            voice(KitInstrument.hiHatClosed, eighths([R, R, R, R, R, R, R, R])),
          ]);
      expect(kit.isKit, isTrue);
      final unit = kit.withSticking(eighths([R, R]));
      expect(unit.isKit, isTrue);
      expect(unit.patternVoices.length, 1);
      expect(unit.requiredSensor, SensorLevel.midi);
    });
  });
}
