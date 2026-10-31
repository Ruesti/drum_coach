import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../../shared/widgets/notation_staff_widget.dart';
import '../../../shared/widgets/sheet_geometry.dart';
import '../../lessons/models/rudiment.dart';
import '../../practice/widgets/line_view.dart';
import '../guided_pages.dart';
import '../models/guided_exercise.dart';
import 'guided_line_view.dart';

/// The playhead of the written-out page: blue, half see-through, so it
/// reads on white without hiding a note.
const guidedPlayheadBlue = Color(0xBF3A8DDE);

/// One page of a guided exercise (Task 4): up to four bars, ALWAYS in a
/// single row over the full width, drawn light (black notes) so it can sit
/// on the white sheet of the play and preview screens.
///
/// [activeTick] is the cursor tick within the PAGE ([guidedPageTick]);
/// null = no playhead. Nothing is coloured, the thin blue playhead is the
/// only cursor. A page shorter than [fullPageBars] (the one-bar outro) is
/// laid out with the bar width of a full page and sits flush left.
/// [dimmed] draws the page at 38 % ("coming up"). The staff is scaled
/// (not re-spaced) to the width it gets, at most to [maxStaffHeight].
class GuidedPageView extends StatelessWidget {
  const GuidedPageView({
    super.key,
    required this.exercise,
    required this.page,
    this.activeTick,
    this.dimmed = false,
    this.maxStaffHeight,
    this.fullPageBars = 4,
  });

  final GuidedExercise exercise;
  final GuidedPage page;
  final int? activeTick;
  final bool dimmed;
  final double? maxStaffHeight;

  /// Bars of a full page (4 wide, 2 narrow): the bar width of every page.
  final int fullPageBars;

  /// Opacity of a dimmed page.
  static const dimmedOpacity = 0.38;

  SheetGeometry _geometry(Rudiment r, double layoutWidth) =>
      computeSheetGeometry(r, layoutWidth - 2 * SheetStaffWidget.hPad,
          showCounts: false,
          clefLine: 0,
          fillWidth: true,
          targetBarsPerRow: _rowBars);

  /// Bars the row is laid out for: a full page, always.
  int get _rowBars => page.bars >= fullPageBars ? page.bars : fullPageBars;

  /// Fits of recent pages: the play screen rebuilds the page on every
  /// playhead step, the shrink loop below must not run each time.
  static final _fits =
      <Object, ({double scale, double layoutWidth, double h})>{};

  /// Scale, layout width and drawn height of the page at [width] under the
  /// height [cap].
  ({double scale, double layoutWidth, double h}) _fit(
      Rudiment rudiment, int fullBars, double width, double cap) {
    final key = (
      exercise,
      page.sectionIndex,
      page.firstBar,
      page.bars,
      fullBars,
      width,
      cap,
    );
    final hit = _fits[key];
    if (hit != null) return hit;

    // A full-width reference page of the same section fixes the bar width.
    final fullRudiment = page.bars == fullBars
        ? rudiment
        : rudimentForGuidedLine(
            exercise,
            pageLine(
                exercise.sections[page.sectionIndex].line, exercise.gridUnit,
                firstBar: 0, bars: fullBars));

    // Largest scale (smallest layout width) that keeps the full page in
    // one row and the staff within the height cap.
    var scale = (width / GuidedLineView.naturalWidth)
        .clamp(1.0, GuidedLineView.maxScale);
    SheetGeometry geo = _geometry(fullRudiment, width / scale);
    double height() =>
        geo.layouts[0].rowCount * geo.rowPitch + 2 * SheetStaffWidget.vPad;
    if (height() * scale > cap) {
      scale = cap / height();
      geo = _geometry(fullRudiment, width / scale);
    }
    for (var i = 0; i < 60 && geo.layouts[0].rowCount > 1; i++) {
      scale *= 0.92;
      geo = _geometry(fullRudiment, width / scale);
    }
    var layoutWidth = width / scale;
    if (page.bars < fullBars) {
      final l = geo.layouts[0];
      final barWidth = l.beatsPerBar * l.pxPerQuarter + l.barGap;
      layoutWidth -= (fullBars - page.bars) * barWidth;
    }
    final fit = (scale: scale, layoutWidth: layoutWidth, h: height() * scale);
    if (_fits.length >= 64) _fits.clear();
    return _fits[key] = fit;
  }

  @override
  Widget build(BuildContext context) {
    final rudiment = rudimentForGuidedLine(exercise, page.line);
    final fullBars = _rowBars;

    final content = LayoutBuilder(builder: (context, c) {
      final width =
          c.maxWidth.isFinite ? c.maxWidth : MediaQuery.of(context).size.width;
      final cap = maxStaffHeight ??
          (c.maxHeight.isFinite ? c.maxHeight : double.infinity);
      final (:scale, :layoutWidth, :h) = _fit(rudiment, fullBars, width, cap);

      return Align(
        alignment: Alignment.topLeft,
        child: SizedBox(
          width: layoutWidth * scale,
          height: h,
          child: FittedBox(
            fit: BoxFit.fitWidth,
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: layoutWidth,
              child: LineView(
                rudiment: rudiment,
                line: 0,
                activeTick: activeTick,
                showCounts: false,
                showLineNumber: false,
                fillWidth: true,
                targetBarsPerRow: _rowBars,
                plain: true,
                cursorStyle: CursorStyle.line,
                playheadWidth: playheadLineWidth / scale,
                playheadColor: guidedPlayheadBlue,
              ),
            ),
          ),
        ),
      );
    });

    final light = Theme(data: drumCoachTheme, child: content);
    return dimmed ? Opacity(opacity: dimmedOpacity, child: light) : light;
  }
}
