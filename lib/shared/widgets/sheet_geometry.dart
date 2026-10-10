import '../../features/lessons/models/rudiment.dart';
import 'staff_layout.dart';

// Row and margin metrics shared by the staff painter, the sheet widget and
// the practice window. All rows of a sheet share one pitch so the window
// can slide by whole rows (spec §4b/§4c).
//
// Width (Uli, 10.10.: "sehr viel Platz geht verloren"): the number box sits
// above the staff, the clef and time signature appear on the first line
// only, and a row runs to the card's edge — so on a 360 dp phone the notes
// get ~290 dp instead of ~215.
const double sheetRowPitch = 104; // the staff band
const double sheetCountBand = 14; // count syllables under the letters
const double sheetRowPitchWithCounts = sheetRowPitch + sheetCountBand;
const double sheetLeftPad = 8;
const double sheetNumberBox = 18; // box size; it sits above the staff, left
const double sheetRightPad = 8;
const double sheetRepeatW = 10; // room for ":|" at the row end
const double sheetSystemPad = 26; // clef (+ time signature), first line only
const double sheetNoClefPad = 4; // every other line starts right away
const double sheetRepeatSystemPad = 22; // "|:" after the clef / line start
const double sheetGraceSystemPad = 14; // flam/drag graces before note 1
const double sheetBarGap = 12;

/// The number box no longer takes a column — kept so callers read alike.
double leftPadFor({required bool numbered}) => sheetLeftPad;
double rightPadFor({required bool repeat}) =>
    sheetRightPad + (repeat ? sheetRepeatW : 0);

/// Room before the first note: clef and time signature on the first line
/// only ([clef]), the start repeat's own width, and extra space when the
/// line opens with a flam or drag so the grace heads clear the repeat dots.
double systemPadFor({required bool repeat, bool graces = false, bool clef = true}) =>
    (clef ? sheetSystemPad : sheetNoClefPad) +
    (repeat ? sheetRepeatSystemPad + (graces ? sheetGraceSystemPad : 0) : 0);

/// True when the first note of [beats] carries grace notes.
bool leadsWithGraces(List<StrokeBeat> beats) =>
    beats.isNotEmpty && beats.first.graces.isNotEmpty;

/// Layout of every line of a sheet at one width, plus the global row order.
class SheetGeometry {
  final List<StaffLayout> layouts;
  final double rowPitch;

  /// Global index of each line's first row.
  final List<int> rowStart;
  final int totalRows;
  const SheetGeometry(
      this.layouts, this.rowPitch, this.rowStart, this.totalRows);

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
/// carries count syllables and [showCounts] is on — every row must stay the
/// same height. Titles sit inside the staff band (under the staff, left),
/// so they cost no height.
SheetGeometry computeSheetGeometry(Rudiment r, double maxWidth,
    {required bool showCounts}) {
  final sheet = r.sheet;
  final counts = showCounts && sheet.any((l) => l.counts);
  final layouts = <StaffLayout>[];
  final starts = <int>[];
  var rows = 0;
  for (var i = 0; i < sheet.length; i++) {
    final l = sheet[i];
    starts.add(rows);
    final layout = computeStaffLayout(
      beats: l.beats,
      grid: r.gridUnit,
      beatsPerBar: r.beatsPerBar,
      maxWidth: maxWidth,
      leftPad: leftPadFor(numbered: true),
      rightPad: rightPadFor(repeat: l.repeat),
      systemPad: systemPadFor(
          repeat: l.repeat, graces: leadsWithGraces(l.beats), clef: i == 0),
      barGap: sheetBarGap,
    );
    layouts.add(layout);
    rows += layout.rowCount;
  }
  return SheetGeometry(
      layouts, counts ? sheetRowPitchWithCounts : sheetRowPitch, starts, rows);
}
