import 'package:flutter/material.dart';

import '../../features/lessons/models/rudiment.dart';

class StickingPatternWidget extends StatelessWidget {
  final List<StrokeBeat> pattern;
  final int? activeBeatIndex;
  // row height (and column width)
  final double beatBoxSize;

  const StickingPatternWidget({
    super.key,
    required this.pattern,
    this.activeBeatIndex,
    this.beatBoxSize = 44,
  });

  @override
  Widget build(BuildContext context) {
    const numberW = 20.0;
    const colGap = 8.0;

    const headerStyle = TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.bold,
      color: Colors.white38,
      letterSpacing: 1,
    );

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Column headers
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(width: numberW + 4),
                SizedBox(
                  width: beatBoxSize,
                  child: const Center(child: Text('R', style: headerStyle)),
                ),
                const SizedBox(width: colGap),
                SizedBox(
                  width: beatBoxSize,
                  child: const Center(child: Text('L', style: headerStyle)),
                ),
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
              numberW: numberW,
              colGap: colGap,
            );
          }),
        ],
      ),
    );
  }
}

class _BeatRow extends StatelessWidget {
  final StrokeBeat beat;
  final int beatNumber;
  final bool isActive;
  final double cellSize;
  final double numberW;
  final double colGap;

  const _BeatRow({
    required this.beat,
    required this.beatNumber,
    required this.isActive,
    required this.cellSize,
    required this.numberW,
    required this.colGap,
  });

  @override
  Widget build(BuildContext context) {
    final isRight = beat.hand == Hand.right;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Beat number
          SizedBox(
            width: numberW + 4,
            child: Text(
              '$beatNumber',
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 9,
                color: isActive
                    ? Colors.amber.withValues(alpha: 0.9)
                    : Colors.white.withValues(alpha: 0.18),
              ),
            ),
          ),

          // R cell
          _StrokeCell(
            hasStroke: isRight,
            isAccent: beat.isAccent,
            isGhost: beat.isGhost,
            isActiveBeat: isActive,
            size: cellSize,
          ),
          SizedBox(width: colGap),

          // L cell
          _StrokeCell(
            hasStroke: !isRight,
            isAccent: beat.isAccent,
            isGhost: beat.isGhost,
            isActiveBeat: isActive,
            size: cellSize,
          ),
        ],
      ),
    );
  }
}

class _StrokeCell extends StatelessWidget {
  final bool hasStroke;
  final bool isAccent;
  final bool isGhost;
  final bool isActiveBeat;
  final double size;

  const _StrokeCell({
    required this.hasStroke,
    required this.isAccent,
    required this.isGhost,
    required this.isActiveBeat,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    // Cell background
    final cellColor = isActiveBeat
        ? Colors.amber.withValues(alpha: 0.08)
        : const Color(0xFF252525);

    // Circle appearance
    Color? circleFill;
    Color circleBorder;
    double circleSize;

    if (!hasStroke) {
      // Empty cell — no circle
      return AnimatedContainer(
        duration: const Duration(milliseconds: 70),
        width: size,
        height: size - 6,
        decoration: BoxDecoration(
          color: cellColor,
          borderRadius: BorderRadius.circular(7),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.07),
            width: 1,
          ),
        ),
      );
    }

    if (isActiveBeat) {
      circleFill = Colors.amber;
      circleBorder = Colors.amber;
      circleSize = size * 0.70;
    } else if (isAccent) {
      circleFill = Colors.deepOrange;
      circleBorder = Colors.deepOrange;
      circleSize = size * 0.72; // accent circles slightly larger
    } else if (isGhost) {
      circleFill = null;
      circleBorder = Colors.white.withValues(alpha: 0.25);
      circleSize = size * 0.48; // ghost circles noticeably smaller
    } else {
      circleFill = null;
      circleBorder = Colors.white.withValues(alpha: 0.75);
      circleSize = size * 0.62;
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 70),
      width: size,
      height: size - 6,
      decoration: BoxDecoration(
        color: cellColor,
        borderRadius: BorderRadius.circular(7),
        border: Border.all(
          color: isActiveBeat
              ? Colors.amber.withValues(alpha: 0.35)
              : Colors.white.withValues(alpha: 0.07),
          width: 1,
        ),
      ),
      child: Center(
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 70),
          width: circleSize,
          height: circleSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: circleFill,
            border: Border.all(
              color: circleBorder,
              width: isAccent && !isActiveBeat ? 2 : 1.5,
            ),
          ),
        ),
      ),
    );
  }
}
