import 'dart:async';

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
  static const int clickCount = 8;
  static const Duration clickInterval = Duration(milliseconds: 500);

  /// Plays [clickCount] clicks and returns the measured offset, or null if
  /// fewer than half the clicks were found in the recording (too noisy, mic
  /// blocked, volume down).
  static Future<LatencyEstimate?> runOnce() async {
    final mic = MicAnalysisService();
    AudioSource? click;
    try {
      if (!await mic.hasPermission) return null;
      if (!SoLoud.instance.isInitialized) return null;
      click = await SoLoud.instance
          .loadMem('calibration_click', MetronomeEngine.calibrationClickWav());

      await mic.startRecording();
      // Let the detector's median baseline warm up before the first click.
      await Future<void>.delayed(const Duration(milliseconds: 400));

      final plannedMs = <double>[];
      for (var i = 0; i < clickCount; i++) {
        plannedMs.add(DateTime.now().microsecondsSinceEpoch / 1000.0);
        await SoLoud.instance.play(click, volume: 1.0);
        await Future<void>.delayed(clickInterval);
      }
      await Future<void>.delayed(const Duration(milliseconds: 300));
      await mic.stopRecording();

      final anchor = mic.sampleClockAnchor;
      if (anchor == null) return null;
      final anchorMs = anchor.microsecondsSinceEpoch / 1000.0;
      final estimate = estimateLatencyOffset(
        plannedClickMs: plannedMs,
        onsetMs: [for (final h in mic.detectedOnsets) anchorMs + h.timeMs],
      );
      if (estimate == null || estimate.matchedClicks < clickCount ~/ 2) {
        return null;
      }
      return estimate;
    } finally {
      if (click != null) {
        SoLoud.instance.disposeSource(click).ignore();
      }
      mic.dispose();
    }
  }
}
