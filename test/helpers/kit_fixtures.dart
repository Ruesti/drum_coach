import 'package:drum_coach/features/coaching/midi/kit_instrument.dart';
import 'package:drum_coach/features/coaching/services/stroke_source.dart';
import 'package:drum_coach/features/lessons/data/etude_dsl.dart';
import 'package:drum_coach/features/lessons/models/rudiment.dart';

/// A showcase kit exercise: a rock groove and a line that touches every
/// head shape (toms, crash, open hat, ride bell, china, splash, cross-stick,
/// ghost, flam, hi-hat pedal) — the golden shows them all at once.
Rudiment kitShowcase() {
  List<StrokeBeat> hh8() => eighths([R, R, R, R, R, R, R, R]);
  List<StrokeBeat> backbeat() => [
        rest(NoteValue.quarter),
        note(L, NoteValue.quarter, accent: true),
        rest(NoteValue.quarter),
        note(L, NoteValue.quarter, accent: true),
      ];
  List<StrokeBeat> kick13() => [
        foot(NoteValue.quarter),
        rest(NoteValue.quarter),
        foot(NoteValue.quarter),
        rest(NoteValue.quarter),
      ];
  final pattern = [
    voice(KitInstrument.hiHatClosed, hh8()),
    voice(KitInstrument.snare, backbeat()),
    voice(KitInstrument.kick, kick13()),
  ];
  final groove = kitLine([
    voice(KitInstrument.hiHatClosed, [...hh8(), ...hh8()]),
    voice(KitInstrument.snare, [...backbeat(), ...backbeat()]),
    voice(KitInstrument.kick, [...kick13(), ...kick13()]),
  ], counts: true);
  // Bar 1: hi-hat eighths with the "&" of 4 open, snare ghost on the "e"
  // of 3, flam on 4, cross-stick on 2; kick 1 and "a" of 2; pedal on 2 + 4.
  // Bar 2: a sixteenth run snare → tom1 → tom2 → floor tom with ride bell
  // and china on 3, splash + crash on 4, kick under every beat.
  final fill = kitLine([
    voice(KitInstrument.hiHatClosed, [
      ...eighths([R, R, R, R, R, R, R]),
      rest(NoteValue.eighth),
      ...[for (var i = 0; i < 4; i++) rest(NoteValue.quarter)],
    ]),
    voice(KitInstrument.hiHatOpen, [
      rest(NoteValue.half),
      rest(NoteValue.quarter),
      rest(NoteValue.eighth),
      note(R, NoteValue.eighth),
      ...[for (var i = 0; i < 4; i++) rest(NoteValue.quarter)],
    ]),
    voice(KitInstrument.snare, [
      rest(NoteValue.quarter),
      rest(NoteValue.quarter),
      rest(NoteValue.sixteenth),
      note(L, NoteValue.sixteenth, ghost: true),
      rest(NoteValue.eighth),
      flam(L, NoteValue.quarter, accent: true),
      ...sixteenths([R, L, R, L]),
      ...[for (var i = 0; i < 3; i++) rest(NoteValue.quarter)],
    ]),
    voice(KitInstrument.snareRim, [
      rest(NoteValue.quarter),
      note(L, NoteValue.quarter),
      rest(NoteValue.half),
      rest(NoteValue.whole),
    ]),
    voice(
        KitInstrument.tom1,
        [
          rest(NoteValue.whole),
          rest(NoteValue.quarter),
          ...sixteenths([R, L, R, L]),
          rest(NoteValue.half),
        ],
        accepts: InstrumentClass.anyTom),
    voice(
        KitInstrument.tom2,
        [
          rest(NoteValue.whole),
          rest(NoteValue.half),
          ...sixteenths([R, L]),
          rest(NoteValue.eighth),
          rest(NoteValue.quarter),
        ],
        accepts: InstrumentClass.anyTom),
    voice(
        KitInstrument.floorTom1,
        [
          rest(NoteValue.whole),
          rest(NoteValue.half),
          rest(NoteValue.eighth),
          ...sixteenths([R, L]),
          rest(NoteValue.quarter),
        ],
        accepts: InstrumentClass.anyTom),
    voice(KitInstrument.rideBell, [
      rest(NoteValue.whole),
      rest(NoteValue.half),
      note(R, NoteValue.quarter),
      rest(NoteValue.quarter),
    ]),
    voice(KitInstrument.china, [
      rest(NoteValue.whole),
      rest(NoteValue.half),
      rest(NoteValue.eighth),
      note(R, NoteValue.eighth),
      rest(NoteValue.quarter),
    ]),
    voice(
        KitInstrument.crash1,
        [
          rest(NoteValue.whole),
          rest(NoteValue.half),
          rest(NoteValue.quarter),
          note(R, NoteValue.quarter, accent: true),
        ],
        accepts: InstrumentClass.anyCrash),
    voice(KitInstrument.splash, [
      rest(NoteValue.whole),
      rest(NoteValue.half),
      rest(NoteValue.quarter),
      rest(NoteValue.eighth),
      note(L, NoteValue.eighth),
    ]),
    voice(KitInstrument.kick, [
      foot(NoteValue.quarter),
      rest(NoteValue.eighth, dotted: true),
      foot(NoteValue.sixteenth),
      rest(NoteValue.half),
      ...[for (var i = 0; i < 4; i++) foot(NoteValue.quarter)],
    ]),
    voice(KitInstrument.hiHatPedal, [
      rest(NoteValue.quarter),
      foot(NoteValue.quarter),
      rest(NoteValue.quarter),
      foot(NoteValue.quarter),
      rest(NoteValue.whole),
    ]),
  ], repeat: false, title: 'Around');
  return Rudiment(
    id: 'kit_showcase',
    name: 'Kit showcase',
    description: '',
    minBpm: 60,
    targetBpm: 120,
    difficulty: Difficulty.intermediate,
    sticking: pattern.first.beats,
    gridUnit: NoteGrid.eighth,
    voicing: ExerciseVoicing.kit,
    requiredSensor: SensorLevel.midi,
    limbs: {Limb.allFour},
    patternVoices: pattern,
    lines: [groove, fill],
  );
}

/// Double bass: hat quarters, backbeat, kick sixteenths R L; line 2 adds
/// the pedal on 2 and 4 and a bar of plain (unsided) kick quarters.
Rudiment doubleBassShowcase() {
  List<StrokeBeat> hhQ() => [for (var i = 0; i < 4; i++) note(R, NoteValue.quarter)];
  List<StrokeBeat> backbeat() => [
        rest(NoteValue.quarter),
        note(L, NoteValue.quarter, accent: true),
        rest(NoteValue.quarter),
        note(L, NoteValue.quarter, accent: true),
      ];
  List<StrokeBeat> db16() => [
        for (var i = 0; i < 8; i++) ...[
          foot(NoteValue.sixteenth, side: R),
          foot(NoteValue.sixteenth, side: L),
        ],
      ];
  List<StrokeBeat> kickQ() => [for (var i = 0; i < 4; i++) foot(NoteValue.quarter)];
  final pattern = [
    voice(KitInstrument.hiHatClosed, hhQ()),
    voice(KitInstrument.snare, backbeat()),
    voice(KitInstrument.kick, db16()),
  ];
  return Rudiment(
    id: 'double_bass_showcase',
    name: 'Double bass showcase',
    description: '',
    minBpm: 60,
    targetBpm: 160,
    difficulty: Difficulty.advanced,
    sticking: pattern.first.beats,
    gridUnit: NoteGrid.sixteenth,
    voicing: ExerciseVoicing.kit,
    requiredSensor: SensorLevel.midi,
    limbs: {Limb.doubleBass},
    patternVoices: pattern,
    lines: [
      kitLine([
        voice(KitInstrument.hiHatClosed, [...hhQ(), ...hhQ()]),
        voice(KitInstrument.snare, [...backbeat(), ...backbeat()]),
        voice(KitInstrument.kick, [...db16(), ...db16()]),
      ], counts: true),
      kitLine([
        voice(KitInstrument.hiHatClosed, [...hhQ(), ...hhQ()]),
        voice(KitInstrument.snare, [...backbeat(), ...backbeat()]),
        voice(KitInstrument.kick, [...db16(), ...kickQ()]),
        voice(KitInstrument.hiHatPedal, [
          for (var i = 0; i < 2; i++) ...[
            rest(NoteValue.quarter),
            foot(NoteValue.quarter),
            rest(NoteValue.quarter),
            foot(NoteValue.quarter),
          ],
        ]),
      ], repeat: false, title: 'Pedal'),
    ],
  );
}
