import '../../models/rudiment.dart';
import '../etude_dsl.dart';

// --- Double-paradiddle group builders --------------------------------------
// A double paradiddle (RLRLRR / LRLRLL) is 6 notes. In eighth-note-triplet
// framing, each 3-note half is exactly one beat (`triplet8` == 1 beat), so a
// full group is 2 beats — two groups make one whole 4/4 bar. Groups are
// always built from two `triplet8` calls (never one 6-note run) so the
// notation renderer draws two "3" brackets instead of one mislabeled bracket
// spanning all 6 notes.

List<StrokeBeat> _paradiddleGroup(List<Hand> first, List<Hand> second,
    {int accentAt = 0}) {
  final Set<int> firstAccents = accentAt < 3 ? {accentAt} : {};
  final Set<int> secondAccents = accentAt >= 3 ? {accentAt - 3} : {};
  return [
    ...triplet8(first, accents: firstAccents),
    ...triplet8(second, accents: secondAccents),
  ];
}

/// RLRLRR, accented on the first note by default.
List<StrokeBeat> _rGroup({int accentAt = 0}) =>
    _paradiddleGroup([R, L, R], [L, R, R], accentAt: accentAt);

/// LRLRLL, accented on the first note by default.
List<StrokeBeat> _lGroup({int accentAt = 0}) =>
    _paradiddleGroup([L, R, L], [R, L, L], accentAt: accentAt);

/// RLRLRR with the trailing double (RR) ghosted for dynamic contrast.
List<StrokeBeat> _rGroupGhostTail() => [
      ...triplet8([R, L, R], accents: {0}),
      note(L, NoteValue.eighth, tuplet: Tuplet.triplet),
      note(R, NoteValue.eighth, tuplet: Tuplet.triplet, ghost: true),
      note(R, NoteValue.eighth, tuplet: Tuplet.triplet, ghost: true),
    ];

/// LRLRLL with the trailing double (LL) ghosted for dynamic contrast.
List<StrokeBeat> _lGroupGhostTail() => [
      ...triplet8([L, R, L], accents: {0}),
      note(R, NoteValue.eighth, tuplet: Tuplet.triplet),
      note(L, NoteValue.eighth, tuplet: Tuplet.triplet, ghost: true),
      note(L, NoteValue.eighth, tuplet: Tuplet.triplet, ghost: true),
    ];

/// RLR (triplet, accented) followed by a sustained quarter note in place of
/// the closing "LRR" triplet beat — same 2-beat duration, but opens space.
List<StrokeBeat> _rGroupPhrased() => [
      ...triplet8([R, L, R], accents: {0}),
      note(R, NoteValue.quarter),
    ];

/// Busiest variant: accents on both triplet pulses (positions 0 and 3) and a
/// ghosted tail note.
List<StrokeBeat> _rGroupBusy() => [
      ...triplet8([R, L, R], accents: {0}),
      note(L, NoteValue.eighth, tuplet: Tuplet.triplet, accent: true),
      note(R, NoteValue.eighth, tuplet: Tuplet.triplet),
      note(R, NoteValue.eighth, tuplet: Tuplet.triplet, ghost: true),
    ];

/// Mirror of [_rGroupBusy], closing the étude on a flam.
List<StrokeBeat> _lGroupBusy() => [
      ...triplet8([L, R, L], accents: {0}),
      note(R, NoteValue.eighth, tuplet: Tuplet.triplet, accent: true),
      note(L, NoteValue.eighth, tuplet: Tuplet.triplet),
      note(L, NoteValue.eighth, tuplet: Tuplet.triplet, graces: [R]),
    ];

final List<Rudiment> doubleParadiddleEtudes = <Rudiment>[
  Rudiment(
    id: 'etude_double_paradiddle_1',
    name: 'Double Paradiddle · Étude 1',
    description:
        'Reine Double Paradiddles im Triolen-Feel, Akzent auf dem ersten Schlag jeder Gruppe.',
    collection: ExerciseCollection.rudimentEtudes,
    collectionGroup: 'Double Paradiddle',
    difficulty: Difficulty.beginner,
    minBpm: 50,
    targetBpm: 80,
    gridUnit: NoteGrid.triplet,
    beatsPerBar: 4,
    skills: {Skill.control, Skill.coordination},
    sticking: [
      ..._rGroup(),
      ..._lGroup(),
      ..._rGroup(),
      ..._lGroup(),
    ],
  ),
  Rudiment(
    id: 'etude_double_paradiddle_2',
    name: 'Double Paradiddle · Étude 2',
    description:
        'Wie Étude 1, aber der Nachschlag (RR/LL) wird geghostet – mehr Dynamik zwischen laut und leise.',
    collection: ExerciseCollection.rudimentEtudes,
    collectionGroup: 'Double Paradiddle',
    difficulty: Difficulty.beginner,
    minBpm: 60,
    targetBpm: 90,
    gridUnit: NoteGrid.triplet,
    beatsPerBar: 4,
    skills: {Skill.control, Skill.coordination},
    sticking: [
      ..._rGroupGhostTail(),
      ..._lGroupGhostTail(),
      ..._rGroupGhostTail(),
      ..._lGroupGhostTail(),
    ],
  ),
  Rudiment(
    id: 'etude_double_paradiddle_3',
    name: 'Double Paradiddle · Étude 3',
    description:
        'Phrasiert: eine Gruppe schließt auf einer Viertelnote statt der Triolen-Sechsergruppe – schafft Raum im Lauf.',
    collection: ExerciseCollection.rudimentEtudes,
    collectionGroup: 'Double Paradiddle',
    difficulty: Difficulty.intermediate,
    minBpm: 70,
    targetBpm: 110,
    gridUnit: NoteGrid.triplet,
    beatsPerBar: 4,
    skills: {Skill.control, Skill.coordination},
    sticking: [
      ..._rGroup(),
      ..._lGroup(),
      ..._rGroupPhrased(),
      ..._lGroup(),
    ],
  ),
  Rudiment(
    id: 'etude_double_paradiddle_4',
    name: 'Double Paradiddle · Étude 4',
    description:
        'Vier Takte im Wechsel: Double-Paradiddle-Takt (6er-Feel) gegen einen geraden Achtel-Akzent-Takt (2er-Feel).',
    collection: ExerciseCollection.rudimentEtudes,
    collectionGroup: 'Double Paradiddle',
    difficulty: Difficulty.advanced,
    minBpm: 85,
    targetBpm: 130,
    gridUnit: NoteGrid.triplet,
    beatsPerBar: 4,
    skills: {Skill.control, Skill.coordination},
    sticking: [
      // Bar 1: double-paradiddle bar (triplet / 6-feel).
      ..._rGroup(),
      ..._lGroup(),
      // Bar 2: straight eighth-note accents (2-feel contrast).
      ...eighths([R, L, R, L, R, L, R, L], accents: {0, 4}),
      // Bar 3: double-paradiddle bar again, opposite lead hand.
      ..._lGroup(),
      ..._rGroup(),
      // Bar 4: straight eighths, denser accent pattern.
      ...eighths([R, L, R, L, R, L, R, L], accents: {0, 2, 4, 6}),
    ],
  ),
  Rudiment(
    id: 'etude_double_paradiddle_5',
    name: 'Double Paradiddle · Étude 5',
    description:
        'Herausforderung: wandernder Akzent über alle sechs Positionen der Gruppe, letzter Takt dichter mit Ghost-Notes und Flam-Schluss.',
    collection: ExerciseCollection.rudimentEtudes,
    collectionGroup: 'Double Paradiddle',
    difficulty: Difficulty.professional,
    minBpm: 100,
    targetBpm: 150,
    gridUnit: NoteGrid.triplet,
    beatsPerBar: 4,
    skills: {Skill.control, Skill.coordination},
    sticking: [
      // Bars 1–3: the accent migrates through all six positions of the group.
      ..._rGroup(accentAt: 0),
      ..._lGroup(accentAt: 1),
      ..._rGroup(accentAt: 2),
      ..._lGroup(accentAt: 3),
      ..._rGroup(accentAt: 4),
      ..._lGroup(accentAt: 5),
      // Bar 4: busier — double accents per group, ghosted tails, flam finish.
      ..._rGroupBusy(),
      ..._lGroupBusy(),
    ],
  ),
];
