import 'package:drum_coach/features/lessons/lesson_detail_screen.dart';
import 'package:drum_coach/shared/widgets/notation_staff_widget.dart';
import 'package:drum_coach/features/lessons/data/etudes.dart';
import 'package:drum_coach/features/lessons/data/rudiments_seed.dart';
import 'package:drum_coach/features/learning/suggested_bpm_provider.dart';
import 'package:drum_coach/features/lessons/lessons_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../helpers/kit_fixtures.dart';

void main() {
  GoRouter buildRouter(String id) => GoRouter(
        initialLocation: '/library/$id',
        routes: [
          GoRoute(
            path: '/library/:id',
            builder: (_, state) =>
                LessonDetailScreen(rudimentId: state.pathParameters['id']!),
          ),
          GoRoute(
            path: '/practice/:id',
            builder: (_, state) => Scaffold(
              body: Text('practice:${state.uri}'),
            ),
          ),
        ],
      );

  Future<void> pump(WidgetTester tester, String id) async {
    await tester.pumpWidget(ProviderScope(
        overrides: [suggestedBpmProvider(id).overrideWith((ref) async => 80)],
        child: MaterialApp.router(routerConfig: buildRouter(id))));
    await tester.pumpAndSettle();
  }

  testWidgets(
    'the sample sheet page shows the pattern box and the lesson, no sheet',
    (tester) async {
      await pump(tester, 'single_paradiddle');
      expect(find.text('PATTERN'), findsOneWidget);
      expect(find.byType(NotationStaffWidget), findsOneWidget);
      expect(find.text('THE SHEET'), findsNothing);
      expect(find.byType(SheetStaffWidget), findsNothing);
      expect(find.text('LESSON'), findsOneWidget);
      for (final t in [
        'Why it matters',
        'How to play it',
        'Practice tips',
        'Where you hear it',
      ]) {
        await tester.scrollUntilVisible(
          find.text(t),
          200,
          scrollable: find.byType(Scrollable).first,
        );
        expect(find.text(t), findsOneWidget);
      }
    },
  );

  testWidgets('a one-line exercise shows its pattern', (tester) async {
    // A legacy basic rudiment without authored lines, and an etude.
    for (final id in ['multiple_bounce_roll', allEtudes.first.id]) {
      await pump(tester, id);
      expect(find.text('THE SHEET'), findsNothing);
      expect(find.text('PATTERN'), findsOneWidget);
      expect(find.byType(NotationStaffWidget), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    }
  });

  testWidgets('Start Practice plays all lines', (tester) async {
    await pump(tester, 'single_paradiddle');
    final start = find.text('Start Practice');
    await tester.scrollUntilVisible(
      start,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(start);
    await tester.pumpAndSettle();
    expect(
      find.text('practice:/practice/single_paradiddle?lines=all&bpm=80'),
      findsOneWidget,
    );
  });

  testWidgets('showStart: false hides Start Practice', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: LessonDetailScreen(
            rudimentId: 'single_paradiddle',
            showStart: false,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('LESSON'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -3000));
    await tester.pumpAndSettle();
    expect(find.text('Start Practice'), findsNothing);
  });

  testWidgets('a kit exercise carries the KIT badge on the info page', (tester) async {
    await tester.pumpWidget(ProviderScope(
        overrides: [
          rudimentsProvider
              .overrideWithValue([...rudimentsSeedData, kitShowcase()]),
        ],
        child: MaterialApp.router(routerConfig: buildRouter('kit_showcase'))));
    await tester.pumpAndSettle();
    expect(find.text('KIT'), findsOneWidget);
  });

  testWidgets('a pad exercise has no KIT badge', (tester) async {
    await pump(tester, 'single_paradiddle');
    expect(find.text('KIT'), findsNothing);
  });
}
