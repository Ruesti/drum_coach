import 'package:drum_coach/features/metronome/backing_styles.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('style catalog', () {
    test('has six styles with unique, non-empty ids and labels', () {
      expect(backingStyles.length, 6);
      final ids = backingStyles.map((s) => s.id).toSet();
      expect(ids.length, 6);
      expect(backingStyles.every((s) => s.id.isNotEmpty && s.label.isNotEmpty),
          isTrue);
    });
    test('every hit lies inside one 4/4 bar with a level in (0, 1]', () {
      for (final s in backingStyles) {
        for (final h in [...s.kick, ...s.hihat]) {
          expect(h.tick, inInclusiveRange(0, backingBarTicks - 1),
              reason: '${s.id} tick ${h.tick}');
          expect(h.level, greaterThan(0.0), reason: s.id);
          expect(h.level, lessThanOrEqualTo(1.0), reason: s.id);
        }
      }
    });
    test('the downbeat is always audible on the hi-hat', () {
      for (final s in backingStyles) {
        expect(s.hihat.any((h) => h.tick == 0), isTrue, reason: s.id);
      }
    });
    test('lookup by id; null and unknown give null', () {
      expect(backingStyleById('rock8')!.label, 'Rock 8ths');
      expect(backingStyleById(null), isNull);
      expect(backingStyleById('bossa'), isNull);
      expect(backingStyleById(backingOff), isNull);
    });
  });

  group('resolveBackingStyle', () {
    test('nothing stored → exercise default', () {
      expect(resolveBackingStyle(stored: null, exerciseDefault: 'rock8'),
          'rock8');
      expect(resolveBackingStyle(stored: null, exerciseDefault: null), isNull);
    });
    test('stored choice wins, explicit off stays off', () {
      expect(resolveBackingStyle(stored: 'swing', exerciseDefault: 'rock8'),
          'swing');
      expect(resolveBackingStyle(stored: backingOff, exerciseDefault: 'rock8'),
          isNull);
    });
    test('unknown ids fall back to off, never throw', () {
      expect(resolveBackingStyle(stored: 'bossa', exerciseDefault: 'rock8'),
          isNull);
      expect(resolveBackingStyle(stored: null, exerciseDefault: 'bossa'),
          isNull);
    });
  });

  group('tileBackingHits', () {
    const hits = [BackingHit(0, 1.0), BackingHit(48, 0.8)];
    test('tiles one bar across a two-bar cycle', () {
      final v = tileBackingHits(hits, beatsPerBar: 4, cycleTicks: 192);
      expect(v.length, 192);
      expect(v[0], 1.0);
      expect(v[48], 0.8);
      expect(v[96], 1.0);
      expect(v[144], 0.8);
      expect(v.where((x) => x > 0).length, 4);
    });
    test('a 2/4 bar drops hits beyond the bar and wraps every 48 ticks', () {
      final v = tileBackingHits(hits, beatsPerBar: 2, cycleTicks: 96);
      expect(v[0], 1.0);
      expect(v[48], 1.0); // bar 2 downbeat, not the dropped beat-3 hit
      expect(v.where((x) => x > 0).length, 2);
    });
    test('rock8 hi-hat has eight strokes per bar, quarters louder', () {
      final rock = backingStyleById('rock8')!;
      final v = tileBackingHits(rock.hihat, beatsPerBar: 4, cycleTicks: 96);
      expect(v.where((x) => x > 0).length, 8);
      expect(v[0], greaterThan(v[12]));
    });
  });
}
