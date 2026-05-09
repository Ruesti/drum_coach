import '../models/rudiment.dart';

const rudimentsSeedData = <Rudiment>[
  // ─── ROLLS ────────────────────────────────────────────────────────────────

  Rudiment(
    id: 'single_stroke_roll',
    name: 'Single Stroke Roll',
    category: 'Rolls',
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
  ),

  Rudiment(
    id: 'double_stroke_roll',
    name: 'Double Stroke Roll',
    category: 'Rolls',
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
  ),

  Rudiment(
    id: 'multiple_bounce_roll',
    name: 'Multiple Bounce Roll',
    category: 'Rolls',
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
  ),

  // ─── PARADIDDLES ──────────────────────────────────────────────────────────

  Rudiment(
    id: 'single_paradiddle',
    name: 'Single Paradiddle',
    category: 'Paradiddles',
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
  ),

  Rudiment(
    id: 'double_paradiddle',
    name: 'Double Paradiddle',
    category: 'Paradiddles',
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
  ),

  Rudiment(
    id: 'paradiddle_diddle',
    name: 'Paradiddle-Diddle',
    category: 'Paradiddles',
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
  ),

  // ─── FLAMS ────────────────────────────────────────────────────────────────

  Rudiment(
    id: 'flam',
    name: 'Flam',
    category: 'Flams',
    description:
        'A grace note played just before the main stroke, creating a thicker '
        'sound. The grace note (shown smaller) is barely audible — keep it tight.',
    minBpm: 60,
    targetBpm: 120,
    difficulty: Difficulty.intermediate,
    sticking: [
      StrokeBeat(hand: Hand.left, isGhost: true),
      StrokeBeat(hand: Hand.right, isAccent: true),
      StrokeBeat(hand: Hand.right, isGhost: true),
      StrokeBeat(hand: Hand.left, isAccent: true),
      StrokeBeat(hand: Hand.left, isGhost: true),
      StrokeBeat(hand: Hand.right, isAccent: true),
      StrokeBeat(hand: Hand.right, isGhost: true),
      StrokeBeat(hand: Hand.left, isAccent: true),
    ],
  ),

  Rudiment(
    id: 'flam_accent',
    name: 'Flam Accent',
    category: 'Flams',
    description:
        'A flam followed by two taps: lR L R / rL R L. Each group of three '
        'starts with a flam accent. Common in rudimental and orchestral drumming.',
    minBpm: 50,
    targetBpm: 100,
    difficulty: Difficulty.intermediate,
    sticking: [
      StrokeBeat(hand: Hand.left, isGhost: true),
      StrokeBeat(hand: Hand.right, isAccent: true),
      StrokeBeat(hand: Hand.left),
      StrokeBeat(hand: Hand.right),
      StrokeBeat(hand: Hand.right, isGhost: true),
      StrokeBeat(hand: Hand.left, isAccent: true),
      StrokeBeat(hand: Hand.right),
      StrokeBeat(hand: Hand.left),
    ],
  ),

  Rudiment(
    id: 'flam_paradiddle',
    name: 'Flam Paradiddle',
    category: 'Flams',
    description:
        'lRLRR / rLRLL. A paradiddle with a flam on the leading stroke. '
        'The grace note adds texture and challenges your stick control significantly.',
    minBpm: 40,
    targetBpm: 90,
    difficulty: Difficulty.advanced,
    sticking: [
      StrokeBeat(hand: Hand.left, isGhost: true),
      StrokeBeat(hand: Hand.right, isAccent: true),
      StrokeBeat(hand: Hand.left),
      StrokeBeat(hand: Hand.right),
      StrokeBeat(hand: Hand.right),
      StrokeBeat(hand: Hand.right, isGhost: true),
      StrokeBeat(hand: Hand.left, isAccent: true),
      StrokeBeat(hand: Hand.right),
      StrokeBeat(hand: Hand.left),
      StrokeBeat(hand: Hand.left),
    ],
  ),

  // ─── RUFFS / DRAGS ────────────────────────────────────────────────────────

  Rudiment(
    id: 'single_drag',
    name: 'Single Drag',
    category: 'Ruffs',
    description:
        'Two grace notes preceding the main stroke: llR rRL. The drag (two ghost '
        'notes) sounds like a rapid roll before the accent. Keep the drags light.',
    minBpm: 50,
    targetBpm: 100,
    difficulty: Difficulty.intermediate,
    sticking: [
      StrokeBeat(hand: Hand.left, isGhost: true),
      StrokeBeat(hand: Hand.left, isGhost: true),
      StrokeBeat(hand: Hand.right, isAccent: true),
      StrokeBeat(hand: Hand.right, isGhost: true),
      StrokeBeat(hand: Hand.right, isGhost: true),
      StrokeBeat(hand: Hand.left, isAccent: true),
    ],
  ),

  Rudiment(
    id: 'double_drag',
    name: 'Double Drag',
    category: 'Ruffs',
    description:
        'Two drag taps followed by an accent: llR L llR L / rrL R rrL R. '
        'Requires independent control of both hands to execute the drags cleanly.',
    minBpm: 40,
    targetBpm: 80,
    difficulty: Difficulty.advanced,
    sticking: [
      StrokeBeat(hand: Hand.left, isGhost: true),
      StrokeBeat(hand: Hand.left, isGhost: true),
      StrokeBeat(hand: Hand.right, isAccent: true),
      StrokeBeat(hand: Hand.left),
      StrokeBeat(hand: Hand.left, isGhost: true),
      StrokeBeat(hand: Hand.left, isGhost: true),
      StrokeBeat(hand: Hand.right, isAccent: true),
      StrokeBeat(hand: Hand.left),
    ],
  ),

  Rudiment(
    id: 'lesson_25',
    name: 'Lesson 25',
    category: 'Ruffs',
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
  ),

  // ─── GHOST NOTES ──────────────────────────────────────────────────────────

  Rudiment(
    id: 'ghost_note_groove',
    name: 'Ghost Note Groove',
    category: 'Ghost Notes',
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
  ),

  Rudiment(
    id: 'dynamics_control',
    name: 'Dynamics Control',
    category: 'Ghost Notes',
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
  ),

  // ─── LINEAR PATTERNS ──────────────────────────────────────────────────────

  Rudiment(
    id: 'linear_beat_1',
    name: 'Linear Beat 1',
    category: 'Linear Patterns',
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
  ),

  Rudiment(
    id: 'linear_beat_2',
    name: 'Linear Beat 2',
    category: 'Linear Patterns',
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
  ),
];

/// Ordered list of all categories for consistent display.
const rudimentCategories = [
  'Rolls',
  'Paradiddles',
  'Flams',
  'Ruffs',
  'Ghost Notes',
  'Linear Patterns',
];
