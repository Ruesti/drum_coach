import 'package:flutter/material.dart';

enum Hand { right, left }

/// Duration of a single grid cell (= one metronome tick) in a pattern.
/// `cellsPerQuarter` is how many of these cells fit in one quarter-note beat —
/// used for beat grouping / beaming and to derive drawn note values.
enum NoteGrid {
  quarter(cellsPerQuarter: 1),
  eighth(cellsPerQuarter: 2),
  triplet(cellsPerQuarter: 3),
  sixteenth(cellsPerQuarter: 4),
  sixteenthTriplet(cellsPerQuarter: 6),
  thirtySecond(cellsPerQuarter: 8);

  final int cellsPerQuarter;
  const NoteGrid({required this.cellsPerQuarter});
}

/// Display label for the Subdivision filter axis (brief: "Subdivision").
extension NoteGridLabel on NoteGrid {
  String get label => switch (this) {
        NoteGrid.quarter => 'Viertel',
        NoteGrid.eighth => '8tel',
        NoteGrid.triplet => 'Triolen',
        NoteGrid.sixteenth => '16tel',
        NoteGrid.sixteenthTriplet => '16tel-Triolen',
        NoteGrid.thirtySecond => '32tel',
      };
}

/// A drawn note value (independent of the pattern's [NoteGrid]). Duration is
/// expressed in quarter-note units so renderer and player share one source.
enum NoteValue {
  whole(quarters: 4.0),
  half(quarters: 2.0),
  quarter(quarters: 1.0),
  eighth(quarters: 0.5),
  sixteenth(quarters: 0.25),
  thirtySecond(quarters: 0.125);

  final double quarters;
  const NoteValue({required this.quarters});
}

/// Tuplet marker. `triplet` = 3 in the space of 2, `sextuplet` = 6 in the
/// space of 4 — both scale a note's duration by 2/3.
enum Tuplet {
  none(factor: 1.0),
  triplet(factor: 2 / 3),
  sextuplet(factor: 2 / 3);

  final double factor;
  const Tuplet({required this.factor});
}

/// A fully-resolved note value: base value with an optional dot and tuplet.
class ResolvedNote {
  final NoteValue value;
  final bool dotted;
  final Tuplet tuplet;
  const ResolvedNote(this.value, this.dotted, this.tuplet);

  /// Duration in quarter-note units.
  double get quarters => value.quarters * (dotted ? 1.5 : 1.0) * tuplet.factor;
}

/// Maps an old uniform [NoteGrid] cell to its equivalent note value, so
/// pre-existing patterns (whose [StrokeBeat.value] is null) resolve unchanged.
ResolvedNote gridToNote(NoteGrid grid) => switch (grid) {
      NoteGrid.quarter => const ResolvedNote(NoteValue.quarter, false, Tuplet.none),
      NoteGrid.eighth => const ResolvedNote(NoteValue.eighth, false, Tuplet.none),
      NoteGrid.triplet => const ResolvedNote(NoteValue.eighth, false, Tuplet.triplet),
      NoteGrid.sixteenth =>
        const ResolvedNote(NoteValue.sixteenth, false, Tuplet.none),
      NoteGrid.sixteenthTriplet =>
        const ResolvedNote(NoteValue.sixteenth, false, Tuplet.sextuplet),
      NoteGrid.thirtySecond =>
        const ResolvedNote(NoteValue.thirtySecond, false, Tuplet.none),
    };

/// Resolves a [StrokeBeat] to its note value: explicit [StrokeBeat.value] when
/// set (new content), otherwise derived from [grid] (legacy uniform patterns).
ResolvedNote resolveNote(StrokeBeat beat, NoteGrid grid) => beat.value != null
    ? ResolvedNote(beat.value!, beat.dotted, beat.tuplet)
    : gridToNote(grid);

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

/// Tag axis: what the exercise trains. Multiple values per exercise are
/// normal — e.g. a linear fill trains both fill and coordination.
enum Skill {
  control(label: 'Kontrolle'),
  coordination(label: 'Koordination'),
  endurance(label: 'Ausdauer'),
  groove(label: 'Groove'),
  fill(label: 'Fill'),
  independence(label: 'Independence');

  final String label;
  const Skill({required this.label});
}

/// Tag axis: stylistic context. Empty for most of today's pure-technique
/// catalog — populated as genre-specific groove/fill content is added.
enum Genre {
  rock(label: 'Rock'),
  funk(label: 'Funk'),
  jazz(label: 'Jazz'),
  latin(label: 'Latin'),
  metal(label: 'Metal'),
  drumCorps(label: 'Drum Corps');

  final String label;
  const Genre({required this.label});
}

/// A named, browsable set of exercises (distinct from the base catalog).
enum ExerciseCollection {
  rudimentEtudes(label: 'Rudiment-Étüden'),
  techniqueStudies(label: 'Technik-Studien'),
  padWorkouts(label: 'Pad-Workouts');

  final String label;
  const ExerciseCollection({required this.label});
}

/// Tag axis: which limbs the exercise engages.
enum Limb {
  hands(label: 'Hände'),
  feet(label: 'Füße'),
  doubleBass(label: 'Doublebass'),
  allFour(label: 'Alle vier');

  final String label;
  const Limb({required this.label});
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

  /// Drawn note value. `null` ⇒ derive from the pattern's [Rudiment.gridUnit]
  /// (legacy uniform patterns). Set explicitly for mixed-value content.
  final NoteValue? value;
  final bool dotted;
  final Tuplet tuplet;

  const StrokeBeat({
    required this.hand,
    this.isAccent = false,
    this.isGhost = false,
    this.isRest = false,
    this.graces = const [],
    this.value,
    this.dotted = false,
    this.tuplet = Tuplet.none,
  });

  /// A silent grid cell (rest). [hand] is ignored when rendering.
  const StrokeBeat.rest({
    this.value,
    this.dotted = false,
    this.tuplet = Tuplet.none,
  })  : hand = Hand.right,
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

  /// Origin of this exercise. Defaults to [ExerciseSource.authored] since
  /// today's seed catalog is entirely hand-notated.
  final ExerciseSource source;

  /// Presentation/playback mode. Defaults to [ExerciseVoicing.pad] since
  /// the current single-voice [NotationStaffWidget] is pad-shaped.
  final ExerciseVoicing voicing;

  /// Tag axis: what this exercise trains. See [Skill].
  final Set<Skill> skills;

  /// Tag axis: stylistic context. See [Genre]. Empty for most technique
  /// exercises; populated for genre-specific content (e.g. drum corps).
  final Set<Genre> genres;

  /// Tag axis: which limbs this exercise engages. See [Limb].
  final Set<Limb> limbs;

  /// Optional named collection this exercise belongs to (null = base catalog).
  final ExerciseCollection? collection;

  /// Optional sub-heading within the collection (e.g. the rudiment name).
  final String? collectionGroup;

  const Rudiment({
    required this.id,
    required this.name,
    required this.description,
    required this.minBpm,
    required this.targetBpm,
    required this.difficulty,
    required this.sticking,
    this.gridUnit = NoteGrid.eighth,
    this.beatsPerBar = 4,
    this.technique = const [],
    this.svgAssetPath,
    this.source = ExerciseSource.authored,
    this.voicing = ExerciseVoicing.pad,
    this.skills = const {},
    this.genres = const {},
    this.limbs = const {Limb.hands},
    this.collection,
    this.collectionGroup,
  });
}
