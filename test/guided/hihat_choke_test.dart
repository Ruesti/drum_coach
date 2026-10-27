import 'dart:io';
import 'dart:math' as math;

import 'package:drum_coach/features/guided/bar_render_backend.dart';
import 'package:drum_coach/features/guided/bar_renderer.dart';
import 'package:drum_coach/features/guided/data/guided_catalog.dart';
import 'package:drum_coach/features/guided/models/guided_exercise.dart';
import 'package:drum_coach/features/guided/models/voice_clip.dart';
import 'package:drum_coach/features/guided/run_plan.dart';
import 'package:drum_coach/features/guided/sample_bank.dart';
import 'package:drum_coach/features/metronome/click_loop_renderer.dart';
import 'package:drum_coach/features/metronome/snare_sample.dart';
import 'package:flutter_test/flutter_test.dart';

const _sr = 44100;

ClipManifest _clipsFor(GuidedExercise ex) => ClipManifest.fromJson({
      'clips': [
        for (final s in ex.sections) ...[
          if (s.speechClipId != null) {'id': s.speechClipId, 'ms': 3000},
          if (s.afterClipId != null) {'id': s.afterClipId, 'ms': 400},
        ],
        for (final id in [...countdownClipIds, ...countInClipIds])
          {'id': id, 'ms': 400},
      ]
    });

double _rms(List<double> s, int from, int to) {
  from = from.clamp(0, s.length);
  to = to.clamp(from, s.length);
  if (to <= from) return 0;
  var sum = 0.0;
  for (var i = from; i < to; i++) {
    sum += s[i] * s[i];
  }
  return math.sqrt(sum / (to - from));
}

void main() {
  test('a choke fades the open hat within the bar and across bars', () {
    final r = BarRenderer();
    final open = List<double>.filled(_sr * 2, 0.5); // rings 2 s
    final vols = List<double>.filled(96, 0.0)..[84] = 1.0; // last eighth
    final bar1 = r.renderBar(bpm: 120, factor: 24, voices: const [], choked: [
      LoopVoice(tickVolumes: vols, loudSamples: open, softSamples: open)
    ]).pcm;
    expect(bar1.last, closeTo(0.5, 1e-6)); // still open at the bar end
    final bar2 = r.renderBar(
        bpm: 120, factor: 24, voices: const [], chokeTicks: const [0]).pcm;
    final fade = (BarRenderer.chokeFadeMs * _sr / 1000).round();
    expect(bar2[fade + 1], 0.0);
    expect(bar2.last, 0.0);
    expect(r.flush(), everyElement(0.0));
  });

  test('without a choke the open hat rings on into the next bars', () {
    final r = BarRenderer();
    final open = List<double>.filled(_sr * 2, 0.5);
    final vols = List<double>.filled(96, 0.0)..[84] = 1.0;
    r.renderBar(bpm: 120, factor: 24, voices: const [], choked: [
      LoopVoice(tickVolumes: vols, loudSamples: open, softSamples: open)
    ]);
    final bar2 = r.renderBar(bpm: 120, factor: 24, voices: const []).pcm;
    expect(bar2[2000], closeTo(0.5, 1e-6));
  });

  for (final id in [
    'guided_kit_funk_sixteenths',
    'guided_kit_halftime_shuffle'
  ]) {
    test('$id V-last: open hat is ≤ −30 dB after the next closed hit',
        () async {
      final ex = guidedCatalog.firstWhere((e) => e.id == id);
      final si =
          ex.sections.lastIndexWhere((s) => s.kind == SectionKind.variation);
      final bars = buildRun(ex,
              bpm: ex.defaultBpm,
              options: const RunOptions(teacher: false),
              clips: _clipsFor(ex))
          .where((b) => b.sectionIndex == si && b.barInSection < 4)
          .toList();
      final open = decodeMonoWav16(
              File(SampleBank.assets[RunSound.hihatOpen]!).readAsBytesSync())
          .toList();
      // Only the open hat sounds; the closed hat is silent but still chokes.
      final sounds = {
        RunSound.hihatOpen: open,
        RunSound.hihatClosed: const [0.0],
        RunSound.hihatPedal: const [0.0],
      };
      final backend = InlineBarRenderBackend();
      await backend.init(sounds);
      final pcm = <double>[];
      final events = <({int sample, bool isOpen})>[];
      final barSamples = 4 * 60 / ex.defaultBpm * _sr;
      for (var b = 0; b < bars.length; b++) {
        final v = bars[b].tickVolumes;
        for (var t = 0; t < runTicksPerBar; t++) {
          final at =
              (b * barSamples + t * 60 / ex.defaultBpm / 24 * _sr).round();
          if ((v[RunSound.hihatOpen]?[t] ?? 0) > 0) {
            events.add((sample: at, isOpen: true));
          }
          if ((v[RunSound.hihatClosed]?[t] ?? 0) > 0 ||
              (v[RunSound.hihatPedal]?[t] ?? 0) > 0) {
            events.add((sample: at, isOpen: false));
          }
        }
        pcm.addAll(await backend.render(BarJob(bpm: bars[b].bpm, tickVolumes: {
          for (final e in v.entries)
            if (sounds.containsKey(e.key)) e.key: e.value
        })));
      }
      pcm.addAll(await backend.flush());
      final opens = events.where((e) => e.isOpen).toList();
      expect(opens, isNotEmpty, reason: 'V-last has an open hat');
      var checked = 0;
      for (final o in opens) {
        final next = events
            .where((e) => !e.isOpen && e.sample > o.sample)
            .map((e) => e.sample)
            .fold<int?>(null, (m, s) => m == null || s < m ? s : m);
        if (next == null) continue;
        final before = _rms(pcm, o.sample, next);
        final fade = (BarRenderer.chokeFadeMs * _sr / 1000).round();
        final after = _rms(pcm, next + fade + 2, next + fade + 2 + _sr ~/ 10);
        expect(before, greaterThan(0.01));
        final db = 20 * math.log(math.max(after, 1e-12) / before) / math.ln10;
        expect(db, lessThanOrEqualTo(-30), reason: 'open hat at ${o.sample}');
        checked++;
      }
      expect(checked, greaterThan(0));
    });
  }

  test('kit mix keeps headroom: groove and V-last peak ≤ 0.9', () async {
    final sounds = SampleBank(recordings: {
      for (final e in SampleBank.assets.entries)
        e.key: decodeMonoWav16(File(e.value).readAsBytesSync()).toList(),
    }).toSoundMap();
    for (final ex
        in guidedCatalog.where((e) => e.package == GuidedPackage.kit)) {
      final run = buildRun(ex,
          bpm: ex.defaultBpm,
          options: const RunOptions(teacher: false),
          clips: _clipsFor(ex));
      final groove =
          ex.sections.indexWhere((s) => s.kind == SectionKind.groove);
      final last =
          ex.sections.lastIndexWhere((s) => s.kind == SectionKind.variation);
      for (final si in [groove, last]) {
        final backend = InlineBarRenderBackend();
        await backend.init(sounds);
        var peak = 0.0;
        for (final b in run.where((b) => b.sectionIndex == si).take(4)) {
          final job = barJobFor(
              RunBar(
                  globalBar: b.globalBar,
                  sectionIndex: b.sectionIndex,
                  barInSection: b.barInSection,
                  bpm: b.bpm,
                  isCountIn: false,
                  isCountdown: false,
                  tickVolumes: {
                    for (final e in b.tickVolumes.entries)
                      if (e.key != RunSound.click) e.key: e.value
                  },
                  events: b.events.whereType<CrashEvent>().toList()),
              clips: const {},
              crashGain: kitMixLevel);
          for (final v in await backend.render(job)) {
            peak = math.max(peak, v.abs());
          }
        }
        expect(peak, lessThanOrEqualTo(0.9), reason: '${ex.id} section $si');
        expect(peak, greaterThan(0.4), reason: '${ex.id} section $si');
      }
    }
  });
}
