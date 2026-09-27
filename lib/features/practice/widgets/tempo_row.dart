import 'package:flutter/material.dart';

import '../../../app/design_tokens.dart';
import '../../../shared/widgets/bpm_control.dart';

/// Minus · big tempo · plus. The buttons move by one ladder step (4 BPM);
/// tapping the number opens the exact-entry dialog for fine values.
class TempoRow extends StatelessWidget {
  const TempoRow({
    super.key,
    required this.bpm,
    required this.onChanged,
    this.step = 4,
    this.min = 40,
    this.max = 240,
  });

  final int bpm;
  final ValueChanged<int> onChanged;
  final int step;
  final int min;
  final int max;

  void _nudge(int delta) => onChanged((bpm + delta).clamp(min, max));

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _RoundButton(
          icon: Icons.remove,
          tooltip: 'Slower',
          onTap: () => _nudge(-step),
        ),
        Expanded(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () async {
              final value =
                  await editBpmDialog(context, current: bpm, min: min, max: max);
              if (value != null) onChanged(value);
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  '$bpm',
                  style: PracticeTypography.numericXl
                      .copyWith(fontSize: 48, height: 1),
                ),
                const SizedBox(width: 8),
                Text(
                  'BPM',
                  style: PracticeTypography.label
                      .copyWith(color: PracticeColors.textMuted),
                ),
              ],
            ),
          ),
        ),
        _RoundButton(
          icon: Icons.add,
          tooltip: 'Faster',
          onTap: () => _nudge(step),
        ),
      ],
    );
  }
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: PracticeColors.raised,
        shape: const CircleBorder(
            side: BorderSide(color: PracticeColors.textFaint)),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(
            width: 44,
            height: 44,
            child: Icon(icon, size: 20, color: PracticeColors.textPrimary),
          ),
        ),
      ),
    );
  }
}
