import '../../models/rudiment.dart';
import '../etude_dsl.dart';

/// One page-length "Pad-Solo" étude: a single continuous 16-bar (4/4) piece
/// combining quarter, eighth and sixteenth notes with rests into a musical
/// arc — calmer opening, rising rhythmic density, a few dramatic breaks,
/// accented cadences — rather than a uniform technical drill. Inspired by
/// (not copied from) a one-page 16-bar solo PDF the user provided under
/// docs/Übungen/ (see docs/Übungen/README.md), which is itself meant to be
/// played through at several tempos (e.g. 50/90/130 BPM) once it's clean.
/// Sticking stays strictly alternating R/L across all played (non-rest)
/// notes throughout.
final List<Rudiment> padSoloEtudes = <Rudiment>[
  Rudiment(
    id: 'etude_pad_solo_page',
    name: 'Pad-Solo · Seite 1',
    description:
        'Durchgehendes 16-Takte-Solo: von ruhigen Vierteln über Achtel- und '
        '16tel-Passagen, synkopierte Phrasen und mehrere Breaks bis zum '
        'virtuosen Schluss — einmal komplett gespielt, dann in mehreren '
        'Tempi (z.B. 50/90/130 BPM) wiederholen.',
    collection: ExerciseCollection.padWorkouts,
    collectionGroup: 'Pad-Solo',
    difficulty: Difficulty.advanced,
    minBpm: 60,
    targetBpm: 130,
    gridUnit: NoteGrid.sixteenth,
    beatsPerBar: 4,
    skills: {Skill.control, Skill.endurance, Skill.fill, Skill.coordination},
    sticking: [
      // Takt 1: ruhiger Start, vier Viertel, Akzent auf 1.
      note(R, NoteValue.quarter, accent: true),
      note(L, NoteValue.quarter),
      note(R, NoteValue.quarter),
      note(L, NoteValue.quarter),

      // Takt 2: Achtel-Bewegung setzt ein, schließt wieder mit Vierteln.
      note(R, NoteValue.eighth, accent: true),
      note(L, NoteValue.eighth),
      note(R, NoteValue.eighth),
      note(L, NoteValue.eighth),
      note(R, NoteValue.quarter),
      note(L, NoteValue.quarter),

      // Takt 3: Steigerung – 16tel-Flourish, dann Achtel, dann eine Viertel
      // gefolgt von einer Viertelpause als kurzer Atemzug.
      note(R, NoteValue.sixteenth, accent: true),
      note(L, NoteValue.sixteenth),
      note(R, NoteValue.sixteenth),
      note(L, NoteValue.sixteenth),
      note(R, NoteValue.eighth),
      note(L, NoteValue.eighth),
      note(R, NoteValue.quarter),
      rest(NoteValue.quarter),

      // Takt 4: Break (Viertelpause), dann Achtel, 16tel-Lauf und
      // akzentuierte Viertel.
      rest(NoteValue.quarter),
      note(L, NoteValue.eighth, accent: true),
      note(R, NoteValue.eighth),
      note(L, NoteValue.sixteenth),
      note(R, NoteValue.sixteenth),
      note(L, NoteValue.sixteenth),
      note(R, NoteValue.sixteenth),
      note(L, NoteValue.quarter, accent: true),

      // Takt 5: synkopierte Achtel-"Frage" mit Atemzug in der Mitte,
      // schließt mit Viertel + Viertelpause.
      note(R, NoteValue.eighth, accent: true),
      note(L, NoteValue.eighth),
      rest(NoteValue.eighth),
      note(R, NoteValue.eighth),
      note(L, NoteValue.quarter),
      rest(NoteValue.quarter),

      // Takt 6: 16tel-"Antwort", dann Achtel, kurzer Atemzug, akzentuierte
      // Schluss-Viertel.
      note(R, NoteValue.sixteenth, accent: true),
      note(L, NoteValue.sixteenth),
      note(R, NoteValue.sixteenth),
      note(L, NoteValue.sixteenth),
      note(R, NoteValue.eighth),
      note(L, NoteValue.eighth),
      rest(NoteValue.quarter),
      note(R, NoteValue.quarter, accent: true),

      // Takt 7: Break zu Beginn (zwei Achtelpausen), dann eine ruhigere
      // Achtel-Phrase, die in einer Viertel ausklingt.
      rest(NoteValue.eighth),
      rest(NoteValue.eighth),
      note(L, NoteValue.eighth, accent: true),
      note(R, NoteValue.eighth),
      note(L, NoteValue.eighth),
      note(R, NoteValue.eighth),
      note(L, NoteValue.quarter),

      // Takt 8: großer 16tel-Aufbau über zwei Schläge, kurzer Atemzug,
      // akzentuierte Schluss-Viertel als Kadenz zur Mitte des Solos.
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

      // Takt 9: zwei 16tel-Gruppen, Achtelpaar, dann punktierte Achtel +
      // 16tel-Figur zum Taktschluss.
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

      // Takt 10: kurzer Atemzug, dann zwei weitere 16tel-Gruppen und eine
      // akzentuierte Schluss-Viertel.
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

      // Takt 11: der Break – eine volle Viertelpause zur Spannung, danach
      // eine Achtel-Phrase und ein 16tel-Lauf als Wiedereinstieg.
      rest(NoteValue.quarter),
      note(L, NoteValue.eighth, accent: true),
      note(R, NoteValue.eighth),
      note(L, NoteValue.eighth),
      note(R, NoteValue.eighth),
      note(L, NoteValue.sixteenth, accent: true),
      note(R, NoteValue.sixteenth),
      note(L, NoteValue.sixteenth),
      note(R, NoteValue.sixteenth),

      // Takt 12: zwei 16tel-Gruppen, punktierte Achtel-16tel-Figur, und eine
      // akzentuierte Schluss-Viertel als Kadenz.
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

      // Takt 13: synkopierter 16tel-Auftakt (Pause auf der "1"), Achtelpaar,
      // 16tel-Gruppe, akzentuierte Schluss-Viertel.
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

      // Takt 14: acht durchgehende 16tel mit wanderndem Akzent alle drei
      // Schläge (Hemiole-Gefühl), dann Atemzug und akzentuierte Schluss-
      // Viertel.
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

      // Takt 15: der große Break – eine halbe Pause (zwei Schläge Stille),
      // dann eine synkopierte Achtel-Phrase als Wiedereinstieg.
      rest(NoteValue.half),
      note(L, NoteValue.eighth, accent: true),
      note(R, NoteValue.eighth),
      note(L, NoteValue.eighth),
      note(R, NoteValue.eighth),

      // Takt 16: finaler 16tel-Lauf über zwei Schläge, Achtelpaar, und eine
      // akzentuierte Schluss-Viertel als große Schluss-Kadenz.
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
