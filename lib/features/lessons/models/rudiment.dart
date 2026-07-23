import 'package:flutter/material.dart';

enum Hand { right, left }

/// Duration of a single grid cell (= one metronome tick) in a pattern.
/// `cellsPerQuarter` is how many of these cells fit in one quarter-note beat —
/// used for beat grouping / beaming and to derive drawn note values.
enum NoteGrid {
  quarter(cellsPerQuarter: 1),
  eighth(cellsPerQuarter: 2),
  triplet(cellsPerQuarter: 3),
  sixteenth(cellsPerQuarter: 4);

  final int cellsPerQuarter;
  const NoteGrid({required this.cellsPerQuarter});
}

enum Difficulty {
  beginner(label: 'Beginner', color: Color(0xFF4CAF50)),
  intermediate(label: 'Intermediate', color: Color(0xFFFFC107)),
  advanced(label: 'Advanced', color: Color(0xFFFF9800)),
  professional(label: 'Professional', color: Color(0xFFF44336));

  final String label;
  final Color color;
  const Difficulty({required this.label, required this.color});
}

/// Where an exercise came from. `generated` = built from the sticking
/// grammar at runtime; `authored` = hand-notated (today's seed data);
/// `excerpt` = a pointer into an imported score (bar range, not a copy).
enum ExerciseSource { generated, authored, excerpt }

/// Which renderer/playback mode an exercise targets. `pad` = single-line
/// sticking notation + click, fully offline (practice pad, on the go).
/// `kit` = full kit notation with per-instrument voicing and synthetic
/// drum sounds (at home).
enum ExerciseVoicing { pad, kit }

/// What an exercise trains. Mirrors the brief's "Skill" axis
/// (`docs/AUDIT.md` Phase 0.5b) — multi-value, since one exercise can train
/// several things at once (e.g. a linear fill trains both `koordination`
/// and `independence`).
enum Skill {
  groove(label: 'Groove'),
  fill(label: 'Fill'),
  koordination(label: 'Koordination'),
  ausdauer(label: 'Ausdauer'),
  kontrolle(label: 'Kontrolle'),
  independence(label: 'Independence');

  final String label;
  const Skill({required this.label});
}

/// Musical/stylistic context. `general` covers today's pure hand-technique
/// catalog (no groove content exists yet); `drumCorps` is the one genre
/// value with real meaning today (Marching Snare rudiments).
enum Genre {
  general(label: 'Allgemein'),
  drumCorps(label: 'Drum Corps');

  final String label;
  const Genre({required this.label});
}

/// Which limbs an exercise is played with. All of today's catalog is
/// `hands` (no foot notation exists yet) — this exists so future kit-mode
/// content (bass drum, doublebass, four-limb coordination) has somewhere
/// to go without a model change.
enum Limb { hands, feet, doublebass, allFour }

/// The classic PAS rudiment family, for the four rudiment groups that have
/// one. `null` on [Rudiment.family] means "not a classic PAS rudiment"
/// (e.g. a Linear Pattern or a focused technique exercise).
enum RudimentFamily {
  roll(label: 'Rolls'),
  paradiddle(label: 'Paradiddles'),
  flam(label: 'Flams'),
  ruff(label: 'Ruffs');

  final String label;
  const RudimentFamily({required this.label});
}

/// One grid cell of a pattern. Occupies exactly one metronome tick.
/// A cell is either a struck note (default) or a [isRest] (silent) cell.
/// [graces] are grace notes (flam = 1, drag = 2) drawn small *before* the main
/// note; they share this cell's tick and do not consume their own grid slot.
class StrokeBeat {
  final Hand hand;
  final bool isAccent;
  final bool isGhost;
  final bool isRest;
  final List<Hand> graces;

  const StrokeBeat({
    required this.hand,
    this.isAccent = false,
    this.isGhost = false,
    this.isRest = false,
    this.graces = const [],
  });

  /// A silent grid cell (rest). [hand] is ignored when rendering.
  const StrokeBeat.rest()
      : hand = Hand.right,
        isAccent = false,
        isGhost = false,
        isRest = true,
        graces = const [];
}

class TechniqueSection {
  final String title;
  final String body;
  const TechniqueSection({required this.title, required this.body});
}

class Rudiment {
  final String id;
  final String name;
  final String category;
  final String description;
  final int minBpm;
  final int targetBpm;
  final Difficulty difficulty;
  final List<StrokeBeat> sticking;

  /// Duration of one [sticking] cell. Drives note values + metronome subdivision.
  final NoteGrid gridUnit;

  /// Quarter-note beats per bar — used for barlines and beam grouping.
  final int beatsPerBar;

  final List<TechniqueSection> technique;
  final String? svgAssetPath;

  /// Position in the curated practice-plan progression (1 = first). Used by the
  /// "Übungen" exercises to order the plan; `null` for standard rudiments.
  final int? level;

  /// Origin of this exercise. Defaults to [ExerciseSource.authored] since
  /// today's seed catalog is entirely hand-notated.
  final ExerciseSource source;

  /// Presentation/playback mode. Defaults to [ExerciseVoicing.pad] since
  /// the current single-voice [NotationStaffWidget] is pad-shaped.
  final ExerciseVoicing voicing;

  /// What this exercise trains. See [Skill]. Empty by default — only the
  /// seed catalog (`rudiments_seed.dart`) is expected to populate this.
  final List<Skill> skill;

  /// Classic PAS rudiment family, if this is one. See [RudimentFamily].
  final RudimentFamily? family;

  /// Musical/stylistic context. See [Genre].
  final Genre genre;

  /// Which limbs this exercise is played with. See [Limb].
  final List<Limb> limbs;

  const Rudiment({
    required this.id,
    required this.name,
    required this.category,
    required this.description,
    required this.minBpm,
    required this.targetBpm,
    required this.difficulty,
    required this.sticking,
    this.gridUnit = NoteGrid.eighth,
    this.beatsPerBar = 4,
    this.technique = const [],
    this.svgAssetPath,
    this.level,
    this.source = ExerciseSource.authored,
    this.voicing = ExerciseVoicing.pad,
    this.skill = const [],
    this.family,
    this.genre = Genre.general,
    this.limbs = const [Limb.hands],
  });
}
