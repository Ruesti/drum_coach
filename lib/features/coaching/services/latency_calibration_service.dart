import 'dart:async';
import 'dart:math' as math;

import 'package:flutter_soloud/flutter_soloud.dart';

import '../../metronome/metronome_engine.dart';
import 'latency_estimator.dart';
import 'mic_analysis_service.dart';

/// One loopback calibration run (§1.3): plays clicks on the speaker while
/// recording through the same raw path as a practice session, then measures
/// the shift between planned and recorded clicks. That shift is the sum of
/// output latency and input latency — exactly what must be subtracted when
/// onsets are compared against planned click times.
class LatencyCalibrationService {
  /// 24 measured clicks = three 8-click blocks for the within-recording
  /// spread readout.
  static const int clickCount = 24;

  /// Plays [clickCount] clicks and returns the measured offset, or null if
  /// fewer than half the clicks were found in the recording (too noisy, mic
  /// blocked, volume down).
  ///
  /// A full record+play cycle is run and discarded first: the device test
  /// showed consecutive runs drifting 68.5 → 53.9 → 49.8 ms — the first
  /// cycle after idle measures a colder, slower audio pipeline, while later
  /// runs sat within 5 ms of each other. Warming up with a discarded cycle
  /// makes already the first reported value a steady-state measurement.
  ///
  /// Click spacing is dithered (390–620 ms): the output side quantizes each
  /// click onto the next audio-buffer boundary, and a fixed interval would
  /// sample similar buffer phases every time — the run median then wobbles
  /// several ms between runs. Dithered spacing spreads the phases so the
  /// median converges.
  static Future<LatencyEstimate?> runOnce() async {
    if (!SoLoud.instance.isInitialized) return null;
    if (!await MicAnalysisService().hasPermission) return null;

    final click = await SoLoud.instance
        .loadMem('calibration_click', MetronomeEngine.calibrationClickWav());
    try {
      await _cycle(click, clicks: 4, settleMs: 250);
      return await _cycle(click, clicks: clickCount, settleMs: 300);
    } finally {
      SoLoud.instance.disposeSource(click).ignore();
    }
  }

  static Future<LatencyEstimate?> _cycle(
    AudioSource click, {
    required int clicks,
    required int settleMs,
  }) async {
    final mic = MicAnalysisService();
    try {
      await mic.startRecording();
      // Let the detector's median baseline warm up before the first click.
      await Future<void>.delayed(const Duration(milliseconds: 400));

      final rng = math.Random(7);
      final plannedMs = <double>[];
      for (var i = 0; i < clicks; i++) {
        plannedMs.add(DateTime.now().microsecondsSinceEpoch / 1000.0);
        await SoLoud.instance.play(click, volume: 1.0);
        await Future<void>.delayed(
            Duration(milliseconds: 390 + rng.nextInt(230)));
      }
      await Future<void>.delayed(Duration(milliseconds: settleMs));
      await mic.stopRecording();

      assert(() {
        // §1.3 diagnostic: sample-clock vs wall-clock drift of this cycle.
        // ignore: avoid_print
        print('calibration cycle drift: ${mic.clockDriftMs?.toStringAsFixed(1)} ms');
        return true;
      }());
      final estimate = estimateLatencyOffset(
        plannedClickMs: plannedMs,
        onsetMs: mic.absoluteOnsetMs,
      );
      if (estimate == null || estimate.matchedClicks < clicks ~/ 2) {
        return null;
      }
      return estimate;
    } finally {
      mic.dispose();
    }
  }
}
