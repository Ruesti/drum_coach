import 'package:flutter/material.dart';

enum Hand { right, left }

enum Difficulty {
  beginner(label: 'Beginner', color: Color(0xFF4CAF50)),
  intermediate(label: 'Intermediate', color: Color(0xFFFFC107)),
  advanced(label: 'Advanced', color: Color(0xFFFF9800)),
  professional(label: 'Professional', color: Color(0xFFF44336));

  final String label;
  final Color color;
  const Difficulty({required this.label, required this.color});
}

class StrokeBeat {
  final Hand hand;
  final bool isAccent;
  final bool isGhost;

  const StrokeBeat({
    required this.hand,
    this.isAccent = false,
    this.isGhost = false,
  });
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
  final String? svgAssetPath;

  const Rudiment({
    required this.id,
    required this.name,
    required this.category,
    required this.description,
    required this.minBpm,
    required this.targetBpm,
    required this.difficulty,
    required this.sticking,
    this.svgAssetPath,
  });
}
