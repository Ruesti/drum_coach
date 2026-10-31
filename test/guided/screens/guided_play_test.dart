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
import 'package:drum_coach/features/guided/run_plan.dart';
import 'package:drum_coach/features/guided/screens/guided_play_screen.dart';
import 'package:drum_coach/features/guided/widgets/guided_banner.dart';
import 'package:drum_coach/features/guided/widgets/guided_line_view.dart';
import 'package:drum_coach/features/guided/widgets/guided_page_view.dart';
import 'package:drum_coach/features/guided/widgets/guided_stage.dart';
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
import '../playhead_probe.dart';

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
      guidedRigProvider.overrideWith((ref) => rig != null
          ? rig()
          : Future.value(GuidedRig(player: p, clips: fakeClipManifest()))),
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

GuidedPageView _pageView(WidgetTester t, String key) =>
    t.widget<GuidedPageView>(find.descendant(
        of: find.byKey(Key(key)), matching: find.byType(GuidedPageView)));

/// The page being played (upper row of the sheet).
GuidedPageView _nowView(WidgetTester t) => _pageView(t, 'guided-now');

/// The page after it (lower row, dimmed).
GuidedPageView _nextView(WidgetTester t) => _pageView(t, 'guided-next');

String _text(WidgetTester t, String key) {
  final w = t.widget(find.byKey(Key(key)));
  return w is Text
      ? (w.data ?? w.textSpan!.toPlainText())
      : t
          .widget<Text>(find.descendant(
              of: find.byKey(Key(key)), matching: find.byType(Text)))
          .data!;
}

/// Planned bars of section [i] in the run (the extension included).
int _planBars(GuidedExercise ex, int i,
        {int bpm = 92, bool teacher = true, bool along = true}) =>
    buildRun(ex,
            bpm: bpm,
            options: RunOptions(teacher: teacher, playAlong: along),
            clips: fakeClipManifest())
        .where((b) => b.sectionIndex == i)
        .length;

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
    // Text only (Task 6): the coming variation's notes are on the sheet,
    // so the banner fits on the phone without scrolling.
    final banner =
        t.widget<GuidedBanner>(find.byKey(const Key('guided-banner')));
    expect(banner.showLine, isFalse);
    expect(banner.variation, 1);
    expect(
        t.getRect(find.byKey(const Key('guided-banner'))).bottom,
        lessThanOrEqualTo(
            t.getRect(find.byKey(const Key('guided-play-toggle'))).top));

    // During the variation: no banner, the text stays small over the notes.
    await _emit(t, p, _pos(v1, 0));
    expect(find.byKey(const Key('guided-banner')), findsNothing);
    expect(t.widget<Text>(find.byKey(const Key('guided-now-text'))).data,
        _kit.sections[v1].textEn);
    expect(_nowView(t).page.sectionIndex, v1);
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

  testWidgets('playhead: a thin line over the notes, no note coloured',
      (t) async {
    // Uli 27.10. (round 2): "dünne Linie über den Noten", the notes are
    // not coloured.
    final pad = guidedCatalog.firstWhere((e) => e.package == GuidedPackage.pad);
    for (final (ex, size, desktop) in [
      (_kit, const Size(412, 915), false),
      (_kit, const Size(2560, 1440), true),
      (pad, const Size(1280, 720), true),
    ]) {
      final p = FakeGuidedPlayer();
      await _open(t, p, size: size, desktop: desktop, ex: ex);
      final g = _varIndex(ex, 1) - 1;
      final v = g + 1;
      final now = find.byKey(const Key('guided-now'));
      double? lastX;
      for (final pos in [
        _pos(g, 0, tick: 0),
        _pos(g, 0, tick: 30),
        _pos(g, 0, tick: 60),
      ]) {
        await _emit(t, p, pos);
        expect(_nowView(t).dimmed, isFalse);
        final c = staffCalls(t, now);
        expect(c.playheads, isEmpty, reason: 'blue, not accent');
        final heads = c.playheadsIn(guidedPlayheadBlue);
        expect(heads, hasLength(1), reason: '${ex.id} $size');
        final ph = heads.single;
        expect(ph.width, lessThanOrEqualTo(3.0), reason: '${ex.id} $size');
        expect(c.hasCursorField, isFalse);
        expect(c.hasNoteRing, isFalse);
        if (lastX != null) {
          expect(ph.x, greaterThan(lastX), reason: '${ex.id} $size');
        }
        lastX = ph.x;
      }
      // In the variation the line follows too.
      await _emit(t, p, _pos(v, 0, tick: 24));
      expect(staffCalls(t, now).playheadsIn(guidedPlayheadBlue), hasLength(1));
      // Where am I stays visible: status line and timeline marker.
      expect(t.widget<Text>(find.byKey(const Key('guided-status'))).data,
          contains('Variation 1'));
      expect(find.byKey(const Key('guided-timeline-marker')), findsOneWidget);
      expect(_nowView(t).page.sectionIndex, v);
    }
  });

  testWidgets('stage spans the whole window at 2560 and 1920', (t) async {
    for (final size in [const Size(2560, 1440), const Size(1920, 1080)]) {
      final p = FakeGuidedPlayer();
      await _open(t, p, size: size, desktop: true);
      final stage = t.getRect(find.byType(GuidedStage));
      expect(stage.width, size.width, reason: '$size');
      expect(stage.left, 0, reason: '$size');
      final wide = t.getRect(find.byKey(const Key('guided-wide')));
      expect(wide.width, size.width, reason: '$size');
      // The pages run to the gutters, no cap.
      final now = t.getRect(find.byKey(const Key('guided-now')));
      expect(now.left, AppSpacing.screenPadding, reason: '$size');
      expect(now.right, size.width - AppSpacing.screenPadding, reason: '$size');
    }
  });

  testWidgets('notes span at least 90 % of the window at 1280, 1600, 2560',
      (t) async {
    final v2 = _varIndex(_kit, 2);
    for (final size in [
      const Size(1280, 720),
      const Size(1600, 900),
      const Size(2560, 1440),
    ]) {
      final p = FakeGuidedPlayer();
      await _open(t, p, size: size, desktop: true);
      expect(t.getSize(find.byType(GuidedPlayScreen)).width, size.width);
      for (final pos in [_pos(v2 - 1, 0), _pos(v2, 1, tick: 40)]) {
        await _emit(t, p, pos);
        for (final key in ['guided-now', 'guided-next']) {
          final staff = t.getRect(find.descendant(
              of: find.byKey(Key(key)), matching: find.byType(FittedBox)));
          expect(staff.width, greaterThanOrEqualTo(0.9 * size.width),
              reason: '$size $key section ${pos.sectionIndex}');
        }
        // Review Focus 3: wide, but not absurdly high.
        expect(t.getSize(find.byKey(const Key('guided-now'))).height,
            lessThanOrEqualTo(400),
            reason: '$size');
      }
      // Countdown disc and banner: on the stage, bottom centre.
      await _emit(t, p, _pos(v2 - 1, 3, tick: 30, countdown: 2));
      final stage = t.getRect(find.byKey(const Key('guided-stage')));
      final disc = t.getRect(find.byType(GuidedCountdown));
      final banner = t.getRect(find.byKey(const Key('guided-banner')));
      expect(disc.width, lessThanOrEqualTo(100));
      for (final r in [disc, banner]) {
        expect(
            stage.contains(r.topLeft) &&
                stage.contains(r.bottomRight - const Offset(0.01, 0.01)),
            isTrue,
            reason: '$size $r in $stage');
        expect(r.center.dx, closeTo(size.width / 2, 1), reason: '$size');
        expect(r.center.dy, greaterThan(stage.center.dy), reason: '$size');
      }
    }
  });

  testWidgets('progress bar height ≤ half of before', (t) async {
    // Before 27.10. the horizontal bar's track was 8 px high (marker 14,
    // the whole bar with labels 34); the wide layout even had a vertical
    // column of the full height.
    const before = 8.0;
    const beforeWidget = 34.0;
    for (final (size, desktop) in [
      (const Size(412, 915), false),
      (const Size(1280, 720), true),
    ]) {
      final p = FakeGuidedPlayer();
      await _open(t, p, size: size, desktop: desktop);
      await _emit(t, p, _pos(_varIndex(_kit, 1), 0));
      final track = t.getSize(find.byKey(const Key('guided-timeline-track')));
      expect(track.height, lessThanOrEqualTo(before / 2), reason: '$size');
      expect(track.width, greaterThan(track.height * 20),
          reason: 'horizontal on every layout');
      final bar = t.getSize(find.byKey(const Key('guided-timeline')));
      expect(bar.height, lessThan(beforeWidget), reason: '$size');
      // The labels stay readable.
      final v1 = find.descendant(
          of: find.byKey(const Key('guided-timeline')),
          matching: find.text('V1'));
      expect(v1, findsOneWidget);
      expect(t.widget<Text>(v1).style!.fontSize, greaterThanOrEqualTo(12));
    }
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

    // Desktop: the same thin bar under the header, it moves right.
    final q = FakeGuidedPlayer();
    await _open(t, q, size: const Size(1280, 720), desktop: true);
    await _emit(t, q, _pos(1, 0));
    final d = t.getCenter(marker).dx;
    await _emit(t, q, _pos(_varIndex(_kit, 2), 0));
    expect(t.getCenter(marker).dx, greaterThan(d));
    // In the control bar under the sheet.
    expect(t.getCenter(marker).dy,
        greaterThan(t.getRect(find.byKey(const Key('guided-next'))).bottom));
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
    // Never over the notes.
    final sheet = t.getRect(find.byKey(const Key('guided-sheet')));
    expect(t.getRect(hint).overlaps(sheet), isFalse);
    expect(t.getRect(hint).right, lessThanOrEqualTo(1280));
  });

  group('content cap at 1600 wide', () {
    Size sizeOf(WidgetTester t, String text) => t.getSize(find
        .ancestor(of: find.text(text), matching: find.byType(Scaffold))
        .first);

    testWidgets('play screen fills the window', (t) async {
      final p = FakeGuidedPlayer();
      await _open(t, p, size: const Size(1600, 900), desktop: true);
      expect(t.getSize(find.byType(GuidedPlayScreen)).width, 1600);
      expect(find.byKey(const Key('guided-wide')), findsOneWidget);
    });

    testWidgets('cap returns to 900 on the first frame of the pop', (t) async {
      final p = FakeGuidedPlayer();
      await _open(t, p, size: const Size(1600, 900), desktop: true);
      expect(t.getSize(find.byType(GuidedPlayScreen)).width, 1600);
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
      (const Size(1600, 900), true),
      (const Size(1024, 768), true),
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
          final hint = t.renderObject<RenderParagraph>(
              find.byKey(const Key('guided-key-hint')));
          expect(hint.didExceedMaxLines, isFalse, reason: '$size');
        }
      }
      p.finishedCtrl.add(null);
      await t.pumpAndSettle();
      expect(t.takeException(), isNull, reason: '$size end');
    }
  });

  group('Drumeo look', () {
    int firstGroove(GuidedExercise ex) =>
        ex.sections.indexWhere((s) => s.kind == SectionKind.groove);

    Rect staffRect(WidgetTester t, String key) => t.getRect(find.descendant(
        of: find.byKey(Key(key)), matching: find.byType(FittedBox)));

    testWidgets('wide play shows stage, sheet and controls in that order',
        (t) async {
      final p = FakeGuidedPlayer();
      await _open(t, p, size: const Size(1920, 1080), desktop: true);
      await _emit(t, p, _pos(firstGroove(_kit), 1, tick: 30));
      final stage = t.getRect(find.byKey(const Key('guided-stage')));
      final sheet = t.getRect(find.byKey(const Key('guided-sheet')));
      final controls = t.getRect(find.byKey(const Key('guided-controls')));
      expect(stage.top, 0);
      expect(sheet.top, closeTo(stage.bottom, 0.5));
      expect(controls.top, closeTo(sheet.bottom, 0.5));
      expect(controls.bottom, 1080);
      for (final r in [stage, sheet, controls]) {
        expect(r.width, 1920);
      }
      // The stage gets the most, the sheet about the Richtwert (38 %).
      expect(stage.height, greaterThan(sheet.height));
      expect(sheet.height, inInclusiveRange(0.28 * 1080, 0.42 * 1080));
      expect(controls.height, lessThanOrEqualTo(0.09 * 1080));
      // White sheet.
      expect(t.widget<ColoredBox>(find.byKey(const Key('guided-sheet'))).color,
          Colors.white);
      // Two pages in the sheet, the lower one dimmed.
      final now = t.getRect(find.byKey(const Key('guided-now')));
      final next = t.getRect(find.byKey(const Key('guided-next')));
      expect(sheet.contains(now.center) && sheet.contains(next.center), isTrue);
      expect(next.top, greaterThanOrEqualTo(now.bottom));
      expect(_nowView(t).dimmed, isFalse);
      expect(_nextView(t).dimmed, isTrue);
      // Little empty paper: the two pages fill most of the sheet.
      expect(now.height + next.height, greaterThan(0.7 * sheet.height));
      // Both pages at their natural size: over the full width.
      for (final key in ['guided-now', 'guided-next']) {
        expect(staffRect(t, key).width,
            greaterThanOrEqualTo(1920 - 2 * AppSpacing.screenPadding - 1),
            reason: key);
      }
      // One row of controls, everything inside the bar.
      final row = [
        'guided-play-toggle',
        'guided-play-stop',
        'guided-time',
        'guided-timeline',
        'guided-total',
        'guided-teacher',
        'guided-along',
        'guided-key-hint',
      ];
      for (final k in row) {
        final r = t.getRect(find.byKey(Key(k)));
        expect(r.top, greaterThanOrEqualTo(controls.top), reason: k);
        expect(r.bottom, lessThanOrEqualTo(controls.bottom), reason: k);
        expect(r.left, greaterThanOrEqualTo(0), reason: k);
        expect(r.right, lessThanOrEqualTo(1920), reason: k);
      }
      final tempo = t.getRect(find.byType(TempoRow));
      expect(controls.contains(tempo.center), isTrue);
      double x(String k) => t.getRect(find.byKey(Key(k))).left;
      expect(x('guided-play-toggle'), lessThan(x('guided-play-stop')));
      expect(x('guided-play-stop'), lessThan(x('guided-time')));
      expect(x('guided-time'), lessThan(x('guided-timeline')));
      expect(x('guided-timeline'), lessThan(x('guided-total')));
      expect(x('guided-total'), lessThan(tempo.left));
      expect(tempo.left, lessThan(x('guided-teacher')));
      expect(x('guided-teacher'), lessThan(x('guided-along')));
      expect(x('guided-along'), lessThan(x('guided-key-hint')));
      expect(t.getSize(find.byKey(const Key('guided-timeline'))).width,
          greaterThan(400));
      expect(_text(t, 'guided-total'), startsWith('~'));
      // Stage overlays: package · level, name, status, back before the title.
      final tag = '${_kit.package == GuidedPackage.kit ? 'SET' : 'PAD'}'
          ' · ${_kit.difficulty.label.toUpperCase()}';
      for (final f in [
        find.text(tag),
        find.text(_kit.name),
        find.byKey(const Key('guided-status')),
        find.byKey(const Key('guided-bar-count')),
        find.byTooltip('Back'),
      ]) {
        expect(f, findsOneWidget);
        expect(stage.contains(t.getCenter(f)), isTrue);
      }
      expect(t.getRect(find.byTooltip('Back')).right,
          lessThanOrEqualTo(t.getRect(find.text(_kit.name)).left));
      expect(t.takeException(), isNull);
    });

    testWidgets('sheet spans the window width minus gutter at 2560', (t) async {
      final p = FakeGuidedPlayer();
      await _open(t, p, size: const Size(2560, 1440), desktop: true);
      await _emit(t, p, _pos(firstGroove(_kit), 0, tick: 30));
      const min = 2560 - 2 * AppSpacing.screenPadding - 1;
      expect(t.getSize(find.byKey(const Key('guided-sheet'))).width,
          greaterThanOrEqualTo(min));
      for (final key in ['guided-now', 'guided-next']) {
        final r = staffRect(t, key);
        expect(r.width, greaterThanOrEqualTo(min), reason: key);
        expect(r.left, closeTo(AppSpacing.screenPadding, 0.5), reason: key);
      }
    });

    testWidgets('now and next pages show 4 bars each when wide', (t) async {
      final p = FakeGuidedPlayer();
      await _open(t, p, size: const Size(1280, 720), desktop: true);
      final g = firstGroove(_kit);
      await _emit(t, p, _pos(g, 1, tick: 30));
      expect(_nowView(t).page.bars, 4);
      expect(_nowView(t).fullPageBars, 4);
      expect(_nowView(t).page.firstBar, 0);
      expect(_nextView(t).page.bars, 4);
      expect(_nextView(t).fullPageBars, 4);
      // Written out, no repeat sign.
      expect(_nowView(t).page.line.repeat, isFalse);
      expect(_text(t, 'guided-label-now'), 'Now · Groove');
      expect(_text(t, 'guided-label-next'), 'Next · Groove');
    });

    testWidgets('sheet labels name the section of each page', (t) async {
      final p = FakeGuidedPlayer();
      await _open(t, p, size: const Size(1280, 720), desktop: true);
      final v2 = _varIndex(_kit, 2);
      final title = _kit.sections[v2].titleEn!;
      final lastPage = (_planBars(_kit, v2 - 1) - 1) ~/ 4 * 4;
      await _emit(t, p, _pos(v2 - 1, lastPage));
      expect(_text(t, 'guided-label-now'), 'Now · Groove');
      expect(_text(t, 'guided-label-next'), 'Next · Variation 2 · $title');
      expect(_nextView(t).page.sectionIndex, v2);
      await _emit(t, p, _pos(v2, 0, tick: 10));
      expect(_text(t, 'guided-label-now'), 'Now · Variation 2 · $title');
      final outro = _kit.sections.length - 1;
      await _emit(t, p, _pos(outro, 0));
      expect(_text(t, 'guided-label-now'), 'Now · Ending');
      expect(find.byKey(const Key('guided-label-next')), findsNothing);
      expect(find.byKey(const Key('guided-next')), findsNothing);
      expect(t.takeException(), isNull);
    });

    testWidgets('page turns when bar 5 of a section starts', (t) async {
      final p = FakeGuidedPlayer();
      await _open(t, p, size: const Size(1920, 1080), desktop: true);
      final g = _varIndex(_kit, 1) - 1;
      expect(_planBars(_kit, g), greaterThanOrEqualTo(8));
      await _emit(t, p, _pos(g, 3, tick: 72));
      expect(_nowView(t).page.firstBar, 0);
      expect(_nowView(t).activeTick, 3 * 96 + 72);
      expect(_nextView(t).page.sectionIndex, g);
      expect(_nextView(t).page.firstBar, 4);
      final nowTop = t.getRect(find.byKey(const Key('guided-now'))).top;
      await _emit(t, p, _pos(g, 4));
      expect(_nowView(t).page.firstBar, 4);
      expect(_nowView(t).activeTick, 0);
      // No scrolling: the upper row stays where it was.
      expect(t.getRect(find.byKey(const Key('guided-now'))).top, nowTop);
    });

    testWidgets('tempo change keeps the page and tick', (t) async {
      final p = FakeGuidedPlayer();
      await _open(t, p, size: const Size(1280, 720), desktop: true);
      final g = _varIndex(_kit, 1) - 1;
      await _emit(t, p, _pos(g, 5, tick: 30));
      final page = _nowView(t).page;
      final tick = _nowView(t).activeTick;
      final next = _nextView(t).page;
      await _key(t, LogicalKeyboardKey.arrowUp);
      expect(p.setBpmCalls, isNotEmpty);
      expect(_nowView(t).page, page);
      expect(_nowView(t).activeTick, tick);
      expect(_nextView(t).page, next);
    });

    testWidgets('count-in shows the first groove page without playhead',
        (t) async {
      final p = FakeGuidedPlayer();
      await _open(t, p, size: const Size(1920, 1080), desktop: true);
      await _emit(t, p, _pos(-1, 0, tick: 48, bar: 0));
      final now = _nowView(t);
      expect(now.page.sectionIndex, firstGroove(_kit));
      expect(now.page.firstBar, 0);
      expect(now.activeTick, isNull);
      expect(
          staffCalls(t, find.byKey(const Key('guided-now')))
              .playheadsIn(guidedPlayheadBlue),
          isEmpty);
      expect(_text(t, 'guided-label-now'), 'Count-in');
      expect(find.byKey(const Key('guided-bar-count')), findsNothing);
    });

    testWidgets('paused keeps the page and freezes the playhead', (t) async {
      final p = FakeGuidedPlayer();
      await _open(t, p, size: const Size(1920, 1080), desktop: true);
      final g = firstGroove(_kit);
      await _emit(t, p, _pos(g, 2, tick: 40));
      double head() => staffCalls(t, find.byKey(const Key('guided-now')))
          .playheadsIn(guidedPlayheadBlue)
          .single
          .x;
      final page = _nowView(t).page;
      final x = head();
      await t.tap(find.byKey(const Key('guided-play-toggle')));
      await t.pump();
      expect(p.calls.last, 'pause');
      await t.pump(const Duration(seconds: 2));
      expect(_nowView(t).page, page);
      expect(_nowView(t).activeTick, 2 * 96 + 40);
      expect(head(), x);
    });

    testWidgets('resize from wide to narrow while playing shows 2-bar pages',
        (t) async {
      final p = FakeGuidedPlayer();
      await _open(t, p, size: const Size(1280, 720), desktop: true);
      final g = _varIndex(_kit, 1) - 1;
      await _emit(t, p, _pos(g, 5, tick: 30));
      expect(_nowView(t).page.bars, 4);
      expect(_nowView(t).page.firstBar, 4);
      await t.binding.setSurfaceSize(const Size(412, 915));
      await t.pumpAndSettle();
      expect(t.takeException(), isNull);
      expect(find.byKey(const Key('guided-wide')), findsNothing);
      expect(_nowView(t).page.bars, 2);
      expect(_nowView(t).fullPageBars, 2);
      expect(_nowView(t).page.firstBar, 4);
      expect(_nowView(t).activeTick, 96 + 30);
      expect(_nextView(t).page.firstBar, 6);
      expect(_nextView(t).dimmed, isTrue);
      expect(p.calls, ['start']);
      // And back.
      await t.binding.setSurfaceSize(const Size(1280, 720));
      await t.pumpAndSettle();
      expect(_nowView(t).page.bars, 4);
      expect(_nowView(t).activeTick, 96 + 30);
    });

    testWidgets('coming up shows the variation title', (t) async {
      final p = FakeGuidedPlayer();
      await _open(t, p, size: const Size(1920, 1080), desktop: true);
      final v1 = _varIndex(_kit, 1);
      await _emit(t, p, _pos(v1 - 1, 0));
      expect(_text(t, 'guided-coming-up'),
          'Coming up: ${_kit.sections[v1].titleEn}');
      final stage = t.getRect(find.byKey(const Key('guided-stage')));
      final c = t.getRect(find.byKey(const Key('guided-coming-up')));
      expect(stage.contains(c.center), isTrue);
      expect(c.center.dx, greaterThan(1920 / 2), reason: 'top right');
      expect(
          c.top,
          greaterThan(
              t.getRect(find.byKey(const Key('guided-bar-count'))).top));
      await _emit(t, p, _pos(v1, 0));
      expect(find.byKey(const Key('guided-coming-up')), findsNothing);
    });

    testWidgets(
        'bar count shows bar in section and section length from the '
        'plan', (t) async {
      final p = FakeGuidedPlayer();
      await _open(t, p, size: const Size(1920, 1080), desktop: true);
      final g = _varIndex(_kit, 1) - 1;
      await _emit(t, p, _pos(g, 2));
      expect(_text(t, 'guided-bar-count'), 'Bar 3 / ${_planBars(_kit, g)}');
      final v1 = g + 1;
      await _emit(t, p, _pos(v1, 0));
      expect(_text(t, 'guided-bar-count'), 'Bar 1 / ${_planBars(_kit, v1)}');
      final r = t.getRect(find.byKey(const Key('guided-bar-count')));
      expect(r.right, greaterThan(1920 - 200), reason: 'top right');
      expect(r.top, lessThan(200));
    });

    testWidgets('banner on the stage has no note line', (t) async {
      final p = FakeGuidedPlayer();
      await _open(t, p, size: const Size(1920, 1080), desktop: true);
      final v1 = _varIndex(_kit, 1);
      await _emit(t, p, _pos(v1 - 1, 0));
      final banner = find.byKey(const Key('guided-banner'));
      expect(t.widget<GuidedBanner>(banner).showLine, isFalse);
      expect(find.descendant(of: banner, matching: find.byType(GuidedLineView)),
          findsNothing);
      expect(
          find.descendant(
              of: banner, matching: find.text(_kit.sections[v1].textEn!)),
          findsOneWidget);
      final stage = t.getRect(find.byKey(const Key('guided-stage')));
      expect(stage.contains(t.getRect(banner).center), isTrue);
    });

    testWidgets('photo is not covered by the sheet', (t) async {
      for (final size in [
        const Size(1920, 1080),
        const Size(1366, 768),
        const Size(2560, 1440),
      ]) {
        final p = FakeGuidedPlayer();
        await _open(t, p, size: size, desktop: true);
        await _emit(t, p, _pos(_varIndex(_kit, 1) - 1, 0));
        final stage = t.getRect(find.byKey(const Key('guided-stage')));
        final sheet = t.getRect(find.byKey(const Key('guided-sheet')));
        final controls = t.getRect(find.byKey(const Key('guided-controls')));
        expect(stage.overlaps(sheet), isFalse, reason: '$size');
        expect(stage.overlaps(controls), isFalse, reason: '$size');
        // The 4:3 photo at full stage height.
        final photo = t.getRect(find.byKey(const ValueKey('stage-photo')));
        expect(photo.height, closeTo(stage.height, 0.5), reason: '$size');
        expect(photo.width, closeTo(stage.height * 4 / 3, 0.5),
            reason: '$size');
        expect(photo.overlaps(sheet), isFalse, reason: '$size');
      }
    });

    testWidgets('phone: stage strip on top, two 2-bar pages under it',
        (t) async {
      final p = FakeGuidedPlayer();
      await _open(t, p);
      await _emit(t, p, _pos(firstGroove(_kit), 1, tick: 30));
      final stage = t.getRect(find.byKey(const Key('guided-stage')));
      expect(stage.top, 0);
      expect(stage.height, closeTo(0.3 * 915, 1));
      expect(stage.contains(t.getCenter(find.text(_kit.name))), isTrue);
      final now = t.getRect(find.byKey(const Key('guided-now')));
      expect(now.top, greaterThanOrEqualTo(stage.bottom));
      expect(_nowView(t).page.bars, 2);
      expect(_nextView(t).page.bars, 2);
      expect(t.takeException(), isNull);
    });
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
      await shot(t, const Size(1920, 1080), true, positions: [
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
      // A laptop window (anti-goal: notes too small at 1366x768).
      await shot(t, const Size(1366, 768), true, positions: [
        _pos(v2, 2, tick: 40, bar: 33),
      ]);
      expect(t.takeException(), isNull);
      await expectLater(find.byKey(const Key('shot')),
          matchesGoldenFile('../../goldens/guided_play_desktop_variation.png'));
    });

    testWidgets('golden: 2560x1440 mid-variation with playhead', (t) async {
      final v2 = _varIndex(_kit, 2);
      await shot(t, const Size(2560, 1440), true, positions: [
        _pos(v2, 2, tick: 40, bar: 33),
      ]);
      expect(t.takeException(), isNull);
      await expectLater(find.byKey(const Key('shot')),
          matchesGoldenFile('../../goldens/guided_play_desktop_2560.png'));
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
