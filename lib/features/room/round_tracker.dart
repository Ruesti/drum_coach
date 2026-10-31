/// Round boundaries from the metronome's beat stream (Trainingsraum): a
/// round is one pass through the played unit, [beatsPerRound] ticks long.
/// Pure — the practice screen feeds it every beat index it receives.
class RoundTracker {
  RoundTracker({required this.beatsPerRound})
      : assert(beatsPerRound > 0, 'a round needs ticks');

  final int beatsPerRound;

  int? _round;
  bool _counts = true;

  /// Round the last beat fell into (null before the first beat).
  int? get currentRound => _round;

  /// Feeds one beat. Returns the number of the round that just ended when
  /// [beatIndex] crosses into a later round — unless that round was
  /// dropped by [reset]. Silent ticks emit no beat, so indices may jump.
  /// A backwards jump (playback restarted) starts afresh.
  int? onBeat(int beatIndex) {
    final r = beatIndex ~/ beatsPerRound;
    final prev = _round;
    _round = r;
    if (prev == null || r == prev) return null;
    if (r < prev) {
      _counts = true;
      return null;
    }
    final ended = _counts ? prev : null;
    _counts = true;
    return ended;
  }

  /// The round in progress does not count (tempo changed by hand, the unit
  /// was rebuilt); the next one counts again.
  void reset() => _counts = false;
}
