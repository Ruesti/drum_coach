import '../../models/rudiment.dart';
import '../etude_dsl.dart';

/// Acht eigenständige Sticking-Pattern-Übungen: kurze 2-Takt-Handsatz-
/// Permutationen aus durchgehenden Achtelnoten (8 Noten pro Takt), ohne
/// Akzente oder Ghost Notes. Trainieren reines R/L-Vokabular und
/// Handunabhängigkeit jenseits der klassischen RLRL-Standardmuster.
final List<Rudiment> stickingPatternEtudes = <Rudiment>[
  Rudiment(
    id: 'etude_pad_sticking_1',
    name: 'Sticking-Pattern · Spiegel-Wechsel',
    description:
        'Achtel-Handsatzmuster, dessen zweiter Takt die Hände des ersten spiegelt.',
    collection: ExerciseCollection.padWorkouts,
    collectionGroup: 'Sticking-Patterns',
    difficulty: Difficulty.beginner,
    minBpm: 70,
    targetBpm: 100,
    gridUnit: NoteGrid.eighth,
    beatsPerBar: 4,
    skills: {Skill.coordination, Skill.control},
    sticking: [
      // Takt 1: R L L R L R R L (8 Achtel)
      ...eighths([R, L, L, R, L, R, R, L], accents: {}),
      // Takt 2: Spiegelung (R<->L getauscht) von Takt 1 (8 Achtel)
      ...eighths([L, R, R, L, R, L, L, R], accents: {}),
    ],
  ),
  Rudiment(
    id: 'etude_pad_sticking_2',
    name: 'Sticking-Pattern · Doppelschlag-Fluss',
    description:
        'Kombiniert Doppelschläge (RR/LL) mit Einzelschlägen zu einem fließenden Handwechsel.',
    collection: ExerciseCollection.padWorkouts,
    collectionGroup: 'Sticking-Patterns',
    difficulty: Difficulty.beginner,
    minBpm: 70,
    targetBpm: 100,
    gridUnit: NoteGrid.eighth,
    beatsPerBar: 4,
    skills: {Skill.coordination, Skill.control},
    sticking: [
      // Takt 1: R R L L R L R L (8 Achtel)
      ...eighths([R, R, L, L, R, L, R, L], accents: {}),
      // Takt 2: Spiegelung von Takt 1 (8 Achtel)
      ...eighths([L, L, R, R, L, R, L, R], accents: {}),
    ],
  ),
  Rudiment(
    id: 'etude_pad_sticking_3',
    name: 'Sticking-Pattern · Versetzte Paare',
    description:
        'Verschiebt die Doppelschlag-Position innerhalb des Taktes für ungewohnte Koordination.',
    collection: ExerciseCollection.padWorkouts,
    collectionGroup: 'Sticking-Patterns',
    difficulty: Difficulty.beginner,
    minBpm: 75,
    targetBpm: 105,
    gridUnit: NoteGrid.eighth,
    beatsPerBar: 4,
    skills: {Skill.coordination, Skill.control},
    sticking: [
      // Takt 1: R L R R L R L L (8 Achtel)
      ...eighths([R, L, R, R, L, R, L, L], accents: {}),
      // Takt 2: Spiegelung von Takt 1 (8 Achtel)
      ...eighths([L, R, L, L, R, L, R, R], accents: {}),
    ],
  ),
  Rudiment(
    id: 'etude_pad_sticking_4',
    name: 'Sticking-Pattern · Kreuzmuster',
    description:
        'Zwei benachbarte Doppelschlag-Paare pro Takt für erweiterte Handunabhängigkeit.',
    collection: ExerciseCollection.padWorkouts,
    collectionGroup: 'Sticking-Patterns',
    difficulty: Difficulty.beginner,
    minBpm: 80,
    targetBpm: 110,
    gridUnit: NoteGrid.eighth,
    beatsPerBar: 4,
    skills: {Skill.coordination, Skill.control},
    sticking: [
      // Takt 1: L R R L L R L R (8 Achtel)
      ...eighths([L, R, R, L, L, R, L, R], accents: {}),
      // Takt 2: Spiegelung von Takt 1 (8 Achtel)
      ...eighths([R, L, L, R, R, L, R, L], accents: {}),
    ],
  ),
  Rudiment(
    id: 'etude_pad_sticking_5',
    name: 'Sticking-Pattern · Retrograde',
    description:
        'Takt 2 spielt das Muster aus Takt 1 rückwärts – trainiert Mustererkennung in beide Richtungen.',
    collection: ExerciseCollection.padWorkouts,
    collectionGroup: 'Sticking-Patterns',
    difficulty: Difficulty.intermediate,
    minBpm: 90,
    targetBpm: 120,
    gridUnit: NoteGrid.eighth,
    beatsPerBar: 4,
    skills: {Skill.coordination, Skill.control},
    sticking: [
      // Takt 1: R R L R L L R L (8 Achtel)
      ...eighths([R, R, L, R, L, L, R, L], accents: {}),
      // Takt 2: Rückwärtslauf (Retrograde) von Takt 1 (8 Achtel)
      ...eighths([L, R, L, L, R, L, R, R], accents: {}),
    ],
  ),
  Rudiment(
    id: 'etude_pad_sticking_6',
    name: 'Sticking-Pattern · Tripel-Kontrolle',
    description:
        'Bewusster Dreifachschlag (LLL/RRR) im Muster – Trainingsziel: kontrollierte Tripel-Anschläge ohne Tempo-Einbruch.',
    collection: ExerciseCollection.padWorkouts,
    collectionGroup: 'Sticking-Patterns',
    difficulty: Difficulty.intermediate,
    minBpm: 90,
    targetBpm: 120,
    gridUnit: NoteGrid.eighth,
    beatsPerBar: 4,
    skills: {Skill.coordination, Skill.control},
    sticking: [
      // Takt 1: R L L L R L R R (8 Achtel, LLL als Trainingsziel)
      ...eighths([R, L, L, L, R, L, R, R], accents: {}),
      // Takt 2: Spiegelung von Takt 1 (8 Achtel, RRR als Trainingsziel)
      ...eighths([L, R, R, R, L, R, L, L], accents: {}),
    ],
  ),
  Rudiment(
    id: 'etude_pad_sticking_7',
    name: 'Sticking-Pattern · Versetzte Doppelschläge',
    description:
        'Die Doppelschlag-Positionen verschieben sich zwischen den beiden Takten und fordern schnelles Umdenken.',
    collection: ExerciseCollection.padWorkouts,
    collectionGroup: 'Sticking-Patterns',
    difficulty: Difficulty.intermediate,
    minBpm: 100,
    targetBpm: 130,
    gridUnit: NoteGrid.eighth,
    beatsPerBar: 4,
    skills: {Skill.coordination, Skill.control},
    sticking: [
      // Takt 1: L L R L R R L R (8 Achtel)
      ...eighths([L, L, R, L, R, R, L, R], accents: {}),
      // Takt 2: neues, kontrastierendes Muster mit versetzten Paaren (8 Achtel)
      ...eighths([R, L, R, L, L, R, R, L], accents: {}),
    ],
  ),
  Rudiment(
    id: 'etude_pad_sticking_8',
    name: 'Sticking-Pattern · Kraft & Balance',
    description:
        'Höchste Stufe: bewusste Dreifachschläge plus unausgeglichene Handverteilung (5:3) fordern Kraft und Kontrolle in beiden Händen.',
    collection: ExerciseCollection.padWorkouts,
    collectionGroup: 'Sticking-Patterns',
    difficulty: Difficulty.intermediate,
    minBpm: 100,
    targetBpm: 135,
    gridUnit: NoteGrid.eighth,
    beatsPerBar: 4,
    skills: {Skill.coordination, Skill.control},
    sticking: [
      // Takt 1: R L R R R L R L (8 Achtel, RRR + 5R:3L als Trainingsziel)
      ...eighths([R, L, R, R, R, L, R, L], accents: {}),
      // Takt 2: Spiegelung von Takt 1 (8 Achtel, LLL + 5L:3R als Trainingsziel)
      ...eighths([L, R, L, L, L, R, L, R], accents: {}),
    ],
  ),
];
