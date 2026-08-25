import 'package:flutter/material.dart';

import '../../app/design_tokens.dart';

/// Pulsing beat indicator. Diameter is deliberately large (160px full-screen,
/// 120px compact) — at 60cm, in the corner of the eye, area change reads
/// better than edge detail. Timing stays 220ms: 30% scale up (easeOut),
/// 70% back down (easeIn), opacity 50→100→50%.
class BeatIndicator extends StatefulWidget {
  const BeatIndicator({
    super.key,
    required this.isPlaying,
    required this.isAccent,
    required this.beatTrigger,
    this.diameter = 160,
    this.beatNumber,
    this.child,
    this.onTap,
  });

  final bool isPlaying;
  final bool isAccent;

  /// Changes value (e.g. currentBeatIndex) whenever a new beat fires.
  final Object? beatTrigger;
  final double diameter;

  /// Shown centered inside the circle, e.g. the running beat count.
  final int? beatNumber;

  /// Overlay content (e.g. a play/stop icon) drawn on top of the circle.
  final Widget? child;
  final VoidCallback? onTap;

  @override
  State<BeatIndicator> createState() => _BeatIndicatorState();
}

class _BeatIndicatorState extends State<BeatIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
    _scale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.45)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 30,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.45, end: 1.0)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 70,
      ),
    ]).animate(_controller);
    _opacity = TweenSequence<double>([
      TweenSequenceItem(tween: Tween<double>(begin: 0.5, end: 1.0), weight: 30),
      TweenSequenceItem(tween: Tween<double>(begin: 1.0, end: 0.5), weight: 70),
    ]).animate(_controller);
  }

  @override
  void didUpdateWidget(covariant BeatIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPlaying && widget.beatTrigger != oldWidget.beatTrigger) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final baseColor = widget.isAccent
        ? AppColors.accent
        : AppColors.textPrimary.withValues(alpha: 0.7);
    final idleColor = AppColors.textPrimary.withValues(alpha: 0.15);

    Widget circle = AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Transform.scale(
          scale: widget.isPlaying ? _scale.value : 1.0,
          child: Container(
            width: widget.diameter,
            height: widget.diameter,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: widget.isPlaying
                  ? baseColor.withValues(alpha: _opacity.value)
                  : idleColor,
              boxShadow: widget.isPlaying && widget.isAccent
                  ? [
                      BoxShadow(
                        color: AppColors.accent.withValues(alpha: 0.4),
                        blurRadius: 20,
                        spreadRadius: 4,
                      ),
                    ]
                  : null,
            ),
            child: widget.child ??
                (widget.beatNumber != null
                    ? Text(
                        widget.isPlaying ? '${widget.beatNumber}' : '—',
                        style: AppTypography.display,
                      )
                    : null),
          ),
        );
      },
    );

    if (widget.onTap != null) {
      circle = GestureDetector(onTap: widget.onTap, child: circle);
    }
    return circle;
  }
}
