import 'dart:async';
import 'dart:typed_data';

import 'package:drum_coach/features/guided/bar_render_backend.dart';
import 'package:drum_coach/features/guided/guided_player.dart';
import 'package:drum_coach/features/guided/models/guided_exercise.dart';
import 'package:drum_coach/features/guided/models/voice_clip.dart';
import 'package:drum_coach/features/guided/pcm_sink.dart';
import 'package:drum_coach/features/guided/run_clock.dart';
import 'package:drum_coach/features/guided/run_plan.dart';
import 'package:drum_coach/features/lessons/models/rudiment.dart';
import 'package:flutter_test/flutter_test.dart';

class FakePcmSink implements PcmSink {
  final appended = <Float32List>[];
  final pauses = <bool>[];
  double pos = 0;
  bool opened = false;
  bool closed = false;
  bool ended = false;

  List<int> get counts => [for (final b in appended) b.length];

  /// Start (ms) of appended bar [i].
  double startMs(int i) =>
      appended.take(i).fold<int>(0, (n, b) => n + b.length) / 44.1;

  double get totalMs => startMs(appended.length);

  @override
  Future<void> open(int sampleRate, {required Duration maxBuffer}) async {
    await openGate?.future;
    opened = true;
    this.maxBuffer = maxBuffer;
  }

  Duration? maxBuffer;

  /// When set, open() waits for it.
  Completer<void>? openGate;

  /// Appends from this index on fail.
  int? failAppendAt;

  @override
  bool append(Float32List pcm) {
    if (failAppendAt != null && appended.length >= failAppendAt!) return false;
    appended.add(pcm);
    return true;
  }

  @override
  double positionMs() => pos;
  @override
  void pause(bool paused) => pauses.add(paused);
  @override
  void markEnded() => ended = true;
  @override
  Future<void> close() async => closed = true;
}

const _r = StrokeBeat(hand: Hand.right);
const _acc = StrokeBeat(hand: Hand.right, isAccent: true);
ExerciseLine _groove() =>
    const ExerciseLine([_acc, _r, _r, _r, _acc, _r, _r, _r]);
ExerciseLine _varLine() =>
    const ExerciseLine([_acc, _r, _acc, _r, _acc, _r, _acc, _r]);

/// count-in 0 | groove 1-4 (explanation v1 on bar 2, countdown bar 4) |
/// variation 5-12 | groove 13-16 | outro 17.
GuidedExercise _ex({int minBpm = 40, int maxBpm = 240}) => GuidedExercise(
      id: 'x',
      name: 'X',
      description: 'd',
      package: GuidedPackage.pad,
      difficulty: Difficulty.beginner,
      defaultBpm: 100,
      minBpm: minBpm,
      maxBpm: maxBpm,
      gridUnit: NoteGrid.eighth,
      sections: [
        const GuidedSection(
            kind: SectionKind.intro, line: ExerciseLine([]), bars: 0),
        GuidedSection(kind: SectionKind.groove, line: _groove(), bars: 4),
        GuidedSection(
            kind: SectionKind.variation,
            line: _varLine(),
            bars: 8,
            textEn: 'Accent every quarter.',
            speechClipId: 'v1',
            afterClipId: 'good'),
        GuidedSection(kind: SectionKind.groove, line: _groove(), bars: 4),
        GuidedSection(kind: SectionKind.outro, line: _groove(), bars: 1),
      ],
    );

const _clipMs = {'v1': 3200.0, 'good': 400.0};
double _ms(String id) => _clipMs[id] ?? 400;

final _manifest = ClipManifest.fromJson({
  'clips': [
    for (final id in ['v1', 'good', ...countdownClipIds, ...countInClipIds])
      {'id': id, 'ms': _ms(id)},
  ]
});

Future<VoiceClip> _loadClip(String id) async => VoiceClip(
    id, Float32List.fromList(List.filled((_ms(id) * 44.1).round(), 0.1)));

final _drums = <RunSound, List<double>>{
  RunSound.pattern: List.filled(800, 0.3),
  RunSound.kick: List.filled(800, 0.3),
  RunSound.hihatLoud: List.filled(400, 0.2),
  RunSound.hihatSoft: List.filled(400, 0.1),
  RunSound.click: List.filled(300, 0.4),
  RunSound.crash: const [],
};

/// Only the voice sounds: every non-zero sample comes from a clip.
const _silentDrums = <RunSound, List<double>>{};

GuidedPlayer _player(FakePcmSink sink,
        {Map<RunSound, List<double>>? sounds,
        DateTime Function()? now,
        double minQueuedMs = 0,
        BarRenderBackend? renderer,
        Future<VoiceClip> Function(String id)? loadClip}) =>
    GuidedPlayer(
      sink: sink,
      clips: _manifest,
      loadClip: loadClip ?? _loadClip,
      sounds: sounds ?? _drums,
      renderer: renderer ?? InlineBarRenderBackend(),
      autoPoll: false,
      minQueuedMs: minQueuedMs,
      now: now,
    );

/// Renders are held until the test completes them.
class GatedBackend implements BarRenderBackend {
  final pending = <Completer<Float32List>>[];
  int calls = 0;

  @override
  Future<void> init(Map<RunSound, List<double>> sounds) async {}
  @override
  Future<Float32List> render(BarJob job) {
    calls++;
    final c = Completer<Float32List>();
    pending.add(c);
    return c.future;
  }

  void completeFirst() =>
      pending.removeAt(0).complete(Float32List(_samplesAt(100)));

  @override
  void reset() {}
  @override
  Future<void> dispose() async {}
}

class ThrowingBackend extends InlineBarRenderBackend {
  int calls = 0;
  @override
  Future<Float32List> render(BarJob job) {
    if (++calls >= 3) return Future.error(StateError('boom'));
    return super.render(job);
  }
}

int _samplesAt(int bpm) => (4 * 60 / bpm * 44100).round();

/// Moves the play position just inside bar [bar] and polls.
Future<void> _playInto(GuidedPlayer p, FakePcmSink s, int bar) async {
  s.pos = s.startMs(bar) + 1;
  await p.poll();
}

void main() {
  test('appends lookahead on start', () async {
    final sink = FakePcmSink();
    final p = _player(sink);
    await p.start(_ex(), bpm: 100, options: const RunOptions());
    expect(sink.opened, isTrue);
    expect(sink.counts, [_samplesAt(100), _samplesAt(100)]);
    await p.stop();
    expect(sink.closed, isTrue);
  });

  test('time-based lookahead queues at least minQueuedMs', () async {
    final sink = FakePcmSink();
    final p = _player(sink, minQueuedMs: 2500);
    await p.start(_ex(), bpm: 240, options: const RunOptions());
    // 1000 ms per bar at 240: one bar ahead would be 2 bars; 2500 ms
    // queued need 3.
    expect(sink.appended.length, 3);
    sink.pos = 1500;
    await p.poll();
    expect(sink.appended.length, 4);
    expect(sink.totalMs - sink.pos, greaterThanOrEqualTo(2500));
    await p.stop();
  });

  test('tempo change while a bar is queued', () async {
    final sink = FakePcmSink();
    final p = _player(sink);
    final positions = <RunPosition>[];
    p.positions.listen(positions.add);
    await p.start(_ex(), bpm: 100, options: const RunOptions());
    for (var b = 1; b <= 5; b++) {
      await _playInto(p, sink, b);
    }
    expect(sink.appended.length, 7); // playing bar 5, bar 6 queued
    p.setBpm(140);
    expect(p.bpm, 140);
    await _playInto(p, sink, 6);
    expect(sink.counts[6], _samplesAt(100)); // already rendered: old tempo
    expect(sink.counts[7], _samplesAt(140));
    // Sweep to the end in 37 ms steps: positions never go back.
    final done = p.finished.first;
    var guard = 0;
    while (!sink.ended || sink.pos < sink.totalMs) {
      sink.pos += 37;
      await p.poll();
      if (++guard > 100000) fail('no end');
    }
    await p.poll();
    await done;
    expect(sink.counts.skip(7), everyElement(_samplesAt(140)));
    for (var i = 1; i < positions.length; i++) {
      final a = positions[i - 1], b = positions[i];
      expect(b.bar * 96 + b.tick, greaterThan(a.bar * 96 + a.tick));
    }
    expect(positions.last.bar, 17);
    expect(positions.firstWhere((e) => e.bar == 7).bpm, 140);
    expect(positions.firstWhere((e) => e.bar == 5).sectionIndex, 2);
    await p.stop();
  });

  test('teacher off applies to unrendered bars', () async {
    final sink = FakePcmSink();
    final p = _player(sink, sounds: _silentDrums);
    await p.start(_ex(), bpm: 100, options: const RunOptions());
    // Explanation v1 (3.2 s, longer than a 2.4-s bar) sits on bar 2.
    await _playInto(p, sink, 1); // bar 2 appended
    expect(sink.appended[2].any((v) => v != 0), isTrue);
    p.setOptions(const RunOptions(teacher: false));
    expect(p.options.teacher, isFalse);
    await _playInto(p, sink, 2); // bar 3 rendered after the switch
    final bar3 = sink.appended[3];
    // The clip started in bar 2 continues (carry intact) ...
    expect(bar3.first, isNot(0));
    final clipTail = (3200 * 44.1).round() - _samplesAt(100);
    expect(bar3[clipTail - 1], isNot(0));
    // ... and then nothing more is spoken.
    expect(bar3.skip(clipTail + 1).every((v) => v == 0), isTrue);
    var guard = 0;
    while (!sink.ended || sink.pos < sink.totalMs) {
      sink.pos += 500;
      await p.poll();
      if (++guard > 10000) fail('no end');
    }
    for (final bar in sink.appended.skip(4)) {
      expect(bar.every((v) => v == 0), isTrue);
    }
    await p.stop();
  });

  test('play-along off applies to unrendered bars', () async {
    final sink = FakePcmSink();
    final p = _player(sink, sounds: {RunSound.click: List.filled(100, 0.5)});
    await p.start(_ex(), bpm: 100, options: const RunOptions(teacher: false));
    // Only clicks sound; with play-along on a groove bar has no click.
    await _playInto(p, sink, 1);
    expect(sink.appended[2].every((v) => v == 0), isTrue);
    p.setOptions(const RunOptions(teacher: false, playAlong: false));
    await _playInto(p, sink, 2);
    final beat = _samplesAt(100) ~/ 4;
    final bar3 = sink.appended[3];
    for (var q = 0; q < 4; q++) {
      expect(bar3[q * beat], isNot(0), reason: 'click on beat ${q + 1}');
    }
    await p.stop();
  });

  test('frozen position pauses the run', () async {
    var t = DateTime(2026, 10, 18, 12);
    final sink = FakePcmSink();
    final p = _player(sink, now: () => t);
    final positions = <RunPosition>[];
    p.positions.listen(positions.add);
    await p.start(_ex(), bpm: 100, options: const RunOptions());
    sink.pos = 500;
    for (var i = 0; i < 110; i++) {
      await p.poll();
      t = t.add(const Duration(milliseconds: 10));
    }
    expect(sink.pauses, [true]);
    expect(positions, isNotEmpty);
    expect(positions.last.bar, 0);
    // Stopped polling: more polls do nothing until resume().
    final n = positions.length;
    sink.pos = 900;
    await p.poll();
    expect(positions.length, n);
    p.resume();
    expect(sink.pauses, [true, false]);
    await p.poll();
    expect(positions.length, n + 1);
    await p.stop();
  });

  test('user pause does not count as frozen', () async {
    var t = DateTime(2026, 10, 18, 12);
    final sink = FakePcmSink();
    final p = _player(sink, now: () => t);
    await p.start(_ex(), bpm: 100, options: const RunOptions());
    p.pause();
    expect(p.isPaused, isTrue);
    for (var i = 0; i < 200; i++) {
      await p.poll();
      t = t.add(const Duration(milliseconds: 10));
    }
    expect(sink.pauses, [true]);
    p.resume();
    expect(sink.pauses, [true, false]);
    await p.stop();
  });

  test('finished fires after outro', () async {
    final sink = FakePcmSink();
    final p = _player(sink);
    var finished = 0;
    p.finished.listen((_) => finished++);
    await p.start(_ex(), bpm: 200, options: const RunOptions());
    var guard = 0;
    while (!sink.ended) {
      sink.pos += 300;
      await p.poll();
      if (++guard > 10000) fail('no end');
    }
    expect(sink.appended.length, 18); // count-in + 16 + outro
    await p.poll();
    expect(finished, 0); // outro still playing
    sink.pos = sink.totalMs;
    await p.poll();
    await pumpEventQueue();
    expect(finished, 1);
    await p.poll();
    await pumpEventQueue();
    expect(finished, 1);
    await p.stop();
  });

  test('bpm clamps to 40..240', () async {
    final sink = FakePcmSink();
    final p = _player(sink);
    await p.start(_ex(), bpm: 300, options: const RunOptions());
    expect(p.bpm, 240);
    expect(sink.counts.first, _samplesAt(240));
    p.setBpm(10);
    expect(p.bpm, 40);
    p.setBpm(1000);
    expect(p.bpm, 240);
    await p.stop();
  });

  test('crash plays on the pad quieter than the kit', () {
    expect(crashGainFor(GuidedPackage.pad), 0.4);
    expect(crashGainFor(GuidedPackage.kit), 1.0);
  });

  test('isolate backend renders the same bars as inline', () async {
    final plan = buildRun(_ex(),
        bpm: 120, options: const RunOptions(), clips: _manifest);
    final clip = (await _loadClip('v1')).samples;
    final jobs = [
      for (final bar in plan.take(4))
        barJobFor(bar,
            clips: {
              'v1': clip,
              'good': clip,
              for (final id in [...countdownClipIds, ...countInClipIds])
                id: clip
            },
            crashGain: 0.4)
    ];
    final a = InlineBarRenderBackend();
    final b = IsolateBarRenderBackend();
    await a.init(_drums);
    await b.init(_drums);
    for (final j in jobs) {
      final x = await a.render(j);
      final y = await b.render(j);
      expect(y, orderedEquals(x));
    }
    await b.dispose();
    await a.dispose();
  });

  test('slow run fits the stream', () async {
    final sink = FakePcmSink();
    final p = _player(sink);
    final ex = _ex(minBpm: 40);
    await p.start(ex, bpm: 40, options: const RunOptions());
    var guard = 0;
    while (!sink.ended) {
      sink.pos += 1000;
      await p.poll();
      if (++guard > 10000) fail('no end');
    }
    final planned =
        buildRun(ex, bpm: 40, options: const RunOptions(), clips: _manifest)
            .length;
    expect(sink.appended.length, planned);
    expect(sink.maxBuffer!.inMicroseconds / 1000,
        greaterThanOrEqualTo(sink.totalMs * 1.25 + 30000 - 1));
    await p.stop();
  });

  test('bpm clamps to the exercise range during a run', () async {
    final sink = FakePcmSink();
    final p = _player(sink);
    await p.start(_ex(minBpm: 60, maxBpm: 200),
        bpm: 30, options: const RunOptions());
    expect(p.bpm, 60);
    p.setBpm(10);
    expect(p.bpm, 60);
    p.setBpm(230);
    expect(p.bpm, 200);
    await p.stop();
  });

  test('failed append surfaces an error', () async {
    final sink = FakePcmSink()..failAppendAt = 3;
    final p = _player(sink);
    final errors = <Object>[];
    p.errors.listen(errors.add);
    await p.start(_ex(), bpm: 100, options: const RunOptions());
    for (var b = 1; b <= 6; b++) {
      sink.pos = 2400.0 * b + 1;
      await p.poll();
    }
    await pumpEventQueue();
    expect(sink.appended.length, 3);
    expect(errors, hasLength(1));
    await p.stop();
  });

  test('render error surfaces on errors', () async {
    final sink = FakePcmSink();
    final p = _player(sink, renderer: ThrowingBackend());
    final errors = <Object>[];
    p.errors.listen(errors.add);
    await p.start(_ex(), bpm: 100, options: const RunOptions());
    await _playInto(p, sink, 1);
    await _playInto(p, sink, 1);
    await pumpEventQueue();
    expect(sink.appended.length, 2);
    expect(errors.single, isA<StateError>());
    await p.stop();
  });

  test('restart during pending fill keeps one fill loop', () async {
    final sink = FakePcmSink();
    final gate = GatedBackend();
    final p = _player(sink, renderer: gate);
    unawaited(p.start(_ex(), bpm: 100, options: const RunOptions()));
    await pumpEventQueue();
    expect(gate.pending, hasLength(1)); // run A, bar 0
    final second = p.start(_ex(), bpm: 100, options: const RunOptions());
    await pumpEventQueue();
    expect(gate.pending, hasLength(2)); // run B, bar 0
    gate.completeFirst(); // stale run A finishes
    await pumpEventQueue();
    unawaited(p.poll());
    await pumpEventQueue();
    expect(gate.pending, hasLength(1), reason: 'a second fill loop started');
    gate.completeFirst();
    await pumpEventQueue();
    gate.completeFirst();
    await second;
    expect(sink.appended, hasLength(2));
    await p.stop();
  });

  test('tempo set during start applies to the first bar', () async {
    final sink = FakePcmSink();
    final p = _player(sink);
    sink.openGate = Completer<void>();
    final f = p.start(_ex(), bpm: 100, options: const RunOptions());
    await pumpEventQueue(); // queue planned at 100, open() pending
    p.setBpm(140);
    sink.openGate!.complete();
    await f;
    expect(p.bpm, 140);
    expect(sink.counts, everyElement(_samplesAt(140)));
    await p.stop();
  });

  test('teacher off restamp accents the countdown clicks', () async {
    final sink = FakePcmSink();
    final p = _player(sink, sounds: {RunSound.click: List.filled(50, 0.1)});
    await p.start(_ex(), bpm: 100, options: const RunOptions());
    await _playInto(p, sink, 1);
    await _playInto(p, sink, 2); // bar 3 appended, countdown bar 4 not yet
    p.setOptions(const RunOptions(teacher: false));
    await _playInto(p, sink, 3);
    final bar4 = sink.appended[4];
    final beat = _samplesAt(100) ~/ 4;
    expect(bar4[beat], closeTo(0.15, 0.01)); // "3" click, accent 1.5
  });

  test('a failed clip load is retried', () async {
    final sink = FakePcmSink();
    final tried = <String>{};
    Future<VoiceClip> flaky(String id) async {
      if (tried.add(id)) throw StateError('not yet');
      return _loadClip(id);
    }

    final p = _player(sink, sounds: _silentDrums, loadClip: flaky);
    await p.start(_ex(), bpm: 100, options: const RunOptions());
    await _playInto(p, sink, 1); // bar 2 with the explanation
    expect(sink.appended[2].any((v) => v != 0), isTrue);
    await p.stop();
  });
}
