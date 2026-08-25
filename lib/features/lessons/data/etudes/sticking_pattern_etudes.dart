import '../../models/rudiment.dart';
import '../etude_dsl.dart';

/// One page-length sticking étude: 10 one-bar R/L hand-pattern permutations
/// (straight eighth notes, no accents/ghosts) played back to back — the
/// same "one page, many short lines to loop individually" format as a
/// sticking worksheet. Inspired by (not copied from) a sticking-pattern
/// PDF the user provided under docs/Übungen/ (see docs/Übungen/README.md).
final List<Rudiment> stickingPatternEtudes = <Rudiment>[
  Rudiment(
    id: 'etude_pad_sticking_page',
    name: 'Sticking-Patterns · Seite 1',
    description:
        '10 verschiedene Achtel-Handsätze im Wechsel, ein Takt pro Muster — '
        'jeden Takt einzeln in Schleife üben, wie bei einem Sticking-'
        'Übungsblatt.',
    collection: ExerciseCollection.padWorkouts,
    collectionGroup: 'Sticking-Patterns',
    difficulty: Difficulty.beginner,
    minBpm: 70,
    targetBpm: 110,
    gridUnit: NoteGrid.eighth,
    beatsPerBar: 4,
    skills: {Skill.coordination, Skill.control},
    sticking: [
      ...eighths([R, L, R, L, R, L, R, L]), // 1
      ...eighths([L, R, L, R, L, R, L, R]), // 2
      ...eighths([R, R, L, L, R, R, L, L]), // 3
      ...eighths([L, L, R, R, L, L, R, R]), // 4
      ...eighths([R, L, L, R, R, L, L, R]), // 5
      ...eighths([L, R, R, L, L, R, R, L]), // 6
      ...eighths([R, R, L, R, L, L, R, L]), // 7
      ...eighths([L, L, R, L, R, R, L, R]), // 8
      ...eighths([R, R, R, L, L, R, R, R]), // 9
      ...eighths([L, L, L, R, R, L, L, L]), // 10
    ],
  ),
];
