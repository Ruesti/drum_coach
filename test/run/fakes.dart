import 'dart:async';

import 'package:drum_coach/audio/click_player.dart';
import 'package:drum_coach/audio/click_track.dart';
import 'package:drum_coach/measure/stroke.dart';
import 'package:drum_coach/midi/stroke_source.dart';

/// Controllable clock: [wait] advances it instead of sleeping.
class FakeClock {
  double now = 1000000;
  void Function()? onTick;
  Future<void> wait(Duration d) async {
    now += d.inMicroseconds / 1000.0;
    onTick?.call();
    await Future<void>.delayed(Duration.zero);
  }
}

/// A clock whose [wait] blocks until [release]; [now] only moves when the
/// test sets it. Lets a widget test hold runs mid-way.
class ManualClock extends FakeClock {
  final _waiters = <Completer<void>>[];
  @override
  Future<void> wait(Duration d) {
    final c = Completer<void>();
    _waiters.add(c);
    return c.future;
  }

  void release() {
    final w = [..._waiters];
    _waiters.clear();
    for (final c in w) {
      c.complete();
    }
  }
}

class FakeSource implements StrokeSource {
  FakeSource({this.strokes = const []});
  @override
  List<Stroke> strokes;
  final conn = StreamController<bool>.broadcast();
  bool started = false, stopped = false;
  Future<void> Function()? onStart;
  Object? startError;
  @override
  Future<void> start() async {
    if (startError != null) throw startError!;
    started = true;
    await onStart?.call();
  }

  @override
  Future<void> stop() async => stopped = true;
  @override
  Stream<bool> get connection => conn.stream;
  @override
  String get deviceName => 'Fake Module';
  int disposed = 0;
  @override
  void dispose() => disposed++;
}

class FakeOut implements ClickOut {
  FakeOut(this.clock);
  final FakeClock clock;
  ClickTrack? played;
  bool stopped = false;
  Future<void> Function()? onPlay;
  @override
  Future<void> init() async {}
  @override
  Future<double> play(ClickTrack t) async {
    played = t;
    await onPlay?.call();
    stopped = false; // the click only really starts once play() completes
    return clock.now;
  }

  @override
  Future<void> stop() async => stopped = true;
}
