/// Backing-loop styles (Engine part 1): one 4/4 bar of kick and hi-hat on
/// the 24-ticks-per-quarter grid. Pure data, no Flutter. The player's pad
/// voice is the "snare" — the band deliberately has none.
///
/// Tick cheat sheet (24 per quarter): beat 1 = 0, "e" = 6, "&" = 12,
/// "a" = 18, beat 2 = 24 … beat 4 = 72; third triplet of a beat = +16.
library;

enum BackingFeel { straight, shuffle, swing }

class BackingHit {
  /// 0..95 inside one 4/4 bar.
  final int tick;

  /// 0 < level ≤ 1. Hi-hat hits ≥ 0.9 use the accent ("slightly open") sound.
  final double level;
  const BackingHit(this.tick, this.level);
}

class BackingStyle {
  /// Stable id — stored in settings and exercise data.
  final String id;
  final String label;
  final BackingFeel feel;
  final List<BackingHit> kick;
  final List<BackingHit> hihat;
  const BackingStyle({
    required this.id,
    required this.label,
    required this.feel,
    required this.kick,
    required this.hihat,
  });
}

/// Ticks in one 4/4 bar at 24 ticks per quarter.
const int backingBarTicks = 96;

List<BackingHit> _eighths({double quarter = 1.0, double and = 0.7}) => [
      for (var q = 0; q < 4; q++) ...[
        BackingHit(q * 24, quarter),
        BackingHit(q * 24 + 12, and),
      ],
    ];

List<BackingHit> _sixteenths(
        {double quarter = 1.0, double and = 0.7, double ea = 0.5}) =>
    [
      for (var q = 0; q < 4; q++) ...[
        BackingHit(q * 24, quarter),
        BackingHit(q * 24 + 6, ea),
        BackingHit(q * 24 + 12, and),
        BackingHit(q * 24 + 18, ea),
      ],
    ];

final List<BackingStyle> backingStyles = List.unmodifiable([
  BackingStyle(
    id: 'rock8',
    label: 'Rock 8ths',
    feel: BackingFeel.straight,
    kick: const [BackingHit(0, 1.0), BackingHit(48, 1.0)],
    hihat: _eighths(),
  ),
  BackingStyle(
    id: 'rock16',
    label: 'Rock 16ths',
    feel: BackingFeel.straight,
    kick: const [BackingHit(0, 1.0), BackingHit(48, 1.0), BackingHit(60, 0.9)],
    hihat: _sixteenths(),
  ),
  BackingStyle(
    id: 'halftime',
    label: 'Half-time',
    feel: BackingFeel.straight,
    kick: const [BackingHit(0, 1.0), BackingHit(36, 0.9)],
    hihat: [
      for (var q = 0; q < 4; q++) ...[
        BackingHit(q * 24, q.isEven ? 1.0 : 0.6),
        BackingHit(q * 24 + 12, 0.6),
      ],
    ],
  ),
  BackingStyle(
    id: 'shuffle',
    label: 'Shuffle',
    feel: BackingFeel.shuffle,
    kick: const [BackingHit(0, 1.0), BackingHit(48, 1.0)],
    hihat: [
      for (var q = 0; q < 4; q++) ...[
        BackingHit(q * 24, 1.0),
        BackingHit(q * 24 + 16, 0.6),
      ],
    ],
  ),
  BackingStyle(
    id: 'swing',
    label: 'Swing',
    feel: BackingFeel.swing,
    // Feathered kick on all four, ride-style "spang-a-lang" on the hi-hat.
    kick: const [
      BackingHit(0, 0.4),
      BackingHit(24, 0.4),
      BackingHit(48, 0.4),
      BackingHit(72, 0.4),
    ],
    hihat: const [
      BackingHit(0, 1.0),
      BackingHit(24, 1.0),
      BackingHit(40, 0.6),
      BackingHit(48, 1.0),
      BackingHit(72, 1.0),
      BackingHit(88, 0.6),
    ],
  ),
  BackingStyle(
    id: 'funk16',
    label: 'Funk 16ths',
    feel: BackingFeel.straight,
    kick: const [
      BackingHit(0, 1.0),
      BackingHit(18, 0.9),
      BackingHit(36, 0.9),
      BackingHit(48, 1.0),
      BackingHit(66, 0.9),
    ],
    hihat: _sixteenths(quarter: 1.0, and: 0.8, ea: 0.45),
  ),
]);

BackingStyle? backingStyleById(String? id) {
  if (id == null) return null;
  for (final s in backingStyles) {
    if (s.id == id) return s;
  }
  return null;
}

/// Per-tick volumes of one backing voice across [cycleTicks]: the style's
/// bar is tiled every `beatsPerBar × 24` ticks; hits beyond a shorter bar
/// (2/4 exercises) are dropped. Ticks are always 24 per quarter here.
List<double> tileBackingHits(
  List<BackingHit> hits, {
  required int beatsPerBar,
  required int cycleTicks,
}) {
  final bar = beatsPerBar * 24;
  final out = List<double>.filled(cycleTicks, 0.0);
  for (var start = 0; start < cycleTicks; start += bar) {
    for (final h in hits) {
      if (h.tick >= bar) continue;
      final t = start + h.tick;
      if (t < cycleTicks) out[t] = h.level;
    }
  }
  return out;
}
