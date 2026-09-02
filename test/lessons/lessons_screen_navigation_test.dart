import 'package:drum_coach/features/learning/suggested_bpm_provider.dart';
import 'package:drum_coach/features/lessons/lessons_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  GoRouter buildRouter() => GoRouter(
        initialLocation: '/lessons',
        routes: [
          GoRoute(
            path: '/lessons',
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
            path: '/practice/:id',
            builder: (_, state) => Scaffold(
              body: Text('practice:${state.pathParameters['id']}'),
            ),
          ),
        ],
      );

  testWidgets('tapping a lesson tile goes straight to practice, not the explanation',
      (tester) async {
    final router = buildRouter();
    await tester.pumpWidget(
      ProviderScope(
        // The tile's onTap awaits suggestedBpmProvider (an Isar lookup) before
        // navigating — override it so this test doesn't need a real database.
        overrides: [
          suggestedBpmProvider('single_stroke_roll').overrideWith((ref) async => 100),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Single Stroke Roll'));
    await tester.pumpAndSettle();

    expect(_textStartingWith('practice:'), findsOneWidget);
    expect(_textStartingWith('explanation:'), findsNothing);
  });

  testWidgets('tapping the info icon opens the explanation on demand', (tester) async {
    final router = buildRouter();
    await tester.pumpWidget(
      ProviderScope(child: MaterialApp.router(routerConfig: router)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.info_outline).first);
    await tester.pumpAndSettle();

    expect(_textStartingWith('explanation:'), findsOneWidget);
  });
}

Finder _textStartingWith(String prefix) => find.byWidgetPredicate(
      (w) => w is Text && (w.data?.startsWith(prefix) ?? false),
    );
