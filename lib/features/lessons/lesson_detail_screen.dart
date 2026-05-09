import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../shared/widgets/sticking_pattern_widget.dart';
import 'lessons_provider.dart';
import 'models/rudiment.dart';

class LessonDetailScreen extends ConsumerWidget {
  final String rudimentId;

  const LessonDetailScreen({super.key, required this.rudimentId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rudiment = ref.watch(rudimentByIdProvider(rudimentId));

    return Scaffold(
      appBar: AppBar(title: Text(rudiment.name)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _MetaRow(rudiment: rudiment),
            const SizedBox(height: 20),
            Text(
              rudiment.description,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: Colors.white70, height: 1.6),
            ),
            const SizedBox(height: 32),
            Text(
              'STICKING PATTERN',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Colors.deepOrange,
                    letterSpacing: 2,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            StickingPatternWidget(pattern: rudiment.sticking),
            const SizedBox(height: 12),
            _Legend(),
            if (rudiment.technique.isNotEmpty) ...[
              const SizedBox(height: 32),
              Text(
                'TECHNIK',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Colors.deepOrange,
                      letterSpacing: 2,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 12),
              ...rudiment.technique.map(
                (s) => _TechniqueCard(section: s),
              ),
            ],
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => context.push('/practice/${rudiment.id}'),
              icon: const Icon(Icons.play_arrow_rounded),
              label: const Text('Start Practice'),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  final Rudiment rudiment;
  const _MetaRow({required this.rudiment});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _InfoChip(
          icon: Icons.speed_outlined,
          label: '${rudiment.minBpm}–${rudiment.targetBpm} BPM',
          color: Colors.white54,
        ),
        _InfoChip(
          icon: Icons.bar_chart_outlined,
          label: rudiment.difficulty.label,
          color: rudiment.difficulty.color,
        ),
        _InfoChip(
          icon: Icons.folder_outlined,
          label: rudiment.category,
          color: Colors.white38,
        ),
      ],
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _InfoChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          Text(label, style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

class _TechniqueCard extends StatelessWidget {
  final TechniqueSection section;
  const _TechniqueCard({required this.section});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              section.title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              section.body,
              style: const TextStyle(
                fontSize: 13,
                color: Colors.white70,
                height: 1.55,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _LegendItem(
          symbol: '●',
          color: Colors.deepOrange,
          label: 'Accent',
        ),
        const SizedBox(width: 16),
        _LegendItem(
          symbol: 'R',
          color: Colors.white.withValues(alpha: 0.35),
          label: 'Ghost note',
          small: true,
        ),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  final String symbol;
  final Color color;
  final String label;
  final bool small;

  const _LegendItem({
    required this.symbol,
    required this.color,
    required this.label,
    this.small = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          symbol,
          style: TextStyle(
            fontSize: small ? 11 : 13,
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: Theme.of(context)
              .textTheme
              .labelSmall
              ?.copyWith(color: Colors.white38),
        ),
      ],
    );
  }
}
