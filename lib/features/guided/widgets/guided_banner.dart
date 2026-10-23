import 'package:flutter/material.dart';

import '../../../app/design_tokens.dart';
import '../../lessons/models/rudiment.dart';
import '../models/guided_exercise.dart';
import 'guided_line_view.dart';
import 'guided_panel.dart';

/// "Coming up" (Plan 3a, Task 5, Spec §3.2): while the explanation plays in
/// the groove, the next variation's text and, under it, its notes dimmed so
/// they can be read before the change. Shown with the teacher off too —
/// then it is the only explanation.
class GuidedBanner extends StatelessWidget {
  const GuidedBanner({
    super.key,
    required this.exercise,
    required this.variation,
    required this.text,
    required this.line,
    this.lineMaxHeight,
    this.large = false,
  });

  final GuidedExercise exercise;

  /// 1-based number of the coming variation.
  final int variation;
  final String text;
  final ExerciseLine line;
  final double? lineMaxHeight;

  /// Wide layout: a little more type.
  final bool large;

  @override
  Widget build(BuildContext context) {
    return GuidedPanel(
      padding: const EdgeInsets.fromLTRB(AppSpacing.cardPadding, AppSpacing.md,
          AppSpacing.cardPadding, AppSpacing.cardPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: const BoxDecoration(
                    color: PracticeColors.accent, shape: BoxShape.circle),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text('COMING UP',
                  style: PracticeTypography.label.copyWith(
                      color: PracticeColors.accent, letterSpacing: 1.4)),
              const SizedBox(width: AppSpacing.sm),
              Text('V$variation',
                  style: PracticeTypography.label
                      .copyWith(color: PracticeColors.textMuted)),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            text,
            style: (large
                    ? PracticeTypography.title.copyWith(fontSize: 20)
                    : PracticeTypography.subtitle)
                .copyWith(color: PracticeColors.textSecondary, height: 1.3),
          ),
          const SizedBox(height: AppSpacing.md),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.chip),
            child: GuidedLineView(
              exercise: exercise,
              line: line,
              dimmed: true,
              maxStaffHeight: lineMaxHeight,
            ),
          ),
        ],
      ),
    );
  }
}

/// The big countdown step over the notes: 3 · 2 · 1 · GO (also with the
/// teacher off, Spec §3.2). [remaining] 0 = GO.
class GuidedCountdown extends StatelessWidget {
  const GuidedCountdown({super.key, required this.remaining, this.size = 132});

  final int remaining;

  /// Diameter of the disc.
  final double size;

  @override
  Widget build(BuildContext context) {
    final go = remaining == 0;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: go
            ? PracticeColors.accent
            : PracticeColors.base.withValues(alpha: 0.88),
        border: go ? null : Border.all(color: PracticeColors.accent, width: 3),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 24,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Text(
        go ? 'GO' : '$remaining',
        style: PracticeTypography.numericXl.copyWith(
          fontSize: go ? size * 0.36 : size * 0.56,
          color: Colors.white,
          height: 1,
          letterSpacing: go ? 2 : 0,
        ),
      ),
    );
  }
}
