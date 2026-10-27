import 'dart:math' as math;

import '../../shared/widgets/kit_layout.dart';
import '../coaching/midi/kit_instrument.dart';
import '../lessons/models/pattern_playback.dart';
import '../lessons/models/rudiment.dart';
import '../practice/kit_backing.dart';
import 'models/guided_exercise.dart';
import 'models/voice_clip.dart';

/// What a bar sounds; the player resolves each to PCM (one recording per
/// kit instrument, Optik-Runde 1: "Crash hört sich an wie snare").
///
/// - [pattern]: a pad line — the pad snare recording.
/// - kit voices: see [runSoundOf]. [snareGhost] never appears in
///   [RunBar.tickVolumes]: it is the soft sample the renderer uses for
///   ghost strokes of [snare].
/// - [crash] also plays for a [CrashEvent] (start of the first groove and
///   of the ending).
/// - [click]: count-in, countdown and the play-along-off quarter click.
enum RunSound {
  pattern,
  kick,
  snare,
  snareGhost,
  rim,
  hihatClosed,
  hihatOpen,
  hihatPedal,
  tomHigh,
  tomLow,
  tomFloor,
  crash,
  ride,
  rideBell,
  click,
}

/// The sound a kit voice plays. Toms: the high rack tom is [RunSound.tomHigh],
/// the low rack tom [RunSound.tomLow], both floor toms [RunSound.tomFloor];
/// every crash-like cymbal (crash 1/2, china, splash) is [RunSound.crash].
/// The microphone pad (and an unknown note) plays the pad snare.
RunSound runSoundOf(KitInstrument i) => switch (i) {
      KitInstrument.kick => RunSound.kick,
      KitInstrument.snare => RunSound.snare,
      KitInstrument.snareRim => RunSound.rim,
      KitInstrument.hiHatClosed => RunSound.hihatClosed,
      KitInstrument.hiHatOpen => RunSound.hihatOpen,
      KitInstrument.hiHatPedal => RunSound.hihatPedal,
      KitInstrument.tom1 => RunSound.tomHigh,
      KitInstrument.tom2 => RunSound.tomLow,
      KitInstrument.floorTom1 || KitInstrument.floorTom2 => RunSound.tomFloor,
      KitInstrument.crash1 ||
      KitInstrument.crash2 ||
      KitInstrument.china ||
      KitInstrument.splash =>
        RunSound.crash,
      KitInstrument.ride => RunSound.ride,
      KitInstrument.rideBell => RunSound.rideBell,
      KitInstrument.pad || KitInstrument.unknown => RunSound.pattern,
    };

/// Something placed on a tick of one bar (tick relative to the bar start).
sealed class RunEvent {
  const RunEvent(this.tick);
  final int tick;
}

/// A spoken voice clip starting at [tick].
class ClipEvent extends RunEvent {
  const ClipEvent(super.tick, this.clipId);
  final String clipId;
}

/// Crash cymbal (pad package: the player plays it quieter, Spec §3.5).
class CrashEvent extends RunEvent {
  const CrashEvent(super.tick);
}

/// Countdown step for the banner: 3, 2, 1, 0 (= go, beat 1 of the variation).
class CountdownEvent extends RunEvent {
  const CountdownEvent(super.tick, this.remaining);
  final int remaining;
}

/// One planned 4/4 bar on the 24-ticks-per-quarter grid.
class RunBar {
  const RunBar({
    required this.globalBar,
    required this.sectionIndex,
    required this.barInSection,
    required this.bpm,
    required this.isCountIn,
    required this.isCountdown,
    required this.tickVolumes,
    required this.events,
  });

  /// Position in the whole run; the count-in is 0.
  final int globalBar;

  /// Index into [GuidedExercise.sections]; -1 for the count-in.
  final int sectionIndex;

  /// Bar within the section, auto-extension bars included (they come first).
  final int barInSection;

  /// Tempo this bar was planned at.
  final int bpm;
  final bool isCountIn;

  /// Last bar before a variation (carries the 3-2-1).
  final bool isCountdown;

  /// Per sound: [runTicksPerBar] volumes. Sounds that stay silent in this
  /// bar are left out.
  final Map<RunSound, List<double>> tickVolumes;

  /// Sorted by tick.
  final List<RunEvent> events;
}

/// Where the player is: the last bar it has committed to the stream. The
/// player keeps the planned rest of the current section, so a cursor for
/// [buildRun] is always the LAST bar of its section
/// (`barInSection == sectionBars - 1`); the count-in is section -1 with one
/// bar.
class RunCursor {
  const RunCursor({
    required this.sectionIndex,
    required this.barInSection,
    required this.globalBar,
    required this.sectionBars,
  });
  final int sectionIndex;
  final int barInSection;
  final int globalBar;

  /// Planned length of the cursor's section (auto-extension included).
  final int sectionBars;
}

class RunOptions {
  const RunOptions({this.teacher = true, this.playAlong = true});

  /// Voice on (count-in, explanations, countdown words, after-phrases).
  final bool teacher;

  /// true: the app plays the line; false: only a quarter click.
  final bool playAlong;
}

const countdownClipIds = ['cd_three', 'cd_two', 'cd_one', 'cd_go'];
const countInClipIds = ['ci_one', 'ci_two', 'ci_three', 'ci_four'];

/// Ticks of one 4/4 bar on the pattern clock.
const int runTicksPerBar = guidedBeatsPerBar * kitTicksPerQuarter;

/// Gap between the end of an explanation and the countdown bar.
const double explanationGapMs = 250;

const double _clickVolume = 1.0;
const double _accentClickVolume = 1.5;

/// Plans the run at [bpm]. Without [from] it starts at the count-in
/// (global bar 0); with [from] it returns the sections after the cursor's
/// section, global bars counting on from `from.globalBar + 1`. On a tempo /
/// teacher / playAlong change the player keeps the planned rest of the
/// current section and calls this from that section's last bar, so a
/// section is never replanned once started; a cursor inside a section
/// throws [ArgumentError].
///
/// A groove before a variation is auto-extended (teacher on) by whole bars
/// at its start so its explanation fits before the countdown at [bpm].
List<RunBar> buildRun(
  GuidedExercise ex, {
  required int bpm,
  required RunOptions options,
  required ClipManifest clips,
  RunCursor? from,
}) {
  ex.validate();
  if (from != null && from.barInSection != from.sectionBars - 1) {
    throw ArgumentError('cursor must be the last bar of its section: '
        'bar ${from.barInSection} of ${from.sectionBars}');
  }
  final barMs = guidedBeatsPerBar * 60000 / bpm;
  final beatMs = 60000 / bpm;
  final secs = ex.sections;
  final firstGroove = secs.indexWhere((s) => s.kind == SectionKind.groove);

  // Count words longer than a beat → half-bar countdown / count-in.
  final halfCountdown = countdownClipIds
      .take(3)
      .any((id) => clips.durationMs(id) > beatMs + 1e-9);
  // Even two beats too short: only "go" is spoken (clicks/counts stay).
  final countdownGoOnly = countdownClipIds
      .take(3)
      .any((id) => clips.durationMs(id) > 2 * beatMs + 1e-9);
  final halfCountIn =
      countInClipIds.any((id) => clips.durationMs(id) > beatMs + 1e-9);
  final countInOneOnly =
      countInClipIds.any((id) => clips.durationMs(id) > 2 * beatMs + 1e-9);

  int barsFor(double ms) => ms <= 0 ? 0 : (ms / barMs - 1e-9).ceil();

  final out = <RunBar>[];
  var global = from == null ? 0 : from.globalBar + 1;

  if (from == null) {
    out.add(_countInBar(bpm, options,
        step: countInOneOnly ? 4 : (halfCountIn ? 2 : 1)));
    global = 1;
  }
  final startSection = from == null ? 0 : from.sectionIndex + 1;

  for (var si = startSection; si < secs.length; si++) {
    final s = secs[si];
    final beforeVariation =
        si + 1 < secs.length && secs[si + 1].kind == SectionKind.variation;
    final afterVariation = si > 0 && secs[si - 1].kind == SectionKind.variation;

    // After-phrase on beat 1 of the groove right after a variation.
    final afterClip =
        options.teacher && s.kind == SectionKind.groove && afterVariation
            ? secs[si - 1].afterClipId
            : null;

    var bars = s.bars;
    int? explanationBar;
    String? explanationClip;
    if (s.kind == SectionKind.groove && beforeVariation && options.teacher) {
      explanationClip = secs[si + 1].speechClipId!;
      final lead =
          barsFor(clips.durationMs(explanationClip) + explanationGapMs);
      final afterBars =
          afterClip == null ? 0 : barsFor(clips.durationMs(afterClip));
      bars = math.max(bars, lead + afterBars + 1);
      explanationBar = bars - 1 - lead;
    }

    final line = _LineSounds(s.line, ex.gridUnit);
    for (var b = 0; b < bars; b++) {
      final isCountdown = beforeVariation && b == bars - 1;
      final events = <RunEvent>[];
      final clickTicks = <int, double>{};
      final accent = options.teacher ? _clickVolume : _accentClickVolume;

      if (b == 0 && (si == firstGroove || s.kind == SectionKind.outro)) {
        events.add(const CrashEvent(0));
      }
      if (b == 0 && afterClip != null) events.add(ClipEvent(0, afterClip));
      if (b == explanationBar) events.add(ClipEvent(0, explanationClip!));
      if (isCountdown) {
        final steps = halfCountdown
            ? const [(beat: 0, n: 2, clip: 1), (beat: 2, n: 1, clip: 2)]
            : const [
                (beat: 1, n: 3, clip: 0),
                (beat: 2, n: 2, clip: 1),
                (beat: 3, n: 1, clip: 2),
              ];
        for (final st in steps) {
          final tick = st.beat * kitTicksPerQuarter;
          events.add(CountdownEvent(tick, st.n));
          if (options.teacher && !countdownGoOnly) {
            events.add(ClipEvent(tick, countdownClipIds[st.clip]));
          }
          clickTicks[tick] = accent;
        }
      }
      if (s.kind == SectionKind.variation && b == 0) {
        events.add(const CountdownEvent(0, 0));
        if (options.teacher) events.add(ClipEvent(0, countdownClipIds[3]));
        clickTicks[0] = accent;
      }

      final vols = <RunSound, List<double>>{};
      if (options.playAlong) {
        line.addBar(b, vols);
      } else {
        for (var q = 0; q < guidedBeatsPerBar; q++) {
          clickTicks.putIfAbsent(q * kitTicksPerQuarter, () => _clickVolume);
        }
      }
      if (clickTicks.isNotEmpty) {
        final click = List<double>.filled(runTicksPerBar, 0.0);
        clickTicks.forEach((t, v) => click[t] = v);
        vols[RunSound.click] = click;
      }
      events.sort((a, c) => a.tick.compareTo(c.tick));
      out.add(RunBar(
        globalBar: global++,
        sectionIndex: si,
        barInSection: b,
        bpm: bpm,
        isCountIn: false,
        isCountdown: isCountdown,
        tickVolumes: vols,
        events: List.unmodifiable(events),
      ));
    }
  }
  return out;
}

RunBar _countInBar(int bpm, RunOptions options, {required int step}) {
  final events = <RunEvent>[];
  if (options.teacher) {
    // Words longer than a beat: "one" on 1, "three" on 3 only; longer than
    // two beats: "one" only. Clicks stay on all four beats.
    for (var q = 0; q < guidedBeatsPerBar; q += step) {
      events.add(ClipEvent(q * kitTicksPerQuarter, countInClipIds[q]));
    }
  }
  return RunBar(
    globalBar: 0,
    sectionIndex: -1,
    barInSection: 0,
    bpm: bpm,
    isCountIn: true,
    isCountdown: false,
    tickVolumes: {
      RunSound.click: [
        for (var t = 0; t < runTicksPerBar; t++)
          t % kitTicksPerQuarter == 0 ? _clickVolume : 0.0
      ],
    },
    events: List.unmodifiable(events),
  );
}

/// A line's sounds over its whole length, sliced bar by bar (a line of
/// several bars repeats; extra bars of an extended groove repeat it too).
/// Volumes come from the same helpers as the practice screen, per voice:
/// kick and hi-hat from [kitBackingTracks] (band scale, an open hi-hat
/// always full), every other kit voice from [buildVoicesPlayback] (pattern
/// scale, as [kitPatternSound]). Voices that share a sound
/// (both floor toms) mix by their loudest tick, as `buildVoicesPlayback`.
class _LineSounds {
  _LineSounds(ExerciseLine line, NoteGrid grid) {
    if (line.beats.isEmpty && !line.isKit) return;
    if (line.isKit) {
      for (final v in line.voices) {
        final sound = runSoundOf(v.instrument);
        final vols = kitSoundOf(v.instrument) != null
            ? kitBackingTracks([v], grid).single.tickVolumes
            : buildVoicesPlayback([v], grid).tickVolumes;
        final have = _full[sound];
        _full[sound] = have == null ? vols : _maxOf([have, vols])!;
      }
    } else {
      _full[RunSound.pattern] =
          buildPatternPlayback(line.beats, grid).tickVolumes;
    }
    if (_full.isEmpty) return;
    _bars = (_full.values.first.length / runTicksPerBar).floor();
  }

  final _full = <RunSound, List<double>>{};
  var _bars = 0;

  void addBar(int barInSection, Map<RunSound, List<double>> into) {
    if (_bars == 0) return;
    final start = (barInSection % _bars) * runTicksPerBar;
    _full.forEach((sound, vols) {
      final slice = vols.sublist(start, start + runTicksPerBar);
      if (slice.any((v) => v > 0)) into[sound] = slice;
    });
  }

  static List<double>? _maxOf(List<List<double>> tracks) {
    if (tracks.isEmpty) return null;
    final out = List<double>.of(tracks.first);
    for (final t in tracks.skip(1)) {
      for (var i = 0; i < out.length; i++) {
        out[i] = math.max(out[i], t[i]);
      }
    }
    return out;
  }
}
