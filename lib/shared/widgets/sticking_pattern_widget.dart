import 'package:flutter/material.dart';

import '../../features/lessons/models/rudiment.dart';

class StickingPatternWidget extends StatelessWidget {
  final List<StrokeBeat> pattern;
  final int? activeBeatIndex;
  // kept for API compatibility — used as row/cell size
  final double beatBoxSize;

  const StickingPatternWidget({
    super.key,
    required this.pattern,
    this.activeBeatIndex,
    this.beatBoxSize = 44,
  });

  @override
  Widget build(BuildContext context) {
    const headerStyle = TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.bold,
      color: Colors.white38,
      letterSpacing: 1,
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Column headers
        Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Row(
            children: [
              const SizedBox(width: 28),
              Expanded(child: Center(child: Text('R', style: headerStyle))),
              const SizedBox(width: 4),
              Expanded(child: Center(child: Text('L', style: headerStyle))),
              const SizedBox(width: 6),
            ],
          ),
        ),

        // Beat rows
        ...List.generate(pattern.length, (i) {
          return _BeatRow(
            beat: pattern[i],
            beatNumber: i + 1,
            isActive: activeBeatIndex != null && i == activeBeatIndex,
            cellSize: beatBoxSize,
          );
        }),
      ],
    );
  }
}

class _BeatRow extends StatelessWidget {
  final StrokeBeat beat;
  final int beatNumber;
  final bool isActive;
  final double cellSize;

  const _BeatRow({
    required this.beat,
    required this.beatNumber,
    required this.isActive,
    required this.cellSize,
  });

  @override
  Widget build(BuildContext context) {
    final isRight = beat.hand == Hand.right;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 70),
        height: cellSize,
        decoration: BoxDecoration(
          color: isActive
              ? Colors.amber.withValues(alpha: 0.10)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            // Beat number
            SizedBox(
              width: 28,
              child: Text(
                '$beatNumber',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 10,
                  color: isActive
                      ? Colors.amber.withValues(alpha: 0.9)
                      : Colors.white.withValues(alpha: 0.18),
                  fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),

            // R cell
            Expanded(
              child: _StrokeCell(
                hasStroke: isRight,
                isAccent: beat.isAccent,
                isGhost: beat.isGhost,
                isActive: isActive,
                size: cellSize,
              ),
            ),
            const SizedBox(width: 4),

            // L cell
            Expanded(
              child: _StrokeCell(
                hasStroke: !isRight,
                isAccent: beat.isAccent,
                isGhost: beat.isGhost,
                isActive: isActive,
                size: cellSize,
              ),
            ),
            const SizedBox(width: 6),
          ],
        ),
      ),
    );
  }
}

class _StrokeCell extends StatelessWidget {
  final bool hasStroke;
  final bool isAccent;
  final bool isGhost;
  final bool isActive;
  final double size;

  const _StrokeCell({
    required this.hasStroke,
    required this.isAccent,
    required this.isGhost,
    required this.isActive,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    final cellSize = size - 8; // vertical padding

    Color? fillColor;
    Color borderColor;
    double borderWidth;

    if (!hasStroke) {
      // Empty cell — subtle box outline
      fillColor = null;
      borderColor = Colors.white.withValues(alpha: 0.06);
      borderWidth = 1;
    } else if (isActive) {
      fillColor = Colors.amber;
      borderColor = Colors.amber;
      borderWidth = 1.5;
    } else if (isAccent) {
      fillColor = Colors.deepOrange;
      borderColor = Colors.deepOrange;
      borderWidth = 1.5;
    } else if (isGhost) {
      fillColor = null;
      borderColor = Colors.white.withValues(alpha: 0.22);
      borderWidth = 1;
    } else {
      fillColor = null;
      borderColor = Colors.white.withValues(alpha: 0.65);
      borderWidth = 1.5;
    }

    return Center(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 70),
        width: cellSize * 0.72,
        height: cellSize * 0.72,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: fillColor,
          border: Border.all(color: borderColor, width: borderWidth),
        ),
      ),
    );
  }
}
