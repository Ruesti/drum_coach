import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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
          const Divider(height: 1, color: Colors.white12),
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
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Colors.white38,
                  letterSpacing: 1.5,
                ),
          ),
          const SizedBox(height: 4),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final value in values) ...[
                  _FilterChip(
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
        style: TextStyle(color: Colors.white.withValues(alpha: 0.45)),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected
              ? Colors.deepOrange.withValues(alpha: 0.18)
              : Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? Colors.deepOrange : Colors.white24,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.deepOrange : Colors.white54,
          ),
        ),
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
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        '${rudiment.minBpm}–${rudiment.targetBpm} BPM',
        style: TextStyle(
            color: Colors.white.withValues(alpha: 0.45), fontSize: 12),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _DifficultyChip(difficulty: rudiment.difficulty),
          const SizedBox(width: 4),
          const Icon(Icons.chevron_right, color: Colors.white24),
        ],
      ),
      onTap: () => context.push('/lessons/${rudiment.id}'),
    );
  }
}

class _DifficultyChip extends StatelessWidget {
  final Difficulty difficulty;
  const _DifficultyChip({required this.difficulty});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: difficulty.color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: difficulty.color.withValues(alpha: 0.4)),
      ),
      child: Text(
        difficulty.label,
        style: TextStyle(
          fontSize: 11,
          color: difficulty.color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
