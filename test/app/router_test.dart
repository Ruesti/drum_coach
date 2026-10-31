import 'package:drum_coach/app/router.dart';
import 'package:drum_coach/app/theme.dart';
import 'package:drum_coach/data/local/settings_service.dart';
import 'package:drum_coach/features/guided/data/guided_catalog.dart';
import 'package:drum_coach/features/guided/screens/guided_preview_screen.dart';
import 'package:drum_coach/features/lessons/line_list_screen.dart';
import 'package:drum_coach/features/room/room_provider.dart';
import 'package:drum_coach/features/room/room_screen.dart';
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
              title: "Today's session",
              detail: 'Warm-up + Rudiments',
              minutes: 30,
              route: '/room',
            )),
        roomPlanProvider.overrideWith((ref) async => null),
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
    // Since 29.09. the title sits on the photo header, not in an AppBar:
    // the tab label plus the header title.
    expect(find.byType(AppBar), findsNothing);
    expect(find.text('Library'), findsNWidgets(2));
    // The header scrolls with the list: scroll down to the first tile.
    await tester.scrollUntilVisible(find.text('Single Stroke Roll'), 200,
        scrollable: find
            .descendant(
                of: find.byType(CustomScrollView),
                matching: find.byType(Scrollable))
            .first);
    expect(find.text('Single Stroke Roll'), findsOneWidget);
  });

  testWidgets('legacy /lessons redirects to /library', (tester) async {
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();
    router.go('/lessons');
    await tester.pumpAndSettle();
    expect(router.routerDelegate.currentConfiguration.uri.path, '/library');
  });

  testWidgets('/exercise/:id opens the line list', (tester) async {
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();
    router.go('/exercise/single_paradiddle');
    await tester.pumpAndSettle();
    expect(find.byType(LineListScreen), findsOneWidget);
  });

  testWidgets('/room opens the room over the shell', (tester) async {
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();
    router.push('/room');
    await tester.pumpAndSettle();
    expect(find.byType(RoomScreen), findsOneWidget);
    // Full screen: pushed on the root navigator, no bottom nav on top.
    expect(find.byType(BottomNavigationBar), findsNothing);
  });

  test('/program and /routine no longer exist', () {
    for (final path in const [
      '/program',
      '/program/setup',
      '/routine',
      '/routine/single_paradiddle',
    ]) {
      expect(router.configuration.findMatch(Uri.parse(path)).isEmpty, isTrue,
          reason: path);
    }
    expect(router.configuration.findMatch(Uri.parse('/room')).isEmpty, isFalse);
  });

  testWidgets('/guided/:id opens the preview', (tester) async {
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();
    router.push('/guided/${guidedCatalog.first.id}');
    await tester.pumpAndSettle();
    expect(find.byType(GuidedPreviewScreen), findsOneWidget);
    expect(find.text(guidedCatalog.first.name), findsOneWidget);
  });
}
