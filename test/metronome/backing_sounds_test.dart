import 'package:drum_coach/features/metronome/backing_sounds.dart';
import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter_test/flutter_test.dart';

const _sr = 44100;

double _peak(List<double> s) =>
    s.fold(0.0, (m, v) => v.abs() > m ? v.abs() : m);

/// Zero crossings per second — low for a pitched thump, high for noise.
double _zeroCrossingRate(List<double> s) {
  var n = 0;
  for (var i = 1; i < s.length; i++) {
    if ((s[i - 1] < 0) != (s[i] < 0)) n++;
  }
  return n / (s.length / _sr);
}

void main() {
  group('kick', () {
    final kick = kickSamples();
    test('is about 180 ms long and not silent', () {
      expect(kick.length, closeTo(_sr * 0.180, _sr * 0.180 * 0.05));
      expect(_peak(kick), inInclusiveRange(0.3, 0.95));
    });
    test('is a low thump: few zero crossings per second', () {
      expect(_zeroCrossingRate(kick), lessThan(400));
    });
    test('is deterministic', () {
      expect(listEquals(kick, kickSamples()), isTrue);
    });
  });

  group('hi-hat', () {
    final closed = hihatSamples(accent: false);
    final open = hihatSamples(accent: true);
    test('closed is about 60 ms with peak 0.5', () {
      expect(closed.length, closeTo(_sr * 0.060, _sr * 0.060 * 0.05));
      expect(_peak(closed), closeTo(0.5, 1e-9));
    });
    test('accent is longer (about 160 ms) with peak 0.65', () {
      expect(open.length, closeTo(_sr * 0.160, _sr * 0.160 * 0.05));
      expect(open.length, greaterThan(closed.length));
      expect(_peak(open), closeTo(0.65, 1e-9));
    });
    test('is noise: many zero crossings per second', () {
      expect(_zeroCrossingRate(closed), greaterThan(3000));
      expect(_zeroCrossingRate(open), greaterThan(3000));
    });
    test('is deterministic', () {
      expect(listEquals(closed, hihatSamples(accent: false)), isTrue);
    });
  });
}
