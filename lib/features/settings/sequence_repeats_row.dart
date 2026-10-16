import 'package:flutter/material.dart';

import '../../app/design_tokens.dart';
import '../../shared/widgets/app_badge.dart';

/// "Repeats per line" for line sequences (`?lines=1,3,5`): how often each
/// selected line plays before the next one — 1× to 4×.
class SequenceRepeatsRow extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;
  const SequenceRepeatsRow(
      {super.key, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        for (var n = 1; n <= 4; n++)
          AppSelectableChip(
            key: ValueKey('repeats-$n'),
            label: '$n×',
            selected: value == n,
            onTap: () => onChanged(n),
          ),
      ],
    );
  }
}
