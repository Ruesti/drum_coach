import '../../../shared/widgets/kit_layout.dart';
import '../../lessons/models/rudiment.dart';

enum GuidedPackage { kit, pad }

enum SectionKind { intro, groove, variation, outro }

/// Fixed meter of guided exercises.
const int guidedBeatsPerBar = 4;

/// One part of a guided exercise: a line played for [bars] bars.
class GuidedSection {
  const GuidedSection({
    required this.kind,
    required this.line,
    required this.bars,
    this.textEn,
    this.speechClipId,
    this.afterClipId,
  });

  final SectionKind kind;
  final ExerciseLine line;
  final int bars;

  /// Explanation: shown (banner / line above the notes) AND spoken.
  final String? textEn;

  /// Clip of [textEn], spoken in the groove before this section.
  final String? speechClipId;

  /// Short phrase after the section ("Good - back to the groove.").
  final String? afterClipId;
}

class GuidedExercise {
  const GuidedExercise({
    required this.id,
    required this.name,
    required this.description,
    required this.package,
    required this.difficulty,
    required this.defaultBpm,
    required this.minBpm,
    required this.maxBpm,
    required this.gridUnit,
    required this.sections,
  });

  final String id;
  final String name;
  final String description;
  final GuidedPackage package;
  final Difficulty difficulty;
  final int defaultBpm;
  final int minBpm;
  final int maxBpm;
  final NoteGrid gridUnit;
  final List<GuidedSection> sections;

  int get beatsPerBar => guidedBeatsPerBar;

  int get variationCount =>
      sections.where((s) => s.kind == SectionKind.variation).length;

  /// Planned bars including the one count-in bar, without auto extension.
  /// [bpm] is accepted for the later tempo-dependent extension; the plan
  /// itself does not depend on it.
  int barsAt(int bpm) => 1 + sections.fold<int>(0, (n, s) => n + s.bars);

  /// Throws [ArgumentError] when the exercise breaks the structure rules.
  void validate() {
    if (sections.length < 2) {
      throw ArgumentError('$id: needs at least an intro and an outro');
    }
    if (sections.first.kind != SectionKind.intro ||
        sections.last.kind != SectionKind.outro) {
      throw ArgumentError('$id: must start with intro and end with outro');
    }
    final intros = sections.where((s) => s.kind == SectionKind.intro).length;
    final outros = sections.where((s) => s.kind == SectionKind.outro).length;
    if (intros != 1 || outros != 1) {
      throw ArgumentError('$id: exactly one intro and one outro required');
    }
    final ticksPerBar = guidedBeatsPerBar * kitTicksPerQuarter;
    for (var i = 0; i < sections.length; i++) {
      final s = sections[i];
      if (s.bars < 0 || (s.bars == 0 && s.kind != SectionKind.intro)) {
        throw ArgumentError('$id: section $i needs bars > 0');
      }
      final ticks = ticksOf(s.line.beats, gridUnit);
      if (ticks % ticksPerBar != 0 || (ticks == 0 && s.bars > 0)) {
        throw ArgumentError('$id: section $i does not span whole bars');
      }
      if (s.kind == SectionKind.variation) {
        if (s.textEn == null ||
            s.textEn!.isEmpty ||
            s.speechClipId == null ||
            s.speechClipId!.isEmpty) {
          throw ArgumentError(
              '$id: variation $i needs textEn and speechClipId');
        }
        if (i > 0 && sections[i - 1].kind == SectionKind.variation) {
          throw ArgumentError('$id: variation $i directly follows a variation');
        }
      }
    }
  }
}
