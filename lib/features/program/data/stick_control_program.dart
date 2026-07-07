import '../models/training_program.dart';

/// Exercise keys — these reference existing [Rudiment.id]s in
/// `lib/features/lessons/data/rudiments_seed.dart` (no duplicate rudiments are
/// seeded; see BERICHT_TRAINING_PROGRAM.md §0.2).
const scSingles = 'single_stroke_roll';
const scDoubles = 'double_stroke_roll';
const scParadiddle = 'single_paradiddle';

/// The fixed "Stick Control – 12 Wochen" curriculum (STICK_CONTROL_PROGRAM.md
/// §2 / §9.2). Static data — served read-only via `trainingProgramProvider`.
/// The 84 [ProgramDay]s are expanded at runtime by the generator, not stored.
const stickControlProgram = TrainingProgram(
  name: 'Stick Control – 12 Wochen',
  description:
      'Fortgeschrittener Anfänger → saubere, lockere Hände. Nur Pad + Stöcke, '
      'tägliche kurze Sessions. Tempo ist Nebenprodukt von Evenness und '
      'Lockerheit, nicht das Ziel.',
  totalWeeks: 12,
  phases: [
    ProgramPhase(
      index: 1,
      name: 'Fundament',
      focus:
          'Beide Hände exakt gleich hoch, exakt gleich laut. Locker greifen — '
          'der Stock soll federn, nicht gewürgt werden. Kein Tempo suchen; '
          'Gleichheit ist das Ziel.',
      focusCue:
          'Von vorne filmen. Die schwache Hand schlägt fast immer tiefer — '
          'genau das angleichen.',
      weekStart: 1,
      weekEnd: 3,
      startBpm: 70,
      exerciseKey: scSingles,
    ),
    ProgramPhase(
      index: 2,
      name: 'Fingerkontrolle',
      focus:
          'Erster Schlag aus dem Handgelenk, zweiter aus dem Absprung. Die '
          'Finger fangen den zweiten nur — du schlägst ihn nicht aktiv. '
          'Handgelenk ruhiger, Finger arbeiten.',
      focusCue:
          'Fühlt sich anfangs schwach an. Dieser Muskel ist genau der, der dir '
          'zum Tempo gefehlt hat.',
      weekStart: 4,
      weekEnd: 6,
      startBpm: 60,
      exerciseKey: scDoubles,
    ),
    ProgramPhase(
      index: 3,
      name: 'Kontrolle',
      focus:
          'Akzent klar und voll, Taps klein und leise — der Unterschied kommt '
          'aus der Stockhöhe, nicht aus mehr Kraft. Zwischen Akzent und Tap '
          'darf der Griff nicht verkrampfen.',
      focusCue:
          'Beim Paradiddle liegt der Akzent auf dem ersten Schlag jeder Gruppe. '
          'Die restlichen drei bleiben klein und gleich.',
      weekStart: 7,
      weekEnd: 9,
      startBpm: 70,
      exerciseKey: scParadiddle,
    ),
    ProgramPhase(
      index: 4,
      name: 'Tempo & Ausdauer',
      focus:
          'Jetzt neue saubere Bestwerte holen. Die Regel bleibt: Tempo nur nach '
          'lockerem, gleichmäßigem Durchlauf. Endurance-Läufe: zwei Minuten am '
          'Stück, ohne dass die Gleichheit zerfällt.',
      focusCue:
          'Wenn es verkrampft, ist das Tempo zu hoch — vier zurück, sauber '
          'festigen, dann erneut.',
      weekStart: 10,
      weekEnd: 12,
      // Phase 4 rotates the line per week (§9.3); the generator overrides this.
      // Fallback start tempo when no stored clean tempo exists yet.
      startBpm: 100,
      exerciseKey: scSingles,
    ),
  ],
);
