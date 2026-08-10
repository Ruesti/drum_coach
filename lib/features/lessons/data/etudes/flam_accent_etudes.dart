import '../../models/rudiment.dart';
import '../etude_dsl.dart';

// --- Flam Accent group builders ---------------------------------------------
// A flam accent beat is a flammed, accented note followed by two plain taps,
// all three notes falling on one eighth-note-triplet beat (= one quarter).
// The lead hand alternates every beat: a right-lead beat plays flam(R)-L-R,
// the following left-lead beat mirrors it as flam(L)-R-L. Four beats make one
// whole 4/4 bar.

/// One flam-accent beat: flammed accented [lead] note, then two taps
/// ([lead]'s partner, then [lead] again). Set [ghostTaps] to ghost the two
/// taps for dynamic contrast against the accented flam.
List<StrokeBeat> _flamAccentBeat(Hand lead, {bool ghostTaps = false}) {
  final other = lead == R ? L : R;
  return [
    note(lead, NoteValue.eighth,
        tuplet: Tuplet.triplet, accent: true, graces: [other]),
    note(other, NoteValue.eighth, tuplet: Tuplet.triplet, ghost: ghostTaps),
    note(lead, NoteValue.eighth, tuplet: Tuplet.triplet, ghost: ghostTaps),
  ];
}

/// Busiest variant: both the flam and the closing tap are accented, the
/// middle tap ghosted — more dynamic range packed into one beat.
List<StrokeBeat> _flamAccentBeatBusy(Hand lead) {
  final other = lead == R ? L : R;
  return [
    note(lead, NoteValue.eighth,
        tuplet: Tuplet.triplet, accent: true, graces: [other]),
    note(other, NoteValue.eighth, tuplet: Tuplet.triplet, ghost: true),
    note(lead, NoteValue.eighth, tuplet: Tuplet.triplet, accent: true),
  ];
}

/// A whole bar of four flam-accent beats, [leads] giving each beat's lead
/// hand in order.
List<StrokeBeat> _bar(List<Hand> leads, {bool ghostTaps = false}) => [
      for (final h in leads) ..._flamAccentBeat(h, ghostTaps: ghostTaps),
    ];

final List<Rudiment> flamAccentEtudes = <Rudiment>[
  Rudiment(
    id: 'etude_flam_accent_1',
    name: 'Flam Accent · Étude 1',
    description:
        'Reine Flam Accents im Triolen-Feel, die Führung wechselt bei jedem Schlag zwischen rechts und links.',
    collection: ExerciseCollection.rudimentEtudes,
    collectionGroup: 'Flam Accent',
    difficulty: Difficulty.beginner,
    minBpm: 60,
    targetBpm: 90,
    gridUnit: NoteGrid.triplet,
    beatsPerBar: 4,
    skills: {Skill.control, Skill.coordination},
    sticking: [
      ..._bar([R, L, R, L]),
      ..._bar([R, L, R, L]),
    ],
  ),
  Rudiment(
    id: 'etude_flam_accent_2',
    name: 'Flam Accent · Étude 2',
    description:
        'Wie Étude 1, aber die beiden Tap-Noten werden geghostet – mehr dynamischer Kontrast zum betonten Flam.',
    collection: ExerciseCollection.rudimentEtudes,
    collectionGroup: 'Flam Accent',
    difficulty: Difficulty.beginner,
    minBpm: 70,
    targetBpm: 100,
    gridUnit: NoteGrid.triplet,
    beatsPerBar: 4,
    skills: {Skill.control, Skill.coordination},
    sticking: [
      ..._bar([R, L, R, L], ghostTaps: true),
      ..._bar([R, L, R, L], ghostTaps: true),
    ],
  ),
  Rudiment(
    id: 'etude_flam_accent_3',
    name: 'Flam Accent · Étude 3',
    description:
        'Phrasiert: ein Schlag wird durch eine ausgehaltene Viertelnote statt der Triolen-Dreiergruppe ersetzt – schafft Raum im Lauf.',
    collection: ExerciseCollection.rudimentEtudes,
    collectionGroup: 'Flam Accent',
    difficulty: Difficulty.intermediate,
    minBpm: 80,
    targetBpm: 120,
    gridUnit: NoteGrid.triplet,
    beatsPerBar: 4,
    skills: {Skill.control, Skill.coordination},
    sticking: [
      // Bar 1: straight flam-accent bar.
      ..._bar([R, L, R, L]),
      // Bar 2: the second beat (left lead) opens up into a sustained
      // quarter note instead of its triplet beat — same duration, more space.
      ..._flamAccentBeat(R),
      note(L, NoteValue.quarter),
      ..._flamAccentBeat(R),
      ..._flamAccentBeat(L),
    ],
  ),
  Rudiment(
    id: 'etude_flam_accent_4',
    name: 'Flam Accent · Étude 4',
    description:
        'Vier Takte im Wechsel: Flam-Accent-Takt im Triolen-Feel gegen einen geraden Achtel-Akzent-Takt, mit steigender Akzentdichte.',
    collection: ExerciseCollection.rudimentEtudes,
    collectionGroup: 'Flam Accent',
    difficulty: Difficulty.advanced,
    minBpm: 90,
    targetBpm: 140,
    gridUnit: NoteGrid.triplet,
    beatsPerBar: 4,
    skills: {Skill.control, Skill.coordination},
    sticking: [
      // Bar 1: flam-accent bar (triplet / 6-feel).
      ..._bar([R, L, R, L]),
      // Bar 2: straight eighth-note accents (2-feel contrast).
      ...eighths([R, L, R, L, R, L, R, L], accents: {0, 4}),
      // Bar 3: flam-accent bar again, opposite starting lead.
      ..._bar([L, R, L, R]),
      // Bar 4: straight eighths, denser accent pattern.
      ...eighths([R, L, R, L, R, L, R, L], accents: {0, 2, 4, 6}),
    ],
  ),
  Rudiment(
    id: 'etude_flam_accent_5',
    name: 'Flam Accent · Étude 5',
    description:
        'Herausforderung: durchgehende Flam Accents bis zum Zieltempo, letzter Takt dichter mit doppeltem Akzent und Ghost-Note pro Schlag.',
    collection: ExerciseCollection.rudimentEtudes,
    collectionGroup: 'Flam Accent',
    difficulty: Difficulty.professional,
    minBpm: 100,
    targetBpm: 150,
    gridUnit: NoteGrid.triplet,
    beatsPerBar: 4,
    skills: {Skill.control, Skill.coordination},
    sticking: [
      // Bars 1–3: continuous flam accents, starting lead alternates per bar.
      ..._bar([R, L, R, L]),
      ..._bar([L, R, L, R]),
      ..._bar([R, L, R, L]),
      // Bar 4: busier — accented flam and closing tap, ghosted middle tap.
      ..._flamAccentBeatBusy(R),
      ..._flamAccentBeatBusy(L),
      ..._flamAccentBeatBusy(R),
      ..._flamAccentBeatBusy(L),
    ],
  ),
];
