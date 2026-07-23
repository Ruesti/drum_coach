import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'data/rudiments_seed.dart';
import 'models/rudiment.dart';

part 'lessons_provider.g.dart';

@riverpod
List<Rudiment> rudiments(RudimentsRef ref) => rudimentsSeedData;

@riverpod
Rudiment rudimentById(RudimentByIdRef ref, String id) {
  return ref.watch(rudimentsProvider).firstWhere(
        (r) => r.id == id,
        orElse: () => throw ArgumentError('Unknown rudiment id: $id'),
      );
}

/// Pure filter used by [LessonsScreen] — no widget/provider dependency, so
/// it's directly unit-testable. [family] narrows to one PAS rudiment
/// family (`null` = no family filter). [skills] narrows to rudiments
/// carrying at least one of the given skill tags (OR semantics within the
/// set; empty set = no skill filter). Family and skill filters combine
/// with AND semantics. Result is sorted by name.
List<Rudiment> filterRudiments(
  List<Rudiment> all, {
  RudimentFamily? family,
  Set<Skill> skills = const {},
}) {
  return all.where((r) {
    if (family != null && r.family != family) return false;
    if (skills.isNotEmpty && !r.skill.any(skills.contains)) return false;
    return true;
  }).toList()
    ..sort((a, b) => a.name.compareTo(b.name));
}

typedef LessonsFilterState = ({RudimentFamily? family, Set<Skill> skills});

@riverpod
class LessonsFilter extends _$LessonsFilter {
  @override
  LessonsFilterState build() => (family: null, skills: const {});

  void setFamily(RudimentFamily? family) =>
      state = (family: family, skills: state.skills);

  void toggleSkill(Skill skill) {
    final next = {...state.skills};
    if (!next.remove(skill)) next.add(skill);
    state = (family: state.family, skills: next);
  }
}

@riverpod
List<Rudiment> filteredRudiments(FilteredRudimentsRef ref) {
  final all = ref.watch(rudimentsProvider);
  final filter = ref.watch(lessonsFilterProvider);
  return filterRudiments(all, family: filter.family, skills: filter.skills);
}
