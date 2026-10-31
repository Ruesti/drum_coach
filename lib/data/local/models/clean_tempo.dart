import 'package:isar/isar.dart';

part 'clean_tempo.g.dart';

/// The last *clean* tempo reached for a given exercise line, in BPM.
///
/// Was the only persisted state of the training program (seeded its tempo
/// ladder). The program is gone (Trainingsraum, 31.10.); the collection stays
/// registered so old rows survive, but nothing reads or writes it.
@collection
class CleanTempo {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late String exerciseKey;

  late int bpm;
}
