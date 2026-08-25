import '../../models/rudiment.dart';
import '../etude_dsl.dart';

/// Six 1-Takt-Zähl-Etüden für absolute Anfänger*innen: Viertel- und
/// Achtelnoten in wechselnden Positionen, um Zählen/Unterteilen zu üben
/// (z.B. "1 2 3 4" reine Viertel, dann "1-und 2 3 4" mit einer Achtelgruppe
/// an wechselnder Position). Sticking ist über die gesamte Notenfolge jeder
/// Etüde strikt alternierend R/L, beginnend mit R – unabhängig davon, ob die
/// einzelne Note eine Viertel oder eine Achtel ist.
final List<Rudiment> beginnerCountEtudes = <Rudiment>[
  Rudiment(
    id: 'etude_pad_basics_1',
    name: 'Zähl-Etüde 1 · Viertel',
    description: 'Vier Viertelnoten – der Grundpuls zum Zählen "1 2 3 4".',
    collection: ExerciseCollection.padWorkouts,
    collectionGroup: 'Grundlagen',
    difficulty: Difficulty.beginner,
    minBpm: 50,
    targetBpm: 90,
    gridUnit: NoteGrid.eighth,
    beatsPerBar: 4,
    skills: {Skill.control},
    sticking: [
      // 1.0 + 1.0 + 1.0 + 1.0 = 4.0 quarters
      note(R, NoteValue.quarter),
      note(L, NoteValue.quarter),
      note(R, NoteValue.quarter),
      note(L, NoteValue.quarter),
    ],
  ),
  Rudiment(
    id: 'etude_pad_basics_2',
    name: 'Zähl-Etüde 2 · Achtel auf 1',
    description:
        'Eine Achtelgruppe auf Zählzeit 1, danach drei Viertel: "1-und 2 3 4".',
    collection: ExerciseCollection.padWorkouts,
    collectionGroup: 'Grundlagen',
    difficulty: Difficulty.beginner,
    minBpm: 50,
    targetBpm: 90,
    gridUnit: NoteGrid.eighth,
    beatsPerBar: 4,
    skills: {Skill.control},
    sticking: [
      // 0.5 + 0.5 + 1.0 + 1.0 + 1.0 = 4.0 quarters
      note(R, NoteValue.eighth),
      note(L, NoteValue.eighth),
      note(R, NoteValue.quarter),
      note(L, NoteValue.quarter),
      note(R, NoteValue.quarter),
    ],
  ),
  Rudiment(
    id: 'etude_pad_basics_3',
    name: 'Zähl-Etüde 3 · Achtel auf 2',
    description:
        'Viertel auf 1, Achtelgruppe auf Zählzeit 2, dann zwei Viertel: '
        '"1 2-und 3 4".',
    collection: ExerciseCollection.padWorkouts,
    collectionGroup: 'Grundlagen',
    difficulty: Difficulty.beginner,
    minBpm: 50,
    targetBpm: 90,
    gridUnit: NoteGrid.eighth,
    beatsPerBar: 4,
    skills: {Skill.control},
    sticking: [
      // 1.0 + 0.5 + 0.5 + 1.0 + 1.0 = 4.0 quarters
      note(R, NoteValue.quarter),
      note(L, NoteValue.eighth),
      note(R, NoteValue.eighth),
      note(L, NoteValue.quarter),
      note(R, NoteValue.quarter),
    ],
  ),
  Rudiment(
    id: 'etude_pad_basics_4',
    name: 'Zähl-Etüde 4 · Achtel auf 3',
    description:
        'Zwei Viertel, Achtelgruppe auf Zählzeit 3, dann eine Viertel: '
        '"1 2 3-und 4".',
    collection: ExerciseCollection.padWorkouts,
    collectionGroup: 'Grundlagen',
    difficulty: Difficulty.beginner,
    minBpm: 50,
    targetBpm: 90,
    gridUnit: NoteGrid.eighth,
    beatsPerBar: 4,
    skills: {Skill.control},
    sticking: [
      // 1.0 + 1.0 + 0.5 + 0.5 + 1.0 = 4.0 quarters
      note(R, NoteValue.quarter),
      note(L, NoteValue.quarter),
      note(R, NoteValue.eighth),
      note(L, NoteValue.eighth),
      note(R, NoteValue.quarter),
    ],
  ),
  Rudiment(
    id: 'etude_pad_basics_5',
    name: 'Zähl-Etüde 5 · Achtel auf 4',
    description:
        'Drei Viertel, Achtelgruppe auf Zählzeit 4: "1 2 3 4-und".',
    collection: ExerciseCollection.padWorkouts,
    collectionGroup: 'Grundlagen',
    difficulty: Difficulty.beginner,
    minBpm: 50,
    targetBpm: 90,
    gridUnit: NoteGrid.eighth,
    beatsPerBar: 4,
    skills: {Skill.control},
    sticking: [
      // 1.0 + 1.0 + 1.0 + 0.5 + 0.5 = 4.0 quarters
      note(R, NoteValue.quarter),
      note(L, NoteValue.quarter),
      note(R, NoteValue.quarter),
      note(L, NoteValue.eighth),
      note(R, NoteValue.eighth),
    ],
  ),
  Rudiment(
    id: 'etude_pad_basics_6',
    name: 'Zähl-Etüde 6 · Achtel auf 1 und 3',
    description:
        'Zwei Achtelgruppen auf Zählzeit 1 und 3, dazwischen und danach '
        'Viertel: "1-und 2 3-und 4".',
    collection: ExerciseCollection.padWorkouts,
    collectionGroup: 'Grundlagen',
    difficulty: Difficulty.beginner,
    minBpm: 50,
    targetBpm: 90,
    gridUnit: NoteGrid.eighth,
    beatsPerBar: 4,
    skills: {Skill.control},
    sticking: [
      // 0.5 + 0.5 + 1.0 + 0.5 + 0.5 + 1.0 = 4.0 quarters
      note(R, NoteValue.eighth),
      note(L, NoteValue.eighth),
      note(R, NoteValue.quarter),
      note(L, NoteValue.eighth),
      note(R, NoteValue.eighth),
      note(L, NoteValue.quarter),
    ],
  ),
];
