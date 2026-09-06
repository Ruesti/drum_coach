import 'package:drum_coach/features/coaching/services/sequence_aligner.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('alignSequences', () {
    test('matches a clean run one-to-one with correct deviations', () {
      final r = alignSequences(
        expectedMs: [0, 500, 1000, 1500],
        onsetMs: [5, 495, 1010, 1500],
      );
      expect(r.notes.length, 4);
      expect(r.hitCount, 4);
      expect(r.missedCount, 0);
      expect(r.extraCount, 0);
      expect(r.notes[0].deviationMs, closeTo(5, 0.001));
      expect(r.notes[1].deviationMs, closeTo(-5, 0.001));
      expect(r.notes[2].deviationMs, closeTo(10, 0.001));
      expect(r.notes[3].deviationMs, closeTo(0, 0.001));
    });

    // Abnahme (a): ein Schlag bewusst ausgelassen — genau eine Auslassung
    // an der richtigen Position, alle übrigen Zuordnungen unverschoben.
    test('(a) detects a single omission at the correct position', () {
      final r = alignSequences(
        expectedMs: [0, 500, 1000, 1500],
        onsetMs: [2, 502, 1498], // third stroke missing
      );
      expect(r.hitCount, 3);
      expect(r.missedCount, 1);
      expect(r.extraCount, 0);
      expect(r.notes[2].hit, isFalse, reason: 'note at 1000 ms is the miss');
      expect(r.notes[0].deviationMs, closeTo(2, 0.001));
      expect(r.notes[1].deviationMs, closeTo(2, 0.001));
      expect(r.notes[3].deviationMs, closeTo(-2, 0.001));
    });

    // Abnahme (b): ein Schlag bewusst doppelt — ein Onset zugeordnet, einer
    // als überzählig ausgewiesen, jede Note höchstens einmal vergeben.
    test('(b) flags a double stroke as one match plus one extra onset', () {
      final r = alignSequences(
        expectedMs: [0, 500, 1000, 1500],
        onsetMs: [0, 500, 545, 1000, 1500], // extra stroke after beat 2
      );
      expect(r.hitCount, 4);
      expect(r.missedCount, 0);
      expect(r.extraCount, 1);
      expect(r.extraOnsetIndices, [2]);
      final assigned = r.notes
          .where((n) => n.hit)
          .map((n) => n.onsetIndex)
          .toList();
      expect(assigned.toSet().length, assigned.length,
          reason: 'no onset may be assigned to two notes');
    });

    // Abnahme (c): ein Schlag ~150 ms zu früh bei engem Raster (200 ms) —
    // die Monotonie des Alignments verhindert den Sprung auf die zeitlich
    // nähere Nachbarnote; die richtige Note wird mit −150 ms getroffen.
    test('(c) keeps an early stroke on its own note instead of the neighbor',
        () {
      final r = alignSequences(
        expectedMs: [0, 200, 400, 600],
        onsetMs: [0, 200, 250, 600], // third stroke 150 ms early
      );
      expect(r.hitCount, 4);
      expect(r.missedCount, 0);
      expect(r.extraCount, 0);
      expect(r.notes[2].deviationMs, closeTo(-150, 0.001));
    });

    test('treats an onset far from every note as extra, note as missed', () {
      final r = alignSequences(
        expectedMs: [0, 500],
        onsetMs: [0, 900], // 400 ms away from note 1 — beyond max deviation
      );
      expect(r.hitCount, 1);
      expect(r.missedCount, 1);
      expect(r.extraCount, 1);
      expect(r.notes[1].hit, isFalse);
      expect(r.extraOnsetIndices, [1]);
    });

    test('handles empty onset list as all notes missed', () {
      final r = alignSequences(expectedMs: [0, 500, 1000], onsetMs: []);
      expect(r.hitCount, 0);
      expect(r.missedCount, 3);
      expect(r.extraCount, 0);
    });
  });

  group('hand-value confidence gate (90% hit, <5% extra)', () {
    List<double> grid(int n) => [for (var i = 0; i < n; i++) i * 500.0];

    test('allows hand values at exactly 90% hits and no extras', () {
      final r = alignSequences(
        expectedMs: grid(20),
        onsetMs: grid(20).sublist(0, 18), // 18/20 = 90%
      );
      expect(r.hitRate, closeTo(0.9, 0.001));
      expect(r.handValuesAllowed, isTrue);
    });

    test('blocks hand values below 90% hits', () {
      final r = alignSequences(
        expectedMs: grid(20),
        onsetMs: grid(20).sublist(0, 17), // 85%
      );
      expect(r.handValuesAllowed, isFalse);
    });

    test('blocks hand values at 5% extra onsets', () {
      final onsets = [...grid(20), 9750.0]; // one extra = 5% of 20
      final r = alignSequences(expectedMs: grid(20), onsetMs: onsets);
      expect(r.hitCount, 20);
      expect(r.extraCount, 1);
      expect(r.handValuesAllowed, isFalse,
          reason: '5% extra is not < 5%');
    });
  });
}
