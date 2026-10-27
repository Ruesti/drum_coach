import '../../features/lessons/models/rudiment.dart';
import 'kit_layout.dart';
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

/// A kit row (Brief B.2): five lines with stems up (hands) and down (feet)
/// need more height than the pad row. One pitch for the whole sheet.
const double kitRowPitch = 132;

/// A kit row with foot letters (double bass, Nachtrag B.4c): a second
/// letter row under the feet stems needs more height.
const double kitRowPitchWithFeet = 146;
const double sheetLeftPad = 8;
const double sheetNumberBox = 18; // box size; it sits above the staff, left
const double sheetRightPad = 4; // = the left margin (staff starts at 4)
const double sheetRepeatW = 0; // ":|" sits on the final barline, no extra room
const double sheetSystemPad = 26; // clef (+ time signature), first line only
const double sheetNoClefPad = 4; // every other line starts right away
const double sheetRepeatSystemPad = 22; // "|:" after the clef / line start
const double sheetGraceSystemPad = 14; // flam/drag graces before note 1
const double sheetBarGap = 12;

/// Upper bound of the note spacing (px per quarter) of a line: the comfort
/// size, or none with `fillWidth` — the line then always spans its row
/// (the guided play screen, Uli 27.10.: "über die volle Bildschirmbreite").
double preferredPxPerQuarterFor({required bool fillWidth}) =>
    fillWidth ? double.infinity : 56;

/// Kit lines without a clef: the number box would sit on the first hands
/// beam (kit stems reach higher), so the line starts right of the box.
const double kitBoxPad = sheetNumberBox + 4;

/// Kit line with the time signature and no start repeat: the kick under
/// beat 1 and the hi-hat above it would touch the digits.
const double kitTimeSigPad = 10;

/// The number box no longer takes a column — kept so callers read alike.
double leftPadFor({required bool numbered}) => sheetLeftPad;
double rightPadFor({required bool repeat}) =>
    sheetRightPad + (repeat ? sheetRepeatW : 0);

/// Room before the first note: clef and time signature on the first line
/// only ([clef]), the start repeat's own width, and extra space when the
/// line opens with a flam or drag so the grace heads clear the repeat dots.
/// Kit lines only: [kitBox] keeps a clef-less line clear of the number box
/// ([kitBoxPad]), [kitTimeSig] adds room after the time signature
/// ([kitTimeSigPad]).
double systemPadFor(
        {required bool repeat,
        bool graces = false,
        bool clef = true,
        bool kitBox = false,
        bool kitTimeSig = false}) =>
    (clef ? sheetSystemPad : sheetNoClefPad) +
    (repeat ? sheetRepeatSystemPad + (graces ? sheetGraceSystemPad : 0) : 0) +
    (kitBox ? kitBoxPad : 0) +
    (kitTimeSig ? kitTimeSigPad : 0);

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

  /// Per line: the kit layout of a kit line, null for a pad line.
  final List<KitLineLayout?> kitLayouts;
  const SheetGeometry(
      this.layouts, this.rowPitch, this.rowStart, this.totalRows,
      {this.kitLayouts = const []});

  bool get isKit => kitLayouts.any((k) => k != null);

  /// Global row of note [index] in [line] (pad lines).
  int rowOf(int line, int index) =>
      rowStart[line] + layouts[line].placements[index].row;

  /// Global row of [tick] in [line] (kit lines); a pad line's first row.
  int rowOfTick(int line, int tick) {
    final kit = line < kitLayouts.length ? kitLayouts[line] : null;
    return rowStart[line] + (kit?.rowOfTick(tick) ?? 0);
  }

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
///
/// [clefLine] is the line that carries clef and time signature — line 0 on
/// a whole sheet; the one-line view shows its line alone, so that line
/// gets them (and the matching start room). [fillWidth] spreads every line
/// over the whole width ([preferredPxPerQuarterFor]).
SheetGeometry computeSheetGeometry(Rudiment r, double maxWidth,
    {required bool showCounts, int clefLine = 0, bool fillWidth = false}) {
  final pxq = preferredPxPerQuarterFor(fillWidth: fillWidth);
  final sheet = r.sheet;
  final counts = showCounts && sheet.any((l) => l.counts);
  final kit = sheet.any((l) => l.isKit);
  final feet = kit && r.hasFootSides;
  final layouts = <StaffLayout>[];
  final kitLayouts = <KitLineLayout?>[];
  final starts = <int>[];
  var rows = 0;
  for (var i = 0; i < sheet.length; i++) {
    final l = sheet[i];
    starts.add(rows);
    final leftPad = leftPadFor(numbered: true);
    final rightPad = rightPadFor(repeat: l.repeat);
    final systemPad = systemPadFor(
        repeat: l.repeat,
        graces: l.voices.any((v) => leadsWithGraces(v.beats)),
        clef: i == clefLine,
        // Same rules as the painter: clef and time signature on one line.
        kitBox: l.isKit && i != clefLine,
        kitTimeSig: l.isKit && i == clefLine && !l.repeat);
    if (l.isKit) {
      final kl = computeKitLineLayout(
        voices: l.kitVoices,
        grid: r.gridUnit,
        beatsPerBar: r.beatsPerBar,
        maxWidth: maxWidth,
        leftPad: leftPad,
        rightPad: rightPad,
        systemPad: systemPad,
        barGap: sheetBarGap,
        preferredPxPerQuarter: pxq,
      );
      layouts.add(kl.hands);
      kitLayouts.add(kl);
      rows += kl.rowCount;
    } else {
      final layout = computeStaffLayout(
        beats: l.beats,
        grid: r.gridUnit,
        beatsPerBar: r.beatsPerBar,
        maxWidth: maxWidth,
        leftPad: leftPad,
        rightPad: rightPad,
        systemPad: systemPad,
        barGap: sheetBarGap,
        preferredPxPerQuarter: pxq,
      );
      layouts.add(layout);
      kitLayouts.add(null);
      rows += layout.rowCount;
    }
  }
  final base = feet ? kitRowPitchWithFeet : kit ? kitRowPitch : sheetRowPitch;
  return SheetGeometry(
      layouts, counts ? base + sheetCountBand : base, starts, rows,
      kitLayouts: kitLayouts);
}
