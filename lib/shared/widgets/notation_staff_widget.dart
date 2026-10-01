import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/material.dart';

import '../../app/design_tokens.dart';
import '../../features/lessons/models/rudiment.dart';
import 'count_labels.dart';
import 'sheet_geometry.dart';
import 'staff_layout.dart';

/// Renders a pattern as an engraved five-line drum staff on warm off-white
/// "paper" — black ink on a light field reads better at arm's length than
/// light notation on dark: a percussion clef, time signature, noteheads on
/// the middle line (snare) + stems + beams/flags, accents (>), ghost notes,
/// grace notes, rests, and R/L sticking letters beneath each note.
///
/// Noteheads, clef, time signature, flags, accents and rests are drawn with
/// the Bravura SMuFL music font (real engraving glyphs) rather than
/// hand-drawn Canvas primitives — that's what separates "looks like a real
/// sheet of music" from "looks hand-sketched". Ghost-note heads, grace
/// notes and the augmentation dot stay hand-drawn (simple shapes with no
/// natural glyph substitute at this scale). Letters, line numbers and count
/// syllables use the app's label font (IBM Plex Mono), never the system font.
///
/// This widget draws ONE plain line — the exercise's [Rudiment.sticking] —
/// without a number box or repeat signs, ending in a final barline: the
/// "pattern" box on the info page and the generator preview. Whole sheets
/// (numbered lines, repeats, titles, counts) are [SheetStaffWidget].
///
/// When [activeIndex] is set (during playback), the cursor logic inverts
/// from the rest of the (dark) app: the *field* behind the active note turns
/// amber, the ink stays black.
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

  static const _hPad = 4.0;
  static const _vPad = 16.0;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.of(context).size.width;
        final contentWidth = width - 2 * _hPad;
        final painter = _StaffPainter(
          beats: rudiment.sticking,
          grid: rudiment.gridUnit,
          beatsPerBar: rudiment.beatsPerBar,
          maxWidth: contentWidth,
          rowPitch: sheetRowPitch,
          activeIndex: activeIndex,
        );
        return Container(
          width: double.infinity,
          padding:
              const EdgeInsets.symmetric(horizontal: _hPad, vertical: _vPad),
          decoration: BoxDecoration(
            color: AppColors.paper,
            borderRadius: BorderRadius.circular(AppRadius.card),
          ),
          child: CustomPaint(
            size: Size(contentWidth, painter.computeHeight()),
            painter: painter,
          ),
        );
      },
    );
  }
}

/// A whole sheet (Blattform, spec §4b): one [CustomPaint] per line, stacked
/// on one paper card, every row the same height ([SheetGeometry.rowPitch])
/// so the practice window can slide by whole rows. Each line gets its
/// number box, repeat signs when it repeats, a final barline on the last
/// line, an optional title above and count syllables below.
///
/// [activeLine] / [activeIndex] place the cursor; every other line dims to
/// 45 % (null = nothing dims, the info page). [onLineTap] reports the index
/// of a tapped line.
class SheetStaffWidget extends StatelessWidget {
  final Rudiment rudiment;
  final int? activeLine;
  final int? activeIndex;
  final bool showSticking;
  final bool showCounts;
  final ValueChanged<int>? onLineTap;

  /// Geometry computed by the caller for this content width (the practice
  /// window caches it across the per-note rebuilds); null computes it here.
  final SheetGeometry? geometry;

  const SheetStaffWidget({
    super.key,
    required this.rudiment,
    this.activeLine,
    this.activeIndex,
    this.showSticking = true,
    this.showCounts = true,
    this.onLineTap,
    this.geometry,
  });

  static const hPad = 4.0;
  static const vPad = 16.0;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final width = constraints.maxWidth.isFinite
          ? constraints.maxWidth
          : MediaQuery.of(context).size.width;
      final contentWidth = width - 2 * hPad;
      final geo = geometry ??
          computeSheetGeometry(rudiment, contentWidth, showCounts: showCounts);
      final sheet = rudiment.sheet;
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: hPad, vertical: vPad),
        decoration: BoxDecoration(
          color: AppColors.paper,
          borderRadius: BorderRadius.circular(AppRadius.card),
        ),
        child: Column(
          children: [
            for (var i = 0; i < sheet.length; i++)
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onLineTap == null ? null : () => onLineTap!(i),
                child: CustomPaint(
                  size: Size(
                      contentWidth, geo.layouts[i].rowCount * geo.rowPitch),
                  painter: _StaffPainter(
                    beats: sheet[i].beats,
                    grid: rudiment.gridUnit,
                    beatsPerBar: rudiment.beatsPerBar,
                    maxWidth: contentWidth,
                    rowPitch: geo.rowPitch,
                    activeIndex: activeLine == i ? activeIndex : null,
                    lineNumber: i + 1,
                    repeat: sheet[i].repeat,
                    finalBar: i == sheet.length - 1,
                    showTimeSig: i == 0,
                    title: sheet[i].title,
                    countLabels: showCounts && sheet[i].counts
                        ? countLabelsFor(sheet[i].beats, rudiment.gridUnit,
                            rudiment.beatsPerBar)
                        : null,
                    dimmed: activeLine != null && activeLine != i,
                    showSticking: showSticking,
                  ),
                ),
              ),
          ],
        ),
      );
    });
  }
}

/// Bravura (SMuFL) codepoints used by the drum staff. See smufl.org.
class _Smufl {
  static const clefPerc = '\u{E069}'; // unpitchedPercussionClef1
  static const noteheadBlack = '\u{E0A4}';
  static const noteheadHalf = '\u{E0A3}';
  static const noteheadWhole = '\u{E0A2}';
  static const flag8Up = '\u{E240}';
  static const flag16Up = '\u{E242}';
  static const flag32Up = '\u{E244}';
  static const accent = '\u{E4A0}'; // articAccentAbove
  static const restWhole = '\u{E4E3}';
  static const restHalf = '\u{E4E4}';
  static const restQuarter = '\u{E4E5}';
  static const rest8 = '\u{E4E6}';
  static const rest16 = '\u{E4E7}';
  static const rest32 = '\u{E4E8}';
  static String timeSig(int digit) => String.fromCharCode(0xE080 + digit);
}

/// Paints one line of notation (one or more rows). Knows its place in a
/// sheet: number box, repeat signs, final barline, title, counts, dimming.
class _StaffPainter extends CustomPainter {
  final List<StrokeBeat> beats;
  final NoteGrid grid;
  final int beatsPerBar;
  final double maxWidth;

  /// Height of one row; the staff band itself is always [_staffBandH] high,
  /// extra pitch is the count band below.
  final double rowPitch;
  final int? activeIndex;

  /// Number in the box at the left of the first row; null = no box.
  final int? lineNumber;
  final bool repeat;

  /// Thin + thick barline at the very end (last line of a sheet, or a plain
  /// pattern). Otherwise the line ends in a single barline — or in ":|".
  final bool finalBar;
  final bool showTimeSig;
  final String? title;

  /// Count syllable per note (null entries = none); null = no count row.
  final List<String?>? countLabels;

  /// Whole line at 45 % — it is not the one being played.
  final bool dimmed;
  final bool showSticking;

  _StaffPainter({
    required this.beats,
    required this.grid,
    required this.beatsPerBar,
    required this.maxWidth,
    required this.rowPitch,
    this.activeIndex,
    this.lineNumber,
    this.repeat = false,
    this.finalBar = true,
    this.showTimeSig = true,
    this.title,
    this.countLabels,
    this.dimmed = false,
    this.showSticking = true,
  });

  late final double _leftPad = leftPadFor(numbered: lineNumber != null);
  late final double _rightPad = rightPadFor(repeat: repeat);
  late final double _systemPad =
      systemPadFor(repeat: repeat, graces: leadsWithGraces(beats));

  /// Duration-proportional layout — the single source of horizontal geometry,
  /// beam runs and tuplet groups. Computed once, lazily.
  late final StaffLayout _layout = computeStaffLayout(
    beats: beats,
    grid: grid,
    beatsPerBar: beatsPerBar,
    maxWidth: maxWidth,
    leftPad: _leftPad,
    rightPad: _rightPad,
    systemPad: _systemPad,
    barGap: sheetBarGap,
  );

  // ── Layout metrics ────────────────────────────────────────────────────────
  static const double _staffBandH = sheetRowPitch;

  // Five-line staff geometry.
  static const double _lineGap = 6; // vertical gap between adjacent staff lines
  // Middle (3rd) line = snare = notehead center.

  // Vertical positions within the staff band.
  static const double _accentY = 8; // accents / triplet marks / grace tops
  static const double _stemTopY = 18;
  static const double _midY = 54; // middle staff line / notehead center
  static const double _letterY = 90; // R/L letters (below the bottom line)
  static const double _countY = 104; // count syllables (in the count band)
  static const double _titleY = 69; // line title: under the staff, left,
  // in the free strip between the bottom line (66) and the letters (84)

  static const double _headRx = 6;
  static const double _headRy = 4.6;

  // Width of the cursor field (no longer a grid "cell").
  static const double _cursorW = 22;

  // Right margin added past the last note when drawing a row's staff lines.
  static const double _lineEndMargin = 14;

  // Number box: square at the far left, centred on the middle line.
  static const double _boxSize = 22;

  // ── Colors — black ink on warm off-white paper ──────────────────────────
  static const _staffColor = Color(0x2E17181A); // ink @ 18%
  static const _inkColor = AppColors.ink;
  static const _accentColor = AppColors.paperAccent;
  static const _cursorField = AppColors.live; // amber field behind active note
  static const _cursorLine = AppColors.paperCursorLine;
  static const _ghostColor = Color(0x7317181A); // ink @ 45%
  static const _letterColor = Color(0x9917181A); // ink @ 60%

  /// The app's label font (IBM Plex Mono) for letters, numbers and counts.
  static final TextStyle _labelStyle = AppTypography.label;

  double computeHeight() => _layout.rowCount * rowPitch;

  /// Dims [color] to 45 % when this whole line is not the one playing.
  Color _dim(Color color) =>
      dimmed ? color.withValues(alpha: color.a * 0.45) : color;

  @override
  void paint(Canvas canvas, Size size) {
    for (var row = 0; row < _layout.rowCount; row++) {
      // A lone short row is centred in the card (layout.xOffset); the row
      // is drawn unshifted and moved as a whole, clef and barlines included.
      canvas.save();
      canvas.translate(_layout.xOffset, 0);
      _paintRow(canvas, row);
      canvas.restore();
    }
  }

  void _paintRow(Canvas canvas, int row) {
    final y0 = row * rowPitch; // top of the staff band
    final staffY = y0 + _midY; // middle line = snare = notehead center
    final topLineY = staffY - 2 * _lineGap;
    final bottomLineY = staffY + 2 * _lineGap;
    final isLastRow = row == _layout.rowCount - 1;

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

    // Five staff lines spanning this row's used width (they start right
    // after the number box, or near the card edge without one).
    final staffPaint = Paint()
      ..color = _dim(_staffColor)
      ..strokeWidth = 1.0;
    final lineStartX = _leftPad - sheetLeftPad / 2;
    for (var l = 0; l < 5; l++) {
      final y = topLineY + l * _lineGap;
      canvas.drawLine(Offset(lineStartX, y), Offset(lineEndX, y), staffPaint);
    }

    // Number box, title and time signature belong to the first row only.
    if (row == 0) {
      if (lineNumber != null) _drawNumberBox(canvas, staffY);
      if (title != null) {
        // Under the staff at the left, where nothing else is drawn — above
        // the staff it would sit on the first note's accent.
        _drawTextLeft(canvas, title!,
            Offset(_leftPad - sheetLeftPad / 2, y0 + _titleY), _dim(_inkColor),
            10,
            bold: true);
      }
    }

    // Percussion clef + time signature (time signature only on the first row
    // of the sheet).
    _drawClef(canvas, staffY);
    if (row == 0 && showTimeSig) _drawTimeSignature(canvas, staffY);

    // Start repeat right after the time signature; the system pad keeps the
    // first note (and its grace notes) clear of the dots.
    if (row == 0 && repeat) {
      _drawStartRepeat(canvas, _leftPad + sheetSystemPad + 5, topLineY,
          bottomLineY, staffY);
    }

    // Barlines (full staff height) at each internal bar boundary in the row.
    final barPaint = Paint()
      ..color = _dim(_staffColor)
      ..strokeWidth = 1.0;
    final barWidth = _layout.beatsPerBar * _layout.pxPerQuarter + sheetBarGap;
    for (var barInRow = 1; barInRow <= maxBarInRow; barInRow++) {
      final x = _leftPad + _systemPad + barInRow * barWidth - sheetBarGap / 2;
      canvas.drawLine(Offset(x, topLineY), Offset(x, bottomLineY), barPaint);
    }

    // End of the row: ":|" on the last row of a repeating line, the final
    // barline on the last row of a closing line, a single barline otherwise.
    if (isLastRow && repeat) {
      _drawEndRepeat(canvas, lineEndX, topLineY, bottomLineY, staffY);
    } else if (isLastRow && finalBar) {
      _drawFinalBarline(canvas, lineEndX, topLineY, bottomLineY);
    } else {
      _drawSingleBarline(canvas, lineEndX, topLineY, bottomLineY);
    }

    // Cursor field: the active note's slot turns amber; ink stays black.
    if (activeIndex != null) {
      for (final p in rowPlacements) {
        if (p.index != activeIndex) continue;
        final cx = p.xCenter;
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
                center: Offset(cx, y0 + _staffBandH / 2),
                width: _cursorW,
                height: _staffBandH - 16),
            const Radius.circular(8),
          ),
          Paint()..color = _cursorField,
        );
        final linePaint = Paint()
          ..color = _cursorLine
          ..strokeWidth = 3;
        canvas.drawLine(
            Offset(cx, y0 + 10), Offset(cx, y0 + _staffBandH - 10), linePaint);
        break;
      }
    }

    // Beams / tuplet brackets, then individual note heads / flags / letters.
    _paintBeamsAndNotes(canvas, row, rowPlacements, y0, staffY);
  }

  void _paintBeamsAndNotes(Canvas canvas, int row,
      List<NotePlacement> rowPlacements, double y0, double staffY) {
    final stemTopY = y0 + _stemTopY;

    // Draw beam runs and record which placement indices belong to one, so a
    // beamed note draws a beam rather than an individual flag.
    final beamedIndices = <int>{};
    for (final bg in _layout.beams) {
      if (bg.row != row || bg.beamCount == 0) continue;
      final x0 = _placementAt(bg.startIndex).xCenter + _headRx - 0.5;
      final x1 = _placementAt(bg.endIndex).xCenter + _headRx - 0.5;
      final beamPaint = Paint()
        ..color = _dim(_inkColor)
        ..strokeWidth = 3.0;
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
      _drawTupletBracket(
          canvas, x0, x1, y0 + _accentY, label, _dim(_inkColor));
    }

    // Heads, stems, flags, accents, graces, rests, dots, letters, counts.
    for (final p in rowPlacements) {
      final beat = beats[p.index];
      final resolved = p.resolved;
      final x = p.xCenter;
      final isActive = p.index == activeIndex;

      final noteBeamCount = beamCountFor(resolved.value);

      if (p.isRest) {
        _drawRest(canvas, Offset(x, staffY), resolved.value, _dim(_ghostColor));
        continue;
      }

      final headColor = _dim(beat.isAccent
          ? _accentColor
          : beat.isGhost
              ? _ghostColor
              : _inkColor);

      // Grace notes (drawn small, to the left).
      if (beat.graces.isNotEmpty) {
        _drawGraces(
            canvas, beat.graces, x, staffY, stemTopY, _dim(_ghostColor));
      }

      // Notehead — Bravura glyph for filled/whole/half, hand-drawn hollow
      // oval for ghost notes (no natural glyph substitute at this scale).
      _drawHead(canvas, Offset(x, staffY), headColor,
          ghost: beat.isGhost, active: isActive, value: resolved.value);

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
        _drawAccent(canvas, Offset(x, y0 + _accentY), _dim(_accentColor));
      }

      // Ghost parentheses.
      if (beat.isGhost) {
        final ghostInk = _dim(_ghostColor);
        _drawText(canvas, '(', Offset(x - _headRx - 4, staffY), ghostInk, 14);
        _drawText(canvas, ')', Offset(x + _headRx + 4, staffY), ghostInk, 14);
      }

      // Augmentation dot to the right of the head.
      if (resolved.dotted) {
        _drawDot(canvas, Offset(x, staffY), headColor);
      }

      // R/L letter.
      if (showSticking) {
        final letter = beat.hand == Hand.right ? 'R' : 'L';
        _drawText(canvas, letter, Offset(x, y0 + _letterY), _dim(_letterColor),
            12,
            bold: true);
      }

      // Count syllable under the letter.
      final count = countLabels == null ? null : countLabels![p.index];
      if (count != null) {
        _drawText(
            canvas, count, Offset(x, y0 + _countY), _dim(_letterColor), 10);
      }
    }
  }

  /// Placement for a `beats` index. Placements are appended in beat order, so
  /// `index == list position` and this is a direct lookup.
  NotePlacement _placementAt(int index) => _layout.placements[index];

  // ── Glyph helpers ───────────────────────────────────────────────────────--
  /// Draws a Bravura glyph centred horizontally on [center].x, with its
  /// alphabetic baseline placed on [center].y (SMuFL noteheads/rests/clefs
  /// register on the baseline). [dyStaffSpaces] nudges per-glyph position;
  /// [emScale] overrides the default staff-scaled em (4 staff spaces — a
  /// note drawn at "normal" size occupies one em in a 5-line staff).
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

  /// Neutral percussion clef (Bravura glyph, registered on the staff center).
  void _drawClef(Canvas canvas, double staffY) {
    _drawGlyph(canvas, _Smufl.clefPerc, Offset(_leftPad + 10, staffY),
        _dim(_inkColor.withValues(alpha: 0.9)));
  }

  /// Time signature: [beatsPerBar] over 4 (quarter-note pulse), stacked
  /// digit glyphs.
  void _drawTimeSignature(Canvas canvas, double staffY) {
    final x = _leftPad + 20.0;
    _drawGlyph(canvas, _Smufl.timeSig(beatsPerBar),
        Offset(x, staffY - _lineGap), _dim(_inkColor));
    _drawGlyph(canvas, _Smufl.timeSig(4), Offset(x, staffY + _lineGap),
        _dim(_inkColor));
  }

  /// Line number in a square box at the far left, centred on the middle
  /// line — like the numbered cells of a printed exercise sheet.
  void _drawNumberBox(Canvas canvas, double staffY) {
    final rect = Rect.fromLTWH(
        sheetLeftPad / 2, staffY - _boxSize / 2, _boxSize, _boxSize);
    canvas.drawRect(
        rect,
        Paint()
          ..color = _dim(_inkColor.withValues(alpha: 0.8))
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0);
    _drawText(canvas, '$lineNumber', rect.center, _dim(_inkColor), 12,
        bold: true);
  }

  void _drawHead(Canvas canvas, Offset c, Color color,
      {bool ghost = false, bool active = false, NoteValue? value}) {
    final rx = ghost ? _headRx * 0.78 : _headRx;
    final ry = ghost ? _headRy * 0.78 : _headRy;
    final rect = Rect.fromCenter(center: c, width: rx * 2, height: ry * 2);
    if (ghost) {
      // Outline head: ghost notes read as hollow + parentheses, not a glyph.
      canvas.drawOval(
          rect,
          Paint()
            ..color = color
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.4);
    } else {
      final glyph = switch (value) {
        NoteValue.whole => _Smufl.noteheadWhole,
        NoteValue.half => _Smufl.noteheadHalf,
        _ => _Smufl.noteheadBlack,
      };
      _drawGlyph(canvas, glyph, c, color);
    }
    if (active) {
      // Cursor ring — ties the note to the amber field/line behind it.
      canvas.drawOval(
          rect.inflate(2.5),
          Paint()
            ..color = _cursorLine
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2);
    }
  }

  void _drawFlags(
      Canvas canvas, double stemX, double stemTopY, Color color, int beamCount) {
    final glyph = switch (beamCount) {
      1 => _Smufl.flag8Up,
      2 => _Smufl.flag16Up,
      _ => _Smufl.flag32Up,
    };
    // Flag hangs off the stem top; register near the notehead line then lift.
    _drawGlyph(canvas, glyph, Offset(stemX + 3, stemTopY), color,
        dyStaffSpaces: -1.5);
  }

  void _drawAccent(Canvas canvas, Offset c, Color color) {
    _drawGlyph(canvas, _Smufl.accent, c, color, dyStaffSpaces: 0.3);
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
      canvas.drawOval(rect, Paint()..color = color);
      // tiny stem
      final p = Paint()
        ..color = color
        ..strokeWidth = 1.1;
      canvas.drawLine(
          Offset(gx + 2.6, staffY), Offset(gx + 2.6, stemTopY + 4), p);
    }
    // Slash through grace stems (flam/drag marker).
    final slash = Paint()
      ..color = color
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;
    final firstX = mainX - _headRx - 6 - (n - 1) * gW;
    canvas.drawLine(Offset(firstX - 3, stemTopY + 8),
        Offset(firstX + 8, stemTopY - 2), slash);
  }

  void _drawRest(Canvas canvas, Offset c, NoteValue value, Color color) {
    final glyph = switch (value) {
      NoteValue.whole => _Smufl.restWhole,
      NoteValue.half => _Smufl.restHalf,
      NoteValue.quarter => _Smufl.restQuarter,
      NoteValue.eighth => _Smufl.rest8,
      NoteValue.sixteenth => _Smufl.rest16,
      NoteValue.thirtySecond => _Smufl.rest32,
    };
    _drawGlyph(canvas, glyph, c, color);
  }

  /// Augmentation dot: small filled circle just right of the notehead.
  void _drawDot(Canvas canvas, Offset headCenter, Color color) {
    canvas.drawCircle(
        Offset(headCenter.dx + _headRx + 4, headCenter.dy), 1.6,
        Paint()..color = color);
  }

  /// Tuplet bracket: a thin horizontal line with downward end ticks and a gap
  /// in the middle for the [label] number, centred over the group.
  void _drawTupletBracket(Canvas canvas, double x0, double x1, double y,
      String label, Color color) {
    final mid = (x0 + x1) / 2;
    const gap = 7.0; // half-width of the numeral gap in the bracket line
    // Only draw the connecting line/ticks when the group is wide enough;
    // otherwise the numeral alone marks the tuplet.
    if (x1 - x0 > 2 * gap + 2) {
      final paint = Paint()
        ..color = color.withValues(alpha: color.a * 0.7)
        ..strokeWidth = 1.1
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(Offset(x0, y + 4), Offset(x0, y), paint); // left tick
      canvas.drawLine(Offset(x0, y), Offset(mid - gap, y), paint);
      canvas.drawLine(Offset(mid + gap, y), Offset(x1, y), paint);
      canvas.drawLine(Offset(x1, y), Offset(x1, y + 4), paint); // right tick
    }
    _drawText(canvas, label, Offset(mid, y), color, 11, italic: true);
  }

  // ── Barlines ──────────────────────────────────────────────────────────────
  Paint get _thinBar => Paint()
    ..color = _dim(_inkColor.withValues(alpha: 0.6))
    ..strokeWidth = 1.0;
  Paint get _thickBar => Paint()
    ..color = _dim(_inkColor.withValues(alpha: 0.85))
    ..strokeWidth = 2.2;

  void _drawSingleBarline(Canvas canvas, double x, double top, double bottom) {
    canvas.drawLine(Offset(x, top), Offset(x, bottom), _thinBar);
  }

  /// Final barline: thin + thick — the sheet (or the plain pattern) ends.
  void _drawFinalBarline(Canvas canvas, double x, double top, double bottom) {
    canvas.drawLine(Offset(x - 4, top), Offset(x - 4, bottom), _thinBar);
    canvas.drawLine(Offset(x, top), Offset(x, bottom), _thickBar);
  }

  void _drawRepeatDots(Canvas canvas, double x, double staffY) {
    final paint = Paint()..color = _dim(_inkColor.withValues(alpha: 0.85));
    canvas.drawCircle(Offset(x, staffY - _lineGap / 2), 1.6, paint);
    canvas.drawCircle(Offset(x, staffY + _lineGap / 2), 1.6, paint);
  }

  /// "|:" — thick, thin, dots (dots towards the music).
  void _drawStartRepeat(
      Canvas canvas, double x, double top, double bottom, double staffY) {
    canvas.drawLine(Offset(x - 3, top), Offset(x - 3, bottom), _thickBar);
    canvas.drawLine(Offset(x + 1, top), Offset(x + 1, bottom), _thinBar);
    _drawRepeatDots(canvas, x + 6, staffY);
  }

  /// ":|" — dots, thin, thick at the row end.
  void _drawEndRepeat(
      Canvas canvas, double x, double top, double bottom, double staffY) {
    _drawRepeatDots(canvas, x - 7, staffY);
    canvas.drawLine(Offset(x - 3, top), Offset(x - 3, bottom), _thinBar);
    canvas.drawLine(Offset(x, top), Offset(x, bottom), _thickBar);
  }

  // ── Text ──────────────────────────────────────────────────────────────────
  TextPainter _textPainter(String text, Color color, double size,
      {bool bold = false, bool italic = false}) {
    return TextPainter(
      text: TextSpan(
        text: text,
        style: _labelStyle.copyWith(
          color: color,
          fontSize: size,
          fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
          fontStyle: italic ? FontStyle.italic : FontStyle.normal,
          letterSpacing: 0,
          height: 1.0,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
  }

  /// Text centred on [center].
  void _drawText(Canvas canvas, String text, Offset center, Color color,
      double size,
      {bool bold = false, bool italic = false}) {
    final tp = _textPainter(text, color, size, bold: bold, italic: italic);
    tp.paint(
        canvas, Offset(center.dx - tp.width / 2, center.dy - tp.height / 2));
  }

  /// Text with its top-left corner at [topLeft].
  void _drawTextLeft(Canvas canvas, String text, Offset topLeft, Color color,
      double size,
      {bool bold = false}) {
    final tp = _textPainter(text, color, size, bold: bold);
    tp.paint(canvas, topLeft);
  }

  @override
  bool shouldRepaint(_StaffPainter old) =>
      old.beats != beats ||
      old.grid != grid ||
      old.beatsPerBar != beatsPerBar ||
      old.activeIndex != activeIndex ||
      old.maxWidth != maxWidth ||
      old.rowPitch != rowPitch ||
      old.lineNumber != lineNumber ||
      old.repeat != repeat ||
      old.finalBar != finalBar ||
      old.showTimeSig != showTimeSig ||
      old.title != title ||
      // The label list is rebuilt per build; compare by content so a line
      // with counts does not repaint on every note of another line.
      !listEquals(old.countLabels, countLabels) ||
      old.dimmed != dimmed ||
      old.showSticking != showSticking;
}
