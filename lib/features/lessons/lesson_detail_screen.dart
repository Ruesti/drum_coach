import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/design_tokens.dart';
import '../../shared/widgets/app_badge.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/notation_staff_widget.dart';
import 'lessons_provider.dart';
import 'models/rudiment.dart';

class LessonDetailScreen extends ConsumerWidget {
  final String rudimentId;

  const LessonDetailScreen({super.key, required this.rudimentId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rudiment = ref.watch(rudimentByIdProvider(rudimentId));

    return Scaffold(
      appBar: AppBar(
        title: Text(
          rudiment.name,
          maxLines: rudiment.name.length > 24 ? 2 : 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _MetaRow(rudiment: rudiment),
            const SizedBox(height: 20),
            Text(
              rudiment.description,
              style: AppTypography.body.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 32),
            Text(
              'STICKING PATTERN',
              style: AppTypography.label.copyWith(
                color: AppColors.accent,
                letterSpacing: 2,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            NotationStaffWidget(rudiment: rudiment),
            const SizedBox(height: 12),
            _Legend(),
            if (rudiment.technique.isNotEmpty) ...[
              const SizedBox(height: 32),
              Text(
                'TECHNIK',
                style: AppTypography.label.copyWith(
                  color: AppColors.accent,
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
          color: AppColors.textMuted,
        ),
        AppBadge(
          label: rudiment.difficulty.label,
          color: rudiment.difficulty.color,
        ),
        for (final skill in rudiment.skills)
          _InfoChip(
            icon: Icons.label_outline,
            label: skill.label,
            color: AppColors.textFaint,
          ),
        for (final genre in rudiment.genres)
          _InfoChip(
            icon: Icons.public,
            label: genre.label,
            color: AppColors.textFaint,
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
          Text(label, style: AppTypography.label.copyWith(color: color)),
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
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              section.title,
              style: AppTypography.body.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              section.body,
              style: AppTypography.body.copyWith(
                color: AppColors.textSecondary,
                fontSize: 13,
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            'Snare auf der mittleren Linie; die Taktart steht am Anfang.',
            style: AppTypography.label.copyWith(color: AppColors.textMuted),
          ),
        ),
        Wrap(
          spacing: 16,
          runSpacing: 8,
          children: [
            _LegendItem(
              symbol: '>',
              color: AppColors.accent,
              label: 'Akzent',
            ),
            _LegendItem(
              symbol: '( )',
              color: AppColors.textMuted,
              label: 'Ghost Note',
              small: true,
            ),
            _LegendItem(
              symbol: '♪',
              color: AppColors.textMuted,
              label: 'Vorschlag (Flam/Drag)',
              small: true,
            ),
          ],
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
          style: AppTypography.label.copyWith(color: AppColors.textMuted),
        ),
      ],
    );
  }
}
