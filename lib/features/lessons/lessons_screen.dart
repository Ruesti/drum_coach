import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/design_tokens.dart';
import '../../shared/widgets/app_badge.dart';
import 'lessons_provider.dart';
import 'models/rudiment.dart';
import 'rudiment_filter.dart';

class LessonsScreen extends ConsumerStatefulWidget {
  const LessonsScreen({super.key});

  @override
  ConsumerState<LessonsScreen> createState() => _LessonsScreenState();
}

class _LessonsScreenState extends ConsumerState<LessonsScreen> {
  Set<Skill> _selectedSkills = {};
  Set<Genre> _selectedGenres = {};
  Set<Limb> _selectedLimbs = {};
  Set<NoteGrid> _selectedSubdivisions = {};

  @override
  Widget build(BuildContext context) {
    final all = ref.watch(rudimentsProvider);
    final filtered = filterRudiments(
      all,
      RudimentFilters(
        skills: _selectedSkills,
        genres: _selectedGenres,
        limbs: _selectedLimbs,
        subdivisions: _selectedSubdivisions,
      ),
    );

    final presentGenres = all.expand((r) => r.genres).toSet();
    final presentSubdivisions = all.map((r) => r.gridUnit).toSet();

    return Scaffold(
      appBar: AppBar(title: const Text('Lessons')),
      body: Column(
        children: [
          _FilterAxisRow<Skill>(
            label: 'Skill',
            values: Skill.values,
            selected: _selectedSkills,
            labelOf: (s) => s.label,
            onChanged: (v) => setState(() => _selectedSkills = v),
          ),
          if (presentGenres.isNotEmpty)
            _FilterAxisRow<Genre>(
              label: 'Genre',
              values: Genre.values.where(presentGenres.contains).toList(),
              selected: _selectedGenres,
              labelOf: (g) => g.label,
              onChanged: (v) => setState(() => _selectedGenres = v),
            ),
          _FilterAxisRow<Limb>(
            label: 'Gliedmaßen',
            values: Limb.values,
            selected: _selectedLimbs,
            labelOf: (l) => l.label,
            onChanged: (v) => setState(() => _selectedLimbs = v),
          ),
          if (presentSubdivisions.isNotEmpty)
            _FilterAxisRow<NoteGrid>(
              label: 'Subdivision',
              values:
                  NoteGrid.values.where(presentSubdivisions.contains).toList(),
              selected: _selectedSubdivisions,
              labelOf: (g) => g.label,
              onChanged: (v) => setState(() => _selectedSubdivisions = v),
            ),
          const Divider(height: 1, color: AppColors.textFaint),
          Expanded(
            child: filtered.isEmpty
                ? const _EmptyFilterState()
                : ListView(
                    padding: const EdgeInsets.only(bottom: 24, top: 8),
                    children: [
                      for (final rudiment in filtered)
                        _RudimentTile(rudiment: rudiment),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _FilterAxisRow<T> extends StatelessWidget {
  final String label;
  final List<T> values;
  final Set<T> selected;
  final String Function(T) labelOf;
  final ValueChanged<Set<T>> onChanged;

  const _FilterAxisRow({
    required this.label,
    required this.values,
    required this.selected,
    required this.labelOf,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: AppTypography.label.copyWith(color: AppColors.textMuted),
          ),
          const SizedBox(height: 4),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final value in values) ...[
                  AppSelectableChip(
                    label: labelOf(value),
                    selected: selected.contains(value),
                    onTap: () {
                      final next = Set<T>.from(selected);
                      if (!next.remove(value)) next.add(value);
                      onChanged(next);
                    },
                  ),
                  const SizedBox(width: 8),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyFilterState extends StatelessWidget {
  const _EmptyFilterState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'Keine Übungen für diese Filterkombination.',
        style: AppTypography.body.copyWith(color: AppColors.textMuted),
      ),
    );
  }
}

class _RudimentTile extends StatelessWidget {
  final Rudiment rudiment;
  const _RudimentTile({required this.rudiment});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      title: Text(
        rudiment.name,
        maxLines: rudiment.name.length > 24 ? 2 : 1,
        overflow: TextOverflow.ellipsis,
        style: AppTypography.subtitle,
      ),
      subtitle: Text(
        '${rudiment.minBpm}–${rudiment.targetBpm} BPM',
        style: AppTypography.label.copyWith(color: AppColors.textMuted),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppBadge(
            label: rudiment.difficulty.label,
            color: rudiment.difficulty.color,
          ),
          const SizedBox(width: 4),
          const Icon(Icons.chevron_right, color: AppColors.textFaint),
        ],
      ),
      onTap: () => context.push('/lessons/${rudiment.id}'),
    );
  }
}
