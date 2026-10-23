import 'package:flutter/material.dart';

import '../../../app/design_tokens.dart';
import '../../../shared/widgets/app_badge.dart';
import '../guided_format.dart';
import '../models/guided_exercise.dart';

/// One guided exercise in the library list.
class GuidedTile extends StatelessWidget {
  const GuidedTile({super.key, required this.exercise, required this.onTap});
  final GuidedExercise exercise;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ex = exercise;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.screenPadding, vertical: 10),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(ex.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.subtitle),
                  const SizedBox(height: 2),
                  Text(ex.description,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.body
                          .copyWith(color: AppColors.textMuted)),
                  const SizedBox(height: 2),
                  Text('${guidedDurationLabel(ex)} · ${ex.defaultBpm} BPM',
                      style: AppTypography.label
                          .copyWith(color: AppColors.textMuted)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            AppBadge(label: ex.package == GuidedPackage.kit ? 'SET' : 'PAD'),
            const SizedBox(width: 6),
            AppBadge(label: ex.difficulty.label, color: ex.difficulty.color),
          ],
        ),
      ),
    );
  }
}
