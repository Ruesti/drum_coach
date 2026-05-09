import 'package:isar/isar.dart';

part 'rudiment_progress.g.dart';

enum MasteryLevel { beginner, developing, competent, proficient, mastered }

@collection
class RudimentProgress {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late String rudimentId;

  late int currentBpm;
  late int bestBpm;

  @Enumerated(EnumType.name)
  late MasteryLevel mastery;

  late int srInterval;     // days until next review
  late int srRepetitions;  // consecutive successful reviews
  late DateTime lastPracticed;
  late DateTime nextReviewDate;
}
