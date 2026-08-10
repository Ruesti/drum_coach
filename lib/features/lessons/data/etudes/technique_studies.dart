import '../../models/rudiment.dart';
import '../etude_dsl.dart';

// --- Study 1 & 2: accent-walk / accent-ghost building blocks ---------------
//
// Both studies play continuous 16th-note single strokes (RLRL RLRL ...).
// Each beat is a 4-note RLRL group and 4 is even, so every beat starts on R
// again — the alternation never breaks across beat boundaries.

/// One beat (4 sixteenths, RLRL) with the accent on cell [accentIndex]
/// (0-3) and no other dynamic marking.
List<StrokeBeat> _walkingAccentBeat(int accentIndex) =>
    sixteenths([R, L, R, L], accents: {accentIndex});

/// One beat (4 sixteenths, RLRL): cell 0 (the downbeat) accented, cells
/// 1-3 ghosted — trains the accent/ghost dynamic gap.
List<StrokeBeat> _accentGhostBeat() => [
      note(R, NoteValue.sixteenth, accent: true),
      note(L, NoteValue.sixteenth, ghost: true),
      note(R, NoteValue.sixteenth, ghost: true),
      note(L, NoteValue.sixteenth, ghost: true),
    ];

// --- Study 3: paradiddle + single-stroke-four building blocks --------------

/// One bar of straight single paradiddles (RLRR LRLL RLRR LRLL), lead note
/// of every group accented.
List<StrokeBeat> _paradiddleBar() => [
      ...sixteenths([R, L, R, R], accents: {0}),
      ...sixteenths([L, R, L, L], accents: {0}),
      ...sixteenths([R, L, R, R], accents: {0}),
      ...sixteenths([L, R, L, L], accents: {0}),
    ];

/// One bar of single-stroke-four: continuous 16th singles grouped 4+4+4+4,
/// the first note of every group accented.
List<StrokeBeat> _singleFourBar() => [
      ...sixteenths([R, L, R, L], accents: {0}),
      ...sixteenths([R, L, R, L], accents: {0}),
      ...sixteenths([R, L, R, L], accents: {0}),
      ...sixteenths([R, L, R, L], accents: {0}),
    ];

// --- Study 4: flam + drag + roll building blocks ----------------------------

/// One beat of alternating flams: an accented flam tap on [lead] followed
/// by a plain tap on the opposite hand (2 eighths = 1 beat).
List<StrokeBeat> _flamTapBeat(Hand lead) {
  final other = lead == R ? L : R;
  return [
    flam(lead, NoteValue.eighth, accent: true),
    note(other, NoteValue.eighth),
  ];
}

/// One beat of alternating drag taps: a drag on [lead] followed by an
/// accented tap on the opposite hand (2 eighths = 1 beat).
List<StrokeBeat> _dragTapBeat(Hand lead) {
  final other = lead == R ? L : R;
  return [
    drag(lead, NoteValue.eighth),
    note(other, NoteValue.eighth, accent: true),
  ];
}

/// One beat of a double-stroke roll (RRLL, 4 sixteenths = 1 beat).
List<StrokeBeat> _rollBeat16() => sixteenths([R, R, L, L]);

// --- Study 5: crescendo doubles ---------------------------------------------

/// One beat of double-stroke-roll sixteenths (RRLL) at a single dynamic
/// level: [ghost] for pp, [accent] for f, neither for a plain mf.
List<StrokeBeat> _crescendoRollBeat({bool ghost = false, bool accent = false}) => [
      for (final h in [R, R, L, L])
        note(h, NoteValue.sixteenth, ghost: ghost, accent: accent),
    ];

// --- Study 6: endurance singles ---------------------------------------------

/// One beat of 16th-note singles (RLRL) with the downbeat accented.
List<StrokeBeat> _enduranceBeat() => sixteenths([R, L, R, L], accents: {0});

/// Technique studies: unlike the single-rudiment étude progressions, each
/// entry here combines several ideas (accent placement, sticking concepts,
/// dynamics, stamina) into one short piece.
final List<Rudiment> techniqueStudies = <Rudiment>[
  Rudiment(
    id: 'etude_study_1',
    name: 'Akzent-Studie · Wandernde Akzente',
    description:
        'Durchgehende 16tel-Einzelschläge; der Akzent wandert von Zählzeit zu '
        'Zählzeit eine 16tel weiter nach hinten.',
    collection: ExerciseCollection.techniqueStudies,
    collectionGroup: 'Akzent-Studien',
    difficulty: Difficulty.intermediate,
    minBpm: 70,
    targetBpm: 110,
    gridUnit: NoteGrid.sixteenth,
    beatsPerBar: 4,
    skills: {Skill.control},
    sticking: [
      // Bar 1: accent on cell 0, then 1, then 2, then 3.
      ..._walkingAccentBeat(0),
      ..._walkingAccentBeat(1),
      ..._walkingAccentBeat(2),
      ..._walkingAccentBeat(3),
      // Bar 2: same walk repeated.
      ..._walkingAccentBeat(0),
      ..._walkingAccentBeat(1),
      ..._walkingAccentBeat(2),
      ..._walkingAccentBeat(3),
    ],
  ),
  Rudiment(
    id: 'etude_study_2',
    name: 'Akzent-Studie · Accent & Ghost',
    description:
        '16tel-Einzelschläge mit betonten Zählzeiten und geghosteten '
        'Zwischennoten — trainiert den dynamischen Abstand zwischen Accent '
        'und Ghost Note.',
    collection: ExerciseCollection.techniqueStudies,
    collectionGroup: 'Akzent-Studien',
    difficulty: Difficulty.advanced,
    minBpm: 80,
    targetBpm: 120,
    gridUnit: NoteGrid.sixteenth,
    beatsPerBar: 4,
    skills: {Skill.control},
    sticking: [
      // 2 bars = 8 beats of accent-then-3-ghosts.
      ..._accentGhostBeat(),
      ..._accentGhostBeat(),
      ..._accentGhostBeat(),
      ..._accentGhostBeat(),
      ..._accentGhostBeat(),
      ..._accentGhostBeat(),
      ..._accentGhostBeat(),
      ..._accentGhostBeat(),
    ],
  ),
  Rudiment(
    id: 'etude_study_3',
    name: 'Kombi-Studie · Paradiddle + Single Four',
    description:
        'Kurze Phrase aus Single-Paradiddle-Takt und Single-Stroke-Four-Takt '
        'im Wechsel — verbindet zwei Sticking-Konzepte.',
    collection: ExerciseCollection.techniqueStudies,
    collectionGroup: 'Kombinations-Studien',
    difficulty: Difficulty.intermediate,
    minBpm: 70,
    targetBpm: 110,
    gridUnit: NoteGrid.sixteenth,
    beatsPerBar: 4,
    skills: {Skill.coordination, Skill.fill},
    sticking: [
      ..._paradiddleBar(),
      ..._singleFourBar(),
      ..._paradiddleBar(),
      ..._singleFourBar(),
    ],
  ),
  Rudiment(
    id: 'etude_study_4',
    name: 'Kombi-Studie · Flam + Drag + Roll',
    description:
        'Flam-Figur, Drag-Figur und Doppelschlag-Roll werden nacheinander '
        'vorgestellt und im letzten Takt zu einer fließenden Phrase verbunden.',
    collection: ExerciseCollection.techniqueStudies,
    collectionGroup: 'Kombinations-Studien',
    difficulty: Difficulty.advanced,
    minBpm: 80,
    targetBpm: 120,
    gridUnit: NoteGrid.sixteenth,
    beatsPerBar: 4,
    skills: {Skill.coordination, Skill.fill},
    sticking: [
      // Bar 1: flam figure, lead alternates every beat.
      ..._flamTapBeat(R),
      ..._flamTapBeat(L),
      ..._flamTapBeat(R),
      ..._flamTapBeat(L),
      // Bar 2: drag figure, lead alternates every beat.
      ..._dragTapBeat(R),
      ..._dragTapBeat(L),
      ..._dragTapBeat(R),
      ..._dragTapBeat(L),
      // Bar 3: double-stroke roll, 4 beats of RRLL sixteenths.
      ..._rollBeat16(),
      ..._rollBeat16(),
      ..._rollBeat16(),
      ..._rollBeat16(),
      // Bar 4: flowing phrase — flam pickup, drag answer, roll closes it out.
      ..._flamTapBeat(R),
      ..._dragTapBeat(L),
      ..._rollBeat16(),
      ..._rollBeat16(),
    ],
  ),
  Rudiment(
    id: 'etude_study_5',
    name: 'Roll-Studie · Crescendo-Doubles',
    description:
        'Durchgehende Doppelschläge (RRLL), die sich über vier Takte von '
        'Ghost Notes über normale Lautstärke bis zu Akzenten steigern.',
    collection: ExerciseCollection.techniqueStudies,
    collectionGroup: 'Roll- & Endurance-Studien',
    difficulty: Difficulty.intermediate,
    minBpm: 60,
    targetBpm: 100,
    gridUnit: NoteGrid.sixteenth,
    beatsPerBar: 4,
    skills: {Skill.endurance, Skill.control},
    sticking: [
      // Bar 1: all ghosted (pp).
      ..._crescendoRollBeat(ghost: true),
      ..._crescendoRollBeat(ghost: true),
      ..._crescendoRollBeat(ghost: true),
      ..._crescendoRollBeat(ghost: true),
      // Bar 2: normal dynamic (mf).
      ..._crescendoRollBeat(),
      ..._crescendoRollBeat(),
      ..._crescendoRollBeat(),
      ..._crescendoRollBeat(),
      // Bars 3-4: accented (f) — the crescendo's peak, sustained.
      ..._crescendoRollBeat(accent: true),
      ..._crescendoRollBeat(accent: true),
      ..._crescendoRollBeat(accent: true),
      ..._crescendoRollBeat(accent: true),
      ..._crescendoRollBeat(accent: true),
      ..._crescendoRollBeat(accent: true),
      ..._crescendoRollBeat(accent: true),
      ..._crescendoRollBeat(accent: true),
    ],
  ),
  Rudiment(
    id: 'etude_study_6',
    name: 'Endurance-Studie · Dauerlauf',
    description:
        'Vier Takte durchgehende 16tel-Einzelschläge mit Akzent auf jeder '
        'Zählzeit — reine Ausdauerarbeit bis ins Zieltempo.',
    collection: ExerciseCollection.techniqueStudies,
    collectionGroup: 'Roll- & Endurance-Studien',
    difficulty: Difficulty.advanced,
    minBpm: 90,
    targetBpm: 150,
    gridUnit: NoteGrid.sixteenth,
    beatsPerBar: 4,
    skills: {Skill.endurance, Skill.control},
    sticking: [
      // 4 bars = 16 beats of RLRL with a downbeat accent each beat.
      ..._enduranceBeat(),
      ..._enduranceBeat(),
      ..._enduranceBeat(),
      ..._enduranceBeat(),
      ..._enduranceBeat(),
      ..._enduranceBeat(),
      ..._enduranceBeat(),
      ..._enduranceBeat(),
      ..._enduranceBeat(),
      ..._enduranceBeat(),
      ..._enduranceBeat(),
      ..._enduranceBeat(),
      ..._enduranceBeat(),
      ..._enduranceBeat(),
      ..._enduranceBeat(),
      ..._enduranceBeat(),
    ],
  ),
];
