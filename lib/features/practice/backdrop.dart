import 'dart:math';

/// Photos behind the practice screen (28.09., Uli: "Bild per Zufallsgenerator
/// in jeder Übung, ca. 30 Fotos"): the practice set, 18 motifs × 2 seeds,
/// see `assets/illustrations/practice/README.md`.
final List<String> practiceBackdrops = List.unmodifiable([
  for (final motif in [
    'p01_garage_teen',
    'p02_jazz_bar',
    'p03_loft_woman',
    'p04_basement_metal',
    'p05_school_room',
    'p06_church_gospel',
    'p07_rooftop_dusk',
    'p08_club_red',
    'p09_studio_glass',
    'p10_home_kid',
    'p11_festival_day',
    'p12_practice_pad',
    'p13_theater_orch',
    'p14_bar_woman',
    'p15_rehearsal_foam',
    'p16_daylight_plant',
    'p17_stone_cellar',
    'p18_evening_loft',
  ])
    for (final seed in ['s5', 's77'])
      'assets/illustrations/practice/${motif}_$seed.jpg',
]);

/// One random photo from the pool — never the one shown last time ([avoid]),
/// so two exercises in a row do not look the same.
String pickBackdrop(Random rng, {String? avoid}) {
  final pool = practiceBackdrops.length > 1 && avoid != null
      ? practiceBackdrops.where((p) => p != avoid).toList()
      : practiceBackdrops;
  return pool[rng.nextInt(pool.length)];
}

String? _lastShown;

/// The next photo for any screen (practice, Today, Library — 29.09.):
/// random, never the one shown last, wherever that was.
String nextBackdrop({Random? rng}) {
  final next = pickBackdrop(rng ?? Random(), avoid: _lastShown);
  _lastShown = next;
  return next;
}
