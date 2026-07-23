import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'lessons_provider.dart';
import 'models/rudiment.dart';

class LessonsScreen extends ConsumerWidget {
  const LessonsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(lessonsFilterProvider);
    final notifier = ref.read(lessonsFilterProvider.notifier);
    final rudiments = ref.watch(filteredRudimentsProvider);
    final availableSkills = ref.watch(availableSkillsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Lessons')),
      body: Column(
        children: [
          _FamilyFilterRow(
            selected: filter.family,
            onSelect: notifier.setFamily,
          ),
          _GenreFilterRow(
            selected: filter.genre,
            onSelect: notifier.setGenre,
          ),
          _SkillFilterRow(
            skills: availableSkills,
            selected: filter.skills,
            onToggle: notifier.toggleSkill,
          ),
          const Divider(height: 1, color: Colors.white12),
          Expanded(
            child: rudiments.isEmpty
                ? const _EmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.only(bottom: 24, top: 8),
                    itemCount: rudiments.length,
                    itemBuilder: (context, i) =>
                        _RudimentTile(rudiment: rudiments[i]),
                  ),
          ),
        ],
      ),
    );
  }
}

class _FamilyFilterRow extends StatelessWidget {
  final RudimentFamily? selected;
  final ValueChanged<RudimentFamily?> onSelect;

  const _FamilyFilterRow({required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final options = <RudimentFamily?>[null, ...RudimentFamily.values];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        children: [
          for (final option in options) ...[
            _FilterChip(
              label: option?.label ?? 'Alle',
              selected: selected == option,
              onTap: () => onSelect(option),
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }
}

class _GenreFilterRow extends StatelessWidget {
  final Genre? selected;
  final ValueChanged<Genre?> onSelect;

  const _GenreFilterRow({required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final options = <Genre?>[null, ...Genre.values];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
      child: Row(
        children: [
          for (final option in options) ...[
            _FilterChip(
              label: option?.label ?? 'Alle',
              selected: selected == option,
              onTap: () => onSelect(option),
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }
}

class _SkillFilterRow extends StatelessWidget {
  final List<Skill> skills;
  final Set<Skill> selected;
  final ValueChanged<Skill> onToggle;

  const _SkillFilterRow({
    required this.skills,
    required this.selected,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Row(
        children: [
          for (final skill in skills) ...[
            _FilterChip(
              label: skill.label,
              selected: selected.contains(skill),
              onTap: () => onToggle(skill),
            ),
            const SizedBox(width: 8),
          ],
        ],
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

class _EmptyState extends StatelessWidget {
  const _EmptyState();

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
