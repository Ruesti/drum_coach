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
  });
}
