import 'kit.dart';

const int ticksPerQuarter = 24;

/// One target hit inside a bar; `0 <= tick < beatsPerBar * ticksPerQuarter`.
class TargetHit {
  const TargetHit(this.voice, this.tick);
  final Voice voice;
  final int tick;
}

/// A target hit placed on the timeline. [bar] is 0-based.
class TargetTime {
  const TargetTime({
    required this.index,
    required this.voice,
    required this.bar,
    required this.timeMs,
  });
  final int index;
  final Voice voice;
  final int bar;
  final double timeMs;
}
