import 'package:drum_coach/app/theme.dart';
import 'package:drum_coach/features/practice/backdrop.dart';
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
        path: '/room',
        builder: (_, __) => const Scaffold(body: Text('ROOM STUB'))),
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
  title: "Today's session",
  detail: 'Warm-up + Rudiments',
  minutes: 30,
  route: '/room',
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
    expect(find.text('CONTINUE'), findsOneWidget);
    expect(find.text("Today's session"), findsOneWidget);
    expect(find.text('Warm-up + Rudiments'), findsOneWidget);
    expect(find.text('Start · 30 min'), findsOneWidget);
    expect(find.text('PRACTICE FREELY'), findsOneWidget);
    expect(find.text('Open library'), findsOneWidget);
    expect(find.text('6'), findsOneWidget);
    expect(find.text('day streak'), findsOneWidget);
    expect(find.text('12'), findsOneWidget);
    expect(find.text('/20'), findsOneWidget);
    expect(find.text('min today'), findsOneWidget);
    expect(find.byIcon(Icons.settings_outlined), findsOneWidget);
  });

  testWidgets('today continue opens /room', (tester) async {
    await tester.pumpWidget(_app(step: _exercise));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Start · 30 min'));
    await tester.pumpAndSettle();
    expect(find.text('ROOM STUB'), findsOneWidget);
  });

  testWidgets('Open library goes to the library', (tester) async {
    await tester.pumpWidget(_app(step: _exercise));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Open library'));
    await tester.pumpAndSettle();
    expect(find.text('LIBRARY STUB'), findsOneWidget);
  });

  testWidgets('status bar icons are light over the full-screen photo',
      (tester) async {
    // 29.09. (Uli): the photo fills the screen up behind the status bar, so
    // the system icons must be light; Today has no AppBar and sets it itself.
    await tester.pumpWidget(_app(step: _exercise));
    await tester.pumpAndSettle();
    final region = tester.widget<AnnotatedRegion<SystemUiOverlayStyle>>(
        find.byType(AnnotatedRegion<SystemUiOverlayStyle>));
    expect(region.value.statusBarIconBrightness, Brightness.light);
  });

  String? assetOf(WidgetTester tester) {
    final images = tester.widgetList<Image>(find.byType(Image));
    for (final img in images) {
      final provider = img.image;
      if (provider is AssetImage) return provider.assetName;
    }
    return null;
  }

  testWidgets('the backdrop photo fills the screen and comes from the pool',
      (tester) async {
    // 29.09. (Uli): "Die Startseite hat noch kein Fullscreen-Bild" — a random
    // portrait photo from the practice pool behind the whole screen; the
    // program phase no longer picks a picture.
    await tester.pumpWidget(_app(step: _exercise));
    await tester.pumpAndSettle();
    expect(practiceBackdrops, contains(assetOf(tester)));
    final rect = tester.getRect(find.byType(Image).first);
    expect(rect.width, 360);
    expect(rect.height, 780);
    expect(find.byType(AspectRatio), findsNothing);
    // The doors still sit on paper below the photo.
    expect(find.text('CONTINUE'), findsOneWidget);
    expect(find.text('Open library'), findsOneWidget);
  });
}
