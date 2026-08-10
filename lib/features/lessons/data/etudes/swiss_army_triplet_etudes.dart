import '../../models/rudiment.dart';
import '../etude_dsl.dart';

// --- Swiss Army Triplet group builders --------------------------------------
// A Swiss Army Triplet beat is a flammed, accented lead-hand note, a second
// plain lead-hand tap, then one tap from the opposite hand — R R L sticking
// (or L L R when the left hand leads), all three notes falling on one
// eighth-note-triplet beat (= one quarter). The flam always lands on the
// lead hand. Four beats make one whole 4/4 bar.

/// One Swiss Army Triplet beat: flammed accented [lead] note, a second plain
/// [lead] tap, then one tap from the opposite hand. Set [ghostTaps] to ghost
/// the two non-flammed taps for dynamic contrast against the accented flam.
List<StrokeBeat> _swissBeat(Hand lead, {bool ghostTaps = false}) {
  final other = lead == R ? L : R;
  return [
    note(lead, NoteValue.eighth,
        tuplet: Tuplet.triplet, accent: true, graces: [other]),
    note(lead, NoteValue.eighth, tuplet: Tuplet.triplet, ghost: ghostTaps),
    note(other, NoteValue.eighth, tuplet: Tuplet.triplet, ghost: ghostTaps),
  ];
}

/// Busiest variant: the closing tap (opposite hand) is accented too, the
/// second lead tap ghosted — more dynamic range packed into one beat.
List<StrokeBeat> _swissBeatBusy(Hand lead) {
  final other = lead == R ? L : R;
  return [
    note(lead, NoteValue.eighth,
        tuplet: Tuplet.triplet, accent: true, graces: [other]),
    note(lead, NoteValue.eighth, tuplet: Tuplet.triplet, ghost: true),
    note(other, NoteValue.eighth, tuplet: Tuplet.triplet, accent: true),
  ];
}

/// A whole bar of four Swiss Army Triplet beats, [leads] giving each beat's
/// lead hand in order.
List<StrokeBeat> _bar(List<Hand> leads, {bool ghostTaps = false}) => [
      for (final h in leads) ..._swissBeat(h, ghostTaps: ghostTaps),
    ];

final List<Rudiment> swissArmyTripletEtudes = <Rudiment>[
  Rudiment(
    id: 'etude_swiss_army_triplet_1',
    name: 'Swiss Army Triplet · Étude 1',
    description:
        'Reine Swiss Army Triplets im Triolen-Feel, durchgehend von rechts geführt (Flam-R, R, L).',
    collection: ExerciseCollection.rudimentEtudes,
    collectionGroup: 'Swiss Army Triplet',
    difficulty: Difficulty.beginner,
    minBpm: 60,
    targetBpm: 90,
    gridUnit: NoteGrid.triplet,
    beatsPerBar: 4,
    skills: {Skill.control, Skill.coordination},
    sticking: [
      ..._bar([R, R, R, R]),
      ..._bar([R, R, R, R]),
    ],
  ),
  Rudiment(
    id: 'etude_swiss_army_triplet_2',
    name: 'Swiss Army Triplet · Étude 2',
    description:
        'Wie Étude 1, aber die beiden Tap-Noten werden geghostet – der akzentuierte Flam tritt stärker hervor.',
    collection: ExerciseCollection.rudimentEtudes,
    collectionGroup: 'Swiss Army Triplet',
    difficulty: Difficulty.beginner,
    minBpm: 70,
    targetBpm: 100,
    gridUnit: NoteGrid.triplet,
    beatsPerBar: 4,
    skills: {Skill.control, Skill.coordination},
    sticking: [
      ..._bar([R, R, R, R], ghostTaps: true),
      ..._bar([R, R, R, R], ghostTaps: true),
    ],
  ),
  Rudiment(
    id: 'etude_swiss_army_triplet_3',
    name: 'Swiss Army Triplet · Étude 3',
    description:
        'Phrasiert: ein Schlag wird durch eine akzentuierte Viertelnote ersetzt – schafft Raum im Triolen-Lauf.',
    collection: ExerciseCollection.rudimentEtudes,
    collectionGroup: 'Swiss Army Triplet',
    difficulty: Difficulty.intermediate,
    minBpm: 80,
    targetBpm: 120,
    gridUnit: NoteGrid.triplet,
    beatsPerBar: 4,
    skills: {Skill.control, Skill.coordination},
    sticking: [
      // Bar 1: straight Swiss Army Triplet bar, lead R throughout.
      ..._bar([R, R, R, R]),
      // Bar 2: second beat opens into a sustained accented quarter note
      // instead of its triplet beat — same duration, more space.
      ..._swissBeat(R),
      note(R, NoteValue.quarter, accent: true),
      ..._swissBeat(R),
      ..._swissBeat(R),
    ],
  ),
  Rudiment(
    id: 'etude_swiss_army_triplet_4',
    name: 'Swiss Army Triplet · Étude 4',
    description:
        'Vier Takte: die Führungshand wechselt alle zwei Schläge, im Kontrast zu geraden Achtel-Akzent-Takten.',
    collection: ExerciseCollection.rudimentEtudes,
    collectionGroup: 'Swiss Army Triplet',
    difficulty: Difficulty.advanced,
    minBpm: 90,
    targetBpm: 130,
    gridUnit: NoteGrid.triplet,
    beatsPerBar: 4,
    skills: {Skill.control, Skill.coordination},
    sticking: [
      // Bar 1: Swiss Army Triplets, lead hand alternates every two beats.
      ..._bar([R, R, L, L]),
      // Bar 2: straight eighth-note accents (2-feel contrast).
      ...eighths([R, L, R, L, R, L, R, L], accents: {0, 4}),
      // Bar 3: Swiss Army Triplets again, opposite starting lead.
      ..._bar([L, L, R, R]),
      // Bar 4: straight eighths, denser accent pattern.
      ...eighths([R, L, R, L, R, L, R, L], accents: {0, 2, 4, 6}),
    ],
  ),
  Rudiment(
    id: 'etude_swiss_army_triplet_5',
    name: 'Swiss Army Triplet · Étude 5',
    description:
        'Herausforderung: durchgehende Swiss Army Triplets bis zum Zieltempo, die Führung wechselt pro Takt, letzter Takt dichter mit akzentuierten Taps.',
    collection: ExerciseCollection.rudimentEtudes,
    collectionGroup: 'Swiss Army Triplet',
    difficulty: Difficulty.professional,
    minBpm: 100,
    targetBpm: 140,
    gridUnit: NoteGrid.triplet,
    beatsPerBar: 4,
    skills: {Skill.control, Skill.coordination},
    sticking: [
      // Bars 1–3: continuous Swiss Army Triplets, lead alternates per bar.
      ..._bar([R, R, R, R]),
      ..._bar([L, L, L, L]),
      ..._bar([R, R, R, R]),
      // Bar 4: busier — accented closing tap on every beat, lead alternates
      // per beat for extra density.
      ..._swissBeatBusy(R),
      ..._swissBeatBusy(L),
      ..._swissBeatBusy(R),
      ..._swissBeatBusy(L),
    ],
  ),
];
