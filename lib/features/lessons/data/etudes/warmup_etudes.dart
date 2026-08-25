import '../../models/rudiment.dart';
import '../etude_dsl.dart';

/// Warm-up étude progression: settles the hands in before the session's real
/// technical work starts. Mirrors a classic "warm the hands up" order — pure
/// single-hand repetition first, then alternating strokes, then grouped hand
/// sets — while the note value climbs from quarters to eighths to
/// sixteenths across the seven pieces.

// --- building blocks --------------------------------------------------------

/// One bar of straight quarter notes, all struck by [hand] (4 notes = 1 bar).
List<StrokeBeat> _singleHandQuarterBar(Hand hand) =>
    run([hand, hand, hand, hand], NoteValue.quarter);

/// One bar of alternating quarter notes, starting on [lead] (4 notes = 1 bar).
List<StrokeBeat> _alternatingQuarterBar(Hand lead) {
  final other = lead == R ? L : R;
  return run([lead, other, lead, other], NoteValue.quarter);
}

/// One bar of alternating eighth notes, starting on [lead] (8 notes = 1 bar).
List<StrokeBeat> _alternatingEighthBar(Hand lead) {
  final other = lead == R ? L : R;
  return eighths([lead, other, lead, other, lead, other, lead, other]);
}

/// One bar of alternating sixteenth notes, starting on [lead]
/// (16 notes = 1 bar).
List<StrokeBeat> _alternatingSixteenthBar(Hand lead) {
  final other = lead == R ? L : R;
  return sixteenths([
    lead, other, lead, other, lead, other, lead, other, //
    lead, other, lead, other, lead, other, lead, other,
  ]);
}

/// One bar of grouped hand sets: two 4-note eighth-note blocks, [lead] first
/// then the opposite hand (8 notes = 1 bar) — e.g. RRRR LLLL.
List<StrokeBeat> _groupedEighthBar(Hand lead) {
  final other = lead == R ? L : R;
  return eighths([lead, lead, lead, lead, other, other, other, other]);
}

/// Warm-up études: the pad-workout collection's "Warm-Up" group. Each entry
/// is a short, low-effort progression meant to be played first, before any
/// other exercise, so the hands are loose and the alternation is settled.
final List<Rudiment> warmupEtudes = <Rudiment>[
  Rudiment(
    id: 'etude_pad_warmup_1',
    name: 'Warm-Up 1 · Nur Rechts',
    description:
        'Reine Viertelnoten, ausschließlich mit der rechten Hand — löst das '
        'Handgelenk, bevor beidhändig gespielt wird.',
    collection: ExerciseCollection.padWorkouts,
    collectionGroup: 'Warm-Up',
    difficulty: Difficulty.beginner,
    minBpm: 40,
    targetBpm: 70,
    gridUnit: NoteGrid.quarter,
    beatsPerBar: 4,
    skills: {Skill.endurance, Skill.control},
    sticking: [
      // 2 bars = 8 quarters, R R R R | R R R R.
      ..._singleHandQuarterBar(R),
      ..._singleHandQuarterBar(R),
    ],
  ),
  Rudiment(
    id: 'etude_pad_warmup_2',
    name: 'Warm-Up 2 · Nur Links',
    description:
        'Reine Viertelnoten, ausschließlich mit der linken Hand — gleicht die '
        'schwächere Seite an die rechte Hand an.',
    collection: ExerciseCollection.padWorkouts,
    collectionGroup: 'Warm-Up',
    difficulty: Difficulty.beginner,
    minBpm: 40,
    targetBpm: 70,
    gridUnit: NoteGrid.quarter,
    beatsPerBar: 4,
    skills: {Skill.endurance, Skill.control},
    sticking: [
      // 2 bars = 8 quarters, L L L L | L L L L.
      ..._singleHandQuarterBar(L),
      ..._singleHandQuarterBar(L),
    ],
  ),
  Rudiment(
    id: 'etude_pad_warmup_3',
    name: 'Warm-Up 3 · Wechselschlag Viertel',
    description:
        'Beide Hände wechseln sich in Viertelnoten ab — der erste Schritt von '
        'Einzelhand- zu Wechselschlag-Bewegung.',
    collection: ExerciseCollection.padWorkouts,
    collectionGroup: 'Warm-Up',
    difficulty: Difficulty.beginner,
    minBpm: 45,
    targetBpm: 75,
    gridUnit: NoteGrid.quarter,
    beatsPerBar: 4,
    skills: {Skill.endurance, Skill.control},
    sticking: [
      // 2 bars = 8 quarters, R L R L | R L R L.
      ..._alternatingQuarterBar(R),
      ..._alternatingQuarterBar(R),
    ],
  ),
  Rudiment(
    id: 'etude_pad_warmup_4',
    name: 'Warm-Up 4 · Wechselschlag Achtel',
    description:
        'Der Wechselschlag aus Warm-Up 3, jetzt doppelt so dicht in '
        'Achtelnoten gespielt.',
    collection: ExerciseCollection.padWorkouts,
    collectionGroup: 'Warm-Up',
    difficulty: Difficulty.beginner,
    minBpm: 50,
    targetBpm: 85,
    gridUnit: NoteGrid.eighth,
    beatsPerBar: 4,
    skills: {Skill.endurance, Skill.control},
    sticking: [
      // 2 bars = 16 eighths.
      ..._alternatingEighthBar(R),
      ..._alternatingEighthBar(R),
    ],
  ),
  Rudiment(
    id: 'etude_pad_warmup_5',
    name: 'Warm-Up 5 · Gruppierte Handsätze',
    description:
        'Blöcke aus vier gleichen Achtelschlägen im Wechsel zwischen rechts '
        'und links — bereitet auf gruppierte Stickings vor.',
    collection: ExerciseCollection.padWorkouts,
    collectionGroup: 'Warm-Up',
    difficulty: Difficulty.intermediate,
    minBpm: 55,
    targetBpm: 90,
    gridUnit: NoteGrid.eighth,
    beatsPerBar: 4,
    skills: {Skill.endurance, Skill.control, Skill.coordination},
    sticking: [
      // 2 bars = 16 eighths, RRRR LLLL | RRRR LLLL.
      ..._groupedEighthBar(R),
      ..._groupedEighthBar(R),
    ],
  ),
  Rudiment(
    id: 'etude_pad_warmup_6',
    name: 'Warm-Up 6 · Wechselschlag Sechzehntel',
    description:
        'Der Wechselschlag verdichtet sich weiter zu durchgehenden '
        'Sechzehnteln — der letzte Schritt vor dem eigentlichen Training.',
    collection: ExerciseCollection.padWorkouts,
    collectionGroup: 'Warm-Up',
    difficulty: Difficulty.intermediate,
    minBpm: 60,
    targetBpm: 100,
    gridUnit: NoteGrid.sixteenth,
    beatsPerBar: 4,
    skills: {Skill.endurance, Skill.control},
    sticking: [
      // 2 bars = 32 sixteenths.
      ..._alternatingSixteenthBar(R),
      ..._alternatingSixteenthBar(R),
    ],
  ),
  Rudiment(
    id: 'etude_pad_warmup_7',
    name: 'Warm-Up 7 · Von Achtel zu Sechzehntel',
    description:
        'Takt 1 alternierend in Achteln, Takt 2 alternierend in Sechzehnteln '
        '— simuliert innerhalb einer Übung das Gefühl von langsam zu schnell.',
    collection: ExerciseCollection.padWorkouts,
    collectionGroup: 'Warm-Up',
    difficulty: Difficulty.intermediate,
    minBpm: 60,
    targetBpm: 100,
    gridUnit: NoteGrid.sixteenth,
    beatsPerBar: 4,
    skills: {Skill.endurance, Skill.control, Skill.coordination},
    sticking: [
      // Bar 1 = 8 eighths, bar 2 = 16 sixteenths — both 4 quarters = 1 bar.
      ..._alternatingEighthBar(R),
      ..._alternatingSixteenthBar(R),
    ],
  ),
];
