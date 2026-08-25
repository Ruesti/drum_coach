import '../../models/rudiment.dart';
import '../etude_dsl.dart';

/// Akzent-Workout: fünf eigenständige Pad-Übungen im Stil klassischer
/// "wandernder Akzent"-Studien. Durchgehende 16tel-Einzelschläge (binär) bzw.
/// Achteltriolen (ternär) laufen in RLRL- bzw. RLR/LRL-Handfolge, während ein
/// Akzent an festen oder wandernden Positionen innerhalb der Gruppe sitzt —
/// das trainiert Akzent-Kontrolle bei gleichzeitig unveränderter Handfolge.
///
/// Jede Beat-Gruppe (`sixteenths(...)` bzw. `triplet8(...)`) entspricht genau
/// einer Zählzeit (1.0 quarters); vier Gruppen ergeben bei `beatsPerBar: 4`
/// exakt einen Takt.

// --- Binäre Bausteine (16tel, RLRL) -----------------------------------------

/// Eine Zählzeit 16tel-Einzelschläge (RLRL) mit Akzenten auf den in
/// [accents] genannten Zellen (0-3 innerhalb der Gruppe).
List<StrokeBeat> _binaryBeat(Set<int> accents) =>
    sixteenths([R, L, R, L], accents: accents);

// --- Ternäre Bausteine (Achteltriolen, RLR/LRL) -----------------------------

/// Eine Zählzeit Achteltriolen mit alternierender Handfolge: gerade
/// Zählzeiten (0-basiert) spielen RLR, ungerade LRL — so bleibt die
/// Handfolge über Zählzeit- und Taktgrenzen hinweg durchgehend.
List<StrokeBeat> _ternaryBeat(int beatIndex, Set<int> accents) =>
    triplet8(beatIndex.isEven ? [R, L, R] : [L, R, L], accents: accents);

/// Akzent-Workout: fünf eigene Studien zur Akzent-Kontrolle bei laufender
/// Handfolge — binär (16tel) und ternär (Achteltriolen), mit festem,
/// wiederholtem oder wanderndem Akzent.
final List<Rudiment> accentWorkoutEtudes = <Rudiment>[
  Rudiment(
    id: 'etude_pad_accent_1',
    name: 'Akzent-Workout · Doppel-Akzent binär',
    description:
        'Durchgehende 16tel-Einzelschläge (RLRL); statt nur der Zählzeit '
        'wird zusätzlich die dritte 16tel jeder Gruppe akzentuiert — trainiert '
        'zwei unabhängige Akzent-Impulse pro Zählzeit.',
    collection: ExerciseCollection.padWorkouts,
    collectionGroup: 'Akzent-Workout',
    difficulty: Difficulty.intermediate,
    minBpm: 70,
    targetBpm: 110,
    gridUnit: NoteGrid.sixteenth,
    beatsPerBar: 4,
    skills: {Skill.control, Skill.coordination},
    sticking: [
      // Bar 1: 4 Zählzeiten mit Akzent auf Zelle 0 und Zelle 2.
      ..._binaryBeat({0, 2}),
      ..._binaryBeat({0, 2}),
      ..._binaryBeat({0, 2}),
      ..._binaryBeat({0, 2}),
      // Bar 2: identisch wiederholt.
      ..._binaryBeat({0, 2}),
      ..._binaryBeat({0, 2}),
      ..._binaryBeat({0, 2}),
      ..._binaryBeat({0, 2}),
    ],
  ),
  Rudiment(
    id: 'etude_pad_accent_2',
    name: 'Akzent-Workout · Fester Nachschlag-Akzent',
    description:
        'Durchgehende 16tel-Einzelschläge (RLRL); der Akzent sitzt fest auf '
        'der letzten 16tel jeder Zählzeit (dem "e"-Nachschlag) — trainiert '
        'einen Akzent, der nicht auf der Zählzeit selbst liegt.',
    collection: ExerciseCollection.padWorkouts,
    collectionGroup: 'Akzent-Workout',
    difficulty: Difficulty.intermediate,
    minBpm: 70,
    targetBpm: 110,
    gridUnit: NoteGrid.sixteenth,
    beatsPerBar: 4,
    skills: {Skill.control, Skill.coordination},
    sticking: [
      // Bar 1: 4 Zählzeiten mit Akzent auf Zelle 3.
      ..._binaryBeat({3}),
      ..._binaryBeat({3}),
      ..._binaryBeat({3}),
      ..._binaryBeat({3}),
      // Bar 2: identisch wiederholt.
      ..._binaryBeat({3}),
      ..._binaryBeat({3}),
      ..._binaryBeat({3}),
      ..._binaryBeat({3}),
    ],
  ),
  Rudiment(
    id: 'etude_pad_accent_3',
    name: 'Akzent-Workout · Triolen-Downbeat',
    description:
        'Durchgehende Achteltriolen mit alternierender Handfolge (RLR/LRL); '
        'der erste Schlag jeder Triole wird akzentuiert — überträgt das '
        'Akzent-Kontrolle-Training ins ternäre Feld.',
    collection: ExerciseCollection.padWorkouts,
    collectionGroup: 'Akzent-Workout',
    difficulty: Difficulty.intermediate,
    minBpm: 70,
    targetBpm: 110,
    gridUnit: NoteGrid.triplet,
    beatsPerBar: 4,
    skills: {Skill.control, Skill.coordination},
    sticking: [
      // Bar 1: 4 Zählzeiten, Akzent jeweils auf dem ersten Triolen-Schlag.
      ..._ternaryBeat(0, {0}),
      ..._ternaryBeat(1, {0}),
      ..._ternaryBeat(2, {0}),
      ..._ternaryBeat(3, {0}),
      // Bar 2: identisch fortgesetzt.
      ..._ternaryBeat(4, {0}),
      ..._ternaryBeat(5, {0}),
      ..._ternaryBeat(6, {0}),
      ..._ternaryBeat(7, {0}),
    ],
  ),
  Rudiment(
    id: 'etude_pad_accent_4',
    name: 'Akzent-Workout · Wandernder Triolen-Akzent',
    description:
        'Durchgehende Achteltriolen mit alternierender Handfolge (RLR/LRL); '
        'der Akzent wandert innerhalb der Triole von Schlag 1 über 2 nach 3 '
        'und wieder zurück — anspruchsvolle Akzent-Kontrolle im 3er-Raster.',
    collection: ExerciseCollection.padWorkouts,
    collectionGroup: 'Akzent-Workout',
    difficulty: Difficulty.advanced,
    minBpm: 90,
    targetBpm: 140,
    gridUnit: NoteGrid.triplet,
    beatsPerBar: 4,
    skills: {Skill.control, Skill.coordination},
    sticking: [
      // Bar 1: Akzent wandert 0 -> 1 -> 2 -> 1 (hin und zurück).
      ..._ternaryBeat(0, {0}),
      ..._ternaryBeat(1, {1}),
      ..._ternaryBeat(2, {2}),
      ..._ternaryBeat(3, {1}),
      // Bar 2: derselbe Wanderweg wiederholt.
      ..._ternaryBeat(4, {0}),
      ..._ternaryBeat(5, {1}),
      ..._ternaryBeat(6, {2}),
      ..._ternaryBeat(7, {1}),
    ],
  ),
  Rudiment(
    id: 'etude_pad_accent_5',
    name: 'Akzent-Workout · Binär/Ternär im Vergleich',
    description:
        'Takt 1 durchgehende 16tel mit wanderndem Akzent (binär), Takt 2 '
        'Achteltriolen mit wanderndem Akzent (ternär) — derselbe Wander-Akzent '
        'unmittelbar im Wechsel zwischen 4er- und 3er-Raster gespielt.',
    collection: ExerciseCollection.padWorkouts,
    collectionGroup: 'Akzent-Workout',
    difficulty: Difficulty.advanced,
    minBpm: 90,
    targetBpm: 130,
    gridUnit: NoteGrid.triplet,
    beatsPerBar: 4,
    skills: {Skill.control, Skill.coordination},
    sticking: [
      // Bar 1 (binär): Akzent wandert 0 -> 1 -> 2 -> 3 durch die 16tel-Gruppe.
      ..._binaryBeat({0}),
      ..._binaryBeat({1}),
      ..._binaryBeat({2}),
      ..._binaryBeat({3}),
      // Bar 2 (ternär): Akzent wandert 0 -> 1 -> 2 -> 1 durch die Triole.
      ..._ternaryBeat(4, {0}),
      ..._ternaryBeat(5, {1}),
      ..._ternaryBeat(6, {2}),
      ..._ternaryBeat(7, {1}),
    ],
  ),
];
