import '../../models/rudiment.dart';
import '../etude_dsl.dart';

/// Two page-length accent études — one binary (16th notes, 4-groups), one
/// ternary (eighth-note triplets, 3-groups) — each stringing several accent
/// ideas (walking, fixed, doubled) into one continuous 8-bar piece.
/// Inspired by (not copied from) the "Akzente binär/ternär" section of a
/// workout PDF the user provided under docs/Übungen/ (see
/// docs/Übungen/README.md).
List<StrokeBeat> _binaryBeat(Set<int> accents) =>
    sixteenths([R, L, R, L], accents: accents);
List<StrokeBeat> _ternaryBeat(List<Hand> hands, Set<int> accents) =>
    triplet8(hands, accents: accents);

final List<Rudiment> accentWorkoutEtudes = <Rudiment>[
  Rudiment(
    id: 'etude_pad_accent_binaer',
    name: 'Akzent-Workout · Binär',
    description:
        'Durchgehende 16tel-Einzelschläge, 8 Takte: wandernder Akzent, '
        'fester Nachschlag-Akzent und Doppel-Akzent nacheinander.',
    collection: ExerciseCollection.padWorkouts,
    collectionGroup: 'Akzent-Workout',
    difficulty: Difficulty.intermediate,
    minBpm: 70,
    targetBpm: 120,
    gridUnit: NoteGrid.sixteenth,
    beatsPerBar: 4,
    skills: {Skill.control, Skill.coordination},
    sticking: [
      // Takt 1-2: wandernder Akzent (0→1→2→3).
      ..._binaryBeat({0}), ..._binaryBeat({1}),
      ..._binaryBeat({2}), ..._binaryBeat({3}),
      ..._binaryBeat({0}), ..._binaryBeat({1}),
      ..._binaryBeat({2}), ..._binaryBeat({3}),
      // Takt 3-4: fester Akzent auf dem "e" (Index 1).
      for (var i = 0; i < 8; i++) ..._binaryBeat({1}),
      // Takt 5-6: fester Akzent auf dem "&" (Index 2).
      for (var i = 0; i < 8; i++) ..._binaryBeat({2}),
      // Takt 7-8: Doppel-Akzent (Downbeat + "&").
      for (var i = 0; i < 8; i++) ..._binaryBeat({0, 2}),
    ],
  ),
  Rudiment(
    id: 'etude_pad_accent_ternaer',
    name: 'Akzent-Workout · Ternär',
    description:
        'Durchgehende Achteltriolen, 8 Takte: Akzent auf jedem Triolen-'
        'Downbeat, dann ein wandernder Akzent über die Triole.',
    collection: ExerciseCollection.padWorkouts,
    collectionGroup: 'Akzent-Workout',
    difficulty: Difficulty.advanced,
    minBpm: 70,
    targetBpm: 120,
    gridUnit: NoteGrid.triplet,
    beatsPerBar: 4,
    skills: {Skill.control, Skill.coordination},
    sticking: [
      // Takt 1-4: Akzent auf jedem Triolen-Downbeat, Handführung wechselt
      // pro Zählzeit (RLR / LRL) für gleichmäßige Beanspruchung.
      for (var i = 0; i < 16; i++)
        ..._ternaryBeat(i.isEven ? [R, L, R] : [L, R, L], {0}),
      // Takt 5-8: wandernder Akzent innerhalb der Triole (0→1→2).
      for (var i = 0; i < 16; i++)
        ..._ternaryBeat(i.isEven ? [R, L, R] : [L, R, L], {i % 3}),
    ],
  ),
];
