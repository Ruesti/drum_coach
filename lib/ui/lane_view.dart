import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../content/analysis.dart';
import '../measure/hit_matcher.dart';
import '../measure/kit.dart';
import '../measure/session_record.dart';
import '../measure/targets.dart';

const laneEarly = Color(0xFF42A5F5);
const laneOnTime = Color(0xFF66BB6A);
const laneLate = Color(0xFFFFA726);
const laneMissed = Color(0xFFEF5350);
const laneExtra = Color(0xFF9E9E9E);

/// Early (< −15 ms) blue, on time (|d| ≤ 15 ms) green, late (> 15 ms) orange.
Color deviationColor(double deviationMs) => deviationMs < -15
    ? laneEarly
    : deviationMs > 15
        ? laneLate
        : laneOnTime;

/// 3 px at velocity 1 up to 8 px at 127.
double dotRadius(int velocity) => 3 + (velocity.clamp(1, 127) - 1) * 5 / 126;

/// Deviations are drawn this many times larger than the time axis.
const double deviationScale = 4;

enum LaneMarkerKind { target, hit, missed, wrongInstrument, extra }

/// One drawn mark. [bar] is 0-based (−1 for extras, which have no target);
/// [rect] is what a tap hits.
class LaneMarker {
  const LaneMarker({
    required this.kind,
    required this.lane,
    required this.center,
    required this.size,
    required this.color,
    this.bar = -1,
    this.deviationMs,
    this.velocity,
    this.label,
  });

  final LaneMarkerKind kind;
  final Voice lane;
  final Offset center;

  /// Radius for dots/circles, half side for squares and ×.
  final double size;
  final Color color;
  final int bar;
  final double? deviationMs;
  final int? velocity;

  /// Instrument label for wrong instruments and extras.
  final String? label;

  Rect get rect => Rect.fromCircle(center: center, radius: size);
}

const _voiceNames = {
  Voice.hiHat: 'hi-hat',
  Voice.snare: 'snare',
  Voice.kick: 'kick',
};

/// Row for a stroke on an instrument that is not one of the three voices:
/// cymbals with the hi-hat, pedal with the kick, everything else with the
/// snare.
Voice laneForInstrument(KitInstrument i) =>
    voiceOf(i) ??
    switch (i) {
      KitInstrument.crash1 ||
      KitInstrument.crash2 ||
      KitInstrument.ride ||
      KitInstrument.rideBell ||
      KitInstrument.china ||
      KitInstrument.splash =>
        Voice.hiHat,
      KitInstrument.hiHatPedal => Voice.kick,
      _ => Voice.snare,
    };

/// Text shown when a marker is tapped; bar is 1-based.
String describeMarker(LaneMarker m) {
  String ms(double d) => '${d < 0 ? '-' : '+'}${d.abs().toStringAsFixed(1)} ms';
  final voice = _voiceNames[m.lane]!;
  return switch (m.kind) {
    LaneMarkerKind.hit =>
      'bar ${m.bar + 1} · $voice · ${ms(m.deviationMs!)} · vel ${m.velocity}',
    LaneMarkerKind.wrongInstrument => 'bar ${m.bar + 1} · $voice · '
        '${m.label} instead · ${ms(m.deviationMs!)} · vel ${m.velocity}',
    LaneMarkerKind.missed => 'bar ${m.bar + 1} · $voice · missed',
    LaneMarkerKind.extra => 'extra · ${m.label} · vel ${m.velocity}',
    LaneMarkerKind.target => 'bar ${m.bar + 1} · $voice · target',
  };
}

/// Pure geometry of the lane view: rows hi-hat / snare / kick, x = time with
/// the whole exercise across the width (1 bar = width / bars); hits are
/// shifted by [deviationScale] × their deviation.
class LaneLayout {
  LaneLayout._(this.size, this.markers);

  static const double padX = 10;

  final Size size;
  final List<LaneMarker> markers;

  factory LaneLayout.fromAnalysis(
      SessionAnalysis a, SessionRecord record, Size size) {
    final ex = a.exercise;
    final laneH = size.height / Voice.values.length;
    double rowY(Voice v) => laneH * (v.index + 0.5);
    final scale = (size.width - 2 * padX) / (ex.bars * ex.barMs);
    final quarterMs = 60000 / ex.bpm;
    final firstTick = ex.barHits.map((h) => h.tick).reduce(math.min);
    final firstBeatMs = a.targets.isEmpty
        ? 0.0
        : a.targets.map((t) => t.timeMs).reduce(math.min) -
            firstTick * quarterMs / ticksPerQuarter;
    double x(double timeMs) => padX + (timeMs - firstBeatMs) * scale;

    final markers = <LaneMarker>[];
    for (final o in a.match.targets) {
      final t = o.target;
      final tx = x(t.timeMs);
      markers.add(LaneMarker(
        kind: LaneMarkerKind.target,
        lane: t.voice,
        center: Offset(tx, rowY(t.voice)),
        size: laneH * 0.3,
        color: laneExtra,
        bar: t.bar,
      ));
      final stroke =
          o.strokeIndex == null ? null : record.strokes[o.strokeIndex!];
      final shifted = Offset(
          tx + (o.deviationMs ?? 0) * deviationScale * scale, rowY(t.voice));
      markers.add(switch (o.kind) {
        HitKind.hit => LaneMarker(
            kind: LaneMarkerKind.hit,
            lane: t.voice,
            center: shifted,
            size: dotRadius(stroke!.velocity),
            color: deviationColor(o.deviationMs!),
            bar: t.bar,
            deviationMs: o.deviationMs,
            velocity: stroke.velocity,
          ),
        HitKind.wrongInstrument => LaneMarker(
            kind: LaneMarkerKind.wrongInstrument,
            lane: t.voice,
            center: shifted,
            size: 4,
            color: laneLate,
            bar: t.bar,
            deviationMs: o.deviationMs,
            velocity: stroke!.velocity,
            label: stroke.instrument.label,
          ),
        HitKind.missed => LaneMarker(
            kind: LaneMarkerKind.missed,
            lane: t.voice,
            center: Offset(tx, rowY(t.voice)),
            size: 5,
            color: laneMissed,
            bar: t.bar,
          ),
      });
    }
    final latency = record.latencyOffsetMs ?? 0;
    for (final i in a.match.extraStrokeIndices) {
      final s = record.strokes[i];
      final lane = laneForInstrument(s.instrument);
      markers.add(LaneMarker(
        kind: LaneMarkerKind.extra,
        lane: lane,
        center: Offset(x(s.timeMs - latency), rowY(lane)),
        size: 4,
        color: laneExtra,
        velocity: s.velocity,
        label: s.instrument.label,
      ));
    }
    return LaneLayout._(size, markers);
  }

  /// The tappable marker (not a target tick) nearest to [p] whose rect,
  /// widened by 3 px, contains [p].
  LaneMarker? markerAt(Offset p) {
    LaneMarker? best;
    var bestDist = double.infinity;
    for (final m in markers) {
      if (m.kind == LaneMarkerKind.target) continue;
      if (!m.rect.inflate(3).contains(p)) continue;
      final d = (m.center - p).distanceSquared;
      if (d < bestDist) {
        best = m;
        bestDist = d;
      }
    }
    return best;
  }
}

class LanePainter extends CustomPainter {
  LanePainter(this.layout, {this.selected});

  final LaneLayout layout;
  final LaneMarker? selected;

  @override
  void paint(Canvas canvas, Size size) {
    final laneH = size.height / Voice.values.length;
    final line = Paint()
      ..color = laneExtra.withValues(alpha: 0.3)
      ..strokeWidth = 1;
    for (final v in Voice.values) {
      final y = laneH * (v.index + 0.5);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), line);
    }
    final lastLabelRight = <Voice, double>{};
    for (final m in layout.markers) {
      final c = m.center;
      final s = m.size;
      final stroke = Paint()
        ..color = m.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      switch (m.kind) {
        case LaneMarkerKind.target:
          canvas.drawLine(
              c.translate(0, -s),
              c.translate(0, s),
              Paint()
                ..color = m.color
                ..strokeWidth = 1);
        case LaneMarkerKind.hit:
          canvas.drawCircle(c, s, Paint()..color = m.color);
        case LaneMarkerKind.missed:
          canvas.drawCircle(c, s, stroke);
        case LaneMarkerKind.wrongInstrument:
          canvas.drawRect(
              Rect.fromCircle(center: c, radius: s), Paint()..color = m.color);
          final right = _label(canvas, m, lastLabelRight[m.lane]);
          if (right != null) lastLabelRight[m.lane] = right;
        case LaneMarkerKind.extra:
          canvas.drawLine(c.translate(-s, -s), c.translate(s, s), stroke);
          canvas.drawLine(c.translate(-s, s), c.translate(s, -s), stroke);
      }
    }
    final sel = selected;
    if (sel != null) {
      canvas.drawCircle(
          sel.center,
          sel.size + 3,
          Paint()
            ..color = Colors.white
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5);
    }
  }

  /// Instrument label under a wrong-instrument square, skipped where it
  /// would overlap the previous label of the lane. Returns its right edge.
  double? _label(Canvas canvas, LaneMarker m, double? lastRight) {
    final tp = TextPainter(
      text: TextSpan(
          text: m.label, style: TextStyle(color: m.color, fontSize: 9)),
      textDirection: TextDirection.ltr,
    )..layout();
    final left = m.center.dx - tp.width / 2;
    if (lastRight != null && left < lastRight + 4) return null;
    tp.paint(canvas, Offset(left, m.center.dy + m.size + 1));
    return left + tp.width;
  }

  @override
  bool shouldRepaint(LanePainter old) =>
      old.layout != layout || old.selected != selected;
}

/// The lane view of one session: targets, hits, misses, wrong instruments
/// and extras per voice; tap a mark for its numbers.
class LaneView extends StatefulWidget {
  const LaneView({super.key, required this.analysis, required this.record});

  final SessionAnalysis analysis;
  final SessionRecord record;

  static const double height = 150;

  @override
  State<LaneView> createState() => _LaneViewState();
}

class _LaneViewState extends State<LaneView> {
  LaneLayout? _layout;
  LaneMarker? _selected;

  LaneLayout _layoutFor(Size size) {
    final l = _layout;
    if (l != null && l.size == size) return l;
    _selected = null;
    return _layout =
        LaneLayout.fromAnalysis(widget.analysis, widget.record, size);
  }

  @override
  void didUpdateWidget(LaneView old) {
    super.didUpdateWidget(old);
    if (old.analysis != widget.analysis || old.record != widget.record) {
      _layout = null;
      _selected = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final uncalibrated = widget.record.latencyOffsetMs == null;
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            SizedBox(
              width: 56,
              height: LaneView.height,
              child: Column(
                children: [
                  for (final v in Voice.values)
                    Expanded(
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(_voiceNames[v]!,
                            style: TextStyle(color: muted, fontSize: 12)),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: LayoutBuilder(builder: (context, c) {
                final layout = _layoutFor(Size(c.maxWidth, LaneView.height));
                return Stack(
                  children: [
                    GestureDetector(
                      onTapUp: (d) => setState(
                          () => _selected = layout.markerAt(d.localPosition)),
                      child: CustomPaint(
                        size: layout.size,
                        painter: LanePainter(layout, selected: _selected),
                      ),
                    ),
                    if (uncalibrated)
                      Positioned.fill(
                        child: IgnorePointer(
                          child: Center(
                            child: Text('uncalibrated',
                                style: TextStyle(
                                    color: laneExtra.withValues(alpha: 0.6),
                                    fontSize: 32,
                                    fontWeight: FontWeight.w700)),
                          ),
                        ),
                      ),
                  ],
                );
              }),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          _selected == null
              ? 'Tap a mark for its numbers'
              : describeMarker(_selected!),
          style: TextStyle(color: _selected == null ? muted : null),
        ),
      ],
    );
  }
}
