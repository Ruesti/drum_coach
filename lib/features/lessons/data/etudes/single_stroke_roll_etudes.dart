import '../../models/rudiment.dart';
import '../etude_dsl.dart';

/// Five Single Stroke Roll (RLRL) études, rising complexity and tempo:
/// 1) plain accented 16ths, 2) downbeat-only accents, 3) phrased with rests,
/// 4) straight 16ths into 16th-sextuplets, 5) migrating-accent challenge.
final List<Rudiment> singleStrokeRollEtudes = <Rudiment>[
  Rudiment(
    id: 'etude_single_stroke_roll_1',
    name: 'Single Stroke Roll · Etude 1',
    description: 'Pure 16th-note single strokes with an accent on every stroke.',
    collection: ExerciseCollection.rudimentEtudes,
    collectionGroup: 'Single Stroke Roll',
    difficulty: Difficulty.beginner,
    minBpm: 60,
    targetBpm: 90,
    gridUnit: NoteGrid.sixteenth,
    beatsPerBar: 4,
    skills: {Skill.control},
    sticking: [
      // 2 bars: every beat is RLRL, accent on the downbeat of each beat.
      for (var beat = 0; beat < 8; beat++)
        ...sixteenths([R, L, R, L], accents: {0}),
    ],
  ),
  Rudiment(
    id: 'etude_single_stroke_roll_2',
    name: 'Single Stroke Roll · Etude 2',
    description: '16th-note single strokes with accents on beats 1 and 3.',
    collection: ExerciseCollection.rudimentEtudes,
    collectionGroup: 'Single Stroke Roll',
    difficulty: Difficulty.beginner,
    minBpm: 70,
    targetBpm: 100,
    gridUnit: NoteGrid.sixteenth,
    beatsPerBar: 4,
    skills: {Skill.control},
    sticking: [
      // 2 bars: RLRL every beat, but only beats 1 & 3 carry the accent.
      for (var bar = 0; bar < 2; bar++)
        for (var beat = 0; beat < 4; beat++)
          ...sixteenths([R, L, R, L], accents: beat.isEven ? {0} : {}),
    ],
  ),
  Rudiment(
    id: 'etude_single_stroke_roll_3',
    name: 'Single Stroke Roll · Etude 3',
    description: 'Phrased 16ths with rests – a musical motif.',
    collection: ExerciseCollection.rudimentEtudes,
    collectionGroup: 'Single Stroke Roll',
    difficulty: Difficulty.intermediate,
    minBpm: 80,
    targetBpm: 120,
    gridUnit: NoteGrid.sixteenth,
    beatsPerBar: 4,
    skills: {Skill.control},
    sticking: [
      // Bar 1: "call" – note-note-rest-rest, then rest-rest-note-note,
      // repeated. Rest groups are always 2 cells long, so the sticking on
      // every played note keeps strictly alternating RLRL.
      note(R, NoteValue.sixteenth, accent: true), note(L, NoteValue.sixteenth),
      rest(NoteValue.sixteenth), rest(NoteValue.sixteenth),
      rest(NoteValue.sixteenth), rest(NoteValue.sixteenth),
      note(R, NoteValue.sixteenth), note(L, NoteValue.sixteenth),
      note(R, NoteValue.sixteenth, accent: true), note(L, NoteValue.sixteenth),
      rest(NoteValue.sixteenth), rest(NoteValue.sixteenth),
      rest(NoteValue.sixteenth), rest(NoteValue.sixteenth),
      note(R, NoteValue.sixteenth), note(L, NoteValue.sixteenth),
      // Bar 2: "response" – the mirrored phrase (rest first, then note).
      rest(NoteValue.sixteenth), rest(NoteValue.sixteenth),
      note(R, NoteValue.sixteenth), note(L, NoteValue.sixteenth),
      note(R, NoteValue.sixteenth, accent: true), note(L, NoteValue.sixteenth),
      rest(NoteValue.sixteenth), rest(NoteValue.sixteenth),
      rest(NoteValue.sixteenth), rest(NoteValue.sixteenth),
      note(R, NoteValue.sixteenth), note(L, NoteValue.sixteenth),
      note(R, NoteValue.sixteenth, accent: true), note(L, NoteValue.sixteenth),
      rest(NoteValue.sixteenth), rest(NoteValue.sixteenth),
    ],
  ),
  Rudiment(
    id: 'etude_single_stroke_roll_4',
    name: 'Single Stroke Roll · Etude 4',
    description: 'From straight 16ths into 16th-note sextuplets – a faster feel.',
    collection: ExerciseCollection.rudimentEtudes,
    collectionGroup: 'Single Stroke Roll',
    difficulty: Difficulty.advanced,
    minBpm: 95,
    targetBpm: 150,
    gridUnit: NoteGrid.sixteenth,
    beatsPerBar: 4,
    skills: {Skill.control, Skill.endurance},
    sticking: [
      // Bars 1-2: straight 16th singles, accent on every downbeat.
      for (var beat = 0; beat < 8; beat++)
        ...sixteenths([R, L, R, L], accents: {0}),
      // Bars 3-4: 16th-note sextuplets (6 singles per beat), same accent feel.
      for (var beat = 0; beat < 8; beat++)
        ...sextuplet16([R, L, R, L, R, L], accents: {0}),
    ],
  ),
  Rudiment(
    id: 'etude_single_stroke_roll_5',
    name: 'Single Stroke Roll · Etude 5',
    description: 'A moving accent over continuous 16ths – top speed.',
    collection: ExerciseCollection.rudimentEtudes,
    collectionGroup: 'Single Stroke Roll',
    difficulty: Difficulty.professional,
    minBpm: 110,
    targetBpm: 200,
    gridUnit: NoteGrid.sixteenth,
    beatsPerBar: 4,
    skills: {Skill.control, Skill.endurance},
    sticking: [
      // Continuous RLRL 16ths; the accented 16th-note position within the
      // beat migrates 1 -> 2 -> 3 -> 4, one full bar per position.
      for (var beat = 0; beat < 4; beat++)
        ...sixteenths([R, L, R, L], accents: {0}),
      for (var beat = 0; beat < 4; beat++)
        ...sixteenths([R, L, R, L], accents: {1}),
      for (var beat = 0; beat < 4; beat++)
        ...sixteenths([R, L, R, L], accents: {2}),
      for (var beat = 0; beat < 4; beat++)
        ...sixteenths([R, L, R, L], accents: {3}),
    ],
  ),
];
