import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../practice/backdrop.dart';

/// Practice-screen look for the guided screens: a random photo, a dark scrim
/// (lighter while configuring, darker while playing) and the child inside
/// the dark practice theme.
class GuidedBackdrop extends StatefulWidget {
  const GuidedBackdrop({
    super.key,
    required this.playing,
    required this.child,
    this.photo,
  });

  final bool playing;
  final Widget child;

  /// Fixed photo for tests/goldens; otherwise one is picked per screen open.
  final String? photo;

  @override
  State<GuidedBackdrop> createState() => _GuidedBackdropState();
}

class _GuidedBackdropState extends State<GuidedBackdrop> {
  late final String _photo = widget.photo ?? nextBackdrop();

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: drumCoachPracticeTheme,
      child: Material(
        color: Colors.transparent,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              _photo,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const SizedBox.shrink(),
            ),
            AnimatedContainer(
              key: const ValueKey('guided-scrim'),
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeOut,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: widget.playing
                      ? const [
                          Color(0x4D101010),
                          Color(0x99101010),
                          Color(0xE0101010),
                        ]
                      : const [
                          Color(0x26101010),
                          Color(0x66101010),
                          Color(0xD9101010),
                        ],
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
            ),
            SafeArea(child: widget.child),
          ],
        ),
      ),
    );
  }
}
