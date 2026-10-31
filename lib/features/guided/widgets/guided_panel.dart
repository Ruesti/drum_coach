import 'package:flutter/material.dart';

import '../../../app/design_tokens.dart';

/// Dark glass card that keeps text readable over the photo.
class GuidedPanel extends StatelessWidget {
  const GuidedPanel({super.key, required this.child, this.padding});
  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) => Container(
        padding: padding ?? const EdgeInsets.all(AppSpacing.cardPadding),
        decoration: BoxDecoration(
          color: PracticeColors.base.withValues(alpha: 0.72),
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: child,
      );
}

/// Small mono caps label at the top of a [GuidedPanel], optional value on
/// the right.
class GuidedPanelLabel extends StatelessWidget {
  const GuidedPanelLabel(this.text, {super.key, this.trailing, this.color});
  final String text;
  final String? trailing;
  final Color? color;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.md),
        child: Row(
          children: [
            Expanded(
              child: Text(text,
                  style: PracticeTypography.label
                      .copyWith(color: color ?? PracticeColors.textMuted)),
            ),
            if (trailing != null)
              Text(trailing!,
                  style: PracticeTypography.label
                      .copyWith(color: PracticeColors.textMuted)),
          ],
        ),
      );
}

/// Title, one-line explanation and a switch in the accent color.
class GuidedSwitchRow extends StatelessWidget {
  const GuidedSwitchRow({
    super.key,
    required this.title,
    this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onChanged(!value),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: PracticeTypography.subtitle),
                  if (subtitle != null)
                    Text(subtitle!,
                        style: PracticeTypography.body.copyWith(
                            fontSize: 13,
                            height: 1.3,
                            color: PracticeColors.textMuted)),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Switch(
              value: value,
              onChanged: onChanged,
              activeThumbColor: Colors.white,
              activeTrackColor: PracticeColors.accent,
            ),
          ],
        ),
      ),
    );
  }
}

/// Big accent button in the practice screen's style (height 56).
class GuidedAccentButton extends StatelessWidget {
  const GuidedAccentButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: FilledButton(
        style: FilledButton.styleFrom(
          backgroundColor: PracticeColors.accent,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.card)),
        ),
        onPressed: onPressed,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 26),
            const SizedBox(width: 10),
            Text(label,
                style:
                    PracticeTypography.subtitle.copyWith(color: Colors.white)),
          ],
        ),
      ),
    );
  }
}

/// Outlined companion of [GuidedAccentButton] (same height). Without a
/// [label] it is a square icon button with [tooltip].
class GuidedGhostButton extends StatelessWidget {
  const GuidedGhostButton({
    super.key,
    required this.icon,
    this.label,
    this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String? label;
  final String? tooltip;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final style = OutlinedButton.styleFrom(
      foregroundColor: PracticeColors.textPrimary,
      backgroundColor: PracticeColors.base.withValues(alpha: 0.45),
      side: const BorderSide(color: PracticeColors.textFaint),
      padding: label == null ? EdgeInsets.zero : null,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card)),
    );
    final Widget button = label == null
        ? OutlinedButton(
            style: style,
            onPressed: onPressed,
            child: Icon(icon, size: 24),
          )
        : OutlinedButton.icon(
            style: style,
            onPressed: onPressed,
            icon: Icon(icon, size: 20),
            label: Text(label!, style: PracticeTypography.subtitle),
          );
    return SizedBox(
      height: 56,
      width: label == null ? 56 : null,
      child:
          tooltip == null ? button : Tooltip(message: tooltip, child: button),
    );
  }
}

/// Desktop key hints under the controls: two balanced lines (the text
/// carries the line break), at the design label size (12), never shrunk.
class GuidedKeyHint extends StatelessWidget {
  const GuidedKeyHint(this.text, {super.key});
  final String text;

  static TextStyle get style => PracticeTypography.label
      .copyWith(fontSize: 12, color: PracticeColors.textMuted);

  /// Width [text] needs on its (at most two) lines.
  static double widthOf(BuildContext context, String text) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
      textScaler: MediaQuery.textScalerOf(context),
      maxLines: 2,
    )..layout();
    final w = tp.width;
    tp.dispose();
    return w;
  }

  @override
  Widget build(BuildContext context) => Text(
        text,
        key: const Key('guided-key-hint'),
        maxLines: 2,
        textAlign: TextAlign.center,
        style: style,
      );
}
