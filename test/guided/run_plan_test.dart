import 'package:drum_coach/features/coaching/midi/kit_instrument.dart';
import 'package:drum_coach/features/guided/models/guided_exercise.dart';
import 'package:drum_coach/features/guided/models/voice_clip.dart';
import 'package:drum_coach/features/guided/run_plan.dart';
import 'package:drum_coach/features/lessons/models/rudiment.dart';
import 'package:flutter_test/flutter_test.dart';

const _r = StrokeBeat(hand: Hand.right);
const _acc = StrokeBeat(hand: Hand.right, isAccent: true);

/// One 4/4 bar of eighths (grid eighth).
ExerciseLine _groove() =>
    const ExerciseLine([_acc, _r, _r, _r, _acc, _r, _r, _r]);
ExerciseLine _varLine() =>
    const ExerciseLine([_acc, _r, _acc, _r, _acc, _r, _acc, _r]);

GuidedSection _g(int bars) =>
    GuidedSection(kind: SectionKind.groove, line: _groove(), bars: bars);
GuidedSection _v(int bars, String clip) => GuidedSection(
    kind: SectionKind.variation,
    line: _varLine(),
    bars: bars,
    textEn: 'Now accent every quarter.',
    speechClipId: clip,
    afterClipId: 'good');

GuidedExercise _ex(List<GuidedSection> s) => GuidedExercise(
      id: 'x',
      name: 'X',
      description: 'd',
      package: GuidedPackage.pad,
      difficulty: Difficulty.beginner,
      defaultBpm: 100,
      minBpm: 40,
      maxBpm: 240,
      gridUnit: NoteGrid.eighth,
      sections: s,
    );

GuidedExercise _fixture() => _ex([
      const GuidedSection(
          kind: SectionKind.intro, line: ExerciseLine([]), bars: 0),
      _g(4),
      _v(8, 'v1'),
      _g(4),
      _v(8, 'v2'),
      _g(4),
      GuidedSection(kind: SectionKind.outro, line: _groove(), bars: 1),
    ]);

ClipManifest _clips({double cd = 400}) => ClipManifest.fromJson({
      'clips': [
        {'id': 'v1', 'ms': 3200},
        {'id': 'v2', 'ms': 3200},
        {'id': 'v3', 'ms': 3200},
        {'id': 'v4', 'ms': 3200},
        {'id': 'good', 'ms': 400},
        for (final id in [...countdownClipIds, ...countInClipIds])
          {'id': id, 'ms': cd},
      ]
    });

double _barMs(RunBar b) => 4 * 60000 / b.bpm;

/// Start of every bar in ms (bars planned in one go from the count-in).
List<double> _starts(List<RunBar> bars) {
  final out = <double>[];
  var t = 0.0;
  for (final b in bars) {
    out.add(t);
    t += _barMs(b);
  }
  return out;
}

double _tickMs(RunBar b, int tick) => tick * 60000 / b.bpm / 24;

List<({String id, double start, double end})> _clipSpans(
    List<RunBar> bars, ClipManifest clips) {
  final s = _starts(bars);
  return [
    for (var i = 0; i < bars.length; i++)
      for (final e in bars[i].events.whereType<ClipEvent>())
        (
          id: e.clipId,
          start: s[i] + _tickMs(bars[i], e.tick),
          end: s[i] + _tickMs(bars[i], e.tick) + clips.durationMs(e.clipId),
        ),
  ];
}

int _firstBarOf(List<RunBar> bars, int section) =>
    bars.indexWhere((b) => b.sectionIndex == section && !b.isCountIn);

void main() {
  const on = RunOptions();

  test('count-in bar first', () {
    final bars = buildRun(_fixture(), bpm: 100, options: on, clips: _clips());
    expect(bars[0].isCountIn, isTrue);
    expect(bars[0].globalBar, 0);
    final click = bars[0].tickVolumes[RunSound.click]!;
    expect(click.length, 96);
    expect([
      for (var t = 0; t < 96; t++)
        if (click[t] > 0) t
    ], [
      0,
      24,
      48,
      72
    ]);
    expect(bars[0].events.whereType<ClipEvent>().map((e) => e.clipId).toList(),
        countInClipIds);
  });

  test('every bar spans 96 ticks per sound and counts globally', () {
    final bars = buildRun(_fixture(), bpm: 100, options: on, clips: _clips());
    for (var i = 0; i < bars.length; i++) {
      expect(bars[i].globalBar, i);
      expect(bars[i].bpm, 100);
      for (final v in bars[i].tickVolumes.values) {
        expect(v.length, 96);
      }
    }
    // 1 count-in + 4 + 8 + 4 + 8 + 4 + 1, no extension at 100 bpm.
    expect(bars.length, 30);
  });

  test('crash on first groove bar and outro', () {
    final bars = buildRun(_fixture(), bpm: 100, options: on, clips: _clips());
    final crashBars = [
      for (final b in bars)
        if (b.events.any((e) => e is CrashEvent)) b
    ];
    expect(crashBars.length, 2);
    expect(crashBars[0].sectionIndex, 1);
    expect(crashBars[0].barInSection, 0);
    expect(crashBars[1].sectionIndex, 6);
    for (final b in crashBars) {
      expect(b.events.whereType<CrashEvent>().single.tick, 0);
    }
  });

  test('countdown bar precedes each variation', () {
    final bars = buildRun(_fixture(), bpm: 100, options: on, clips: _clips());
    for (final vs in [2, 4]) {
      final vi = _firstBarOf(bars, vs);
      final cd = bars[vi - 1];
      expect(cd.isCountdown, isTrue);
      expect(cd.sectionIndex, vs - 1);
      final counts = cd.events.whereType<CountdownEvent>().toList();
      expect([for (final c in counts) c.remaining], [3, 2, 1]);
      expect([for (final c in counts) c.tick], [24, 48, 72]);
      expect(
          {for (final e in cd.events.whereType<ClipEvent>()) e.tick: e.clipId},
          {24: 'cd_three', 48: 'cd_two', 72: 'cd_one'});
      final go = bars[vi].events.whereType<CountdownEvent>().single;
      expect(go.remaining, 0);
      expect(go.tick, 0);
      expect(bars[vi].events.whereType<ClipEvent>().map((e) => e.clipId),
          contains('cd_go'));
    }
    expect(bars.where((b) => b.isCountdown).length, 2);
  });

  test('countdown halves when words do not fit a beat', () {
    final clips = _clips();
    final bars = buildRun(_fixture(), bpm: 240, options: on, clips: clips);
    final vi = _firstBarOf(bars, 2);
    final cd = bars[vi - 1];
    expect(cd.isCountdown, isTrue);
    expect({for (final e in cd.events.whereType<ClipEvent>()) e.tick: e.clipId},
        {0: 'cd_two', 48: 'cd_one'});
    expect([for (final c in cd.events.whereType<CountdownEvent>()) c.remaining],
        [2, 1]);
    final goClip = bars[vi].events.whereType<ClipEvent>().single;
    expect(goClip.clipId, 'cd_go');
    expect(goClip.tick, 0);

    final spans = _clipSpans(bars, clips)
      ..sort((a, b) => a.start.compareTo(b.start));
    for (var i = 1; i < spans.length; i++) {
      expect(spans[i].start, greaterThanOrEqualTo(spans[i - 1].end - 1e-6),
          reason: '${spans[i - 1].id} overlaps ${spans[i].id}');
    }
  });

  void expectExplanationFits(List<RunBar> bars, ClipManifest clips) {
    final s = _starts(bars);
    for (final (vs, id) in [(2, 'v1'), (4, 'v2')]) {
      final vi = _firstBarOf(bars, vs);
      final cdStart = s[vi - 1];
      final span = _clipSpans(bars, clips).singleWhere((c) => c.id == id);
      expect(span.end + 250, lessThanOrEqualTo(cdStart + 1e-6));
      // Placed in the groove right before the variation, on beat 1.
      final at = bars.indexWhere(
          (b) => b.events.any((e) => e is ClipEvent && e.clipId == id));
      expect(bars[at].sectionIndex, vs - 1);
      expect(bars[at].events.whereType<ClipEvent>().first.tick, 0);
      // Latest such bar: one bar later would not fit any more.
      expect(s[at] + _barMs(bars[at]) + 3200 + 250, greaterThan(cdStart));
    }
  }

  void expectNoOverlap(List<RunBar> bars, ClipManifest clips) {
    final spans = _clipSpans(bars, clips)
      ..sort((a, b) => a.start.compareTo(b.start));
    for (var i = 1; i < spans.length; i++) {
      expect(spans[i].start, greaterThanOrEqualTo(spans[i - 1].end - 1e-6),
          reason: '${spans[i - 1].id} overlaps ${spans[i].id}');
    }
  }

  test('countdown speaks only go when words exceed two beats', () {
    // 240 bpm: two beats = 500 ms, words 600 ms.
    final clips = _clips(cd: 600);
    final bars = buildRun(_fixture(), bpm: 240, options: on, clips: clips);
    for (final vs in [2, 4]) {
      final vi = _firstBarOf(bars, vs);
      final cd = bars[vi - 1];
      expect(cd.events.whereType<ClipEvent>(), isEmpty);
      final counts = cd.events.whereType<CountdownEvent>().toList();
      expect(counts, isNotEmpty);
      final click = cd.tickVolumes[RunSound.click]!;
      for (final c in counts) {
        expect(click[c.tick], 1.0);
      }
      expect(bars[vi].events.whereType<ClipEvent>().single.clipId, 'cd_go');
    }
    expect(
        bars[0].events.whereType<ClipEvent>().map((e) => e.clipId), ['ci_one']);
    expectNoOverlap(bars, clips);
  });

  test('half count-in speaks one and three, clicks all four', () {
    final clips = _clips();
    final bars = buildRun(_fixture(), bpm: 240, options: on, clips: clips);
    expect({
      for (final e in bars[0].events.whereType<ClipEvent>()) e.tick: e.clipId
    }, {
      0: 'ci_one',
      48: 'ci_three'
    });
    final click = bars[0].tickVolumes[RunSound.click]!;
    expect([
      for (var t = 0; t < 96; t++)
        if (click[t] > 0) t
    ], [
      0,
      24,
      48,
      72
    ]);
    expectNoOverlap(bars, clips);
  });

  test('long after-phrase extends the groove without overlap', () {
    // 100 bpm, bar 2400 ms: explanation needs 2 lead bars (fits 4 bars),
    // the 2600 ms after-phrase needs 2 more → groove 2 grows to 5 bars.
    final clips = ClipManifest.fromJson({
      'clips': [
        {'id': 'v1', 'ms': 3200},
        {'id': 'v2', 'ms': 3200},
        {'id': 'good', 'ms': 2600},
        for (final id in [...countdownClipIds, ...countInClipIds])
          {'id': id, 'ms': 400},
      ]
    });
    final bars = buildRun(_fixture(), bpm: 100, options: on, clips: clips);
    expect(bars.where((b) => b.sectionIndex == 1).length, 4);
    expect(bars.where((b) => b.sectionIndex == 3).length, 5);
    final spans = _clipSpans(bars, clips);
    final good = spans.firstWhere((c) => c.id == 'good');
    final v2 = spans.singleWhere((c) => c.id == 'v2');
    expect(v2.start, greaterThanOrEqualTo(good.end - 1e-6));
    expectNoOverlap(bars, clips);
    expectExplanationFits(bars, clips);
  });

  test('explanation ends before countdown at 100 bpm', () {
    final clips = _clips();
    final bars = buildRun(_fixture(), bpm: 100, options: on, clips: clips);
    expectExplanationFits(bars, clips);
  });

  test('extends relax bars at 240 bpm', () {
    final clips = _clips();
    final bars = buildRun(_fixture(), bpm: 240, options: on, clips: clips);
    final groove2 = bars.where((b) => b.sectionIndex == 3).toList();
    expect(groove2.length, greaterThan(4));
    expect([for (final b in groove2) b.barInSection],
        List.generate(groove2.length, (i) => i));
    expectExplanationFits(bars, clips);
  });

  test('teacher off has no clips', () {
    final bars = buildRun(_fixture(),
        bpm: 240, options: const RunOptions(teacher: false), clips: _clips());
    expect(bars.expand((b) => b.events).whereType<ClipEvent>(), isEmpty);
    // No auto extension without the voice.
    expect(bars.length, 30);
    final vi = _firstBarOf(bars, 2);
    final cd = bars[vi - 1];
    final click = cd.tickVolumes[RunSound.click]!;
    for (final c in cd.events.whereType<CountdownEvent>()) {
      expect(click[c.tick], 1.5);
    }
    expect(bars[vi].tickVolumes[RunSound.click]![0], 1.5);
  });

  test('countdown counts identical with teacher on and off', () {
    List<List<int>> counts(RunOptions o) => [
          for (final b
              in buildRun(_fixture(), bpm: 100, options: o, clips: _clips()))
            [for (final e in b.events.whereType<CountdownEvent>()) e.remaining]
        ];
    expect(counts(const RunOptions(teacher: false)), counts(on));
  });

  test('playAlong off is click only', () {
    final bars = buildRun(_fixture(),
        bpm: 100, options: const RunOptions(playAlong: false), clips: _clips());
    for (final b in bars) {
      expect(b.tickVolumes.keys.toSet(), {RunSound.click});
      final click = b.tickVolumes[RunSound.click]!;
      expect([
        for (var t = 0; t < 96; t++)
          if (click[t] > 0) t
      ], [
        0,
        24,
        48,
        72
      ]);
    }
  });

  test('playAlong on plays the line, click only for count-in and countdown',
      () {
    final bars = buildRun(_fixture(), bpm: 100, options: on, clips: _clips());
    final groove = bars[1];
    expect(groove.tickVolumes.containsKey(RunSound.click), isFalse);
    final pattern = groove.tickVolumes[RunSound.pattern]!;
    expect(pattern[0], 2.0); // accent, PatternPlayback value
    expect(pattern[12], 0.85);
    final vi = _firstBarOf(bars, 2);
    expect(bars[vi - 1].tickVolumes[RunSound.click]![24], 1.0);
    expect(bars[vi].tickVolumes[RunSound.pattern]![24], 2.0);
  });

  test('kit line maps kick and hi-hat to their sounds', () {
    final hh = [for (var i = 0; i < 8; i++) i.isEven ? _acc : _r];
    final kick = [
      _r,
      const StrokeBeat.rest(),
      const StrokeBeat.rest(),
      const StrokeBeat.rest(),
      _r,
      const StrokeBeat.rest(),
      const StrokeBeat.rest(),
      const StrokeBeat.rest(),
    ];
    final snare = [
      const StrokeBeat.rest(),
      const StrokeBeat.rest(),
      _r,
      const StrokeBeat.rest(),
      const StrokeBeat.rest(),
      const StrokeBeat.rest(),
      _r,
      const StrokeBeat.rest(),
    ];
    final line = ExerciseLine.kit([
      Voice(KitInstrument.hiHatClosed, hh),
      Voice(KitInstrument.kick, kick),
      Voice(KitInstrument.snare, snare),
    ]);
    final ex = GuidedExercise(
      id: 'k',
      name: 'K',
      description: 'd',
      package: GuidedPackage.kit,
      difficulty: Difficulty.beginner,
      defaultBpm: 100,
      minBpm: 40,
      maxBpm: 240,
      gridUnit: NoteGrid.eighth,
      sections: [
        const GuidedSection(
            kind: SectionKind.intro, line: ExerciseLine([]), bars: 0),
        GuidedSection(kind: SectionKind.groove, line: line, bars: 2),
        GuidedSection(kind: SectionKind.outro, line: line, bars: 1),
      ],
    );
    final b = buildRun(ex, bpm: 100, options: on, clips: _clips())[1];
    final v = b.tickVolumes;
    expect(v[RunSound.kick]![0], 0.7);
    expect(v[RunSound.kick]![12], 0);
    expect(v[RunSound.hihatLoud]![0], 1.0);
    expect(v[RunSound.hihatLoud]![12], 0);
    expect(v[RunSound.hihatSoft]![12], 0.7);
    expect(v[RunSound.hihatSoft]![0], 0);
    expect(v[RunSound.pattern]![24], 0.85); // snare in the pattern sound
    expect(v[RunSound.pattern]![0], 0); // kick/hi-hat come from samples
  });

  List<int> sectionSeq(Iterable<RunBar> bars) {
    final out = <int>[];
    for (final b in bars) {
      if (out.isEmpty || out.last != b.sectionIndex) out.add(b.sectionIndex);
    }
    return out;
  }

  test('from cursor at section end continues with next section', () {
    final ex = _fixture();
    final clips = _clips();
    final before = buildRun(ex, bpm: 100, options: on, clips: clips);
    // Last bar of variation 1 (section 2).
    final at = before.lastWhere((b) => b.sectionIndex == 2);
    expect(at.globalBar, 12);
    final cursor = RunCursor(
        sectionIndex: at.sectionIndex,
        barInSection: at.barInSection,
        globalBar: at.globalBar,
        sectionBars: before.where((b) => b.sectionIndex == 2).length);
    final after =
        buildRun(ex, bpm: 140, options: on, clips: clips, from: cursor);
    expect(after.first.globalBar, 13);
    expect(after.first.bpm, 140);
    expect((after.first.sectionIndex, after.first.barInSection), (3, 0));
    for (var i = 1; i < after.length; i++) {
      expect(after[i].globalBar, after[i - 1].globalBar + 1);
    }
    expect(sectionSeq([...before.take(13), ...after]), sectionSeq(before));
    // Every variation still gets a full countdown bar.
    final vi = _firstBarOf(after, 4);
    final cd = after[vi - 1];
    expect(cd.isCountdown, isTrue);
    expect([for (final e in cd.events.whereType<CountdownEvent>()) e.remaining],
        [3, 2, 1]);
    expect(after.where((b) => b.isCountdown).length, 1);
    expectExplanationFits([...before.take(13), ...after], clips);
  });

  test('from cursor mid-section throws', () {
    expect(
        () => buildRun(_fixture(),
            bpm: 140,
            options: on,
            clips: _clips(),
            from: const RunCursor(
                sectionIndex: 2,
                barInSection: 5,
                globalBar: 10,
                sectionBars: 8)),
        throwsArgumentError);
  });

  test('from count-in starts at the first section', () {
    final after = buildRun(_fixture(),
        bpm: 100,
        options: on,
        clips: _clips(),
        from: const RunCursor(
            sectionIndex: -1, barInSection: 0, globalBar: 0, sectionBars: 1));
    expect(after.first.sectionIndex, 1);
    expect(after.first.globalBar, 1);
    expect(after.length, 29);
  });

  test('about five minutes', () {
    final ex = _ex([
      const GuidedSection(
          kind: SectionKind.intro, line: ExerciseLine([]), bars: 0),
      _g(8),
      _v(16, 'v1'),
      _g(8),
      _v(16, 'v2'),
      _g(8),
      _v(16, 'v3'),
      _g(8),
      _v(16, 'v4'),
      _g(8),
      GuidedSection(kind: SectionKind.outro, line: _groove(), bars: 1),
    ]);
    ex.validate();
    final bars = buildRun(ex, bpm: 100, options: on, clips: _clips());
    final min = bars.fold<double>(0, (t, b) => t + _barMs(b)) / 60000;
    expect(min, inInclusiveRange(4, 6));
  });
}
