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

/// Skills actually present on at least one seed rudiment, in [Skill] enum
/// order. Used to drive the skill filter chip row so chips that would
/// always dead-end on an empty result (e.g. no rudiment is tagged
/// `Skill.groove` or `Skill.fill` today) aren't rendered.
@riverpod
List<Skill> availableSkills(AvailableSkillsRef ref) {
  final present = ref.watch(rudimentsProvider).expand((r) => r.skill).toSet();
  return Skill.values.where(present.contains).toList();
}

/// Pure filter used by [LessonsScreen] — no widget/provider dependency, so
/// it's directly unit-testable. [family] narrows to one PAS rudiment
/// family (`null` = no family filter). [genre] narrows to one musical/
/// stylistic context (`null` = no genre filter). [skills] narrows to
/// rudiments carrying at least one of the given skill tags (OR semantics
/// within the set; empty set = no skill filter). Family, genre and skill
/// filters combine with AND semantics. Result is sorted by name.
List<Rudiment> filterRudiments(
  List<Rudiment> all, {
  RudimentFamily? family,
  Genre? genre,
  Set<Skill> skills = const {},
}) {
  return all.where((r) {
    if (family != null && r.family != family) return false;
    if (genre != null && r.genre != genre) return false;
    if (skills.isNotEmpty && !r.skill.any(skills.contains)) return false;
    return true;
  }).toList()
    ..sort((a, b) => a.name.compareTo(b.name));
}

typedef LessonsFilterState = ({
  RudimentFamily? family,
  Genre? genre,
  Set<Skill> skills,
});

@riverpod
class LessonsFilter extends _$LessonsFilter {
  @override
  LessonsFilterState build() => (family: null, genre: null, skills: const {});

  void setFamily(RudimentFamily? family) =>
      state = (family: family, genre: state.genre, skills: state.skills);

  void setGenre(Genre? genre) =>
      state = (family: state.family, genre: genre, skills: state.skills);

  void toggleSkill(Skill skill) {
    final next = {...state.skills};
    if (!next.remove(skill)) next.add(skill);
    state = (family: state.family, genre: state.genre, skills: next);
  }
}

@riverpod
List<Rudiment> filteredRudiments(FilteredRudimentsRef ref) {
  final all = ref.watch(rudimentsProvider);
  final filter = ref.watch(lessonsFilterProvider);
  return filterRudiments(
    all,
    family: filter.family,
    genre: filter.genre,
    skills: filter.skills,
  );
}
