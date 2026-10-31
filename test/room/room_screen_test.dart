import 'package:drum_coach/app/design_tokens.dart';
import 'package:drum_coach/app/theme.dart';
import 'package:drum_coach/data/local/models/rudiment_progress.dart';
import 'package:drum_coach/features/lessons/lessons_provider.dart';
import 'package:drum_coach/features/lessons/models/rudiment.dart';
import 'package:drum_coach/features/room/room_provider.dart';
import 'package:drum_coach/features/room/room_screen.dart';
import 'package:drum_coach/features/room/training_area.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

Rudiment ex(String id, String name, TrainingArea area,
        [Difficulty d = Difficulty.beginner]) =>
    Rudiment(
      id: id,
      name: name,
      description: '',
      minBpm: 60,
      targetBpm: 100,
      difficulty: d,
      sticking: const [],
      area: area,
    );

final _catalog = [
  ex('h1', 'Hand One', TrainingArea.handTechnique),
  ex('h2', 'Hand Two', TrainingArea.handTechnique),
  ex('r1', 'Rudi One', TrainingArea.rudiments),
  ex('f1', 'Foot One', TrainingArea.feet),
  ex('g1', 'Groove One', TrainingArea.groove),
  ex('g2', 'Groove Two', TrainingArea.groove),
];

RudimentProgress _prog(String id, {required int bpm}) => RudimentProgress()
  ..exerciseId = id
  ..currentBpm = bpm
  ..bestBpm = bpm
  ..mastery = MasteryLevel.developing
  ..srInterval = 1
  ..srRepetitions = 0
  ..lastPracticed = DateTime.now().subtract(const Duration(days: 1))
  ..nextReviewDate = DateTime.now().add(const Duration(days: 5));

Widget _app({
  List<Rudiment>? catalog,
  Map<String, RudimentProgress>? progress,
}) {
  final router = GoRouter(initialLocation: '/room', routes: [
    GoRoute(path: '/room', builder: (_, __) => const RoomScreen()),
    GoRoute(
      path: '/practice/:id',
      builder: (_, s) => Scaffold(body: Text('practice:${s.uri}')),
    ),
    GoRoute(
      path: '/library',
      builder: (_, __) => const Scaffold(body: Text('LIBRARY STUB')),
    ),
  ]);
  return ProviderScope(
    overrides: [
      rudimentsProvider.overrideWithValue(catalog ?? _catalog),
      roomProgressProvider.overrideWith(
          (ref) async => progress ?? {'g1': _prog('g1', bpm: 84)}),
    ],
    child: MaterialApp.router(routerConfig: router, theme: drumCoachTheme),
  );
}

void main() {
  setUpAll(() async {
    AppTypography.title;
    AppTypography.body;
    await GoogleFonts.pendingFonts();
  });

  setUp(() {
    final binding = TestWidgetsFlutterBinding.ensureInitialized();
    binding.platformDispatcher.views.first.physicalSize =
        const Size(1080, 2340);
    binding.platformDispatcher.views.first.devicePixelRatio = 3.0;
  });

  tearDown(() {
    final view = TestWidgetsFlutterBinding.ensureInitialized()
        .platformDispatcher
        .views
        .first;
    view.resetPhysicalSize();
    view.resetDevicePixelRatio();
  });

  testWidgets('room screen shows warm-up and focus', (tester) async {
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();
    expect(find.text('Warm-up'), findsOneWidget);
    // One per basic area, from the planner.
    expect(find.byKey(const Key('warmup-h1')), findsOneWidget);
    expect(find.byKey(const Key('warmup-r1')), findsOneWidget);
    expect(find.byKey(const Key('warmup-f1')), findsOneWidget);
    // Never-played areas come first: hand technique is suggested.
    expect(find.text("Today's focus: Hand technique"), findsOneWidget);
    expect(find.byKey(const Key('deepen-h1')), findsOneWidget);
    expect(find.byKey(const Key('deepen-h2')), findsOneWidget);
    // A chip for every non-empty area, the suggestion marked.
    for (final label in ['Hand technique', 'Rudiments', 'Feet', 'Grooves']) {
      expect(find.widgetWithText(ChoiceChip, label), findsOneWidget,
          reason: label);
    }
    expect(find.widgetWithText(ChoiceChip, 'Metal'), findsNothing);
    final suggested = find.byKey(const Key('area-handTechnique'));
    expect(find.descendant(of: suggested, matching: find.byIcon(Icons.star)),
        findsOneWidget);
  });

  testWidgets('choosing an area replans deepen', (tester) async {
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ChoiceChip, 'Grooves'));
    await tester.pumpAndSettle();
    expect(find.text("Today's focus: Grooves"), findsOneWidget);
    expect(find.byKey(const Key('deepen-g1')), findsOneWidget);
    expect(find.byKey(const Key('deepen-g2')), findsOneWidget);
    expect(find.byKey(const Key('deepen-h1')), findsNothing);
    // The suggestion stays marked on its own chip.
    expect(
        find.descendant(
            of: find.byKey(const Key('area-handTechnique')),
            matching: find.byIcon(Icons.star)),
        findsOneWidget);
  });

  testWidgets('start opens practice in room mode', (tester) async {
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ChoiceChip, 'Grooves'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('deepen-g1')));
    await tester.tap(find.descendant(
        of: find.byKey(const Key('deepen-g1')), matching: find.text('Start')));
    await tester.pumpAndSettle();
    // Played before: its current tempo; with the ladder (room=1).
    expect(find.text('practice:/practice/g1?lines=all&bpm=84&room=1'),
        findsOneWidget);
  });

  testWidgets('warm-up start opens practice without room mode', (tester) async {
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();
    await tester.tap(find.descendant(
        of: find.byKey(const Key('warmup-h1')), matching: find.text('Start')));
    await tester.pumpAndSettle();
    // Never played: the exercise's entry tempo, no tempo ladder.
    expect(find.text('practice:/practice/h1?lines=all&bpm=60'), findsOneWidget);
  });

  testWidgets('a fully mastered level shows a friendly line', (tester) async {
    final mastered = {
      for (final id in ['g1', 'g2'])
        id: _prog(id, bpm: 100)..mastery = MasteryLevel.mastered,
    };
    await tester.pumpWidget(_app(progress: mastered));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ChoiceChip, 'Grooves'));
    await tester.pumpAndSettle();
    expect(
        find.textContaining('Everything at this level sits'), findsOneWidget);
  });

  testWidgets('nothing to plan shows an empty state', (tester) async {
    await tester.pumpWidget(_app(catalog: const []));
    await tester.pumpAndSettle();
    expect(find.text('Nothing to practice here yet.'), findsOneWidget);
  });

  testWidgets('golden: room on a phone', (tester) async {
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();
    await expectLater(find.byType(RoomScreen),
        matchesGoldenFile('../goldens/room_phone.png'));
  });

  testWidgets('golden: room on the desktop', (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();
    await expectLater(find.byType(RoomScreen),
        matchesGoldenFile('../goldens/room_desktop.png'));
  });
}
