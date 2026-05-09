import 'package:flutter/material.dart';

import '../../features/lessons/models/rudiment.dart';

class StickingPatternWidget extends StatelessWidget {
  final List<StrokeBeat> pattern;
  final int? activeBeatIndex;
  // kept for API compatibility — now used as row height
  final double beatBoxSize;

  const StickingPatternWidget({
    super.key,
    required this.pattern,
    this.activeBeatIndex,
    this.beatBoxSize = 44,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: List.generate(pattern.length, (i) {
        return _BeatRow(
          beat: pattern[i],
          beatNumber: i + 1,
          isActive: activeBeatIndex != null && i == activeBeatIndex,
          rowHeight: beatBoxSize,
        );
      }),
    );
  }
}

class _BeatRow extends StatelessWidget {
  final StrokeBeat beat;
  final int beatNumber;
  final bool isActive;
  final double rowHeight;

  const _BeatRow({
    required this.beat,
    required this.beatNumber,
    required this.isActive,
    required this.rowHeight,
  });

  @override
  Widget build(BuildContext context) {
    final isRight = beat.hand == Hand.right;
    final label = isRight ? 'R' : 'L';

    // Colours
    final accentColor = Colors.deepOrange;
    final activeColor = Colors.amber;

    final barColor = isActive
        ? activeColor
        : beat.isAccent
            ? accentColor
            : beat.isGhost
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.white.withValues(alpha: 0.14);

    final textColor = isActive
        ? Colors.black
        : beat.isGhost
            ? Colors.white.withValues(alpha: 0.28)
            : Colors.white.withValues(alpha: 0.9);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 70),
        height: rowHeight,
        decoration: BoxDecoration(
          color: isActive
              ? activeColor.withValues(alpha: 0.12)
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
                      ? activeColor.withValues(alpha: 0.9)
                      : Colors.white.withValues(alpha: 0.18),
                  fontWeight:
                      isActive ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),

            // Accent dot column
            SizedBox(
              width: 14,
              child: beat.isAccent
                  ? Text(
                      '●',
                      style: TextStyle(
                        fontSize: 7,
                        color: isActive ? activeColor : accentColor,
                      ),
                    )
                  : null,
            ),

            // Coloured bar with hand label
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 70),
                  decoration: BoxDecoration(
                    color: barColor,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: isActive
                          ? activeColor
                          : beat.isAccent
                              ? accentColor.withValues(alpha: 0.45)
                              : Colors.white.withValues(alpha: 0.08),
                      width: isActive ? 1.5 : 1,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      label,
                      style: TextStyle(
                        fontSize: beat.isGhost
                            ? rowHeight * 0.28
                            : rowHeight * 0.38,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(width: 6),
          ],
        ),
      ),
    );
  }
}
