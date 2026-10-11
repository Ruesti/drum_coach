import 'dart:async';

import 'mic_analysis_service.dart';
import 'stroke_source.dart';

/// The microphone as a [StrokeSource]: wraps the Etappe-1 recording chain
/// unchanged (thresholds, sample clock, latency loopback stay inside
/// [MicAnalysisService]).
class MicStrokeSource implements StrokeSource {
  MicStrokeSource({MicAnalysisService? service})
      : service = service ?? MicAnalysisService();

  final MicAnalysisService service;
  final _statusCtrl = StreamController<StrokeSourceStatus>.broadcast();
  StrokeSourceStatus _status = StrokeSourceStatus.ready;

  @override
  StrokeSourceKind get kind => StrokeSourceKind.mic;
  @override
  bool get velocityExact => false;
  @override
  StrokeSourceStatus get status => _status;
  @override
  Stream<StrokeSourceStatus> get statusChanges => _statusCtrl.stream;
  @override
  String? get deviceName => null;
  @override
  List<StrokeEvent> get events => service.strokeEvents;

  @override
  Future<void> start() async {
    try {
      await service.startRecording();
      _status = StrokeSourceStatus.ready;
    } catch (_) {
      _status = StrokeSourceStatus.notMeasurable;
      _statusCtrl.add(_status);
      rethrow;
    }
  }

  @override
  Future<void> stop() => service.stopRecording();

  @override
  Map<String, Object>? describeSetup() => service.setup?.describe();

  @override
  void dispose() {
    _statusCtrl.close();
    service.dispose();
  }
}
