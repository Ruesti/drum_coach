import 'backing_styles.dart';
import 'click_loop_renderer.dart';

/// Backing is dropped when the cycle would exceed this many 4/4 bars — a
/// pattern that odd does not exist in the catalog, and rendering minutes of
/// WAV on every tempo change would stall the loop rebuild.
const int maxBackingCycleBars = 64;

/// A kit voice the band plays with the player (Phase B.4, S23 test 16.10.:
/// "Backing" on a kit exercise = the line's own kick and hi-hat with the
/// real backing samples): per-tick volumes over one pattern cycle (same
/// length as the pattern volumes).
enum KitSound { kick, hihat }

class KitSoundTrack {
  const KitSoundTrack(this.tickVolumes, this.sound);
  final List<double> tickVolumes;
  final KitSound sound;
}

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
/// - [backingKick] / [backingHihat]: false mutes that band voice (Brief B.4:
///   the band keeps quiet in the voices the player plays).
/// - [kitTracks]: kick/hi-hat voices of a kit unit, tiled to the cycle and
///   played with [kickSound] / [hihatLoud] / [hihatSoft] at [backingLevel]
///   in place of a style (kit exercise with Backing on); they need no bar
///   clock, so the cycle stays the pattern.
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
  bool backingKick = true,
  bool backingHihat = true,
  List<KitSoundTrack> kitTracks = const [],
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
  for (final t in kitTracks) {
    if (t.tickVolumes.length != patternTicks) {
      throw ArgumentError('kit track spans ${t.tickVolumes.length} ticks, '
          'the pattern $patternTicks');
    }
    final kick = t.sound == KitSound.kick;
    final loud = kick ? kickSound : hihatLoud;
    final soft = kick ? kickSound : hihatSoft;
    if (loud == null || soft == null) continue;
    voices.add(LoopVoice(
      tickVolumes: [
        for (var i = 0; i < cycle; i++) t.tickVolumes[i % patternTicks]
      ],
      loudSamples: loud,
      softSamples: soft,
      loudFrom: kick ? 1.0 : 0.9,
      gain: backingLevel,
    ));
  }
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
    if (backingKick) {
      voices.add(LoopVoice(
        tickVolumes: tileBackingHits(style.kick,
            beatsPerBar: beatsPerBar, cycleTicks: cycle),
        loudSamples: kickPcm,
        softSamples: kickPcm,
        gain: backingLevel,
      ));
    }
    if (backingHihat) {
      voices.add(LoopVoice(
        tickVolumes: tileBackingHits(style.hihat,
            beatsPerBar: beatsPerBar, cycleTicks: cycle),
        loudSamples: hhLoud,
        softSamples: hhSoft,
        loudFrom: 0.9,
        gain: backingLevel,
      ));
    }
  }
  return LoopPlan(cycleTicks: cycle, patternVolumes: tiled, voices: voices);
}
