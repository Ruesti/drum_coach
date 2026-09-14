import 'package:drum_coach/features/coaching/services/lapse_detector.dart';
import 'package:flutter_test/flutter_test.dart';

/// A "lapse" is a locally bad stretch (player fell off the tempo) that a
/// whole-session average would dilute away: 1 bad minute in 10 minutes is
/// still 90% overall — the Auftraggeber wants exactly that caught (13.09.).
void main() {
  // 8th notes at 150 BPM: 200 ms grid. noteTimes are the assessed window's
  // expected times, hit == null means the note was missed, otherwise the
  // deviation in ms.
  List<double> grid(int n, {double step = 200}) =>
      [for (var i = 0; i < n; i++) i * step];

  group('LapseDetector', () {
    test('clean long run has no lapses', () {
      final notes = grid(600); // 2 minutes
      final devs = List<double?>.filled(600, 5);
      final lapses = detectLapses(
          noteTimesMs: notes, deviationsMs: devs);
      expect(lapses, isEmpty);
    });

    test('10 seconds of dropped notes inside a long run become one lapse',
        () {
      final notes = grid(600);
      // Notes between 60 s and 70 s are almost all missed.
      final devs = <double?>[
        for (var i = 0; i < 600; i++)
          (notes[i] >= 60000 && notes[i] < 70000)
              ? (i % 5 == 0 ? 10.0 : null) // 20% hit rate in the hole
              : 5.0,
      ];
      final lapses = detectLapses(
          noteTimesMs: notes, deviationsMs: devs);
      expect(lapses.length, 1);
      final l = lapses.single;
      expect(l.startMs, lessThanOrEqualTo(61000));
      expect(l.endMs, greaterThanOrEqualTo(68000));
      expect(l.endMs - l.startMs, lessThanOrEqualTo(16000),
          reason: 'the lapse must stay local, not swallow the good part');
    });

    test('10 seconds of wild timing (all hit, huge jitter) become a lapse',
        () {
      final notes = grid(600);
      var flip = false;
      final devs = <double?>[
        for (var i = 0; i < 600; i++)
          (notes[i] >= 30000 && notes[i] < 40000)
              ? ((flip = !flip) ? 90.0 : -90.0) // std dev ~90 ms locally
              : 3.0,
      ];
      final lapses = detectLapses(
          noteTimesMs: notes, deviationsMs: devs);
      expect(lapses.length, 1);
      expect(lapses.single.startMs, lessThanOrEqualTo(31000));
      expect(lapses.single.endMs, greaterThanOrEqualTo(38000));
    });

    test('two separate holes yield two lapses', () {
      final notes = grid(900); // 3 minutes
      final devs = <double?>[
        for (var i = 0; i < 900; i++)
          ((notes[i] >= 20000 && notes[i] < 29000) ||
                  (notes[i] >= 120000 && notes[i] < 129000))
              ? null
              : 0.0,
      ];
      final lapses = detectLapses(
          noteTimesMs: notes, deviationsMs: devs);
      expect(lapses.length, 2);
    });

    test('a single missed note in a clean run is NOT a lapse', () {
      final notes = grid(300);
      final devs = <double?>[for (var i = 0; i < 300; i++) i == 150 ? null : 4];
      expect(
          detectLapses(noteTimesMs: notes, deviationsMs: devs), isEmpty);
    });

    test('short runs below one window length never report lapses', () {
      final notes = grid(10); // 2 s of notes
      final devs = List<double?>.filled(10, null); // even all missed
      expect(
          detectLapses(noteTimesMs: notes, deviationsMs: devs), isEmpty,
          reason: 'the global gate already covers short runs');
    });
  });
}
