import 'package:flutter/material.dart';

import '../../../shared/widgets/kit_layout.dart';
import '../../../shared/widgets/notation_staff_widget.dart';
import '../../../shared/widgets/sheet_geometry.dart';
import '../../lessons/models/pattern_playback.dart';
import '../../lessons/models/rudiment.dart';
import '../../practice/widgets/line_view.dart';
import '../models/guided_exercise.dart';
import '../run_clock.dart';

/// One guided line as an ordinary one-line sheet, so the practice screen's
/// [LineView] (and with it the app's only notation path) can draw it: kit
/// lines keep their voices (five-line kit staff), pad lines their sticking.
Rudiment rudimentForGuidedLine(GuidedExercise ex, ExerciseLine line) {
  final kit = line.isKit;
  return Rudiment(
    id: '${ex.id}_line',
    name: ex.name,
    description: ex.description,
    minBpm: ex.minBpm,
    targetBpm: ex.defaultBpm,
    difficulty: ex.difficulty,
    sticking: line.beats,
    gridUnit: ex.gridUnit,
    beatsPerBar: ex.beatsPerBar,
    voicing: kit ? ExerciseVoicing.kit : ExerciseVoicing.pad,
    lines: [line],
    patternVoices: kit ? line.kitVoices : const [],
  );
}

/// Cursor tick within [line] for the player's position [p]. The player's
/// [RunPosition.tick] counts within the current BAR; a line of several bars
/// repeats inside its section, so the bar within the line is
/// `barInSection % lineBars`.
int lineTickFor(RunPosition p, ExerciseLine line, NoteGrid grid) {
  const ticksPerBar = guidedBeatsPerBar * kitTicksPerQuarter;
  final lineBars = (ticksOf(line.beats, grid) ~/ ticksPerBar).clamp(1, 1 << 30);
  return (p.barInSection % lineBars) * ticksPerBar + p.tick;
}

/// The notes of one guided line (Plan 3a, Task 2), drawn with the
/// practice screen's [LineView].
///
/// [activeTick] is the cursor tick within the LINE (the caller maps the
/// player's position with [lineTickFor]); null = no cursor. [dimmed] draws
/// the line at 45 % for "coming up". The view fills the width it gets; on
/// a wide layout the staff grows (scaled, not re-spaced) until it reaches
/// [maxStaffHeight] — at phone width it is drawn at its natural size.
class GuidedLineView extends StatelessWidget {
  const GuidedLineView({
    super.key,
    required this.exercise,
    required this.line,
    this.activeTick,
    this.dimmed = false,
    this.maxStaffHeight,
  });

  final GuidedExercise exercise;
  final ExerciseLine line;
  final int? activeTick;
  final bool dimmed;
  final double? maxStaffHeight;

  /// Opacity of a dimmed ("coming up") line.
  static const dimmedOpacity = 0.45;

  /// Width at which the staff is drawn at its natural size; wider layouts
  /// scale it up instead of spreading the notes ever further apart.
  static const naturalWidth = 520.0;

  /// Upper bound of the scale, whatever [maxStaffHeight] allows.
  static const maxScale = 2.2;

  @override
  Widget build(BuildContext context) {
    final rudiment = rudimentForGuidedLine(exercise, line);
    // Pad lines place their cursor by note index, kit lines by tick.
    int? activeIndex;
    final tick = activeTick;
    if (tick != null && !line.isKit && line.beats.isNotEmpty) {
      final pb = buildPatternPlayback(line.beats, exercise.gridUnit);
      activeIndex = pb.noteIndexAtTick(tick % pb.totalTicks);
    }
    Widget view(double width) => SizedBox(
          width: width,
          child: LineView(
            rudiment: rudiment,
            line: 0,
            activeIndex: activeIndex,
            activeTick: line.isKit ? tick : null,
            showCounts: false,
          ),
        );

    final content = LayoutBuilder(builder: (context, c) {
      final width =
          c.maxWidth.isFinite ? c.maxWidth : MediaQuery.of(context).size.width;
      var scale = (width / naturalWidth).clamp(1.0, maxScale);
      if (scale > 1.0) {
        final maxH = maxStaffHeight ??
            (c.maxHeight.isFinite ? c.maxHeight : double.infinity);
        final h = _heightAt(rudiment, width / scale);
        if (h * scale > maxH) {
          scale = (maxH / _heightAt(rudiment, width)).clamp(1.0, scale);
        }
      }
      if (scale <= 1.0) {
        final cap = maxStaffHeight;
        return cap == null
            ? view(width)
            : ConstrainedBox(
                constraints: BoxConstraints(maxHeight: cap),
                child: view(width));
      }
      final inner = width / scale;
      return SizedBox(
        width: width,
        height: _heightAt(rudiment, inner) * scale,
        child: FittedBox(
          fit: BoxFit.fitWidth,
          alignment: Alignment.topCenter,
          child: view(inner),
        ),
      );
    });

    return dimmed ? Opacity(opacity: dimmedOpacity, child: content) : content;
  }

  /// Natural height of the one-line card at [width] (as [LineView] sizes it).
  static double _heightAt(Rudiment r, double width) {
    final SheetGeometry geo = computeSheetGeometry(
        r, width - 2 * SheetStaffWidget.hPad,
        showCounts: false, clefLine: 0);
    return geo.layouts[0].rowCount * geo.rowPitch + 2 * SheetStaffWidget.vPad;
  }
}
