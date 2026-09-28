import 'dart:math';

/// Photos behind the practice screen (28.09., Uli: "Bild per Zufallsgenerator
/// in jeder Übung", a pool of about 30). Until the practice set is rendered
/// and picked, the pool is the Today set.
const List<String> practiceBackdrops = [
  'assets/illustrations/today/phase1.jpg',
  'assets/illustrations/today/phase2.jpg',
  'assets/illustrations/today/phase3.jpg',
  'assets/illustrations/today/phase4.jpg',
  'assets/illustrations/today/rest.jpg',
  'assets/illustrations/today/done.jpg',
  'assets/illustrations/today/setup.jpg',
];

/// One random photo from the pool — never the one shown last time ([avoid]),
/// so two exercises in a row do not look the same.
String pickBackdrop(Random rng, {String? avoid}) {
  final pool = practiceBackdrops.length > 1 && avoid != null
      ? practiceBackdrops.where((p) => p != avoid).toList()
      : practiceBackdrops;
  return pool[rng.nextInt(pool.length)];
}
