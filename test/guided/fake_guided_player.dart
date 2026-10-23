import 'dart:async';

import 'package:drum_coach/features/guided/guided_player.dart';
import 'package:drum_coach/features/guided/data/guided_catalog.dart';
import 'package:drum_coach/features/guided/models/guided_exercise.dart';
import 'package:drum_coach/features/guided/models/voice_clip.dart';
import 'package:drum_coach/features/guided/run_clock.dart';
import 'package:drum_coach/features/guided/run_plan.dart';

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
  RunOptions? startedOptions;
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
    startedOptions = options;
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

/// Every clip the demos and the catalog use: explanations 3.5 s, the rest
/// 0.4 s.
ClipManifest fakeClipManifest() => ClipManifest.fromJson({
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
          for (final ex in guidedCatalog)
            for (final s in ex.sections)
              if (s.speechClipId != null) s.speechClipId!,
        ])
          {'id': id, 'ms': id.startsWith(RegExp('demo|g_')) ? 3500 : 400},
      ]
    });
