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
/// shows as many whole rows as fit and turns the page when the cursor
/// leaves them.
class LineView extends StatefulWidget {
  final Rudiment rudiment;

  /// Sheet line shown (0-based).
  final int line;
  final int? activeIndex;

  /// Cursor tick within [line] for kit lines; [activeIndex] is ignored there.
  final int? activeTick;
  final bool showSticking;
  final bool showCounts;

  const LineView({
    super.key,
    required this.rudiment,
    required this.line,
    this.activeIndex,
    this.activeTick,
    this.showSticking = true,
    this.showCounts = true,
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

  SheetGeometry _geometryFor(double contentWidth, int line) {
    final cached = _geo;
    if (cached != null &&
        identical(_geoRudiment, widget.rudiment) &&
        _geoWidth == contentWidth &&
        _geoCounts == widget.showCounts &&
        _geoLine == line) {
      return cached;
    }
    final geo = computeSheetGeometry(widget.rudiment, contentWidth,
        showCounts: widget.showCounts, clefLine: line);
    _geo = geo;
    _geoRudiment = widget.rudiment;
    _geoWidth = contentWidth;
    _geoCounts = widget.showCounts;
    _geoLine = line;
    return geo;
  }

  /// Row of the cursor within [line] (0 before the start).
  int _activeRow(SheetGeometry geo, int line) {
    final kit = line < geo.kitLayouts.length ? geo.kitLayouts[line] : null;
    if (kit != null) return kit.rowOfTick(widget.activeTick ?? 0);
    final placements = geo.layouts[line].placements;
    if (placements.isEmpty) return 0;
    return placements[(widget.activeIndex ?? 0).clamp(0, placements.length - 1)]
        .row;
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
      );
      if (!c.maxHeight.isFinite || height <= c.maxHeight) {
        return SizedBox(height: height, child: sheet);
      }
      // Too tall: a window of whole rows, paged by the cursor.
      final visible =
          ((c.maxHeight - 2 * pad) / geo.rowPitch).floor().clamp(1, rows);
      final top =
          math.min(_activeRow(geo, line) ~/ visible * visible, rows - visible);
      return ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: Container(
          height: visible * geo.rowPitch + 2 * pad,
          color: AppColors.paper,
          child: Stack(
            children: [
              Positioned(
                  top: -top * geo.rowPitch,
                  left: 0,
                  right: 0,
                  child: SizedBox(height: height, child: sheet)),
              // Paper bands hide the slivers of the rows above and below.
              const Positioned(top: 0, left: 0, right: 0, child: _PaperBand()),
              const Positioned(
                  bottom: 0, left: 0, right: 0, child: _PaperBand()),
            ],
          ),
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
