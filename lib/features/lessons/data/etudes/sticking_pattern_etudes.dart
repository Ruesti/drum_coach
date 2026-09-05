import '../../models/rudiment.dart';
import '../etude_dsl.dart';

/// Swap every hand in [hands] (R↔L) — used to build the mirrored half of
/// each sticking étude below.
List<Hand> _mirror(List<Hand> hands) =>
    hands.map((h) => h == R ? L : R).toList();

/// Double every stroke (R L → R R L L) — turns the 8-note eighth-note motif
/// into a 16-note sixteenth-note motif for the "verdichtet" second half:
/// same hand sequence, doubled into rudimental doubles instead of singles.
List<Hand> _double(List<Hand> hands) =>
    hands.expand((h) => [h, h]).toList();

/// Six 8-bar sticking studies, each built from ONE 8-note motif developed
/// over the whole piece instead of a chain of unrelated one-bar patterns:
///   bar 1-2  motif, played twice (eighths)
///   bar 3-4  the motif mirrored (R<->L getauscht), played twice
///   bar 5-6  the SAME motif densified into doubles (sixteenths), twice
///   bar 7-8  the densified motif mirrored, played twice
/// One idea, carried through in two dynamics (singles → doubles) instead of
/// switching to a new, unrelated figure every bar. #1-3 use an even 4:4 R/L
/// split (beginner); #4-6 step up to asymmetric 5:3 / 3:5 splits
/// (intermediate).
final List<Rudiment> stickingPatternEtudes = <Rudiment>[
  () {
    const motif = [R, L, L, R, L, R, R, L]; // 4:4
    return Rudiment(
      id: 'etude_pad_sticking_1',
      name: 'Kreuzmuster',
      description:
          'Motiv R L L R L R R L: erst als Einzelschläge gespielt und '
          'gespiegelt, dann dasselbe Motiv als Doppelschläge verdichtet und '
          'wieder gespiegelt — eine 8-Takt-Studie mit rotem Faden statt '
          'loser Handsatz-Häppchen.',
      collection: ExerciseCollection.padWorkouts,
      collectionGroup: 'Sticking-Patterns',
      difficulty: Difficulty.beginner,
      minBpm: 70,
      targetBpm: 110,
      gridUnit: NoteGrid.sixteenth,
      beatsPerBar: 4,
      skills: {Skill.coordination, Skill.control},
      sticking: [
        ...eighths(motif), ...eighths(motif),
        ...eighths(_mirror(motif)), ...eighths(_mirror(motif)),
        ...sixteenths(_double(motif)), ...sixteenths(_double(motif)),
        ...sixteenths(_double(_mirror(motif))), ...sixteenths(_double(_mirror(motif))),
      ],
    );
  }(),
  () {
    const motif = [L, R, R, L, L, R, L, R]; // 4:4
    return Rudiment(
      id: 'etude_pad_sticking_2',
      name: 'Wellenmuster',
      description:
          'Motiv L R R L L R L R: erst als Einzelschläge, dann als '
          'Doppelschläge verdichtet — jeweils gespiegelt wiederholt.',
      collection: ExerciseCollection.padWorkouts,
      collectionGroup: 'Sticking-Patterns',
      difficulty: Difficulty.beginner,
      minBpm: 70,
      targetBpm: 115,
      gridUnit: NoteGrid.sixteenth,
      beatsPerBar: 4,
      skills: {Skill.coordination, Skill.control},
      sticking: [
        ...eighths(motif), ...eighths(motif),
        ...eighths(_mirror(motif)), ...eighths(_mirror(motif)),
        ...sixteenths(_double(motif)), ...sixteenths(_double(motif)),
        ...sixteenths(_double(_mirror(motif))), ...sixteenths(_double(_mirror(motif))),
      ],
    );
  }(),
  () {
    const motif = [R, R, L, R, L, L, R, L]; // 4:4
    return Rudiment(
      id: 'etude_pad_sticking_3',
      name: 'Doppel-Wechsel',
      description:
          'Motiv R R L R L L R L: erst als Einzelschläge, dann als '
          'Doppelschläge verdichtet — jeweils gespiegelt wiederholt.',
      collection: ExerciseCollection.padWorkouts,
      collectionGroup: 'Sticking-Patterns',
      difficulty: Difficulty.beginner,
      minBpm: 75,
      targetBpm: 120,
      gridUnit: NoteGrid.sixteenth,
      beatsPerBar: 4,
      skills: {Skill.coordination, Skill.control},
      sticking: [
        ...eighths(motif), ...eighths(motif),
        ...eighths(_mirror(motif)), ...eighths(_mirror(motif)),
        ...sixteenths(_double(motif)), ...sixteenths(_double(motif)),
        ...sixteenths(_double(_mirror(motif))), ...sixteenths(_double(_mirror(motif))),
      ],
    );
  }(),
  () {
    const motif = [R, R, L, R, R, L, L, R]; // 5 R : 3 L
    return Rudiment(
      id: 'etude_pad_sticking_4',
      name: 'Rechts-Schwerpunkt',
      description:
          'Asymmetrisches Motiv R R L R R L L R (5:3): erst als '
          'Einzelschläge, dann als Doppelschläge verdichtet — jeweils '
          'gespiegelt wiederholt.',
      collection: ExerciseCollection.padWorkouts,
      collectionGroup: 'Sticking-Patterns',
      difficulty: Difficulty.intermediate,
      minBpm: 90,
      targetBpm: 130,
      gridUnit: NoteGrid.sixteenth,
      beatsPerBar: 4,
      skills: {Skill.coordination, Skill.control},
      sticking: [
        ...eighths(motif), ...eighths(motif),
        ...eighths(_mirror(motif)), ...eighths(_mirror(motif)),
        ...sixteenths(_double(motif)), ...sixteenths(_double(motif)),
        ...sixteenths(_double(_mirror(motif))), ...sixteenths(_double(_mirror(motif))),
      ],
    );
  }(),
  () {
    const motif = [L, R, R, L, R, L, R, R]; // 5 R : 3 L
    return Rudiment(
      id: 'etude_pad_sticking_5',
      name: 'Rechts-Fluss',
      description:
          'Asymmetrisches Motiv L R R L R L R R (5:3): erst als '
          'Einzelschläge, dann als Doppelschläge verdichtet — jeweils '
          'gespiegelt wiederholt.',
      collection: ExerciseCollection.padWorkouts,
      collectionGroup: 'Sticking-Patterns',
      difficulty: Difficulty.intermediate,
      minBpm: 95,
      targetBpm: 135,
      gridUnit: NoteGrid.sixteenth,
      beatsPerBar: 4,
      skills: {Skill.coordination, Skill.control},
      sticking: [
        ...eighths(motif), ...eighths(motif),
        ...eighths(_mirror(motif)), ...eighths(_mirror(motif)),
        ...sixteenths(_double(motif)), ...sixteenths(_double(motif)),
        ...sixteenths(_double(_mirror(motif))), ...sixteenths(_double(_mirror(motif))),
      ],
    );
  }(),
  () {
    const motif = [R, L, L, R, L, L, R, L]; // 3 R : 5 L
    return Rudiment(
      id: 'etude_pad_sticking_6',
      name: 'Links-Schwerpunkt',
      description:
          'Asymmetrisches Motiv R L L R L L R L (3:5): erst als '
          'Einzelschläge, dann als Doppelschläge verdichtet — jeweils '
          'gespiegelt wiederholt.',
      collection: ExerciseCollection.padWorkouts,
      collectionGroup: 'Sticking-Patterns',
      difficulty: Difficulty.intermediate,
      minBpm: 100,
      targetBpm: 140,
      gridUnit: NoteGrid.sixteenth,
      beatsPerBar: 4,
      skills: {Skill.coordination, Skill.control},
      sticking: [
        ...eighths(motif), ...eighths(motif),
        ...eighths(_mirror(motif)), ...eighths(_mirror(motif)),
        ...sixteenths(_double(motif)), ...sixteenths(_double(motif)),
        ...sixteenths(_double(_mirror(motif))), ...sixteenths(_double(_mirror(motif))),
      ],
    );
  }(),
];
