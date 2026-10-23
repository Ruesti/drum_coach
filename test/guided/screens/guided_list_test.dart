import 'package:drum_coach/app/platform_support.dart';
import 'package:drum_coach/features/guided/data/guided_catalog.dart';
import 'package:drum_coach/features/guided/guided_format.dart';
import 'package:drum_coach/features/guided/models/guided_exercise.dart';
import 'package:drum_coach/features/guided/widgets/guided_tile.dart';
import 'package:drum_coach/features/lessons/lessons_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

Future<GoRouter> pumpLibrary(WidgetTester tester, Size size) async {
  await tester.binding.setSurfaceSize(size);
  addTearDown(() => tester.binding.setSurfaceSize(null));
  final router = GoRouter(initialLocation: '/library', routes: [
    GoRoute(path: '/library', builder: (_, __) => const LessonsScreen()),
    GoRoute(
        path: '/guided/:id',
        builder: (_, s) =>
            Scaffold(body: Text('preview:${s.pathParameters['id']}'))),
  ]);
  await tester.pumpWidget(
      ProviderScope(child: MaterialApp.router(routerConfig: router)));
  await tester.pumpAndSettle();
  return router;
}

Future<void> openGuided(WidgetTester tester) async {
  await tester.tap(find.text('Guided'));
  await tester.pumpAndSettle();
}

void main() {
  tearDown(() {
    debugDesktopOverride = null;
    uncappedContentCount.value = 0;
  });

  testWidgets('toggle shows guided list', (tester) async {
    await pumpLibrary(tester, const Size(412, 900));
    expect(find.text('Skill'.toUpperCase()), findsOneWidget);
    expect(find.byType(GuidedTile), findsNothing);
    await openGuided(tester);
    expect(find.text('SKILL'), findsNothing);
    expect(find.byType(GuidedTile), findsWidgets);
  });

  testWidgets('set/pad filter', (tester) async {
    await pumpLibrary(tester, const Size(412, 900));
    await openGuided(tester);
    await tester.tap(find.text('Pad'));
    await tester.pumpAndSettle();
    final tiles = tester.widgetList<GuidedTile>(find.byType(GuidedTile));
    expect(tiles, isNotEmpty);
    expect(tiles.every((t) => t.exercise.package == GuidedPackage.pad), isTrue);
    await tester.tap(find.text('Set'));
    await tester.pumpAndSettle();
    final both = tester.widgetList<GuidedTile>(find.byType(GuidedTile));
    expect(both.any((t) => t.exercise.package == GuidedPackage.kit), isTrue);
  });

  testWidgets('tile shows name, badges, duration', (tester) async {
    await pumpLibrary(tester, const Size(412, 900));
    await openGuided(tester);
    final ex = guidedCatalog.first;
    final tile = find.widgetWithText(GuidedTile, ex.name);
    expect(tile, findsOneWidget);
    expect(
        find.descendant(
            of: tile,
            matching:
                find.text(ex.package == GuidedPackage.kit ? 'SET' : 'PAD')),
        findsOneWidget);
    expect(
        find.descendant(
            of: tile, matching: find.text(ex.difficulty.label.toUpperCase())),
        findsOneWidget);
    expect(
        find.descendant(
            of: tile,
            matching:
                find.text('${guidedDurationLabel(ex)} · ${ex.defaultBpm} BPM')),
        findsOneWidget);
  });

  testWidgets('tap pushes preview route', (tester) async {
    await pumpLibrary(tester, const Size(412, 900));
    await openGuided(tester);
    final ex = guidedCatalog.first;
    await tester.tap(find.widgetWithText(GuidedTile, ex.name));
    await tester.pumpAndSettle();
    expect(find.text('preview:${ex.id}'), findsOneWidget);
  });

  testWidgets('two columns when wide', (tester) async {
    debugDesktopOverride = true;
    await pumpLibrary(tester, const Size(1280, 800));
    await openGuided(tester);
    final tiles = find.byType(GuidedTile);
    expect(tiles, findsAtLeastNWidgets(2));
    expect(
        tester.getTopLeft(tiles.at(0)).dy, tester.getTopLeft(tiles.at(1)).dy);
  });

  testWidgets('one column at 412', (tester) async {
    await pumpLibrary(tester, const Size(412, 900));
    await openGuided(tester);
    final tiles = find.byType(GuidedTile);
    expect(tester.getTopLeft(tiles.at(0)).dy,
        isNot(tester.getTopLeft(tiles.at(1)).dy));
  });
}
