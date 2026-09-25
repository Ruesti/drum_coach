import 'package:flutter/material.dart';

import '../../app/design_tokens.dart';

enum AppCardVariant { standard, raised, error }

/// Shared card surface. Replaces the per-screen duplicated
/// `Container(decoration: BoxDecoration(color: Color(0xFF1E1E1E), ...))`
/// pattern with one consistent, tappable surface.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.variant = AppCardVariant.standard,
    this.onTap,
    this.padding = const EdgeInsets.all(AppSpacing.cardPadding),
  });

  final Widget child;
  final AppCardVariant variant;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;

  Color _background(AppPalette p) {
    switch (variant) {
      case AppCardVariant.standard:
        return p.surface;
      case AppCardVariant.raised:
        return p.raised;
      case AppCardVariant.error:
        return p.struggled.withValues(alpha: 0.12);
    }
  }

  BoxBorder? _border(AppPalette p) {
    if (variant == AppCardVariant.error) {
      return Border.all(color: p.struggled.withValues(alpha: 0.4));
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final content = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: _background(palette),
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: _border(palette),
      ),
      child: child,
    );

    if (onTap == null) return content;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: content,
      ),
    );
  }
}
