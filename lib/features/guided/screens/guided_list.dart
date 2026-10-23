import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/design_tokens.dart';
import '../../../shared/widgets/app_badge.dart';
import '../../lessons/models/rudiment.dart';
import '../data/guided_catalog.dart';
import '../models/guided_exercise.dart';
import '../widgets/guided_tile.dart';

/// The library is capped at 900 px on desktop, so it never reaches the
/// 1000 px of `guidedWide`: the list switches to two columns from this
/// available width instead.
const double guidedGridMinWidth = 700;

/// Guided part of the library: Set | Pad and Difficulty filters, tiles
/// grouped by difficulty.
class GuidedList extends StatefulWidget {
  const GuidedList({super.key});

  @override
  State<GuidedList> createState() => _GuidedListState();
}

class _GuidedListState extends State<GuidedList> {
  Set<GuidedPackage> _packages = {};
  Set<Difficulty> _difficulties = {};

  Widget _chips<T>(String label, List<T> values, Set<T> selected,
      String Function(T) labelOf, ValueChanged<Set<T>> onChanged) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(),
              style: AppTypography.label.copyWith(color: AppColors.textMuted)),
          const SizedBox(height: 4),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(children: [
              for (final v in values) ...[
                AppSelectableChip(
                  label: labelOf(v),
                  selected: selected.contains(v),
                  onTap: () {
                    final next = Set<T>.from(selected);
                    if (!next.remove(v)) next.add(v);
                    onChanged(next);
                  },
                ),
                const SizedBox(width: 8),
              ],
            ]),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final shown = [
      for (final ex in guidedCatalog)
        if ((_packages.isEmpty || _packages.contains(ex.package)) &&
            (_difficulties.isEmpty || _difficulties.contains(ex.difficulty)))
          ex,
    ];
    void open(GuidedExercise ex) => context.push('/guided/${ex.id}');
    return Column(
      children: [
        _chips<GuidedPackage>(
            'Type',
            GuidedPackage.values,
            _packages,
            (p) => p == GuidedPackage.kit ? 'Set' : 'Pad',
            (v) => setState(() => _packages = v)),
        _chips<Difficulty>('Difficulty', Difficulty.values, _difficulties,
            (d) => d.label, (v) => setState(() => _difficulties = v)),
        const Divider(height: 1, color: AppColors.textFaint),
        Expanded(
          child: shown.isEmpty
              ? Center(
                  child: Text('No guided exercises match this filter.',
                      style: AppTypography.body
                          .copyWith(color: AppColors.textMuted)))
              : LayoutBuilder(builder: (context, c) {
                  final cols = c.maxWidth >= guidedGridMinWidth ? 2 : 1;
                  return ListView(
                    padding: const EdgeInsets.only(bottom: 24, top: 8),
                    children: [
                      for (final d in Difficulty.values)
                        ..._group(d, shown, cols, open),
                    ],
                  );
                }),
        ),
      ],
    );
  }

  List<Widget> _group(Difficulty d, List<GuidedExercise> shown, int cols,
      void Function(GuidedExercise) open) {
    final items = shown.where((e) => e.difficulty == d).toList();
    if (items.isEmpty) return const [];
    return [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
        child: Text(d.label.toUpperCase(),
            style: AppTypography.label.copyWith(color: AppColors.textMuted)),
      ),
      if (cols == 1)
        for (final ex in items) GuidedTile(exercise: ex, onTap: () => open(ex))
      else
        for (var i = 0; i < items.length; i += 2)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var j = i; j < i + 2; j++)
                Expanded(
                  child: j < items.length
                      ? GuidedTile(
                          exercise: items[j], onTap: () => open(items[j]))
                      : const SizedBox(),
                ),
            ],
          ),
    ];
  }
}
