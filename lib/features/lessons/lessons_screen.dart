import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'data/rudiments_seed.dart';
import 'lessons_provider.dart';
import 'models/rudiment.dart';

class LessonsScreen extends ConsumerStatefulWidget {
  const LessonsScreen({super.key});

  @override
  ConsumerState<LessonsScreen> createState() => _LessonsScreenState();
}

class _LessonsScreenState extends ConsumerState<LessonsScreen> {
  // null = all, 'rudiments' = standard rudiments only, 'uebungen' = free exercises
  String _filter = 'all';

  static const _uebungenCategory = 'Übungen';
  static const _rudimentCategories = [
    'Rolls', 'Paradiddles', 'Flams', 'Ruffs', 'Ghost Notes', 'Linear Patterns',
  ];

  @override
  Widget build(BuildContext context) {
    final grouped = ref.watch(groupedRudimentsProvider);

    final showCategories = switch (_filter) {
      'rudiments' => _rudimentCategories,
      'uebungen'  => [_uebungenCategory],
      _           => rudimentCategories,
    };

    return Scaffold(
      appBar: AppBar(title: const Text('Lessons')),
      body: Column(
        children: [
          // Filter bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Row(
              children: [
                _FilterChip(
                  label: 'Alle',
                  selected: _filter == 'all',
                  onTap: () => setState(() => _filter = 'all'),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Rudiments',
                  selected: _filter == 'rudiments',
                  onTap: () => setState(() => _filter = 'rudiments'),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Übungen',
                  selected: _filter == 'uebungen',
                  onTap: () => setState(() => _filter = 'uebungen'),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Colors.white12),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.only(bottom: 24),
              children: [
                for (final category in showCategories) ...[
                  _CategoryHeader(category: category),
                  for (final rudiment in grouped[category] ?? [])
                    _RudimentTile(rudiment: rudiment),
                ],
              ],
            ),
          ),
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

class _CategoryHeader extends StatelessWidget {
  final String category;
  const _CategoryHeader({required this.category});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
      child: Text(
        category.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Colors.deepOrange,
              letterSpacing: 2,
              fontWeight: FontWeight.bold,
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
