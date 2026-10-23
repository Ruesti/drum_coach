import 'dart:async';
import 'dart:io';

import 'package:drum_coach/app/design_tokens.dart';
import 'package:drum_coach/app/platform_support.dart';
import 'package:drum_coach/data/local/settings_service.dart';
import 'package:drum_coach/features/guided/data/guided_catalog.dart';
import 'package:drum_coach/features/guided/guided_rig_provider.dart';
import 'package:drum_coach/features/guided/guided_shortcuts.dart';
import 'package:drum_coach/features/guided/models/guided_exercise.dart';
import 'package:drum_coach/features/guided/run_clock.dart';
import 'package:drum_coach/features/guided/screens/guided_play_screen.dart';
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

/// Index of the [n]-th (1-based) variation of [ex].
int _varIndex(GuidedExercise ex, int n) {
  var k = 0;
  for (var i = 0; i < ex.sections.length; i++) {
    if (ex.sections[i].kind == SectionKind.variation && ++k == n) return i;
  }
  throw StateError('no variation $n');
}

RunPosition _pos(int section, int barInSection,
        {int tick = 0, int bar = 10, int bpm = 120, int? countdown}) =>
    RunPosition(
      bar: bar,
      sectionIndex: section,
      barInSection: barInSection,
      beat: tick ~/ 24 + 1,
      tick: tick,
      bpm: bpm,
      plannedAt: DateTime(2026),
      countdown: countdown,
    );

Future<GoRouter> _open(
  WidgetTester t,
  FakeGuidedPlayer p, {
  Size size = const Size(412, 915),
  bool desktop = false,
  GuidedExercise? ex,
  String query = '?bpm=92&teacher=1&along=1',
  String photo = 'assets/none.jpg',
  Future<GuidedRig> Function()? rig,
  bool settle = true,
}) async {
  debugDesktopOverride = desktop ? true : null;
  await t.binding.setSurfaceSize(size);
  addTearDown(() => t.binding.setSurfaceSize(null));
  final id = (ex ?? _kit).id;
  final router = GoRouter(initialLocation: '/', routes: [
    GoRoute(path: '/', builder: (_, __) => const Scaffold(body: Text('home'))),
    GoRoute(
        path: '/library',
        builder: (_, __) => const Scaffold(body: Text('library'))),
    GoRoute(
        path: '/guided/:id',
        builder: (_, __) => const Scaffold(body: Text('preview'))),
    GoRoute(
      path: '/guided/:id/play',
      builder: (_, s) => GuidedPlayScreen.fromQuery(
          s.pathParameters['id']!, s.uri.queryParameters,
          photo: photo),
    ),
  ]);
  await t.pumpWidget(ProviderScope(
    overrides: [
      guidedRigProvider.overrideWith(
          (ref) => rig != null
              ? rig()
              : Future.value(
                  GuidedRig(player: p, clips: fakeClipManifest()))),
    ],
    child: RepaintBoundary(
      key: const Key('shot'),
      child: MaterialApp.router(
        debugShowCheckedModeBanner: false,
        routerConfig: router,
        builder: capContentWidth,
      ),
    ),
  ));
  router.push('/guided/$id');
  await t.pumpAndSettle();
  router.push('/guided/$id/play$query');
  if (settle) {
    await t.pumpAndSettle();
  } else {
    await t.pump();
    await t.pump(const Duration(seconds: 1));
  }
  return router;
}

Future<void> _emit(WidgetTester t, FakeGuidedPlayer p, RunPosition pos) async {
  p.positionCtrl.add(pos);
  await t.pumpAndSettle();
}

Future<void> _key(WidgetTester t, LogicalKeyboardKey k,
    {bool shift = false}) async {
  if (shift) await t.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
  await t.sendKeyEvent(k);
  if (shift) await t.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
  await t.pumpAndSettle();
}

GuidedLineView _nowView(WidgetTester t) =>
    t.widget<GuidedLineView>(find.descendant(
        of: find.byKey(const Key('guided-now')),
        matching: find.byType(GuidedLineView)));

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await SettingsService.init();
  });
  tearDown(() {
    debugDesktopOverride = null;
    uncappedContentCount.value = 0;
  });

  testWidgets('starts with bpm and options from the route', (t) async {
    final p = FakeGuidedPlayer();
    await _open(t, p, query: '?bpm=92&teacher=0&along=1');
    expect(p.calls, ['start']);
    expect(p.started, same(_kit));
    expect(p.startedBpm, 92);
    expect(p.startedOptions!.teacher, isFalse);
    expect(p.startedOptions!.playAlong, isTrue);
    expect(find.text(_kit.name), findsOneWidget);
  });

  testWidgets('missing or odd query falls back to the exercise defaults',
      (t) async {
    final p = FakeGuidedPlayer();
    await _open(t, p, query: '?bpm=9999');
    expect(p.startedBpm, _kit.maxBpm);
    expect(p.startedOptions!.teacher, SettingsService.guidedTeacher);
  });

  testWidgets('banner shows coming-up text before a variation', (t) async {
    final p = FakeGuidedPlayer();
    await _open(t, p);
    final v1 = _varIndex(_kit, 1);
    await _emit(t, p, _pos(v1 - 1, 0));
    expect(find.byKey(const Key('guided-banner')), findsOneWidget);
    expect(find.text('COMING UP'), findsOneWidget);
    expect(find.text(_kit.sections[v1].textEn!), findsOneWidget);
    // The coming variation, dimmed, inside the banner.
    final next = t.widget<GuidedLineView>(find.descendant(
        of: find.byKey(const Key('guided-banner')),
        matching: find.byType(GuidedLineView)));
    expect(next.dimmed, isTrue);
    expect(next.line, same(_kit.sections[v1].line));

    // During the variation: no banner, the text stays small over the notes.
    await _emit(t, p, _pos(v1, 0));
    expect(find.byKey(const Key('guided-banner')), findsNothing);
    expect(t.widget<Text>(find.byKey(const Key('guided-now-text'))).data,
        _kit.sections[v1].textEn);
    expect(_nowView(t).line, same(_kit.sections[v1].line));
  });

  testWidgets(
      'countdown numbers appear in the countdown bar, also with '
      'teacher off', (t) async {
    final p = FakeGuidedPlayer();
    await _open(t, p, query: '?bpm=92&teacher=0&along=1');
    final v1 = _varIndex(_kit, 1);
    final cd = find.byKey(const Key('guided-countdown'));
    await _emit(t, p, _pos(v1 - 1, 3, tick: 0));
    expect(cd, findsNothing);
    for (final (n, label) in [(3, '3'), (2, '2'), (1, '1')]) {
      await _emit(t, p, _pos(v1 - 1, 3, tick: (4 - n) * 24, countdown: n));
      expect(
          find.descendant(of: cd, matching: find.text(label)), findsOneWidget);
    }
    await _emit(t, p, _pos(v1, 0, countdown: 0));
    expect(find.descendant(of: cd, matching: find.text('GO')), findsOneWidget);
    await _emit(t, p, _pos(v1, 0, tick: 24));
    expect(cd, findsNothing);
  });

  testWidgets('cursor follows run position', (t) async {
    final p = FakeGuidedPlayer();
    await _open(t, p);
    final g = _varIndex(_kit, 1) - 1;
    final line = _kit.sections[g].line;
    await _emit(t, p, _pos(g, 0, tick: 30));
    expect(_nowView(t).activeTick,
        lineTickFor(_pos(g, 0, tick: 30), line, _kit.gridUnit));
    await _emit(t, p, _pos(g, 1, tick: 60));
    expect(_nowView(t).activeTick,
        lineTickFor(_pos(g, 1, tick: 60), line, _kit.gridUnit));
    expect(_nowView(t).dimmed, isFalse);
  });

  testWidgets('timeline marker advances', (t) async {
    final p = FakeGuidedPlayer();
    await _open(t, p);
    final marker = find.byKey(const Key('guided-timeline-marker'));
    await _emit(t, p, _pos(1, 0));
    final a = t.getCenter(marker).dx;
    await _emit(t, p, _pos(1, 2));
    final b = t.getCenter(marker).dx;
    await _emit(t, p, _pos(_varIndex(_kit, 2), 0));
    final c = t.getCenter(marker).dx;
    expect(b, greaterThan(a));
    expect(c, greaterThan(b));

    // Desktop: vertical, it moves down.
    final q = FakeGuidedPlayer();
    await _open(t, q, size: const Size(1280, 720), desktop: true);
    await _emit(t, q, _pos(1, 0));
    final d = t.getCenter(marker).dy;
    await _emit(t, q, _pos(_varIndex(_kit, 2), 0));
    expect(t.getCenter(marker).dy, greaterThan(d));
  });

  testWidgets('resizing while playing keeps the run', (t) async {
    final p = FakeGuidedPlayer();
    await _open(t, p, size: const Size(1280, 720), desktop: true);
    final v1 = _varIndex(_kit, 1);
    await _emit(t, p, _pos(v1, 2, tick: 30));
    expect(find.byKey(const Key('guided-wide')), findsOneWidget);
    await t.binding.setSurfaceSize(const Size(412, 915));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('guided-wide')), findsNothing);
    expect(t.takeException(), isNull);
    await t.binding.setSurfaceSize(const Size(1280, 720));
    await t.pumpAndSettle();
    expect(p.calls, ['start']);
    expect(find.text('Variation 1 of ${_kit.variationCount} · bar 3'),
        findsOneWidget);
    expect(find.text('Pause'), findsOneWidget);
  });

  testWidgets('long variation text wraps at 412 wide', (t) async {
    // The longest explanation of the catalog.
    GuidedExercise? ex;
    var vi = -1;
    var longest = '';
    for (final e in guidedCatalog) {
      for (var i = 0; i < e.sections.length; i++) {
        final s = e.sections[i].textEn;
        if (s != null && s.length > longest.length) {
          (ex, vi, longest) = (e, i, s);
        }
      }
    }
    final p = FakeGuidedPlayer();
    await _open(t, p, ex: ex);
    await _emit(t, p, _pos(vi - 1, 0));
    expect(t.takeException(), isNull);
    final text = find.text(longest);
    final style = t.widget<Text>(text).style!;
    expect(t.getSize(text).height,
        greaterThan(1.5 * style.fontSize! * (style.height ?? 1.2)));
    expect(t.getRect(text).right, lessThanOrEqualTo(412));
    await _emit(t, p, _pos(vi, 0));
    expect(t.takeException(), isNull);
  });

  testWidgets('leaving the screen stops the player', (t) async {
    final p = FakeGuidedPlayer();
    await _open(t, p);
    await t.tap(find.byTooltip('Back'));
    await t.pumpAndSettle();
    expect(p.calls, contains('stop'));
    expect(find.text('preview'), findsOneWidget);

    // Esc on desktop: stop and back.
    final q = FakeGuidedPlayer();
    await _open(t, q, size: const Size(1280, 720), desktop: true);
    await _key(t, LogicalKeyboardKey.escape);
    expect(q.calls, contains('stop'));
    expect(find.text('preview'), findsOneWidget);
  });

  testWidgets('finished shows the end view; space does not restart', (t) async {
    final p = FakeGuidedPlayer();
    await _open(t, p, size: const Size(1280, 720), desktop: true);
    await _emit(t, p, _pos(_kit.sections.length - 1, 0, bar: 10, bpm: 120));
    p.finishedCtrl.add(null);
    await t.pumpAndSettle();
    expect(find.byKey(const Key('guided-end')), findsOneWidget);
    expect(find.text('Done'), findsOneWidget);
    expect(find.text(_kit.name), findsOneWidget);
    // 11 bars at 120 BPM played.
    expect(find.text('0:22'), findsOneWidget);
    expect(find.text('92'), findsOneWidget);
    await _key(t, LogicalKeyboardKey.space);
    expect(p.calls, ['start']);
    await t.tap(find.text('Again'));
    await t.pumpAndSettle();
    expect(p.calls, ['start', 'start']);
    expect(find.byKey(const Key('guided-end')), findsNothing);
    p.finishedCtrl.add(null);
    await t.pumpAndSettle();
    await t.tap(find.text('Back to library'));
    await t.pumpAndSettle();
    expect(find.text('library'), findsOneWidget);
  });

  testWidgets('end view ignores every key but Esc', (t) async {
    final p = FakeGuidedPlayer();
    await _open(t, p, size: const Size(1280, 720), desktop: true);
    p.finishedCtrl.add(null);
    await t.pumpAndSettle();
    expect(find.byKey(const Key('guided-end')), findsOneWidget);
    final calls = [...p.calls];
    for (final k in [
      LogicalKeyboardKey.space,
      LogicalKeyboardKey.arrowUp,
      LogicalKeyboardKey.arrowDown,
      LogicalKeyboardKey.minus,
      LogicalKeyboardKey.equal,
      LogicalKeyboardKey.keyT,
      LogicalKeyboardKey.keyP,
    ]) {
      await _key(t, k);
    }
    await _key(t, LogicalKeyboardKey.arrowUp, shift: true);
    expect(p.calls, calls);
    expect(p.setBpmCalls, isEmpty);
    expect(p.optionCalls, isEmpty);
    expect(SettingsService.guidedTeacher, isTrue);
    expect(SettingsService.guidedPlayAlong, isTrue);
    expect(find.text('92'), findsOneWidget);
    await _key(t, LogicalKeyboardKey.escape);
    expect(find.text('preview'), findsOneWidget);
  });

  testWidgets('loading view has Back and Esc', (t) async {
    final gate = Completer<GuidedRig>();
    final p = FakeGuidedPlayer();
    await _open(t, p, rig: () => gate.future, settle: false);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await t.tap(find.byKey(const Key('guided-loading-back')));
    await t.pump();
    await t.pump(const Duration(seconds: 1));
    expect(find.byType(GuidedPlayScreen), findsNothing);
    expect(find.text('preview'), findsOneWidget);
    expect(p.calls, isEmpty);

    // Desktop: Esc while loading.
    await _open(t, p,
        size: const Size(1280, 720),
        desktop: true,
        rig: () => Completer<GuidedRig>().future,
        settle: false);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await t.sendKeyEvent(LogicalKeyboardKey.escape);
    await t.pump();
    await t.pump(const Duration(seconds: 1));
    expect(find.byType(GuidedPlayScreen), findsNothing);
    expect(find.text('preview'), findsOneWidget);
  });

  testWidgets('tempo row and key hint', (t) async {
    final p = FakeGuidedPlayer();
    await _open(t, p, size: const Size(1280, 720), desktop: true);
    expect(t.widget<TempoRow>(find.byType(TempoRow)).step, guidedTempoStep);
    final hint = find.byKey(const Key('guided-key-hint'));
    expect(t.widget<Text>(hint).data, guidedPlayKeyHint);
    expect(guidedPlayKeyHint, contains('±'));
    final para = t.renderObject<RenderParagraph>(hint);
    expect(para.didExceedMaxLines, isFalse);
    expect(para.size.height, lessThan(3 * 12 * 1.3));
    expect(para.text.style!.fontSize, greaterThanOrEqualTo(12),
        reason: 'key hint is at least 12 px');
    final stop = t.getRect(find.byKey(const Key('guided-play-stop')));
    expect(t.getRect(hint).right, lessThanOrEqualTo(stop.right + 0.5));
  });

  group('content cap at 1600 wide', () {
    Size sizeOf(WidgetTester t, String text) => t.getSize(find
        .ancestor(of: find.text(text), matching: find.byType(Scaffold))
        .first);

    testWidgets('play screen is 1440 wide', (t) async {
      final p = FakeGuidedPlayer();
      await _open(t, p, size: const Size(1600, 900), desktop: true);
      expect(t.getSize(find.byType(GuidedPlayScreen)).width, 1440);
      expect(find.byKey(const Key('guided-wide')), findsOneWidget);
    });

    testWidgets('cap returns to 900 on the first frame of the pop',
        (t) async {
      final p = FakeGuidedPlayer();
      await _open(t, p, size: const Size(1600, 900), desktop: true);
      expect(t.getSize(find.byType(GuidedPlayScreen)).width, 1440);
      await t.sendKeyEvent(LogicalKeyboardKey.escape);
      await t.pump();
      // Pop animation running: both pages there, already capped.
      expect(find.byType(GuidedPlayScreen), findsOneWidget);
      expect(sizeOf(t, 'preview').width, 900);
      expect(t.getSize(find.byType(GuidedPlayScreen)).width, 900);
      await t.pumpAndSettle();
      expect(sizeOf(t, 'preview').width, 900);
      expect(uncappedContentCount.value, 0);
    });

    testWidgets('library is 900 after Back to library', (t) async {
      final p = FakeGuidedPlayer();
      await _open(t, p, size: const Size(1600, 900), desktop: true);
      p.finishedCtrl.add(null);
      await t.pumpAndSettle();
      await t.tap(find.text('Back to library'));
      // The first frame that shows the library is already capped.
      var frames = 0;
      while (find.text('library').evaluate().isEmpty) {
        await t.pump(const Duration(milliseconds: 16));
        expect(++frames, lessThan(10));
      }
      expect(sizeOf(t, 'library').width, 900);
      await t.pumpAndSettle();
      expect(find.byType(GuidedPlayScreen), findsNothing);
      expect(sizeOf(t, 'library').width, 900);
      expect(uncappedContentCount.value, 0);
    });
  });

  testWidgets('pause, resume and a frozen run', (t) async {
    final p = FakeGuidedPlayer();
    await _open(t, p);
    await t.tap(find.byKey(const Key('guided-play-toggle')));
    await t.pump();
    expect(p.calls.last, 'pause');
    expect(find.text('Resume'), findsOneWidget);
    await t.tap(find.byKey(const Key('guided-play-toggle')));
    await t.pump();
    expect(p.calls.last, 'resume');
    p.frozen = true;
    p.stateCtrl.add(null);
    await t.pump();
    expect(find.text('Resume'), findsOneWidget);
  });

  testWidgets('controls and keys change tempo and options live', (t) async {
    final p = FakeGuidedPlayer();
    await _open(t, p, size: const Size(1280, 720), desktop: true);
    await _key(t, LogicalKeyboardKey.arrowUp);
    expect(p.setBpmCalls.last, 96);
    await _key(t, LogicalKeyboardKey.arrowUp, shift: true);
    expect(p.setBpmCalls.last, 104);
    await _key(t, LogicalKeyboardKey.arrowDown);
    expect(p.setBpmCalls.last, 100);
    for (var i = 0; i < 40; i++) {
      await _key(t, LogicalKeyboardKey.arrowUp, shift: true);
    }
    expect(p.setBpmCalls.last, _kit.maxBpm);
    await _key(t, LogicalKeyboardKey.keyT);
    expect(p.optionCalls.last.teacher, isFalse);
    expect(SettingsService.guidedTeacher, isFalse);
    await _key(t, LogicalKeyboardKey.keyP);
    expect(p.optionCalls.last.playAlong, isFalse);
    expect(p.optionCalls.last.teacher, isFalse);
    await t.tap(find.byKey(const Key('guided-teacher')));
    await t.pumpAndSettle();
    expect(p.optionCalls.last.teacher, isTrue);
    await _key(t, LogicalKeyboardKey.space);
    expect(p.calls.last, 'pause');
  });

  testWidgets(
      'wide layout fits 1280x720 without scrolling; no overflow '
      'at phone and tablet', (t) async {
    final v2 = _varIndex(_kit, 2);
    for (final (size, desktop) in [
      (const Size(1280, 720), true),
      (const Size(412, 915), false),
      (const Size(820, 1180), false),
    ]) {
      final p = FakeGuidedPlayer();
      await _open(t, p, size: size, desktop: desktop);
      for (final pos in [
        _pos(-1, 0),
        _pos(v2 - 1, 0),
        _pos(v2 - 1, 3, tick: 30, countdown: 2),
        _pos(v2, 1, tick: 40),
        _pos(_kit.sections.length - 1, 0),
      ]) {
        await _emit(t, p, pos);
        expect(t.takeException(), isNull, reason: '$size');
        if (desktop) {
          for (final s in t.stateList<ScrollableState>(find.descendant(
              of: find.byKey(const Key('guided-main-scroll')),
              matching: find.byType(Scrollable)))) {
            expect(s.position.maxScrollExtent, 0,
                reason: 'section ${pos.sectionIndex}');
          }
        }
      }
      p.finishedCtrl.add(null);
      await t.pumpAndSettle();
      expect(t.takeException(), isNull, reason: '$size end');
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

    Future<FakeGuidedPlayer> shot(WidgetTester t, Size size, bool desktop,
        {required List<RunPosition> positions}) async {
      final p = FakeGuidedPlayer();
      await _open(t, p, size: size, desktop: desktop, photo: _photo);
      await t.runAsync(() async {
        final el = t.element(find.byType(GuidedPlayScreen));
        await precacheImage(const AssetImage(_photo), el);
      });
      for (final pos in positions) {
        await _emit(t, p, pos);
      }
      return p;
    }

    testWidgets('golden: desktop mid-run, banner and countdown', (t) async {
      final v2 = _varIndex(_kit, 2);
      await shot(t, const Size(1280, 720), true, positions: [
        _pos(v2 - 2, 4, bar: 20),
        _pos(v2 - 1, 3, tick: 54, bar: 30, countdown: 2),
      ]);
      expect(t.takeException(), isNull);
      await expectLater(find.byKey(const Key('shot')),
          matchesGoldenFile('../../goldens/guided_play_desktop.png'));
    });

    testWidgets('golden: phone mid-run with banner', (t) async {
      final v2 = _varIndex(_kit, 2);
      await shot(t, const Size(412, 915), false, positions: [
        _pos(v2 - 2, 4, bar: 20),
        _pos(v2 - 1, 1, tick: 30, bar: 28),
      ]);
      expect(t.takeException(), isNull);
      await expectLater(find.byKey(const Key('shot')),
          matchesGoldenFile('../../goldens/guided_play_phone.png'));
    });

    testWidgets('golden: phone in a variation', (t) async {
      final v2 = _varIndex(_kit, 2);
      await shot(t, const Size(412, 915), false, positions: [
        _pos(v2, 2, tick: 40, bar: 33),
      ]);
      expect(t.takeException(), isNull);
      await expectLater(find.byKey(const Key('shot')),
          matchesGoldenFile('../../goldens/guided_play_phone_variation.png'));
    });

    testWidgets('golden: desktop in a variation', (t) async {
      final v2 = _varIndex(_kit, 2);
      await shot(t, const Size(1280, 720), true, positions: [
        _pos(v2, 2, tick: 40, bar: 33),
      ]);
      expect(t.takeException(), isNull);
      await expectLater(find.byKey(const Key('shot')),
          matchesGoldenFile('../../goldens/guided_play_desktop_variation.png'));
    });

    testWidgets('golden: end view', (t) async {
      final p = await shot(t, const Size(1280, 720), true, positions: [
        _pos(_kit.sections.length - 1, 0, bar: 120, bpm: 92),
      ]);
      p.finishedCtrl.add(null);
      await t.pumpAndSettle();
      expect(t.takeException(), isNull);
      await expectLater(find.byKey(const Key('shot')),
          matchesGoldenFile('../../goldens/guided_play_end.png'));
    });
  });
}
