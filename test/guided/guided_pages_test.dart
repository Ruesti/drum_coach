import 'package:drum_coach/features/coaching/midi/kit_instrument.dart';
import 'package:drum_coach/features/guided/data/guided_catalog.dart';
import 'package:drum_coach/features/guided/guided_pages.dart';
import 'package:drum_coach/features/guided/guided_run_controller.dart';
import 'package:drum_coach/features/guided/models/guided_exercise.dart';
import 'package:drum_coach/features/guided/run_clock.dart';
import 'package:drum_coach/features/guided/run_plan.dart';
import 'package:drum_coach/features/lessons/models/rudiment.dart';
import 'package:drum_coach/shared/widgets/kit_layout.dart';
import 'package:flutter_test/flutter_test.dart';

const _r = StrokeBeat(hand: Hand.right, value: NoteValue.quarter);
const _l = StrokeBeat(hand: Hand.left, value: NoteValue.quarter);

/// [n] quarter notes, alternating R/L.
List<StrokeBeat> _q(int n) => [for (var i = 0; i < n; i++) i.isEven ? _r : _l];

ExerciseLine _pad(int bars) => ExerciseLine(_q(bars * 4));

GuidedSection _sec(SectionKind k, int bars, ExerciseLine line) => GuidedSection(
    kind: k,
    line: line,
    bars: bars,
    textEn: k == SectionKind.variation ? 't' : null,
    titleEn: k == SectionKind.variation ? 'T' : null,
    speechClipId: k == SectionKind.variation ? 'c' : null);

GuidedExercise _ex(List<GuidedSection> s) => GuidedExercise(
      id: 'x',
      name: 'X',
      description: 'd',
      package: GuidedPackage.pad,
      difficulty: Difficulty.beginner,
      defaultBpm: 80,
      minBpm: 60,
      maxBpm: 120,
      gridUnit: NoteGrid.quarter,
      sections: s,
    );

GuidedExercise _standard({int grooveBars = 8}) => _ex([
      _sec(SectionKind.intro, 0, const ExerciseLine([])),
      _sec(SectionKind.groove, grooveBars, _pad(1)),
      _sec(SectionKind.variation, 4, _pad(2)),
      _sec(SectionKind.groove, grooveBars, _pad(1)),
      _sec(SectionKind.outro, 1, _pad(1)),
    ]);

RunPosition _pos(int section, int barInSection, [int tick = 0]) => RunPosition(
      bar: 1,
      sectionIndex: section,
      barInSection: barInSection,
      beat: 1,
      tick: tick,
      bpm: 80,
      plannedAt: DateTime(2026),
    );

List<GuidedSectionTime> _plan(GuidedExercise ex,
        {Map<int, int> over = const {}}) =>
    [
      (sectionIndex: -1, bars: 1, ms: 0),
      for (var i = 0; i < ex.sections.length; i++)
        (sectionIndex: i, bars: over[i] ?? ex.sections[i].bars, ms: 0),
    ];

void main() {
  test('pageLine repeats a 1-bar line to 4 bars', () {
    final p = pageLine(_pad(1), NoteGrid.quarter, firstBar: 0, bars: 4);
    expect(p.repeat, isFalse);
    expect(p.beats.length, 16);
    expect(ticksOf(p.beats, NoteGrid.quarter), 4 * runTicksPerBar);
  });

  test('pageLine takes bars 2-3 of a 4-bar kit line per voice', () {
    final hat = [for (var i = 0; i < 16; i++) _r];
    final kick = <StrokeBeat>[
      for (var b = 0; b < 4; b++) ...[
        StrokeBeat(hand: null, value: NoteValue.quarter, isAccent: b == 2),
        const StrokeBeat.rest(value: NoteValue.quarter),
        const StrokeBeat.rest(value: NoteValue.half),
      ],
    ];
    final line = ExerciseLine.kit([
      Voice(KitInstrument.hiHatClosed, hat),
      Voice(KitInstrument.kick, kick),
    ]);
    final p = pageLine(line, NoteGrid.quarter, firstBar: 2, bars: 2);
    expect(p.isKit, isTrue);
    expect(p.repeat, isFalse);
    expect(p.kitVoices[0].instrument, KitInstrument.hiHatClosed);
    expect(p.kitVoices[0].beats.length, 8);
    expect(p.kitVoices[1].beats.length, 6);
    expect(p.kitVoices[1].beats.first.isAccent, isTrue);
    expect(p.kitVoices[1].beats[3].isAccent, isFalse);
    expect(ticksOf(p.kitVoices[1].beats, NoteGrid.quarter), 2 * runTicksPerBar);
  });

  test('pageLine keeps triplets and flams of Triplet Flams and Drags', () {
    final ex =
        guidedCatalog.firstWhere((e) => e.id == 'guided_pad_triplet_flams');
    var checked = 0;
    for (final s in ex.sections.where((s) => s.line.beats.isNotEmpty)) {
      final lineBars = ticksOf(s.line.beats, ex.gridUnit) ~/ runTicksPerBar;
      var graces = 0, triplets = 0, notes = 0;
      for (var b = 0; b < lineBars; b++) {
        final p = pageLine(s.line, ex.gridUnit, firstBar: b, bars: 1);
        notes += p.beats.length;
        graces += p.beats.fold<int>(0, (n, x) => n + x.graces.length);
        triplets += p.beats.where((x) => x.tuplet != Tuplet.none).length;
      }
      expect(notes, s.line.beats.length);
      expect(graces, s.line.beats.fold<int>(0, (n, x) => n + x.graces.length));
      expect(
          triplets, s.line.beats.where((x) => x.tuplet != Tuplet.none).length);
      checked++;
    }
    expect(checked, greaterThan(0));
  });

  test('pageLine rejects a note crossing a bar line', () {
    final line = ExerciseLine([
      ..._q(3),
      const StrokeBeat(hand: Hand.right, value: NoteValue.half),
      ..._q(3),
    ]);
    expect(() => pageLine(line, NoteGrid.quarter, firstBar: 0, bars: 1),
        throwsArgumentError);
  });

  test('pageLine rejects a tuplet group crossing a bar line', () {
    const t = StrokeBeat(
        hand: Hand.right, value: NoteValue.eighth, tuplet: Tuplet.triplet);
    const e = StrokeBeat(hand: Hand.right, value: NoteValue.eighth);
    // 3 quarters + 2 eighths = 4 beats - 0 ... start the group mid-bar:
    // bar 1 = q q q e e(=1 beat) -> instead: q q q, then e, then group of 3
    // triplet eighths (1 beat) starting half a beat before the bar line.
    final line = ExerciseLine([..._q(3), e, t, t, t, e, ..._q(3)]);
    expect(() => pageLine(line, NoteGrid.quarter, firstBar: 0, bars: 1),
        throwsArgumentError);
  });

  test('pages at count-in show the first groove without tick', () {
    final ex = _standard();
    final r = guidedPagesAt(ex, _plan(ex), _pos(-1, 0), pageBars: 4);
    expect(r.now.sectionIndex, 1);
    expect(r.now.firstBar, 0);
    expect(r.now.bars, 4);
    expect(guidedPageTick(r.now, _pos(-1, 0)), isNull);
    expect(guidedPagesAt(ex, _plan(ex), null, pageBars: 4).now.sectionIndex, 1);
  });

  test('page turns at bar 4 of a 8-bar section', () {
    final ex = _standard();
    final plan = _plan(ex);
    final a = guidedPagesAt(ex, plan, _pos(1, 3, 40), pageBars: 4);
    expect(a.now.firstBar, 0);
    expect(a.next!.firstBar, 4);
    expect(a.next!.sectionIndex, 1);
    expect(guidedPageTick(a.now, _pos(1, 3, 40)), 3 * runTicksPerBar + 40);
    final b = guidedPagesAt(ex, plan, _pos(1, 4, 5), pageBars: 4);
    expect(b.now.firstBar, 4);
    expect(guidedPageTick(b.now, _pos(1, 4, 5)), 5);
    expect(guidedPageTick(a.now, _pos(1, 4, 5)), isNull);
  });

  test('last page of an extended groove ends with the section', () {
    final ex = _standard();
    final plan = _plan(ex, over: {1: 12});
    final pages = [
      for (var b = 0; b < 12; b += 4)
        guidedPagesAt(ex, plan, _pos(1, b), pageBars: 4).now,
    ];
    expect(pages.map((p) => p.firstBar), [0, 4, 8]);
    expect(pages.last.bars, 4);
    final last = guidedPagesAt(ex, plan, _pos(1, 11), pageBars: 4);
    expect(last.now.firstBar, 8);
    expect(last.next!.sectionIndex, 2);
  });

  test("next of a groove's last page is the variation's first page", () {
    final ex = _standard();
    final r = guidedPagesAt(ex, _plan(ex), _pos(1, 7), pageBars: 4);
    expect(r.now.firstBar, 4);
    expect(r.next!.sectionIndex, 2);
    expect(r.next!.firstBar, 0);
    expect(r.next!.bars, 4);
  });

  test('outro page has 1 bar and no next', () {
    final ex = _standard();
    final r = guidedPagesAt(ex, _plan(ex), _pos(4, 0), pageBars: 4);
    expect(r.now.bars, 1);
    expect(r.next, isNull);
  });

  test('pageBars 2 halves the pages', () {
    final ex = _standard();
    final plan = _plan(ex);
    final r = guidedPagesAt(ex, plan, _pos(1, 5), pageBars: 2);
    expect(r.now.firstBar, 4);
    expect(r.now.bars, 2);
    expect(r.next!.firstBar, 6);
    expect(
        guidedPagesAt(ex, plan, _pos(1, 7), pageBars: 2).next!.sectionIndex, 2);
  });

  test('preview pages are groove plus each variation', () {
    final ex = _standard();
    final pages = guidedPreviewPages(ex, pageBars: 4);
    expect(pages.map((p) => p.sectionIndex), [1, 2]);
    expect(pages.every((p) => p.firstBar == 0 && p.bars == 4), isTrue);
  });

  test('every catalog section can be paged at every bar', () {
    for (final ex in guidedCatalog) {
      for (final pb in [2, 4]) {
        expect(guidedPreviewPages(ex, pageBars: pb), isNotEmpty);
        for (var i = 0; i < ex.sections.length; i++) {
          final s = ex.sections[i];
          for (var b = 0; b < s.bars; b++) {
            guidedPagesAt(ex, _plan(ex), _pos(i, b), pageBars: pb);
          }
        }
      }
    }
  });
}
