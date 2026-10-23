import 'dart:io';

import 'package:drum_coach/app/design_tokens.dart';
import 'package:drum_coach/app/platform_support.dart';
import 'package:drum_coach/data/local/settings_service.dart';
import 'package:drum_coach/features/guided/data/demo_exercise.dart';
import 'package:drum_coach/features/guided/data/guided_catalog.dart';
import 'package:drum_coach/features/guided/data/guided_lookup.dart';
import 'package:drum_coach/features/guided/guided_format.dart';
import 'package:drum_coach/features/guided/guided_rig_provider.dart';
import 'package:drum_coach/features/guided/guided_shortcuts.dart';
import 'package:drum_coach/features/guided/models/guided_exercise.dart';
import 'package:drum_coach/features/guided/screens/guided_play_screen.dart';
import 'package:drum_coach/features/guided/screens/guided_preview_screen.dart';
import 'package:drum_coach/features/guided/widgets/guided_line_view.dart';
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

  testWidgets('start pushes play only once', (t) async {
    final router = await _pump(t, _kit.id, const Size(1280, 800), desktop: true);
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
