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
  Rudiment(
    id: 'etude_pad_accent_marsch',
    name: 'Akzent-Workout · Marsch',
    description:
        'Fester Downbeat-Akzent auf Zählzeit 1+3 über 6 Takte, der sich in '
        'den letzten 2 Takten zum Doppel-Akzent auf allen vier Zählzeiten '
        '(1+2+3+4, Marsch-Gefühl) steigert.',
    collection: ExerciseCollection.padWorkouts,
    collectionGroup: 'Akzent-Workout',
    difficulty: Difficulty.intermediate,
    minBpm: 70,
    targetBpm: 120,
    gridUnit: NoteGrid.sixteenth,
    beatsPerBar: 4,
    skills: {Skill.control, Skill.coordination},
    sticking: [
      // Takt 1-6: Akzent auf 1+3 (Downbeat-Betonung), 2 und 4 unbetont.
      for (var i = 0; i < 6; i++) ...[
        ..._binaryBeat({0}),
        ..._binaryBeat({}),
        ..._binaryBeat({0}),
        ..._binaryBeat({}),
      ],
      // Takt 7-8: Steigerung zum Marsch-Doppel-Akzent (1+2+3+4).
      for (var i = 0; i < 2; i++)
        for (var j = 0; j < 4; j++) ..._binaryBeat({0}),
    ],
  ),
  Rudiment(
    id: 'etude_pad_accent_verschiebung',
    name: 'Akzent-Workout · Verschiebung',
    description:
        'Akzent wandert alle 2 Takte eine Zählzeit weiter: erst auf 1, dann '
        'auf 2, dann auf 3, dann auf 4 — ein voller Durchlauf durch alle '
        'vier Positionen über 16tel.',
    collection: ExerciseCollection.padWorkouts,
    collectionGroup: 'Akzent-Workout',
    difficulty: Difficulty.intermediate,
    minBpm: 70,
    targetBpm: 120,
    gridUnit: NoteGrid.sixteenth,
    beatsPerBar: 4,
    skills: {Skill.control, Skill.coordination},
    sticking: [
      // Je 2 Takte pro Position (0=Zählzeit 1 ... 3=Zählzeit 4); nur die
      // Zielzählzeit trägt den Downbeat-Akzent, die anderen bleiben glatt.
      for (var pos = 0; pos < 4; pos++)
        for (var bar = 0; bar < 2; bar++)
          for (var beat = 0; beat < 4; beat++)
            ..._binaryBeat(beat == pos ? {0} : {}),
    ],
  ),
  Rudiment(
    id: 'etude_pad_accent_ternaer_versetzt',
    name: 'Akzent-Workout · Ternär versetzt',
    description:
        'Achteltriolen mit Akzent auf dem 2. Triolen-Schlag statt dem '
        'Downbeat (versetzter, ungewöhnlicherer Sound): 6 Takte Wiederholung, '
        'dann eine kleine Variation (Akzent auf dem 3. Schlag) zum Schluss.',
    collection: ExerciseCollection.padWorkouts,
    collectionGroup: 'Akzent-Workout',
    difficulty: Difficulty.advanced,
    minBpm: 70,
    targetBpm: 120,
    gridUnit: NoteGrid.triplet,
    beatsPerBar: 4,
    skills: {Skill.control, Skill.coordination},
    sticking: [
      // Takt 1-6: Akzent auf dem 2. Triolen-Schlag (Index 1).
      for (var i = 0; i < 24; i++)
        ..._ternaryBeat(i.isEven ? [R, L, R] : [L, R, L], {1}),
      // Takt 7-8: kleine Variation — Akzent wandert auf den 3. Schlag.
      for (var i = 0; i < 8; i++)
        ..._ternaryBeat(i.isEven ? [R, L, R] : [L, R, L], {2}),
    ],
  ),
  Rudiment(
    id: 'etude_pad_accent_mix',
    name: 'Akzent-Workout · Mix Binär/Ternär',
    description:
        'Klares A-B-A\'-B\'-Muster: 2 Takte binär mit Akzent auf 1+3, dann '
        '2 Takte ternär mit Akzent auf dem Downbeat, dann eine Wiederholung '
        'beider Ideen (4 weitere Takte).',
    collection: ExerciseCollection.padWorkouts,
    collectionGroup: 'Akzent-Workout',
    difficulty: Difficulty.advanced,
    minBpm: 60,
    targetBpm: 110,
    gridUnit: NoteGrid.sixteenth,
    beatsPerBar: 4,
    skills: {Skill.control, Skill.coordination},
    sticking: [
      // A (Takt 1-2): binär, Akzent auf 1+3.
      for (var i = 0; i < 2; i++) ...[
        ..._binaryBeat({0}),
        ..._binaryBeat({}),
        ..._binaryBeat({0}),
        ..._binaryBeat({}),
      ],
      // B (Takt 3-4): ternär, Akzent auf dem Downbeat jeder Triole.
      for (var i = 0; i < 8; i++)
        ..._ternaryBeat(i.isEven ? [R, L, R] : [L, R, L], {0}),
      // A' (Takt 5-6): Wiederholung von A.
      for (var i = 0; i < 2; i++) ...[
        ..._binaryBeat({0}),
        ..._binaryBeat({}),
        ..._binaryBeat({0}),
        ..._binaryBeat({}),
      ],
      // B' (Takt 7-8): Wiederholung von B.
      for (var i = 0; i < 8; i++)
        ..._ternaryBeat(i.isEven ? [R, L, R] : [L, R, L], {0}),
    ],
  ),
];
