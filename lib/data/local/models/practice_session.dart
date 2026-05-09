import 'package:isar/isar.dart';

part 'practice_session.g.dart';

@collection
class PracticeSession {
  Id id = Isar.autoIncrement;
  late String rudimentId;
  late int durationSeconds;
  late int achievedBpm;
  late int rating; // 1 = struggled, 2 = ok, 3 = solid
  late DateTime date;
}
