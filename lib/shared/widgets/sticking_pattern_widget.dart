import 'package:flutter/material.dart';

import '../../features/lessons/models/rudiment.dart';

class StickingPatternWidget extends StatelessWidget {
  final List<StrokeBeat> pattern;
  final int? activeBeatIndex;
  final double beatBoxSize;

  const StickingPatternWidget({
    super.key,
    required this.pattern,
    this.activeBeatIndex,
    this.beatBoxSize = 48,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: List.generate(pattern.length, (i) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: _BeatBox(
                beat: pattern[i],
                isActive: activeBeatIndex != null && i == activeBeatIndex,
                size: beatBoxSize,
              ),
            );
          }),
        ),
      ),
    );
  }
}

class _BeatBox extends StatelessWidget {
  final StrokeBeat beat;
  final bool isActive;
  final double size;

  const _BeatBox({
    required this.beat,
    required this.isActive,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    final label = beat.hand == Hand.right ? 'R' : 'L';

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Accent dot — always reserve height for alignment
        SizedBox(
          height: 14,
          child: beat.isAccent
              ? const Text(
                  '●',
                  style: TextStyle(
                    fontSize: 9,
                    color: Colors.deepOrange,
                    height: 1,
                  ),
                )
              : null,
        ),
        const SizedBox(height: 2),
        // Beat box with scale animation
        AnimatedScale(
          scale: isActive ? 1.15 : 1.0,
          duration: const Duration(milliseconds: 60),
          curve: Curves.easeOut,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 60),
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: isActive
                  ? Colors.amber.withValues(alpha: 0.85)
                  : beat.isGhost
                      ? Colors.white.withValues(alpha: 0.07)
                      : Colors.white.withValues(alpha: 0.13),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isActive
                    ? Colors.amber
                    : Colors.white.withValues(alpha: isActive ? 0.6 : 0.15),
                width: isActive ? 2 : 1,
              ),
            ),
            child: Center(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: beat.isGhost ? size * 0.28 : size * 0.38,
                  fontWeight: FontWeight.bold,
                  color: isActive
                      ? Colors.black87
                      : beat.isGhost
                          ? Colors.white.withValues(alpha: 0.35)
                          : Colors.white.withValues(alpha: 0.88),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
