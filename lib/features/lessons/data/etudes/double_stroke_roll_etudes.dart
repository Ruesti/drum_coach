import '../../models/rudiment.dart';
import '../etude_dsl.dart';

/// Double Stroke Roll (RRLL RRLL) étude progression: 5 exercises, rising
/// difficulty and tempo, all built on the RRLL double-stroke sticking.
final List<Rudiment> doubleStrokeRollEtudes = <Rudiment>[
  Rudiment(
    id: 'etude_double_stroke_roll_1',
    name: 'Double Stroke Roll · Etude 1',
    description: 'Clean double strokes on a 16th-note grid, with no accents at all.',
    collection: ExerciseCollection.rudimentEtudes,
    collectionGroup: 'Double Stroke Roll',
    difficulty: Difficulty.beginner,
    minBpm: 50,
    targetBpm: 80,
    gridUnit: NoteGrid.sixteenth,
    beatsPerBar: 4,
    skills: {Skill.control},
    sticking: [
      // Bar 1
      ...sixteenths([R, R, L, L]),
      ...sixteenths([R, R, L, L]),
      ...sixteenths([R, R, L, L]),
      ...sixteenths([R, R, L, L]),
      // Bar 2
      ...sixteenths([R, R, L, L]),
      ...sixteenths([R, R, L, L]),
      ...sixteenths([R, R, L, L]),
      ...sixteenths([R, R, L, L]),
    ],
  ),
  Rudiment(
    id: 'etude_double_stroke_roll_2',
    name: 'Double Stroke Roll · Etude 2',
    description: 'Double strokes with the first note accented on beats 1 and 3.',
    collection: ExerciseCollection.rudimentEtudes,
    collectionGroup: 'Double Stroke Roll',
    difficulty: Difficulty.beginner,
    minBpm: 60,
    targetBpm: 90,
    gridUnit: NoteGrid.sixteenth,
    beatsPerBar: 4,
    skills: {Skill.control},
    sticking: [
      // Bar 1 — downbeats (1 & 3) accented
      ...sixteenths([R, R, L, L], accents: {0}), // beat 1
      ...sixteenths([R, R, L, L]),
      ...sixteenths([R, R, L, L], accents: {0}), // beat 3
      ...sixteenths([R, R, L, L]),
      // Bar 2
      ...sixteenths([R, R, L, L], accents: {0}), // beat 1
      ...sixteenths([R, R, L, L]),
      ...sixteenths([R, R, L, L], accents: {0}), // beat 3
      ...sixteenths([R, R, L, L]),
    ],
  ),
  Rudiment(
    id: 'etude_double_stroke_roll_3',
    name: 'Double Stroke Roll · Etude 3',
    description: 'Double strokes with short breathing rests for extra phrasing.',
    collection: ExerciseCollection.rudimentEtudes,
    collectionGroup: 'Double Stroke Roll',
    difficulty: Difficulty.intermediate,
    minBpm: 70,
    targetBpm: 110,
    gridUnit: NoteGrid.sixteenth,
    beatsPerBar: 4,
    skills: {Skill.control},
    sticking: [
      // Bar 1 — rest breaks the roll after beat 3's leading double
      ...sixteenths([R, R, L, L]),
      ...sixteenths([R, R, L, L]),
      note(R, NoteValue.sixteenth),
      note(R, NoteValue.sixteenth),
      rest(NoteValue.eighth), // beat 3: RR then breathe
      ...sixteenths([R, R, L, L]),
      // Bar 2 — second rest, placed on beat 2 for variety
      ...sixteenths([R, R, L, L]),
      note(R, NoteValue.sixteenth),
      note(R, NoteValue.sixteenth),
      rest(NoteValue.eighth), // beat 2: RR then breathe
      ...sixteenths([R, R, L, L]),
      ...sixteenths([R, R, L, L]),
    ],
  ),
  Rudiment(
    id: 'etude_double_stroke_roll_4',
    name: 'Double Stroke Roll · Etude 4',
    description: 'Alternate between dense 16th-note and more open 8th-note doubles.',
    collection: ExerciseCollection.rudimentEtudes,
    collectionGroup: 'Double Stroke Roll',
    difficulty: Difficulty.advanced,
    minBpm: 85,
    targetBpm: 140,
    gridUnit: NoteGrid.sixteenth,
    beatsPerBar: 4,
    skills: {Skill.control, Skill.endurance},
    sticking: [
      // Bar 1 — 16th-note doubles (dense)
      ...sixteenths([R, R, L, L]),
      ...sixteenths([R, R, L, L]),
      ...sixteenths([R, R, L, L]),
      ...sixteenths([R, R, L, L]),
      // Bar 2 — eighth-note doubles (open), two groups = 4 beats
      ...eighths([R, R, L, L]),
      ...eighths([R, R, L, L]),
      // Bar 3 — back to 16th-note doubles
      ...sixteenths([R, R, L, L]),
      ...sixteenths([R, R, L, L]),
      ...sixteenths([R, R, L, L]),
      ...sixteenths([R, R, L, L]),
      // Bar 4 — eighth-note doubles again
      ...eighths([R, R, L, L]),
      ...eighths([R, R, L, L]),
    ],
  ),
  Rudiment(
    id: 'etude_double_stroke_roll_5',
    name: 'Double Stroke Roll · Etude 5',
    description:
        'Accented double strokes at high tempo — every 2-bar phrase ends on an accented single stroke.',
    collection: ExerciseCollection.rudimentEtudes,
    collectionGroup: 'Double Stroke Roll',
    difficulty: Difficulty.professional,
    minBpm: 100,
    targetBpm: 180,
    gridUnit: NoteGrid.sixteenth,
    beatsPerBar: 4,
    skills: {Skill.control, Skill.endurance},
    sticking: [
      // Bar 1 — leading stroke of every double accented (RR LL)
      ...sixteenths([R, R, L, L], accents: {0, 2}),
      ...sixteenths([R, R, L, L], accents: {0, 2}),
      ...sixteenths([R, R, L, L], accents: {0, 2}),
      ...sixteenths([R, R, L, L], accents: {0, 2}),
      // Bar 2 — phrase closes with one accented single stroke
      ...sixteenths([R, R, L, L], accents: {0, 2}),
      ...sixteenths([R, R, L, L], accents: {0, 2}),
      ...sixteenths([R, R, L, L], accents: {0, 2}),
      note(R, NoteValue.quarter, accent: true), // end of phrase 1
      // Bar 3 — second phrase, same accented-doubles pattern
      ...sixteenths([R, R, L, L], accents: {0, 2}),
      ...sixteenths([R, R, L, L], accents: {0, 2}),
      ...sixteenths([R, R, L, L], accents: {0, 2}),
      ...sixteenths([R, R, L, L], accents: {0, 2}),
      // Bar 4 — closes with one accented single stroke
      ...sixteenths([R, R, L, L], accents: {0, 2}),
      ...sixteenths([R, R, L, L], accents: {0, 2}),
      ...sixteenths([R, R, L, L], accents: {0, 2}),
      note(R, NoteValue.quarter, accent: true), // end of phrase 2
    ],
  ),
];
