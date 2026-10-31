import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import '../../practice/backdrop.dart';

/// Photo stage of the play and preview screens (Drumeo-lesson look): the photo
/// uncovered in a 4:3 window at full height in the middle, the same file
/// blurred and darkened at the sides. [child] holds the overlays.
class GuidedStage extends StatelessWidget {
  const GuidedStage({super.key, required this.photo, required this.child});

  final String photo;
  final Widget child;

  static Widget _empty(BuildContext _, Object __, StackTrace? ___) =>
      const SizedBox.shrink();

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        ImageFiltered(
          key: const ValueKey('stage-blur'),
          imageFilter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Image.asset(photo, fit: BoxFit.cover, errorBuilder: _empty),
        ),
        const ColoredBox(color: Color(0x8C000000)),
        LayoutBuilder(builder: (context, c) {
          // 4:3 at full height; a stage narrower than that gets the full
          // width and the photo is cropped taller than 4:3.
          final w = c.maxWidth < c.maxHeight * 4 / 3
              ? c.maxWidth
              : c.maxHeight * 4 / 3;
          return Center(
            child: SizedBox(
              key: const ValueKey('stage-photo'),
              width: w,
              height: c.maxHeight,
              child: Image.asset(
                photo,
                fit: BoxFit.cover,
                alignment: Alignment(0, backdropFocusY(photo)),
                errorBuilder: _empty,
              ),
            ),
          );
        }),
        const Align(
          alignment: Alignment.topCenter,
          child: FractionallySizedBox(
            heightFactor: 0.3,
            widthFactor: 1,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0x99000000), Color(0x00000000)],
                ),
              ),
            ),
          ),
        ),
        child,
      ],
    );
  }
}
