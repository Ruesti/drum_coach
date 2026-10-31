import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../../shared/widgets/kit_layout.dart';
import '../../../shared/widgets/notation_staff_widget.dart';
import '../../../shared/widgets/sheet_geometry.dart';
import '../../lessons/models/rudiment.dart';
import '../../practice/widgets/line_view.dart';
import '../guided_pages.dart';
import '../models/guided_exercise.dart';
import '../run_plan.dart';
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
/// [dimmed] draws the page at 38 % ("coming up").
///
/// Size (Task 6 fix): the row is laid out as compact as one row allows and
/// then SCALED up to the width it gets — the notes grow, they are not
/// spread — at most until the drawn page is [maxStaffHeight] high. All
/// pages of an exercise share one scale (the densest page decides), so the
/// staff does not change size at a section change. Only the band the notes
/// use is shown: the empty paper above and under the row is cut off.
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

  /// Largest scale without a height cap (a page alone in a big box).
  static const maxScale = 4.0;

  /// Bars the row is laid out for: a full page, always.
  int get _rowBars => page.bars >= fullPageBars ? page.bars : fullPageBars;

  static SheetGeometry _geometry(Rudiment r, double layoutWidth, int bars) =>
      computeSheetGeometry(r, layoutWidth - 2 * SheetStaffWidget.hPad,
          showCounts: false,
          clefLine: 0,
          fillWidth: true,
          targetBarsPerRow: bars);

  static bool _oneRow(Rudiment r, double layoutWidth, int bars) =>
      _geometry(r, layoutWidth, bars).layouts[0].rowCount == 1;

  static int _lineBars(ExerciseLine line, NoteGrid grid) {
    final beats = line.isKit ? line.kitVoices.first.beats : line.beats;
    var ticks = 0;
    for (final b in beats) {
      ticks += ticksOfNote(resolveNote(b, grid));
    }
    return (ticks / runTicksPerBar).ceil();
  }

  /// Every distinct full page of [ex] at [bars] bars, as rudiments.
  static Iterable<Rudiment> _allPages(GuidedExercise ex, int bars) sync* {
    for (final s in ex.sections) {
      final n = _lineBars(s.line, ex.gridUnit);
      if (n == 0 || s.bars == 0) continue;
      for (var fb = 0; fb < n; fb += bars) {
        yield rudimentForGuidedLine(
            ex, pageLine(s.line, ex.gridUnit, firstBar: fb, bars: bars));
      }
    }
  }

  // ── Vertical band ────────────────────────────────────────────────────

  static final _bands = <Object, ({double top, double bottom})>{};

  /// The part of the drawn line (in [LineView] units, its top padding
  /// included) that holds ink, the same for every page of [ex]: accents
  /// from the top of the row, down to the feet stems, or to the R/L
  /// letters when a line of the exercise has some.
  static ({double top, double bottom}) bandOf(GuidedExercise ex) =>
      _bands[ex] ??= () {
        const pad = SheetStaffWidget.vPad;
        final kit = ex.sections.any((s) => s.line.isKit);
        if (!kit) return (top: pad - 4, bottom: pad + sheetRowPitch);
        var hand = false;
        var feet = false;
        for (final s in ex.sections) {
          final n = _lineBars(s.line, ex.gridUnit);
          if (n == 0 || !s.line.isKit) continue;
          final r = rudimentForGuidedLine(ex, s.line);
          feet = feet || r.hasFootSides;
          final k = _geometry(r, 4000, n).kitLayouts[0];
          hand = hand || (k?.handLetters.isNotEmpty ?? false);
        }
        // Letter baselines: hands 116 (130 with foot sides), foot sides
        // 114; feet stems end at 96.
        final bottom = feet
            ? (hand ? 138.0 : 122.0)
            : hand
                ? 124.0
                : 102.0;
        return (top: pad - 1, bottom: pad + bottom);
      }();

  // ── Scale ────────────────────────────────────────────────────────────

  static final _scales = <Object, double>{};

  /// The scale all pages of [exercise] share at [width] under [cap]: the
  /// largest that keeps every full page in one row, at most [cap] / band.
  double _scale(double width, double cap) {
    final key = (exercise, fullPageBars, width, cap);
    final hit = _scales[key];
    if (hit != null) return hit;
    final band = bandOf(exercise);
    final bandH = band.bottom - band.top;
    final hi = cap.isFinite ? cap / bandH : maxScale;
    var best = hi;
    for (final r in _allPages(exercise, fullPageBars)) {
      if (_oneRow(r, width / best, fullPageBars)) continue;
      // Largest scale (narrowest layout) that keeps this page in one row.
      var lo = 0.05;
      var up = best;
      for (var i = 0; i < 16; i++) {
        final mid = (lo + up) / 2;
        if (_oneRow(r, width / mid, fullPageBars)) {
          lo = mid;
        } else {
          up = mid;
        }
      }
      best = lo;
    }
    if (_scales.length >= 64) _scales.clear();
    return _scales[key] = best;
  }

  @override
  Widget build(BuildContext context) {
    final rudiment = rudimentForGuidedLine(exercise, page.line);
    final fullBars = _rowBars;
    final band = bandOf(exercise);

    final content = LayoutBuilder(builder: (context, c) {
      final width =
          c.maxWidth.isFinite ? c.maxWidth : MediaQuery.of(context).size.width;
      final cap = maxStaffHeight ??
          (c.maxHeight.isFinite ? c.maxHeight : double.infinity);
      final scale = _scale(width, cap);
      var layoutWidth = width / scale;
      if (page.bars < fullBars) {
        // Bar width of a full page, flush left.
        final full = rudimentForGuidedLine(
            exercise,
            pageLine(
                exercise.sections[page.sectionIndex].line, exercise.gridUnit,
                firstBar: 0, bars: fullBars));
        final l = _geometry(full, layoutWidth, fullBars).layouts[0];
        final barWidth = l.beatsPerBar * l.pxPerQuarter + l.barGap;
        layoutWidth -= (fullBars - page.bars) * barWidth;
      }
      final rowPitch = rudiment.isKit
          ? (rudiment.hasFootSides ? kitRowPitchWithFeet : kitRowPitch)
          : sheetRowPitch;
      final fullH = (rowPitch + 2 * SheetStaffWidget.vPad) * scale;

      return Align(
        alignment: Alignment.topLeft,
        child: SizedBox(
          width: layoutWidth * scale,
          height: (band.bottom - band.top) * scale,
          child: ClipRect(
            child: OverflowBox(
              alignment: Alignment.topLeft,
              minHeight: fullH,
              maxHeight: fullH,
              child: Transform.translate(
                offset: Offset(0, -band.top * scale),
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
            ),
          ),
        ),
      );
    });

    final light = Theme(data: drumCoachTheme, child: content);
    return dimmed ? Opacity(opacity: dimmedOpacity, child: light) : light;
  }
}
