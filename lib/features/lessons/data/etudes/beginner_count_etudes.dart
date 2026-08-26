import '../../models/rudiment.dart';
import '../etude_dsl.dart';

/// Six short, self-contained beginner pieces (4 bars each) instead of one
/// long list of unrelated 1-bar lines. Every piece has one clear idea: an
/// eighth-note group moves from one position in bars 1–2 to a different,
/// related position in bars 3–4 (the same shape, just relocated) — never a
/// random new pattern out of nowhere. Difficulty rises gently: pieces 1–2
/// move one eighth-group per bar, 3–4 move two, 5–6 add denser eighth-note
/// coverage (piece 5) and a moving accent (piece 6), while staying fully on
/// the eighth-note grid so it's always easy to count. Sticking alternates
/// strictly R/L within every bar, restarting on R each bar. Inspired by
/// (not copied from) a beginner PDF the user provided under docs/Übungen/
/// (see docs/Übungen/README.md).

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
    name: 'Grundlagen · Achtelgruppe 1→3',
    description:
        'Eine Achtelgruppe wandert von Zählzeit 1 (Takt 1–2) zu Zählzeit 3 '
        '(Takt 3–4) — dieselbe Idee, nur an anderer Stelle im Takt.',
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
    name: 'Grundlagen · Achtelgruppe 2→4',
    description:
        'Eine Achtelgruppe wandert von Zählzeit 2 (Takt 1–2) zu Zählzeit 4 '
        '(Takt 3–4).',
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
    name: 'Grundlagen · Zwei Achtelgruppen springen',
    description:
        'Zwei Achtelgruppen springen von den Zählzeiten 1+3 (Takt 1–2) zu '
        'den Zählzeiten 2+4 (Takt 3–4).',
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
    name: 'Grundlagen · Vorne nach hinten',
    description:
        'Zwei Achtelgruppen wandern von vorne im Takt (Zählzeit 1+2, Takt '
        '1–2) nach hinten (Zählzeit 3+4, Takt 3–4).',
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
    name: 'Grundlagen · Kadenz wandert',
    description:
        'Durchgehende Achtel mit einer Viertel-Kadenz, die vom Taktende '
        '(Zählzeit 4, Takt 1–2) an den Taktanfang (Zählzeit 1, Takt 3–4) '
        'wandert.',
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
    name: 'Grundlagen · Wandernder Akzent',
    description:
        'Durchgehende Achtel, deren Akzent auf dem Zwischenschlag von '
        'Zählzeit 1+3 (Takt 1–2) zu Zählzeit 2+4 (Takt 3–4) wandert.',
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
