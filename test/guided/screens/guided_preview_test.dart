import 'dart:io';

import 'package:drum_coach/app/design_tokens.dart';
import 'package:drum_coach/app/platform_support.dart';
import 'package:drum_coach/data/local/settings_service.dart';
import 'package:drum_coach/features/guided/data/demo_exercise.dart';
import 'package:drum_coach/features/guided/data/guided_catalog.dart';
import 'package:drum_coach/features/guided/data/guided_lookup.dart';
import 'package:drum_coach/features/guided/guided_format.dart';
import 'package:drum_coach/features/guided/guided_pages.dart';
import 'package:drum_coach/features/guided/guided_rig_provider.dart';
import 'package:drum_coach/features/guided/guided_shortcuts.dart';
import 'package:drum_coach/features/guided/models/guided_exercise.dart';
import 'package:drum_coach/features/guided/screens/guided_play_screen.dart';
import 'package:drum_coach/features/guided/screens/guided_preview_screen.dart';
import 'package:drum_coach/features/guided/widgets/guided_page_view.dart';
import 'package:drum_coach/features/practice/widgets/tempo_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../fake_guided_player.dart';

const _photo = 'assets/illustrations/practice/p07_rooftop_dusk_s5.jpg';

GuidedExercise get _kit => guidedCatalog.first;

String _variationLabel(int n, GuidedSection s) =>
    'Variation $n${s.titleEn == null ? '' : ' · ${s.titleEn}'} · ${s.bars} bars';

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

/// Preview with the real play screen behind Start (fake player).
Future<GoRouter> _pumpWithPlay(WidgetTester t, FakeGuidedPlayer p) async {
  debugDesktopOverride = true;
  await t.binding.setSurfaceSize(const Size(1280, 800));
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
      builder: (_, s) => GuidedPlayScreen.fromQuery(
          s.pathParameters['id']!, s.uri.queryParameters,
          photo: 'assets/none.jpg'),
    ),
  ]);
  await t.pumpWidget(ProviderScope(
    overrides: [
      guidedRigProvider.overrideWith(
          (ref) async => GuidedRig(player: p, clips: fakeClipManifest())),
    ],
    child: MaterialApp.router(routerConfig: router, builder: capContentWidth),
  ));
  router.push('/guided/${_kit.id}');
  await t.pumpAndSettle();
  return router;
}

bool _switch(WidgetTester t, String key) => t
    .widget<Switch>(find.descendant(
        of: find.byKey(Key(key)), matching: find.byType(Switch)))
    .value;

String _bpmText(WidgetTester t) {
  return '${t.widget<TempoRow>(find.byType(TempoRow)).bpm}';
}

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await SettingsService.init();
  });
  tearDown(() {
    debugDesktopOverride = null;
    uncappedContentCount.value = 0;
  });

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

  testWidgets('shows header and badges', (t) async {
    await _pump(t, _kit.id, const Size(1280, 800), desktop: true);
    expect(find.text(_kit.name), findsOneWidget);
    expect(find.text(_kit.description), findsOneWidget);
    expect(find.text(guidedDurationLabel(_kit)), findsOneWidget);
    expect(find.text('SET'), findsOneWidget);
    expect(find.text('Ending'), findsNothing);
  });

  GuidedExercise exWithVariations(int n) =>
      guidedCatalog.firstWhere((e) => e.variationCount >= n);

  Finder sheetText(String s) => find.descendant(
      of: find.byKey(const Key('guided-preview-sheet')),
      matching: find.textContaining(s, skipOffstage: false));

  testWidgets('preview sheet lists groove and every variation once', (t) async {
    for (final (size, desktop) in [
      (const Size(1280, 800), true),
      (const Size(412, 915), false),
    ]) {
      final ex = exWithVariations(3);
      await _pump(t, ex.id, size, desktop: desktop);
      expect(t.takeException(), isNull);
      final pageBars = desktop ? 4 : 2;
      final pages = guidedPreviewPages(ex, pageBars: pageBars);
      expect(pages.length, 1 + ex.variationCount);
      expect(find.byType(GuidedPageView, skipOffstage: false),
          findsNWidgets(pages.length),
          reason: '$size');
      expect(sheetText('Groove · '), findsOneWidget);
      for (var n = 1; n <= ex.variationCount; n++) {
        expect(sheetText('Variation $n · '), findsOneWidget, reason: '$size');
      }
      for (final v in find
          .byType(GuidedPageView, skipOffstage: false)
          .evaluate()
          .map((e) => e.widget as GuidedPageView)) {
        expect(v.activeTick, isNull);
        expect(v.fullPageBars, pageBars);
      }
    }
  });

  testWidgets('variation label shows title and bars', (t) async {
    final ex = exWithVariations(2);
    await _pump(t, ex.id, const Size(1280, 800), desktop: true);
    final groove = ex.sections.firstWhere((s) => s.kind == SectionKind.groove);
    expect(sheetText('Groove · ${groove.bars} bars'), findsOneWidget);
    var n = 0;
    for (final s in ex.sections.where((s) => s.kind == SectionKind.variation)) {
      n++;
      expect(sheetText(_variationLabel(n, s)), findsOneWidget);
    }
    // Never the word null for a variation without a title.
    expect(sheetText('null'), findsNothing);
  });

  testWidgets('no explanation text in the preview', (t) async {
    await _pump(t, _kit.id, const Size(1280, 800), desktop: true);
    for (final s in _kit.sections) {
      if (s.textEn == null) continue;
      expect(find.text(s.textEn!, skipOffstage: false), findsNothing);
    }
    expect(find.text('SEQUENCE'), findsNothing);
  });

  testWidgets('sheet scrolls, stage stays', (t) async {
    final ex = guidedCatalog.firstWhere((e) => e.variationCount >= 5,
        orElse: () => exWithVariations(4));
    await _pump(t, ex.id, const Size(1366, 768), desktop: true);
    expect(t.takeException(), isNull);
    final stage = find.byKey(const Key('guided-stage'));
    final sheet = find.byKey(const Key('guided-preview-sheet'));
    final stageBefore = t.getRect(stage);
    expect(stageBefore.height, greaterThanOrEqualTo(0.45 * 768 - 0.5));
    expect(t.getRect(sheet).top, closeTo(stageBefore.bottom, 0.5));
    expect(t.getRect(sheet).bottom, closeTo(768, 0.5));
    final startBefore = t.getRect(find.byKey(const Key('guided-start')));
    expect(startBefore.bottom, lessThanOrEqualTo(stageBefore.bottom));

    var n = 0;
    GuidedSection? lastSection;
    for (final s in ex.sections.where((s) => s.kind == SectionKind.variation)) {
      n++;
      lastSection = s;
    }
    final last =
        find.text(_variationLabel(n, lastSection!), skipOffstage: false);
    expect(last, findsOneWidget);
    final scrollable =
        find.descendant(of: sheet, matching: find.byType(Scrollable)).first;
    await t.scrollUntilVisible(last, 200, scrollable: scrollable);
    await t.pumpAndSettle();
    expect(t.takeException(), isNull);
    expect(last.hitTestable(), findsOneWidget);
    expect(t.getRect(stage), stageBefore);
    expect(t.getRect(find.byKey(const Key('guided-start'))), startBefore);
  });

  testWidgets('settings panel fits the low stage at 1280x720', (t) async {
    await _pump(t, _kit.id, const Size(1280, 720), desktop: true);
    expect(t.takeException(), isNull);
    final stage = t.getRect(find.byKey(const Key('guided-stage')));
    final panel = t.getRect(find
        .ancestor(
            of: find.byKey(const Key('guided-start')),
            matching: find.byType(Container))
        .first);
    expect(panel.top, greaterThanOrEqualTo(stage.top));
    expect(panel.bottom, lessThanOrEqualTo(stage.bottom));
    // The key hint is inside the panel, under Start.
    expect(t.getRect(find.byKey(const Key('guided-key-hint'))).bottom,
        lessThanOrEqualTo(panel.bottom));
  });

  testWidgets('phone: sheet pages show every variation without clipping',
      (t) async {
    for (final id in [
      'guided_kit_backbeat_walk',
      'guided_pad_fives_and_sixes'
    ]) {
      final ex = guidedExerciseById(id)!;
      await _pump(t, ex.id, const Size(412, 915));
      expect(t.takeException(), isNull);
      final last = find.byType(GuidedPageView, skipOffstage: false).last;
      await t.ensureVisible(last);
      await t.pumpAndSettle();
      expect(t.takeException(), isNull);
      final r = t.getRect(last);
      expect(r.left, greaterThanOrEqualTo(0));
      expect(r.right, lessThanOrEqualTo(412 + 0.5));
      expect(r.bottom, lessThanOrEqualTo(915 + 0.5));
    }
  });

  testWidgets('start pushes play only once', (t) async {
    final router =
        await _pump(t, _kit.id, const Size(1280, 800), desktop: true);
    await t.sendKeyEvent(LogicalKeyboardKey.space);
    await t.sendKeyEvent(LogicalKeyboardKey.space);
    await t.pumpAndSettle();
    expect(find.textContaining('play:'), findsOneWidget);
    router.pop();
    await t.pumpAndSettle();
    expect(find.textContaining('play:'), findsNothing);
    expect(find.byType(GuidedPreviewScreen), findsOneWidget);
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

  testWidgets('preview adopts tempo and switches changed during play',
      (t) async {
    final p = FakeGuidedPlayer();
    await _pumpWithPlay(t, p);
    final b = _kit.defaultBpm;
    await _key(t, LogicalKeyboardKey.space);
    expect(find.byType(GuidedPlayScreen), findsOneWidget);
    expect(p.startedBpm, b);
    expect(p.startedOptions!.teacher, isTrue);

    // In play: teacher off, faster; Esc back to the preview.
    await _key(t, LogicalKeyboardKey.keyT);
    await _key(t, LogicalKeyboardKey.arrowUp);
    await _key(t, LogicalKeyboardKey.escape);
    expect(find.byType(GuidedPlayScreen), findsNothing);
    expect(_bpmText(t), '${b + guidedTempoStep}');
    expect(_switch(t, 'guided-teacher'), isFalse);
    expect(_switch(t, 'guided-along'), isTrue);

    // The next Start sends the new values, not the old ones.
    await _key(t, LogicalKeyboardKey.space);
    expect(p.startedBpm, b + guidedTempoStep);
    expect(p.startedOptions!.teacher, isFalse);
    expect(p.startedOptions!.playAlong, isTrue);

    // System back (no Esc, no button) brings the values back too.
    await _key(t, LogicalKeyboardKey.arrowUp);
    await _key(t, LogicalKeyboardKey.keyP);
    await t.binding.handlePopRoute();
    await t.pumpAndSettle();
    expect(find.byType(GuidedPlayScreen), findsNothing);
    expect(p.calls, contains('stop'));
    expect(_bpmText(t), '${b + 2 * guidedTempoStep}');
    expect(_switch(t, 'guided-along'), isFalse);
  });

  testWidgets('tempo step and duration use the shared helpers', (t) async {
    await _pump(t, _kit.id, const Size(412, 915));
    expect(t.widget<TempoRow>(find.byType(TempoRow)).step, guidedTempoStep);
    await t.ensureVisible(find.byTooltip('Faster'));
    await t.pumpAndSettle();
    for (var i = 0; i < 5; i++) {
      await t.tap(find.byTooltip('Faster'));
      await t.pumpAndSettle();
    }
    final bpm = _kit.defaultBpm + 5 * guidedTempoStep;
    expect(_bpmText(t), '$bpm');
    expect(find.text(guidedDurationLabel(_kit, bpm: bpm)), findsOneWidget);
    expect(guidedDurationLabel(_kit, bpm: _kit.defaultBpm),
        guidedDurationLabel(_kit));
  });

  testWidgets('desktop key hint names +/- and stays on one line', (t) async {
    await _pump(t, _kit.id, const Size(1280, 800), desktop: true);
    final hint = find.byKey(const Key('guided-key-hint'));
    expect(t.widget<Text>(hint).data, guidedPreviewKeyHint);
    expect(guidedPreviewKeyHint, contains('±'));
    final para = t.renderObject<RenderParagraph>(hint);
    expect(para.didExceedMaxLines, isFalse);
    expect(para.size.height, lessThan(3 * 12 * 1.3));
    expect(para.text.style!.fontSize, greaterThanOrEqualTo(12),
        reason: 'key hint is at least 12 px');
    final start = t.getRect(find.byKey(const Key('guided-start')));
    final r = t.getRect(hint);
    expect(r.left, greaterThanOrEqualTo(start.left - 0.5));
    expect(r.right, lessThanOrEqualTo(start.right + 0.5));
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

      // Tablet portrait and desktop: stage on top with Start at its right,
      // the sheet below.
      for (final (size, desktop) in [
        (const Size(820, 1180), false),
        (const Size(1280, 800), true),
      ]) {
        await _pump(t, ex.id, size, desktop: desktop);
        expect(t.takeException(), isNull);
        final stage = t.getRect(find.byKey(const Key('guided-stage')));
        final sheet = t.getRect(find.byKey(const Key('guided-preview-sheet')));
        final st = t.getRect(find.byKey(const Key('guided-start')));
        expect(stage.top, 0);
        expect(sheet.top, closeTo(stage.bottom, 0.5));
        expect(st.bottom, lessThanOrEqualTo(stage.bottom));
        expect(st.right, size.width - AppSpacing.screenPadding - AppSpacing.md);
        expect(st.left, greaterThan(size.width / 2));
      }

      // Small landscape phone: still no overflow.
      await _pump(t, ex.id, const Size(700, 360));
      expect(t.takeException(), isNull);
    }
  });

  testWidgets('stage and sheet fill the window width', (t) async {
    for (final size in [const Size(2560, 1440), const Size(1920, 1080)]) {
      await _pump(t, _kit.id, size, desktop: true);
      expect(t.takeException(), isNull);
      for (final k in ['guided-stage', 'guided-preview-sheet']) {
        final r = t.getRect(find.byKey(Key(k)));
        expect(r.left, 0, reason: '$size $k');
        expect(r.width, size.width, reason: '$size $k');
      }
    }
  });

  testWidgets('home behind the preview keeps the 900 cap', (t) async {
    final router =
        await _pump(t, _kit.id, const Size(2560, 1440), desktop: true);
    router.pop();
    await t.pumpAndSettle();
    expect(
        t
            .getSize(find
                .ancestor(
                    of: find.text('home'), matching: find.byType(Scaffold))
                .first)
            .width,
        900);
    expect(uncappedContentCount.value, 0);
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
