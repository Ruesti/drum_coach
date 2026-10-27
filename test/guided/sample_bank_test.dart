import 'dart:io';
import 'dart:math' as math;

import 'package:drum_coach/features/guided/run_plan.dart';
import 'package:drum_coach/features/guided/sample_bank.dart';
import 'package:drum_coach/features/metronome/metronome_engine.dart';
import 'package:drum_coach/features/metronome/snare_sample.dart';
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

  test('decoded recordings replace the fallbacks', () {
    final snare = [0.1, 0.2, 0.3];
    final crash = [0.4, 0.5];
    final bank = SampleBank(
        recordings: {RunSound.pattern: snare, RunSound.crash: crash});
    expect(bank.of(RunSound.pattern), snare);
    expect(bank.of(RunSound.crash), crash);
  });

  test('a missing recording falls back to the closest real instrument', () {
    final kit = [0.1, 0.2];
    final ride = [0.3, 0.4];
    final closed = [0.5, 0.6];
    final tom = [0.7, 0.8];
    final bank = SampleBank(recordings: {
      RunSound.snare: kit,
      RunSound.ride: ride,
      RunSound.hihatClosed: closed,
      RunSound.tomLow: tom,
    });
    expect(bank.of(RunSound.rideBell), ride);
    expect(bank.of(RunSound.crash), ride); // never the snare for cymbals
    expect(bank.of(RunSound.hihatPedal), closed);
    expect(bank.of(RunSound.hihatOpen), closed);
    expect(bank.of(RunSound.snareGhost), kit);
    expect(bank.of(RunSound.rim), kit);
    expect(bank.of(RunSound.tomHigh), tom);
    expect(bank.of(RunSound.tomFloor), tom);
    // without any cymbal recording: the synthetic crash, not the snare
    final bare = SampleBank(recordings: {RunSound.snare: kit});
    expect(bare.of(RunSound.ride), crashFallbackSamples());
    expect(bare.of(RunSound.rideBell), crashFallbackSamples());
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
    // Not the synthetic fallbacks: the pad snare is ~0.67 s, the crash 2.5 s.
    expect(snare.length, greaterThan(44100 * 0.6));
    expect(crash.length, greaterThan(44100 * 2.3));
    expect(onsetIndex(snare), lessThan(44));
    expect(onsetIndex(crash), lessThan(44));
  });

  test('every sample loads and starts within 1 ms', () async {
    final bank = await SampleBank.load();
    expect(
        SampleBank.assets.keys,
        containsAll([
          RunSound.pattern,
          RunSound.kick,
          RunSound.snare,
          RunSound.snareGhost,
          RunSound.hihatClosed,
          RunSound.hihatOpen,
          RunSound.tomHigh,
          RunSound.tomLow,
          RunSound.tomFloor,
          RunSound.crash,
          RunSound.ride,
        ]));
    SampleBank.assets.forEach((sound, path) {
      final s = decodeMonoWav16(File(path).readAsBytesSync());
      expect(s, isNotEmpty, reason: path);
      expect(onsetIndex(s), lessThan(44), reason: '$path onset');
      expect(_peak(s), inInclusiveRange(0.5, 1.0), reason: '$path peak');
      expect(s.length, lessThanOrEqualTo(44100 * 2.5 + 1), reason: path);
      // load() hands out exactly the recording, not a fallback
      expect(bank.of(sound), s, reason: '$sound from $path');
    });
  });

  test('each kit sound of the catalog is its own recording', () async {
    final bank = await SampleBank.load();
    final sounds = [
      RunSound.kick,
      RunSound.snare,
      RunSound.hihatClosed,
      RunSound.hihatOpen,
      RunSound.tomHigh,
      RunSound.tomFloor,
      RunSound.crash,
    ];
    for (var i = 0; i < sounds.length; i++) {
      for (var j = i + 1; j < sounds.length; j++) {
        expect(identical(bank.of(sounds[i]), bank.of(sounds[j])), isFalse,
            reason: '${sounds[i]} == ${sounds[j]}');
      }
      expect(bank.of(sounds[i]), isNot(bank.of(RunSound.pattern)),
          reason: '${sounds[i]} plays the pad snare');
    }
  });

  test('CREDITS lists every new file', () {
    final credits = File('assets/audio/CREDITS.md').readAsStringSync();
    final wavs = Directory('assets/audio')
        .listSync()
        .whereType<File>()
        .map((f) => f.uri.pathSegments.last)
        .where((n) => n.endsWith('.wav'));
    for (final n in {
      ...wavs,
      ...SampleBank.assets.values.map((p) => p.split('/').last)
    }) {
      expect(credits, contains('`$n`'), reason: n);
    }
  });
}
