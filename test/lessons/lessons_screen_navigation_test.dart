import 'package:drum_coach/features/learning/suggested_bpm_provider.dart';
import 'package:drum_coach/features/lessons/data/etudes.dart';
import 'package:drum_coach/features/lessons/data/rudiments_seed.dart';
import 'package:drum_coach/features/lessons/exercise_entry.dart';
import 'package:drum_coach/features/lessons/lessons_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  GoRouter buildRouter() => GoRouter(
        initialLocation: '/library',
        routes: [
          GoRoute(
            path: '/library',
            builder: (_, __) => const LessonsScreen(),
            routes: [
              GoRoute(
                path: ':id',
                builder: (_, state) => Scaffold(
                  body: Text('explanation:${state.pathParameters['id']}'),
                ),
              ),
            ],
          ),
          GoRoute(
            path: '/exercise/:id',
            builder: (_, state) => Scaffold(
              body: Text('lines:${state.pathParameters['id']}'),
            ),
          ),
          GoRoute(
            path: '/practice/:id',
            builder: (_, state) => Scaffold(
              body: Text('practice:${state.pathParameters['id']}'),
            ),
          ),
        ],
      );

  test('opensLineList: sheets yes, one-line etudes no', () {
    expect(
      opensLineList(
        rudimentsSeedData.firstWhere((r) => r.id == 'single_stroke_roll'),
      ),
      isTrue,
    );
    expect(opensLineList(allEtudes.first), isFalse);
  });

  testWidgets('tapping a sheet tile opens its line list', (tester) async {
    final router = buildRouter();
    await tester.pumpWidget(
      ProviderScope(
        // The tile's onTap awaits suggestedBpmProvider (an Isar lookup) before
        // navigating — override it so this test doesn't need a real database.
        overrides: [
          suggestedBpmProvider('single_stroke_roll')
              .overrideWith((ref) async => 100),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Single Stroke Roll'));
    await tester.pumpAndSettle();

    expect(find.text('lines:single_stroke_roll'), findsOneWidget);
    expect(_textStartingWith('practice:'), findsNothing);
    expect(_textStartingWith('explanation:'), findsNothing);
  });

  testWidgets('tapping the info icon opens the explanation on demand',
      (tester) async {
    final router = buildRouter();
    await tester.pumpWidget(
      ProviderScope(child: MaterialApp.router(routerConfig: router)),
    );
    await tester.pumpAndSettle();

    // The header scrolls with the list; bring the first tile into view.
    await tester.scrollUntilVisible(find.byIcon(Icons.info_outline).first, 200,
        scrollable: _list);
    await tester.ensureVisible(find.byIcon(Icons.info_outline).first);
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.info_outline).first);
    await tester.pumpAndSettle();

    expect(_textStartingWith('explanation:'), findsOneWidget);
  });

  testWidgets(
      'short window: header scrolls with the list, first tile reachable',
      (tester) async {
    tester.view.physicalSize = const Size(800, 600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(child: MaterialApp.router(routerConfig: buildRouter())),
    );
    await tester.pumpAndSettle();

    // All filter rows are shown (areas are assigned now).
    expect(find.text('AREA'), findsOneWidget);
    expect(find.text('SKILL'), findsOneWidget);
    expect(find.text('SUBDIVISION'), findsOneWidget);

    final tile = find.text('Single Stroke Roll');
    await tester.scrollUntilVisible(tile, 200, scrollable: _list);
    await tester.ensureVisible(tile);
    await tester.pumpAndSettle();
    final rect = tester.getRect(tile);
    expect(rect.height, greaterThan(0));
    expect(rect.bottom, lessThanOrEqualTo(600));
    expect(rect.top, greaterThanOrEqualTo(0));
  });
}

Finder _textStartingWith(String prefix) => find.byWidgetPredicate(
      (w) => w is Text && (w.data?.startsWith(prefix) ?? false),
    );

final _list = find
    .descendant(
        of: find.byType(CustomScrollView), matching: find.byType(Scrollable))
    .first;
