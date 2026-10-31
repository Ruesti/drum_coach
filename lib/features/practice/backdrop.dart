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

/// Vertical alignment (-1 top .. 1 bottom) of the 4:3 window on the portrait
/// photo, so head and drums stay in view. Keys = asset paths. Tuned with
/// `python3 tool/backdrop_focus_sheet.py <out.png>`.
const Map<String, double> backdropFocus = {
  'assets/illustrations/practice/p01_garage_teen_s5.jpg': 0.0,
  'assets/illustrations/practice/p01_garage_teen_s77.jpg': 0.0,
  'assets/illustrations/practice/p02_jazz_bar_s5.jpg': 0.1,
  'assets/illustrations/practice/p02_jazz_bar_s77.jpg': 0.1,
  'assets/illustrations/practice/p03_loft_woman_s5.jpg': -0.2,
  'assets/illustrations/practice/p03_loft_woman_s77.jpg': -0.2,
  'assets/illustrations/practice/p04_basement_metal_s5.jpg': -0.15,
  'assets/illustrations/practice/p04_basement_metal_s77.jpg': -0.2,
  'assets/illustrations/practice/p05_school_room_s5.jpg': 0.0,
  'assets/illustrations/practice/p05_school_room_s77.jpg': 0.0,
  'assets/illustrations/practice/p06_church_gospel_s5.jpg': -0.05,
  'assets/illustrations/practice/p06_church_gospel_s77.jpg': -0.05,
  'assets/illustrations/practice/p07_rooftop_dusk_s5.jpg': -0.1,
  'assets/illustrations/practice/p07_rooftop_dusk_s77.jpg': -0.15,
  'assets/illustrations/practice/p08_club_red_s5.jpg': 0.1,
  'assets/illustrations/practice/p08_club_red_s77.jpg': 0.1,
  'assets/illustrations/practice/p09_studio_glass_s5.jpg': -0.1,
  'assets/illustrations/practice/p09_studio_glass_s77.jpg': -0.1,
  'assets/illustrations/practice/p10_home_kid_s5.jpg': 0.1,
  'assets/illustrations/practice/p10_home_kid_s77.jpg': 0.1,
  'assets/illustrations/practice/p11_festival_day_s5.jpg': -0.1,
  'assets/illustrations/practice/p11_festival_day_s77.jpg': -0.05,
  'assets/illustrations/practice/p12_practice_pad_s5.jpg': 0.0,
  'assets/illustrations/practice/p12_practice_pad_s77.jpg': 0.0,
  'assets/illustrations/practice/p13_theater_orch_s5.jpg': -0.6,
  'assets/illustrations/practice/p13_theater_orch_s77.jpg': -0.45,
  'assets/illustrations/practice/p14_bar_woman_s5.jpg': -0.2,
  'assets/illustrations/practice/p14_bar_woman_s77.jpg': -0.25,
  'assets/illustrations/practice/p15_rehearsal_foam_s5.jpg': -0.15,
  'assets/illustrations/practice/p15_rehearsal_foam_s77.jpg': -0.15,
  'assets/illustrations/practice/p16_daylight_plant_s5.jpg': 0.0,
  'assets/illustrations/practice/p16_daylight_plant_s77.jpg': 0.0,
  'assets/illustrations/practice/p17_stone_cellar_s5.jpg': 0.25,
  'assets/illustrations/practice/p17_stone_cellar_s77.jpg': 0.2,
  'assets/illustrations/practice/p18_evening_loft_s5.jpg': 0.2,
  'assets/illustrations/practice/p18_evening_loft_s77.jpg': 0.15,
};

/// Alignment for [asset]; photos without an entry use -0.2.
double backdropFocusY(String asset) => backdropFocus[asset] ?? -0.2;
