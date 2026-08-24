import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/design_tokens.dart';
import 'lessons_provider.dart';
import 'models/rudiment.dart';

/// Browse screen for a named [ExerciseCollection] (e.g. Rudiment-Étüden),
/// grouped by [Rudiment.collectionGroup] (e.g. per rudiment name), preserving
/// first-seen order. Mirrors the dark-theme visual language of
/// [ProgramScreen]/[LessonsScreen].
class CollectionScreen extends ConsumerWidget {
  final ExerciseCollection collection;
  const CollectionScreen({super.key, required this.collection});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final all = ref.watch(rudimentsProvider);
    final entries = all.where((r) => r.collection == collection).toList();

    // Dart's default map literal is backed by LinkedHashMap, so this
    // preserves first-seen insertion order for group keys.
    final grouped = <String, List<Rudiment>>{};
    for (final r in entries) {
      final key = r.collectionGroup ?? '';
      grouped.putIfAbsent(key, () => []).add(r);
    }

    return Scaffold(
      appBar: AppBar(title: Text(collection.label)),
      body: entries.isEmpty
          ? const _EmptyCollectionState()
          : ListView(
              padding: const EdgeInsets.only(bottom: 24, top: 8),
              children: [
                for (final group in grouped.entries) ...[
                  if (group.key.isNotEmpty) _GroupHeader(title: group.key),
                  for (final rudiment in group.value)
                    _EtudeTile(rudiment: rudiment),
                ],
              ],
            ),
    );
  }
}

class _EmptyCollectionState extends StatelessWidget {
  const _EmptyCollectionState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'Keine Übungen in dieser Sammlung.',
        style: AppTypography.body.copyWith(color: AppColors.textMuted),
      ),
    );
  }
}

class _GroupHeader extends StatelessWidget {
  final String title;
  const _GroupHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        title,
        style: AppTypography.label.copyWith(
          color: AppColors.accent,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class _EtudeTile extends StatelessWidget {
  final Rudiment rudiment;
  const _EtudeTile({required this.rudiment});

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
        '${rudiment.difficulty.label} · ${rudiment.minBpm}–${rudiment.targetBpm} BPM',
        style: AppTypography.label.copyWith(color: AppColors.textMuted),
      ),
      trailing: const Icon(Icons.chevron_right, color: AppColors.textFaint),
      onTap: () => context.push('/practice/${rudiment.id}'),
    );
  }
}
