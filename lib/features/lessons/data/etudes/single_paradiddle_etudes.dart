import '../../models/rudiment.dart';
import '../etude_dsl.dart';

// --- Sticking building blocks -----------------------------------------
//
// A single paradiddle group (RLRR or LRLL) is 4 sixteenth notes = 1 beat.
// A full paradiddle pair (RLRR LRLL) is 2 beats. Helpers below assemble
// whole beats/bars from these groups so every étude's sticking list sums
// to a whole number of 4/4 bars.

/// One sixteenth-note paradiddle group led by [lead] (RLRR if R, LRLL if
/// L) — 4 notes = 1 beat. [accents] selects which of the 4 notes (0-3)
/// carry the accent; defaults to the lead note (index 0).
List<StrokeBeat> _group(Hand lead, {Set<int> accents = const {0}}) {
  final Hand other = lead == R ? L : R;
  return sixteenths([lead, other, lead, lead], accents: accents);
}

/// A full paradiddle pair (RLRR LRLL) = 2 beats, same accent pattern
/// applied to both groups.
List<StrokeBeat> _pair({Set<int> accents = const {0}}) => [
      ..._group(R, accents: accents),
      ..._group(L, accents: accents),
    ];

/// One bar (4 beats = 2 pairs) of straight paradiddles with the given
/// accent pattern applied to every group.
List<StrokeBeat> _accentBar(Set<int> accents) => [
      ..._pair(accents: accents),
      ..._pair(accents: accents),
    ];

/// One paradiddle group led by [lead], lead note accented and the
/// trailing double (positions 2 & 3) played as ghost notes — dynamic
/// contrast between the accent and the diddle.
List<StrokeBeat> _groupGhostDouble(Hand lead) {
  final Hand other = lead == R ? L : R;
  return [
    note(lead, NoteValue.sixteenth, accent: true),
    note(other, NoteValue.sixteenth),
    note(lead, NoteValue.sixteenth, ghost: true),
    note(lead, NoteValue.sixteenth, ghost: true),
  ];
}

/// One eighth-note-triplet beat with a paradiddle-style alternating lead
/// (RLR / LRL), accenting the lead note — shifts a paradiddle bar into a
/// triplet feel while keeping the "accent leads" character.
List<StrokeBeat> _tripletBeat(Hand lead) {
  final Hand other = lead == R ? L : R;
  return triplet8([lead, other, lead], accents: {0});
}

/// One straight sixteenth-note bar (2 paradiddle pairs).
List<StrokeBeat> _straightBar() => [
      ..._pair(),
      ..._pair(),
    ];

/// One eighth-triplet bar (4 triplet beats, alternating lead).
List<StrokeBeat> _tripletBar() => [
      ..._tripletBeat(R),
      ..._tripletBeat(L),
      ..._tripletBeat(R),
      ..._tripletBeat(L),
    ];

/// One "phrased" bar: 3 paradiddle groups (R, L, R lead) followed by a
/// breath beat — an eighth note on the opposite hand plus an eighth rest
/// (still a whole beat: 0.5 + 0.5 quarters).
List<StrokeBeat> _phrasedBar() => [
      ..._group(R),
      ..._group(L),
      ..._group(R),
      note(L, NoteValue.eighth),
      rest(NoteValue.eighth),
    ];

/// Fill-like closing beat: ghost the pickup pair, accent the landing
/// double (LRLL sticking kept intact) — reads as a small crescendo into
/// the final downbeat.
List<StrokeBeat> _fillFlourish() => [
      note(L, NoteValue.sixteenth, ghost: true),
      note(R, NoteValue.sixteenth, ghost: true),
      note(L, NoteValue.sixteenth, accent: true),
      note(L, NoteValue.sixteenth, accent: true),
    ];

final List<Rudiment> singleParadiddleEtudes = <Rudiment>[
  Rudiment(
    id: 'etude_single_paradiddle_1',
    name: 'Single Paradiddle · Étude 1',
    description: 'Reine Paradiddles, Akzent auf der ersten Note jeder Gruppe.',
    collection: ExerciseCollection.rudimentEtudes,
    collectionGroup: 'Single Paradiddle',
    difficulty: Difficulty.beginner,
    minBpm: 60,
    targetBpm: 90,
    gridUnit: NoteGrid.sixteenth,
    beatsPerBar: 4,
    skills: {Skill.control, Skill.coordination},
    sticking: [
      // 2 bars = 4 paradiddle pairs (RLRR LRLL ×4).
      ..._pair(),
      ..._pair(),
      ..._pair(),
      ..._pair(),
    ],
  ),
  Rudiment(
    id: 'etude_single_paradiddle_2',
    name: 'Single Paradiddle · Étude 2',
    description:
        'Akzent auf der Führungsnote, Doppelschlag (RR/LL) als Ghost Notes für dynamischen Kontrast.',
    collection: ExerciseCollection.rudimentEtudes,
    collectionGroup: 'Single Paradiddle',
    difficulty: Difficulty.beginner,
    minBpm: 70,
    targetBpm: 100,
    gridUnit: NoteGrid.sixteenth,
    beatsPerBar: 4,
    skills: {Skill.control, Skill.coordination},
    sticking: [
      // 2 bars = 4 paradiddle pairs, ghosted doubles throughout.
      ..._groupGhostDouble(R),
      ..._groupGhostDouble(L),
      ..._groupGhostDouble(R),
      ..._groupGhostDouble(L),
      ..._groupGhostDouble(R),
      ..._groupGhostDouble(L),
      ..._groupGhostDouble(R),
      ..._groupGhostDouble(L),
    ],
  ),
  Rudiment(
    id: 'etude_single_paradiddle_3',
    name: 'Single Paradiddle · Étude 3',
    description:
        'Phrasierte Paradiddles: drei Gruppen plus Achtel-Atmer für eine musikalische Phrase.',
    collection: ExerciseCollection.rudimentEtudes,
    collectionGroup: 'Single Paradiddle',
    difficulty: Difficulty.intermediate,
    minBpm: 80,
    targetBpm: 120,
    gridUnit: NoteGrid.sixteenth,
    beatsPerBar: 4,
    skills: {Skill.control, Skill.coordination},
    sticking: [
      // 2 bars, each: RLRR LRLL RLRR + (L eighth + eighth rest).
      ..._phrasedBar(),
      ..._phrasedBar(),
    ],
  ),
  Rudiment(
    id: 'etude_single_paradiddle_4',
    name: 'Single Paradiddle · Étude 4',
    description:
        'Paradiddles im Wechsel: 16tel-Bar, Achteltriolen-Bar, 16tel-Bar, Achteltriolen-Bar.',
    collection: ExerciseCollection.rudimentEtudes,
    collectionGroup: 'Single Paradiddle',
    difficulty: Difficulty.advanced,
    minBpm: 95,
    targetBpm: 140,
    gridUnit: NoteGrid.sixteenth,
    beatsPerBar: 4,
    skills: {Skill.control, Skill.coordination},
    sticking: [
      // 4 bars: straight, triplet-feel, straight, triplet-feel.
      ..._straightBar(),
      ..._tripletBar(),
      ..._straightBar(),
      ..._tripletBar(),
    ],
  ),
  Rudiment(
    id: 'etude_single_paradiddle_5',
    name: 'Single Paradiddle · Étude 5',
    description:
        'Wandernder Akzent über alle vier Noten der Gruppe (inklusive Doppelschlag, inward/outward), Fill-artiger Schlussschlag.',
    collection: ExerciseCollection.rudimentEtudes,
    collectionGroup: 'Single Paradiddle',
    difficulty: Difficulty.professional,
    minBpm: 105,
    targetBpm: 160,
    gridUnit: NoteGrid.sixteenth,
    beatsPerBar: 4,
    skills: {Skill.control, Skill.coordination, Skill.fill},
    sticking: [
      // Bar 1: accent on the lead note (index 0) — the standard accent.
      ..._accentBar({0}),
      // Bar 2: accent migrates to index 1.
      ..._accentBar({1}),
      // Bar 3: accent on the double, inward (index 2).
      ..._accentBar({2}),
      // Bar 4: accent on the double, outward (index 3) for 3 beats, then
      // a fill-like flourish on the final beat.
      ..._pair(accents: {3}),
      ..._group(R, accents: {3}),
      ..._fillFlourish(),
    ],
  ),
];
