import 'package:drum_coach/features/lessons/lesson_detail_screen.dart';
import 'package:drum_coach/shared/widgets/notation_staff_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

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
        child: MaterialApp.router(routerConfig: buildRouter(id))));
    await tester.pumpAndSettle();
  }

  Finder paints() => find.descendant(
      of: find.byType(SheetStaffWidget), matching: find.byType(CustomPaint));

  testWidgets(
      'the sample sheet page shows the pattern box, THE SHEET and the lesson',
      (tester) async {
    await pump(tester, 'single_paradiddle');
    expect(find.text('PATTERN'), findsOneWidget);
    expect(find.byType(NotationStaffWidget), findsOneWidget);
    expect(find.text('THE SHEET'), findsOneWidget);
    expect(find.byType(SheetStaffWidget), findsOneWidget);
    expect(find.text('LESSON'), findsOneWidget);
    for (final t in [
      'Why it matters',
      'How to play it',
      'Practice tips',
      'Song examples'
    ]) {
      await tester.scrollUntilVisible(find.text(t), 200,
          scrollable: find.byType(Scrollable).first);
      expect(find.text(t), findsOneWidget);
    }
  });

  testWidgets('a one-line exercise shows the sheet only, no pattern box',
      (tester) async {
    await pump(tester, 'single_stroke_roll');
    expect(find.text('THE SHEET'), findsOneWidget);
    expect(find.byType(SheetStaffWidget), findsOneWidget);
    expect(find.text('PATTERN'), findsNothing);
    expect(find.byType(NotationStaffWidget), findsNothing);
  });

  testWidgets('tapping line 3 of the sheet starts practice on it',
      (tester) async {
    await pump(tester, 'single_paradiddle');
    final third = paints().at(2);
    await tester.scrollUntilVisible(third, 200,
        scrollable: find.byType(Scrollable).first);
    await tester.tap(third);
    await tester.pumpAndSettle();
    expect(find.text('practice:/practice/single_paradiddle?line=3'),
        findsOneWidget);
  });
}
