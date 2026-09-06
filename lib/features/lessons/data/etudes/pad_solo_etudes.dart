import '../../models/rudiment.dart';
import '../etude_dsl.dart';

// ── Reusable phrase blocks ───────────────────────────────────────────────
// Each solo is built the way a real short snare solo is written: state a
// clear 2-bar theme, repeat or vary it, contrast it with a second idea, then
// return to the theme for a cadence. Accents always mark the strong beats
// (1 and 3) or the theme's own rhythm — never a random cell. Rests only
// ever fall at the END of a 2-bar phrase (a breath before the next idea),
// never mid-phrase. That's what makes it read as a piece of music instead
// of a pattern grab-bag.

/// One bar of steady quarters, downbeat + beat-3 accented (march feel).
List<StrokeBeat> _quarterBar(Hand lead) {
  final other = lead == R ? L : R;
  return [
    note(lead, NoteValue.quarter, accent: true),
    note(other, NoteValue.quarter),
    note(lead, NoteValue.quarter, accent: true),
    note(other, NoteValue.quarter),
  ];
}

/// One bar of straight eighths, accented on beats 1 and 3.
List<StrokeBeat> _eighthBar(Hand lead) {
  final other = lead == R ? L : R;
  return [
    note(lead, NoteValue.eighth, accent: true), note(other, NoteValue.eighth),
    note(lead, NoteValue.eighth), note(other, NoteValue.eighth),
    note(lead, NoteValue.eighth, accent: true), note(other, NoteValue.eighth),
    note(lead, NoteValue.eighth), note(other, NoteValue.eighth),
  ];
}

/// One bar (4 beats) of straight sixteenths, accent on [accentIndex] of
/// every beat (0 = downbeat feel, 1/2/3 = pushed off the beat).
List<StrokeBeat> _sixteenthBar(Hand lead, int accentIndex) {
  final other = lead == R ? L : R;
  return [
    for (var i = 0; i < 4; i++)
      ...sixteenths([lead, other, lead, other], accents: {accentIndex}),
  ];
}

/// Three quarters + a closing quarter rest — a one-bar "breath" that ends a
/// phrase without breaking the pulse.
List<StrokeBeat> _breathBar(Hand lead) {
  final other = lead == R ? L : R;
  return [
    note(lead, NoteValue.quarter, accent: true),
    note(other, NoteValue.quarter),
    note(lead, NoteValue.quarter),
    rest(NoteValue.quarter),
  ];
}

/// Closing cadence: an eighth-note push into two accented quarters.
List<StrokeBeat> _cadenceBar(Hand lead) {
  final other = lead == R ? L : R;
  return [
    note(lead, NoteValue.eighth), note(other, NoteValue.eighth),
    note(lead, NoteValue.eighth), note(other, NoteValue.eighth),
    note(lead, NoteValue.quarter, accent: true),
    note(other, NoteValue.quarter, accent: true),
  ];
}

/// A one-bar roll fill (continuous doubles) leading into the final accent.
List<StrokeBeat> _rollFillBar(Hand lead) {
  final other = lead == R ? L : R;
  return sixteenths([
    lead, lead, other, other, lead, lead, other, other,
    lead, lead, other, other, lead, lead, other, other,
  ]);
}

final List<Rudiment> padSoloEtudes = <Rudiment>[
  Rudiment(
    id: 'etude_pad_solo_1',
    name: 'Pad-Solo · Antrittsfigur',
    description:
        'Marschartiges Thema in Vierteln/Achteln, kontrastiert mit einer '
        '16tel-Passage, kehrt zum Thema zurück und schließt mit einer '
        'Kadenz — ein Solo mit klarem roten Faden statt loser Figuren.',
    collection: ExerciseCollection.padWorkouts,
    collectionGroup: 'Pad-Solo',
    difficulty: Difficulty.intermediate,
    minBpm: 60,
    targetBpm: 110,
    gridUnit: NoteGrid.sixteenth,
    beatsPerBar: 4,
    skills: {Skill.control, Skill.fill},
    sticking: [
      // A: Thema (2 Takte).
      ..._quarterBar(R), ..._eighthBar(R),
      // A': Thema wiederholt, andere Hand führt.
      ..._quarterBar(L), ..._eighthBar(L),
      // B: Kontrast — 16tel, Akzent auf der Zählzeit, dann leicht verschoben.
      ..._sixteenthBar(R, 0), ..._sixteenthBar(R, 1),
      // A: Thema kehrt zurück, endet mit Atemzug + Kadenz.
      ..._breathBar(R), ..._cadenceBar(R),
    ],
  ),
  Rudiment(
    id: 'etude_pad_solo_2',
    name: 'Pad-Solo · Achtel trifft Sechzehntel',
    description:
        'Eine Achtel-Idee wird von einer schnelleren 16tel-Version '
        'beantwortet, zweimal durchlaufen mit wechselnder Führungshand, '
        'Schluss mit Roll-Fill und Kadenz.',
    collection: ExerciseCollection.padWorkouts,
    collectionGroup: 'Pad-Solo',
    difficulty: Difficulty.intermediate,
    minBpm: 66,
    targetBpm: 116,
    gridUnit: NoteGrid.sixteenth,
    beatsPerBar: 4,
    skills: {Skill.control, Skill.fill, Skill.coordination},
    sticking: [
      // Frage (Achtel) + Antwort (16tel), rechts geführt.
      ..._eighthBar(R), ..._sixteenthBar(R, 0),
      // Dieselbe Frage & Antwort, links geführt (Wiedererkennung + Balance).
      ..._eighthBar(L), ..._sixteenthBar(L, 0),
      // Steigerung: Antwort jetzt off-beat akzentuiert.
      ..._eighthBar(R), ..._sixteenthBar(R, 2),
      // Schluss: Roll-Fill führt in die Kadenz.
      ..._rollFillBar(R), ..._cadenceBar(L),
    ],
  ),
  Rudiment(
    id: 'etude_pad_solo_3',
    name: 'Pad-Solo · Wellenbewegung',
    description:
        'Durchgehendes 16tel-Thema mit wanderndem Akzent (0→1→2→3), das '
        'einmal komplett "wandert" bevor der Atemzug zur Kadenz führt.',
    collection: ExerciseCollection.padWorkouts,
    collectionGroup: 'Pad-Solo',
    difficulty: Difficulty.advanced,
    minBpm: 78,
    targetBpm: 126,
    gridUnit: NoteGrid.sixteenth,
    beatsPerBar: 4,
    skills: {Skill.control, Skill.endurance, Skill.coordination},
    sticking: [
      // Thema: wandernder Akzent, ein voller Durchlauf 0-1-2-3 (2 Takte).
      ..._sixteenthBar(R, 0), ..._sixteenthBar(R, 1),
      // Wiederholung des Wanderns, Führung wechselt für Balance.
      ..._sixteenthBar(L, 2), ..._sixteenthBar(L, 3),
      // Kontrast: ruhigere Achtel-Passage als Erholung vor dem Finale.
      ..._eighthBar(R), ..._eighthBar(L),
      // Schluss: Atemzug, dann Roll-Fill in die Kadenz.
      ..._breathBar(R), ..._rollFillBar(R),
    ],
  ),
  Rudiment(
    id: 'etude_pad_solo_4',
    name: 'Pad-Solo · Groove-Break',
    description:
        'Achtel-Groove-Thema, das von einem markanten Break (Viertelpause + '
        'Roll-Fill) unterbrochen wird, bevor Thema und Kadenz zurückkehren.',
    collection: ExerciseCollection.padWorkouts,
    collectionGroup: 'Pad-Solo',
    difficulty: Difficulty.advanced,
    minBpm: 80,
    targetBpm: 130,
    gridUnit: NoteGrid.sixteenth,
    beatsPerBar: 4,
    skills: {Skill.control, Skill.fill, Skill.coordination},
    sticking: [
      // Thema (2 Takte Achtel-Groove).
      ..._eighthBar(R), ..._eighthBar(R),
      // Der Break: Atemzug, dann Roll-Fill als Ausrufezeichen.
      ..._breathBar(L), ..._rollFillBar(L),
      // Thema kehrt zurück, jetzt links geführt.
      ..._eighthBar(L), ..._eighthBar(L),
      // Finale: 16tel-Steigerung in die Kadenz.
      ..._sixteenthBar(R, 0), ..._cadenceBar(R),
    ],
  ),
  Rudiment(
    id: 'etude_pad_solo_5',
    name: 'Pad-Solo · Aufbau',
    description:
        'Ein Thema, das sich takt-für-takt steigert — von Vierteln über '
        'Achtel zu 16teln — und in einem doppelten Roll-Fill-Finale endet.',
    collection: ExerciseCollection.padWorkouts,
    collectionGroup: 'Pad-Solo',
    difficulty: Difficulty.intermediate,
    minBpm: 64,
    targetBpm: 118,
    gridUnit: NoteGrid.sixteenth,
    beatsPerBar: 4,
    skills: {Skill.control, Skill.endurance},
    sticking: [
      // Aufbau: Viertel → Achtel → Viertel → Achtel (Thema gefestigt).
      ..._quarterBar(R), ..._eighthBar(R),
      ..._quarterBar(L), ..._eighthBar(L),
      // Steigerung: 16tel, Akzent auf der Zählzeit, dann verschoben.
      ..._sixteenthBar(R, 0), ..._sixteenthBar(R, 1),
      // Finale: Roll-Fill, Atemzug, dann Kadenz.
      ..._rollFillBar(R), ..._cadenceBar(L),
    ],
  ),
  Rudiment(
    id: 'etude_pad_solo_6',
    name: 'Pad-Solo · Zuruf & Echo',
    description:
        'Ein Viertel-Zuruf bekommt jedes Mal eine schnellere 16tel-Antwort, '
        'dreimal variiert (Führungshand, Akzentposition), bevor das große '
        'Finale mit zwei Roll-Fills schließt.',
    collection: ExerciseCollection.padWorkouts,
    collectionGroup: 'Pad-Solo',
    difficulty: Difficulty.advanced,
    minBpm: 84,
    targetBpm: 132,
    gridUnit: NoteGrid.sixteenth,
    beatsPerBar: 4,
    skills: {Skill.control, Skill.fill, Skill.coordination, Skill.endurance},
    sticking: [
      // Ruf (Viertel) + Antwort (16tel, Downbeat-Akzent).
      ..._quarterBar(R), ..._sixteenthBar(R, 0),
      // Ruf + Antwort, links geführt, Akzent verschoben.
      ..._quarterBar(L), ..._sixteenthBar(L, 1),
      // Ruf + Antwort, rechts, Akzent weiter verschoben — Spannungsaufbau.
      ..._quarterBar(R), ..._sixteenthBar(R, 2),
      // Finale: zwei Roll-Fills in Folge, letzter mit Kadenz-Feeling.
      ..._rollFillBar(L), ..._cadenceBar(R),
    ],
  ),
];
