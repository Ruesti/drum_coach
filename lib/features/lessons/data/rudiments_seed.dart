import '../models/rudiment.dart';

const rudimentsSeedData = <Rudiment>[
  // ─── ROLLS ────────────────────────────────────────────────────────────────

  Rudiment(
    id: 'single_stroke_roll',
    name: 'Single Stroke Roll',
    skills: {Skill.control},
    description:
        'The most fundamental rudiment. Alternate single strokes between hands '
        'as fast and evenly as possible. Focus on equal pressure and rebound.',
    minBpm: 60,
    targetBpm: 200,
    difficulty: Difficulty.beginner,
    sticking: [
      StrokeBeat(hand: Hand.right, isAccent: true),
      StrokeBeat(hand: Hand.left),
      StrokeBeat(hand: Hand.right),
      StrokeBeat(hand: Hand.left),
      StrokeBeat(hand: Hand.right),
      StrokeBeat(hand: Hand.left),
      StrokeBeat(hand: Hand.right),
      StrokeBeat(hand: Hand.left),
    ],
    technique: [
      TechniqueSection(
        title: 'Motion',
        body:
            'Let the stick rebound naturally after impact — no active lifting. '
            'The motion comes from the wrist; keep the arm relaxed. '
            'Both hands should look and sound identical.',
      ),
      TechniqueSection(
        title: 'Common Mistakes',
        body:
            '• Gripping too tightly on the rebound — the stick needs room to move\n'
            '• Uneven volume between right and left\n'
            '• Raising the shoulders at higher tempos',
      ),
      TechniqueSection(
        title: 'Practice Plan',
        body:
            'Start at 60 BPM in eighth notes. Only speed up once both hands '
            'sound like one. Use a metronome and listen for gaps or rushing. '
            'Practice in front of a mirror to compare hand positions.',
      ),
      TechniqueSection(
        title: 'Musical Application',
        body:
            'The foundation for everything — fills, hi-hat patterns, ghost note grooves. '
            'Without a solid single stroke roll, no other rudiment works.',
      ),
    ],
  ),

  Rudiment(
    id: 'double_stroke_roll',
    name: 'Double Stroke Roll',
    skills: {Skill.control},
    description:
        'Two consecutive strokes per hand. The second stroke uses the natural '
        'rebound of the stick. Keep both strokes even in volume and timing.',
    minBpm: 60,
    targetBpm: 180,
    difficulty: Difficulty.beginner,
    sticking: [
      StrokeBeat(hand: Hand.right, isAccent: true),
      StrokeBeat(hand: Hand.right),
      StrokeBeat(hand: Hand.left, isAccent: true),
      StrokeBeat(hand: Hand.left),
      StrokeBeat(hand: Hand.right, isAccent: true),
      StrokeBeat(hand: Hand.right),
      StrokeBeat(hand: Hand.left, isAccent: true),
      StrokeBeat(hand: Hand.left),
    ],
    technique: [
      TechniqueSection(
        title: 'Motion',
        body:
            'First stroke: full stick height, active wrist throw. '
            'Second stroke: controlled rebound — the stick "falls" back. '
            'At slow tempos: two deliberate strokes. At speed: '
            'the rebound takes over the second stroke automatically.',
      ),
      TechniqueSection(
        title: 'Common Mistakes',
        body:
            '• Second stroke quieter than the first\n'
            '• Not enough finger control — the fingers assist the rebound\n'
            '• Strokes evenly spaced instead of close together',
      ),
      TechniqueSection(
        title: 'Practice Plan',
        body:
            'First practice each double stroke extremely slowly as two separate, '
            'deliberate motions. Increase the tempo step by step. '
            'The "click-click" should start to feel like a single "clack".',
      ),
      TechniqueSection(
        title: 'Musical Application',
        body:
            'The core of the buzz roll at top speed. '
            'Double strokes on snare and toms for fills. '
            'Important in Latin rhythms (conga transfers).',
      ),
    ],
  ),

  Rudiment(
    id: 'multiple_bounce_roll',
    name: 'Multiple Bounce Roll',
    skills: {Skill.control},
    description:
        'Also called buzz roll. Press the stick into the drum head to create '
        'multiple uncontrolled bounces per stroke. Creates a sustained roll sound.',
    minBpm: 40,
    targetBpm: 100,
    difficulty: Difficulty.intermediate,
    sticking: [
      StrokeBeat(hand: Hand.right, isGhost: true),
      StrokeBeat(hand: Hand.left, isGhost: true),
      StrokeBeat(hand: Hand.right, isGhost: true),
      StrokeBeat(hand: Hand.left, isGhost: true),
    ],
    technique: [
      TechniqueSection(
        title: 'Motion',
        body:
            'Press the stick lightly into the head — a guided press, not a '
            'clamped grip. The stick bounces multiple times freely. '
            'The pressure controls the density of the bounces. '
            'Alternate hands so that no gap is audible.',
      ),
      TechniqueSection(
        title: 'Common Mistakes',
        body:
            '• Lifting the stick between strokes (audible gaps)\n'
            '• Too much or too little pressure\n'
            '• Uneven hand-to-hand transitions',
      ),
      TechniqueSection(
        title: 'Practice Plan',
        body:
            'First find the right amount of pressure with one hand. '
            'Then practice each hand separately. Only combine them once '
            'each hand produces an even buzz on its own.',
      ),
      TechniqueSection(
        title: 'Musical Application',
        body:
            'Crescendo rolls and fermata strokes. Essential in orchestral '
            'and marching band playing. Gives snare solos dramatic expression.',
      ),
    ],
  ),

  // ─── PARADIDDLES ──────────────────────────────────────────────────────────

  Rudiment(
    id: 'single_paradiddle',
    name: 'Single Paradiddle',
    skills: {Skill.control, Skill.coordination},
    description:
        'RLRR LRLL. One of the most important rudiments. The double stroke at '
        'the end shifts the leading hand on each repetition. Great for fills and grooves.',
    minBpm: 60,
    targetBpm: 120,
    difficulty: Difficulty.beginner,
    sticking: [
      StrokeBeat(hand: Hand.right, isAccent: true),
      StrokeBeat(hand: Hand.left),
      StrokeBeat(hand: Hand.right),
      StrokeBeat(hand: Hand.right),
      StrokeBeat(hand: Hand.left, isAccent: true),
      StrokeBeat(hand: Hand.right),
      StrokeBeat(hand: Hand.left),
      StrokeBeat(hand: Hand.left),
    ],
    technique: [
      TechniqueSection(
        title: 'Motion',
        body:
            'Accent on beat 1 of each group (alternating R and L). '
            'The double strokes at the end of each group (RR / LL) '
            'automatically switch the leading hand on the next pass. '
            'Say the pattern out loud: "Para-did-dle, para-did-dle".',
      ),
      TechniqueSection(
        title: 'Common Mistakes',
        body:
            '• Accenting only with the right hand\n'
            '• Uneven double strokes (second stroke too quiet)\n'
            '• Unstable tempo when the leading hand switches',
      ),
      TechniqueSection(
        title: 'Practice Plan',
        body:
            'First practice only R–L–R–R, then only L–R–L–L. '
            'Then connect the two. Variation: accent the doubles (RL**RR** / LR**LL**) '
            'for a different groove character.',
      ),
      TechniqueSection(
        title: 'Musical Application',
        body:
            'One of the most versatile rudiments. Fills, grooves, solo patterns. '
            'Spread around the kit, every stroke gets a different sound. '
            'One of the 40 PAS rudiments every drummer needs to know.',
      ),
    ],
  ),

  Rudiment(
    id: 'double_paradiddle',
    name: 'Double Paradiddle',
    skills: {Skill.control, Skill.coordination},
    description:
        'RLRLRR LRLRLL. Extends the paradiddle concept with two extra single '
        'strokes. Creates a 12-note phrase that works well over triplet-feel rhythms.',
    minBpm: 50,
    targetBpm: 100,
    difficulty: Difficulty.intermediate,
    sticking: [
      StrokeBeat(hand: Hand.right, isAccent: true),
      StrokeBeat(hand: Hand.left),
      StrokeBeat(hand: Hand.right),
      StrokeBeat(hand: Hand.left),
      StrokeBeat(hand: Hand.right),
      StrokeBeat(hand: Hand.right),
      StrokeBeat(hand: Hand.left, isAccent: true),
      StrokeBeat(hand: Hand.right),
      StrokeBeat(hand: Hand.left),
      StrokeBeat(hand: Hand.right),
      StrokeBeat(hand: Hand.left),
      StrokeBeat(hand: Hand.left),
    ],
    technique: [
      TechniqueSection(
        title: 'Motion',
        body:
            '12 notes per cycle: RLRLRR / LRLRLL. '
            'Four single strokes, then a double stroke. '
            'The accent on note 1 alternates automatically between R and L. '
            'Think: "Para-para-diddle".',
      ),
      TechniqueSection(
        title: 'Common Mistakes',
        body:
            '• Losing track of which hand is leading\n'
            '• Uneven subdivisions\n'
            '• The double stroke breaking the flow of the groove',
      ),
      TechniqueSection(
        title: 'Practice Plan',
        body:
            'Count "1-e-+-a-2-+" to place the 12-note group in a 12/8 feel. '
            'Start extremely slowly with accents, then build the tempo.',
      ),
      TechniqueSection(
        title: 'Musical Application',
        body:
            'Sits naturally over triplet rhythms (12/8, shuffle). '
            'Common in jazz and fusion. Great for fills across three beats.',
      ),
    ],
  ),

  Rudiment(
    id: 'paradiddle_diddle',
    name: 'Paradiddle-Diddle',
    skills: {Skill.control, Skill.coordination},
    description:
        'RLRRLL LRLLRR. A 6-note phrase built from the paradiddle with a trailing '
        'double stroke. Creates a feeling of three over two when played at speed.',
    minBpm: 60,
    targetBpm: 100,
    difficulty: Difficulty.intermediate,
    sticking: [
      StrokeBeat(hand: Hand.right, isAccent: true),
      StrokeBeat(hand: Hand.left),
      StrokeBeat(hand: Hand.right),
      StrokeBeat(hand: Hand.right),
      StrokeBeat(hand: Hand.left),
      StrokeBeat(hand: Hand.left),
      StrokeBeat(hand: Hand.left, isAccent: true),
      StrokeBeat(hand: Hand.right),
      StrokeBeat(hand: Hand.left),
      StrokeBeat(hand: Hand.left),
      StrokeBeat(hand: Hand.right),
      StrokeBeat(hand: Hand.right),
    ],
    technique: [
      TechniqueSection(
        title: 'Motion',
        body:
            '6 notes: R-L-RR-LL. Think: "Para-did-dle-did-dle". '
            'The pattern splits into three groups of two, which creates '
            'a 3-over-2 polyrhythm when repeated.',
      ),
      TechniqueSection(
        title: 'Common Mistakes',
        body:
            '• Double strokes at different volumes\n'
            '• Rushing the second double stroke (LL)\n'
            '• Losing the accent at higher tempos',
      ),
      TechniqueSection(
        title: 'Practice Plan',
        body:
            'Think in groups of six. Practice as triplets (3+3 over 4/4) '
            'to develop the polyrhythmic feel.',
      ),
      TechniqueSection(
        title: 'Musical Application',
        body:
            'Creates a polyrhythmic feel at speed. '
            'Very effective in drum solos and for complex fills.',
      ),
    ],
  ),

  // ─── FLAMS ────────────────────────────────────────────────────────────────

  Rudiment(
    id: 'flam',
    name: 'Flam',
    skills: {Skill.control},
    description:
        'A grace note played just before the main stroke, creating a thicker '
        'sound. The grace note (shown smaller) is barely audible — keep it tight.',
    minBpm: 60,
    targetBpm: 120,
    difficulty: Difficulty.intermediate,
    sticking: [
      // Each flam is one quarter-note stroke with a grace note struck just
      // before it (see StrokeBeat.graces) — not two separate, evenly-spaced
      // beats. 4 quarters = 1 bar, same total length as before.
      StrokeBeat(hand: Hand.right, isAccent: true, value: NoteValue.quarter, graces: [Hand.left]),
      StrokeBeat(hand: Hand.left, isAccent: true, value: NoteValue.quarter, graces: [Hand.right]),
      StrokeBeat(hand: Hand.right, isAccent: true, value: NoteValue.quarter, graces: [Hand.left]),
      StrokeBeat(hand: Hand.left, isAccent: true, value: NoteValue.quarter, graces: [Hand.right]),
    ],
    technique: [
      TechniqueSection(
        title: 'Stick Heights',
        body:
            'Grace note hand: hold the stick 2–3 cm above the head. '
            'Primary stroke hand: stick 20–25 cm high. '
            'Both sticks land almost together — the grace note just before. '
            'After the flam, the hands swap heights.',
      ),
      TechniqueSection(
        title: 'Common Mistakes',
        body:
            '• Grace note too loud — sounds like two separate strokes\n'
            '• Both hands at the same height\n'
            '• Flam too "open" (too much time between grace note and primary stroke)',
      ),
      TechniqueSection(
        title: 'Practice Plan',
        body:
            'Practice extremely slowly. Keep the grace note hand close to the head '
            'and move only the primary stroke hand. '
            'Accept an "open" flam at first and tighten it up gradually.',
      ),
      TechniqueSection(
        title: 'Musical Application',
        body:
            'Adds weight and texture to snare accents. '
            'A classic in rock, rudimental, and marching drumming. '
            'Makes fills more dramatic and "fatter".',
      ),
    ],
  ),

  Rudiment(
    id: 'flam_accent',
    name: 'Flam Accent',
    skills: {Skill.control},
    description:
        'A flam followed by two taps: lR L R / rL R L. Each group of three '
        'starts with a flam accent. Common in rudimental and orchestral drumming.',
    minBpm: 50,
    targetBpm: 100,
    difficulty: Difficulty.intermediate,
    sticking: [
      // Flam as one quarter-note stroke with a grace note, followed by two
      // eighth-note taps — same 2-quarters-per-group length as before.
      StrokeBeat(hand: Hand.right, isAccent: true, value: NoteValue.quarter, graces: [Hand.left]),
      StrokeBeat(hand: Hand.left),
      StrokeBeat(hand: Hand.right),
      StrokeBeat(hand: Hand.left, isAccent: true, value: NoteValue.quarter, graces: [Hand.right]),
      StrokeBeat(hand: Hand.right),
      StrokeBeat(hand: Hand.left),
    ],
    technique: [
      TechniqueSection(
        title: 'Motion',
        body:
            'Each group: a flam (lR or rL) followed by two taps. '
            'The flam is the accent; the two taps stay quiet. '
            'Say: "FLAM-tap-tap, FLAM-tap-tap".',
      ),
      TechniqueSection(
        title: 'Common Mistakes',
        body:
            '• Taps after the flam too loud\n'
            '• Flam not tight enough\n'
            '• Tempo collapsing after the flam',
      ),
      TechniqueSection(
        title: 'Practice Plan',
        body:
            'First practice each group in isolation: flam, tap, tap — rest. '
            'Then connect them. Accent the flam strongly and play the taps very softly.',
      ),
      TechniqueSection(
        title: 'Musical Application',
        body:
            'A classic rudimental pattern. Ideal for snare solos and fills. '
            'Ubiquitous in marching percussion.',
      ),
    ],
  ),

  Rudiment(
    id: 'flam_paradiddle',
    name: 'Flam Paradiddle',
    skills: {Skill.control},
    description:
        'lRLRR / rLRLL. A paradiddle with a flam on the leading stroke. '
        'The grace note adds texture and challenges your stick control significantly.',
    minBpm: 40,
    targetBpm: 90,
    difficulty: Difficulty.advanced,
    sticking: [
      // Flam as one quarter-note stroke with a grace note, followed by the
      // paradiddle's remaining three eighth-note taps — same length as before.
      StrokeBeat(hand: Hand.right, isAccent: true, value: NoteValue.quarter, graces: [Hand.left]),
      StrokeBeat(hand: Hand.left),
      StrokeBeat(hand: Hand.right),
      StrokeBeat(hand: Hand.right),
      StrokeBeat(hand: Hand.left, isAccent: true, value: NoteValue.quarter, graces: [Hand.right]),
      StrokeBeat(hand: Hand.right),
      StrokeBeat(hand: Hand.left),
      StrokeBeat(hand: Hand.left),
    ],
    technique: [
      TechniqueSection(
        title: 'Motion',
        body:
            'A paradiddle with a flam on the first stroke of each group. '
            'lRLRR: grace note left, primary stroke right, then continue L-R-R. '
            'The grace note must stay tight to the flam despite the following strokes.',
      ),
      TechniqueSection(
        title: 'Common Mistakes',
        body:
            '• Grace note getting lost in the rest of the pattern\n'
            '• Unstable tempo after the flam\n'
            '• Losing control of the double stroke at the end',
      ),
      TechniqueSection(
        title: 'Practice Plan',
        body:
            'Master the single paradiddle without the flam first. '
            'Then slowly add the grace note. '
            'Very slow practice (40 BPM) is essential here.',
      ),
      TechniqueSection(
        title: 'Musical Application',
        body:
            'A high level of stick control. Impressive texture for '
            'drum solos and complex fills. Requires solid paradiddle and flam control.',
      ),
    ],
  ),

  // ─── RUFFS / DRAGS ────────────────────────────────────────────────────────

  Rudiment(
    id: 'single_drag',
    name: 'Single Drag',
    skills: {Skill.control},
    description:
        'Two grace notes preceding the main stroke: llR rRL. The drag (two ghost '
        'notes) sounds like a rapid roll before the accent. Keep the drags light.',
    minBpm: 50,
    targetBpm: 100,
    difficulty: Difficulty.intermediate,
    sticking: [
      // A drag is two grace notes struck just before the accented main
      // stroke (see StrokeBeat.graces), not three separate, evenly-spaced
      // beats. Dotted quarter (1.5 quarters) matches the old 3-eighths length.
      StrokeBeat(hand: Hand.right, isAccent: true, value: NoteValue.quarter, dotted: true, graces: [Hand.left, Hand.left]),
      StrokeBeat(hand: Hand.left, isAccent: true, value: NoteValue.quarter, dotted: true, graces: [Hand.right, Hand.right]),
    ],
    technique: [
      TechniqueSection(
        title: 'What Is a Drag?',
        body:
            'A drag is two ghost notes (ll or rr) placed right before '
            'the primary stroke. They sound like a miniature double stroke. '
            'The drag should feel like a single event, not three.',
      ),
      TechniqueSection(
        title: 'Motion',
        body:
            'Play the two ghost notes very tight and soft, almost together. '
            'Then the primary stroke at full volume. '
            'Think: "drr-HIT, drr-HIT", not "l-l-R".',
      ),
      TechniqueSection(
        title: 'Common Mistakes',
        body:
            '• Drag notes too loud or too far apart\n'
            '• Drag sounding like three separate strokes\n'
            '• The drag pushing the primary stroke off time',
      ),
      TechniqueSection(
        title: 'Practice Plan',
        body:
            'First practice only the drag (ll) without the primary stroke. '
            'Then add the primary stroke. The drag should sound "crushed" — '
            'packed tight against the accent.',
      ),
    ],
  ),

  Rudiment(
    id: 'double_drag',
    name: 'Double Drag',
    skills: {Skill.control},
    description:
        'Two drag taps followed by an accent: llR L llR L / rrL R rrL R. '
        'Requires independent control of both hands to execute the drags cleanly.',
    minBpm: 40,
    targetBpm: 80,
    difficulty: Difficulty.advanced,
    sticking: [
      // Drag (two grace notes) + accent as one dotted-quarter stroke,
      // followed by a tap — same 2-quarters-per-group length as before.
      StrokeBeat(hand: Hand.right, isAccent: true, value: NoteValue.quarter, dotted: true, graces: [Hand.left, Hand.left]),
      StrokeBeat(hand: Hand.left),
      StrokeBeat(hand: Hand.right, isAccent: true, value: NoteValue.quarter, dotted: true, graces: [Hand.left, Hand.left]),
      StrokeBeat(hand: Hand.left),
    ],
    technique: [
      TechniqueSection(
        title: 'Structure',
        body:
            'Drag + accent + tap, then repeat: llR L / llR L. '
            'Four strokes per group in total: two ghost notes, one accent, one tap. '
            'The tap after the accent sits at medium volume.',
      ),
      TechniqueSection(
        title: 'Common Mistakes',
        body:
            '• Rushing after the drag\n'
            '• Tap after the accent too loud or too quiet\n'
            '• Drags opening up at higher tempos',
      ),
      TechniqueSection(
        title: 'Practice Plan',
        body:
            'Count in groups of four. The drag takes almost no time — '
            'it gets "squeezed" in right before beat 1. '
            'Practice the drag separately until it locks in automatically.',
      ),
      TechniqueSection(
        title: 'Musical Application',
        body:
            'A complex rudimental pattern. Appears in snare drum etudes '
            'and drum corps music.',
      ),
    ],
  ),

  Rudiment(
    id: 'lesson_25',
    name: 'Lesson 25',
    skills: {Skill.control},
    description:
        'Also called the double drag tap. Two sets of drag taps ending with a '
        'double stroke: llR llR R / rrL rrL L. A classic rudimental pattern.',
    minBpm: 40,
    targetBpm: 80,
    difficulty: Difficulty.advanced,
    sticking: [
      StrokeBeat(hand: Hand.left, isGhost: true),
      StrokeBeat(hand: Hand.left, isGhost: true),
      StrokeBeat(hand: Hand.right, isAccent: true),
      StrokeBeat(hand: Hand.left, isGhost: true),
      StrokeBeat(hand: Hand.left, isGhost: true),
      StrokeBeat(hand: Hand.right, isAccent: true),
      StrokeBeat(hand: Hand.right),
      StrokeBeat(hand: Hand.right, isGhost: true),
      StrokeBeat(hand: Hand.right, isGhost: true),
      StrokeBeat(hand: Hand.left, isAccent: true),
      StrokeBeat(hand: Hand.right, isGhost: true),
      StrokeBeat(hand: Hand.right, isGhost: true),
      StrokeBeat(hand: Hand.left, isAccent: true),
      StrokeBeat(hand: Hand.left),
    ],
    technique: [
      TechniqueSection(
        title: 'Origin',
        body:
            '"Lesson 25" comes from traditional drum corps instruction. '
            'Two drags followed by a double stroke: llR llR R. '
            'The name refers to lesson no. 25 in classic method books.',
      ),
      TechniqueSection(
        title: 'Motion',
        body:
            'First drag + accent, second drag + accent, then the double stroke. '
            'All drags stay tight and soft. The closing double stroke '
            'matches the accents in volume.',
      ),
      TechniqueSection(
        title: 'Common Mistakes',
        body:
            '• Closing double stroke too loud or too quiet\n'
            '• Drags getting wider and louder under pressure\n'
            '• Timing drifting on the second drag',
      ),
      TechniqueSection(
        title: 'Practice Plan',
        body:
            'This pattern takes time. '
            'Start at 40 BPM and only speed up after weeks of practice. '
            'Work on each drag separately until it locks in.',
      ),
    ],
  ),

  // ─── GHOST NOTES ──────────────────────────────────────────────────────────

  Rudiment(
    id: 'ghost_note_groove',
    name: 'Ghost Note Groove',
    skills: {Skill.control},
    description:
        'A groove built around accent and ghost note contrast. The accented '
        'strokes cut through while ghost notes fill the space between beats. '
        'Focus on a dramatic dynamic difference between the two.',
    minBpm: 60,
    targetBpm: 120,
    difficulty: Difficulty.intermediate,
    sticking: [
      StrokeBeat(hand: Hand.right, isAccent: true),
      StrokeBeat(hand: Hand.left, isGhost: true),
      StrokeBeat(hand: Hand.right),
      StrokeBeat(hand: Hand.left, isGhost: true),
      StrokeBeat(hand: Hand.right, isAccent: true),
      StrokeBeat(hand: Hand.left, isGhost: true),
      StrokeBeat(hand: Hand.right, isAccent: true),
      StrokeBeat(hand: Hand.left, isGhost: true),
    ],
    technique: [
      TechniqueSection(
        title: 'The Concept',
        body:
            'Ghost notes are so quiet they are barely audible — '
            'they "feel" the groove rather than define it. '
            'The dynamic difference between accent and ghost note '
            'must be dramatic: accents from 20–25 cm stick height, '
            'ghost notes from 1–2 cm.',
      ),
      TechniqueSection(
        title: 'Motion',
        body:
            'Accent hand: the wrist snaps down from full height. '
            'Ghost note hand: the stick hovers just above the head — '
            'minimal motion, no wrist throw.',
      ),
      TechniqueSection(
        title: 'Common Mistakes',
        body:
            '• Ghost notes too loud — they dominate the groove\n'
            '• Stick height too low on accents\n'
            '• Imprecise ghost note timing',
      ),
      TechniqueSection(
        title: 'Musical Application',
        body:
            'The foundation of funk and R&B drumming. '
            'Ghost notes give the groove depth and "feel". '
            'Think Steve Gadd, Vinnie Colaiuta, Questlove.',
      ),
    ],
  ),

  Rudiment(
    id: 'dynamics_control',
    name: 'Dynamics Control',
    skills: {Skill.control},
    description:
        'Systematic practice of forte and piano strokes in alternation. '
        'The goal is a clean, consistent contrast — not just louder and quieter, '
        'but a completely different stroke height and feel.',
    minBpm: 40,
    targetBpm: 80,
    difficulty: Difficulty.beginner,
    sticking: [
      StrokeBeat(hand: Hand.right, isAccent: true),
      StrokeBeat(hand: Hand.left, isGhost: true),
      StrokeBeat(hand: Hand.right, isAccent: true),
      StrokeBeat(hand: Hand.left, isGhost: true),
      StrokeBeat(hand: Hand.left, isAccent: true),
      StrokeBeat(hand: Hand.right, isGhost: true),
      StrokeBeat(hand: Hand.left, isAccent: true),
      StrokeBeat(hand: Hand.right, isGhost: true),
    ],
    technique: [
      TechniqueSection(
        title: 'Core Principle',
        body:
            'Volume comes from stick height, not from force. '
            'Forte = high stick (20–25 cm), relaxed wrist, '
            'fast throw. Piano = low stick (2–3 cm), '
            'controlled, small motion.',
      ),
      TechniqueSection(
        title: 'Common Mistakes',
        body:
            '• Controlling volume with grip pressure (wrong!)\n'
            '• Forte strokes too tense\n'
            '• Piano strokes shaky or uneven',
      ),
      TechniqueSection(
        title: 'Practice Plan',
        body:
            'Practice both stroke types separately until each height is consistent. '
            'Then alternate between them. Recording yourself and listening back '
            'helps enormously in judging the dynamic contrast objectively.',
      ),
      TechniqueSection(
        title: 'Why It Matters',
        body:
            'Dynamic control is musicality. If you can control volume, '
            'you can serve any style — from quiet jazz to hard rock. '
            'It is the most fundamental means of expression on the drums.',
      ),
    ],
  ),

  // ─── LINEAR PATTERNS ──────────────────────────────────────────────────────

  Rudiment(
    id: 'linear_beat_1',
    name: 'Linear Beat 1',
    skills: {Skill.coordination, Skill.fill},
    description:
        'A linear pattern where only one hand plays at a time. No simultaneous '
        'strokes. Builds independence and creates a flowing, open texture. '
        'Common in funk and fusion drumming.',
    minBpm: 60,
    targetBpm: 120,
    difficulty: Difficulty.intermediate,
    sticking: [
      StrokeBeat(hand: Hand.right, isAccent: true),
      StrokeBeat(hand: Hand.left),
      StrokeBeat(hand: Hand.right),
      StrokeBeat(hand: Hand.left, isGhost: true),
      StrokeBeat(hand: Hand.right, isAccent: true),
      StrokeBeat(hand: Hand.right),
      StrokeBeat(hand: Hand.left),
      StrokeBeat(hand: Hand.right),
      StrokeBeat(hand: Hand.left, isGhost: true),
      StrokeBeat(hand: Hand.left),
    ],
    technique: [
      TechniqueSection(
        title: 'What Does Linear Mean?',
        body:
            'Linear means only one hand strikes at a time. '
            'No unison hits. The hands fill each other\'s gaps, '
            'creating a flowing, even stream of notes.',
      ),
      TechniqueSection(
        title: 'Motion',
        body:
            'Accents from 20 cm, taps from 10 cm, ghost notes from 2 cm. '
            'The different heights within the pattern give it '
            'depth and groove. No two strokes are alike.',
      ),
      TechniqueSection(
        title: 'Common Mistakes',
        body:
            '• Hesitating between notes — the pattern must flow\n'
            '• Every note at the same volume\n'
            '• Tempo breaking on R-to-R or L-to-L transitions',
      ),
      TechniqueSection(
        title: 'Practice Plan',
        body:
            'Start at 50 BPM and play the pattern until it feels automatic. '
            'Then speed up. To move it onto the drum set, '
            'assign each hand to a different instrument.',
      ),
    ],
  ),

  Rudiment(
    id: 'linear_beat_2',
    name: 'Linear Beat 2',
    skills: {Skill.coordination, Skill.fill},
    description:
        'A second linear combination exploring a different grouping. '
        'Practice slowly to internalize the pattern before building speed. '
        'Ghost notes add texture without disturbing the groove.',
    minBpm: 60,
    targetBpm: 100,
    difficulty: Difficulty.intermediate,
    sticking: [
      StrokeBeat(hand: Hand.right, isAccent: true),
      StrokeBeat(hand: Hand.left, isGhost: true),
      StrokeBeat(hand: Hand.right),
      StrokeBeat(hand: Hand.right),
      StrokeBeat(hand: Hand.left, isAccent: true),
      StrokeBeat(hand: Hand.right, isGhost: true),
      StrokeBeat(hand: Hand.left),
      StrokeBeat(hand: Hand.left),
      StrokeBeat(hand: Hand.right, isAccent: true),
      StrokeBeat(hand: Hand.left, isGhost: true),
    ],
    technique: [
      TechniqueSection(
        title: 'Structure',
        body:
            'A different grouping than Linear Beat 1. '
            'Same-hand doubles (RR, LL) are allowed — '
            'that sets it apart from a purely alternating linear pattern. '
            'Accents on positions 1, 5, and 9 create a 10-note phrase.',
      ),
      TechniqueSection(
        title: 'Common Mistakes',
        body:
            '• Doubles (RR, LL) too loud or uneven\n'
            '• Losing the accent pattern\n'
            '• Ghost notes missing or too loud',
      ),
      TechniqueSection(
        title: 'Practice Plan',
        body:
            'Learn the accent pattern on its own first. '
            'Then add the ghost notes and taps. '
            'Count the 10-note group deliberately to find your entry point '
            'when looping.',
      ),
      TechniqueSection(
        title: 'Musical Application',
        body:
            'Funk and fusion grooves. Creates complexity without heaviness. '
            'Sources of inspiration: Tony Williams, Vinnie Colaiuta.',
      ),
    ],
  ),

  // ─── ÜBUNGEN ──────────────────────────────────────────────────────────────

  Rudiment(
    id: 'akzent_alle_viertel',
    name: 'Accents on Every Quarter Note',
    skills: {Skill.control},
    description:
        'Every stroke is accented. Train equal volume and rebound in both '
        'hands. Ideal as a warm-up.',
    minBpm: 50,
    targetBpm: 160,
    difficulty: Difficulty.beginner,
    sticking: [
      StrokeBeat(hand: Hand.right, isAccent: true),
      StrokeBeat(hand: Hand.left, isAccent: true),
      StrokeBeat(hand: Hand.right, isAccent: true),
      StrokeBeat(hand: Hand.left, isAccent: true),
    ],
    technique: [
      TechniqueSection(
        title: 'Goal',
        body:
            'Both hands should sound identical. Listen for volume differences '
            'between right and left and actively even them out.',
      ),
      TechniqueSection(
        title: 'Practice Plan',
        body:
            'Start at 50–60 BPM. Only speed up once both hands truly '
            'sound the same. Practice with your eyes closed too.',
      ),
    ],
  ),

  Rudiment(
    id: 'akzent_zwei_vier',
    name: 'Accents on 2 and 4',
    skills: {Skill.control},
    description:
        'Backbeat training: accent the strokes on beats 2 and 4 while '
        '1 and 3 stay quiet. The foundation for snare backbeats.',
    minBpm: 50,
    targetBpm: 160,
    difficulty: Difficulty.beginner,
    sticking: [
      StrokeBeat(hand: Hand.right),
      StrokeBeat(hand: Hand.left, isAccent: true),
      StrokeBeat(hand: Hand.right),
      StrokeBeat(hand: Hand.left, isAccent: true),
    ],
    technique: [
      TechniqueSection(
        title: 'Goal',
        body:
            'Internalize the backbeat. The accent on 2 and 4 must land '
            'automatically, without thinking. It is the basis of every rock and pop groove.',
      ),
      TechniqueSection(
        title: 'Practice Plan',
        body:
            'Count "1-2-3-4" out loud while you play. Feel the pulse on '
            '2 and 4. Many drum students train this daily.',
      ),
    ],
  ),

  Rudiment(
    id: 'akzent_wandernd',
    name: 'Moving Accent',
    skills: {Skill.control},
    description:
        'The accent moves stroke by stroke through all eight positions. '
        'Encourages thinking in grooves and phrasing.',
    minBpm: 50,
    targetBpm: 130,
    difficulty: Difficulty.intermediate,
    sticking: [
      StrokeBeat(hand: Hand.right, isAccent: true),
      StrokeBeat(hand: Hand.left),
      StrokeBeat(hand: Hand.right),
      StrokeBeat(hand: Hand.left),
      StrokeBeat(hand: Hand.right),
      StrokeBeat(hand: Hand.left),
      StrokeBeat(hand: Hand.right),
      StrokeBeat(hand: Hand.left),
    ],
    technique: [
      TechniqueSection(
        title: 'Goal',
        body:
            'Practice the same pattern with the accent on 1, then on 2, then on 3, and so on. '
            'Each position feels different — that builds flexibility.',
      ),
      TechniqueSection(
        title: 'Practice Plan',
        body:
            'Play 4 bars with the accent on position 1, then 4 bars on position 2, '
            'and so on, without stopping. Keep the metronome running throughout.',
      ),
    ],
  ),

  Rudiment(
    id: 'ghostnote_training',
    name: 'Ghost Note Training',
    skills: {Skill.control},
    description:
        'Alternate between loud accented strokes and very soft ghost notes. '
        'Dynamic control is the core goal.',
    minBpm: 50,
    targetBpm: 140,
    difficulty: Difficulty.intermediate,
    sticking: [
      StrokeBeat(hand: Hand.right, isAccent: true),
      StrokeBeat(hand: Hand.left, isGhost: true),
      StrokeBeat(hand: Hand.right, isGhost: true),
      StrokeBeat(hand: Hand.left, isAccent: true),
      StrokeBeat(hand: Hand.right, isGhost: true),
      StrokeBeat(hand: Hand.left, isGhost: true),
      StrokeBeat(hand: Hand.right, isAccent: true),
      StrokeBeat(hand: Hand.left, isGhost: true),
    ],
    technique: [
      TechniqueSection(
        title: 'Motion',
        body:
            'Accents: stick high, full wrist stroke. Ghost notes: stick stays '
            'close to the head, about 2–3 cm high. The contrast makes the groove.',
      ),
      TechniqueSection(
        title: 'Common Mistakes',
        body:
            '• Ghost notes too loud (uncontrolled rebound)\n'
            '• Accents too quiet (afraid of losing the rhythm)\n'
            '• Tempo wavering on transitions between ghost and accent',
      ),
      TechniqueSection(
        title: 'Practice Plan',
        body:
            'Practice only the accents first, then only the ghost notes. Then combine. '
            'Goal: the listener should hear only the accents clearly and feel the '
            'ghost notes in the background.',
      ),
    ],
  ),

  Rudiment(
    id: 'paradiddle_diddle_corps',
    name: 'Paradiddle-Diddle',
    skills: {Skill.control},
    description:
        'An extension of the paradiddle: RLRRLL LRLLRR. Six notes per group — '
        'ideal for triplets and 6/8 applications.',
    minBpm: 50,
    targetBpm: 150,
    difficulty: Difficulty.intermediate,
    sticking: [
      StrokeBeat(hand: Hand.right, isAccent: true),
      StrokeBeat(hand: Hand.left),
      StrokeBeat(hand: Hand.right),
      StrokeBeat(hand: Hand.right),
      StrokeBeat(hand: Hand.left),
      StrokeBeat(hand: Hand.left),
      StrokeBeat(hand: Hand.left, isAccent: true),
      StrokeBeat(hand: Hand.right),
      StrokeBeat(hand: Hand.left),
      StrokeBeat(hand: Hand.left),
      StrokeBeat(hand: Hand.right),
      StrokeBeat(hand: Hand.right),
    ],
    technique: [
      TechniqueSection(
        title: 'Motion',
        body:
            'The doubles at the end (RRLL) use rebound. The first stroke of each '
            'double is active; the second "falls" back.',
      ),
      TechniqueSection(
        title: 'Musical Application',
        body:
            'Perfect for triplet fills. Spread across three toms, RLRRLL '
            'becomes an ascending phrase. Popular in fusion and Latin.',
      ),
    ],
  ),

  Rudiment(
    id: 'six_stroke_roll',
    name: 'Six Stroke Roll',
    skills: {Skill.control},
    description:
        'RLLRRL — six strokes with two doubles in the middle. '
        'Combines single and double strokes into one flowing pattern.',
    minBpm: 50,
    targetBpm: 160,
    difficulty: Difficulty.intermediate,
    sticking: [
      StrokeBeat(hand: Hand.right, isAccent: true),
      StrokeBeat(hand: Hand.left),
      StrokeBeat(hand: Hand.left),
      StrokeBeat(hand: Hand.right),
      StrokeBeat(hand: Hand.right),
      StrokeBeat(hand: Hand.left, isAccent: true),
    ],
    technique: [
      TechniqueSection(
        title: 'Motion',
        body:
            'The first and last strokes are accents with a full throw. '
            'The four middle strokes (LLRR) use rebound and stay quieter.',
      ),
      TechniqueSection(
        title: 'Practice Plan',
        body:
            'Start slowly: accent — double — double — accent. '
            'Then raise the tempo until the transitions feel seamless.',
      ),
    ],
  ),

  Rudiment(
    id: 'gleichmaessigkeit_16tel',
    name: 'Evenness — Sixteenth Notes',
    skills: {Skill.control},
    description:
        'Sixteenth notes in strict alternation, no accents. '
        'Pure control and endurance training for both hands.',
    minBpm: 60,
    targetBpm: 200,
    difficulty: Difficulty.beginner,
    sticking: [
      StrokeBeat(hand: Hand.right),
      StrokeBeat(hand: Hand.left),
      StrokeBeat(hand: Hand.right),
      StrokeBeat(hand: Hand.left),
      StrokeBeat(hand: Hand.right),
      StrokeBeat(hand: Hand.left),
      StrokeBeat(hand: Hand.right),
      StrokeBeat(hand: Hand.left),
      StrokeBeat(hand: Hand.right),
      StrokeBeat(hand: Hand.left),
      StrokeBeat(hand: Hand.right),
      StrokeBeat(hand: Hand.left),
      StrokeBeat(hand: Hand.right),
      StrokeBeat(hand: Hand.left),
      StrokeBeat(hand: Hand.right),
      StrokeBeat(hand: Hand.left),
    ],
    technique: [
      TechniqueSection(
        title: 'Goal',
        body:
            'Perfect timing evenness. Place the metronome click exactly halfway '
            'between two strokes. Listen for gaps or rushing.',
      ),
      TechniqueSection(
        title: 'Practice Plan',
        body:
            'Record yourself with your phone and listen back. Practice stretches of '
            '2–5 minutes without stopping. Endurance is the goal.',
      ),
    ],
  ),

  Rudiment(
    id: 'moeller_motion',
    name: 'Moeller Motion',
    skills: {Skill.control},
    description:
        'A whipping arm motion for efficient energy flow. Produces several '
        'strokes from one arm movement: accent — tap — tap.',
    minBpm: 40,
    targetBpm: 120,
    difficulty: Difficulty.advanced,
    sticking: [
      StrokeBeat(hand: Hand.right, isAccent: true),
      StrokeBeat(hand: Hand.right, isGhost: true),
      StrokeBeat(hand: Hand.right, isGhost: true),
      StrokeBeat(hand: Hand.left, isAccent: true),
      StrokeBeat(hand: Hand.left, isGhost: true),
      StrokeBeat(hand: Hand.left, isGhost: true),
    ],
    technique: [
      TechniqueSection(
        title: 'Motion',
        body:
            'The arm rises for the accent (down stroke). As the arm falls, it '
            'automatically produces two more quiet strokes (tap + up). '
            'No muscle power — gravity and rebound do the work.',
      ),
      TechniqueSection(
        title: 'Common Mistakes',
        body:
            '• Actively lifting the arm instead of letting it fall\n'
            '• Taps too loud (no contrast with the accent volume)\n'
            '• Starting too fast — slow is harder here',
      ),
      TechniqueSection(
        title: 'Practice Plan',
        body:
            'Start extremely slowly (40 BPM). Only raise the tempo once the '
            'motion feels like it happens "by itself". Five minutes daily.',
      ),
    ],
  ),

  Rudiment(
    id: 'doppelschlag_basis',
    name: 'Double Strokes (Basics)',
    skills: {Skill.control},
    description:
        'RRLL at an easy tempo. The foundation of all stick control: two '
        'controlled strokes per hand, the second from the rebound.',
    minBpm: 50,
    targetBpm: 140,
    difficulty: Difficulty.beginner,
    sticking: [
      StrokeBeat(hand: Hand.right, isAccent: true),
      StrokeBeat(hand: Hand.right),
      StrokeBeat(hand: Hand.left, isAccent: true),
      StrokeBeat(hand: Hand.left),
      StrokeBeat(hand: Hand.right, isAccent: true),
      StrokeBeat(hand: Hand.right),
      StrokeBeat(hand: Hand.left, isAccent: true),
      StrokeBeat(hand: Hand.left),
    ],
    technique: [
      TechniqueSection(
        title: 'Motion',
        body:
            'The first stroke of each hand is active from the wrist; the second '
            '"falls" out of the rebound. Both should sound equally loud.',
      ),
      TechniqueSection(
        title: 'Practice Plan',
        body:
            'Start slowly (50 BPM) and focus on a clean second stroke. '
            'Only speed up once both strokes sound even.',
      ),
    ],
  ),

  Rudiment(
    id: 'speed_singles_basis',
    name: 'Single Stroke Speed (Basics)',
    skills: {Skill.control},
    description:
        'Even sixteenth-note single strokes for gradual speed building. '
        'Stay loose — speed comes from relaxation, not from force.',
    minBpm: 60,
    targetBpm: 200,
    difficulty: Difficulty.beginner,
    gridUnit: NoteGrid.sixteenth,
    sticking: [
      StrokeBeat(hand: Hand.right),
      StrokeBeat(hand: Hand.left),
      StrokeBeat(hand: Hand.right),
      StrokeBeat(hand: Hand.left),
      StrokeBeat(hand: Hand.right),
      StrokeBeat(hand: Hand.left),
      StrokeBeat(hand: Hand.right),
      StrokeBeat(hand: Hand.left),
      StrokeBeat(hand: Hand.right),
      StrokeBeat(hand: Hand.left),
      StrokeBeat(hand: Hand.right),
      StrokeBeat(hand: Hand.left),
      StrokeBeat(hand: Hand.right),
      StrokeBeat(hand: Hand.left),
      StrokeBeat(hand: Hand.right),
      StrokeBeat(hand: Hand.left),
    ],
    technique: [
      TechniqueSection(
        title: 'Goal',
        body:
            'Find the highest tempo at which you still play relaxed and even. '
            'As soon as you tense up, take a step back.',
      ),
      TechniqueSection(
        title: 'Practice Plan',
        body:
            'Increase in 5 BPM steps. Hold each step for one minute. Write '
            'down your current top tempo and compare over the weeks.',
      ),
    ],
  ),

  Rudiment(
    id: 'speed_bursts',
    name: 'Speed Bursts',
    skills: {Skill.control},
    description:
        'Four fast sixteenths, then a rest. Trains short bursts of speed '
        'with relaxation in between.',
    minBpm: 70,
    targetBpm: 180,
    difficulty: Difficulty.intermediate,
    gridUnit: NoteGrid.sixteenth,
    sticking: [
      StrokeBeat(hand: Hand.right, isAccent: true),
      StrokeBeat(hand: Hand.left),
      StrokeBeat(hand: Hand.right),
      StrokeBeat(hand: Hand.left),
      StrokeBeat.rest(),
      StrokeBeat.rest(),
      StrokeBeat.rest(),
      StrokeBeat.rest(),
    ],
    technique: [
      TechniqueSection(
        title: 'Motion',
        body:
            'Let the burst explode while staying deliberately loose, then relax '
            'completely during the rest. The rest is part of the exercise.',
      ),
      TechniqueSection(
        title: 'Common Mistakes',
        body:
            '• Staying tense during the rest\n'
            '• Rushing the burst and playing it unevenly',
      ),
    ],
  ),

  Rudiment(
    id: 'speed_doubles',
    name: 'Double Stroke Speed',
    skills: {Skill.control},
    description:
        'Fast double strokes (RRLL) as sixteenths. Speed is built on '
        'clean rebound — not on force.',
    minBpm: 60,
    targetBpm: 170,
    difficulty: Difficulty.advanced,
    gridUnit: NoteGrid.sixteenth,
    sticking: [
      StrokeBeat(hand: Hand.right, isAccent: true),
      StrokeBeat(hand: Hand.right),
      StrokeBeat(hand: Hand.left, isAccent: true),
      StrokeBeat(hand: Hand.left),
      StrokeBeat(hand: Hand.right, isAccent: true),
      StrokeBeat(hand: Hand.right),
      StrokeBeat(hand: Hand.left, isAccent: true),
      StrokeBeat(hand: Hand.left),
      StrokeBeat(hand: Hand.right, isAccent: true),
      StrokeBeat(hand: Hand.right),
      StrokeBeat(hand: Hand.left, isAccent: true),
      StrokeBeat(hand: Hand.left),
      StrokeBeat(hand: Hand.right, isAccent: true),
      StrokeBeat(hand: Hand.right),
      StrokeBeat(hand: Hand.left, isAccent: true),
      StrokeBeat(hand: Hand.left),
    ],
    technique: [
      TechniqueSection(
        title: 'Motion',
        body:
            'At high tempos the second stroke comes almost entirely from the '
            'rebound. Use finger pressure instead of arm strength.',
      ),
      TechniqueSection(
        title: 'Practice Plan',
        body:
            'Start slowly with equally loud strokes. Only raise the tempo if '
            'the second stroke does not drop in volume.',
      ),
    ],
  ),

  Rudiment(
    id: 'ausdauer_dauerlauf',
    name: 'Sixteenth-Note Marathon',
    skills: {Skill.endurance},
    description:
        'Continuous sixteenths for several minutes without a break. '
        'Builds stamina and consistent sound quality.',
    minBpm: 70,
    targetBpm: 150,
    difficulty: Difficulty.beginner,
    gridUnit: NoteGrid.sixteenth,
    sticking: [
      StrokeBeat(hand: Hand.right),
      StrokeBeat(hand: Hand.left),
      StrokeBeat(hand: Hand.right),
      StrokeBeat(hand: Hand.left),
      StrokeBeat(hand: Hand.right),
      StrokeBeat(hand: Hand.left),
      StrokeBeat(hand: Hand.right),
      StrokeBeat(hand: Hand.left),
      StrokeBeat(hand: Hand.right),
      StrokeBeat(hand: Hand.left),
      StrokeBeat(hand: Hand.right),
      StrokeBeat(hand: Hand.left),
      StrokeBeat(hand: Hand.right),
      StrokeBeat(hand: Hand.left),
      StrokeBeat(hand: Hand.right),
      StrokeBeat(hand: Hand.left),
    ],
    technique: [
      TechniqueSection(
        title: 'Goal',
        body:
            'Stay equally loud and even for the entire duration. '
            'Notice the moment your hands start to tire.',
      ),
      TechniqueSection(
        title: 'Practice Plan',
        body:
            'Start with 2 minutes and extend weekly. When quality drops, '
            'consciously relax instead of stopping.',
      ),
    ],
  ),

  Rudiment(
    id: 'ausdauer_doubles',
    name: 'Double Stroke Endurance',
    skills: {Skill.endurance},
    description:
        'Continuous double strokes (RRLL) to build forearm and finger '
        'endurance while keeping the sound consistent.',
    minBpm: 60,
    targetBpm: 140,
    difficulty: Difficulty.intermediate,
    gridUnit: NoteGrid.sixteenth,
    sticking: [
      StrokeBeat(hand: Hand.right),
      StrokeBeat(hand: Hand.right),
      StrokeBeat(hand: Hand.left),
      StrokeBeat(hand: Hand.left),
      StrokeBeat(hand: Hand.right),
      StrokeBeat(hand: Hand.right),
      StrokeBeat(hand: Hand.left),
      StrokeBeat(hand: Hand.left),
      StrokeBeat(hand: Hand.right),
      StrokeBeat(hand: Hand.right),
      StrokeBeat(hand: Hand.left),
      StrokeBeat(hand: Hand.left),
      StrokeBeat(hand: Hand.right),
      StrokeBeat(hand: Hand.right),
      StrokeBeat(hand: Hand.left),
      StrokeBeat(hand: Hand.left),
    ],
    technique: [
      TechniqueSection(
        title: 'Common Mistakes',
        body:
            '• The second stroke getting quieter as fatigue sets in\n'
            '• Tensing up in the forearm — keep the shoulders loose',
      ),
      TechniqueSection(
        title: 'Practice Plan',
        body:
            'A moderate 2–3 minutes at a time. Better clean and short than long '
            'and uneven.',
      ),
    ],
  ),

  Rudiment(
    id: 'akzent_offbeat',
    name: 'Offbeat Accents',
    skills: {Skill.control},
    description:
        'Eighth notes with the accent on the "and" (offbeat). Trains your feel '
        'for syncopation and against-the-pulse phrasing.',
    minBpm: 50,
    targetBpm: 150,
    difficulty: Difficulty.intermediate,
    sticking: [
      StrokeBeat(hand: Hand.right),
      StrokeBeat(hand: Hand.left, isAccent: true),
      StrokeBeat(hand: Hand.right),
      StrokeBeat(hand: Hand.left, isAccent: true),
      StrokeBeat(hand: Hand.right),
      StrokeBeat(hand: Hand.left, isAccent: true),
      StrokeBeat(hand: Hand.right),
      StrokeBeat(hand: Hand.left, isAccent: true),
    ],
    technique: [
      TechniqueSection(
        title: 'Goal',
        body:
            'The accent falls between the beats (the "and"). Count "1-and-2-and" '
            'and consistently stress the "and".',
      ),
      TechniqueSection(
        title: 'Practice Plan',
        body:
            'Count out loud first, then only in your head. The offbeat feel is '
            'the foundation of funk and reggae phrasing.',
      ),
    ],
  ),

  Rudiment(
    id: 'ghost_um_akzent',
    name: 'Ghost Notes Around the Accent',
    skills: {Skill.control},
    description:
        'One loud accent embedded in soft ghost notes. Maximum dynamic '
        'contrast in a tight space.',
    minBpm: 50,
    targetBpm: 130,
    difficulty: Difficulty.intermediate,
    gridUnit: NoteGrid.sixteenth,
    sticking: [
      StrokeBeat(hand: Hand.left, isGhost: true),
      StrokeBeat(hand: Hand.right, isGhost: true),
      StrokeBeat(hand: Hand.left, isAccent: true),
      StrokeBeat(hand: Hand.right, isGhost: true),
      StrokeBeat(hand: Hand.left, isGhost: true),
      StrokeBeat(hand: Hand.right, isGhost: true),
      StrokeBeat(hand: Hand.left, isAccent: true),
      StrokeBeat(hand: Hand.right, isGhost: true),
      StrokeBeat(hand: Hand.left, isGhost: true),
      StrokeBeat(hand: Hand.right, isGhost: true),
      StrokeBeat(hand: Hand.left, isAccent: true),
      StrokeBeat(hand: Hand.right, isGhost: true),
      StrokeBeat(hand: Hand.left, isGhost: true),
      StrokeBeat(hand: Hand.right, isGhost: true),
      StrokeBeat(hand: Hand.left, isAccent: true),
      StrokeBeat(hand: Hand.right, isGhost: true),
    ],
    technique: [
      TechniqueSection(
        title: 'Motion',
        body:
            'Ghost notes stay 2–3 cm above the head; the accent comes from up high. '
            'The difference in stick height creates the dynamics automatically.',
      ),
      TechniqueSection(
        title: 'Goal',
        body:
            'The listener should perceive only the accent clearly, with the ghost '
            'notes as a quiet simmer in the background.',
      ),
    ],
  ),

  Rudiment(
    id: 'timing_achtel_triolen',
    name: 'Even Eighth-Note Triplets',
    skills: {Skill.control},
    description:
        'Triplets with an accent on every beat. Trains dividing the pulse '
        'evenly into three — the foundation for shuffle and swing.',
    minBpm: 50,
    targetBpm: 150,
    difficulty: Difficulty.intermediate,
    gridUnit: NoteGrid.triplet,
    sticking: [
      StrokeBeat(hand: Hand.right, isAccent: true),
      StrokeBeat(hand: Hand.left),
      StrokeBeat(hand: Hand.right),
      StrokeBeat(hand: Hand.left, isAccent: true),
      StrokeBeat(hand: Hand.right),
      StrokeBeat(hand: Hand.left),
      StrokeBeat(hand: Hand.right, isAccent: true),
      StrokeBeat(hand: Hand.left),
      StrokeBeat(hand: Hand.right),
      StrokeBeat(hand: Hand.left, isAccent: true),
      StrokeBeat(hand: Hand.right),
      StrokeBeat(hand: Hand.left),
    ],
    technique: [
      TechniqueSection(
        title: 'Goal',
        body:
            'All three triplet notes spaced exactly evenly. Count '
            '"1-trip-let, 2-trip-let" and place the accent right on the beat.',
      ),
      TechniqueSection(
        title: 'Practice Plan',
        body:
            'Play against a metronome clicking quarter notes and check that the '
            'middle triplet note sits cleanly in the center.',
      ),
    ],
  ),

  Rudiment(
    id: 'timing_galopp',
    name: 'Gallop Rhythm',
    skills: {Skill.control},
    description:
        'An eighth note followed by two sixteenths on each beat (the "gallop"). '
        'Trains precise subdivision within the beat.',
    minBpm: 50,
    targetBpm: 140,
    difficulty: Difficulty.intermediate,
    gridUnit: NoteGrid.sixteenth,
    sticking: [
      StrokeBeat(hand: Hand.right, isAccent: true),
      StrokeBeat.rest(),
      StrokeBeat(hand: Hand.left),
      StrokeBeat(hand: Hand.right),
      StrokeBeat(hand: Hand.left, isAccent: true),
      StrokeBeat.rest(),
      StrokeBeat(hand: Hand.right),
      StrokeBeat(hand: Hand.left),
      StrokeBeat(hand: Hand.right, isAccent: true),
      StrokeBeat.rest(),
      StrokeBeat(hand: Hand.left),
      StrokeBeat(hand: Hand.right),
      StrokeBeat(hand: Hand.left, isAccent: true),
      StrokeBeat.rest(),
      StrokeBeat(hand: Hand.right),
      StrokeBeat(hand: Hand.left),
    ],
    technique: [
      TechniqueSection(
        title: 'Goal',
        body:
            'The first stroke is long (an eighth), followed by two quick '
            'sixteenths. The "da-da-dum" feel must stay even.',
      ),
      TechniqueSection(
        title: 'Common Mistakes',
        body:
            '• Playing the two sixteenths too early (triplet instead of gallop)\n'
            '• Uneven gap after the first stroke',
      ),
    ],
  ),

  // ─── MARCHING SNARE ─────────────────────────────────────────────────────────

  Rudiment(
    id: 'eight_on_a_hand',
    name: 'Eight on a Hand',
    skills: {Skill.control},
    genres: {Genre.drumCorps},
    description:
        'Eight sixteenths per hand with an accent on every beat. '
        'A fundamental marching warm-up for control and an even stroke.',
    minBpm: 60,
    targetBpm: 160,
    difficulty: Difficulty.beginner,
    gridUnit: NoteGrid.sixteenth,
    beatsPerBar: 4,
    sticking: [
      StrokeBeat(hand: Hand.right, isAccent: true),
      StrokeBeat(hand: Hand.right),
      StrokeBeat(hand: Hand.right),
      StrokeBeat(hand: Hand.right),
      StrokeBeat(hand: Hand.right, isAccent: true),
      StrokeBeat(hand: Hand.right),
      StrokeBeat(hand: Hand.right),
      StrokeBeat(hand: Hand.right),
      StrokeBeat(hand: Hand.left, isAccent: true),
      StrokeBeat(hand: Hand.left),
      StrokeBeat(hand: Hand.left),
      StrokeBeat(hand: Hand.left),
      StrokeBeat(hand: Hand.left, isAccent: true),
      StrokeBeat(hand: Hand.left),
      StrokeBeat(hand: Hand.left),
      StrokeBeat(hand: Hand.left),
    ],
    technique: [
      TechniqueSection(
        title: 'Goal',
        body:
            'Even sixteenths with a clear accent on 1, 2, 3, 4. '
            'The unaccented notes stay low and relaxed.',
      ),
      TechniqueSection(
        title: 'Tip',
        body:
            'The wrist drives the accents; the fingers control the low notes. '
            'Both hands should sound identical.',
      ),
    ],
  ),

  Rudiment(
    id: 'flam_accent_corps',
    name: 'Flam Accent',
    skills: {Skill.control},
    genres: {Genre.drumCorps},
    description:
        'A flam on the accented beat, followed by two tap notes — '
        'in a triplet feel. A cornerstone of the marching rudiments.',
    minBpm: 50,
    targetBpm: 140,
    difficulty: Difficulty.intermediate,
    gridUnit: NoteGrid.triplet,
    beatsPerBar: 2,
    sticking: [
      StrokeBeat(hand: Hand.right, isAccent: true, graces: [Hand.left]),
      StrokeBeat(hand: Hand.left),
      StrokeBeat(hand: Hand.right),
      StrokeBeat(hand: Hand.left, isAccent: true, graces: [Hand.right]),
      StrokeBeat(hand: Hand.right),
      StrokeBeat(hand: Hand.left),
    ],
    technique: [
      TechniqueSection(
        title: 'Motion',
        body:
            'The flam lands as a strong accent; the two following taps '
            'stay low. Hands switch after every triplet.',
      ),
    ],
  ),

  Rudiment(
    id: 'flam_tap',
    name: 'Flam Tap',
    skills: {Skill.control},
    genres: {Genre.drumCorps},
    description:
        'A flam followed by a tap with the same hand: lR-R rL-L. '
        'Trains the down-up stroke and double strokes with a flam.',
    minBpm: 50,
    targetBpm: 150,
    difficulty: Difficulty.intermediate,
    gridUnit: NoteGrid.eighth,
    beatsPerBar: 4,
    sticking: [
      StrokeBeat(hand: Hand.right, isAccent: true, graces: [Hand.left]),
      StrokeBeat(hand: Hand.right),
      StrokeBeat(hand: Hand.left, isAccent: true, graces: [Hand.right]),
      StrokeBeat(hand: Hand.left),
      StrokeBeat(hand: Hand.right, isAccent: true, graces: [Hand.left]),
      StrokeBeat(hand: Hand.right),
      StrokeBeat(hand: Hand.left, isAccent: true, graces: [Hand.right]),
      StrokeBeat(hand: Hand.left),
    ],
    technique: [
      TechniqueSection(
        title: 'Down-Up',
        body:
            'The flam is a down stroke (loud, staying low); the tap is a '
            'low up stroke that prepares the next hand.',
      ),
    ],
  ),

  Rudiment(
    id: 'flamacue',
    name: 'Flamacue',
    skills: {Skill.control},
    genres: {Genre.drumCorps},
    description:
        'A flam, then an accent on the second note, two taps, and a '
        'closing flam. A classic, expressive rudiment.',
    minBpm: 50,
    targetBpm: 130,
    difficulty: Difficulty.advanced,
    gridUnit: NoteGrid.sixteenth,
    beatsPerBar: 2,
    sticking: [
      StrokeBeat(hand: Hand.right, graces: [Hand.left]),
      StrokeBeat(hand: Hand.left, isAccent: true),
      StrokeBeat(hand: Hand.right),
      StrokeBeat(hand: Hand.left),
      StrokeBeat(hand: Hand.left, graces: [Hand.right]),
      StrokeBeat(hand: Hand.right, isAccent: true),
      StrokeBeat(hand: Hand.left),
      StrokeBeat(hand: Hand.right),
    ],
    technique: [
      TechniqueSection(
        title: 'Accent',
        body:
            'The accent is not on the flam but on the note right after it. '
            'Exactly this shift is what defines the flamacue.',
      ),
    ],
  ),

  Rudiment(
    id: 'flam_paradiddle_corps',
    name: 'Flam Paradiddle',
    skills: {Skill.control},
    genres: {Genre.drumCorps},
    description:
        'A paradiddle whose first note is an accented flam: '
        'lR-L-R-R rL-R-L-L. Combines flam control with double strokes.',
    minBpm: 50,
    targetBpm: 140,
    difficulty: Difficulty.advanced,
    gridUnit: NoteGrid.sixteenth,
    beatsPerBar: 2,
    sticking: [
      StrokeBeat(hand: Hand.right, isAccent: true, graces: [Hand.left]),
      StrokeBeat(hand: Hand.left),
      StrokeBeat(hand: Hand.right),
      StrokeBeat(hand: Hand.right),
      StrokeBeat(hand: Hand.left, isAccent: true, graces: [Hand.right]),
      StrokeBeat(hand: Hand.right),
      StrokeBeat(hand: Hand.left),
      StrokeBeat(hand: Hand.left),
    ],
    technique: [
      TechniqueSection(
        title: 'Tip',
        body:
            'The flam accent opens each paradiddle; the closing '
            'diddle (RR or LL) stays low and controlled.',
      ),
    ],
  ),

  Rudiment(
    id: 'cheese',
    name: 'Cheese (Flam Diddle)',
    skills: {Skill.control},
    genres: {Genre.drumCorps},
    description:
        'A flam followed immediately by a diddle: lR-R rL-L. '
        'A hybrid rudiment that merges flam and double stroke into one motion.',
    minBpm: 50,
    targetBpm: 130,
    difficulty: Difficulty.advanced,
    gridUnit: NoteGrid.sixteenth,
    beatsPerBar: 2,
    sticking: [
      StrokeBeat(hand: Hand.right, graces: [Hand.left]),
      StrokeBeat(hand: Hand.right),
      StrokeBeat(hand: Hand.left, graces: [Hand.right]),
      StrokeBeat(hand: Hand.left),
      StrokeBeat(hand: Hand.right, graces: [Hand.left]),
      StrokeBeat(hand: Hand.right),
      StrokeBeat(hand: Hand.left, graces: [Hand.right]),
      StrokeBeat(hand: Hand.left),
    ],
    technique: [
      TechniqueSection(
        title: 'Idea',
        body:
            'The flam and the first diddle stroke almost merge into a single '
            'sound. Stay loose — the diddle comes from the fingers.',
      ),
    ],
  ),

  Rudiment(
    id: 'inverted_flam_tap',
    name: 'Inverted Flam Tap',
    skills: {Skill.control},
    genres: {Genre.drumCorps},
    description:
        'A flam tap where the flam falls on the offbeat: R lR L rL. '
        'A demanding variation for timing and hand-to-hand control.',
    minBpm: 50,
    targetBpm: 130,
    difficulty: Difficulty.professional,
    gridUnit: NoteGrid.eighth,
    beatsPerBar: 4,
    sticking: [
      StrokeBeat(hand: Hand.right),
      StrokeBeat(hand: Hand.right, isAccent: true, graces: [Hand.left]),
      StrokeBeat(hand: Hand.left),
      StrokeBeat(hand: Hand.left, isAccent: true, graces: [Hand.right]),
      StrokeBeat(hand: Hand.right),
      StrokeBeat(hand: Hand.right, isAccent: true, graces: [Hand.left]),
      StrokeBeat(hand: Hand.left),
      StrokeBeat(hand: Hand.left, isAccent: true, graces: [Hand.right]),
    ],
    technique: [
      TechniqueSection(
        title: 'Watch Out',
        body:
            'The flam sits on the "and" of the beat. Practice very slowly at '
            'first so the displaced accent lands cleanly.',
      ),
    ],
  ),
];

