import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../app/design_tokens.dart';
import '../../../shared/widgets/notation_staff_widget.dart';
import '../../../shared/widgets/sheet_geometry.dart';
import '../../lessons/models/rudiment.dart';

/// The practice screen's notation (Zeilen statt Blatt, 16.10.): only the
/// line being played, on a paper card exactly as high as its rows. The line
/// keeps its number from the sheet and draws its own clef, time signature
/// and repeat signs; a line change swaps the card's content.
///
/// A line taller than the space it gets (a long étude on a short screen)
/// shows as many whole rows as fit, the played row on top.
class LineView extends StatefulWidget {
  final Rudiment rudiment;

  /// Sheet line shown (0-based).
  final int line;
  final int? activeIndex;

  /// Cursor tick within [line] for kit lines; [activeIndex] is ignored there.
  final int? activeTick;
  final bool showSticking;
  final bool showCounts;

  /// The line-number box (off for guided lines, Ruling R3).
  final bool showLineNumber;

  /// Spread the notes over the whole width (guided play screen); the
  /// practice screen keeps the comfort spacing.
  final bool fillWidth;

  /// How the position shows ([SheetStaffWidget.cursorStyle]); the practice
  /// screen keeps the box.
  final CursorStyle cursorStyle;

  /// Playhead stroke in layout units ([SheetStaffWidget.playheadWidth]).
  final double playheadWidth;

  /// Playhead colour ([SheetStaffWidget.playheadColor]).
  final Color playheadColor;

  /// Bars per row the geometry aims for (2 = the practice screen; a guided
  /// four-bar page asks for 4).
  final int targetBarsPerRow;

  /// No paper card, accents in plain ink ([SheetStaffWidget.plain]).
  final bool plain;

  const LineView({
    super.key,
    required this.rudiment,
    required this.line,
    this.activeIndex,
    this.activeTick,
    this.showSticking = true,
    this.showCounts = true,
    this.showLineNumber = true,
    this.fillWidth = false,
    this.cursorStyle = CursorStyle.box,
    this.playheadWidth = playheadLineWidth,
    this.playheadColor = AppColors.accent,
    this.targetBarsPerRow = 2,
    this.plain = false,
  });

  @override
  State<LineView> createState() => _LineViewState();
}

class _LineViewState extends State<LineView> {
  // Geometry is recomputed only when sheet, width, counts or the shown line
  // change — the screen rebuilds this widget on every note (review 01.10.).
  // The line is part of the key because it carries the clef.
  SheetGeometry? _geo;
  Rudiment? _geoRudiment;
  double _geoWidth = -1;
  bool _geoCounts = true;
  int _geoLine = -1;
  bool _geoFill = false;
  int _geoBars = 2;

  SheetGeometry _geometryFor(double contentWidth, int line) {
    final cached = _geo;
    if (cached != null &&
        identical(_geoRudiment, widget.rudiment) &&
        _geoWidth == contentWidth &&
        _geoCounts == widget.showCounts &&
        _geoLine == line &&
        _geoFill == widget.fillWidth &&
        _geoBars == widget.targetBarsPerRow) {
      return cached;
    }
    final geo = computeSheetGeometry(widget.rudiment, contentWidth,
        showCounts: widget.showCounts,
        clefLine: line,
        fillWidth: widget.fillWidth,
        targetBarsPerRow: widget.targetBarsPerRow);
    _geo = geo;
    _geoRudiment = widget.rudiment;
    _geoWidth = contentWidth;
    _geoCounts = widget.showCounts;
    _geoLine = line;
    _geoFill = widget.fillWidth;
    _geoBars = widget.targetBarsPerRow;
    return geo;
  }

  /// Last row the cursor was on, and the line and sheet it belongs to.
  int _lastRow = 0;
  int _lastRowLine = -1;
  Rudiment? _lastRowRudiment;

  /// Row of the cursor within [line]. Without a cursor (before the start,
  /// or the gap after a unit change) the last shown row stays — row 0 on a
  /// new line or sheet.
  int _activeRow(SheetGeometry geo, int line) {
    if (_lastRowLine != line || !identical(_lastRowRudiment, widget.rudiment)) {
      _lastRow = 0;
      _lastRowLine = line;
      _lastRowRudiment = widget.rudiment;
    }
    final rows = geo.layouts[line].rowCount;
    final kit = line < geo.kitLayouts.length ? geo.kitLayouts[line] : null;
    final placements = geo.layouts[line].placements;
    if (kit != null && widget.activeTick != null) {
      _lastRow = kit.rowOfTick(widget.activeTick!);
    } else if (kit == null &&
        widget.activeIndex != null &&
        placements.isNotEmpty) {
      _lastRow =
          placements[widget.activeIndex!.clamp(0, placements.length - 1)].row;
    }
    return _lastRow.clamp(0, rows - 1);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final width =
          c.maxWidth.isFinite ? c.maxWidth : MediaQuery.of(context).size.width;
      final line = widget.line.clamp(0, widget.rudiment.sheet.length - 1);
      final geo = _geometryFor(width - 2 * SheetStaffWidget.hPad, line);
      const pad = SheetStaffWidget.vPad;
      final rows = geo.layouts[line].rowCount;
      final height = rows * geo.rowPitch + 2 * pad;
      final sheet = SheetStaffWidget(
        rudiment: widget.rudiment,
        geometry: geo,
        onlyLine: line,
        activeLine: line,
        activeIndex: widget.activeIndex,
        activeTick: widget.activeTick,
        showSticking: widget.showSticking,
        showCounts: widget.showCounts,
        showLineNumber: widget.showLineNumber,
        fillWidth: widget.fillWidth,
        cursorStyle: widget.cursorStyle,
        playheadWidth: widget.playheadWidth,
        playheadColor: widget.playheadColor,
        targetBarsPerRow: widget.targetBarsPerRow,
        plain: widget.plain,
      );
      if (!c.maxHeight.isFinite || height <= c.maxHeight) {
        return SizedBox(height: height, child: sheet);
      }
      // Too tall: a window of whole rows — the played row on top, the next
      // rows below (as the old sheet window), the last rows stay together.
      final visible =
          ((c.maxHeight - 2 * pad) / geo.rowPitch).floor().clamp(1, rows);
      final top = math.min(_activeRow(geo, line), rows - visible);
      return Container(
        height: visible * geo.rowPitch + 2 * pad,
        clipBehavior: Clip.antiAlias,
        decoration: SheetStaffWidget.cardDecoration,
        child: Stack(
          children: [
            Positioned(
                top: -top * geo.rowPitch,
                left: 0,
                right: 0,
                child: SizedBox(height: height, child: sheet)),
            // Paper bands hide the slivers of the rows above and below.
            const Positioned(top: 0, left: 0, right: 0, child: _PaperBand()),
            const Positioned(bottom: 0, left: 0, right: 0, child: _PaperBand()),
          ],
        ),
      );
    });
  }
}

class _PaperBand extends StatelessWidget {
  const _PaperBand();

  @override
  Widget build(BuildContext context) =>
      Container(height: SheetStaffWidget.vPad, color: AppColors.paper);
}
