import 'package:flutter/material.dart';

import '../../features/lessons/models/rudiment.dart';
import 'staff_layout.dart';

/// Renders a pattern as an engraved five-line drum staff: a percussion clef,
/// time signature, noteheads on the middle line (snare) + stems + beams/flags,
/// accents (>), ghost notes, grace notes, rests, and R/L sticking letters
/// beneath each note. When [activeIndex] is set (during playback) a running
/// cursor highlights that note.
///
/// Geometry is duration-proportional: horizontal positions, beam runs and
/// tuplet groups come from [computeStaffLayout] so mixed note values
/// (quarters next to sixteenths, triplets, dotted notes) space correctly.
class NotationStaffWidget extends StatelessWidget {
  final Rudiment rudiment;
  final int? activeIndex;

  const NotationStaffWidget({
    super.key,
    required this.rudiment,
    this.activeIndex,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.of(context).size.width;
        final painter = _StaffPainter(
          rudiment: rudiment,
          activeIndex: activeIndex,
          maxWidth: width,
        );
        return CustomPaint(
          size: Size(width, painter.computeHeight()),
          painter: painter,
        );
      },
    );
  }
}

class _StaffPainter extends CustomPainter {
  final Rudiment rudiment;
  final int? activeIndex;
  final double maxWidth;

  _StaffPainter({
    required this.rudiment,
    required this.activeIndex,
    required this.maxWidth,
  });

  /// Duration-proportional layout — the single source of horizontal geometry,
  /// beam runs and tuplet groups. Computed once, lazily.
  late final StaffLayout _layout = computeStaffLayout(
    beats: rudiment.sticking,
    grid: rudiment.gridUnit,
    beatsPerBar: rudiment.beatsPerBar,
    maxWidth: maxWidth,
    leftPad: _leftPad,
    rightPad: _rightPad,
    systemPad: _systemPad,
    barGap: _barGap,
  );

  // ── Layout metrics ────────────────────────────────────────────────────────
  static const double _leftPad = 10;
  static const double _rightPad = 14;
  static const double _barGap = 14; // extra space after a barline
  static const double _rowH = 104;

  // Space reserved at the left of each system for the clef (+ time signature).
  static const double _systemPad = 40;

  // Five-line staff geometry.
  static const double _lineGap = 6; // vertical gap between adjacent staff lines
  // Middle (3rd) line = snare = notehead center.

  // Vertical positions within a row.
  static const double _accentY = 8; // accents / triplet marks / grace tops
  static const double _stemTopY = 18;
  static const double _midY = 54; // middle staff line / notehead center
  static const double _letterY = 90; // R/L letters (below the bottom line)

  static const double _headRx = 6;
  static const double _headRy = 4.6;

  // Width of the translucent active-cursor band (no longer a grid "cell").
  static const double _cursorW = 18;

  // Right margin added past the last note when drawing a row's staff lines.
  static const double _lineEndMargin = 14;

  // ── Colors ────────────────────────────────────────────────────────────────
  static const _staffColor = Color(0x33FFFFFF);
  static const _inkColor = Color(0xFFEDEDED);
  static const _accentColor = Color(0xFFFF7043);
  static const _activeColor = Color(0xFFFFC107);
  static const _ghostColor = Color(0x66FFFFFF);
  static const _letterColor = Color(0x99FFFFFF);

  double computeHeight() => _layout.rowCount * _rowH + 8;

  @override
  void paint(Canvas canvas, Size size) {
    for (var row = 0; row < _layout.rowCount; row++) {
      _paintRow(canvas, row);
    }
  }

  void _paintRow(Canvas canvas, int row) {
    final baseY = row * _rowH;
    final staffY = baseY + _midY; // middle line = snare = notehead center
    final topLineY = staffY - 2 * _lineGap;
    final bottomLineY = staffY + 2 * _lineGap;

    final rowPlacements =
        _layout.placements.where((p) => p.row == row).toList(growable: false);

    // Used width of this row = rightmost notehead + a small margin.
    var maxX = _leftPad + _systemPad;
    var maxBarInRow = 0;
    for (final p in rowPlacements) {
      if (p.xCenter > maxX) maxX = p.xCenter;
      final barInRow = p.bar - row * _layout.barsPerRow;
      if (barInRow > maxBarInRow) maxBarInRow = barInRow;
    }
    final lineEndX = maxX + _lineEndMargin;

    // Five staff lines spanning this row's used width.
    final staffPaint = Paint()
      ..color = _staffColor
      ..strokeWidth = 1.2;
    const lineStartX = _leftPad / 2;
    for (var l = 0; l < 5; l++) {
      final y = topLineY + l * _lineGap;
      canvas.drawLine(Offset(lineStartX, y), Offset(lineEndX, y), staffPaint);
    }

    // Percussion clef + time signature (time signature only on the first row).
    _drawClef(canvas, staffY);
    if (row == 0) _drawTimeSignature(canvas, staffY);

    // Barlines (full staff height) at each internal bar boundary in the row.
    final barPaint = Paint()
      ..color = _staffColor
      ..strokeWidth = 1.2;
    final barWidth = _layout.beatsPerBar * _layout.pxPerQuarter + _barGap;
    for (var barInRow = 1; barInRow <= maxBarInRow; barInRow++) {
      final x = _leftPad + _systemPad + barInRow * barWidth - _barGap / 2;
      canvas.drawLine(Offset(x, topLineY), Offset(x, bottomLineY), barPaint);
    }

    // Active cursor band at the placement whose index == activeIndex.
    if (activeIndex != null) {
      for (final p in rowPlacements) {
        if (p.index != activeIndex) continue;
        final cx = p.xCenter;
        final cursorPaint = Paint()
          ..color = _activeColor.withValues(alpha: 0.14);
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
                center: Offset(cx, baseY + _rowH / 2),
                width: _cursorW,
                height: _rowH - 16),
            const Radius.circular(8),
          ),
          cursorPaint,
        );
        final linePaint = Paint()
          ..color = _activeColor.withValues(alpha: 0.55)
          ..strokeWidth = 1.5;
        canvas.drawLine(Offset(cx, baseY + 10),
            Offset(cx, baseY + _rowH - 10), linePaint);
        break;
      }
    }

    // Beams / tuplet brackets, then individual note heads / flags / letters.
    _paintBeamsAndNotes(canvas, row, rowPlacements, baseY, staffY);
  }

  void _paintBeamsAndNotes(Canvas canvas, int row,
      List<NotePlacement> rowPlacements, double baseY, double staffY) {
    final stemTopY = baseY + _stemTopY;

    // Draw beam runs and record which placement indices belong to one, so a
    // beamed note draws a beam rather than an individual flag.
    final beamedIndices = <int>{};
    for (final bg in _layout.beams) {
      if (bg.row != row || bg.beamCount == 0) continue;
      final x0 = _placementAt(bg.startIndex).xCenter + _headRx - 0.5;
      final x1 = _placementAt(bg.endIndex).xCenter + _headRx - 0.5;
      final beamPaint = Paint()
        ..color = _inkColor
        ..strokeWidth = 3.2;
      for (var b = 0; b < bg.beamCount; b++) {
        final y = stemTopY + b * 5.0;
        canvas.drawLine(Offset(x0, y), Offset(x1, y), beamPaint);
      }
      for (var idx = bg.startIndex; idx <= bg.endIndex; idx++) {
        beamedIndices.add(idx);
      }
    }

    // Tuplet brackets + numbers ("3" triplet, "6" sextuplet) over each group.
    for (final bg in _layout.beams) {
      if (bg.row != row || bg.tuplet == Tuplet.none) continue;
      final x0 = _placementAt(bg.startIndex).xCenter;
      final x1 = _placementAt(bg.endIndex).xCenter;
      final label = bg.tuplet == Tuplet.sextuplet ? '6' : '3';
      _drawTupletBracket(canvas, x0, x1, baseY + _accentY, label);
    }

    // Heads, stems, flags, accents, graces, rests, dots, letters.
    for (final p in rowPlacements) {
      final beat = rudiment.sticking[p.index];
      final resolved = p.resolved;
      final x = p.xCenter;
      final isActive = p.index == activeIndex;
      final noteBeamCount = beamCountFor(resolved.value);

      if (p.isRest) {
        _drawRest(canvas, Offset(x, staffY), noteBeamCount);
        continue;
      }

      final headColor = isActive
          ? _activeColor
          : beat.isAccent
              ? _accentColor
              : beat.isGhost
                  ? _ghostColor
                  : _inkColor;

      // Grace notes (drawn small, to the left).
      if (beat.graces.isNotEmpty) {
        _drawGraces(canvas, beat.graces, x, staffY, stemTopY, headColor);
      }

      // Notehead — open (outline) for whole/half, filled otherwise.
      final isOpen = resolved.value == NoteValue.whole ||
          resolved.value == NoteValue.half;
      _drawHead(canvas, Offset(x, staffY), headColor,
          ghost: beat.isGhost, active: isActive, open: isOpen);

      // Stem (up, from right of head) — whole notes are stemless.
      if (resolved.value != NoteValue.whole) {
        final stemX = x + _headRx - 0.6;
        final stemPaint = Paint()
          ..color = headColor
          ..strokeWidth = 1.6;
        canvas.drawLine(
            Offset(stemX, staffY - 1), Offset(stemX, stemTopY), stemPaint);

        // Flag(s) when this note carries beams but isn't part of a beam run.
        if (noteBeamCount > 0 && !beamedIndices.contains(p.index)) {
          _drawFlags(canvas, stemX, stemTopY, headColor, noteBeamCount);
        }
      }

      // Accent mark.
      if (beat.isAccent) {
        _drawAccent(canvas, Offset(x, baseY + _accentY), headColor);
      }

      // Ghost parentheses.
      if (beat.isGhost) {
        _drawText(canvas, '(', Offset(x - _headRx - 4, staffY), _ghostColor, 14);
        _drawText(canvas, ')', Offset(x + _headRx + 4, staffY), _ghostColor, 14);
      }

      // Augmentation dot to the right of the head.
      if (resolved.dotted) {
        _drawDot(canvas, Offset(x, staffY), headColor);
      }

      // R/L letter.
      final letter = beat.hand == Hand.right ? 'R' : 'L';
      _drawText(canvas, letter, Offset(x, baseY + _letterY),
          isActive ? _activeColor : _letterColor, 12,
          bold: true);
    }
  }

  /// Placement for a `beats` index. Placements are appended in beat order, so
  /// `index == list position` and this is a direct lookup.
  NotePlacement _placementAt(int index) => _layout.placements[index];

  // ── Glyph helpers ───────────────────────────────────────────────────────--
  /// Neutral percussion clef: two thick vertical bars centred on the staff.
  void _drawClef(Canvas canvas, double staffY) {
    final paint = Paint()..color = _inkColor.withValues(alpha: 0.85);
    final top = staffY - _lineGap * 1.3;
    final h = _lineGap * 2.6;
    for (final bx in const [_leftPad + 14.0, _leftPad + 19.0]) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(bx, top, 3.0, h),
          const Radius.circular(1.2),
        ),
        paint,
      );
    }
  }

  /// Time signature: [Rudiment.beatsPerBar] over 4 (quarter-note pulse).
  void _drawTimeSignature(Canvas canvas, double staffY) {
    const x = _leftPad + 30.0;
    _drawText(canvas, '${rudiment.beatsPerBar}', Offset(x, staffY - _lineGap),
        _inkColor, 15,
        bold: true);
    _drawText(canvas, '4', Offset(x, staffY + _lineGap), _inkColor, 15,
        bold: true);
  }

  void _drawHead(Canvas canvas, Offset c, Color color,
      {bool ghost = false, bool active = false, bool open = false}) {
    final rx = ghost ? _headRx * 0.78 : _headRx;
    final ry = ghost ? _headRy * 0.78 : _headRy;
    final rect = Rect.fromCenter(center: c, width: rx * 2, height: ry * 2);
    if (ghost || open) {
      // Outline head: ghost notes and open (whole/half) note values.
      canvas.drawOval(
          rect,
          Paint()
            ..color = color
            ..style = PaintingStyle.stroke
            ..strokeWidth = ghost ? 1.4 : 1.8);
    } else {
      canvas.drawOval(rect, Paint()..color = color);
    }
    if (active) {
      canvas.drawOval(
          rect.inflate(2.5),
          Paint()
            ..color = color.withValues(alpha: 0.4)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5);
    }
  }

  void _drawFlags(
      Canvas canvas, double stemX, double stemTopY, Color color, int beamCount) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round;
    for (var b = 0; b < beamCount; b++) {
      final y = stemTopY + b * 5.0;
      final path = Path()
        ..moveTo(stemX, y)
        ..quadraticBezierTo(stemX + 8, y + 3, stemX + 7, y + 10);
      canvas.drawPath(path, paint);
    }
  }

  void _drawAccent(Canvas canvas, Offset c, Color color) {
    final paint = Paint()
      ..color = _accentColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round;
    final path = Path()
      ..moveTo(c.dx - 5, c.dy - 3)
      ..lineTo(c.dx + 5, c.dy)
      ..lineTo(c.dx - 5, c.dy + 3);
    canvas.drawPath(path, paint);
  }

  void _drawGraces(Canvas canvas, List<Hand> graces, double mainX,
      double staffY, double stemTopY, Color color) {
    // Small noteheads stepping left from the main note.
    const gW = 9.0;
    final n = graces.length;
    for (var i = 0; i < n; i++) {
      final gx = mainX - _headRx - 6 - (n - 1 - i) * gW;
      final rect =
          Rect.fromCenter(center: Offset(gx, staffY), width: 6, height: 4.4);
      canvas.drawOval(rect, Paint()..color = _ghostColor);
      // tiny stem
      final p = Paint()
        ..color = _ghostColor
        ..strokeWidth = 1.1;
      canvas.drawLine(Offset(gx + 2.6, staffY), Offset(gx + 2.6, stemTopY + 4), p);
    }
    // Slash through grace stems (flam/drag marker).
    final slash = Paint()
      ..color = _ghostColor
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;
    final firstX = mainX - _headRx - 6 - (n - 1) * gW;
    canvas.drawLine(Offset(firstX - 3, stemTopY + 8),
        Offset(firstX + 8, stemTopY - 2), slash);
  }

  void _drawRest(Canvas canvas, Offset c, int beamCount) {
    // Simplified rest glyph that scales with the note value.
    final paint = Paint()
      ..color = _ghostColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;
    if (beamCount == 0) {
      // Quarter (or longer) rest — squiggle.
      final path = Path()
        ..moveTo(c.dx - 3, c.dy - 9)
        ..lineTo(c.dx + 2, c.dy - 3)
        ..lineTo(c.dx - 3, c.dy + 2)
        ..lineTo(c.dx + 2, c.dy + 8);
      canvas.drawPath(path, paint);
    } else {
      // Eighth/sixteenth/thirty-second rest — dots (one per beam) + slash.
      for (var b = 0; b < beamCount; b++) {
        final y = c.dy - 6 + b * 6.0;
        canvas.drawCircle(Offset(c.dx - 3, y), 1.6, Paint()..color = _ghostColor);
      }
      canvas.drawLine(Offset(c.dx + 3, c.dy - 8),
          Offset(c.dx - 3, c.dy + 8), paint);
    }
  }

  /// Augmentation dot: small filled circle just right of the notehead.
  void _drawDot(Canvas canvas, Offset headCenter, Color color) {
    canvas.drawCircle(
        Offset(headCenter.dx + _headRx + 4, headCenter.dy), 1.6,
        Paint()..color = color);
  }

  /// Tuplet bracket: a thin horizontal line with downward end ticks and a gap
  /// in the middle for the [label] number, centred over the group.
  void _drawTupletBracket(
      Canvas canvas, double x0, double x1, double y, String label) {
    final mid = (x0 + x1) / 2;
    const gap = 7.0; // half-width of the numeral gap in the bracket line
    // Only draw the connecting line/ticks when the group is wide enough;
    // otherwise the numeral alone marks the tuplet.
    if (x1 - x0 > 2 * gap + 2) {
      final paint = Paint()
        ..color = _inkColor.withValues(alpha: 0.7)
        ..strokeWidth = 1.1
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(Offset(x0, y + 4), Offset(x0, y), paint); // left tick
      canvas.drawLine(Offset(x0, y), Offset(mid - gap, y), paint);
      canvas.drawLine(Offset(mid + gap, y), Offset(x1, y), paint);
      canvas.drawLine(Offset(x1, y), Offset(x1, y + 4), paint); // right tick
    }
    _drawText(canvas, label, Offset(mid, y), _inkColor, 11, italic: true);
  }

  void _drawText(Canvas canvas, String text, Offset center, Color color,
      double size,
      {bool bold = false, bool italic = false}) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: size,
          fontWeight: bold ? FontWeight.bold : FontWeight.normal,
          fontStyle: italic ? FontStyle.italic : FontStyle.normal,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(center.dx - tp.width / 2, center.dy - tp.height / 2));
  }

  @override
  bool shouldRepaint(_StaffPainter old) =>
      old.rudiment != rudiment ||
      old.activeIndex != activeIndex ||
      old.maxWidth != maxWidth;
}
