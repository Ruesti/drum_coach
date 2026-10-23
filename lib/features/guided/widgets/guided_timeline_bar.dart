import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../app/design_tokens.dart';

enum GuidedSegmentKind { countIn, groove, variation, outro }

/// One section on the timeline: its planned share of the run and, for a
/// variation, its short label ("V2").
class GuidedTimelineSegment {
  const GuidedTimelineSegment({
    required this.kind,
    required this.ms,
    this.label,
  });
  final GuidedSegmentKind kind;
  final double ms;
  final String? label;
}

/// The whole run as one bar (Plan 3a, Task 5): quiet groove segments,
/// accent-tinted variations, the played part filled, a marker at the
/// current place. [Axis.horizontal] for the narrow layout (variation labels
/// under the bar), [Axis.vertical] for the side column (labels to the right,
/// the current section highlighted).
class GuidedTimelineBar extends StatelessWidget {
  const GuidedTimelineBar({
    super.key,
    required this.segments,
    required this.progress,
    this.current,
    this.axis = Axis.horizontal,
  });

  final List<GuidedTimelineSegment> segments;

  /// 0..1 of the whole run.
  final double progress;

  /// Index into [segments] of the section playing; null = none.
  final int? current;
  final Axis axis;

  static const thickness = 8.0;
  static const markerSize = 14.0;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final vertical = axis == Axis.vertical;
      final length = vertical ? c.maxHeight : c.maxWidth;
      final total = segments.fold<double>(0, (a, s) => a + s.ms);
      final p = progress.clamp(0.0, 1.0);
      final at = p * length;

      // Segment spans in px along the bar.
      final spans = <(double, double)>[];
      var pos = 0.0;
      for (final s in segments) {
        final len = total <= 0 ? 0.0 : s.ms / total * length;
        spans.add((pos, pos + len));
        pos += len;
      }

      final bar = CustomPaint(
        size: vertical ? Size(thickness, length) : Size(length, thickness),
        painter: _BarPainter(
          segments: segments,
          spans: spans,
          at: at,
          vertical: vertical,
        ),
      );
      final marker = Container(
        key: const Key('guided-timeline-marker'),
        width: markerSize,
        height: markerSize,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
          border: Border.all(color: PracticeColors.accent, width: 3),
          boxShadow: [
            BoxShadow(
                color: PracticeColors.accent.withValues(alpha: 0.6),
                blurRadius: 10),
          ],
        ),
      );

      final labels = <Widget>[];
      for (var i = 0; i < segments.length; i++) {
        final s = segments[i];
        final isCurrent = i == current;
        final String? text = s.label ??
            (vertical && s.kind == GuidedSegmentKind.outro ? 'End' : null);
        if (text == null) continue;
        final (a, b) = spans[i];
        final mid = (a + b) / 2;
        final isVar = s.kind == GuidedSegmentKind.variation;
        final style = PracticeTypography.label.copyWith(
          fontSize: vertical ? 13 : 11,
          color: isCurrent
              ? PracticeColors.textPrimary
              : isVar
                  ? PracticeColors.accent.withValues(alpha: 0.85)
                  : PracticeColors.textMuted,
        );
        if (vertical) {
          labels.add(Positioned(
            left: thickness + AppSpacing.md,
            right: 0,
            top: mid - 9,
            height: 18,
            child: Row(children: [
              Text(text, style: style),
              if (isCurrent) ...[
                const SizedBox(width: AppSpacing.sm),
                Container(
                  width: 5,
                  height: 5,
                  decoration: const BoxDecoration(
                      color: PracticeColors.accent, shape: BoxShape.circle),
                ),
              ],
            ]),
          ));
        } else {
          labels.add(Positioned(
            left: mid - 20,
            width: 40,
            top: markerSize + 4,
            child: Text(text, textAlign: TextAlign.center, style: style),
          ));
        }
      }

      final markerAt = at - markerSize / 2;
      if (vertical) {
        return SizedBox(
          width: c.maxWidth,
          height: length,
          child: Stack(clipBehavior: Clip.none, children: [
            Positioned(left: 0, top: 0, child: bar),
            ...labels,
            Positioned(
                left: (thickness - markerSize) / 2,
                top: markerAt,
                child: marker),
          ]),
        );
      }
      return SizedBox(
        width: length,
        height: markerSize + 4 + 16,
        child: Stack(clipBehavior: Clip.none, children: [
          Positioned(left: 0, top: (markerSize - thickness) / 2, child: bar),
          ...labels,
          Positioned(left: markerAt, top: 0, child: marker),
        ]),
      );
    });
  }
}

class _BarPainter extends CustomPainter {
  _BarPainter({
    required this.segments,
    required this.spans,
    required this.at,
    required this.vertical,
  });

  final List<GuidedTimelineSegment> segments;
  final List<(double, double)> spans;
  final double at;
  final bool vertical;

  static const _gap = 2.0;

  Color _color(GuidedSegmentKind k, bool played) => switch (k) {
        GuidedSegmentKind.variation => played
            ? PracticeColors.accent
            : PracticeColors.accent.withValues(alpha: 0.32),
        GuidedSegmentKind.countIn => played
            ? Colors.white.withValues(alpha: 0.45)
            : Colors.white.withValues(alpha: 0.10),
        _ => played
            ? Colors.white.withValues(alpha: 0.78)
            : Colors.white.withValues(alpha: 0.16),
      };

  @override
  void paint(Canvas canvas, Size size) {
    final t = vertical ? size.width : size.height;
    final r = Radius.circular(t / 2);
    for (var i = 0; i < segments.length; i++) {
      var (a, b) = spans[i];
      if (i > 0) a += _gap / 2;
      if (i < segments.length - 1) b -= _gap / 2;
      if (b - a <= 0.5) continue;
      Rect rect(double from, double to) => vertical
          ? Rect.fromLTRB(0, from, t, to)
          : Rect.fromLTRB(from, 0, to, t);
      final kind = segments[i].kind;
      canvas.drawRRect(RRect.fromRectAndRadius(rect(a, b), r),
          Paint()..color = _color(kind, false));
      final playedTo = math.min(b, at);
      if (playedTo > a) {
        canvas.drawRRect(RRect.fromRectAndRadius(rect(a, playedTo), r),
            Paint()..color = _color(kind, true));
      }
    }
  }

  @override
  bool shouldRepaint(_BarPainter old) =>
      old.at != at ||
      old.vertical != vertical ||
      !identical(old.segments, segments) ||
      old.spans.length != spans.length;
}
