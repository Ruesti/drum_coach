/// Estimates when playback really started from (wall clock, play position)
/// samples taken shortly after `play()`.
///
/// The backend's play position advances in whole audio buffers and lags
/// behind the wall clock, so every sample satisfies
/// `nowMs − positionMs ≥ true start`. The minimum over all samples is the
/// best estimate: the sample taken just after a buffer step lies closest to
/// the true start (same idea as `MidiTimestampMapper`). Returns null for no
/// samples.
double? estimateStartMs(List<({double nowMs, double positionMs})> samples) {
  double? best;
  for (final s in samples) {
    final v = s.nowMs - s.positionMs;
    if (best == null || v < best) best = v;
  }
  return best;
}
