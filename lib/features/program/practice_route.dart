import 'models/training_program.dart';

/// Route into the practice screen for a program block — one place for the
/// bpm / min / ladder query, shared by the program screen and Today.
String practiceRouteFor(ExerciseBlock block) {
  final params = [
    if (block.startBpm != null) 'bpm=${block.startBpm}',
    if (block.durationMinutes > 0) 'min=${block.durationMinutes}',
    if (block.type == BlockType.tempoLadder) 'ladder=1',
  ].join('&');
  return '/practice/${block.exerciseKey}${params.isEmpty ? '' : '?$params'}';
}
