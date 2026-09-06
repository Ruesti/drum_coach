/// Piecewise mapping from a recording's sample clock to the wall clock
/// (§1.3).
///
/// A single global anchor assumes samples ÷ rate equals elapsed real time.
/// The device test disproved that: within one ~12 s recording the apparent
/// offset drifted 15–25 ms — lost samples or resampler skew accumulate, and
/// over a minutes-long practice session that would silently corrupt every
/// timing value. Anchoring each onset to the arrival time of its own chunk
/// neighborhood caps the error at per-chunk delivery jitter, which cannot
/// accumulate.
///
/// Per chunk k the candidate anchor is `arrival_k − cumSamples_k/rate` (the
/// wall-clock instant of sample 0 as seen from chunk k). Delivery delay only
/// pushes candidates later, so the minimum over a local window around the
/// onset's chunk gives a jitter-robust local anchor.
class SampleClockMap {
  SampleClockMap({required this.sampleRate, this.window = 6});

  final int sampleRate;

  /// Chunks on each side of an onset's chunk considered for the local
  /// minimum.
  final int window;

  final List<int> _cumEndSamples = [];
  final List<int> _candidateUs = [];

  void addChunk({required DateTime arrivedAt, required int samples}) {
    final cum = (_cumEndSamples.isEmpty ? 0 : _cumEndSamples.last) + samples;
    _cumEndSamples.add(cum);
    _candidateUs.add(arrivedAt.microsecondsSinceEpoch -
        (cum * 1000000 ~/ sampleRate));
  }

  /// Wall-clock time of the sample at [timeMs] on the sample clock, or null
  /// before any chunk arrived.
  DateTime? timeAt(double timeMs) {
    if (_cumEndSamples.isEmpty) return null;
    final sampleIdx = (timeMs / 1000.0 * sampleRate).round();
    var i = _cumEndSamples.length - 1;
    for (var k = 0; k < _cumEndSamples.length; k++) {
      if (_cumEndSamples[k] > sampleIdx) {
        i = k;
        break;
      }
    }
    // Forward-only window: candidates of *earlier* chunks predate any sample
    // gap between them and the onset and would anchor too early; candidates
    // from the onset's chunk onward all include the gaps before it, and a
    // gap between onset and a later chunk only pushes that candidate later —
    // which the minimum discards.
    final to = (i + window).clamp(0, _candidateUs.length - 1);
    var anchorUs = _candidateUs[i];
    for (var k = i + 1; k <= to; k++) {
      if (_candidateUs[k] < anchorUs) anchorUs = _candidateUs[k];
    }
    return DateTime.fromMicrosecondsSinceEpoch(
        anchorUs + (timeMs * 1000).round());
  }

  /// How far the sample clock fell behind the wall clock across the stream
  /// (positive = samples lost / clock skew). Diagnostic for the §1.3 report.
  double? get driftMs {
    if (_candidateUs.length < 2) return null;
    return (_candidateUs.last - _candidateUs.first) / 1000.0;
  }
}
