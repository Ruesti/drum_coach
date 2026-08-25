import 'models/rudiment.dart';

/// Selected values per tag axis for the Lessons-screen filter UI. Empty sets
/// mean "no restriction on this axis" — matches everything.
class RudimentFilters {
  final Set<Skill> skills;
  final Set<Genre> genres;
  final Set<Limb> limbs;
  final Set<NoteGrid> subdivisions;

  const RudimentFilters({
    this.skills = const {},
    this.genres = const {},
    this.limbs = const {},
    this.subdivisions = const {},
  });

  bool get isEmpty =>
      skills.isEmpty && genres.isEmpty && limbs.isEmpty && subdivisions.isEmpty;
}

/// Filters [all] by [filters]: within one axis, a selected value matches if
/// the rudiment has ANY of the selected values (OR); across axes, a
/// rudiment must satisfy EVERY axis that has a selection (AND). An axis
/// with no selection does not restrict the result.
List<Rudiment> filterRudiments(List<Rudiment> all, RudimentFilters filters) {
  if (filters.isEmpty) return all;
  return all.where((r) {
    if (filters.skills.isNotEmpty &&
        r.skills.intersection(filters.skills).isEmpty) {
      return false;
    }
    if (filters.genres.isNotEmpty &&
        r.genres.intersection(filters.genres).isEmpty) {
      return false;
    }
    if (filters.limbs.isNotEmpty &&
        r.limbs.intersection(filters.limbs).isEmpty) {
      return false;
    }
    if (filters.subdivisions.isNotEmpty &&
        !filters.subdivisions.contains(r.gridUnit)) {
      return false;
    }
    return true;
  }).toList();
}
