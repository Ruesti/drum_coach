import 'package:drum_coach/app/design_tokens.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// Paint colours come back as floats: compare the 32-bit value.
bool _is(Paint p, Color c) => p.color.toARGB32() == c.toARGB32();

/// One drawn playhead line, in screen pixels.
typedef Playhead = ({double x, double top, double bottom, double width});

/// Everything the staff painter under [of] draws, recorded call by call.
class StaffCalls {
  StaffCalls(this.calls, this.scale, this.origin);
  final List<(Symbol, List<dynamic>)> calls;

  /// Screen pixels per painter unit (a scaled-up guided line > 1).
  final double scale;
  final Offset origin;

  Iterable<(Symbol, List<dynamic>)> _of(Symbol m) =>
      calls.where((c) => c.$1 == m);

  /// Accent-coloured lines = the playhead.
  List<Playhead> get playheads => playheadsIn(AppColors.accent);

  /// Lines in [colour] (the guided page's blue playhead).
  List<Playhead> playheadsIn(Color colour) => [
        for (final c in _of(#drawLine))
          if (_is(c.$2[2] as Paint, colour))
            (
              x: origin.dx + (c.$2[0] as Offset).dx * scale,
              top: (c.$2[0] as Offset).dy * scale,
              bottom: (c.$2[1] as Offset).dy * scale,
              width: (c.$2[2] as Paint).strokeWidth * scale,
            ),
      ];

  /// Drawn height of the five-line staff in screen pixels: the length of a
  /// barline (staff colour, vertical, top to bottom line).
  double get staffHeight {
    for (final c in _of(#drawLine)) {
      final a = c.$2[0] as Offset;
      final b = c.$2[1] as Offset;
      if (a.dx == b.dx &&
          (c.$2[2] as Paint).color.toARGB32() == staffInk.toARGB32()) {
        return (b.dy - a.dy).abs() * scale;
      }
    }
    throw StateError('no barline drawn');
  }

  /// The staff lines' colour (ink at 18 %).
  static const staffInk = Color(0x2E17181A);

  /// The box cursor's amber field behind the active note.
  bool get hasCursorField => _of(#drawRRect)
      .any((c) => _is(c.$2[1] as Paint, AppColors.live));

  /// A coloured ring around a note (box cursor) — any oval in the cursor
  /// colour.
  bool get hasNoteRing => _of(#drawOval)
      .any((c) => _is(c.$2[1] as Paint, AppColors.paperCursorLine));
}

bool _isStaffPaint(Widget w) =>
    w is CustomPaint && w.painter.runtimeType.toString() == '_StaffPainter';

/// Records the staff painter under [of] (exactly one).
StaffCalls staffCalls(WidgetTester t, Finder of) {
  final finder = find.descendant(
      of: of, matching: find.byWidgetPredicate(_isStaffPaint));
  expect(finder, findsOneWidget);
  final box = t.renderObject<RenderBox>(finder);
  final rect = t.getRect(finder);
  final calls = <(Symbol, List<dynamic>)>[];
  expect(
      box,
      paints
        ..everything((m, args) {
          calls.add((m, List<dynamic>.of(args)));
          return true;
        }));
  return StaffCalls(calls, rect.width / box.size.width, rect.topLeft);
}
