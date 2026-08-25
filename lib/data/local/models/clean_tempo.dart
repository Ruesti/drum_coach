import 'package:isar/isar.dart';

part 'clean_tempo.g.dart';

/// The last *clean* tempo reached for a given exercise line, in BPM.
///
/// This is the only persisted state of the training program: it seeds the next
/// tempo ladder (STICK_CONTROL_PROGRAM.md §4/§6). One row per [exerciseKey]
/// (an existing `Rudiment.id`). Mirrors the [RudimentProgress] pattern.
@collection
class CleanTempo {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late String exerciseKey;

  late int bpm;
}
