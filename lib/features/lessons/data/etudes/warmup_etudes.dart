import '../../models/rudiment.dart';
import '../etude_dsl.dart';

/// Two page-length warm-up pieces, each stringing several short lines into
/// one continuous étude — "verbinde alle Zeilen zu einer Übung" (connect
/// all lines into one exercise) was the explicit instruction on one of the
/// source warm-up sheets the user provided under docs/Übungen/. Inspired by
/// (not copied from) those PDFs — see docs/Übungen/README.md.
final List<Rudiment> warmupEtudes = <Rudiment>[
  Rudiment(
    id: 'etude_pad_warmup_einspielen',
    name: 'Warm-Up · Einspielübung',
    description:
        '6 aufeinander aufbauende Zeilen (je 1 Takt Viertel + 1 Takt Achtel) '
        'zu einer durchgehenden Einspielübung verbunden: Einzelhand, '
        'alternierend, dann bis zu 16tel gesteigert.',
    collection: ExerciseCollection.padWorkouts,
    collectionGroup: 'Warm-Up',
    difficulty: Difficulty.beginner,
    minBpm: 40,
    targetBpm: 120,
    gridUnit: NoteGrid.sixteenth,
    beatsPerBar: 4,
    skills: {Skill.endurance, Skill.control},
    sticking: [
      // Zeile 1: nur rechte Hand.
      ...[R, R, R, R].map((h) => note(h, NoteValue.quarter)),
      ...eighths([R, R, R, R, R, R, R, R]),
      // Zeile 2: nur linke Hand.
      ...[L, L, L, L].map((h) => note(h, NoteValue.quarter)),
      ...eighths([L, L, L, L, L, L, L, L]),
      // Zeile 3: alternierend, rechts beginnend.
      ...[R, L, R, L].map((h) => note(h, NoteValue.quarter)),
      ...eighths([R, L, R, L, R, L, R, L]),
      // Zeile 4: alternierend, links beginnend.
      ...[L, R, L, R].map((h) => note(h, NoteValue.quarter)),
      ...eighths([L, R, L, R, L, R, L, R]),
      // Zeile 5: Handwechsel mitten in der Zeile (8 L, dann 8 R).
      ...eighths([L, L, L, L, L, L, L, L]),
      ...eighths([R, R, R, R, R, R, R, R]),
      // Zeile 6: alternierende Achtel, dann alternierende 16tel (Tempo-Sprung).
      ...eighths([R, L, R, L, R, L, R, L]),
      ...sixteenths([R, L, R, L, R, L, R, L, R, L, R, L, R, L, R, L]),
    ],
  ),
  Rudiment(
    id: 'etude_pad_warmup_handsaetze',
    name: 'Warm-Up · Handsatz-Aufwärmen',
    description:
        '3 Handsatz-Blöcke (je 3 Takte 16tel) zu einer Aufwärm-Übung '
        'verbunden — von 2er- über 3er- bis 4er-Gruppen.',
    collection: ExerciseCollection.padWorkouts,
    collectionGroup: 'Warm-Up',
    difficulty: Difficulty.intermediate,
    minBpm: 60,
    targetBpm: 130,
    gridUnit: NoteGrid.sixteenth,
    beatsPerBar: 4,
    skills: {Skill.endurance, Skill.coordination},
    sticking: [
      // Block 1: 2er-Gruppen (RRLL), 3 Takte.
      ...sixteenths([R, R, L, L, R, R, L, L, R, R, L, L, R, R, L, L]),
      ...sixteenths([R, R, L, L, R, R, L, L, R, R, L, L, R, R, L, L]),
      ...sixteenths([R, R, L, L, R, R, L, L, R, R, L, L, R, R, L, L]),
      // Block 2: 3er-Gruppen (RRRLLL), 3 Takte.
      ...sixteenths([R, R, R, L, L, L, R, R, R, L, L, L, R, R, R, L]),
      ...sixteenths([L, L, R, R, R, L, L, L, R, R, R, L, L, L, R, R]),
      ...sixteenths([R, L, L, L, R, R, R, L, L, L, R, R, R, L, L, L]),
      // Block 3: 4er-Gruppen (RRRRLLLL), 3 Takte.
      ...sixteenths([R, R, R, R, L, L, L, L, R, R, R, R, L, L, L, L]),
      ...sixteenths([L, L, L, L, R, R, R, R, L, L, L, L, R, R, R, R]),
      ...sixteenths([R, R, R, R, L, L, L, L, R, R, R, R, L, L, L, L]),
    ],
  ),
];
