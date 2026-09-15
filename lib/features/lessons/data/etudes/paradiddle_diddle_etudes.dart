import '../../models/rudiment.dart';
import '../etude_dsl.dart';

// --- Paradiddle-diddle group builders --------------------------------------
// A paradiddle-diddle (RLRRLL / LRLLRR) is 6 notes. In eighth-note-triplet
// framing, each 3-note half is exactly one beat (`triplet8` == 1 beat), so a
// full group is 2 beats — two groups make one whole 4/4 bar. Groups are
// always built from two `triplet8` calls (never one 6-note run) so the
// notation renderer draws two "3" brackets instead of one mislabeled bracket
// spanning all 6 notes.

List<StrokeBeat> _paradiddleDiddleGroup(List<Hand> first, List<Hand> second,
    {int accentAt = 0}) {
  final Set<int> firstAccents = accentAt < 3 ? {accentAt} : {};
  final Set<int> secondAccents = accentAt >= 3 ? {accentAt - 3} : {};
  return [
    ...triplet8(first, accents: firstAccents),
    ...triplet8(second, accents: secondAccents),
  ];
}

/// RLRRLL, accented on the first note by default.
List<StrokeBeat> _rGroup({int accentAt = 0}) =>
    _paradiddleDiddleGroup([R, L, R], [R, L, L], accentAt: accentAt);

/// LRLLRR, accented on the first note by default.
List<StrokeBeat> _lGroup({int accentAt = 0}) =>
    _paradiddleDiddleGroup([L, R, L], [L, R, R], accentAt: accentAt);

/// RLRRLL with the trailing diddle (LL) ghosted for dynamic contrast.
List<StrokeBeat> _rGroupGhostTail() => [
      ...triplet8([R, L, R], accents: {0}),
      note(R, NoteValue.eighth, tuplet: Tuplet.triplet),
      note(L, NoteValue.eighth, tuplet: Tuplet.triplet, ghost: true),
      note(L, NoteValue.eighth, tuplet: Tuplet.triplet, ghost: true),
    ];

/// LRLLRR with the trailing diddle (RR) ghosted for dynamic contrast.
List<StrokeBeat> _lGroupGhostTail() => [
      ...triplet8([L, R, L], accents: {0}),
      note(L, NoteValue.eighth, tuplet: Tuplet.triplet),
      note(R, NoteValue.eighth, tuplet: Tuplet.triplet, ghost: true),
      note(R, NoteValue.eighth, tuplet: Tuplet.triplet, ghost: true),
    ];

/// RLR (triplet, accented) followed by a sustained quarter note in place of
/// the closing "RLL" triplet beat — same 2-beat duration, but opens space.
List<StrokeBeat> _rGroupPhrased() => [
      ...triplet8([R, L, R], accents: {0}),
      note(R, NoteValue.quarter),
    ];

/// Busiest variant: accents on both triplet pulses (positions 0 and 3) and a
/// ghosted tail note.
List<StrokeBeat> _rGroupBusy() => [
      ...triplet8([R, L, R], accents: {0}),
      note(R, NoteValue.eighth, tuplet: Tuplet.triplet, accent: true),
      note(L, NoteValue.eighth, tuplet: Tuplet.triplet),
      note(L, NoteValue.eighth, tuplet: Tuplet.triplet, ghost: true),
    ];

/// Mirror of [_rGroupBusy], closing the étude on a flam.
List<StrokeBeat> _lGroupBusy() => [
      ...triplet8([L, R, L], accents: {0}),
      note(L, NoteValue.eighth, tuplet: Tuplet.triplet, accent: true),
      note(R, NoteValue.eighth, tuplet: Tuplet.triplet),
      note(R, NoteValue.eighth, tuplet: Tuplet.triplet, graces: [L]),
    ];

final List<Rudiment> paradiddleDiddleEtudes = <Rudiment>[
  Rudiment(
    id: 'etude_paradiddle_diddle_1',
    name: 'Paradiddle-diddle · Etude 1',
    description:
        'Pure paradiddle-diddles in a triplet feel, accent on the first stroke of each group.',
    collection: ExerciseCollection.rudimentEtudes,
    collectionGroup: 'Paradiddle-diddle',
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
    id: 'etude_paradiddle_diddle_2',
    name: 'Paradiddle-diddle · Etude 2',
    description:
        'Like Etude 1, but the trailing double (LL/RR) is ghosted – more dynamic range between loud and soft.',
    collection: ExerciseCollection.rudimentEtudes,
    collectionGroup: 'Paradiddle-diddle',
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
    id: 'etude_paradiddle_diddle_3',
    name: 'Paradiddle-diddle · Etude 3',
    description:
        'Phrased: one group closes on a quarter note instead of the triplet diddle – creates space in the run.',
    collection: ExerciseCollection.rudimentEtudes,
    collectionGroup: 'Paradiddle-diddle',
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
    id: 'etude_paradiddle_diddle_4',
    name: 'Paradiddle-diddle · Etude 4',
    description:
        'Four alternating bars: a paradiddle-diddle bar (triplet feel) against a straight eighth-note accent bar.',
    collection: ExerciseCollection.rudimentEtudes,
    collectionGroup: 'Paradiddle-diddle',
    difficulty: Difficulty.advanced,
    minBpm: 85,
    targetBpm: 130,
    gridUnit: NoteGrid.triplet,
    beatsPerBar: 4,
    skills: {Skill.control, Skill.coordination},
    sticking: [
      // Bar 1: paradiddle-diddle bar (triolen-feel).
      ..._rGroup(),
      ..._lGroup(),
      // Bar 2: straight eighth-note accents (contrast).
      ...eighths([R, L, R, L, R, L, R, L], accents: {0, 4}),
      // Bar 3: paradiddle-diddle bar again, opposite lead hand.
      ..._lGroup(),
      ..._rGroup(),
      // Bar 4: straight eighths, denser accent pattern.
      ...eighths([R, L, R, L, R, L, R, L], accents: {0, 2, 4, 6}),
    ],
  ),
  Rudiment(
    id: 'etude_paradiddle_diddle_5',
    name: 'Paradiddle-diddle · Etude 5',
    description:
        'Challenge: a moving accent across all six positions of the group; the last bar gets denser with ghost notes and a flam ending.',
    collection: ExerciseCollection.rudimentEtudes,
    collectionGroup: 'Paradiddle-diddle',
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
