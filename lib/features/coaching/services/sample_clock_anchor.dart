/// Wall-clock anchor of an audio stream's sample 0 (§1.3).
///
/// Every chunk yields a candidate anchor: its arrival time minus the duration
/// of all samples delivered up to and including it. Delivery delay only ever
/// pushes candidates *later*, so the minimum over all chunks is the best
/// estimate of the true start — anchoring on the first chunk alone inherits
/// that one chunk's delivery jitter and shifts the whole run between
/// calibration passes.
class SampleClockAnchor {
  SampleClockAnchor({required this.sampleRate});

  final int sampleRate;

  int _samplesDelivered = 0;
  DateTime? _anchor;

  DateTime? get anchor => _anchor;

  void addChunk({required DateTime arrivedAt, required int samples}) {
    _samplesDelivered += samples;
    final candidate = arrivedAt.subtract(
        Duration(microseconds: _samplesDelivered * 1000000 ~/ sampleRate));
    if (_anchor == null || candidate.isBefore(_anchor!)) {
      _anchor = candidate;
    }
  }
}
