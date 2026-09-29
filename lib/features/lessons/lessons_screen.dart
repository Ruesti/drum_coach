import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/design_tokens.dart';
import '../../shared/widgets/app_badge.dart';
import '../learning/suggested_bpm_provider.dart';
import '../practice/backdrop.dart';
import 'lessons_provider.dart';
import 'models/rudiment.dart';
import 'rudiment_filter.dart';

class LessonsScreen extends ConsumerStatefulWidget {
  const LessonsScreen({super.key});

  @override
  ConsumerState<LessonsScreen> createState() => _LessonsScreenState();
}

class _LessonsScreenState extends ConsumerState<LessonsScreen> {
  /// Header photo, chosen once per screen instance (29.09., Uli).
  late final String _hero = nextBackdrop();
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

    // The photo header runs up behind the status bar: light system icons.
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light
          .copyWith(statusBarColor: Colors.transparent),
      child: Scaffold(
      body: Column(
        children: [
          _LibraryHero(asset: _hero),
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
            label: 'Limbs',
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
      ),
    );
  }
}

/// Borderless photo header, about a third of the screen, with the title on
/// it (29.09., Uli: "die Library-Seite braucht Bild"). The bottom darkens
/// so the white title reads on every photo; the filters start right below.
class _LibraryHero extends StatelessWidget {
  const _LibraryHero({required this.asset});
  final String asset;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.32,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            asset,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) =>
                const ColoredBox(color: AppColors.raised),
          ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0x40101010),
                  Color(0x00101010),
                  Color(0xA6101010),
                ],
                stops: [0.0, 0.35, 1.0],
              ),
            ),
          ),
          Positioned(
            left: AppSpacing.screenPadding,
            right: AppSpacing.screenPadding,
            bottom: AppSpacing.md,
            child: Text(
              'Library',
              style: AppTypography.display.copyWith(
                color: Colors.white,
                shadows: const [
                  Shadow(
                      color: Color(0x99000000),
                      blurRadius: 8,
                      offset: Offset(0, 1)),
                ],
              ),
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
        'No exercises match this filter combination.',
        style: AppTypography.body.copyWith(color: AppColors.textMuted),
      ),
    );
  }
}

class _RudimentTile extends ConsumerWidget {
  final Rudiment rudiment;
  const _RudimentTile({required this.rudiment});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
          IconButton(
            icon: const Icon(Icons.info_outline, color: AppColors.textFaint),
            tooltip: 'Show explanation',
            onPressed: () => context.push('/library/${rudiment.id}'),
          ),
        ],
      ),
      // Straight into practice, matching the Routine/Program entry points —
      // the explanation is available on demand via the info button above
      // instead of forced before every start.
      onTap: () async {
        final bpm = await ref.read(suggestedBpmProvider(rudiment.id).future);
        if (context.mounted) context.push('/practice/${rudiment.id}?bpm=$bpm');
      },
    );
  }
}
