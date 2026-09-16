import 'package:drum_coach/app/router.dart';
import 'package:drum_coach/app/theme.dart';
import 'package:drum_coach/data/local/settings_service.dart';
import 'package:drum_coach/features/stats/stats_provider.dart';
import 'package:drum_coach/features/today/next_step.dart';
import 'package:drum_coach/features/today/next_step_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget _app() => ProviderScope(
      overrides: [
        nextStepProvider.overrideWith((ref) async => const PathStep(
              kind: PathStepKind.setup,
              title: 'Set up your path',
              detail: 'Pick duration and level.',
              route: '/program/setup',
            )),
        streakDaysProvider.overrideWith((ref) async => 0),
        todayStatusProvider.overrideWith(
            (ref) async => const TodayStatus(minutes: 0, goalMinutes: 20)),
      ],
      child: MaterialApp.router(routerConfig: router, theme: drumCoachTheme),
    );

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await SettingsService.init();
    await SettingsService.setOnboardingDone();
    router.go('/');
  });

  testWidgets('bottom nav shows Today, Library, Progress', (tester) async {
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();
    expect(find.text('Today'), findsWidgets);
    expect(find.text('Library'), findsOneWidget);
    expect(find.text('Progress'), findsOneWidget);
    expect(find.text('Dashboard'), findsNothing);
    expect(find.text('Routine'), findsNothing);
  });

  testWidgets('Library tab opens the lessons list titled Library',
      (tester) async {
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Library'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(AppBar, 'Library'), findsOneWidget);
  });

  testWidgets('legacy /lessons redirects to /library', (tester) async {
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();
    router.go('/lessons');
    await tester.pumpAndSettle();
    expect(router.routerDelegate.currentConfiguration.uri.path, '/library');
  });
}
