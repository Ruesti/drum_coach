import '../../models/rudiment.dart';
import '../etude_dsl.dart';

/// One page-length beginner étude: 8 short 1-bar count/subdivision ideas,
/// each written out twice (matching the repeat-sign phrasing of a real
/// method-book line) for 16 bars total — progressively mixing quarter and
/// eighth notes. Inspired by (not copied from) a beginner PDF the user
/// provided under docs/Übungen/ (see docs/Übungen/README.md). Sticking
/// alternates R/L within each line (odd-length lines restart on R at the
/// repeat, same as a real method-book repeat bar).
final List<Rudiment> beginnerCountEtudes = <Rudiment>[
  Rudiment(
    id: 'etude_pad_basics_page',
    name: 'Grundlagen · Zählen & Unterteilen',
    description:
        '8 Zeilen, die Viertel und Achtel an wechselnder Position kombinieren '
        '— jede Zeile zweimal gespielt, wie ein Übungsblatt mit '
        'Wiederholungszeichen.',
    collection: ExerciseCollection.padWorkouts,
    collectionGroup: 'Grundlagen',
    difficulty: Difficulty.beginner,
    minBpm: 50,
    targetBpm: 100,
    gridUnit: NoteGrid.eighth,
    beatsPerBar: 4,
    skills: {Skill.control},
    sticking: [
      // Zeile 1: reine Viertel (Basis-Zählen), 2x.
      for (var i = 0; i < 2; i++) ...[
        note(R, NoteValue.quarter), note(L, NoteValue.quarter),
        note(R, NoteValue.quarter), note(L, NoteValue.quarter),
      ],
      // Zeile 2: Achtelgruppe auf Zählzeit 1, 2x.
      for (var i = 0; i < 2; i++) ...[
        note(R, NoteValue.eighth), note(L, NoteValue.eighth),
        note(R, NoteValue.quarter), note(L, NoteValue.quarter),
        note(R, NoteValue.quarter),
      ],
      // Zeile 3: Achtelgruppe auf Zählzeit 2, 2x.
      for (var i = 0; i < 2; i++) ...[
        note(R, NoteValue.quarter),
        note(L, NoteValue.eighth), note(R, NoteValue.eighth),
        note(L, NoteValue.quarter), note(R, NoteValue.quarter),
      ],
      // Zeile 4: Achtelgruppe auf Zählzeit 3, 2x.
      for (var i = 0; i < 2; i++) ...[
        note(R, NoteValue.quarter), note(L, NoteValue.quarter),
        note(R, NoteValue.eighth), note(L, NoteValue.eighth),
        note(R, NoteValue.quarter),
      ],
      // Zeile 5: Achtelgruppe auf Zählzeit 4, 2x.
      for (var i = 0; i < 2; i++) ...[
        note(R, NoteValue.quarter), note(L, NoteValue.quarter),
        note(R, NoteValue.quarter),
        note(L, NoteValue.eighth), note(R, NoteValue.eighth),
      ],
      // Zeile 6: zwei Achtelgruppen (1 + 3), 2x.
      for (var i = 0; i < 2; i++) ...[
        note(R, NoteValue.eighth), note(L, NoteValue.eighth),
        note(R, NoteValue.quarter),
        note(L, NoteValue.eighth), note(R, NoteValue.eighth),
        note(L, NoteValue.quarter),
      ],
      // Zeile 7: zwei Achtelgruppen (2 + 4), 2x.
      for (var i = 0; i < 2; i++) ...[
        note(R, NoteValue.quarter),
        note(L, NoteValue.eighth), note(R, NoteValue.eighth),
        note(L, NoteValue.quarter),
        note(R, NoteValue.eighth), note(L, NoteValue.eighth),
      ],
      // Zeile 8: durchgehend Achtel (Kadenz), 2x.
      for (var i = 0; i < 2; i++) ...eighths([R, L, R, L, R, L, R, L]),
    ],
  ),
];
