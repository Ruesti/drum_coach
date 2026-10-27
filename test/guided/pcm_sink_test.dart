import 'dart:async';
import 'dart:typed_data';

import 'package:drum_coach/features/guided/pcm_sink.dart';
import 'package:flutter_test/flutter_test.dart';

/// Records the SoLoud calls; like SoLoud's buffer stream, adding data or
/// ending the data unpauses the voice.
class FakeSoloud implements SoloudStreamApi {
  final calls = <String>[];
  bool voicePaused = false;

  /// Answers for the next play() calls; when empty, a handle at once.
  final playAnswers = <Future<Object> Function()>[];
  int plays = 0;

  @override
  bool get isReady => true;
  @override
  Future<void> init() async {}
  @override
  Object openStream(int sampleRate, Duration maxBuffer) => 'src';
  @override
  void addData(Object source, Uint8List bytes) {
    calls.add('add');
    voicePaused = false; // checkBuffering
  }

  @override
  Future<Object> play(Object source, {required bool paused}) {
    plays++;
    calls.add('play(paused: $paused)');
    if (playAnswers.isNotEmpty) return playAnswers.removeAt(0)();
    voicePaused = paused;
    return Future.value('h$plays');
  }

  @override
  void setPause(Object handle, bool paused) {
    calls.add('setPause($handle, $paused)');
    voicePaused = paused;
  }

  @override
  void setDataIsEnded(Object source) {
    calls.add('ended');
    voicePaused = false; // checkBuffering(0)
  }

  @override
  bool isValidHandle(Object handle) => true;
  @override
  Duration position(Object handle) => const Duration(milliseconds: 250);
  @override
  Future<void> stop(Object handle) async => calls.add('stop($handle)');
  @override
  Future<void> disposeSource(Object source) async => calls.add('dispose');
}

Float32List _pcm() => Float32List(441);

void main() {
  test('append and markEnded while paused keep the voice paused', () async {
    final api = FakeSoloud();
    final sink = SoloudPcmSink(api: api);
    await sink.open(44100, maxBuffer: const Duration(seconds: 10));
    expect(sink.append(_pcm()), isTrue);
    await pumpEventQueue(); // play() returned h1
    sink.pause(true);
    expect(api.voicePaused, isTrue);
    expect(sink.append(_pcm()), isTrue);
    expect(api.voicePaused, isTrue, reason: 'addData unpaused the voice');
    expect(
        api.calls.sublist(api.calls.length - 2), ['add', 'setPause(h1, true)']);
    sink.markEnded();
    expect(api.voicePaused, isTrue, reason: 'setDataIsEnded unpaused it');
    sink.pause(false);
    expect(api.voicePaused, isFalse);
    // Not paused: no extra setPause after an append.
    await sink.open(44100, maxBuffer: const Duration(seconds: 10));
    api.calls.clear();
    sink.append(_pcm());
    await pumpEventQueue();
    sink.append(_pcm());
    expect(api.calls, ['add', 'play(paused: false)', 'add']);
  });

  test('a failed play() is retried on resume and on a position read', () async {
    final api = FakeSoloud()
      ..playAnswers.addAll([
        () => Future.error(TimeoutException('play')),
        () => Future.error(TimeoutException('play')),
      ]);
    final sink = SoloudPcmSink(api: api);
    await sink.open(44100, maxBuffer: const Duration(seconds: 10));
    sink.append(_pcm());
    await pumpEventQueue();
    expect(api.plays, 1);
    sink.pause(true);
    sink.pause(false); // resume retries
    await pumpEventQueue();
    expect(api.plays, 2);
    expect(sink.positionMs(), 0); // no voice yet: retries again
    await pumpEventQueue();
    expect(api.plays, 3);
    expect(sink.positionMs(), 250); // h3 plays
    expect(api.plays, 3);
  });

  test('pause(true) while play() is pending is applied to the new voice',
      () async {
    final api = FakeSoloud();
    final answer = Completer<Object>();
    api.playAnswers.add(() => answer.future);
    final sink = SoloudPcmSink(api: api);
    await sink.open(44100, maxBuffer: const Duration(seconds: 10));
    sink.append(_pcm()); // play(paused: false) pending
    sink.pause(true);
    answer.complete('h1');
    await pumpEventQueue();
    expect(api.calls.last, 'setPause(h1, true)');
    expect(api.voicePaused, isTrue);
  });

  test('pause(false) while a paused play() is pending unpauses the voice',
      () async {
    final api = FakeSoloud();
    final answer = Completer<Object>();
    api.playAnswers.add(() => answer.future);
    final sink = SoloudPcmSink(api: api);
    await sink.open(44100, maxBuffer: const Duration(seconds: 10));
    sink.pause(true);
    sink.append(_pcm()); // play(paused: true) pending
    sink.pause(false);
    answer.complete('h1');
    await pumpEventQueue();
    expect(api.calls, contains('play(paused: true)'));
    expect(api.calls.last, 'setPause(h1, false)');
  });
}
