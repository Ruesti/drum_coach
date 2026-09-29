import 'dart:math';

import 'package:drum_coach/features/practice/backdrop.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('the practice photo pool is large and lists real asset paths', () {
    // Uli 28.09.: "ca. 30 Fotos" — the pool is the practice set, not Today's.
    expect(practiceBackdrops.length, greaterThanOrEqualTo(30));
    expect(
        practiceBackdrops
            .every((p) => p.startsWith('assets/illustrations/practice/')),
        isTrue);
    expect(practiceBackdrops.toSet().length, practiceBackdrops.length);
    expect(
        practiceBackdrops
            .every((p) => p.startsWith('assets/illustrations/') && p.endsWith('.jpg')),
        isTrue);
  });

  test('pickBackdrop draws from the pool and never repeats the previous one',
      () {
    final rng = Random(42);
    var last = pickBackdrop(rng);
    expect(practiceBackdrops, contains(last));
    for (var i = 0; i < 300; i++) {
      final next = pickBackdrop(rng, avoid: last);
      expect(practiceBackdrops, contains(next));
      expect(next, isNot(last));
      last = next;
    }
  });

  test('over many draws every photo shows up', () {
    final rng = Random(7);
    final seen = <String>{};
    String? last;
    for (var i = 0; i < 600; i++) {
      last = pickBackdrop(rng, avoid: last);
      seen.add(last);
    }
    expect(seen, practiceBackdrops.toSet());
  });

  test('nextBackdrop hands every screen a photo and never the previous one', () {
    var last = nextBackdrop();
    for (var i = 0; i < 200; i++) {
      final next = nextBackdrop();
      expect(practiceBackdrops, contains(next));
      expect(next, isNot(last));
      last = next;
    }
  });
}
