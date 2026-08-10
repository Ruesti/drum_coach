import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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
        style: TextStyle(color: Colors.white.withValues(alpha: 0.45)),
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
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Colors.deepOrange,
              fontWeight: FontWeight.bold,
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
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        '${rudiment.difficulty.label} · ${rudiment.minBpm}–${rudiment.targetBpm} BPM',
        style: TextStyle(
            color: Colors.white.withValues(alpha: 0.45), fontSize: 12),
      ),
      trailing: const Icon(Icons.chevron_right, color: Colors.white24),
      onTap: () => context.push('/practice/${rudiment.id}'),
    );
  }
}
