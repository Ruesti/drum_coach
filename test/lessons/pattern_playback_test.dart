import 'package:drum_coach/features/lessons/models/pattern_playback.dart';
import 'package:drum_coach/features/lessons/models/rudiment.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('buildPatternPlayback — uniform legacy pattern', () {
    // 4 eighth notes at eighth grid => onsets every 12 ticks, total 48.
    final beats = List.generate(4, (_) => const StrokeBeat(hand: Hand.right));
    final pp = buildPatternPlayback(beats, NoteGrid.eighth);

    test('24 ticks/quarter, onsets spaced by note duration', () {
      expect(pp.ticksPerQuarter, 24);
      expect(pp.onsetTicks, [0, 12, 24, 36]);
      expect(pp.totalTicks, 48);
      expect(pp.tickVolumes.length, 48);
    });

    test('volume only on onset ticks', () {
      expect(pp.tickVolumes[0], 0.85);
      expect(pp.tickVolumes[1], 0.0);
      expect(pp.tickVolumes[12], 0.85);
    });

    test('noteIndexAtTick maps a tick to the sounding note', () {
      expect(pp.noteIndexAtTick(0), 0);
      expect(pp.noteIndexAtTick(11), 0);
      expect(pp.noteIndexAtTick(12), 1);
      expect(pp.noteIndexAtTick(47), 3);
    });
  });

  group('buildPatternPlayback — mixed values + tuplet', () {
    // quarter, then an eighth-triplet (3x 1/3 quarter). total = 1 + 1 = 2 quarters.
    const beats = [
      StrokeBeat(hand: Hand.right, value: NoteValue.quarter),
      StrokeBeat(hand: Hand.left, value: NoteValue.eighth, tuplet: Tuplet.triplet),
      StrokeBeat(hand: Hand.right, value: NoteValue.eighth, tuplet: Tuplet.triplet),
      StrokeBeat(hand: Hand.left, value: NoteValue.eighth, tuplet: Tuplet.triplet),
    ];
    final pp = buildPatternPlayback(beats, NoteGrid.eighth);

    test('onset ticks land exactly on the 24-grid', () {
      // quarter=24 ticks; each triplet-eighth=8 ticks.
      expect(pp.onsetTicks, [0, 24, 32, 40]);
      expect(pp.totalTicks, 48);
    });
  });

  group('volume + accents', () {
    test('accent and ghost volumes', () {
      const beats = [
        StrokeBeat(hand: Hand.right, isAccent: true),
        StrokeBeat(hand: Hand.left, isGhost: true),
        StrokeBeat.rest(),
      ];
      final pp = buildPatternPlayback(beats, NoteGrid.quarter);
      expect(pp.tickVolumes[0], 2.0);   // accent, onset tick 0
      expect(pp.tickVolumes[24], 0.25); // ghost, onset tick 24
      expect(pp.tickVolumes[48], 0.0);  // rest, onset tick 48
    });
  });

  group('PatternPlayback.forRudiment', () {
    test('derives from the rudiment grid + sticking', () {
      const r = Rudiment(
        id: 'x', name: 'x', description: 'x', minBpm: 60, targetBpm: 120,
        difficulty: Difficulty.beginner, gridUnit: NoteGrid.eighth,
        sticking: [StrokeBeat(hand: Hand.right), StrokeBeat(hand: Hand.left)],
      );
      final pp = PatternPlayback.forRudiment(r);
      expect(pp.onsetTicks, [0, 12]);
    });
  });
}
