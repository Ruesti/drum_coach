import 'dart:async';

import 'package:drum_coach/app/platform_support.dart';
import 'package:drum_coach/features/guided/data/demo_exercise.dart';
import 'package:drum_coach/features/guided/data/guided_catalog.dart';
import 'package:drum_coach/features/guided/debug_guided_screen.dart';
import 'package:drum_coach/features/guided/guided_rig_provider.dart';
import 'package:drum_coach/features/guided/models/guided_exercise.dart';
import 'package:drum_coach/features/guided/run_clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_guided_player.dart';

Widget _app(FakeGuidedPlayer p) => ProviderScope(
      overrides: [
        guidedRigProvider.overrideWith(
            (ref) async => GuidedRig(player: p, clips: fakeClipManifest())),
      ],
      child: const MaterialApp(home: DebugGuidedScreen()),
    );

RunPosition _pos(int section, int barInSection, int beat) => RunPosition(
      bar: 20,
      sectionIndex: section,
      barInSection: barInSection,
      beat: beat,
      tick: (beat - 1) * 24,
      bpm: 100,
      plannedAt: DateTime(2026),
    );

/// Opens the exercise dropdown and picks [ex].
Future<void> _pick(WidgetTester tester, GuidedExercise ex) async {
  await tester.tap(find.byKey(const ValueKey('guided-exercise')));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(ValueKey('guided-exercise-${ex.id}')).last);
  await tester.pumpAndSettle();
}

void main() {
  setUp(() => debugDesktopOverride = false);
  tearDown(() => debugDesktopOverride = null);

  testWidgets('switches toggle RunOptions on the player', (tester) async {
    final p = FakeGuidedPlayer();
    await tester.pumpWidget(_app(p));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('guided-teacher')));
    await tester.pump();
    expect(p.optionCalls.last.teacher, isFalse);
    expect(p.optionCalls.last.playAlong, isTrue);
    await tester.tap(find.byKey(const ValueKey('guided-playalong')));
    await tester.pump();
    expect(p.optionCalls.last.teacher, isFalse);
    expect(p.optionCalls.last.playAlong, isFalse);
  });

  testWidgets('BPM buttons call setBpm(currentBpm ± 4)', (tester) async {
    final p = FakeGuidedPlayer();
    await tester.pumpWidget(_app(p));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('guided-bpm-up')));
    await tester.pump();
    expect(p.setBpmCalls, [demoKitExercise.defaultBpm + 4]);
    expect(find.text('${demoKitExercise.defaultBpm + 4}'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('guided-bpm-down')));
    await tester.pump();
    expect(p.setBpmCalls.last, demoKitExercise.defaultBpm);
  });

  testWidgets('Start plays the chosen demo; Pause and Stop reach the player',
      (tester) async {
    final p = FakeGuidedPlayer();
    await tester.pumpWidget(_app(p));
    await tester.pumpAndSettle();
    await _pick(tester, demoPadExercise);
    await tester.tap(find.byKey(const ValueKey('guided-start')));
    await tester.pump();
    expect(p.started?.id, demoPadExercise.id);
    expect(p.startedBpm, demoPadExercise.defaultBpm);
    await tester.tap(find.byKey(const ValueKey('guided-start')));
    await tester.pump();
    expect(p.calls, contains('pause'));
    await tester.tap(find.byKey(const ValueKey('guided-stop')));
    await tester.pump();
    expect(p.calls.last, 'stop');
  });

  testWidgets('exercise dropdown lists demos and catalog', (tester) async {
    final p = FakeGuidedPlayer();
    await tester.pumpWidget(_app(p));
    await tester.pumpAndSettle();
    expect(find.text('Exercise'), findsOneWidget);
    final dd = tester.widget<DropdownButton<GuidedExercise>>(
        find.byKey(const ValueKey('guided-exercise')));
    final listed = [
      for (final i in dd.items!)
        if (i.value != null) i.value!
    ];
    // Demos first, then the catalog with Set entries before Pad entries.
    expect(listed, [
      demoKitExercise,
      demoPadExercise,
      ...guidedCatalog.where((e) => e.package == GuidedPackage.kit),
      ...guidedCatalog.where((e) => e.package == GuidedPackage.pad),
    ]);
    expect(listed, hasLength(2 + guidedCatalog.length));

    // Label: name · difficulty · ~m:ss at the default tempo.
    final kit = guidedCatalog.firstWhere((e) => e.package == GuidedPackage.kit);
    final sec = (kit.barsAt(kit.defaultBpm) * 240 / kit.defaultBpm).round();
    final mmss = '${sec ~/ 60}:${(sec % 60).toString().padLeft(2, '0')}';
    await _pick(tester, kit);
    expect(find.text('${kit.name} · ${kit.difficulty.label} · ~$mmss'),
        findsWidgets);
    expect(find.text(kit.description), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('guided-start')));
    await tester.pump();
    expect(identical(p.started, kit), isTrue);
    expect(p.startedBpm, kit.defaultBpm);

    // Locked while running.
    expect(
        tester
            .widget<DropdownButton<GuidedExercise>>(
                find.byKey(const ValueKey('guided-exercise')))
            .onChanged,
        isNull);
  });

  testWidgets('status line, variation text and errors follow the player',
      (tester) async {
    final p = FakeGuidedPlayer();
    await tester.pumpWidget(_app(p));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('guided-start')));
    await tester.pump();
    p.positionCtrl.add(_pos(2, 4, 2));
    await tester.pump();
    expect(find.text('Section 3 of 9 · Variation 1 · bar 5 · beat 2'),
        findsOneWidget);
    expect(find.text(demoKitExercise.sections[2].textEn!), findsOneWidget);
    expect(find.text('NOW'), findsOneWidget);

    // In the groove before V2 the coming variation's text is shown.
    p.positionCtrl.add(_pos(3, 0, 1));
    await tester.pump();
    expect(
        find.text('Section 4 of 9 · Groove · bar 1 · beat 1'), findsOneWidget);
    expect(find.text(demoKitExercise.sections[4].textEn!), findsOneWidget);
    expect(find.text('COMING UP'), findsOneWidget);

    p.errorCtrl.add(StateError('boom'));
    await tester.pump();
    expect(find.textContaining('boom'), findsOneWidget);
  });

  testWidgets('desktop keys: Space starts, + raises the tempo, Esc stops',
      (tester) async {
    debugDesktopOverride = true;
    final p = FakeGuidedPlayer();
    await tester.pumpWidget(_app(p));
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.pump();
    expect(p.calls, contains('start'));
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.pump();
    expect(p.setBpmCalls.last, demoKitExercise.defaultBpm + 4);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pump();
    expect(p.calls.last, 'stop');
  });

  testWidgets('a frozen run shows Resume and resumes the player',
      (tester) async {
    final p = FakeGuidedPlayer();
    await tester.pumpWidget(_app(p));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('guided-start')));
    await tester.pump();
    expect(find.text('Pause'), findsOneWidget);
    p.frozen = true;
    p.stateCtrl.add(null);
    await tester.pump();
    expect(find.text('Resume'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('guided-start')));
    await tester.pump();
    expect(p.calls.last, 'resume');
    expect(p.calls, isNot(contains('pause')));
    expect(find.text('Pause'), findsOneWidget);
  });

  testWidgets('an error resets the page to stopped', (tester) async {
    final p = FakeGuidedPlayer();
    await tester.pumpWidget(_app(p));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('guided-start')));
    await tester.pump();
    expect(find.text('Pause'), findsOneWidget);
    p.errorCtrl.add(StateError('stream refused'));
    await tester.pump();
    expect(find.text('Start'), findsOneWidget);
    expect(find.textContaining('stream refused'), findsOneWidget);
    expect(p.calls.last, 'stop');
    // Start works again.
    await tester.tap(find.byKey(const ValueKey('guided-start')));
    await tester.pump();
    expect(p.calls.where((c) => c == 'start'), hasLength(2));
  });

  testWidgets('taps while start() is in flight are ignored', (tester) async {
    final p = FakeGuidedPlayer()..startGate = Completer<void>();
    await tester.pumpWidget(_app(p));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('guided-start')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('guided-start')));
    await tester.pump();
    expect(p.calls, ['start']);
    p.startGate!.complete();
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('guided-start')));
    await tester.pump();
    expect(p.calls, ['start', 'pause']);
  });
}
