import 'dart:io';

import 'package:drum_coach/app/design_tokens.dart';
import 'package:drum_coach/app/platform_support.dart';
import 'package:drum_coach/data/local/settings_service.dart';
import 'package:drum_coach/features/guided/data/demo_exercise.dart';
import 'package:drum_coach/features/guided/data/guided_catalog.dart';
import 'package:drum_coach/features/guided/data/guided_lookup.dart';
import 'package:drum_coach/features/guided/guided_format.dart';
import 'package:drum_coach/features/guided/models/guided_exercise.dart';
import 'package:drum_coach/features/guided/screens/guided_preview_screen.dart';
import 'package:drum_coach/features/guided/widgets/guided_line_view.dart';
import 'package:drum_coach/features/practice/widgets/tempo_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _photo = 'assets/illustrations/practice/p07_rooftop_dusk_s5.jpg';

GuidedExercise get _kit => guidedCatalog.first;

Future<GoRouter> _pump(WidgetTester t, String id, Size size,
    {bool desktop = false}) async {
  debugDesktopOverride = desktop ? true : null;
  await t.binding.setSurfaceSize(size);
  addTearDown(() => t.binding.setSurfaceSize(null));
  final router = GoRouter(initialLocation: '/', routes: [
    GoRoute(path: '/', builder: (_, __) => const Scaffold(body: Text('home'))),
    GoRoute(
      path: '/guided/:id',
      builder: (_, s) => GuidedPreviewScreen(
          id: s.pathParameters['id']!, photo: 'assets/none.jpg'),
    ),
    GoRoute(
      path: '/guided/:id/play',
      builder: (_, s) => Scaffold(body: Text('play:${s.uri}')),
    ),
  ]);
  await t.pumpWidget(MaterialApp.router(
    routerConfig: router,
    builder: capContentWidth,
  ));
  router.push('/guided/$id');
  await t.pumpAndSettle();
  return router;
}

Future<void> _key(WidgetTester t, LogicalKeyboardKey k,
    {bool shift = false}) async {
  if (shift) await t.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
  await t.sendKeyEvent(k);
  if (shift) await t.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
  await t.pumpAndSettle();
}

String _bpmText(WidgetTester t) {
  return '${t.widget<TempoRow>(find.byType(TempoRow)).bpm}';
}

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await SettingsService.init();
  });
  tearDown(() => debugDesktopOverride = null);

  test('lookup resolves catalog and demos, null for unknown', () {
    expect(guidedExerciseById(_kit.id), same(_kit));
    expect(guidedExerciseById(demoKitExercise.id), same(demoKitExercise));
    expect(guidedExerciseById(demoPadExercise.id), same(demoPadExercise));
    expect(guidedExerciseById('nope'), isNull);
  });

  test('settings default on and persist', () async {
    expect(SettingsService.guidedTeacher, isTrue);
    expect(SettingsService.guidedPlayAlong, isTrue);
    await SettingsService.setGuidedTeacher(false);
    await SettingsService.setGuidedPlayAlong(false);
    expect(SettingsService.guidedTeacher, isFalse);
    expect(SettingsService.guidedPlayAlong, isFalse);
  });

  testWidgets('shows timeline with every variation text', (t) async {
    await _pump(t, _kit.id, const Size(1280, 800), desktop: true);
    expect(find.text(_kit.name), findsOneWidget);
    expect(find.text(_kit.description), findsOneWidget);
    expect(find.text(guidedDurationLabel(_kit)), findsOneWidget);
    expect(find.text('SET'), findsOneWidget);
    var n = 0;
    for (final s in _kit.sections) {
      if (s.kind != SectionKind.variation) continue;
      n++;
      expect(find.text(s.textEn!), findsOneWidget);
      expect(find.text('V$n'), findsOneWidget);
    }
    expect(n, _kit.variationCount);
    final grooves = _kit.sections.where((s) => s.kind == SectionKind.groove);
    expect(find.text('Groove'), findsNWidgets(grooves.length));
    expect(find.text('Ending'), findsOneWidget);
    expect(find.byType(GuidedLineView), findsOneWidget);
  });

  testWidgets('start pushes play with bpm and options', (t) async {
    final router = await _pump(t, _kit.id, const Size(412, 915));
    expect(_bpmText(t), '${_kit.defaultBpm}');
    await t.ensureVisible(find.byKey(const Key('guided-teacher')));
    await t.pumpAndSettle();
    await t.tap(find.byTooltip('Faster'));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('guided-teacher')));
    await t.pumpAndSettle();
    expect(SettingsService.guidedTeacher, isFalse);
    await t.tap(find.byKey(const Key('guided-start')));
    await t.pumpAndSettle();
    expect(
        find.text('play:/guided/${_kit.id}/play'
            '?bpm=${_kit.defaultBpm + 4}&teacher=0&along=1'),
        findsOneWidget);
    expect(router.canPop(), isTrue);
  });

  testWidgets('remembered options are restored', (t) async {
    await SettingsService.setGuidedPlayAlong(false);
    await _pump(t, _kit.id, const Size(412, 915));
    final sw = t.widget<Switch>(find.descendant(
        of: find.byKey(const Key('guided-along')),
        matching: find.byType(Switch)));
    expect(sw.value, isFalse);
  });

  testWidgets('keys change tempo and toggles', (t) async {
    await _pump(t, _kit.id, const Size(1280, 800), desktop: true);
    final b = _kit.defaultBpm;
    await _key(t, LogicalKeyboardKey.arrowUp);
    expect(_bpmText(t), '${b + 4}');
    await _key(t, LogicalKeyboardKey.arrowUp, shift: true);
    expect(_bpmText(t), '${b + 12}');
    await _key(t, LogicalKeyboardKey.minus);
    expect(_bpmText(t), '${b + 8}');
    await _key(t, LogicalKeyboardKey.arrowDown);
    expect(_bpmText(t), '${b + 4}');
    for (var i = 0; i < 40; i++) {
      await _key(t, LogicalKeyboardKey.arrowUp, shift: true);
    }
    expect(_bpmText(t), '${_kit.maxBpm}');
    for (var i = 0; i < 40; i++) {
      await _key(t, LogicalKeyboardKey.arrowDown, shift: true);
    }
    expect(_bpmText(t), '${_kit.minBpm}');
    await _key(t, LogicalKeyboardKey.equal);
    expect(_bpmText(t), '${_kit.minBpm + 4}');

    await _key(t, LogicalKeyboardKey.keyT);
    await _key(t, LogicalKeyboardKey.keyP);
    expect(SettingsService.guidedTeacher, isFalse);
    expect(SettingsService.guidedPlayAlong, isFalse);
    await _key(t, LogicalKeyboardKey.space);
    expect(
        find.text('play:/guided/${_kit.id}/play'
            '?bpm=${_kit.minBpm + 4}&teacher=0&along=0'),
        findsOneWidget);
  });

  testWidgets('escape goes back', (t) async {
    await _pump(t, _kit.id, const Size(1280, 800), desktop: true);
    await _key(t, LogicalKeyboardKey.escape);
    expect(find.text('home'), findsOneWidget);
    expect(find.byType(GuidedPreviewScreen), findsNothing);
  });

  testWidgets('unknown id shows not found', (t) async {
    await _pump(t, 'does_not_exist', const Size(412, 915));
    expect(find.text('Exercise not found'), findsOneWidget);
    expect(find.byKey(const Key('guided-start')), findsNothing);
    await t.tap(find.text('Back'));
    await t.pumpAndSettle();
    expect(find.text('home'), findsOneWidget);
  });

  testWidgets('demo exercise opens too', (t) async {
    await _pump(t, demoPadExercise.id, const Size(412, 915));
    expect(find.text(demoPadExercise.name), findsOneWidget);
    expect(find.text('PAD'), findsOneWidget);
  });

  testWidgets('renders at phone, tablet and desktop sizes without overflow',
      (t) async {
    for (final ex in [_kit, guidedCatalog.last]) {
      // Phone: one column, Start pinned to the bottom.
      await _pump(t, ex.id, const Size(412, 915));
      expect(t.takeException(), isNull);
      final start = t.getRect(find.byKey(const Key('guided-start')));
      expect(start.bottom, greaterThan(915 - 80));
      expect(start.width, greaterThan(300));

      // Tablet portrait: two columns.
      await _pump(t, ex.id, const Size(820, 1180));
      expect(t.takeException(), isNull);
      final tl = t.getRect(find.byKey(const Key('guided-timeline')));
      final st = t.getRect(find.byKey(const Key('guided-start')));
      expect(st.left, greaterThan(tl.right - 1));

      // Desktop: inside the 900 cap, two columns.
      await _pump(t, ex.id, const Size(1280, 800), desktop: true);
      expect(t.takeException(), isNull);
      final tl2 = t.getRect(find.byKey(const Key('guided-timeline')));
      final st2 = t.getRect(find.byKey(const Key('guided-start')));
      expect(st2.left, greaterThan(tl2.right - 1));
      expect(tl2.left, greaterThanOrEqualTo(190));

      // Small landscape phone: still no overflow.
      await _pump(t, ex.id, const Size(700, 360));
      expect(t.takeException(), isNull);
    }
  });

  group('goldens', () {
    setUpAll(() async {
      final bytes = await File('assets/fonts/Bravura.otf').readAsBytes();
      final loader = FontLoader('Bravura')
        ..addFont(Future.value(ByteData.sublistView(bytes)));
      await loader.load();
      AppTypography.label;
      await GoogleFonts.pendingFonts();
    });

    Future<void> shot(
        WidgetTester t, Size size, bool desktop, String name) async {
      debugDesktopOverride = desktop ? true : null;
      await t.binding.setSurfaceSize(size);
      addTearDown(() => t.binding.setSurfaceSize(null));
      final router = GoRouter(initialLocation: '/', routes: [
        GoRoute(path: '/', builder: (_, __) => const SizedBox()),
        GoRoute(
          path: '/guided/:id',
          builder: (_, s) =>
              GuidedPreviewScreen(id: s.pathParameters['id']!, photo: _photo),
        ),
      ]);
      await t.pumpWidget(RepaintBoundary(
        key: const Key('shot'),
        child: MaterialApp.router(
          debugShowCheckedModeBanner: false,
          routerConfig: router,
          builder: capContentWidth,
        ),
      ));
      router.push('/guided/${_kit.id}');
      await t.pumpAndSettle();
      await t.runAsync(() async {
        final el = t.element(find.byType(GuidedPreviewScreen));
        await precacheImage(const AssetImage(_photo), el);
      });
      await t.pumpAndSettle();
      expect(t.takeException(), isNull);
      await expectLater(find.byKey(const Key('shot')),
          matchesGoldenFile('../../goldens/$name.png'));
    }

    testWidgets('golden: desktop', (t) async {
      await shot(t, const Size(900, 800), true, 'guided_preview_desktop');
    });

    testWidgets('golden: phone', (t) async {
      await shot(t, const Size(412, 915), false, 'guided_preview_phone');
    });
  });
}
