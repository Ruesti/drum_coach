import 'package:flutter/material.dart';

import '../../app/design_tokens.dart';

/// Unified error pattern: icon + sentence + retry. Cards no longer collapse
/// silently and full-screen loads no longer show bare error text.
class ErrorStateWidget extends StatelessWidget {
  const ErrorStateWidget({
    super.key,
    required this.message,
    this.onRetry,
    this.compact = false,
  });

  final String message;
  final VoidCallback? onRetry;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return Padding(
      padding: EdgeInsets.symmetric(
          vertical: compact ? AppSpacing.md : AppSpacing.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.error_outline,
            color: palette.struggled,
            size: compact ? 20 : 32,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            message,
            textAlign: TextAlign.center,
            style: AppTypography.body.copyWith(color: palette.textSecondary),
          ),
          if (onRetry != null) ...[
            const SizedBox(height: AppSpacing.sm),
            TextButton(
              onPressed: onRetry,
              style: TextButton.styleFrom(foregroundColor: palette.accent),
              child: const Text('Try again'),
            ),
          ],
        ],
      ),
    );
  }
}
