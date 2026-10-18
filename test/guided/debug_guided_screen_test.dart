import 'dart:async';

import 'package:drum_coach/app/platform_support.dart';
import 'package:drum_coach/features/guided/data/demo_exercise.dart';
import 'package:drum_coach/features/guided/debug_guided_screen.dart';
import 'package:drum_coach/features/guided/guided_player.dart';
import 'package:drum_coach/features/guided/guided_rig_provider.dart';
import 'package:drum_coach/features/guided/models/guided_exercise.dart';
import 'package:drum_coach/features/guided/models/voice_clip.dart';
import 'package:drum_coach/features/guided/run_clock.dart';
import 'package:drum_coach/features/guided/run_plan.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Records the calls the page makes; everything else is unused.
class FakeGuidedPlayer implements GuidedPlayer {
  final positionCtrl = StreamController<RunPosition>.broadcast();
  final errorCtrl = StreamController<Object>.broadcast();
  final finishedCtrl = StreamController<void>.broadcast();
  final stateCtrl = StreamController<void>.broadcast();
  bool frozen = false;

  /// When set, start() waits for it.
  Completer<void>? startGate;
  final setBpmCalls = <int>[];
  final optionCalls = <RunOptions>[];
  final calls = <String>[];
  GuidedExercise? started;
  int? startedBpm;
  int _bpm = 100;

  @override
  Stream<RunPosition> get positions => positionCtrl.stream;
  @override
  Stream<Object> get errors => errorCtrl.stream;
  @override
  Stream<void> get finished => finishedCtrl.stream;
  @override
  Stream<void> get stateChanges => stateCtrl.stream;
  @override
  bool get isFrozen => frozen;
  @override
  int get bpm => _bpm;

  @override
  Future<void> start(GuidedExercise ex,
      {required int bpm, required RunOptions options}) async {
    started = ex;
    startedBpm = bpm;
    _bpm = bpm;
    calls.add('start');
    await startGate?.future;
  }

  @override
  void setBpm(int bpm) {
    setBpmCalls.add(bpm);
    _bpm = bpm;
  }

  @override
  void setOptions(RunOptions options) => optionCalls.add(options);
  @override
  void pause() => calls.add('pause');
  @override
  void resume() {
    frozen = false;
    calls.add('resume');
  }

  @override
  Future<void> stop() async => calls.add('stop');
  @override
  Future<void> dispose() async => calls.add('dispose');

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

ClipManifest _clips() => ClipManifest.fromJson({
      'clips': [
        for (final id in [
          ...countInClipIds,
          ...countdownClipIds,
          'after_good',
          'after_last',
          'demo_kit_v1',
          'demo_kit_v2',
          'demo_kit_v3',
          'demo_pad_v1',
          'demo_pad_v2',
          'demo_pad_v3',
        ])
          {'id': id, 'ms': id.startsWith('demo') ? 3500 : 400},
      ]
    });

Widget _app(FakeGuidedPlayer p) => ProviderScope(
      overrides: [
        guidedRigProvider
            .overrideWith((ref) async => GuidedRig(player: p, clips: _clips())),
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
    await tester.tap(find.text('Pad demo'));
    await tester.pump();
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
