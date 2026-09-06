import 'package:drum_coach/features/lessons/data/rudiments_seed.dart';
import 'package:drum_coach/features/lessons/models/rudiment.dart';
import 'package:flutter_test/flutter_test.dart';

/// The base-catalog flam/drag rudiments used to encode a flam/drag as two
/// (or three) separate, evenly-spaced StrokeBeats — a ghost note occupying
/// its own full grid cell, immediately followed by a separately-timed
/// accented beat. That's what made them play and notate as discrete,
/// full-length strokes instead of a near-simultaneous grace + main stroke.
/// They should now use StrokeBeat.graces instead, like the newer
/// flam_accent_corps/flam_tap/etc. rudiments already do.
void main() {
  Rudiment byId(String id) =>
      rudimentsSeedData.firstWhere((r) => r.id == id);

  double totalQuarters(Rudiment r) => r.sticking
      .map((b) => resolveNote(b, r.gridUnit).quarters)
      .fold(0.0, (a, b) => a + b);

  group('flam/drag base rudiments use graces, not separate ghost beats', () {
    for (final id in ['flam', 'flam_accent', 'flam_paradiddle', 'single_drag', 'double_drag']) {
      test('$id has no bare isGhost beats left', () {
        final r = byId(id);
        expect(r.sticking.any((b) => b.isGhost), isFalse,
            reason: '$id should express its grace note(s) via graces:, not a '
                'separate isGhost StrokeBeat');
      });

      test('$id still has at least one flam/drag with graces attached', () {
        final r = byId(id);
        expect(r.sticking.any((b) => b.graces.isNotEmpty), isTrue);
      });
    }

    test('flam: 4 quarter-note flams, alternating hands, 1 bar total', () {
      final r = byId('flam');
      expect(totalQuarters(r), 4.0);
      expect(r.sticking, hasLength(4));
      for (final b in r.sticking) {
        expect(b.isAccent, isTrue);
        expect(b.graces, [b.hand == Hand.right ? Hand.left : Hand.right]);
      }
    });

    test('flam_accent: total duration unchanged by the migration (4 quarters)', () {
      expect(totalQuarters(byId('flam_accent')), 4.0);
    });

    test('flam_paradiddle: total duration unchanged by the migration (5 quarters)', () {
      expect(totalQuarters(byId('flam_paradiddle')), 5.0);
    });

    test('single_drag: each accent carries a 2-grace drag, 3 quarters total', () {
      final r = byId('single_drag');
      expect(totalQuarters(r), 3.0);
      for (final b in r.sticking) {
        expect(b.graces, hasLength(2));
        expect(b.graces[0], b.graces[1], reason: 'a drag is two grace notes on the same hand');
      }
    });

    test('double_drag: total duration unchanged by the migration (4 quarters)', () {
      expect(totalQuarters(byId('double_drag')), 4.0);
    });
  });
}
