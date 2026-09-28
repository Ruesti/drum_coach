import '../lessons/models/rudiment.dart';
import '../metronome/backing_styles.dart';

/// Picks the backing style for an exercise (Engine part 1; decided 28.09.:
/// the user never picks — the band fits the exercise by itself).
///
/// Order: an explicit exercise default (`Rudiment.backing`, catalog data),
/// then genre (jazz swings, funk gets sixteenths), then the pattern's
/// subdivision: triplets shuffle, sixteenths get a sixteenth hi-hat up to
/// 139 BPM and relax to eighths from 140 — the way a drummer would —
/// everything else gets straight eighths. Never null: every exercise has
/// a band; whether it sounds is the switch's and the headphone rule's job.
String autoBackingStyle(Rudiment r, {required int bpm}) {
  final explicit = backingStyleById(r.backing);
  if (explicit != null) return explicit.id;
  if (r.genres.contains(Genre.jazz)) return 'swing';
  if (r.genres.contains(Genre.funk)) return 'funk16';
  final hasTuplets = r.sticking.any((b) => b.tuplet != Tuplet.none);
  if (r.gridUnit == NoteGrid.triplet || hasTuplets) return 'shuffle';
  final fineGrid = r.gridUnit.cellsPerQuarter >= 4;
  final fineValues = r.sticking.any((b) =>
      b.value == NoteValue.sixteenth || b.value == NoteValue.thirtySecond);
  if (fineGrid || fineValues) return bpm >= 140 ? 'rock8' : 'rock16';
  return 'rock8';
}
