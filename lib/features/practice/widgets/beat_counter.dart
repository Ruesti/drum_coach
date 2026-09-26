import 'package:flutter/material.dart';

import '../../../app/design_tokens.dart';

/// Which beat of the bar (0-based) a pattern tick falls on. The metronome
/// counts ticks on a fine grid ([ticksPerQuarter] per quarter note); the
/// counter shows quarter-note beats and wraps at the exercise's bar length.
int beatOfTick(int tick,
        {required int ticksPerQuarter, required int beatsPerBar}) =>
    (tick ~/ ticksPerQuarter) % beatsPerBar;

/// The "1 2 3 4" counter under the sheet: one big mono digit per beat of the
/// bar, the active beat in accent with a short bar under it. Null = idle,
/// nothing highlighted.
class BeatCounter extends StatelessWidget {
  const BeatCounter({
    super.key,
    required this.beatsPerBar,
    required this.activeBeat,
  });

  final int beatsPerBar;
  final int? activeBeat;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (var i = 0; i < beatsPerBar; i++)
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${i + 1}',
                    style: PracticeTypography.numericXl.copyWith(
                      fontSize: 56,
                      height: 1,
                      color: i == activeBeat
                          ? PracticeColors.accent
                          : PracticeColors.textFaint,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    width: 22,
                    height: 4,
                    decoration: BoxDecoration(
                      color: i == activeBeat
                          ? PracticeColors.accent
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
