import '../../features/lessons/models/rudiment.dart';
import 'staff_layout.dart';

// Row and margin metrics shared by the staff painter, the sheet widget and
// the practice window. All rows of a sheet share one pitch so the window
// can slide by whole rows (spec §4b/§4c).
const double sheetRowPitch = 104; // the staff band
const double sheetCountBand = 14; // count syllables under the letters
const double sheetTitleBand = 14; // line titles above the staff
const double sheetRowPitchWithCounts = sheetRowPitch + sheetCountBand;
const double sheetLeftPad = 8;
const double sheetNumberBoxW = 26; // number box 22 px + 4 px gap
const double sheetRightPad = 12;
const double sheetRepeatW = 10; // room for ":|" at the row end
const double sheetSystemPad = 26; // clef (+ time signature)
const double sheetRepeatSystemPad = 20; // extra room for "|:" after the clef
const double sheetBarGap = 12;

double leftPadFor({required bool numbered}) =>
    sheetLeftPad + (numbered ? sheetNumberBoxW : 0);
double rightPadFor({required bool repeat}) =>
    sheetRightPad + (repeat ? sheetRepeatW : 0);
double systemPadFor({required bool repeat}) =>
    sheetSystemPad + (repeat ? sheetRepeatSystemPad : 0);

/// Layout of every line of a sheet at one width, plus the global row order.
class SheetGeometry {
  final List<StaffLayout> layouts;
  final double rowPitch;

  /// Space above every staff band reserved for line titles (0 when no line
  /// of the sheet has one).
  final double topInset;

  /// Global index of each line's first row.
  final List<int> rowStart;
  final int totalRows;
  const SheetGeometry(this.layouts, this.rowPitch, this.rowStart,
      this.totalRows, {this.topInset = 0});

  /// Global row of note [index] in [line].
  int rowOf(int line, int index) =>
      rowStart[line] + layouts[line].placements[index].row;

  /// The line a global [row] belongs to.
  int lineOfRow(int row) {
    var l = 0;
    while (l + 1 < rowStart.length && rowStart[l + 1] <= row) {
      l++;
    }
    return l;
  }

  double get height => totalRows * rowPitch;
}

/// Lays out each line of [r]'s sheet at [maxWidth] (content width inside the
/// paper card). The pitch grows for the whole sheet as soon as one line
/// carries count syllables (and [showCounts] is on) or a title — every row
/// must stay the same height.
SheetGeometry computeSheetGeometry(Rudiment r, double maxWidth,
    {required bool showCounts}) {
  final sheet = r.sheet;
  final counts = showCounts && sheet.any((l) => l.counts);
  final titles = sheet.any((l) => l.title != null);
  final layouts = <StaffLayout>[];
  final starts = <int>[];
  var rows = 0;
  for (final l in sheet) {
    starts.add(rows);
    final layout = computeStaffLayout(
      beats: l.beats,
      grid: r.gridUnit,
      beatsPerBar: r.beatsPerBar,
      maxWidth: maxWidth,
      leftPad: leftPadFor(numbered: true),
      rightPad: rightPadFor(repeat: l.repeat),
      systemPad: systemPadFor(repeat: l.repeat),
      barGap: sheetBarGap,
    );
    layouts.add(layout);
    rows += layout.rowCount;
  }
  final pitch = sheetRowPitch +
      (counts ? sheetCountBand : 0) +
      (titles ? sheetTitleBand : 0);
  return SheetGeometry(layouts, pitch, starts, rows,
      topInset: titles ? sheetTitleBand : 0);
}
