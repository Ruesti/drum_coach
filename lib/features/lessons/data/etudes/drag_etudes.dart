import '../../models/rudiment.dart';
import '../etude_dsl.dart';

// --- Drag building blocks -----------------------------------------------
//
// A drag = two grace notes on the opposite hand immediately before a
// primary stroke (`drag()` in etude_dsl.dart). Only straight (non-tuplet)
// note values are used throughout this file. Grace notes share the primary
// note's tick, so `drag(h, v)` occupies exactly one `v`-duration slot — the
// same as a plain `note(h, v)` — which keeps all whole-bar math simple.

Hand _opp(Hand h) => h == R ? L : R;

/// One "single drag tap" unit: a drag on [lead], followed by an accented
/// tap on the opposite hand, both of duration [v]. Used straight (eighth)
/// for Étude 2 and densified (sixteenth, 2 per beat) for Étude 5's closing
/// bar.
List<StrokeBeat> _dragTapUnit(Hand lead, NoteValue v) => [
      drag(lead, v),
      note(_opp(lead), v, accent: true),
    ];

/// A bar built from consecutive drag-tap units, one lead hand per entry in
/// [leads]. Passing an even-length, R/L-alternating list keeps the drag
/// lead hand alternating continuously across bar boundaries too.
List<StrokeBeat> _dragTapBar(List<Hand> leads, NoteValue v) => [
      for (final h in leads) ..._dragTapUnit(h, v),
    ];

/// A bar that opens with a sixteenth-note drag on [lead], then fills the
/// remaining 15 sixteenth slots with plain alternating single strokes
/// ("taps") continuing the sticking hand-to-hand — 16 sixteenths = 4 beats.
List<StrokeBeat> _dragSixteenthBar(Hand lead) {
  final Hand other = _opp(lead);
  return [
    drag(lead, NoteValue.sixteenth),
    ...sixteenths(List.generate(15, (i) => i.isEven ? other : lead)),
  ];
}

/// Drag (2 grace notes on the opposite hand + a primary stroke) étude
/// progression: 5 exercises, rising difficulty and tempo, from plain
/// quarter-note drags to accent-heavy drag taps at speed.
final List<Rudiment> dragEtudes = <Rudiment>[
  Rudiment(
    id: 'etude_drag_1',
    name: 'Drag · Étude 1',
    description:
        'Reine Viertel-Drags im ständigen Wechsel zwischen rechter und linker Führungshand.',
    collection: ExerciseCollection.rudimentEtudes,
    collectionGroup: 'Drag',
    difficulty: Difficulty.beginner,
    minBpm: 50,
    targetBpm: 80,
    gridUnit: NoteGrid.eighth,
    beatsPerBar: 4,
    skills: {Skill.control},
    sticking: [
      // 2 bars = 8 quarter-note drags, lead hand alternates every drag.
      drag(R, NoteValue.quarter),
      drag(L, NoteValue.quarter),
      drag(R, NoteValue.quarter),
      drag(L, NoteValue.quarter),
      drag(R, NoteValue.quarter),
      drag(L, NoteValue.quarter),
      drag(R, NoteValue.quarter),
      drag(L, NoteValue.quarter),
    ],
  ),
  Rudiment(
    id: 'etude_drag_2',
    name: 'Drag · Étude 2',
    description:
        'Single Drag Tap: Drag plus Antipper pro Zählzeit, die Tap-Note trägt den Akzent.',
    collection: ExerciseCollection.rudimentEtudes,
    collectionGroup: 'Drag',
    difficulty: Difficulty.beginner,
    minBpm: 60,
    targetBpm: 90,
    gridUnit: NoteGrid.eighth,
    beatsPerBar: 4,
    skills: {Skill.control},
    sticking: [
      // 2 bars = 8 beats, each an eighth-drag + accented eighth-tap.
      ..._dragTapBar([R, L, R, L], NoteValue.eighth),
      ..._dragTapBar([R, L, R, L], NoteValue.eighth),
    ],
  ),
  Rudiment(
    id: 'etude_drag_3',
    name: 'Drag · Étude 3',
    description:
        'Drags eingebettet in einen Achtel-Fluss, mit Pausen für mehr Raum zwischen den Phrasen.',
    collection: ExerciseCollection.rudimentEtudes,
    collectionGroup: 'Drag',
    difficulty: Difficulty.intermediate,
    minBpm: 70,
    targetBpm: 110,
    gridUnit: NoteGrid.eighth,
    beatsPerBar: 4,
    skills: {Skill.control},
    sticking: [
      // Bar 1
      drag(R, NoteValue.eighth), note(L, NoteValue.eighth), // beat 1
      rest(NoteValue.eighth), note(R, NoteValue.eighth), // beat 2 — space
      drag(L, NoteValue.eighth), note(R, NoteValue.eighth), // beat 3
      note(L, NoteValue.eighth), rest(NoteValue.eighth), // beat 4 — space
      // Bar 2
      rest(NoteValue.eighth), drag(R, NoteValue.eighth), // beat 1 — space
      note(L, NoteValue.eighth), note(R, NoteValue.eighth), // beat 2
      drag(L, NoteValue.eighth), rest(NoteValue.eighth), // beat 3
      note(R, NoteValue.eighth), note(L, NoteValue.eighth), // beat 4
    ],
  ),
  Rudiment(
    id: 'etude_drag_4',
    name: 'Drag · Étude 4',
    description:
        'Drag auf Zählzeit 1 führt in durchlaufende 16tel-Antipper – vier Takte, wechselnde Führungshand.',
    collection: ExerciseCollection.rudimentEtudes,
    collectionGroup: 'Drag',
    difficulty: Difficulty.advanced,
    minBpm: 80,
    targetBpm: 130,
    gridUnit: NoteGrid.eighth,
    beatsPerBar: 4,
    skills: {Skill.control, Skill.coordination},
    sticking: [
      ..._dragSixteenthBar(R),
      ..._dragSixteenthBar(L),
      ..._dragSixteenthBar(R),
      ..._dragSixteenthBar(L),
    ],
  ),
  Rudiment(
    id: 'etude_drag_5',
    name: 'Drag · Étude 5',
    description:
        'Herausforderung: akzentuierte Drag-Taps im Wechsel, letzter Takt zu 16teln verdichtet.',
    collection: ExerciseCollection.rudimentEtudes,
    collectionGroup: 'Drag',
    difficulty: Difficulty.professional,
    minBpm: 90,
    targetBpm: 140,
    gridUnit: NoteGrid.eighth,
    beatsPerBar: 4,
    skills: {Skill.control, Skill.coordination},
    sticking: [
      // Bars 1–3: eighth-note drag-taps, lead hand alternates every beat.
      ..._dragTapBar([R, L, R, L], NoteValue.eighth),
      ..._dragTapBar([R, L, R, L], NoteValue.eighth),
      ..._dragTapBar([R, L, R, L], NoteValue.eighth),
      // Bar 4 — busier: sixteenth-note drag-taps, 2 per beat.
      ..._dragTapBar([R, L, R, L, R, L, R, L], NoteValue.sixteenth),
    ],
  ),
];
