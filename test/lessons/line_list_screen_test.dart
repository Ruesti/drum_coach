import 'dart:io';

import 'package:drum_coach/app/design_tokens.dart';
import 'package:drum_coach/app/theme.dart';
import 'package:drum_coach/data/local/settings_service.dart';
import 'package:drum_coach/features/learning/suggested_bpm_provider.dart';
import 'package:drum_coach/features/lessons/lesson_detail_screen.dart';
import 'package:drum_coach/features/lessons/line_list_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  const id = 'single_stroke_roll';

  setUpAll(() async {
    final bytes = await File('assets/fonts/Bravura.otf').readAsBytes();
    final loader = FontLoader('Bravura')
      ..addFont(Future.value(ByteData.sublistView(bytes)));
    await loader.load();
    AppTypography.label;
    await GoogleFonts.pendingFonts();
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await SettingsService.init();
  });

  GoRouter buildRouter(String rid) => GoRouter(
        initialLocation: '/exercise/$rid',
        routes: [
          GoRoute(
            path: '/exercise/:id',
            builder: (_, state) =>
                LineListScreen(rudimentId: state.pathParameters['id']!),
          ),
          GoRoute(
            path: '/practice/:id',
            builder: (_, state) =>
                Scaffold(body: Text('practice:${state.uri}')),
          ),
        ],
      );

  Future<void> pump(WidgetTester tester, [String rid = id]) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [suggestedBpmProvider(rid).overrideWith((ref) async => 80)],
      child: MaterialApp.router(
          routerConfig: buildRouter(rid), theme: drumCoachTheme),
    ));
    await tester.pumpAndSettle();
  }

  Finder card(int n) => find.byKey(Key('line-card-$n'));

  testWidgets('lists all eight lines and scrolls', (tester) async {
    await pump(tester);
    expect(card(1), findsOneWidget);
    await tester.scrollUntilVisible(card(8), 300,
        scrollable: find.byType(Scrollable).first);
    expect(card(8), findsOneWidget);
    expect(find.text('Challenge'), findsNothing);
  });

  testWidgets('tap opens that line', (tester) async {
    await pump(tester);
    await tester.scrollUntilVisible(card(3), 300,
        scrollable: find.byType(Scrollable).first);
    await tester.tap(card(3));
    await tester.pumpAndSettle();
    expect(find.text('practice:/practice/$id?lines=3&bpm=80'), findsOneWidget);
  });

  testWidgets(
      'long-press selects; Play 3 lines starts the sequence in list '
      'order', (tester) async {
    await pump(tester);
    Future<void> show(int n, [double delta = 200]) async {
      // Built may still mean off-screen (cache extent): bring it into view.
      await tester.scrollUntilVisible(card(n), delta,
          scrollable: find.byType(Scrollable).first);
      await tester.ensureVisible(card(n));
      await tester.pumpAndSettle();
    }

    await show(5);
    await tester.longPress(card(5));
    await tester.pumpAndSettle();
    await show(2, -200);
    await tester.tap(card(2));
    await tester.pump();
    await show(7);
    await tester.tap(card(7));
    await tester.pump();
    expect(find.text('3 selected'), findsOneWidget);
    expect(find.text('Play 3 lines'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('play-selected')));
    await tester.pumpAndSettle();
    expect(
        find.text('practice:/practice/$id?lines=2,5,7&bpm=80'), findsOneWidget);
  });

  testWidgets('Play all', (tester) async {
    await pump(tester);
    await tester.tap(find.byKey(const ValueKey('play-all')));
    await tester.pumpAndSettle();
    expect(
        find.text('practice:/practice/$id?lines=all&bpm=80'), findsOneWidget);
  });

  testWidgets('Select button, close and back leave selection mode',
      (tester) async {
    await pump(tester);
    expect(find.byType(Checkbox), findsNothing);
    await tester.tap(find.byKey(const ValueKey('select-mode')));
    await tester.pumpAndSettle();
    expect(find.byType(Checkbox), findsWidgets);
    final play = tester
        .widget<FilledButton>(find.byKey(const ValueKey('play-selected')));
    expect(play.onPressed, isNull);
    await tester.tap(find.byKey(const ValueKey('selection-close')));
    await tester.pumpAndSettle();
    expect(find.byType(Checkbox), findsNothing);
    // System back leaves selection mode first, the screen stays.
    await tester.tap(find.byKey(const ValueKey('select-mode')));
    await tester.pumpAndSettle();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byType(Checkbox), findsNothing);
    expect(find.byType(LineListScreen), findsOneWidget);
  });

  testWidgets('the last practised line is marked', (tester) async {
    await pump(tester);
    expect(find.byKey(const ValueKey('line-card-last')), findsNothing);
    await tester.pumpWidget(const SizedBox());
    await SettingsService.setLastLine(id, 3);
    await pump(tester);
    await tester.scrollUntilVisible(card(4), 300,
        scrollable: find.byType(Scrollable).first);
    expect(
        find.ancestor(
            of: card(4),
            matching: find.byKey(const ValueKey('line-card-last'))),
        findsOneWidget);
  });

  testWidgets('ⓘ opens the lesson', (tester) async {
    await pump(tester);
    await tester.tap(find.byKey(const ValueKey('lesson-info')));
    await tester.pumpAndSettle();
    expect(find.byType(LessonDetailScreen), findsOneWidget);
  });

  for (final (name, rid) in [
    ('pad', 'single_stroke_roll'),
    ('kit', 'groove_rock8'),
  ]) {
    testWidgets('golden: line list $name', (tester) async {
      tester.view.physicalSize = const Size(360, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await pump(tester, rid);
      expect(tester.takeException(), isNull);
      await expectLater(find.byType(LineListScreen),
          matchesGoldenFile('../goldens/line_list_$rid.png'));
    });
  }
}
