import 'package:drum_coach/app/theme.dart';
import 'package:drum_coach/features/stats/stats_provider.dart';
import 'package:drum_coach/features/today/next_step.dart';
import 'package:drum_coach/features/today/next_step_provider.dart';
import 'package:drum_coach/features/today/today_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

Widget _app({
  required PathStep step,
  int streak = 6,
  TodayStatus today = const TodayStatus(minutes: 12, goalMinutes: 20),
}) {
  final router = GoRouter(routes: [
    GoRoute(path: '/', builder: (_, __) => const TodayScreen()),
    GoRoute(
        path: '/library',
        builder: (_, __) => const Scaffold(body: Text('LIBRARY STUB'))),
    GoRoute(
        path: '/practice/:id',
        builder: (_, s) =>
            Scaffold(body: Text('PRACTICE ${s.pathParameters['id']}'))),
    GoRoute(
        path: '/program/setup',
        builder: (_, __) => const Scaffold(body: Text('SETUP STUB'))),
    GoRoute(
        path: '/settings',
        builder: (_, __) => const Scaffold(body: Text('SETTINGS STUB'))),
  ]);
  return ProviderScope(
    key: UniqueKey(), // fresh container per pump — overrides can't change in place
    overrides: [
      nextStepProvider.overrideWith((ref) async => step),
      streakDaysProvider.overrideWith((ref) async => streak),
      todayStatusProvider.overrideWith((ref) async => today),
    ],
    child: MaterialApp.router(routerConfig: router, theme: drumCoachTheme),
  );
}

const _exercise = PathStep(
  kind: PathStepKind.exercise,
  title: 'Single Paradiddle',
  detail: 'Day 9 · Step 2 of 3 · 84 BPM',
  minutes: 8,
  route: '/practice/single_paradiddle?bpm=84&min=8',
);

void main() {
  setUp(() {
    // Phone-sized surface: the illustration must not push the lower doors
    // out of the lazily built list.
    final binding = TestWidgetsFlutterBinding.ensureInitialized();
    binding.platformDispatcher.views.first.physicalSize = const Size(1080, 2340);
    binding.platformDispatcher.views.first.devicePixelRatio = 3.0;
  });

  tearDown(() {
    final view = TestWidgetsFlutterBinding.ensureInitialized().platformDispatcher.views.first;
    view.resetPhysicalSize();
    view.resetDevicePixelRatio();
  });

  testWidgets('shows the two doors and compact stats', (tester) async {
    await tester.pumpWidget(_app(step: _exercise));
    await tester.pumpAndSettle();
    expect(find.text('CONTINUE THE PATH'), findsOneWidget);
    expect(find.text('Single Paradiddle'), findsOneWidget);
    expect(find.text('Day 9 · Step 2 of 3 · 84 BPM'), findsOneWidget);
    expect(find.text('Start · 8 min'), findsOneWidget);
    expect(find.text('PRACTICE FREELY'), findsOneWidget);
    expect(find.text('Open library'), findsOneWidget);
    expect(find.text('6'), findsOneWidget);
    expect(find.text('day streak'), findsOneWidget);
    expect(find.text('12'), findsOneWidget);
    expect(find.text('/20'), findsOneWidget);
    expect(find.text('min today'), findsOneWidget);
    expect(find.byIcon(Icons.settings_outlined), findsOneWidget);
  });

  testWidgets('Start opens the practice route', (tester) async {
    await tester.pumpWidget(_app(step: _exercise));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Start · 8 min'));
    await tester.pumpAndSettle();
    expect(find.text('PRACTICE single_paradiddle'), findsOneWidget);
  });

  testWidgets('Open library goes to the library', (tester) async {
    await tester.pumpWidget(_app(step: _exercise));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Open library'));
    await tester.pumpAndSettle();
    expect(find.text('LIBRARY STUB'), findsOneWidget);
  });

  testWidgets('setup state offers the program setup', (tester) async {
    const setup = PathStep(
      kind: PathStepKind.setup,
      title: 'Set up your path',
      detail: 'Pick duration and level — the path does the rest.',
      route: '/program/setup',
    );
    await tester.pumpWidget(_app(
        step: setup,
        streak: 0,
        today: const TodayStatus(minutes: 0, goalMinutes: 20)));
    await tester.pumpAndSettle();
    expect(find.text('Set up your path'), findsWidgets);
    await tester.tap(find.widgetWithText(ElevatedButton, 'Set up your path'));
    await tester.pumpAndSettle();
    expect(find.text('SETUP STUB'), findsOneWidget);
  });

  testWidgets('rest day shows no start button', (tester) async {
    const rest = PathStep(
      kind: PathStepKind.restDay,
      title: 'Rest day',
      detail: 'Day 7 · nothing to play, the streak keeps.',
    );
    await tester.pumpWidget(_app(step: rest));
    await tester.pumpAndSettle();
    expect(find.text('Rest day'), findsOneWidget);
    expect(find.byType(ElevatedButton), findsNothing);
  });

  testWidgets('status bar icons are dark on the light Today screen',
      (tester) async {
    // Coming back from the dark practice screen left the system icons
    // light; Today has no AppBar, so it must set the overlay style itself.
    await tester.pumpWidget(_app(step: _exercise));
    await tester.pumpAndSettle();
    final region = tester.widget<AnnotatedRegion<SystemUiOverlayStyle>>(
        find.byType(AnnotatedRegion<SystemUiOverlayStyle>));
    expect(region.value.statusBarIconBrightness, Brightness.dark);
  });

  String? assetOf(WidgetTester tester) {
    final images = tester.widgetList<Image>(find.byType(Image));
    for (final img in images) {
      final provider = img.image;
      if (provider is AssetImage) return provider.assetName;
    }
    return null;
  }

  testWidgets('shows the illustration of the current program phase',
      (tester) async {
    const step = PathStep(
      kind: PathStepKind.exercise,
      title: 'Single Paradiddle',
      detail: 'Day 9 · Step 2 of 3 · 84 BPM',
      minutes: 8,
      route: '/practice/single_paradiddle?bpm=84&min=8',
      phase: 3,
    );
    await tester.pumpWidget(_app(step: step));
    await tester.pumpAndSettle();
    expect(assetOf(tester), 'assets/illustrations/today/phase3.jpg');
    // Decided 23.09.: the banner is 16:9, not the old 2.4:1 strip — tight
    // action shots need the height.
    final ratio = tester.widget<AspectRatio>(
      find.ancestor(of: find.byType(Image), matching: find.byType(AspectRatio)).first,
    );
    expect(ratio.aspectRatio, closeTo(16 / 9, 0.001));
  });

  testWidgets('rest day, done and setup have their own pictures',
      (tester) async {
    const rest = PathStep(kind: PathStepKind.restDay, title: 'Rest day', detail: '', phase: 2);
    await tester.pumpWidget(_app(step: rest));
    await tester.pumpAndSettle();
    expect(assetOf(tester), 'assets/illustrations/today/rest.jpg');

    const done = PathStep(kind: PathStepKind.dayDone, title: 'Day 9 done', detail: '', route: '/program');
    await tester.pumpWidget(_app(step: done));
    await tester.pumpAndSettle();
    expect(assetOf(tester), 'assets/illustrations/today/done.jpg');

    const setup = PathStep(kind: PathStepKind.setup, title: 'Set up your path', detail: '', route: '/program/setup');
    await tester.pumpWidget(_app(step: setup));
    await tester.pumpAndSettle();
    expect(assetOf(tester), 'assets/illustrations/today/setup.jpg');
  });
}
