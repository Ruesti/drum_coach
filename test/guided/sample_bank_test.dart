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

  test('assets are credited in CREDITS.md', () {
    final credits = File('assets/audio/CREDITS.md').readAsStringSync();
    expect(credits, contains('snare.mp3'));
    if (File('assets/audio/crash.mp3').existsSync()) {
      expect(credits, contains('crash.mp3'));
    }
  });
}
