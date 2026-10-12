import '../services/latency_estimator.dart';

/// Result of "play along to the click" (Brief A.4): the systematic
/// offset between MIDI stroke and planned click, and the spread between
/// four blocks of the run. When [unsure] is true the screen asks
/// for a repeat instead of saving.
class MidiLatencyResult {
  final double offsetMs;
  final double spreadMs;
  final int matched;
  final int clicks;
  final double unsureAboveMs;

  const MidiLatencyResult({
    required this.offsetMs,
    required this.spreadMs,
    required this.matched,
    required this.clicks,
    required this.unsureAboveMs,
  });

  bool get unsure => spreadMs > unsureAboveMs || matched < clicks * 0.75;
}

MidiLatencyResult? estimateMidiLatency({
  required List<double> clickMs,
  required List<double> strokeMs,
  double unsureAboveMs = 10,
}) {
  final est =
      estimateLatencyOffset(plannedClickMs: clickMs, onsetMs: strokeMs);
  if (est == null) return null;
  return MidiLatencyResult(
    offsetMs: est.offsetMs,
    spreadMs: est.blockSpreadMs(4) ?? 0,
    matched: est.matchedClicks,
    clicks: est.totalClicks,
    unsureAboveMs: unsureAboveMs,
  );
}
