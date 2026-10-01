import 'package:flutter/material.dart';

import '../../../app/design_tokens.dart';
import '../../../shared/widgets/notation_staff_widget.dart';
import '../../../shared/widgets/sheet_geometry.dart';
import '../../lessons/models/rudiment.dart';

/// Paper margin above the first and below the last visible row — the same
/// 16 px the sheet card itself uses.
const double sheetWindowPad = 16;

/// The row just below the old top slides up; anything else (loop restart,
/// line change, mode change) is a new page and jumps.
bool slidesUp(int oldTop, int newTop) => newTop == oldTop + 1;

/// Rows the window shows: up to [preferred], never more than the sheet has,
/// at least [minimum] when the sheet has that many.
int visibleRowsFor({
  required double maxHeight,
  required double rowPitch,
  required int totalRows,
  int preferred = 4,
  int minimum = 2,
}) {
  if (totalRows <= minimum) return totalRows;
  final fit = maxHeight.isFinite
      ? ((maxHeight - 2 * sheetWindowPad) / rowPitch).floor()
      : preferred;
  return fit.clamp(minimum, preferred).clamp(minimum, totalRows);
}

/// Fixed-height window over a sheet (spec §4c): the active row is always the
/// top row, the next rows wait below (dimmed by the sheet widget), and the
/// content slides up one row at every row boundary. Sheet mode shows the
/// first rows again after the last one — the loop goes on.
class SheetWindow extends StatefulWidget {
  final Rudiment rudiment;
  final int activeLine;
  final int? activeIndex;
  final bool sheetMode;
  final bool showSticking;
  final bool showCounts;
  final ValueChanged<int>? onLineTap;
  final int preferredRows;

  const SheetWindow({
    super.key,
    required this.rudiment,
    required this.activeLine,
    this.activeIndex,
    this.sheetMode = false,
    this.showSticking = true,
    this.showCounts = true,
    this.onLineTap,
    this.preferredRows = 4,
  });

  @override
  State<SheetWindow> createState() => _SheetWindowState();
}

class _SheetWindowState extends State<SheetWindow>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 180), value: 1);

  /// Row on top (the played one) and the row a running slide started from.
  int _topRow = 0;
  double _fromRow = 0;
  SheetGeometry? _geo;

  int _rowFor(SheetGeometry geo) {
    final line = widget.activeLine.clamp(0, geo.layouts.length - 1);
    final notes = geo.layouts[line].placements.length;
    final index = (widget.activeIndex ?? 0).clamp(0, notes - 1);
    return geo.rowOf(line, index);
  }

  @override
  void didUpdateWidget(covariant SheetWindow old) {
    super.didUpdateWidget(old);
    final geo = _geo;
    if (geo == null ||
        old.rudiment != widget.rudiment ||
        old.showCounts != widget.showCounts) {
      return; // build recomputes the geometry and jumps
    }
    final next = _rowFor(geo);
    if (next == _topRow) return;
    if (slidesUp(_topRow, next)) {
      _fromRow = _topRow.toDouble();
      _topRow = next;
      _anim.forward(from: 0);
    } else {
      _topRow = next;
      _fromRow = next.toDouble();
    }
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final width = c.maxWidth.isFinite
          ? c.maxWidth
          : MediaQuery.of(context).size.width;
      final geo = computeSheetGeometry(
          widget.rudiment, width - 2 * SheetStaffWidget.hPad,
          showCounts: widget.showCounts);
      _geo = geo;
      // Anything didUpdateWidget did not animate (first build, a changed
      // sheet or width) lands on its row at once.
      final next = _rowFor(geo);
      if (next != _topRow) {
        _topRow = next;
        _fromRow = next.toDouble();
      }
      final rows = visibleRowsFor(
          maxHeight: c.maxHeight,
          rowPitch: geo.rowPitch,
          totalRows: geo.totalRows,
          preferred: widget.preferredRows);
      final height = rows * geo.rowPitch + 2 * sheetWindowPad;
      final sheet = SheetStaffWidget(
        rudiment: widget.rudiment,
        activeLine: widget.activeLine,
        activeIndex: widget.activeIndex,
        showSticking: widget.showSticking,
        showCounts: widget.showCounts,
        onLineTap: widget.onLineTap,
      );
      return ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: ClipRect(
          child: Container(
            height: height,
            color: AppColors.paper,
            child: AnimatedBuilder(
              animation: _anim,
              builder: (context, _) {
                final t = Curves.easeOutCubic.transform(_anim.value);
                final row = _fromRow + (_topRow - _fromRow) * t;
                final dy = -row * geo.rowPitch;
                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned(top: dy, left: 0, right: 0, child: sheet),
                    if (widget.sheetMode)
                      Positioned(
                        top: dy + geo.height,
                        left: 0,
                        right: 0,
                        child: SheetStaffWidget(
                          rudiment: widget.rudiment,
                          activeLine: -1, // preview: every line dimmed
                          showSticking: widget.showSticking,
                          showCounts: widget.showCounts,
                        ),
                      ),
                    // Paper bands hide the slivers of the rows above and
                    // below the window while the content slides.
                    const Positioned(
                        top: 0, left: 0, right: 0, child: _PaperBand()),
                    const Positioned(
                        bottom: 0, left: 0, right: 0, child: _PaperBand()),
                  ],
                );
              },
            ),
          ),
        ),
      );
    });
  }
}

class _PaperBand extends StatelessWidget {
  const _PaperBand();

  @override
  Widget build(BuildContext context) => IgnorePointer(
        child: Container(height: sheetWindowPad, color: AppColors.paper),
      );
}
