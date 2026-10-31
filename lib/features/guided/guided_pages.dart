import '../../shared/widgets/kit_layout.dart';
import '../lessons/models/rudiment.dart';
import 'guided_run_controller.dart';
import 'models/guided_exercise.dart';
import 'run_clock.dart';
import 'run_plan.dart';

/// One written-out page of a guided section: [bars] bars from [firstBar]
/// (counted from the start of the section), as a non-repeating line.
class GuidedPage {
  const GuidedPage({
    required this.sectionIndex,
    required this.firstBar,
    required this.bars,
    required this.line,
  });

  final int sectionIndex;
  final int firstBar;
  final int bars;
  final ExerciseLine line;

  @override
  bool operator ==(Object other) =>
      other is GuidedPage &&
      other.sectionIndex == sectionIndex &&
      other.firstBar == firstBar &&
      other.bars == bars;

  @override
  int get hashCode => Object.hash(sectionIndex, firstBar, bars);
}

/// Notes of [beats] per bar of the line (index = bar in the line). Throws
/// [ArgumentError] when a note, or a tuplet group, crosses a bar line.
List<List<StrokeBeat>> _splitBars(List<StrokeBeat> beats, NoteGrid grid) {
  final starts = <int>[];
  var tick = 0;
  for (final b in beats) {
    starts.add(tick);
    tick += ticksOfNote(resolveNote(b, grid));
  }
  starts.add(tick);
  final out = List.generate(tick ~/ runTicksPerBar, (_) => <StrokeBeat>[]);

  // Tuplet groups: runs of equal tuplets cut into 3 (triplet) / 6 (sextuplet).
  final groupStart = <int, int>{};
  final groupEnd = <int, int>{};
  var i = 0;
  while (i < beats.length) {
    final t = resolveNote(beats[i], grid).tuplet;
    if (t == Tuplet.none) {
      i++;
      continue;
    }
    final size = t == Tuplet.triplet ? 3 : 6;
    var j = i;
    while (j < beats.length &&
        j - i < size &&
        resolveNote(beats[j], grid).tuplet == t) {
      j++;
    }
    for (var k = i; k < j; k++) {
      groupStart[k] = starts[i];
      groupEnd[k] = starts[j];
    }
    i = j;
  }

  for (var k = 0; k < beats.length; k++) {
    final s = groupStart[k] ?? starts[k];
    final e = groupEnd[k] ?? starts[k + 1];
    if (e > s && s ~/ runTicksPerBar != (e - 1) ~/ runTicksPerBar) {
      throw ArgumentError('note $k crosses a bar line (ticks $s..$e)');
    }
    out[starts[k] ~/ runTicksPerBar].add(beats[k]);
  }
  return out;
}

List<StrokeBeat> _sliceBeats(
    List<StrokeBeat> beats, NoteGrid grid, int firstBar, int bars) {
  final perBar = _splitBars(beats, grid);
  if (perBar.isEmpty) return const [];
  return [
    for (var b = firstBar; b < firstBar + bars; b++)
      ...perBar[b % perBar.length],
  ];
}

/// Bars [firstBar] .. [firstBar]+[bars]-1 of the cyclically repeated [line]
/// as a new non-repeating line. Kit lines are cut per voice. Graces stay
/// with their main note. Throws [ArgumentError] when a note crosses a bar
/// line.
ExerciseLine pageLine(ExerciseLine line, NoteGrid grid,
    {required int firstBar, required int bars}) {
  if (line.isKit) {
    return ExerciseLine.kit([
      for (final v in line.kitVoices)
        Voice(v.instrument, _sliceBeats(v.beats, grid, firstBar, bars),
            accepts: v.accepts),
    ], repeat: false, title: line.title, counts: line.counts);
  }
  return ExerciseLine(_sliceBeats(line.beats, grid, firstBar, bars),
      repeat: false, title: line.title, counts: line.counts);
}

bool _hasNotes(GuidedSection s) =>
    s.bars > 0 &&
    (s.line.isKit
        ? s.line.kitVoices.any((v) => v.beats.isNotEmpty)
        : s.line.beats.isNotEmpty);

int _sectionBars(GuidedExercise ex, List<GuidedSectionTime> plan, int i) {
  for (final p in plan) {
    if (p.sectionIndex == i) return p.bars;
  }
  return ex.sections[i].bars;
}

GuidedPage _page(GuidedExercise ex, List<GuidedSectionTime> plan, int section,
    int firstBar, int pageBars) {
  final total = _sectionBars(ex, plan, section);
  final bars = total - firstBar < pageBars ? total - firstBar : pageBars;
  return GuidedPage(
    sectionIndex: section,
    firstBar: firstBar,
    bars: bars,
    line: pageLine(ex.sections[section].line, ex.gridUnit,
        firstBar: firstBar, bars: bars),
  );
}

int? _firstGroove(GuidedExercise ex) {
  for (var i = 0; i < ex.sections.length; i++) {
    if (ex.sections[i].kind == SectionKind.groove &&
        _hasNotes(ex.sections[i])) {
      return i;
    }
  }
  for (var i = 0; i < ex.sections.length; i++) {
    if (_hasNotes(ex.sections[i])) return i;
  }
  return null;
}

/// The page being played and the one after it. Without a position, in the
/// count-in or in an empty intro, [now] is page 0 of the first groove.
/// [next] is null after the outro.
({GuidedPage now, GuidedPage? next}) guidedPagesAt(
    GuidedExercise ex, List<GuidedSectionTime> plan, RunPosition? pos,
    {required int pageBars}) {
  var section = pos?.sectionIndex ?? -1;
  var firstBar = 0;
  if (section >= 0 &&
      section < ex.sections.length &&
      _hasNotes(ex.sections[section])) {
    firstBar = (pos!.barInSection ~/ pageBars) * pageBars;
    final total = _sectionBars(ex, plan, section);
    if (firstBar >= total) firstBar = ((total - 1) ~/ pageBars) * pageBars;
  } else {
    section = _firstGroove(ex) ??
        (throw ArgumentError('${ex.id}: no section with notes'));
  }
  final now = _page(ex, plan, section, firstBar, pageBars);

  GuidedPage? next;
  if (firstBar + now.bars < _sectionBars(ex, plan, section)) {
    next = _page(ex, plan, section, firstBar + now.bars, pageBars);
  } else {
    for (var i = section + 1; i < ex.sections.length; i++) {
      if (_hasNotes(ex.sections[i])) {
        next = _page(ex, plan, i, 0, pageBars);
        break;
      }
    }
  }
  return (now: now, next: next);
}

/// Cursor tick within [page], or null when [pos] is not on this page.
int? guidedPageTick(GuidedPage page, RunPosition? pos) {
  if (pos == null || pos.sectionIndex != page.sectionIndex) return null;
  final rel = pos.barInSection - page.firstBar;
  if (rel < 0 || rel >= page.bars) return null;
  return rel * runTicksPerBar + pos.tick;
}

/// Preview pages: the first groove, then each variation, each page 0.
List<GuidedPage> guidedPreviewPages(GuidedExercise ex,
    {required int pageBars}) {
  final first = _firstGroove(ex);
  return [
    for (var i = 0; i < ex.sections.length; i++)
      if ((i == first || ex.sections[i].kind == SectionKind.variation) &&
          _hasNotes(ex.sections[i]))
        _page(ex, const [], i, 0, pageBars),
  ];
}
