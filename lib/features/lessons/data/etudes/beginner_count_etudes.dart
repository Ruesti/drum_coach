import '../../models/rudiment.dart';
import '../etude_dsl.dart';

/// Six short, self-contained beginner pieces (4 bars each) instead of one
/// long list of unrelated 1-bar lines. Every piece uses a clear
/// "Frage/Antwort" (question/answer) shape: bars 1–2 state a 2-bar idea
/// that places an eighth-note group at one position in the bar, bars 3–4
/// answer with the same idea at a different, complementary position — like
/// a rhyme. Difficulty rises gently: pieces 1–2 use one eighth-group per
/// bar, 3–4 use two, 5–6 add denser eighth-note coverage (piece 5) and an
/// accent-driven syncopation "rhyme" (piece 6), while staying fully on the
/// eighth-note grid so it's always easy to count. Sticking alternates
/// strictly R/L within every bar, restarting on R each bar (like a new
/// verse). Inspired by (not copied from) a beginner PDF the user provided
/// under docs/Übungen/ (see docs/Übungen/README.md).

// --- 1-Achtelgruppe-pro-Takt Bausteine (5 Noten, R L R L R) ---------------

/// Achtelgruppe auf Zählzeit 1: Achtel Achtel Viertel Viertel Viertel.
List<StrokeBeat> _eighthOnBeat1() => [
      note(R, NoteValue.eighth), note(L, NoteValue.eighth),
      note(R, NoteValue.quarter), note(L, NoteValue.quarter),
      note(R, NoteValue.quarter),
    ];

/// Achtelgruppe auf Zählzeit 2: Viertel Achtel Achtel Viertel Viertel.
List<StrokeBeat> _eighthOnBeat2() => [
      note(R, NoteValue.quarter),
      note(L, NoteValue.eighth), note(R, NoteValue.eighth),
      note(L, NoteValue.quarter), note(R, NoteValue.quarter),
    ];

/// Achtelgruppe auf Zählzeit 3: Viertel Viertel Achtel Achtel Viertel.
List<StrokeBeat> _eighthOnBeat3() => [
      note(R, NoteValue.quarter), note(L, NoteValue.quarter),
      note(R, NoteValue.eighth), note(L, NoteValue.eighth),
      note(R, NoteValue.quarter),
    ];

/// Achtelgruppe auf Zählzeit 4: Viertel Viertel Viertel Achtel Achtel.
List<StrokeBeat> _eighthOnBeat4() => [
      note(R, NoteValue.quarter), note(L, NoteValue.quarter),
      note(R, NoteValue.quarter),
      note(L, NoteValue.eighth), note(R, NoteValue.eighth),
    ];

// --- 2-Achtelgruppen-pro-Takt Bausteine (6 Noten, R L R L R L) ------------

/// Achtelgruppen auf 1 + 3 (Off-Beat-Paare, mit Viertel auf 2 und 4).
List<StrokeBeat> _eighthsOnBeats1and3() => [
      note(R, NoteValue.eighth), note(L, NoteValue.eighth),
      note(R, NoteValue.quarter),
      note(L, NoteValue.eighth), note(R, NoteValue.eighth),
      note(L, NoteValue.quarter),
    ];

/// Achtelgruppen auf 2 + 4 (On-Beat-Paare, mit Viertel auf 1 und 3).
List<StrokeBeat> _eighthsOnBeats2and4() => [
      note(R, NoteValue.quarter),
      note(L, NoteValue.eighth), note(R, NoteValue.eighth),
      note(L, NoteValue.quarter),
      note(R, NoteValue.eighth), note(L, NoteValue.eighth),
    ];

/// Achtelgruppen vorne im Takt (1 + 2, vier Achtel am Stück, dann 2 Viertel).
List<StrokeBeat> _eighthsFront() => [
      note(R, NoteValue.eighth), note(L, NoteValue.eighth),
      note(R, NoteValue.eighth), note(L, NoteValue.eighth),
      note(R, NoteValue.quarter), note(L, NoteValue.quarter),
    ];

/// Achtelgruppen hinten im Takt (3 + 4, zwei Viertel, dann vier Achtel).
List<StrokeBeat> _eighthsBack() => [
      note(R, NoteValue.quarter), note(L, NoteValue.quarter),
      note(R, NoteValue.eighth), note(L, NoteValue.eighth),
      note(R, NoteValue.eighth), note(L, NoteValue.eighth),
    ];

// --- Dichtere Bausteine für Stück 5+6 --------------------------------------

/// Sechs Achtel, Kadenz-Viertel am Taktende (Zählzeit 4).
List<StrokeBeat> _sixEighthsCadenceEnd() => [
      note(R, NoteValue.eighth), note(L, NoteValue.eighth),
      note(R, NoteValue.eighth), note(L, NoteValue.eighth),
      note(R, NoteValue.eighth), note(L, NoteValue.eighth),
      note(R, NoteValue.quarter),
    ];

/// Sechs Achtel, Kadenz-Viertel am Taktanfang (Zählzeit 1).
List<StrokeBeat> _sixEighthsCadenceStart() => [
      note(R, NoteValue.quarter),
      note(L, NoteValue.eighth), note(R, NoteValue.eighth),
      note(L, NoteValue.eighth), note(R, NoteValue.eighth),
      note(L, NoteValue.eighth), note(R, NoteValue.eighth),
    ];

/// Volle Achtel-Kadenz mit Akzent auf dem Off-Beat von Zählzeit 1 und 3.
List<StrokeBeat> _fullEighthsAccent1and3() =>
    eighths([R, L, R, L, R, L, R, L], accents: {1, 5});

/// Volle Achtel-Kadenz mit Akzent auf dem Off-Beat von Zählzeit 2 und 4.
List<StrokeBeat> _fullEighthsAccent2and4() =>
    eighths([R, L, R, L, R, L, R, L], accents: {3, 7});

final List<Rudiment> beginnerCountEtudes = <Rudiment>[
  Rudiment(
    id: 'etude_pad_basics_1',
    name: 'Grundlagen · Frage-Antwort I',
    description:
        'Frage (Takt 1–2): Achtelgruppe auf Zählzeit 1. Antwort (Takt 3–4): '
        'dieselbe Idee auf Zählzeit 3 beantwortet — wie ein Reim.',
    collection: ExerciseCollection.padWorkouts,
    collectionGroup: 'Grundlagen',
    difficulty: Difficulty.beginner,
    minBpm: 50,
    targetBpm: 100,
    gridUnit: NoteGrid.eighth,
    beatsPerBar: 4,
    skills: {Skill.control},
    sticking: [
      ..._eighthOnBeat1(), ..._eighthOnBeat1(), // Frage: Takt 1-2
      ..._eighthOnBeat3(), ..._eighthOnBeat3(), // Antwort: Takt 3-4
    ],
  ),
  Rudiment(
    id: 'etude_pad_basics_2',
    name: 'Grundlagen · Frage-Antwort II',
    description:
        'Frage (Takt 1–2): Achtelgruppe auf Zählzeit 2. Antwort (Takt 3–4): '
        'dieselbe Idee auf Zählzeit 4 beantwortet.',
    collection: ExerciseCollection.padWorkouts,
    collectionGroup: 'Grundlagen',
    difficulty: Difficulty.beginner,
    minBpm: 50,
    targetBpm: 100,
    gridUnit: NoteGrid.eighth,
    beatsPerBar: 4,
    skills: {Skill.control},
    sticking: [
      ..._eighthOnBeat2(), ..._eighthOnBeat2(), // Frage: Takt 1-2
      ..._eighthOnBeat4(), ..._eighthOnBeat4(), // Antwort: Takt 3-4
    ],
  ),
  Rudiment(
    id: 'etude_pad_basics_3',
    name: 'Grundlagen · Frage-Antwort III',
    description:
        'Frage (Takt 1–2): zwei Achtelgruppen auf den Off-Beat-Zählzeiten '
        '1+3. Antwort (Takt 3–4): dieselbe Idee auf den On-Beat-Zählzeiten '
        '2+4 beantwortet.',
    collection: ExerciseCollection.padWorkouts,
    collectionGroup: 'Grundlagen',
    difficulty: Difficulty.beginner,
    minBpm: 50,
    targetBpm: 100,
    gridUnit: NoteGrid.eighth,
    beatsPerBar: 4,
    skills: {Skill.control},
    sticking: [
      ..._eighthsOnBeats1and3(), ..._eighthsOnBeats1and3(), // Frage
      ..._eighthsOnBeats2and4(), ..._eighthsOnBeats2and4(), // Antwort
    ],
  ),
  Rudiment(
    id: 'etude_pad_basics_4',
    name: 'Grundlagen · Frage-Antwort IV',
    description:
        'Frage (Takt 1–2): zwei Achtelgruppen vorne im Takt (Zählzeit 1+2). '
        'Antwort (Takt 3–4): dieselbe Idee hinten im Takt (Zählzeit 3+4) '
        'beantwortet.',
    collection: ExerciseCollection.padWorkouts,
    collectionGroup: 'Grundlagen',
    difficulty: Difficulty.beginner,
    minBpm: 50,
    targetBpm: 100,
    gridUnit: NoteGrid.eighth,
    beatsPerBar: 4,
    skills: {Skill.control},
    sticking: [
      ..._eighthsFront(), ..._eighthsFront(), // Frage: Takt 1-2
      ..._eighthsBack(), ..._eighthsBack(), // Antwort: Takt 3-4
    ],
  ),
  Rudiment(
    id: 'etude_pad_basics_5',
    name: 'Grundlagen · Frage-Antwort V',
    description:
        'Frage (Takt 1–2): durchgehende Achtel mit Viertel-Kadenz am '
        'Taktende (Zählzeit 4). Antwort (Takt 3–4): dieselbe Achtel-Kadenz '
        'an den Taktanfang (Zählzeit 1) verschoben.',
    collection: ExerciseCollection.padWorkouts,
    collectionGroup: 'Grundlagen',
    difficulty: Difficulty.beginner,
    minBpm: 50,
    targetBpm: 100,
    gridUnit: NoteGrid.eighth,
    beatsPerBar: 4,
    skills: {Skill.control},
    sticking: [
      ..._sixEighthsCadenceEnd(), ..._sixEighthsCadenceEnd(), // Frage
      ..._sixEighthsCadenceStart(), ..._sixEighthsCadenceStart(), // Antwort
    ],
  ),
  Rudiment(
    id: 'etude_pad_basics_6',
    name: 'Grundlagen · Frage-Antwort VI',
    description:
        'Frage (Takt 1–2): durchgehende Achtel mit Akzent auf dem Off-Beat '
        'von Zählzeit 1 und 3. Antwort (Takt 3–4): dieselbe Idee mit Akzent '
        'auf dem Off-Beat von Zählzeit 2 und 4 beantwortet — ein '
        'Synkopen-Reim.',
    collection: ExerciseCollection.padWorkouts,
    collectionGroup: 'Grundlagen',
    difficulty: Difficulty.beginner,
    minBpm: 50,
    targetBpm: 100,
    gridUnit: NoteGrid.eighth,
    beatsPerBar: 4,
    skills: {Skill.control},
    sticking: [
      ..._fullEighthsAccent1and3(), ..._fullEighthsAccent1and3(), // Frage
      ..._fullEighthsAccent2and4(), ..._fullEighthsAccent2and4(), // Antwort
    ],
  ),
];
