import '../models/guided_exercise.dart';
import 'demo_exercise.dart';
import 'guided_catalog.dart';

/// The guided exercise with [id] — catalog first, then the two demos of the
/// listening page; null when unknown.
GuidedExercise? guidedExerciseById(String id) {
  for (final ex in [...guidedCatalog, demoKitExercise, demoPadExercise]) {
    if (ex.id == id) return ex;
  }
  return null;
}
