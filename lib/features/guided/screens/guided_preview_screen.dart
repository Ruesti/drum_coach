import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../app/design_tokens.dart';
import '../../../app/platform_support.dart';
import '../../../data/local/settings_service.dart';
import '../../../shared/widgets/app_badge.dart';
import '../../practice/widgets/tempo_row.dart';
import '../data/guided_lookup.dart';
import '../guided_format.dart';
import '../models/guided_exercise.dart';
import '../guided_shortcuts.dart';
import '../widgets/guided_backdrop.dart';
import '../widgets/guided_layout.dart';
import '../widgets/guided_line_view.dart';
import '../widgets/guided_panel.dart';
import 'guided_play_screen.dart' show GuidedPlayResult;

/// The preview stays inside the 900 px desktop cap, so it never reaches
/// the 1000 px of [guidedWide]: it switches to two columns from this width
/// (the cap minus a little — desktop and tablet portrait get two columns,
/// phones one).
const double guidedPreviewTwoColumnMinWidth = 820;

/// `/guided/:id`: introduces one guided exercise — the note lines of the
/// groove and each variation, tempo, Teacher / Play along — and starts it.
class GuidedPreviewScreen extends StatefulWidget {
  const GuidedPreviewScreen({super.key, required this.id, this.photo});

  final String id;

  /// Fixed backdrop photo for tests/goldens.
  final String? photo;

  @override
  State<GuidedPreviewScreen> createState() => _GuidedPreviewScreenState();
}

class _GuidedPreviewScreenState extends State<GuidedPreviewScreen> {
  late final GuidedExercise? _ex = guidedExerciseById(widget.id);
  late int _bpm =
      _ex == null ? 0 : _ex.defaultBpm.clamp(_ex.minBpm, _ex.maxBpm);
  bool _teacher = SettingsService.guidedTeacher;
  bool _along = SettingsService.guidedPlayAlong;

  void _setBpm(int v) {
    final ex = _ex!;
    setState(() => _bpm = v.clamp(ex.minBpm, ex.maxBpm));
  }

  void _setTeacher(bool v) {
    setState(() => _teacher = v);
    SettingsService.setGuidedTeacher(v);
  }

  void _setAlong(bool v) {
    setState(() => _along = v);
    SettingsService.setGuidedPlayAlong(v);
  }

  void _back() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/library');
    }
  }

  bool _starting = false;

  Future<void> _start() async {
    if (_starting) return;
    _starting = true;
    final ex = _ex!;
    final GuidedPlayResult? result;
    try {
      result =
          await context.push<GuidedPlayResult>('/guided/${ex.id}/play?bpm=$_bpm'
              '&teacher=${_teacher ? 1 : 0}&along=${_along ? 1 : 0}');
    } finally {
      _starting = false;
    }
    if (!mounted) return;
    // Tempo and switches may have changed during play: take them over, so
    // the next Start does not send the old values. The switches are saved
    // settings, re-read as a fallback (system back without a result).
    setState(() {
      _teacher = result?.teacher ?? SettingsService.guidedTeacher;
      _along = result?.along ?? SettingsService.guidedPlayAlong;
      if (result != null) _bpm = result.bpm.clamp(ex.minBpm, ex.maxBpm);
    });
  }

  Map<ShortcutActivator, VoidCallback> get _shortcuts => guidedShortcuts(
        primary: () => unawaited(_start()),
        bumpBpm: (d) => _setBpm(_bpm + d),
        toggleTeacher: () => _setTeacher(!_teacher),
        togglePlayAlong: () => _setAlong(!_along),
        leave: _back,
      );

  @override
  Widget build(BuildContext context) {
    final ex = _ex;
    final Widget content = ex == null
        ? _NotFound(onBack: _back)
        : LayoutBuilder(builder: (context, c) {
            final two = guidedWide(c.maxWidth) ||
                c.maxWidth >= guidedPreviewTwoColumnMinWidth;
            return two ? _wide(ex) : _narrow(ex);
          });
    // The photo fills the window; only the content stops at
    // [guidedMaxWidth], centred (Uli 27.10., round 2).
    final limited = Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: guidedMaxWidth),
        child: SizedBox.expand(child: content),
      ),
    );
    Widget screen = Scaffold(
      backgroundColor: PracticeColors.base,
      body: GuidedBackdrop(
        playing: false,
        photo: widget.photo,
        child: limited,
      ),
    );
    if (isDesktopPlatform) {
      screen = CallbackShortcuts(
        bindings: ex == null
            ? {const SingleActivator(LogicalKeyboardKey.escape): _back}
            : _shortcuts,
        child: Focus(autofocus: true, child: screen),
      );
    }
    return UncappedContent(
      maxWidth: double.infinity,
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: screen,
      ),
    );
  }

  Widget _header(GuidedExercise ex, {required bool large}) => _Header(
        exercise: ex,
        duration: guidedDurationLabel(ex, bpm: _bpm),
        large: large,
        onBack: _back,
      );

  Widget _settings(GuidedExercise ex) => _SettingsPanel(
        exercise: ex,
        bpm: _bpm,
        teacher: _teacher,
        along: _along,
        onBpm: _setBpm,
        onTeacher: _setTeacher,
        onAlong: _setAlong,
      );

  Widget _wide(GuidedExercise ex) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.xxl, AppSpacing.lg, AppSpacing.xxl, AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _header(ex, large: true),
          const SizedBox(height: AppSpacing.xl),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _NoteCards(
                            key: const Key('guided-cards'), exercise: ex),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.xl),
                Expanded(
                  flex: 2,
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _settings(ex),
                        const SizedBox(height: AppSpacing.lg),
                        GuidedAccentButton(
                            key: const Key('guided-start'),
                            icon: Icons.play_arrow_rounded,
                            label: 'Start',
                            onPressed: () => unawaited(_start())),
                        if (isDesktopPlatform) ...[
                          const SizedBox(height: AppSpacing.md),
                          const _KeyHint(),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _narrow(GuidedExercise ex) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _header(ex, large: false),
                const SizedBox(height: AppSpacing.xl),
                _NoteCards(key: const Key('guided-cards'), exercise: ex),
                const SizedBox(height: AppSpacing.lg),
                _settings(ex),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.lg),
          child: GuidedAccentButton(
              key: const Key('guided-start'),
              icon: Icons.play_arrow_rounded,
              label: 'Start',
              onPressed: () => unawaited(_start())),
        ),
      ],
    );
  }
}

// ── Pieces ──────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  const _Header({
    required this.exercise,
    required this.duration,
    required this.large,
    required this.onBack,
  });

  final GuidedExercise exercise;
  final String duration;
  final bool large;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final ex = exercise;
    final meta = PracticeTypography.label
        .copyWith(color: PracticeColors.textSecondary, fontSize: 13);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Transform.translate(
          offset: const Offset(-8, 0),
          child: IconButton(
            tooltip: 'Back',
            onPressed: onBack,
            icon:
                const Icon(Icons.arrow_back, color: PracticeColors.textPrimary),
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text('GUIDED EXERCISE',
            style: PracticeTypography.label
                .copyWith(color: PracticeColors.accent, letterSpacing: 1.6)),
        const SizedBox(height: AppSpacing.xs),
        Text(ex.name,
            style:
                large ? PracticeTypography.display : PracticeTypography.title),
        const SizedBox(height: AppSpacing.sm),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 620),
          child: Text(ex.description,
              style: PracticeTypography.body
                  .copyWith(color: PracticeColors.textSecondary)),
        ),
        const SizedBox(height: AppSpacing.md),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            AppBadge(label: ex.package == GuidedPackage.kit ? 'SET' : 'PAD'),
            AppBadge(label: ex.difficulty.label, color: ex.difficulty.color),
            const SizedBox(width: AppSpacing.xs),
            Text(duration, style: meta),
            Text('·', style: meta),
            Text(
                '${ex.variationCount} '
                '${ex.variationCount == 1 ? 'variation' : 'variations'}',
                style: meta),
          ],
        ),
      ],
    );
  }
}

String _barsLabel(int n) => n == 1 ? '1 bar' : '$n bars';

/// The note lines as a preview: one card per distinct section line, in
/// order — the groove first, then V1…Vn. No text, just the notes (Uli
/// 27.10.: "nicht textlich anzeigen was gespielt wird").
class _NoteCards extends StatelessWidget {
  const _NoteCards({super.key, required this.exercise});
  final GuidedExercise exercise;

  @override
  Widget build(BuildContext context) {
    final cards = <Widget>[];
    var v = 0;
    var grooveDone = false;
    for (final s in exercise.sections) {
      final String label;
      if (s.kind == SectionKind.groove) {
        if (grooveDone) continue;
        grooveDone = true;
        label = 'GROOVE';
      } else if (s.kind == SectionKind.variation) {
        label = 'V${++v}';
      } else {
        continue;
      }
      if (cards.isNotEmpty) cards.add(const SizedBox(height: AppSpacing.lg));
      cards.add(_NoteCard(
        exercise: exercise,
        section: s,
        label: label,
        isVariation: s.kind == SectionKind.variation,
      ));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: cards,
    );
  }
}

class _NoteCard extends StatelessWidget {
  const _NoteCard({
    required this.exercise,
    required this.section,
    required this.label,
    required this.isVariation,
  });

  final GuidedExercise exercise;
  final GuidedSection section;
  final String label;
  final bool isVariation;

  @override
  Widget build(BuildContext context) {
    final color =
        isVariation ? PracticeColors.accent : PracticeColors.textMuted;
    return GuidedPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: Text(
              '$label · ${_barsLabel(section.bars)}',
              style: PracticeTypography.label
                  .copyWith(color: color, fontSize: 13, letterSpacing: 1),
            ),
          ),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.chip),
            child: GuidedLineView(
              exercise: exercise,
              line: section.line,
              cursorStyle: CursorStyle.none,
              fillWidth: true,
              maxStaffHeight: 220,
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsPanel extends StatelessWidget {
  const _SettingsPanel({
    required this.exercise,
    required this.bpm,
    required this.teacher,
    required this.along,
    required this.onBpm,
    required this.onTeacher,
    required this.onAlong,
  });

  final GuidedExercise exercise;
  final int bpm;
  final bool teacher;
  final bool along;
  final ValueChanged<int> onBpm;
  final ValueChanged<bool> onTeacher;
  final ValueChanged<bool> onAlong;

  @override
  Widget build(BuildContext context) {
    return GuidedPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GuidedPanelLabel('TEMPO',
              trailing: '${exercise.minBpm}–${exercise.maxBpm}'),
          TempoRow(
            bpm: bpm,
            onChanged: onBpm,
            step: guidedTempoStep,
            min: exercise.minBpm,
            max: exercise.maxBpm,
          ),
          const SizedBox(height: AppSpacing.md),
          const Divider(height: 1, color: Color(0x1FFFFFFF)),
          GuidedSwitchRow(
            key: const Key('guided-teacher'),
            title: 'Teacher',
            subtitle: 'A voice explains each variation',
            value: teacher,
            onChanged: onTeacher,
          ),
          const Divider(height: 1, color: Color(0x1FFFFFFF)),
          GuidedSwitchRow(
            key: const Key('guided-along'),
            title: 'Play along',
            subtitle: 'Hear the notes played with you',
            value: along,
            onChanged: onAlong,
          ),
        ],
      ),
    );
  }
}

class _KeyHint extends StatelessWidget {
  const _KeyHint();

  @override
  Widget build(BuildContext context) =>
      const GuidedKeyHint(guidedPreviewKeyHint);
}

class _NotFound extends StatelessWidget {
  const _NotFound({required this.onBack});
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.search_off,
                  size: 40, color: PracticeColors.textMuted),
              const SizedBox(height: AppSpacing.md),
              Text('Exercise not found', style: PracticeTypography.title),
              const SizedBox(height: AppSpacing.lg),
              OutlinedButton(
                onPressed: onBack,
                style: OutlinedButton.styleFrom(
                  foregroundColor: PracticeColors.textPrimary,
                  side: const BorderSide(color: PracticeColors.textFaint),
                ),
                child: const Text('Back'),
              ),
            ],
          ),
        ),
      );
}
