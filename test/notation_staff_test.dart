import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:drum_coach/features/lessons/data/rudiments_seed.dart';
import 'package:drum_coach/features/lessons/lessons_provider.dart';
import 'package:drum_coach/shared/widgets/notation_staff_widget.dart';

void main() {
  group('NotationStaffWidget (5-line staff)', () {
    testWidgets('renders every seeded pattern without throwing', (tester) async {
      for (final rudiment in rudimentsSeedData) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 360,
                child: NotationStaffWidget(rudiment: rudiment),
              ),
            ),
          ),
        );
        expect(tester.takeException(), isNull,
            reason: 'failed rendering ${rudiment.id}');
        expect(find.byType(NotationStaffWidget), findsOneWidget);

        final size = tester.getSize(find.byType(CustomPaint).first);
        expect(size.height, greaterThan(0));
      }
    });

    testWidgets('renders with an active cursor during playback', (tester) async {
      final rudiment = rudimentsSeedData.first;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 360,
              child: NotationStaffWidget(rudiment: rudiment, activeIndex: 2),
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
    });
  });

  group('practice plan', () {
    test('is ordered by level then difficulty', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final plan = container.read(practicePlanProvider);
      expect(plan, isNotEmpty);

      // Every exercise belongs to a focus category.
      for (final r in plan) {
        expect(exerciseCategories, contains(r.category));
      }

      // Levels are non-decreasing (nulls sort last).
      var prevLevel = -1;
      for (final r in plan) {
        final lvl = r.level ?? 1 << 20;
        expect(lvl, greaterThanOrEqualTo(prevLevel),
            reason: 'plan not ordered at ${r.id}');
        prevLevel = lvl;
      }
    });

    test('every focus category has at least one exercise', () {
      for (final cat in exerciseCategories) {
        final inCat = rudimentsSeedData.where((r) => r.category == cat);
        expect(inCat, isNotEmpty, reason: 'no exercises in "$cat"');
      }
    });
  });
}
