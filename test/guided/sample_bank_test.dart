import 'dart:io';
import 'dart:math' as math;

import 'package:drum_coach/features/guided/run_plan.dart';
import 'package:drum_coach/features/guided/sample_bank.dart';
import 'package:drum_coach/features/metronome/metronome_engine.dart';
import 'package:flutter_test/flutter_test.dart';

double _peak(List<double> s) => s.fold(0.0, (m, v) => math.max(m, v.abs()));

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('crash fallback is audible and at most 0.9 peak', () {
    final s = crashFallbackSamples();
    expect(s.length, closeTo(44100 * 1.2, 2));
    expect(_peak(s), greaterThan(0.3));
    expect(_peak(s), lessThanOrEqualTo(0.9 + 1e-9));
    // decaying: the tail is much quieter than the attack
    expect(_peak(s.sublist(s.length - 4410)),
        lessThan(_peak(s.sublist(0, 4410)) * 0.2));
  });

  test('of(click) equals MetronomeEngine.pulseSamples()', () {
    final bank = SampleBank();
    expect(bank.of(RunSound.click), MetronomeEngine.pulseSamples());
  });

  test('without decoded samples every sound is audible (never silence)', () {
    final bank = SampleBank();
    for (final s in RunSound.values) {
      expect(bank.of(s), isNotEmpty, reason: '$s');
      expect(_peak(bank.of(s)), greaterThan(0.0), reason: '$s');
    }
    expect(bank.of(RunSound.crash), crashFallbackSamples());
  });

  test('decoded snare/crash replace the fallbacks', () {
    final snare = [0.1, 0.2, 0.3];
    final crash = [0.4, 0.5];
    final bank = SampleBank(snare: snare, crash: crash);
    expect(bank.of(RunSound.pattern), snare);
    expect(bank.of(RunSound.crash), crash);
  });

  test('toSoundMap covers every RunSound for GuidedPlayer', () {
    final map = SampleBank().toSoundMap();
    expect(map.keys.toSet(), RunSound.values.toSet());
  });

  test('load() without audio engine falls back instead of throwing', () async {
    final bank = await SampleBank.load();
    expect(bank.of(RunSound.crash), isNotEmpty);
    expect(bank.of(RunSound.pattern), isNotEmpty);
  });

  // MP3 decoders without gapless support keep the encoder delay (1105
  // samples = 25 ms of silence) — the snare then lands 25 ms after the
  // synthetic kick and hi-hat (S23/Linux listening test 20.10.).
  int onsetIndex(List<double> s) {
    final peak = _peak(s);
    return s.indexWhere((v) => v.abs() > 0.02 * peak);
  }

  test('recorded snare and crash load and start on their first millisecond',
      () async {
    final bank = await SampleBank.load();
    final snare = bank.of(RunSound.pattern);
    final crash = bank.of(RunSound.crash);
    // Not the synthetic fallbacks: the recordings are ~0.67 s and ~2.4 s.
    expect(snare.length, greaterThan(44100 * 0.6));
    expect(crash.length, greaterThan(44100 * 2.3));
    expect(onsetIndex(snare), lessThan(44));
    expect(onsetIndex(crash), lessThan(44));
  });

  test('assets are credited in CREDITS.md', () {
    final credits = File('assets/audio/CREDITS.md').readAsStringSync();
    expect(credits, contains('snare.wav'));
    if (File('assets/audio/crash.wav').existsSync()) {
      expect(credits, contains('crash.wav'));
    }
  });
}
