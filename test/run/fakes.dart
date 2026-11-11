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

class FakeSource implements StrokeSource {
  FakeSource({this.strokes = const []});
  @override
  List<Stroke> strokes;
  final conn = StreamController<bool>.broadcast();
  bool started = false, stopped = false;
  @override
  Future<void> start() async => started = true;
  @override
  Future<void> stop() async => stopped = true;
  @override
  Stream<bool> get connection => conn.stream;
  @override
  String get deviceName => 'Fake Module';
  @override
  void dispose() {}
}

class FakeOut implements ClickOut {
  FakeOut(this.clock);
  final FakeClock clock;
  ClickTrack? played;
  bool stopped = false;
  @override
  Future<void> init() async {}
  @override
  Future<double> play(ClickTrack t) async {
    played = t;
    return clock.now;
  }

  @override
  Future<void> stop() async => stopped = true;
}
