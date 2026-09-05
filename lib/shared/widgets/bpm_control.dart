import 'package:flutter/material.dart';

import '../../app/design_tokens.dart';

/// −5/−1/+1/+5 BPM step buttons, clamped to [min, max]. A dragging Slider
/// alone is fiddly for precise tempo changes — these give a fast, exact way
/// to nudge the tempo.
class BpmStepButtons extends StatelessWidget {
  final int bpm;
  final ValueChanged<int> onChanged;
  final int min;
  final int max;
  final MainAxisAlignment alignment;

  const BpmStepButtons({
    super.key,
    required this.bpm,
    required this.onChanged,
    this.min = 40,
    this.max = 240,
    this.alignment = MainAxisAlignment.center,
  });

  void _step(int delta) => onChanged((bpm + delta).clamp(min, max));

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: alignment,
      children: [
        _BpmStepButton(label: '−5', onTap: () => _step(-5)),
        const SizedBox(width: 6),
        _BpmStepButton(label: '−1', onTap: () => _step(-1)),
        const SizedBox(width: 6),
        _BpmStepButton(label: '+1', onTap: () => _step(1)),
        const SizedBox(width: 6),
        _BpmStepButton(label: '+5', onTap: () => _step(5)),
      ],
    );
  }
}

class _BpmStepButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _BpmStepButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.raised,
      borderRadius: BorderRadius.circular(AppRadius.chip),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.chip),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Text(
            label,
            style: AppTypography.label.copyWith(color: AppColors.textPrimary),
          ),
        ),
      ),
    );
  }
}

/// Opens a dialog to type an exact BPM value. Returns the clamped value, or
/// null if the dialog was cancelled or the input didn't parse.
Future<int?> editBpmDialog(
  BuildContext context, {
  required int current,
  int min = 40,
  int max = 240,
}) async {
  final controller = TextEditingController(text: '$current');
  final result = await showDialog<int>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: AppColors.surface,
      title: const Text('BPM eingeben'),
      content: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        autofocus: true,
        textAlign: TextAlign.center,
        style: AppTypography.display,
        onSubmitted: (v) => Navigator.pop(ctx, int.tryParse(v)),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Abbrechen'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, int.tryParse(controller.text)),
          child: const Text('OK'),
        ),
      ],
    ),
  );
  if (result == null) return null;
  return result.clamp(min, max);
}
