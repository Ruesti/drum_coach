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
