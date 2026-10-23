import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import 'guided_player.dart';
import 'models/guided_exercise.dart';
import 'models/voice_clip.dart';
import 'run_clock.dart';
import 'run_plan.dart';

/// `Section 3 of 9 · Variation 1 · bar 5 · beat 2` (count-in: `Count-in ·
/// beat 2`) — the listening page's detailed line.
String guidedStatusLine(GuidedExercise ex, RunPosition p) {
  if (p.sectionIndex < 0) return 'Count-in · beat ${p.beat}';
  final s = ex.sections[p.sectionIndex];
  final label = switch (s.kind) {
    SectionKind.intro => 'Intro',
    SectionKind.groove => 'Groove',
    SectionKind.outro => 'Outro',
    SectionKind.variation =>
      'Variation ${guidedVariationNumber(ex, p.sectionIndex)}',
  };
  return 'Section ${p.sectionIndex + 1} of ${ex.sections.length} · $label'
      ' · bar ${p.barInSection + 1} · beat ${p.beat}';
}

/// `Variation 2 of 4 · bar 5`, `Groove · bar 3`, `Count-in`, `Ending` —
/// the practice screen's short line.
String guidedSectionLine(GuidedExercise ex, RunPosition p) {
  if (p.sectionIndex < 0) return 'Count-in';
  final s = ex.sections[p.sectionIndex];
  final bar = 'bar ${p.barInSection + 1}';
  return switch (s.kind) {
    SectionKind.intro => 'Intro · $bar',
    SectionKind.groove => 'Groove · $bar',
    SectionKind.outro => 'Ending',
    SectionKind.variation => 'Variation '
        '${guidedVariationNumber(ex, p.sectionIndex)} of ${ex.variationCount} · $bar',
  };
}

/// 1-based number of the variation at [sectionIndex] (it must be one).
int guidedVariationNumber(GuidedExercise ex, int sectionIndex) => ex.sections
    .take(sectionIndex + 1)
    .where((x) => x.kind == SectionKind.variation)
    .length;

/// The explanation of the variation that is playing ([coming] false) or of
/// the one that comes next ([coming] true); null when none is left.
({bool coming, String text})? guidedVariationText(
    GuidedExercise ex, int sectionIndex) {
  if (sectionIndex >= 0 &&
      ex.sections[sectionIndex].kind == SectionKind.variation) {
    return (coming: false, text: ex.sections[sectionIndex].textEn!);
  }
  for (var i = math.max(0, sectionIndex + 1); i < ex.sections.length; i++) {
    if (ex.sections[i].kind == SectionKind.variation) {
      return (coming: true, text: ex.sections[i].textEn!);
    }
  }
  return null;
}

/// Planned time of one section at the current tempo/options (the count-in
/// is section -1).
typedef GuidedSectionTime = ({int sectionIndex, int bars, double ms});

/// The page-side state of one guided run, shared by the practice screen and
/// the hidden listening page: subscribes to the player, guards start() in
/// flight, turns a frozen position into "Resume", an error into "stopped",
/// and keeps the time estimate.
///
/// Time: [plan] is [buildRun] at the current tempo/options, grouped by
/// section ([totalMs], [progress]); [elapsedMs] is the time actually played,
/// summed bar by bar from the positions at the tempo each bar was rendered.
///
/// Countdown: comes with the position ([RunPosition.countdown], set by the
/// run clock from the plan's countdown events of the bar actually playing),
/// so a tempo change that re-plans the rest cannot shift it.
class GuidedRunController extends ChangeNotifier {
  GuidedRunController({
    required this.player,
    required this.clips,
    required GuidedExercise exercise,
    int? bpm,
    RunOptions options = const RunOptions(),
  })  : _ex = exercise,
        _options = options {
    _bpm = _clamp(exercise, bpm ?? exercise.defaultBpm);
    _subs
      ..add(player.positions.listen(_onPosition))
      // A failed run stops appending; reset to stopped.
      ..add(player.errors.listen((e) {
        _error = '$e';
        _running = false;
        _paused = false;
        notifyListeners();
        unawaited(player.stop());
      }))
      // A frozen position paused the run on its own: show Resume.
      ..add(player.stateChanges.listen((_) => notifyListeners()))
      ..add(player.finished.listen((_) {
        _running = false;
        _paused = false;
        _finished = true;
        _playedMs = _doneMs + _barMs;
        notifyListeners();
      }));
    _replan();
  }

  final GuidedPlayer player;
  final ClipManifest clips;

  GuidedExercise _ex;
  late int _bpm;
  RunOptions _options;
  bool _running = false;
  bool _paused = false;
  bool _starting = false;
  bool _finished = false;
  bool _disposed = false;
  RunPosition? _pos;
  String? _error;
  List<GuidedSectionTime> _plan = const [];

  // Played time: bars before the current one, the current bar's length.
  double _doneMs = 0;
  double _barMs = 0;
  int? _bar;
  double _playedMs = 0;

  final _subs = <StreamSubscription<Object?>>[];

  GuidedExercise get exercise => _ex;
  int get bpm => _bpm;
  RunOptions get options => _options;

  /// A run is going (playing, paused or frozen).
  bool get running => _running;
  bool get starting => _starting;

  /// The run reached its end (cleared by the next start).
  bool get finished => _finished;
  RunPosition? get position => _pos;
  String? get error => _error;

  /// Paused by the user or by a frozen position.
  bool get showResume => _paused || player.isFrozen;

  /// Planned sections at the current tempo/options, count-in first.
  List<GuidedSectionTime> get plan => _plan;

  double get totalMs => _plan.fold(0.0, (a, s) => a + s.ms);

  /// Time played so far (the whole run once [finished]).
  double get elapsedMs {
    if (_finished) return _playedMs;
    final p = _pos;
    if (p == null) return 0;
    return _doneMs + _barMs * p.tick / runTicksPerBar;
  }

  /// Where the position sits in [plan], 0..1: by section, so the marker
  /// stays in the section that is playing whatever the tempo did before.
  double get progress {
    if (_finished) return 1;
    final p = _pos;
    final total = totalMs;
    if (p == null || total <= 0) return 0;
    var before = 0.0;
    for (final s in _plan) {
      if (s.sectionIndex == p.sectionIndex) {
        final bars = math.max(1, s.bars);
        final inBar =
            math.min(p.barInSection, bars - 1) + p.tick / runTicksPerBar;
        return ((before + s.ms * inBar / bars) / total).clamp(0.0, 1.0);
      }
      before += s.ms;
    }
    return 0;
  }

  static int _clamp(GuidedExercise ex, int bpm) => bpm
      .clamp(
          math.max(guidedMinBpm, ex.minBpm), math.min(guidedMaxBpm, ex.maxBpm))
      .toInt();

  void _onPosition(RunPosition p) {
    final last = _bar;
    final ms = guidedBeatsPerBar * 60000 / p.bpm;
    if (last == null) {
      // Bars before the first position seen: at this bar's tempo.
      _doneMs = p.bar * ms;
    } else if (p.bar != last) {
      _doneMs += _barMs + math.max(0, p.bar - last - 1) * ms;
    }
    _bar = p.bar;
    _barMs = ms;
    _pos = p;
    notifyListeners();
  }

  void _replan() {
    final out = <GuidedSectionTime>[];
    for (final b in buildRun(_ex, bpm: _bpm, options: _options, clips: clips)) {
      final ms = guidedBeatsPerBar * 60000 / b.bpm;
      if (out.isNotEmpty && out.last.sectionIndex == b.sectionIndex) {
        final l = out.removeLast();
        out.add(
            (sectionIndex: l.sectionIndex, bars: l.bars + 1, ms: l.ms + ms));
      } else {
        out.add((sectionIndex: b.sectionIndex, bars: 1, ms: ms));
      }
    }
    _plan = out;
  }

  /// Picks another exercise while stopped (listening page); false while a
  /// run is going.
  bool choose(GuidedExercise ex) {
    if (_running || identical(ex, _ex)) return false;
    _ex = ex;
    _bpm = _clamp(ex, ex.defaultBpm);
    _pos = null;
    _finished = false;
    _replan();
    notifyListeners();
    return true;
  }

  /// Starts the run from the top (also after it finished).
  Future<void> start() async {
    if (_starting) return;
    _running = true;
    _paused = false;
    _starting = true;
    _finished = false;
    _error = null;
    _pos = null;
    _bar = null;
    _doneMs = 0;
    _barMs = 0;
    notifyListeners();
    try {
      await player.start(_ex, bpm: _bpm, options: _options);
    } finally {
      _starting = false;
      if (!_disposed) notifyListeners();
    }
  }

  /// Start when stopped, otherwise pause / resume. Ignored while start() is
  /// in flight.
  Future<void> toggle() async {
    if (_starting) return;
    if (!_running) {
      await start();
    } else if (showResume) {
      player.resume();
      _paused = false;
      notifyListeners();
    } else {
      player.pause();
      _paused = true;
      notifyListeners();
    }
  }

  Future<void> stop() async {
    await player.stop();
    if (_disposed) return;
    _running = false;
    _paused = false;
    _pos = null;
    notifyListeners();
  }

  /// Sets the tempo (clamped to the exercise); the player takes it from the
  /// next bar.
  void setBpm(int bpm) {
    final next = _clamp(_ex, bpm);
    if (next == _bpm) return;
    player.setBpm(next);
    _bpm = next;
    _replan();
    notifyListeners();
  }

  void bump(int delta) => setBpm(_bpm + delta);

  void setOptions(RunOptions o) {
    player.setOptions(o);
    _options = o;
    _replan();
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    for (final s in _subs) {
      unawaited(s.cancel());
    }
    // The provider disposes the player; stop now so the run does not
    // outlive the page while the provider winds down.
    unawaited(player.stop());
    super.dispose();
  }
}
