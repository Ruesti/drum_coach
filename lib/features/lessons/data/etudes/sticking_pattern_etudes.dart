import '../../models/rudiment.dart';
import '../etude_dsl.dart';

/// Swap every hand in [hands] (R↔L) — used to build the mirrored second
/// half of each 4-bar sticking étude below.
List<Hand> _mirror(List<Hand> hands) =>
    hands.map((h) => h == R ? L : R).toList();

/// Six short (4-bar) sticking studies, each built from one 8-note eighth-note
/// motif with a clear inner structure instead of a loose chain of unrelated
/// one-bar patterns:
///   bar 1  motif
///   bar 2  motif repeated (festigen)
///   bar 3  motif mirrored (R<->L getauscht)
///   bar 4  mirrored motif repeated (Abschluss/Symmetrie)
/// Straight eighth notes throughout, no accents/ghosts — pure hand-sequence
/// drilling for the pad. #1-3 use an even 4:4 R/L split (beginner); #4-6
/// step up to asymmetric 5:3 / 3:5 splits (intermediate).
final List<Rudiment> stickingPatternEtudes = <Rudiment>[
  () {
    const motif = [R, L, L, R, L, R, R, L]; // 4:4
    return Rudiment(
      id: 'etude_pad_sticking_1',
      name: 'Sticking-Studie 1',
      description:
          'Motiv R L L R L R R L, wiederholt, dann gespiegelt und die '
          'Spiegelung wiederholt — eine kleine 4-Takt-Studie statt loser '
          'Handsatz-Häppchen.',
      collection: ExerciseCollection.padWorkouts,
      collectionGroup: 'Sticking-Patterns',
      difficulty: Difficulty.beginner,
      minBpm: 70,
      targetBpm: 110,
      gridUnit: NoteGrid.eighth,
      beatsPerBar: 4,
      skills: {Skill.coordination, Skill.control},
      sticking: [
        ...eighths(motif),
        ...eighths(motif),
        ...eighths(_mirror(motif)),
        ...eighths(_mirror(motif)),
      ],
    );
  }(),
  () {
    const motif = [L, R, R, L, L, R, L, R]; // 4:4
    return Rudiment(
      id: 'etude_pad_sticking_2',
      name: 'Sticking-Studie 2',
      description:
          'Motiv L R R L L R L R, wiederholt, dann gespiegelt und die '
          'Spiegelung wiederholt.',
      collection: ExerciseCollection.padWorkouts,
      collectionGroup: 'Sticking-Patterns',
      difficulty: Difficulty.beginner,
      minBpm: 70,
      targetBpm: 115,
      gridUnit: NoteGrid.eighth,
      beatsPerBar: 4,
      skills: {Skill.coordination, Skill.control},
      sticking: [
        ...eighths(motif),
        ...eighths(motif),
        ...eighths(_mirror(motif)),
        ...eighths(_mirror(motif)),
      ],
    );
  }(),
  () {
    const motif = [R, R, L, R, L, L, R, L]; // 4:4
    return Rudiment(
      id: 'etude_pad_sticking_3',
      name: 'Sticking-Studie 3',
      description:
          'Motiv R R L R L L R L, wiederholt, dann gespiegelt und die '
          'Spiegelung wiederholt.',
      collection: ExerciseCollection.padWorkouts,
      collectionGroup: 'Sticking-Patterns',
      difficulty: Difficulty.beginner,
      minBpm: 75,
      targetBpm: 120,
      gridUnit: NoteGrid.eighth,
      beatsPerBar: 4,
      skills: {Skill.coordination, Skill.control},
      sticking: [
        ...eighths(motif),
        ...eighths(motif),
        ...eighths(_mirror(motif)),
        ...eighths(_mirror(motif)),
      ],
    );
  }(),
  () {
    const motif = [R, R, L, R, R, L, L, R]; // 5 R : 3 L
    return Rudiment(
      id: 'etude_pad_sticking_4',
      name: 'Sticking-Studie 4',
      description:
          'Asymmetrisches Motiv R R L R R L L R (5:3), wiederholt, dann '
          'gespiegelt und die Spiegelung wiederholt.',
      collection: ExerciseCollection.padWorkouts,
      collectionGroup: 'Sticking-Patterns',
      difficulty: Difficulty.intermediate,
      minBpm: 90,
      targetBpm: 130,
      gridUnit: NoteGrid.eighth,
      beatsPerBar: 4,
      skills: {Skill.coordination, Skill.control},
      sticking: [
        ...eighths(motif),
        ...eighths(motif),
        ...eighths(_mirror(motif)),
        ...eighths(_mirror(motif)),
      ],
    );
  }(),
  () {
    const motif = [L, R, R, L, R, L, R, R]; // 5 R : 3 L
    return Rudiment(
      id: 'etude_pad_sticking_5',
      name: 'Sticking-Studie 5',
      description:
          'Asymmetrisches Motiv L R R L R L R R (5:3), wiederholt, dann '
          'gespiegelt und die Spiegelung wiederholt.',
      collection: ExerciseCollection.padWorkouts,
      collectionGroup: 'Sticking-Patterns',
      difficulty: Difficulty.intermediate,
      minBpm: 95,
      targetBpm: 135,
      gridUnit: NoteGrid.eighth,
      beatsPerBar: 4,
      skills: {Skill.coordination, Skill.control},
      sticking: [
        ...eighths(motif),
        ...eighths(motif),
        ...eighths(_mirror(motif)),
        ...eighths(_mirror(motif)),
      ],
    );
  }(),
  () {
    const motif = [R, L, L, R, L, L, R, L]; // 3 R : 5 L
    return Rudiment(
      id: 'etude_pad_sticking_6',
      name: 'Sticking-Studie 6',
      description:
          'Asymmetrisches Motiv R L L R L L R L (3:5), wiederholt, dann '
          'gespiegelt und die Spiegelung wiederholt.',
      collection: ExerciseCollection.padWorkouts,
      collectionGroup: 'Sticking-Patterns',
      difficulty: Difficulty.intermediate,
      minBpm: 100,
      targetBpm: 140,
      gridUnit: NoteGrid.eighth,
      beatsPerBar: 4,
      skills: {Skill.coordination, Skill.control},
      sticking: [
        ...eighths(motif),
        ...eighths(motif),
        ...eighths(_mirror(motif)),
        ...eighths(_mirror(motif)),
      ],
    );
  }(),
];
