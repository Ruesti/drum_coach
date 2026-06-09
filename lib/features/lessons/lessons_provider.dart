import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'data/rudiments_seed.dart';
import 'models/rudiment.dart';

part 'lessons_provider.g.dart';

@riverpod
List<Rudiment> rudiments(RudimentsRef ref) => rudimentsSeedData;

@riverpod
Map<String, List<Rudiment>> groupedRudiments(GroupedRudimentsRef ref) {
  final all = ref.watch(rudimentsProvider);
  return {
    for (final cat in rudimentCategories)
      cat: all.where((r) => r.category == cat).toList(),
  };
}

@riverpod
Rudiment rudimentById(RudimentByIdRef ref, String id) {
  return ref.watch(rudimentsProvider).firstWhere(
        (r) => r.id == id,
        orElse: () => throw ArgumentError('Unknown rudiment id: $id'),
      );
}

/// The free exercises ("Übungen") as a single ordered progression, sorted by
/// [Rudiment.level] then [Difficulty] — the guided practice plan.
@riverpod
List<Rudiment> practicePlan(PracticePlanRef ref) {
  final plan = ref
      .watch(rudimentsProvider)
      .where((r) => exerciseCategories.contains(r.category))
      .toList()
    ..sort((a, b) {
      final byLevel = (a.level ?? 1 << 20).compareTo(b.level ?? 1 << 20);
      if (byLevel != 0) return byLevel;
      return a.difficulty.index.compareTo(b.difficulty.index);
    });
  return plan;
}
