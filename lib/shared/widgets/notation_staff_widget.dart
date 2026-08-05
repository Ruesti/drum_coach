import 'package:flutter/material.dart';

import '../../features/lessons/models/rudiment.dart';

/// Beat-counter labels for a staff row spanning absolute cells
/// [start, start+count). Returns (indexInRow, beatNumber) for each cell that
/// falls on a quarter-note pulse. Uses the ABSOLUTE cell position so rows that
/// don't begin on a bar boundary (narrow-width wrapping) stay correctly labeled.
List<(int, int)> beatNumbersInRow(
    int start, int count, int cellsPerBeat, int beatsPerBar) {
  final out = <(int, int)>[];
  for (var i = 0; i < count; i++) {
    final pos = start + i;
    if (pos % cellsPerBeat != 0) continue;
    out.add((i, (pos ~/ cellsPerBeat) % beatsPerBar + 1));
  }
  return out;
}

/// Bravura (SMuFL) codepoints used by the drum staff. See smufl.org.
class _Smufl {
  static const clefPerc = '\u{E069}'; // unpitchedPercussionClef1
  static const noteheadBlack = '\u{E0A4}';
  static const parenLeft = '\u{E0F5}'; // noteheadParenthesisLeft
  static const parenRight = '\u{E0F6}'; // noteheadParenthesisRight
  static const flag8Up = '\u{E240}';
  static const flag16Up = '\u{E242}';
  static const flag32Up = '\u{E244}';
  static const accent = '\u{E4A0}'; // articAccentAbove
  static const restQuarter = '\u{E4E5}';
  static const rest8 = '\u{E4E6}';
  static const rest16 = '\u{E4E7}';
  static const rest32 = '\u{E4E8}';
  static String timeSig(int digit) => String.fromCharCode(0xE080 + digit);
}

/// Renders a pattern as an engraved five-line drum staff: a percussion clef,
/// time signature, noteheads on the middle line (snare) + stems + beams/flags,
/// accents (>), ghost notes, grace notes, rests, and R/L sticking letters
/// beneath each note. When [activeIndex] is set (during playback) a running
/// cursor highlights that note.
class NotationStaffWidget extends StatefulWidget {
  final Rudiment rudiment;
  final int? activeIndex;
  final Duration? perCellDuration;
  final bool isPlaying;

  const NotationStaffWidget({
    super.key,
    required this.rudiment,
    this.activeIndex,
    this.perCellDuration,
    this.isPlaying = false,
  });

  @override
  State<NotationStaffWidget> createState() => _NotationStaffWidgetState();
}

class _NotationStaffWidgetState extends State<NotationStaffWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this);
    _syncController();
  }

  @override
  void didUpdateWidget(NotationStaffWidget old) {
    super.didUpdateWidget(old);
    if (old.activeIndex != widget.activeIndex ||
        old.isPlaying != widget.isPlaying ||
        old.perCellDuration != widget.perCellDuration) {
      _syncController();
    }
  }

  /// Re-anchor: whenever a new beat arrives, run the controller 0->1 over one
  /// cell so the cursor glides from this cell to the next. Never run while
  /// stopped (keeps widget tests free of pending timers).
  void _syncController() {
    final per = widget.perCellDuration;
    if (widget.isPlaying && widget.activeIndex != null && per != null &&
        per.inMicroseconds > 0) {
      _ctrl
        ..duration = per
        ..forward(from: 0);
    } else {
      _ctrl.stop();
      _ctrl.value = 0;
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.of(context).size.width;
        return AnimatedBuilder(
          animation: _ctrl,
          builder: (context, _) {
            final anchor = widget.activeIndex;
            final cursorPos = (widget.isPlaying && anchor != null)
                ? anchor + _ctrl.value
                : anchor?.toDouble();
            final painter = _StaffPainter(
              beats: widget.rudiment.sticking,
              grid: widget.rudiment.gridUnit,
              beatsPerBar: widget.rudiment.beatsPerBar,
              activeIndex: anchor,
              cursorPos: cursorPos,
              maxWidth: width,
            );
            return CustomPaint(
              size: Size(width, painter.computeHeight()),
              painter: painter,
            );
          },
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
  final double? cursorPos; // fractional cell position for the gliding cursor
  final double maxWidth;

  _StaffPainter({
    required this.beats,
    required this.grid,
    required this.beatsPerBar,
    required this.activeIndex,
    required this.cursorPos,
    required this.maxWidth,
  });

  // ── Layout metrics ────────────────────────────────────────────────────────
  static const double _cellW = 30;
  static const double _leftPad = 10;
  static const double _rightPad = 14;
  static const double _barGap = 14; // extra space after a barline
  static const double _rowH = 120; // was 104 — room for the beat-number row

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
  static const double _beatNumY = 104; // beat numbers, below the R/L letters

  static const double _headRx = 6;
  static const double _headRy = 4.6;

  // ── Colors ────────────────────────────────────────────────────────────────
  static const _staffColor = Color(0x33FFFFFF);
  static const _inkColor = Color(0xFFEDEDED);
  static const _accentColor = Color(0xFFFF7043);
  static const _activeColor = Color(0xFFFFC107);
  static const _ghostColor = Color(0x66FFFFFF);
  static const _letterColor = Color(0x99FFFFFF);
  static const _beatNumColor = Color(0x77FFC107); // dim amber, the pulse anchor

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

  double _xForFracInRow(double posInRow) {
    final base = posInRow.floor();
    final frac = posInRow - base;
    final x0 = _xForPosInRow(base);
    final x1 = _xForPosInRow(base + 1);
    return x0 + (x1 - x0) * frac;
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

    // Active cursor band (glides between cells when cursorPos is set).
    final cp = cursorPos;
    if (cp != null && cp >= start && cp < end) {
      final cx = _xForFracInRow(cp - start);
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

    // Beat-counter row: one number per quarter-note pulse (the 4/4 reference).
    for (final (i, beatInBar)
        in beatNumbersInRow(start, count, _cellsPerBeat, beatsPerBar)) {
      _drawText(canvas, '$beatInBar', Offset(_xForPosInRow(i), baseY + _beatNumY),
          _beatNumColor, 11, bold: true);
    }
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
        _drawGlyph(canvas, _Smufl.parenLeft,
            Offset(x - _headRx - 3, staffY), _ghostColor);
        _drawGlyph(canvas, _Smufl.parenRight,
            Offset(x + _headRx + 3, staffY), _ghostColor);
      }

      // R/L letter.
      final letter = beat.hand == Hand.right ? 'R' : 'L';
      _drawText(canvas, letter, Offset(x, baseY + _letterY),
          isActive ? _activeColor : _letterColor, 12,
          bold: true);
    }
  }

  // ── Glyph helpers ───────────────────────────────────────────────────────--
  /// Draws a Bravura glyph centred horizontally on [center].x, with its
  /// alphabetic baseline placed on [center].y (SMuFL noteheads/rests register
  /// on the baseline). [dyStaffSpaces] nudges per-glyph; [emScale] overrides
  /// the default staff-scaled em (4 staff spaces).
  void _drawGlyph(Canvas canvas, String glyph, Offset center, Color color,
      {double dyStaffSpaces = 0, double emScale = 4}) {
    final tp = TextPainter(
      text: TextSpan(
        text: glyph,
        style: TextStyle(
          fontFamily: 'Bravura',
          fontSize: emScale * _lineGap,
          color: color,
          height: 1.0,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    final baseline =
        tp.computeDistanceToActualBaseline(TextBaseline.alphabetic);
    tp.paint(
      canvas,
      Offset(center.dx - tp.width / 2,
          center.dy - baseline + dyStaffSpaces * _lineGap),
    );
  }

  void _drawClef(Canvas canvas, double staffY) {
    _drawGlyph(canvas, _Smufl.clefPerc, Offset(_leftPad + 18, staffY),
        _inkColor.withValues(alpha: 0.9));
  }

  /// Time signature: [beatsPerBar] over 4 (quarter-note pulse), stacked.
  void _drawTimeSignature(Canvas canvas, double staffY) {
    const x = _leftPad + 32.0;
    _drawGlyph(canvas, _Smufl.timeSig(beatsPerBar),
        Offset(x, staffY - _lineGap), _inkColor);
    _drawGlyph(canvas, _Smufl.timeSig(4), Offset(x, staffY + _lineGap), _inkColor);
  }

  void _drawHead(Canvas canvas, Offset c, Color color,
      {bool ghost = false, bool active = false}) {
    if (ghost) {
      final rect = Rect.fromCenter(
          center: c, width: _headRx * 1.56, height: _headRy * 1.56);
      canvas.drawOval(
          rect,
          Paint()
            ..color = color
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.4);
    } else {
      _drawGlyph(canvas, _Smufl.noteheadBlack, c, color);
    }
    if (active) {
      _drawGlyph(canvas, _Smufl.noteheadBlack, c,
          color.withValues(alpha: 0.35), emScale: 4.6);
    }
  }

  void _drawFlags(Canvas canvas, double stemX, double stemTopY, Color color) {
    final glyph = switch (_beamCount) {
      1 => _Smufl.flag8Up,
      2 => _Smufl.flag16Up,
      _ => _Smufl.flag32Up,
    };
    // Flag hangs off the stem top; register near the notehead line then lift.
    _drawGlyph(canvas, glyph, Offset(stemX + 3, stemTopY), color,
        dyStaffSpaces: -1.5);
  }

  void _drawAccent(Canvas canvas, Offset c, Color color) {
    _drawGlyph(canvas, _Smufl.accent, c, _accentColor);
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
    final glyph = switch (grid) {
      NoteGrid.quarter => _Smufl.restQuarter,
      NoteGrid.eighth || NoteGrid.triplet => _Smufl.rest8,
      NoteGrid.sixteenth || NoteGrid.sixteenthTriplet => _Smufl.rest16,
      NoteGrid.thirtySecond => _Smufl.rest32,
    };
    _drawGlyph(canvas, glyph, c, _ghostColor);
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
      old.cursorPos != cursorPos ||
      old.beats != beats ||
      old.grid != grid ||
      old.beatsPerBar != beatsPerBar ||
      old.maxWidth != maxWidth;
}
