import 'models/guided_exercise.dart';

/// Where a guided run is right now, derived from the stream's play position.
class RunPosition {
  const RunPosition({
    required this.bar,
    required this.sectionIndex,
    required this.barInSection,
    required this.beat,
    required this.tick,
    required this.bpm,
    required this.plannedAt,
    this.countdown,
  });

  /// Global bar of the run (the count-in is 0).
  final int bar;

  /// Index into [GuidedExercise.sections]; -1 for the count-in.
  final int sectionIndex;
  final int barInSection;

  /// 1-based beat of the bar (1..4).
  final int beat;

  /// Tick within the bar (0..95 on the 24-ticks-per-quarter grid).
  final int tick;

  /// Tempo the bar was rendered at.
  final int bpm;

  /// Wall time at which [tick] started sounding: the poll time minus the
  /// offset into the tick, so the poll cadence does not blur it.
  final DateTime plannedAt;

  /// Countdown step on screen: 3, 2, 1, or 0 = GO; null outside the
  /// countdown. From the plan's countdown events of this bar (they are
  /// planned with the teacher off too): the last step reached in the bar;
  /// GO (on beat 1 of the variation) lasts one beat.
  final int? countdown;
}

/// A countdown step of one bar: [remaining] from [tick] on.
typedef CountdownStep = ({int tick, int remaining});

class _ClockBar {
  const _ClockBar(this.index, this.startMs, this.bpm, this.ticks,
      this.sectionIndex, this.barInSection, this.countdown);
  final int index;
  final double startMs;
  final int bpm;
  final int ticks;
  final int sectionIndex;
  final int barInSection;
  final List<CountdownStep> countdown;

  double get tickMs => 60000 / bpm / (ticks / guidedBeatsPerBar);
}

/// Maps the stream position (ms since the first appended sample) to the bar,
/// beat and tick of the run. Bars are added in order as they are appended;
/// lookup is a binary search, so tempo changes between bars need no
/// special handling.
class RunClock {
  final _bars = <_ClockBar>[];

  /// Registers bar [index] that starts [startMs] into the stream and has
  /// [ticks] ticks at [bpm] (4/4). [countdownSteps]: the bar's countdown
  /// events, sorted by tick.
  void addBar(int index, double startMs, int bpm, int ticks,
      {int sectionIndex = 0,
      int barInSection = 0,
      List<CountdownStep> countdownSteps = const []}) {
    if (_bars.isNotEmpty && startMs < _bars.last.startMs) {
      throw ArgumentError('bars must be added in order: '
          '$startMs < ${_bars.last.startMs}');
    }
    _bars.add(_ClockBar(index, startMs, bpm, ticks, sectionIndex, barInSection,
        countdownSteps));
  }

  bool get isEmpty => _bars.isEmpty;

  /// Position at [positionMs]; null before the first bar. Past the last bar
  /// it stays on the last bar's last tick. [now] defaults to the wall clock.
  RunPosition? at(double positionMs, {DateTime? now}) {
    if (_bars.isEmpty || positionMs < _bars.first.startMs) return null;
    var lo = 0, hi = _bars.length - 1;
    while (lo < hi) {
      final mid = (lo + hi + 1) >> 1;
      if (_bars[mid].startMs <= positionMs) {
        lo = mid;
      } else {
        hi = mid - 1;
      }
    }
    final b = _bars[lo];
    final tickMs = b.tickMs;
    final offset = positionMs - b.startMs;
    var tick = (offset / tickMs).floor();
    var inTick = offset - tick * tickMs;
    if (tick >= b.ticks) {
      tick = b.ticks - 1;
      inTick = 0;
    }
    int? countdown;
    for (final step in b.countdown) {
      if (step.tick <= tick) countdown = step.remaining;
    }
    if (countdown == 0 && tick >= b.ticks ~/ guidedBeatsPerBar) {
      countdown = null;
    }
    final t = now ?? DateTime.now();
    return RunPosition(
      bar: b.index,
      sectionIndex: b.sectionIndex,
      barInSection: b.barInSection,
      beat: tick ~/ (b.ticks ~/ guidedBeatsPerBar) + 1,
      tick: tick,
      bpm: b.bpm,
      plannedAt: t.subtract(Duration(microseconds: (inTick * 1000).round())),
      countdown: countdown,
    );
  }
}
