import '../../models/rudiment.dart';
import '../etude_dsl.dart';

/// One bar (16 sixteenths, 4.0 quarters) of steady alternating singles
/// (RLRL…) played at a single dynamic level: [ghost] for pp, [accent] for
/// f, neither for a plain mf. The sticking never changes across the
/// dynamics étude below — only the volume does.
List<StrokeBeat> _dynamicsBar({bool ghost = false, bool accent = false}) => [
      for (final h in [R, L, R, L, R, L, R, L, R, L, R, L, R, L, R, L])
        note(h, NoteValue.sixteenth, ghost: ghost, accent: accent),
    ];

/// One single-paradiddle cycle — RLRR LRLL when [leadRight], its mirror
/// LRLL RLRR otherwise. 8 strokes; the "roter Faden" pattern for the
/// paradiddle étude below, only ever re-timed (eighths, then sixteenths),
/// never altered.
List<Hand> _paradiddleCycle(bool leadRight) => leadRight
    ? const [R, L, R, R, L, R, L, L]
    : const [L, R, L, L, R, L, R, R];

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
  Rudiment(
    id: 'etude_pad_warmup_dynamik',
    name: 'Warm-Up · Dynamik-Aufbau',
    description:
        'Eine einzige Idee — durchgehende alternierende 16tel-Einzelschläge — '
        'wird nur in der Lautstärke gesteigert: 3 Takte Ghost-Notes (pp), '
        '3 Takte normal (mf), 3 Takte Akzent (f); der letzte Takt stellt '
        'Ghost und Akzent innerhalb einer Zeile direkt gegenüber.',
    collection: ExerciseCollection.padWorkouts,
    collectionGroup: 'Warm-Up',
    difficulty: Difficulty.intermediate,
    minBpm: 50,
    targetBpm: 110,
    gridUnit: NoteGrid.sixteenth,
    beatsPerBar: 4,
    skills: {Skill.endurance, Skill.control},
    sticking: [
      // Takte 1-3: Ghost-Notes (pp) — leise, kontrolliert einspielen.
      ..._dynamicsBar(ghost: true),
      ..._dynamicsBar(ghost: true),
      ..._dynamicsBar(ghost: true),
      // Takte 4-6: normale Lautstärke (mf) — gleiche Sticking, lauter.
      ..._dynamicsBar(),
      ..._dynamicsBar(),
      ..._dynamicsBar(),
      // Takte 7-9: Akzent (f) — voll durchgespielt.
      ..._dynamicsBar(accent: true),
      ..._dynamicsBar(accent: true),
      ..._dynamicsBar(accent: true),
      // Takt 10: Kontrast in einer Zeile — erste Hälfte Ghost, zweite Akzent.
      for (final h in [R, L, R, L, R, L, R, L])
        note(h, NoteValue.sixteenth, ghost: true),
      for (final h in [R, L, R, L, R, L, R, L])
        note(h, NoteValue.sixteenth, accent: true),
    ],
  ),
  Rudiment(
    id: 'etude_pad_warmup_paradiddle',
    name: 'Warm-Up · Paradiddle-Steigerung',
    description:
        'Ein einzelner Paradiddle-Zyklus (RLRR LRLL) wird 4 Takte lang in '
        'Achteln eingespielt, dann 4 Takte lang in 16teln verdichtet — '
        'gleiche Idee, doppeltes Tempo.',
    collection: ExerciseCollection.padWorkouts,
    collectionGroup: 'Warm-Up',
    difficulty: Difficulty.intermediate,
    minBpm: 60,
    targetBpm: 120,
    gridUnit: NoteGrid.sixteenth,
    beatsPerBar: 4,
    skills: {Skill.endurance, Skill.control, Skill.coordination},
    sticking: [
      // Takte 1-4: ein Paradiddle-Zyklus pro Takt, in Achteln.
      ...eighths(_paradiddleCycle(true)),
      ...eighths(_paradiddleCycle(false)),
      ...eighths(_paradiddleCycle(true)),
      ...eighths(_paradiddleCycle(false)),
      // Takte 5-8: gleiche Idee verdichtet — zwei Zyklen pro Takt in 16teln.
      ...sixteenths([..._paradiddleCycle(true), ..._paradiddleCycle(false)]),
      ...sixteenths([..._paradiddleCycle(true), ..._paradiddleCycle(false)]),
      ...sixteenths([..._paradiddleCycle(false), ..._paradiddleCycle(true)]),
      ...sixteenths([..._paradiddleCycle(false), ..._paradiddleCycle(true)]),
    ],
  ),
  Rudiment(
    id: 'etude_pad_warmup_handdominanz',
    name: 'Warm-Up · Handdominanz',
    description:
        'Rechts-dominante Gruppe (RRRL) zunächst in Achteln, dann in 16teln '
        'gesteigert; dieselbe Idee gespiegelt auf Links (LLLR) zur Kontrolle '
        'der jeweils schwächeren Hand; zum Schluss ein Takt, der beide '
        'Richtungen zusammenführt.',
    collection: ExerciseCollection.padWorkouts,
    collectionGroup: 'Warm-Up',
    difficulty: Difficulty.beginner,
    minBpm: 50,
    targetBpm: 110,
    gridUnit: NoteGrid.sixteenth,
    beatsPerBar: 4,
    skills: {Skill.endurance, Skill.control},
    sticking: [
      // Takte 1-2: RRRL in Achteln (2 Gruppen pro Takt).
      ...eighths([R, R, R, L, R, R, R, L]),
      ...eighths([R, R, R, L, R, R, R, L]),
      // Takte 3-4: RRRL in 16teln (4 Gruppen pro Takt) — gleiche Idee, schneller.
      ...sixteenths([R, R, R, L, R, R, R, L, R, R, R, L, R, R, R, L]),
      ...sixteenths([R, R, R, L, R, R, R, L, R, R, R, L, R, R, R, L]),
      // Takte 5-6: gespiegelt auf Links, wieder in Achteln.
      ...eighths([L, L, L, R, L, L, L, R]),
      ...eighths([L, L, L, R, L, L, L, R]),
      // Takte 7-8: LLLR in 16teln.
      ...sixteenths([L, L, L, R, L, L, L, R, L, L, L, R, L, L, L, R]),
      ...sixteenths([L, L, L, R, L, L, L, R, L, L, L, R, L, L, L, R]),
      // Takt 9: Zusammenführung — erste Hälfte RRRL, zweite Hälfte LLLR.
      ...sixteenths([R, R, R, L, R, R, R, L, L, L, L, R, L, L, L, R]),
    ],
  ),
  Rudiment(
    id: 'etude_pad_warmup_kombi',
    name: 'Warm-Up · Kombination',
    description:
        'Verbindet die beiden anderen Warm-Up-Ideen dieser Sammlung zu einer '
        'kurzen Übung: die Gruppengröße wächst Takt für Takt von 1 '
        '(alternierende Einzelschläge) über 2er- und 3er- bis zur '
        '4er-Gruppe, jeweils einmal mit Rechts- und einmal mit Linksstart.',
    collection: ExerciseCollection.padWorkouts,
    collectionGroup: 'Warm-Up',
    difficulty: Difficulty.intermediate,
    minBpm: 55,
    targetBpm: 120,
    gridUnit: NoteGrid.sixteenth,
    beatsPerBar: 4,
    skills: {Skill.endurance, Skill.control, Skill.coordination},
    sticking: [
      // Takt 1-2: Gruppengröße 1 — alternierende Einzelschläge (Einspielübung-Idee).
      ...sixteenths([R, L, R, L, R, L, R, L, R, L, R, L, R, L, R, L]),
      ...sixteenths([L, R, L, R, L, R, L, R, L, R, L, R, L, R, L, R]),
      // Takt 3-4: Gruppengröße 2 (Handsatz-Idee).
      ...sixteenths([R, R, L, L, R, R, L, L, R, R, L, L, R, R, L, L]),
      ...sixteenths([L, L, R, R, L, L, R, R, L, L, R, R, L, L, R, R]),
      // Takt 5-6: Gruppengröße 3.
      ...sixteenths([R, R, R, L, L, L, R, R, R, L, L, L, R, R, R, L]),
      ...sixteenths([L, L, L, R, R, R, L, L, L, R, R, R, L, L, L, R]),
      // Takt 7-8: Gruppengröße 4 — Ziel der Steigerung.
      ...sixteenths([R, R, R, R, L, L, L, L, R, R, R, R, L, L, L, L]),
      ...sixteenths([L, L, L, L, R, R, R, R, L, L, L, L, R, R, R, R]),
    ],
  ),
];
