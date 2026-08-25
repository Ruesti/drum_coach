import '../../models/rudiment.dart';
import '../etude_dsl.dart';

// --- Five Stroke Roll group builder -----------------------------------------
// A five-stroke roll (RRLL R> / LLRR L>) is two 16th-note doubles plus an
// accented release, always 2 beats: 4 sixteenths (1 beat) + a release note
// (1 beat, either a sustained quarter or an eighth + eighth-rest). Two
// groups make one whole 4/4 bar.

Hand _opp(Hand h) => h == R ? L : R;

/// One five-stroke-roll group. [lead] is the hand that starts the doubles
/// and closes the release (RRLL R> for [R], LLRR L> for [L]). [accents]
/// picks which of the 5 strokes are accented — positions 0–3 are the double
/// strokes, position 4 is the release (default: just the release, as in the
/// standard rudiment). [releaseValue] swaps the sustained quarter release
/// for a crisper eighth + eighth-rest phrase. [ghostDoubles] softens all
/// four double-stroke notes for dynamic contrast against the accent.
List<StrokeBeat> _roll(
  Hand lead, {
  Set<int> accents = const {4},
  NoteValue releaseValue = NoteValue.quarter,
  bool ghostDoubles = false,
}) {
  final tail = _opp(lead);
  final hands = [lead, lead, tail, tail];
  final doubles = [
    for (var i = 0; i < 4; i++)
      note(hands[i], NoteValue.sixteenth,
          accent: accents.contains(i), ghost: ghostDoubles),
  ];
  if (releaseValue == NoteValue.eighth) {
    return [
      ...doubles,
      note(lead, NoteValue.eighth, accent: accents.contains(4)),
      rest(NoteValue.eighth),
    ];
  }
  return [
    ...doubles,
    note(lead, releaseValue, accent: accents.contains(4)),
  ];
}

/// Five Stroke Roll (RRLL R> / LLRR L>) étude progression: 5 exercises,
/// rising difficulty and tempo, all built on the five-stroke-roll group.
final List<Rudiment> fiveStrokeRollEtudes = <Rudiment>[
  Rudiment(
    id: 'etude_five_stroke_roll_1',
    name: 'Five Stroke Roll · Étude 1',
    description: 'Reine Fünferwirbel im Wechsel – RRLL R> und LLRR L>, sauber und langsam.',
    collection: ExerciseCollection.rudimentEtudes,
    collectionGroup: 'Five Stroke Roll',
    difficulty: Difficulty.beginner,
    minBpm: 50,
    targetBpm: 80,
    gridUnit: NoteGrid.sixteenth,
    beatsPerBar: 4,
    skills: {Skill.control},
    sticking: [
      // Bar 1
      ..._roll(R),
      ..._roll(L),
      // Bar 2
      ..._roll(R),
      ..._roll(L),
    ],
  ),
  Rudiment(
    id: 'etude_five_stroke_roll_2',
    name: 'Five Stroke Roll · Étude 2',
    description: 'Wirbel geghostet, damit der akzentuierte Abschlussschlag klar heraussticht.',
    collection: ExerciseCollection.rudimentEtudes,
    collectionGroup: 'Five Stroke Roll',
    difficulty: Difficulty.beginner,
    minBpm: 60,
    targetBpm: 90,
    gridUnit: NoteGrid.sixteenth,
    beatsPerBar: 4,
    skills: {Skill.control},
    sticking: [
      // Bar 1 — both doubles ghosted, release stays accented
      ..._roll(R, ghostDoubles: true),
      ..._roll(L, ghostDoubles: true),
      // Bar 2
      ..._roll(R, ghostDoubles: true),
      ..._roll(L, ghostDoubles: true),
    ],
  ),
  Rudiment(
    id: 'etude_five_stroke_roll_3',
    name: 'Five Stroke Roll · Étude 3',
    description: 'Der Abschlussakzent wird zur knackigen Achtel mit Achtelpause phrasiert.',
    collection: ExerciseCollection.rudimentEtudes,
    collectionGroup: 'Five Stroke Roll',
    difficulty: Difficulty.intermediate,
    minBpm: 70,
    targetBpm: 110,
    gridUnit: NoteGrid.sixteenth,
    beatsPerBar: 4,
    skills: {Skill.control},
    sticking: [
      // Bar 1 — release is an accented eighth + eighth-rest, not a quarter
      ..._roll(R, releaseValue: NoteValue.eighth),
      ..._roll(L, releaseValue: NoteValue.eighth),
      // Bar 2
      ..._roll(R, releaseValue: NoteValue.eighth),
      ..._roll(L, releaseValue: NoteValue.eighth),
    ],
  ),
  Rudiment(
    id: 'etude_five_stroke_roll_4',
    name: 'Five Stroke Roll · Étude 4',
    description: 'Fünferwirbel-Takte im Wechsel mit einem Dauer-Doppelschlag-Takt für Ausdauer.',
    collection: ExerciseCollection.rudimentEtudes,
    collectionGroup: 'Five Stroke Roll',
    difficulty: Difficulty.advanced,
    minBpm: 85,
    targetBpm: 130,
    gridUnit: NoteGrid.sixteenth,
    beatsPerBar: 4,
    skills: {Skill.control, Skill.endurance},
    sticking: [
      // Bar 1 — standard five-stroke-roll bar
      ..._roll(R),
      ..._roll(L),
      // Bar 2 — continuous 16th-note doubles (no accent), endurance bar
      ...sixteenths([R, R, L, L]),
      ...sixteenths([R, R, L, L]),
      ...sixteenths([R, R, L, L]),
      ...sixteenths([R, R, L, L]),
      // Bar 3 — five-stroke-roll bar again
      ..._roll(R),
      ..._roll(L),
      // Bar 4 — continuous doubles again
      ...sixteenths([R, R, L, L]),
      ...sixteenths([R, R, L, L]),
      ...sixteenths([R, R, L, L]),
      ...sixteenths([R, R, L, L]),
    ],
  ),
  Rudiment(
    id: 'etude_five_stroke_roll_5',
    name: 'Five Stroke Roll · Étude 5',
    description:
        'Herausforderung: der Akzent wandert durch alle fünf Positionen der Gruppe, bevor der Wirbel im höchsten Tempo dichter wird.',
    collection: ExerciseCollection.rudimentEtudes,
    collectionGroup: 'Five Stroke Roll',
    difficulty: Difficulty.professional,
    minBpm: 100,
    targetBpm: 140,
    gridUnit: NoteGrid.sixteenth,
    beatsPerBar: 4,
    skills: {Skill.control, Skill.endurance},
    sticking: [
      // Bar 1 — accent on the first stroke of each double
      ..._roll(R, accents: {0}),
      ..._roll(L, accents: {1}),
      // Bar 2 — accent walks to the second stroke of each double
      ..._roll(R, accents: {2}),
      ..._roll(L, accents: {3}),
      // Bar 3 — accent reaches the release, then the finish gets busier
      ..._roll(R, accents: {4}),
      ..._roll(L, accents: {0, 2, 4}),
      // Bar 4 — busy: both double leads and the release all accented
      ..._roll(R, accents: {0, 2, 4}),
      ..._roll(L, accents: {0, 2, 4}),
    ],
  ),
];
