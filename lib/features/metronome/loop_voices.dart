import 'backing_styles.dart';
import 'click_loop_renderer.dart';

/// Backing is dropped when the cycle would exceed this many 4/4 bars — a
/// pattern that odd does not exist in the catalog, and rendering minutes of
/// WAV on every tempo change would stall the loop rebuild.
const int maxBackingCycleBars = 64;

/// What the engine renders: the cycle length, the pattern volumes tiled to
/// that cycle (the tick clock and beat poller read these) and every voice.
class LoopPlan {
  const LoopPlan({
    required this.cycleTicks,
    required this.patternVolumes,
    required this.voices,
  });
  final int cycleTicks;
  final List<double> patternVolumes;
  final List<LoopVoice> voices;
}

/// Builds the voice list for one loop cycle. Pure: the engine passes its
/// state in, the demo tool passes constants.
///
/// - [patternVolumes]: one pattern cycle (or the plain-metronome quarter).
/// - [pulse]: the click track — 1.0 on every [factor]-th tick.
/// - [backing]: kick + hi-hat from a style, tiled per bar, only on the
///   24-tick pattern clock (`factor == 24`); the cycle then grows to
///   `lcm(pattern, bar)` and the pattern repeats to fill it.
LoopPlan buildLoopPlan({
  required List<double> patternVolumes,
  required List<double> patternLoud,
  required List<double> patternSoft,
  required int factor,
  bool pulse = false,
  List<double>? pulseSound,
  BackingStyle? backing,
  double backingLevel = 0.7,
  int beatsPerBar = 4,
  List<double>? kickSound,
  List<double>? hihatLoud,
  List<double>? hihatSoft,
}) {
  final patternTicks = patternVolumes.length;
  var cycle = patternTicks;
  var useBacking = backing != null &&
      factor == 24 &&
      kickSound != null &&
      hihatLoud != null &&
      hihatSoft != null;
  if (useBacking) {
    cycle = loopCycleTicks(
        patternTicks: patternTicks, barTicks: beatsPerBar * factor);
    if (cycle > maxBackingCycleBars * backingBarTicks) {
      useBacking = false;
      cycle = patternTicks;
    }
  }
  final tiled = [
    for (var t = 0; t < cycle; t++) patternVolumes[t % patternTicks]
  ];
  final voices = <LoopVoice>[
    LoopVoice(
      tickVolumes: tiled,
      loudSamples: patternLoud,
      softSamples: patternSoft,
      loudFrom: 1.2,
    ),
  ];
  if (pulse && pulseSound != null) {
    voices.add(LoopVoice(
      tickVolumes: [
        for (var t = 0; t < cycle; t++) t % factor == 0 ? 1.0 : 0.0
      ],
      loudSamples: pulseSound,
      softSamples: pulseSound,
    ));
  }
  if (useBacking) {
    // Non-null by the useBacking check above; parameters do not promote.
    final style = backing!;
    final kickPcm = kickSound!;
    final hhLoud = hihatLoud!;
    final hhSoft = hihatSoft!;
    voices.add(LoopVoice(
      tickVolumes: tileBackingHits(style.kick,
          beatsPerBar: beatsPerBar, cycleTicks: cycle),
      loudSamples: kickPcm,
      softSamples: kickPcm,
      gain: backingLevel,
    ));
    voices.add(LoopVoice(
      tickVolumes: tileBackingHits(style.hihat,
          beatsPerBar: beatsPerBar, cycleTicks: cycle),
      loudSamples: hhLoud,
      softSamples: hhSoft,
      loudFrom: 0.9,
      gain: backingLevel,
    ));
  }
  return LoopPlan(cycleTicks: cycle, patternVolumes: tiled, voices: voices);
}
