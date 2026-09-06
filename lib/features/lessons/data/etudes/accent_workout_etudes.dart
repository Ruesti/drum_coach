import '../../models/rudiment.dart';
import '../etude_dsl.dart';

/// Six groove-flavored pieces instead of abstract "accent walks a beat
/// forward" drills — real single-surface drum vocabulary (funk ghost-note
/// pocket, son clave, rock backbeat, bossa, shuffle, boom-bap) adapted to
/// R/L pad practice, each with its own signature feel developed over the
/// piece (state it, vary it, bring it back) rather than a technical
/// exercise about accent position.

Hand _other(Hand h) => h == R ? L : R;

/// Alternating R/L hand sequence of [n] strokes, starting on [start].
List<Hand> _alt(int n, Hand start) =>
    List.generate(n, (i) => i.isEven ? start : _other(start));

// ── 1. Funk-Pocket ─────────────────────────────────────────────────────────
// Classic funk ghost-note vocabulary: mostly quiet ghost strokes with sharp
// accents on the syncopated "&of2" and "ah of4" pickups — the same pocket
// feel a funk drummer plays on the snare under a groove.
List<StrokeBeat> _funkPocketBar(Hand start, {Set<int> accents = const {0, 6, 8, 14}}) {
  final hands = _alt(16, start);
  return [
    for (var i = 0; i < 16; i++)
      note(hands[i], NoteValue.sixteenth,
          accent: accents.contains(i), ghost: !accents.contains(i)),
  ];
}

// ── 2. Latin-Clave ───────────────────────────────────────────────────────--
// The son clave (3-2): a 2-bar, 5-hit rhythm that's the backbone of Latin
// music. Mostly silence — the hits are what matter, so every stroke here is
// a clear accent, not a ghost.
List<StrokeBeat> _claveBars(Hand start) {
  // 8th-note grid, 8 positions/bar. 3-side onsets: 0, 3, 6. 2-side: 2, 4.
  const onsetsBar1 = {0, 3, 6};
  const onsetsBar2 = {2, 4};
  var hand = start;
  final out = <StrokeBeat>[];
  for (final onsets in [onsetsBar1, onsetsBar2]) {
    for (var i = 0; i < 8; i++) {
      if (onsets.contains(i)) {
        out.add(note(hand, NoteValue.eighth, accent: true));
        hand = _other(hand);
      } else {
        out.add(rest(NoteValue.eighth));
      }
    }
  }
  return out;
}

// ── 3. Halftime-Rock ─────────────────────────────────────────────────────--
// A steady 8th-note pulse with the backbeat (2 and 4) cracked hard — the
// same feel as a rock snare backbeat, just on one voice.
List<StrokeBeat> _rockBackbeatBar(Hand start) {
  final hands = _alt(8, start);
  const backbeat = {2, 6}; // beat 2, beat 4
  return [
    for (var i = 0; i < 8; i++)
      note(hands[i], NoteValue.eighth, accent: backbeat.contains(i)),
  ];
}

// ── 4. Bossa-Groove ──────────────────────────────────────────────────────--
// Lighter than funk — fewer ghosts, a smooth syncopated lean typical of
// bossa nova phrasing (accented pickup into beat 1, and the "&of3").
List<StrokeBeat> _bossaBar(Hand start, {Set<int> accents = const {3, 10}}) {
  final hands = _alt(16, start);
  return [
    for (var i = 0; i < 16; i++)
      note(hands[i], NoteValue.sixteenth, accent: accents.contains(i)),
  ];
}

// ── 5. Shuffle-Swing ─────────────────────────────────────────────────────--
// Triplet-grid shuffle: accenting the first note of every triplet gives the
// long-short "swing" lope instead of a straight, mechanical feel.
List<StrokeBeat> _shuffleBeat(List<Hand> hands) =>
    triplet8(hands, accents: {0});

// ── 6. Boom-Bap ──────────────────────────────────────────────────────────--
// Laid-back hip-hop pocket: sparse strong hits (beat 1, "&of3") over a bed
// of quiet ghosts — spacious rather than busy.
List<StrokeBeat> _boomBapBar(Hand start, {Set<int> accents = const {0, 11}}) {
  final hands = _alt(16, start);
  return [
    for (var i = 0; i < 16; i++)
      note(hands[i], NoteValue.sixteenth,
          accent: accents.contains(i), ghost: !accents.contains(i)),
  ];
}

final List<Rudiment> accentWorkoutEtudes = <Rudiment>[
  Rudiment(
    id: 'etude_pad_groove_funk',
    name: 'Funk-Pocket',
    description:
        'Der klassische Funk-Ghost-Groove: leise Ghost-Notes mit scharfen '
        'Akzenten auf dem "&" von 2 und dem "a" von 4 — die Pocket, die '
        'unter jedem Funk-Beat sitzt.',
    collection: ExerciseCollection.padWorkouts,
    collectionGroup: 'Grooves',
    difficulty: Difficulty.intermediate,
    minBpm: 70,
    targetBpm: 110,
    gridUnit: NoteGrid.sixteenth,
    beatsPerBar: 4,
    skills: {Skill.control, Skill.groove},
    sticking: [
      // Takt 1-4: die Pocket, viermal gefestigt.
      for (var i = 0; i < 4; i++) ..._funkPocketBar(i.isEven ? R : L),
      // Takt 5-6: kleine Variation — der zweite Akzent rutscht eine 16tel weiter.
      ..._funkPocketBar(R, accents: {0, 7, 8, 14}),
      ..._funkPocketBar(L, accents: {0, 7, 8, 14}),
      // Takt 7-8: zurück zur Original-Pocket, sauber ausgespielt.
      ..._funkPocketBar(R),
      ..._funkPocketBar(L),
    ],
  ),
  Rudiment(
    id: 'etude_pad_groove_clave',
    name: 'Latin-Clave',
    description:
        'Der Son-Clave-Rhythmus (3-2) — das rhythmische Rückgrat lateinamerikanischer '
        'Musik, hier auf Hand-zu-Hand-Wechsel übertragen: fünf klare Schläge, '
        'viel Stille dazwischen.',
    collection: ExerciseCollection.padWorkouts,
    collectionGroup: 'Grooves',
    difficulty: Difficulty.intermediate,
    minBpm: 80,
    targetBpm: 130,
    gridUnit: NoteGrid.eighth,
    beatsPerBar: 4,
    skills: {Skill.control, Skill.groove, Skill.coordination},
    sticking: [
      // 4x die 2-Takt-Clave, damit sich die Pocket setzen kann.
      ..._claveBars(R),
      ..._claveBars(R),
      ..._claveBars(L),
      ..._claveBars(L),
    ],
  ),
  Rudiment(
    id: 'etude_pad_groove_rock',
    name: 'Halftime-Rock',
    description:
        'Durchgehende Achtel mit hart gecrackter Backbeat (Zählzeit 2+4) — '
        'derselbe Drive wie eine Rock-Snare, nur auf einer Stimme.',
    collection: ExerciseCollection.padWorkouts,
    collectionGroup: 'Grooves',
    difficulty: Difficulty.beginner,
    minBpm: 80,
    targetBpm: 140,
    gridUnit: NoteGrid.eighth,
    beatsPerBar: 4,
    skills: {Skill.control, Skill.groove},
    sticking: [
      for (var i = 0; i < 8; i++) ..._rockBackbeatBar(i.isEven ? R : L),
    ],
  ),
  Rudiment(
    id: 'etude_pad_groove_bossa',
    name: 'Bossa-Groove',
    description:
        'Leichter, synkopierter Bossa-Nova-Feel — weniger Ghost-Notes als '
        'Funk, dafür ein sanfter Auftakt-Schwung in den Akzenten.',
    collection: ExerciseCollection.padWorkouts,
    collectionGroup: 'Grooves',
    difficulty: Difficulty.intermediate,
    minBpm: 80,
    targetBpm: 130,
    gridUnit: NoteGrid.sixteenth,
    beatsPerBar: 4,
    skills: {Skill.control, Skill.groove},
    sticking: [
      // Takt 1-4: die Bossa-Idee gefestigt.
      for (var i = 0; i < 4; i++) ..._bossaBar(i.isEven ? R : L),
      // Takt 5-6: Variation — Akzente einen Hauch später.
      ..._bossaBar(R, accents: {4, 11}),
      ..._bossaBar(L, accents: {4, 11}),
      // Takt 7-8: zurück zur Original-Idee.
      ..._bossaBar(R),
      ..._bossaBar(L),
    ],
  ),
  Rudiment(
    id: 'etude_pad_groove_shuffle',
    name: 'Shuffle-Swing',
    description:
        'Triolische Achtel mit Akzent auf dem ersten Schlag jeder Triole — '
        'der Long-Short-Schlenker, der einen Shuffle schwingen statt '
        'mechanisch klappern lässt.',
    collection: ExerciseCollection.padWorkouts,
    collectionGroup: 'Grooves',
    difficulty: Difficulty.advanced,
    minBpm: 70,
    targetBpm: 120,
    gridUnit: NoteGrid.triplet,
    beatsPerBar: 4,
    skills: {Skill.control, Skill.groove, Skill.coordination},
    sticking: [
      for (var i = 0; i < 32; i++)
        ..._shuffleBeat(i.isEven ? [R, L, R] : [L, R, L]),
    ],
  ),
  Rudiment(
    id: 'etude_pad_groove_boombap',
    name: 'Boom-Bap',
    description:
        'Entspannter Hip-Hop-Groove: wenige starke Schläge (Zählzeit 1 und '
        'das "&" von 3) über einem Teppich leiser Ghost-Notes — Raum statt '
        'Dichte.',
    collection: ExerciseCollection.padWorkouts,
    collectionGroup: 'Grooves',
    difficulty: Difficulty.advanced,
    minBpm: 60,
    targetBpm: 100,
    gridUnit: NoteGrid.sixteenth,
    beatsPerBar: 4,
    skills: {Skill.control, Skill.groove},
    sticking: [
      // Takt 1-4: die Pocket, gefestigt.
      for (var i = 0; i < 4; i++) ..._boomBapBar(i.isEven ? R : L),
      // Takt 5-6: Variation — ein zusätzlicher Akzent auf der "1" von Takt 2.
      ..._boomBapBar(R, accents: {0, 11}),
      ..._boomBapBar(L, accents: {0, 8, 11}),
      // Takt 7-8: zurück zur Original-Pocket.
      ..._boomBapBar(R),
      ..._boomBapBar(L),
    ],
  ),
];
