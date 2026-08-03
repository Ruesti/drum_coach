import 'package:flutter/material.dart';

import '../../features/lessons/models/rudiment.dart';

/// Renders a pattern as an engraved five-line drum staff: a percussion clef,
/// time signature, noteheads on the middle line (snare) + stems + beams/flags,
/// accents (>), ghost notes, grace notes, rests, and R/L sticking letters
/// beneath each note. When [activeIndex] is set (during playback) a running
/// cursor highlights that note.
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
          beats: rudiment.sticking,
          grid: rudiment.gridUnit,
          beatsPerBar: rudiment.beatsPerBar,
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
  final List<StrokeBeat> beats;
  final NoteGrid grid;
  final int beatsPerBar;
  final int? activeIndex;
  final double maxWidth;

  _StaffPainter({
    required this.beats,
    required this.grid,
    required this.beatsPerBar,
    required this.activeIndex,
    required this.maxWidth,
  });

  // ── Layout metrics ────────────────────────────────────────────────────────
  static const double _cellW = 30;
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

  // ── Colors ────────────────────────────────────────────────────────────────
  static const _staffColor = Color(0x33FFFFFF);
  static const _inkColor = Color(0xFFEDEDED);
  static const _accentColor = Color(0xFFFF7043);
  static const _activeColor = Color(0xFFFFC107);
  static const _ghostColor = Color(0x66FFFFFF);
  static const _letterColor = Color(0x99FFFFFF);

  int get _cellsPerBeat => grid.cellsPerQuarter;
  int get _cellsPerBar => beatsPerBar * _cellsPerBeat;

  /// How many beam lines a single note of [grid] carries (0 = stem only).
  int get _beamCount => switch (grid) {
        NoteGrid.quarter => 0,
        NoteGrid.eighth => 1,
        NoteGrid.triplet => 1,
        NoteGrid.sixteenth => 2,
        NoteGrid.sixteenthTriplet => 2,
        NoteGrid.thirtySecond => 3,
      };

  /// Cells that fit per row, snapped down to a whole number of bars.
  int get _cellsPerRow {
    final usable = maxWidth - _leftPad - _rightPad - _systemPad;
    final bars = (usable / (_cellsPerBar * _cellW + _barGap)).floor();
    if (bars < 1) {
      // Fall back to as many cells as fit, at least one.
      return (usable / _cellW).floor().clamp(1, _cellsPerBar);
    }
    return bars * _cellsPerBar;
  }

  int get _rowCount => (beats.length / _cellsPerRow).ceil().clamp(1, 9999);

  double computeHeight() => _rowCount * _rowH + 8;

  // Horizontal x of a cell within its row (0-based position in the row).
  double _xForPosInRow(int posInRow) {
    final bar = posInRow ~/ _cellsPerBar;
    return _leftPad +
        _systemPad +
        posInRow * _cellW +
        bar * _barGap +
        _cellW / 2;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final cpr = _cellsPerRow;
    for (var row = 0; row < _rowCount; row++) {
      final start = row * cpr;
      final end = (start + cpr).clamp(0, beats.length);
      _paintRow(canvas, row, start, end);
    }
  }

  void _paintRow(Canvas canvas, int row, int start, int end) {
    final baseY = row * _rowH;
    final staffY = baseY + _midY; // middle line = snare = notehead center
    final count = end - start;
    final topLineY = staffY - 2 * _lineGap;
    final bottomLineY = staffY + 2 * _lineGap;

    // Five staff lines spanning this row's used width.
    final lineEndX = _xForPosInRow(count - 1) + _cellW / 2;
    final staffPaint = Paint()
      ..color = _staffColor
      ..strokeWidth = 1.2;
    const lineStartX = _leftPad / 2;
    for (var l = 0; l < 5; l++) {
      final y = topLineY + l * _lineGap;
      canvas.drawLine(
          Offset(lineStartX, y), Offset(lineEndX, y), staffPaint);
    }

    // Percussion clef + time signature (time signature only on the first row).
    _drawClef(canvas, staffY);
    if (row == 0) _drawTimeSignature(canvas, staffY);

    // Barlines (full staff height).
    final barPaint = Paint()
      ..color = _staffColor
      ..strokeWidth = 1.2;
    for (var pos = _cellsPerBar; pos < count; pos += _cellsPerBar) {
      final x = _xForPosInRow(pos) - _cellW / 2 - _barGap / 2;
      canvas.drawLine(
          Offset(x, topLineY), Offset(x, bottomLineY), barPaint);
    }

    // Active cursor band.
    if (activeIndex != null &&
        activeIndex! >= start &&
        activeIndex! < end) {
      final cx = _xForPosInRow(activeIndex! - start);
      final cursorPaint = Paint()..color = _activeColor.withValues(alpha: 0.14);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
              center: Offset(cx, baseY + _rowH / 2),
              width: _cellW - 4,
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
    }

    // Beam groups (per beat) then individual note heads / flags / letters.
    _paintBeamsAndNotes(canvas, row, start, end, baseY, staffY);
  }

  void _paintBeamsAndNotes(Canvas canvas, int row, int start, int end,
      double baseY, double staffY) {
    final count = end - start;
    final stemTopY = baseY + _stemTopY;

    // Determine beam runs within each beat group.
    // A run is a maximal sequence of consecutive non-rest onset cells inside
    // the same beat that carry beams. Rests / beat boundaries break runs.
    final beamedPositions = <int>{}; // positions (in row) that belong to a >=2 run

    if (_beamCount > 0) {
      var p = 0;
      while (p < count) {
        final beat = p ~/ _cellsPerBeat;
        var q = p;
        while (q < count &&
            q ~/ _cellsPerBeat == beat &&
            !beats[start + q].isRest) {
          q++;
        }
        final runLen = q - p;
        if (runLen >= 2) {
          // Draw beam(s) across [p, q-1].
          final x0 = _xForPosInRow(p) + _headRx - 0.5;
          final x1 = _xForPosInRow(q - 1) + _headRx - 0.5;
          final beamPaint = Paint()
            ..color = _inkColor
            ..strokeWidth = 3.2;
          for (var b = 0; b < _beamCount; b++) {
            final y = stemTopY + b * 5.0;
            canvas.drawLine(Offset(x0, y), Offset(x1, y), beamPaint);
          }
          for (var k = p; k < q; k++) {
            beamedPositions.add(k);
          }
          // Triplet bracket number.
          if (grid == NoteGrid.triplet && runLen == 3) {
            _drawText(canvas, '3', Offset((x0 + x1) / 2, baseY + _accentY - 4),
                _inkColor, 11, italic: true);
          }
        }
        p = q == p ? p + 1 : q;
      }
    }

    // Heads, stems, flags, accents, graces, rests, letters.
    for (var i = 0; i < count; i++) {
      final beat = beats[start + i];
      final x = _xForPosInRow(i);
      final isActive = activeIndex == start + i;

      if (beat.isRest) {
        _drawRest(canvas, Offset(x, staffY));
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

      // Notehead.
      _drawHead(canvas, Offset(x, staffY), headColor,
          ghost: beat.isGhost, active: isActive);

      // Stem (up, from right of head).
      final stemX = x + _headRx - 0.6;
      final stemPaint = Paint()
        ..color = headColor
        ..strokeWidth = 1.6;
      canvas.drawLine(
          Offset(stemX, staffY - 1), Offset(stemX, stemTopY), stemPaint);

      // Flag(s) if this note carries beams but isn't part of a beam run.
      if (_beamCount > 0 && !beamedPositions.contains(i)) {
        _drawFlags(canvas, stemX, stemTopY, headColor);
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

      // R/L letter.
      final letter = beat.hand == Hand.right ? 'R' : 'L';
      _drawText(canvas, letter, Offset(x, baseY + _letterY),
          isActive ? _activeColor : _letterColor, 12,
          bold: true);
    }
  }

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

  /// Time signature: [beatsPerBar] over 4 (quarter-note pulse), stacked.
  void _drawTimeSignature(Canvas canvas, double staffY) {
    const x = _leftPad + 30.0;
    _drawText(canvas, '$beatsPerBar', Offset(x, staffY - _lineGap), _inkColor,
        15,
        bold: true);
    _drawText(canvas, '4', Offset(x, staffY + _lineGap), _inkColor, 15,
        bold: true);
  }

  void _drawHead(Canvas canvas, Offset c, Color color,
      {bool ghost = false, bool active = false}) {
    final rx = ghost ? _headRx * 0.78 : _headRx;
    final ry = ghost ? _headRy * 0.78 : _headRy;
    final rect = Rect.fromCenter(center: c, width: rx * 2, height: ry * 2);
    if (ghost) {
      canvas.drawOval(
          rect,
          Paint()
            ..color = color
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.4);
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

  void _drawFlags(Canvas canvas, double stemX, double stemTopY, Color color) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round;
    for (var b = 0; b < _beamCount; b++) {
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

  void _drawRest(Canvas canvas, Offset c) {
    // Simplified rest glyph that scales with the note value.
    final paint = Paint()
      ..color = _ghostColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;
    if (_beamCount == 0) {
      // Quarter rest — squiggle.
      final path = Path()
        ..moveTo(c.dx - 3, c.dy - 9)
        ..lineTo(c.dx + 2, c.dy - 3)
        ..lineTo(c.dx - 3, c.dy + 2)
        ..lineTo(c.dx + 2, c.dy + 8);
      canvas.drawPath(path, paint);
    } else {
      // Eighth/sixteenth rest — dots + slash.
      for (var b = 0; b < _beamCount; b++) {
        final y = c.dy - 6 + b * 6.0;
        canvas.drawCircle(Offset(c.dx - 3, y), 1.6, Paint()..color = _ghostColor);
      }
      canvas.drawLine(Offset(c.dx + 3, c.dy - 8),
          Offset(c.dx - 3, c.dy + 8), paint);
    }
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
      old.activeIndex != activeIndex ||
      old.beats != beats ||
      old.grid != grid ||
      old.beatsPerBar != beatsPerBar ||
      old.maxWidth != maxWidth;
}
