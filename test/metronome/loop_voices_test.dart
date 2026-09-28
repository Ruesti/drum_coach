import 'package:drum_coach/features/metronome/backing_styles.dart';
import 'package:drum_coach/features/metronome/loop_voices.dart';
import 'package:drum_coach/features/metronome/stroke_sounds.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final loud = clickSamples(accent: true);
  final soft = clickSamples(accent: false);
  final kick = List.filled(100, 0.5);
  final hh = List.filled(50, 0.4);
  // 4 sixteenths = one quarter = 24 ticks, accent on the first.
  final quarter = [
    for (var t = 0; t < 24; t++) t % 6 == 0 ? (t == 0 ? 2.0 : 0.85) : 0.0
  ];

  LoopPlan plan(
          {BackingStyle? backing,
          bool pulse = false,
          int beatsPerBar = 4,
          int factor = 24,
          List<double>? pattern}) =>
      buildLoopPlan(
        patternVolumes: pattern ?? quarter,
        patternLoud: loud,
        patternSoft: soft,
        factor: factor,
        pulse: pulse,
        pulseSound: pulseSamples(),
        backing: backing,
        backingLevel: 0.7,
        beatsPerBar: beatsPerBar,
        kickSound: kick,
        hihatLoud: hh,
        hihatSoft: hh,
      );

  test('without backing the cycle is the pattern itself, one voice', () {
    final p = plan();
    expect(p.cycleTicks, 24);
    expect(p.voices.length, 1);
    expect(p.patternVolumes, quarter);
  });

  test('pulse adds a voice with 1.0 on every quarter tick', () {
    final p = plan(pulse: true, pattern: List.filled(48, 0.85));
    expect(p.voices.length, 2);
    final pulseVols = p.voices[1].tickVolumes;
    expect(pulseVols[0], 1.0);
    expect(pulseVols[24], 1.0);
    expect(pulseVols[1], 0.0);
    expect(pulseVols.where((v) => v > 0).length, 2);
  });

  test('backing stretches the cycle to whole bars and tiles the pattern', () {
    final p = plan(backing: backingStyleById('rock8'));
    expect(p.cycleTicks, 96);
    expect(p.patternVolumes.length, 96);
    expect(p.patternVolumes[24], 2.0); // pattern repeats every 24 ticks
    expect(p.patternVolumes[30], 0.85);
    expect(p.voices.length, 3);
    final kickVoice = p.voices[1];
    final hhVoice = p.voices[2];
    expect(kickVoice.gain, 0.7);
    expect(kickVoice.tickVolumes[0], 1.0);
    expect(kickVoice.tickVolumes[48], 1.0);
    expect(hhVoice.loudFrom, 0.9);
    expect(hhVoice.tickVolumes.where((v) => v > 0).length, 8);
    expect(p.voices.every((v) => v.tickVolumes.length == 96), isTrue);
  });

  test('a 2/4 exercise gets a 48-tick bar', () {
    final p = plan(backing: backingStyleById('rock8'), beatsPerBar: 2);
    expect(p.cycleTicks, 48);
    expect(p.voices[1].tickVolumes.where((v) => v > 0).length, 1);
  });

  test('backing is ignored outside the 24-tick pattern clock', () {
    final p = plan(
        backing: backingStyleById('rock8'),
        factor: 2,
        pattern: const [2.0, 0.7]);
    expect(p.cycleTicks, 2);
    expect(p.voices.length, 1);
  });

  test('an absurdly long cycle drops the backing instead of rendering minutes',
      () {
    // 97 ticks vs a 96-tick bar → lcm = 97 bars > 64.
    final p = plan(
        backing: backingStyleById('rock8'), pattern: List.filled(97, 0.85));
    expect(p.cycleTicks, 97);
    expect(p.voices.length, 1);
  });

  test('stroke sounds match the engine ones (pure copies)', () {
    expect(clickSamples(accent: true).length, (44100 * 0.030).round());
    expect(rimSamples(accent: false).length, (44100 * 0.10).round());
    expect(pulseSamples().length, (44100 * 0.012).round());
  });
}
