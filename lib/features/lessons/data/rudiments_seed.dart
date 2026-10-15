import '../models/rudiment.dart';
import 'sheets/single_stroke_roll_sheet.dart';
import 'sheets/double_stroke_roll_sheet.dart';
import 'sheets/single_paradiddle_sheet.dart';
import 'sheets/double_paradiddle_sheet.dart';
import 'sheets/paradiddle_diddle_sheet.dart';
import 'sheets/flam_sheet.dart';
import 'sheets/flam_accent_sheet.dart';
import 'sheets/flam_tap_sheet.dart';
import 'sheets/single_drag_sheet.dart';
import 'sheets/five_stroke_roll_sheet.dart';
import 'sheets/seven_stroke_roll_sheet.dart';
import 'sheets/swiss_army_triplet_sheet.dart';
import 'sheets/fill_sixteenth_singles_sheet.dart';
import 'sheets/fill_doubles_sheet.dart';
import 'sheets/fill_paradiddle_sheet.dart';
import 'sheets/fill_triplets_sheet.dart';
import 'sheets/fill_flams_sheet.dart';
import 'sheets/fill_sextuplets_sheet.dart';
import 'sheets/fill_six_groups_sheet.dart';
import 'sheets/fill_roll_sheet.dart';

// A plain list (not const) since 30.09.: the sample sheet is built with the
// étude DSL, which is not const-constructible.
final List<Rudiment> rudimentsSeedData = <Rudiment>[
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
    sticking: singleStrokeRollPattern,
    technique: singleStrokeRollLesson,
    lines: singleStrokeRollSheet,
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
    sticking: doubleStrokeRollPattern,
    technique: doubleStrokeRollLesson,
    lines: doubleStrokeRollSheet,
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
        body: 'Press the stick lightly into the head — a guided press, not a '
            'clamped grip. The stick bounces multiple times freely. '
            'The pressure controls the density of the bounces. '
            'Alternate hands so that no gap is audible.',
      ),
      TechniqueSection(
        title: 'Common Mistakes',
        body: '• Lifting the stick between strokes (audible gaps)\n'
            '• Too much or too little pressure\n'
            '• Uneven hand-to-hand transitions',
      ),
      TechniqueSection(
        title: 'Practice Plan',
        body: 'First find the right amount of pressure with one hand. '
            'Then practice each hand separately. Only combine them once '
            'each hand produces an even buzz on its own.',
      ),
      TechniqueSection(
        title: 'Musical Application',
        body: 'Crescendo rolls and fermata strokes. Essential in orchestral '
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
    sticking: singleParadiddlePattern,
    technique: singleParadiddleLesson,
    lines: singleParadiddleSheet,
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
    sticking: doubleParadiddlePattern,
    technique: doubleParadiddleLesson,
    lines: doubleParadiddleSheet,
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
    sticking: paradiddleDiddlePattern,
    technique: paradiddleDiddleLesson,
    lines: paradiddleDiddleSheet,
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
    sticking: flamPattern,
    technique: flamLesson,
    lines: flamSheet,
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
    sticking: flamAccentPattern,
    technique: flamAccentLesson,
    lines: flamAccentSheet,
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
      StrokeBeat(
          hand: Hand.right,
          isAccent: true,
          value: NoteValue.quarter,
          graces: [Hand.left]),
      StrokeBeat(hand: Hand.left),
      StrokeBeat(hand: Hand.right),
      StrokeBeat(hand: Hand.right),
      StrokeBeat(
          hand: Hand.left,
          isAccent: true,
          value: NoteValue.quarter,
          graces: [Hand.right]),
      StrokeBeat(hand: Hand.right),
      StrokeBeat(hand: Hand.left),
      StrokeBeat(hand: Hand.left),
    ],
    technique: [
      TechniqueSection(
        title: 'Motion',
        body: 'A paradiddle with a flam on the first stroke of each group. '
            'lRLRR: grace note left, primary stroke right, then continue L-R-R. '
            'The grace note must stay tight to the flam despite the following strokes.',
      ),
      TechniqueSection(
        title: 'Common Mistakes',
        body: '• Grace note getting lost in the rest of the pattern\n'
            '• Unstable tempo after the flam\n'
            '• Losing control of the double stroke at the end',
      ),
      TechniqueSection(
        title: 'Practice Plan',
        body: 'Master the single paradiddle without the flam first. '
            'Then slowly add the grace note. '
            'Very slow practice (40 BPM) is essential here.',
      ),
      TechniqueSection(
        title: 'Musical Application',
        body: 'A high level of stick control. Impressive texture for '
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
    sticking: singleDragPattern,
    technique: singleDragLesson,
    lines: singleDragSheet,
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
      StrokeBeat(
          hand: Hand.right,
          isAccent: true,
          value: NoteValue.quarter,
          dotted: true,
          graces: [Hand.left, Hand.left]),
      StrokeBeat(hand: Hand.left),
      StrokeBeat(
          hand: Hand.right,
          isAccent: true,
          value: NoteValue.quarter,
          dotted: true,
          graces: [Hand.left, Hand.left]),
      StrokeBeat(hand: Hand.left),
    ],
    technique: [
      TechniqueSection(
        title: 'Structure',
        body: 'Drag + accent + tap, then repeat: llR L / llR L. '
            'Four strokes per group in total: two ghost notes, one accent, one tap. '
            'The tap after the accent sits at medium volume.',
      ),
      TechniqueSection(
        title: 'Common Mistakes',
        body: '• Rushing after the drag\n'
            '• Tap after the accent too loud or too quiet\n'
            '• Drags opening up at higher tempos',
      ),
      TechniqueSection(
        title: 'Practice Plan',
        body: 'Count in groups of four. The drag takes almost no time — '
            'it gets "squeezed" in right before beat 1. '
            'Practice the drag separately until it locks in automatically.',
      ),
      TechniqueSection(
        title: 'Musical Application',
        body: 'A complex rudimental pattern. Appears in snare drum etudes '
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
        body: '"Lesson 25" comes from traditional drum corps instruction. '
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
        body: '• Closing double stroke too loud or too quiet\n'
            '• Drags getting wider and louder under pressure\n'
            '• Timing drifting on the second drag',
      ),
      TechniqueSection(
        title: 'Practice Plan',
        body: 'This pattern takes time. '
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
        body: 'Ghost notes are so quiet they are barely audible — '
            'they "feel" the groove rather than define it. '
            'The dynamic difference between accent and ghost note '
            'must be dramatic: accents from 20–25 cm stick height, '
            'ghost notes from 1–2 cm.',
      ),
      TechniqueSection(
        title: 'Motion',
        body: 'Accent hand: the wrist snaps down from full height. '
            'Ghost note hand: the stick hovers just above the head — '
            'minimal motion, no wrist throw.',
      ),
      TechniqueSection(
        title: 'Common Mistakes',
        body: '• Ghost notes too loud — they dominate the groove\n'
            '• Stick height too low on accents\n'
            '• Imprecise ghost note timing',
      ),
      TechniqueSection(
        title: 'Musical Application',
        body: 'The foundation of funk and R&B drumming. '
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
        body: 'Volume comes from stick height, not from force. '
            'Forte = high stick (20–25 cm), relaxed wrist, '
            'fast throw. Piano = low stick (2–3 cm), '
            'controlled, small motion.',
      ),
      TechniqueSection(
        title: 'Common Mistakes',
        body: '• Controlling volume with grip pressure (wrong!)\n'
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
        body: 'Dynamic control is musicality. If you can control volume, '
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
        body: 'Linear means only one hand strikes at a time. '
            'No unison hits. The hands fill each other\'s gaps, '
            'creating a flowing, even stream of notes.',
      ),
      TechniqueSection(
        title: 'Motion',
        body: 'Accents from 20 cm, taps from 10 cm, ghost notes from 2 cm. '
            'The different heights within the pattern give it '
            'depth and groove. No two strokes are alike.',
      ),
      TechniqueSection(
        title: 'Common Mistakes',
        body: '• Hesitating between notes — the pattern must flow\n'
            '• Every note at the same volume\n'
            '• Tempo breaking on R-to-R or L-to-L transitions',
      ),
      TechniqueSection(
        title: 'Practice Plan',
        body: 'Start at 50 BPM and play the pattern until it feels automatic. '
            'Then speed up. To move it onto the drum set, '
            'assign each hand to a different instrument.',
      ),
    ],
  ),

  Rudiment(
    id: 'linear_beat_2',
    name: 'Linear Beat 2',
    skills: {Skill.coordination, Skill.fill},
    description: 'A second linear combination exploring a different grouping. '
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
        body: 'A different grouping than Linear Beat 1. '
            'Same-hand doubles (RR, LL) are allowed — '
            'that sets it apart from a purely alternating linear pattern. '
            'Accents on positions 1, 5, and 9 create a 10-note phrase.',
      ),
      TechniqueSection(
        title: 'Common Mistakes',
        body: '• Doubles (RR, LL) too loud or uneven\n'
            '• Losing the accent pattern\n'
            '• Ghost notes missing or too loud',
      ),
      TechniqueSection(
        title: 'Practice Plan',
        body: 'Learn the accent pattern on its own first. '
            'Then add the ghost notes and taps. '
            'Count the 10-note group deliberately to find your entry point '
            'when looping.',
      ),
      TechniqueSection(
        title: 'Musical Application',
        body: 'Funk and fusion grooves. Creates complexity without heaviness. '
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
        body: 'Start at 50–60 BPM. Only speed up once both hands truly '
            'sound the same. Practice with your eyes closed too.',
      ),
    ],
  ),

  Rudiment(
    id: 'akzent_zwei_vier',
    name: 'Accents on 2 and 4',
    skills: {Skill.control},
    description: 'Backbeat training: accent the strokes on beats 2 and 4 while '
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
        body: 'Internalize the backbeat. The accent on 2 and 4 must land '
            'automatically, without thinking. It is the basis of every rock and pop groove.',
      ),
      TechniqueSection(
        title: 'Practice Plan',
        body: 'Count "1-2-3-4" out loud while you play. Feel the pulse on '
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
        body: '• Ghost notes too loud (uncontrolled rebound)\n'
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
        body: 'Perfect for triplet fills. Spread across three toms, RLRRLL '
            'becomes an ascending phrase. Popular in fusion and Latin.',
      ),
    ],
  ),

  Rudiment(
    id: 'six_stroke_roll',
    name: 'Six Stroke Roll',
    skills: {Skill.control},
    description: 'RLLRRL — six strokes with two doubles in the middle. '
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
        body: 'The first and last strokes are accents with a full throw. '
            'The four middle strokes (LLRR) use rebound and stay quieter.',
      ),
      TechniqueSection(
        title: 'Practice Plan',
        body: 'Start slowly: accent — double — double — accent. '
            'Then raise the tempo until the transitions feel seamless.',
      ),
    ],
  ),

  Rudiment(
    id: 'gleichmaessigkeit_16tel',
    name: 'Evenness — Sixteenth Notes',
    skills: {Skill.control},
    description: 'Sixteenth notes in strict alternation, no accents. '
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
        body: '• Actively lifting the arm instead of letting it fall\n'
            '• Taps too loud (no contrast with the accent volume)\n'
            '• Starting too fast — slow is harder here',
      ),
      TechniqueSection(
        title: 'Practice Plan',
        body: 'Start extremely slowly (40 BPM). Only raise the tempo once the '
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
        body: 'Start slowly (50 BPM) and focus on a clean second stroke. '
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
        body: 'Increase in 5 BPM steps. Hold each step for one minute. Write '
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
        body: '• Staying tense during the rest\n'
            '• Rushing the burst and playing it unevenly',
      ),
    ],
  ),

  Rudiment(
    id: 'speed_doubles',
    name: 'Double Stroke Speed',
    skills: {Skill.control},
    description: 'Fast double strokes (RRLL) as sixteenths. Speed is built on '
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
        body: 'At high tempos the second stroke comes almost entirely from the '
            'rebound. Use finger pressure instead of arm strength.',
      ),
      TechniqueSection(
        title: 'Practice Plan',
        body: 'Start slowly with equally loud strokes. Only raise the tempo if '
            'the second stroke does not drop in volume.',
      ),
    ],
  ),

  Rudiment(
    id: 'ausdauer_dauerlauf',
    name: 'Sixteenth-Note Marathon',
    skills: {Skill.endurance},
    description: 'Continuous sixteenths for several minutes without a break. '
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
        body: 'Stay equally loud and even for the entire duration. '
            'Notice the moment your hands start to tire.',
      ),
      TechniqueSection(
        title: 'Practice Plan',
        body: 'Start with 2 minutes and extend weekly. When quality drops, '
            'consciously relax instead of stopping.',
      ),
    ],
  ),

  Rudiment(
    id: 'ausdauer_doubles',
    name: 'Double Stroke Endurance',
    skills: {Skill.endurance},
    description: 'Continuous double strokes (RRLL) to build forearm and finger '
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
        body: '• The second stroke getting quieter as fatigue sets in\n'
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
        body: 'All three triplet notes spaced exactly evenly. Count '
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
        body: 'The first stroke is long (an eighth), followed by two quick '
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
    description: 'Eight sixteenths per hand with an accent on every beat. '
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
        body: 'Even sixteenths with a clear accent on 1, 2, 3, 4. '
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
    description: 'A flam on the accented beat, followed by two tap notes — '
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
        body: 'The flam lands as a strong accent; the two following taps '
            'stay low. Hands switch after every triplet.',
      ),
    ],
  ),

  Rudiment(
    id: 'flam_tap',
    name: 'Flam Tap',
    skills: {Skill.control},
    genres: {Genre.drumCorps},
    description: 'A flam followed by a tap with the same hand: lR-R rL-L. '
        'Trains the down-up stroke and double strokes with a flam.',
    minBpm: 50,
    targetBpm: 150,
    difficulty: Difficulty.intermediate,
    gridUnit: NoteGrid.eighth,
    beatsPerBar: 4,
    sticking: flamTapPattern,
    technique: flamTapLesson,
    lines: flamTapSheet,
  ),

  Rudiment(
    id: 'flamacue',
    name: 'Flamacue',
    skills: {Skill.control},
    genres: {Genre.drumCorps},
    description: 'A flam, then an accent on the second note, two taps, and a '
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
        body: 'The accent is not on the flam but on the note right after it. '
            'Exactly this shift is what defines the flamacue.',
      ),
    ],
  ),

  Rudiment(
    id: 'flam_paradiddle_corps',
    name: 'Flam Paradiddle',
    skills: {Skill.control},
    genres: {Genre.drumCorps},
    description: 'A paradiddle whose first note is an accented flam: '
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
        body: 'The flam accent opens each paradiddle; the closing '
            'diddle (RR or LL) stays low and controlled.',
      ),
    ],
  ),

  Rudiment(
    id: 'cheese',
    name: 'Cheese (Flam Diddle)',
    skills: {Skill.control},
    genres: {Genre.drumCorps},
    description: 'A flam followed immediately by a diddle: lR-R rL-L. '
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
        body: 'The flam and the first diddle stroke almost merge into a single '
            'sound. Stay loose — the diddle comes from the fingers.',
      ),
    ],
  ),

  Rudiment(
    id: 'inverted_flam_tap',
    name: 'Inverted Flam Tap',
    skills: {Skill.control},
    genres: {Genre.drumCorps},
    description: 'A flam tap where the flam falls on the offbeat: R lR L rL. '
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
        body: 'The flam sits on the "and" of the beat. Practice very slowly at '
            'first so the displaced accent lands cleanly.',
      ),
    ],
  ),
  // ─── KATALOG 3a: new base rudiments ─────────────────────────────────────

  Rudiment(
    id: 'five_stroke_roll',
    name: "Five Stroke Roll",
    skills: {Skill.control},
    genres: {Genre.drumCorps},
    description:
        "Two doubles and an accent: R R L L R, L L R R L. The shortest roll that already sounds like a roll.",
    minBpm: 60,
    targetBpm: 140,
    difficulty: Difficulty.intermediate,
    gridUnit: NoteGrid.sixteenth,
    sticking: fiveStrokeRollPattern,
    technique: fiveStrokeRollLesson,
    lines: fiveStrokeRollSheet,
  ),

  Rudiment(
    id: 'seven_stroke_roll',
    name: "Seven Stroke Roll",
    skills: {Skill.control},
    genres: {Genre.drumCorps},
    description:
        "Three doubles and an accent: R R L L R R L. Six fast notes into one landing.",
    minBpm: 50,
    targetBpm: 120,
    difficulty: Difficulty.intermediate,
    gridUnit: NoteGrid.sixteenthTriplet,
    sticking: sevenStrokeRollPattern,
    technique: sevenStrokeRollLesson,
    lines: sevenStrokeRollSheet,
  ),

  Rudiment(
    id: 'swiss_army_triplet',
    name: "Swiss Army Triplet",
    skills: {Skill.control, Skill.coordination},
    genres: {Genre.drumCorps},
    description:
        "A flam, a tap with the same hand, then the other hand: lR R L, as triplets. Fast and oddly comfortable.",
    minBpm: 50,
    targetBpm: 110,
    difficulty: Difficulty.advanced,
    gridUnit: NoteGrid.triplet,
    sticking: swissArmyTripletPattern,
    technique: swissArmyTripletLesson,
    lines: swissArmyTripletSheet,
  ),
  // ─── KATALOG 3b: fill stickings ────────────────────────────────────────────

  Rudiment(
    id: 'fill_sixteenth_singles',
    name: "Sixteenth Singles Fill",
    skills: {Skill.fill, Skill.control},
    description:
        "Three bars of time, then a bar of sixteenth-note singles into the one. The first fill every drummer plays, and the one that has to sound the cleanest.",
    minBpm: 60,
    targetBpm: 130,
    difficulty: Difficulty.beginner,
    gridUnit: NoteGrid.sixteenth,
    sticking: fillSixteenthSinglesPattern,
    technique: fillSixteenthSinglesLesson,
    lines: fillSixteenthSinglesSheet,
  ),

  Rudiment(
    id: 'fill_doubles',
    name: "Doubles Fill",
    skills: {Skill.fill, Skill.control},
    description:
        "Three bars of time and a bar of R R L L. Doubles make a fill sound twice as fast as the hands move, and they are easy to spread over two drums.",
    minBpm: 60,
    targetBpm: 120,
    difficulty: Difficulty.beginner,
    gridUnit: NoteGrid.sixteenth,
    sticking: fillDoublesPattern,
    technique: fillDoublesLesson,
    lines: fillDoublesSheet,
  ),

  Rudiment(
    id: 'fill_paradiddle',
    name: "Paradiddle Fill",
    skills: {Skill.fill, Skill.coordination},
    genres: {Genre.funk},
    description:
        "Paradiddles as a fill over a funk band. The double inside each group moves the lead hand, so the fill wanders between the hands without you steering it.",
    minBpm: 60,
    targetBpm: 120,
    difficulty: Difficulty.intermediate,
    gridUnit: NoteGrid.sixteenth,
    sticking: fillParadiddlePattern,
    technique: fillParadiddleLesson,
    lines: fillParadiddleSheet,
  ),

  Rudiment(
    id: 'fill_triplets',
    name: "Triplet Fill",
    skills: {Skill.fill, Skill.coordination},
    description:
        "Triplet fills over a shuffle band. The time is shuffle hands or plain quarters, the fill rolls in threes and lands on the one.",
    minBpm: 60,
    targetBpm: 130,
    difficulty: Difficulty.intermediate,
    gridUnit: NoteGrid.triplet,
    sticking: fillTripletsPattern,
    technique: fillTripletsLesson,
    lines: fillTripletsSheet,
  ),

  Rudiment(
    id: 'fill_flams',
    name: "Flam Fill",
    skills: {Skill.fill, Skill.control},
    description:
        "Fills built from flams: fat single notes instead of fast ones. A flam fill is slow in the hands and big in the ear.",
    minBpm: 60,
    targetBpm: 110,
    difficulty: Difficulty.intermediate,
    gridUnit: NoteGrid.sixteenth,
    sticking: fillFlamsPattern,
    technique: fillFlamsLesson,
    lines: fillFlamsSheet,
  ),

  Rudiment(
    id: 'fill_sextuplets',
    name: "Sextuplet Fill",
    skills: {Skill.fill, Skill.control},
    description:
        "Six notes per beat over a straight band. The sextuplet fill is the fast, rolling fill of rock and fusion; the time around it stays plain eighths.",
    minBpm: 50,
    targetBpm: 100,
    difficulty: Difficulty.advanced,
    gridUnit: NoteGrid.sixteenthTriplet,
    backing: 'rock8',
    sticking: fillSextupletsPattern,
    technique: fillSextupletsLesson,
    lines: fillSextupletsSheet,
  ),

  Rudiment(
    id: 'fill_six_groups',
    name: "Six-Note Groups Fill",
    skills: {Skill.fill, Skill.coordination},
    genres: {Genre.funk},
    description:
        "Sixteenth-note fills phrased in groups of six: 6 + 6 + 4 over the bar. The accents drift across the beat and pull the listener along.",
    minBpm: 60,
    targetBpm: 110,
    difficulty: Difficulty.advanced,
    gridUnit: NoteGrid.sixteenth,
    sticking: fillSixGroupsPattern,
    technique: fillSixGroupsLesson,
    lines: fillSixGroupsSheet,
  ),

  Rudiment(
    id: 'fill_roll',
    name: "Roll Fill",
    skills: {Skill.fill, Skill.control},
    description:
        "Closed rolls as fills: thirty-second-note doubles that swell into the one. The classic \"snare roll into the chorus\".",
    minBpm: 60,
    targetBpm: 110,
    difficulty: Difficulty.advanced,
    gridUnit: NoteGrid.thirtySecond,
    sticking: fillRollPattern,
    technique: fillRollLesson,
    lines: fillRollSheet,
  ),
];
