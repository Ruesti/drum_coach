import '../../models/rudiment.dart';
import '../etude_dsl.dart';

/// Four original "Pad-Solo" études — short, self-contained 4-bar (4/4) solo
/// pieces that combine quarter, eighth and sixteenth notes with rests into a
/// musical arc, rather than a uniform technical drill. Each piece opens
/// calmer, builds in rhythmic density, includes a dramatic rest ("break"),
/// and resolves with an accented cadence. Nr. 1-2 are intermediate (mostly
/// quarters/eighths with a short sixteenth flourish), Nr. 3-4 are advanced
/// (longer sixteenth passages, a dotted-eighth-sixteenth figure and a
/// hemiola-style accent shift). Sticking stays strictly alternating R/L
/// across all played (non-rest) notes throughout every piece.
final List<Rudiment> padSoloEtudes = <Rudiment>[
  Rudiment(
    id: 'etude_pad_solo_1',
    name: 'Pad-Solo · Nr. 1',
    description:
        'Ruhiges Solo-Stück, das von Vierteln über Achtel zu einer kurzen '
        '16tel-Passage führt und mit einem Break zur Kadenz findet.',
    collection: ExerciseCollection.padWorkouts,
    collectionGroup: 'Pad-Solo',
    difficulty: Difficulty.intermediate,
    minBpm: 60,
    targetBpm: 92,
    gridUnit: NoteGrid.sixteenth,
    beatsPerBar: 4,
    skills: {Skill.control, Skill.fill},
    sticking: [
      // Takt 1: ruhiger Start, vier Viertel, Akzent auf 1.
      // 1.0 + 1.0 + 1.0 + 1.0 = 4.0 ✓
      note(R, NoteValue.quarter, accent: true),
      note(L, NoteValue.quarter),
      note(R, NoteValue.quarter),
      note(L, NoteValue.quarter),

      // Takt 2: Achtel-Bewegung setzt ein, schließt wieder mit Vierteln.
      // (0.5*4) + 1.0 + 1.0 = 2.0 + 1.0 + 1.0 = 4.0 ✓
      note(R, NoteValue.eighth, accent: true),
      note(L, NoteValue.eighth),
      note(R, NoteValue.eighth),
      note(L, NoteValue.eighth),
      note(R, NoteValue.quarter),
      note(L, NoteValue.quarter),

      // Takt 3: Steigerung – 16tel-Flourish, dann Achtel, dann eine Viertel
      // gefolgt von einer Viertelpause als kurzer Atemzug vor dem Break.
      // (0.25*4) + (0.5*2) + 1.0 + 1.0 = 1.0 + 1.0 + 1.0 + 1.0 = 4.0 ✓
      note(R, NoteValue.sixteenth, accent: true),
      note(L, NoteValue.sixteenth),
      note(R, NoteValue.sixteenth),
      note(L, NoteValue.sixteenth),
      note(R, NoteValue.eighth),
      note(L, NoteValue.eighth),
      note(R, NoteValue.quarter),
      rest(NoteValue.quarter),

      // Takt 4: Break (Viertelpause), dann Achtel, 16tel-Lauf und
      // akzentuierte Schluss-Viertel als Kadenz.
      // 1.0 + (0.5*2) + (0.25*4) + 1.0 = 1.0 + 1.0 + 1.0 + 1.0 = 4.0 ✓
      rest(NoteValue.quarter),
      note(L, NoteValue.eighth, accent: true),
      note(R, NoteValue.eighth),
      note(L, NoteValue.sixteenth),
      note(R, NoteValue.sixteenth),
      note(L, NoteValue.sixteenth),
      note(R, NoteValue.sixteenth),
      note(L, NoteValue.quarter, accent: true),
    ],
  ),
  Rudiment(
    id: 'etude_pad_solo_2',
    name: 'Pad-Solo · Nr. 2',
    description:
        'Frage-und-Antwort-Solo mit Achtel-Synkopen, einem 16tel-Aufbau und '
        'einem energischen Schluss nach einer kurzen Generalpause.',
    collection: ExerciseCollection.padWorkouts,
    collectionGroup: 'Pad-Solo',
    difficulty: Difficulty.intermediate,
    minBpm: 66,
    targetBpm: 100,
    gridUnit: NoteGrid.sixteenth,
    beatsPerBar: 4,
    skills: {Skill.control, Skill.fill},
    sticking: [
      // Takt 1: synkopierte Achtel-"Frage" mit Atemzug in der Mitte,
      // schließt mit Viertel + Viertelpause.
      // (0.5*4) + 1.0 + 1.0 = 2.0 + 1.0 + 1.0 = 4.0 ✓
      note(R, NoteValue.eighth, accent: true),
      note(L, NoteValue.eighth),
      rest(NoteValue.eighth),
      note(R, NoteValue.eighth),
      note(L, NoteValue.quarter),
      rest(NoteValue.quarter),

      // Takt 2: 16tel-"Antwort", dann Achtel, kurzer Atemzug, akzentuierte
      // Schluss-Viertel.
      // (0.25*4) + (0.5*2) + 1.0 + 1.0 = 1.0 + 1.0 + 1.0 + 1.0 = 4.0 ✓
      note(R, NoteValue.sixteenth, accent: true),
      note(L, NoteValue.sixteenth),
      note(R, NoteValue.sixteenth),
      note(L, NoteValue.sixteenth),
      note(R, NoteValue.eighth),
      note(L, NoteValue.eighth),
      rest(NoteValue.quarter),
      note(R, NoteValue.quarter, accent: true),

      // Takt 3: Break zu Beginn (zwei Achtelpausen), dann eine ruhigere
      // Achtel-Phrase, die in einer Viertel ausklingt.
      // (0.5*2) + (0.5*4) + 1.0 = 1.0 + 2.0 + 1.0 = 4.0 ✓
      rest(NoteValue.eighth),
      rest(NoteValue.eighth),
      note(L, NoteValue.eighth, accent: true),
      note(R, NoteValue.eighth),
      note(L, NoteValue.eighth),
      note(R, NoteValue.eighth),
      note(L, NoteValue.quarter),

      // Takt 4: großer 16tel-Aufbau über zwei Schläge, kurzer Atemzug,
      // akzentuierte Schluss-Viertel als Kadenz.
      // (0.25*8) + (0.5*2) + 1.0 = 2.0 + 1.0 + 1.0 = 4.0 ✓
      note(R, NoteValue.sixteenth, accent: true),
      note(L, NoteValue.sixteenth),
      note(R, NoteValue.sixteenth),
      note(L, NoteValue.sixteenth),
      note(R, NoteValue.sixteenth, accent: true),
      note(L, NoteValue.sixteenth),
      note(R, NoteValue.sixteenth),
      note(L, NoteValue.sixteenth),
      rest(NoteValue.eighth),
      rest(NoteValue.eighth),
      note(R, NoteValue.quarter, accent: true),
    ],
  ),
  Rudiment(
    id: 'etude_pad_solo_3',
    name: 'Pad-Solo · Nr. 3',
    description:
        'Anspruchsvolles Solo mit durchgehenden 16tel-Läufen, einer '
        'punktierten Achtel-16tel-Figur und einem dramatischen Break in '
        'Takt 3.',
    collection: ExerciseCollection.padWorkouts,
    collectionGroup: 'Pad-Solo',
    difficulty: Difficulty.advanced,
    minBpm: 84,
    targetBpm: 126,
    gridUnit: NoteGrid.sixteenth,
    beatsPerBar: 4,
    skills: {Skill.control, Skill.endurance, Skill.fill},
    sticking: [
      // Takt 1: zwei 16tel-Gruppen, Achtelpaar, dann punktierte Achtel +
      // 16tel-Figur (0.75 + 0.25 = 1 Schlag) zum Taktschluss.
      // (0.25*4) + (0.25*4) + (0.5*2) + (0.75+0.25) = 1.0+1.0+1.0+1.0 = 4.0 ✓
      note(R, NoteValue.sixteenth, accent: true),
      note(L, NoteValue.sixteenth),
      note(R, NoteValue.sixteenth),
      note(L, NoteValue.sixteenth),
      note(R, NoteValue.sixteenth, accent: true),
      note(L, NoteValue.sixteenth),
      note(R, NoteValue.sixteenth),
      note(L, NoteValue.sixteenth),
      note(R, NoteValue.eighth, accent: true),
      note(L, NoteValue.eighth),
      note(R, NoteValue.eighth, dotted: true, accent: true),
      note(L, NoteValue.sixteenth),

      // Takt 2: kurzer Atemzug, dann zwei weitere 16tel-Gruppen und eine
      // akzentuierte Schluss-Viertel.
      // (0.5*2) + (0.25*4) + (0.25*4) + 1.0 = 1.0+1.0+1.0+1.0 = 4.0 ✓
      rest(NoteValue.eighth),
      rest(NoteValue.eighth),
      note(R, NoteValue.sixteenth, accent: true),
      note(L, NoteValue.sixteenth),
      note(R, NoteValue.sixteenth),
      note(L, NoteValue.sixteenth),
      note(R, NoteValue.sixteenth, accent: true),
      note(L, NoteValue.sixteenth),
      note(R, NoteValue.sixteenth),
      note(L, NoteValue.sixteenth),
      note(R, NoteValue.quarter, accent: true),

      // Takt 3: der Break – eine volle Viertelpause zur Spannung, danach
      // eine Achtel-Phrase und ein 16tel-Lauf als Wiedereinstieg.
      // 1.0 + (0.5*4) + (0.25*4) = 1.0 + 2.0 + 1.0 = 4.0 ✓
      rest(NoteValue.quarter),
      note(L, NoteValue.eighth, accent: true),
      note(R, NoteValue.eighth),
      note(L, NoteValue.eighth),
      note(R, NoteValue.eighth),
      note(L, NoteValue.sixteenth, accent: true),
      note(R, NoteValue.sixteenth),
      note(L, NoteValue.sixteenth),
      note(R, NoteValue.sixteenth),

      // Takt 4: zwei 16tel-Gruppen, punktierte Achtel-16tel-Figur, und eine
      // akzentuierte Schluss-Viertel als finale Kadenz.
      // (0.25*4) + (0.25*4) + (0.75+0.25) + 1.0 = 1.0+1.0+1.0+1.0 = 4.0 ✓
      note(L, NoteValue.sixteenth, accent: true),
      note(R, NoteValue.sixteenth),
      note(L, NoteValue.sixteenth),
      note(R, NoteValue.sixteenth),
      note(L, NoteValue.sixteenth, accent: true),
      note(R, NoteValue.sixteenth),
      note(L, NoteValue.sixteenth),
      note(R, NoteValue.sixteenth),
      note(L, NoteValue.eighth, dotted: true, accent: true),
      note(R, NoteValue.sixteenth),
      note(L, NoteValue.quarter, accent: true),
    ],
  ),
  Rudiment(
    id: 'etude_pad_solo_4',
    name: 'Pad-Solo · Nr. 4',
    description:
        'Virtuoses Abschluss-Solo mit synkopiertem Auftakt, wandernden '
        'Akzenten über durchgehenden 16teln (Hemiole-Gefühl) und einer '
        'zweischlägigen Generalpause vor dem finalen Lauf.',
    collection: ExerciseCollection.padWorkouts,
    collectionGroup: 'Pad-Solo',
    difficulty: Difficulty.advanced,
    minBpm: 90,
    targetBpm: 132,
    gridUnit: NoteGrid.sixteenth,
    beatsPerBar: 4,
    skills: {Skill.control, Skill.endurance, Skill.fill, Skill.coordination},
    sticking: [
      // Takt 1: synkopierter 16tel-Auftakt (Pause auf der "1"), Achtelpaar,
      // 16tel-Gruppe, akzentuierte Schluss-Viertel.
      // (0.25*4) + (0.5*2) + (0.25*4) + 1.0 = 1.0+1.0+1.0+1.0 = 4.0 ✓
      rest(NoteValue.sixteenth),
      note(R, NoteValue.sixteenth, accent: true),
      note(L, NoteValue.sixteenth),
      note(R, NoteValue.sixteenth),
      note(L, NoteValue.eighth, accent: true),
      note(R, NoteValue.eighth),
      note(L, NoteValue.sixteenth, accent: true),
      note(R, NoteValue.sixteenth),
      note(L, NoteValue.sixteenth),
      note(R, NoteValue.sixteenth),
      note(L, NoteValue.quarter, accent: true),

      // Takt 2: acht durchgehende 16tel mit wanderndem Akzent alle drei
      // Schläge (Hemiole-Gefühl: Index 0, 3, 6), dann Atemzug und
      // akzentuierte Schluss-Viertel.
      // (0.25*8) + 1.0 + 1.0 = 2.0 + 1.0 + 1.0 = 4.0 ✓
      note(R, NoteValue.sixteenth, accent: true),
      note(L, NoteValue.sixteenth),
      note(R, NoteValue.sixteenth),
      note(L, NoteValue.sixteenth, accent: true),
      note(R, NoteValue.sixteenth),
      note(L, NoteValue.sixteenth),
      note(R, NoteValue.sixteenth, accent: true),
      note(L, NoteValue.sixteenth),
      rest(NoteValue.quarter),
      note(R, NoteValue.quarter, accent: true),

      // Takt 3: der große Break – eine halbe Pause (zwei Schläge Stille),
      // dann eine synkopierte Achtel-Phrase als Wiedereinstieg.
      // 2.0 + (0.5*4) = 2.0 + 2.0 = 4.0 ✓
      rest(NoteValue.half),
      note(L, NoteValue.eighth, accent: true),
      note(R, NoteValue.eighth),
      note(L, NoteValue.eighth),
      note(R, NoteValue.eighth),

      // Takt 4: finaler 16tel-Lauf über zwei Schläge, Achtelpaar, und eine
      // akzentuierte Schluss-Viertel als große Kadenz.
      // (0.25*8) + (0.5*2) + 1.0 = 2.0 + 1.0 + 1.0 = 4.0 ✓
      note(L, NoteValue.sixteenth, accent: true),
      note(R, NoteValue.sixteenth),
      note(L, NoteValue.sixteenth),
      note(R, NoteValue.sixteenth),
      note(L, NoteValue.sixteenth, accent: true),
      note(R, NoteValue.sixteenth),
      note(L, NoteValue.sixteenth),
      note(R, NoteValue.sixteenth),
      note(L, NoteValue.eighth, accent: true),
      note(R, NoteValue.eighth),
      note(L, NoteValue.quarter, accent: true),
    ],
  ),
];
