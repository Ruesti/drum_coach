import '../../models/rudiment.dart';
import '../etude_dsl.dart';

// --- Sticking building blocks -----------------------------------------
//
// Both helpers below build one whole 4/4 bar as 16 sixteenth-note cells
// (rest or struck, always 0.25q each), so every bar they emit trivially
// sums to 4 quarters regardless of which cells are rests.

/// One bar: flam on beat 1, sixteenth taps filling the rest of the bar,
/// with two rests (end of beat 2, end of beat 4) for breathing space.
List<StrokeBeat> _flamPhraseBar(Hand lead) {
  final Hand o = lead == R ? L : R;
  return [
    flam(lead, NoteValue.sixteenth), note(o, NoteValue.sixteenth),
    note(lead, NoteValue.sixteenth), note(o, NoteValue.sixteenth),
    note(lead, NoteValue.sixteenth), note(o, NoteValue.sixteenth),
    note(lead, NoteValue.sixteenth), rest(NoteValue.sixteenth),
    note(o, NoteValue.sixteenth), note(lead, NoteValue.sixteenth),
    note(o, NoteValue.sixteenth), note(lead, NoteValue.sixteenth),
    note(o, NoteValue.sixteenth), note(lead, NoteValue.sixteenth),
    note(o, NoteValue.sixteenth), rest(NoteValue.sixteenth),
  ];
}

/// One bar: busier variant — accented flams on beat 1 (lead) and beat 3
/// (opposite hand), no rests, continuous sixteenth taps between them.
List<StrokeBeat> _busyFlamBar(Hand lead) {
  final Hand o = lead == R ? L : R;
  return [
    flam(lead, NoteValue.sixteenth, accent: true), note(o, NoteValue.sixteenth),
    note(lead, NoteValue.sixteenth), note(o, NoteValue.sixteenth),
    note(lead, NoteValue.sixteenth), note(o, NoteValue.sixteenth),
    note(lead, NoteValue.sixteenth), note(o, NoteValue.sixteenth),
    flam(o, NoteValue.sixteenth, accent: true), note(lead, NoteValue.sixteenth),
    note(o, NoteValue.sixteenth), note(lead, NoteValue.sixteenth),
    note(o, NoteValue.sixteenth), note(lead, NoteValue.sixteenth),
    note(o, NoteValue.sixteenth), note(lead, NoteValue.sixteenth),
  ];
}

/// Five Flam études, rising complexity and tempo: 1) plain quarter-note
/// flams, 2) flam + opposite-hand tap per beat, 3) flam-tap feel (flam +
/// same-hand tap), 4) flams inside a 16th-note phrase with rests, 5) busy
/// accented-flam challenge at the highest tempo. Flam lead hand alternates
/// throughout.
final List<Rudiment> flamEtudes = <Rudiment>[
  Rudiment(
    id: 'etude_flam_1',
    name: 'Flam · Etude 1',
    description: 'Quarter-note flams with the lead hand alternating evenly.',
    collection: ExerciseCollection.rudimentEtudes,
    collectionGroup: 'Flam',
    difficulty: Difficulty.beginner,
    minBpm: 50,
    targetBpm: 80,
    gridUnit: NoteGrid.eighth,
    beatsPerBar: 4,
    skills: {Skill.control},
    sticking: [
      // 2 bars: one flam per quarter-note beat, lead hand alternates R/L.
      for (var i = 0; i < 8; i++) flam(i.isEven ? R : L, NoteValue.quarter),
    ],
  ),
  Rudiment(
    id: 'etude_flam_2',
    name: 'Flam · Etude 2',
    description:
        'A flam on every beat, followed by an eighth-note tap – alternating lead hand.',
    collection: ExerciseCollection.rudimentEtudes,
    collectionGroup: 'Flam',
    difficulty: Difficulty.beginner,
    minBpm: 60,
    targetBpm: 90,
    gridUnit: NoteGrid.eighth,
    beatsPerBar: 4,
    skills: {Skill.control},
    sticking: [
      // 2 bars: per beat, flam (eighth) + tap on the opposite hand (eighth).
      for (var beat = 0; beat < 8; beat++) ...[
        flam(beat.isEven ? R : L, NoteValue.eighth),
        note(beat.isEven ? L : R, NoteValue.eighth),
      ],
    ],
  ),
  Rudiment(
    id: 'etude_flam_3',
    name: 'Flam · Etude 3',
    description:
        'Flam tap feel: flam and tap on the same hand, alternating between right and left.',
    collection: ExerciseCollection.rudimentEtudes,
    collectionGroup: 'Flam',
    difficulty: Difficulty.intermediate,
    minBpm: 70,
    targetBpm: 110,
    gridUnit: NoteGrid.eighth,
    beatsPerBar: 4,
    skills: {Skill.control},
    sticking: [
      // 2 bars: per beat, flam (eighth) + tap on the SAME hand (eighth) —
      // classic flam-tap sticking, lead hand alternates every beat.
      for (var beat = 0; beat < 8; beat++) ...[
        flam(beat.isEven ? R : L, NoteValue.eighth),
        note(beat.isEven ? R : L, NoteValue.eighth),
      ],
    ],
  ),
  Rudiment(
    id: 'etude_flam_4',
    name: 'Flam · Etude 4',
    description: 'Flams embedded in a 16th-note phrase with rests for extra space.',
    collection: ExerciseCollection.rudimentEtudes,
    collectionGroup: 'Flam',
    difficulty: Difficulty.advanced,
    minBpm: 80,
    targetBpm: 130,
    gridUnit: NoteGrid.eighth,
    beatsPerBar: 4,
    skills: {Skill.control, Skill.coordination},
    sticking: [
      // 4 bars, lead hand alternates bar by bar: R, L, R, L.
      ..._flamPhraseBar(R),
      ..._flamPhraseBar(L),
      ..._flamPhraseBar(R),
      ..._flamPhraseBar(L),
    ],
  ),
  Rudiment(
    id: 'etude_flam_5',
    name: 'Flam · Etude 5',
    description: 'Demanding flam accents in dense 16th-note rhythms at top speed.',
    collection: ExerciseCollection.rudimentEtudes,
    collectionGroup: 'Flam',
    difficulty: Difficulty.professional,
    minBpm: 90,
    targetBpm: 150,
    gridUnit: NoteGrid.eighth,
    beatsPerBar: 4,
    skills: {Skill.control, Skill.coordination},
    sticking: [
      // 4 bars, lead hand alternates bar by bar: R, L, R, L. Each bar carries
      // two accented flams (beat 1 lead, beat 3 opposite) over continuous
      // sixteenth taps — no rests, busiest and fastest of the set.
      ..._busyFlamBar(R),
      ..._busyFlamBar(L),
      ..._busyFlamBar(R),
      ..._busyFlamBar(L),
    ],
  ),
];
