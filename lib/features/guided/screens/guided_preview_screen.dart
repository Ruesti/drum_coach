import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../app/design_tokens.dart';
import '../../../app/platform_support.dart';
import '../../../app/theme.dart';
import '../../../data/local/settings_service.dart';
import '../../../shared/widgets/app_badge.dart';
import '../../practice/backdrop.dart';
import '../../practice/widgets/tempo_row.dart';
import '../data/guided_lookup.dart';
import '../guided_format.dart';
import '../guided_pages.dart';
import '../guided_run_controller.dart' show guidedVariationNumber;
import '../models/guided_exercise.dart';
import '../guided_shortcuts.dart';
import '../widgets/guided_backdrop.dart';
import '../widgets/guided_layout.dart';
import '../widgets/guided_stage.dart';
import '../widgets/guided_page_view.dart';
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

  // One photo for the whole visit.
  late final String _photo = widget.photo ?? nextBackdrop();

  @override
  Widget build(BuildContext context) {
    final ex = _ex;
    final Widget content;
    if (ex == null) {
      content = _onBackdrop(_NotFound(onBack: _back));
    } else {
      content = LayoutBuilder(builder: (context, c) {
        final two = guidedWide(c.maxWidth) ||
            c.maxWidth >= guidedPreviewTwoColumnMinWidth;
        return two ? _wide(ex, c.biggest) : _onBackdrop(_narrow(ex));
      });
    }
    Widget screen = Scaffold(
      backgroundColor: PracticeColors.base,
      body: Theme(
        data: drumCoachPracticeTheme,
        child: Material(color: Colors.transparent, child: content),
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

  /// Phone / not-found: the photo fills the window, the content stops at
  /// [guidedMaxWidth], centred.
  Widget _onBackdrop(Widget content) => GuidedBackdrop(
        playing: false,
        photo: _photo,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: guidedMaxWidth),
            child: SizedBox.expand(child: content),
          ),
        ),
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

  /// Most of the window height the sheet may take: the stage keeps >= 45 %.
  static const _sheetShare = 0.55;

  static const _settingsWidth = 320.0;

  /// Wide layout (Drumeo lesson): photo stage with title and settings on
  /// top, the white sheet with the whole exercise below (scrolls itself).
  Widget _wide(GuidedExercise ex, Size size) {
    final sheetMax = _sheetShare * size.height;
    final labelSize = size.height >= 1000 ? 14.0 : 13.0;
    final pageMax =
        ((sheetMax - 2 * AppSpacing.sm - 2 * (labelSize * 1.2 + 2)) / 2)
            .clamp(90.0, 420.0);
    return Column(
      key: const Key('guided-wide'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: GuidedStage(
            key: const Key('guided-stage'),
            photo: _photo,
            child: _wideStage(ex),
          ),
        ),
        ConstrainedBox(
          constraints: BoxConstraints(maxHeight: sheetMax),
          child: _PreviewSheet(
            exercise: ex,
            pageBars: 4,
            pageMax: pageMax,
            gutter: AppSpacing.screenPadding,
            labelSize: labelSize,
            scrolls: true,
          ),
        ),
      ],
    );
  }

  /// Overlays of the stage: back, title and description top left, the
  /// settings with Start bottom right.
  Widget _wideStage(GuidedExercise ex) {
    return Stack(
      children: [
        Positioned(
          left: AppSpacing.sm,
          top: AppSpacing.md,
          right: AppSpacing.screenPadding + _settingsWidth + AppSpacing.lg,
          child: _StageInfo(
            exercise: ex,
            duration: guidedDurationLabel(ex, bpm: _bpm),
            onBack: _back,
          ),
        ),
        Positioned(
          right: AppSpacing.screenPadding,
          bottom: AppSpacing.md,
          width: _settingsWidth,
          child: _StagePanel(
            exercise: ex,
            bpm: _bpm,
            teacher: _teacher,
            along: _along,
            onBpm: _setBpm,
            onTeacher: _setTeacher,
            onAlong: _setAlong,
            onStart: () => unawaited(_start()),
          ),
        ),
      ],
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
                _Header(
                  exercise: ex,
                  duration: guidedDurationLabel(ex, bpm: _bpm),
                  onBack: _back,
                ),
                const SizedBox(height: AppSpacing.xl),
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.card),
                  child: _PreviewSheet(
                    exercise: ex,
                    pageBars: 2,
                    pageMax: 130,
                    gutter: AppSpacing.md,
                    labelSize: 12,
                    scrolls: false,
                  ),
                ),
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
    required this.onBack,
  });

  final GuidedExercise exercise;
  final String duration;
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
        Text(ex.name, style: PracticeTypography.title),
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

const _shadow = [Shadow(color: Color(0x99000000), blurRadius: 8)];

/// Title block on the wide stage: back, badges, name, description, length.
class _StageInfo extends StatelessWidget {
  const _StageInfo({
    required this.exercise,
    required this.duration,
    required this.onBack,
  });

  final GuidedExercise exercise;
  final String duration;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final ex = exercise;
    final meta = PracticeTypography.label.copyWith(
        color: PracticeColors.textSecondary, fontSize: 14, shadows: _shadow);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        IconButton(
          tooltip: 'Back',
          onPressed: onBack,
          constraints: const BoxConstraints.tightFor(width: 44, height: 44),
          icon: const Icon(Icons.arrow_back, color: PracticeColors.textPrimary),
        ),
        const SizedBox(width: AppSpacing.sm),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.xs),
                child: Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.xs,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    AppBadge(
                        label: ex.package == GuidedPackage.kit ? 'SET' : 'PAD'),
                    AppBadge(
                        label: ex.difficulty.label, color: ex.difficulty.color),
                    Text(duration, style: meta),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(ex.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: PracticeTypography.display.copyWith(shadows: _shadow)),
              const SizedBox(height: AppSpacing.sm),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: Text(ex.description,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: PracticeTypography.body.copyWith(
                        color:
                            PracticeColors.textPrimary.withValues(alpha: 0.9),
                        shadows: _shadow)),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// `Groove · 8 bars`, `Variation 2 · Kick on the 16ths · 20 bars`.
String _pageLabel(GuidedExercise ex, GuidedPage page) {
  final s = ex.sections[page.sectionIndex];
  final name = switch (s.kind) {
    SectionKind.variation =>
      'Variation ${guidedVariationNumber(ex, page.sectionIndex)}'
          '${s.titleEn == null ? '' : ' · ${s.titleEn}'}',
    SectionKind.outro => 'Ending',
    SectionKind.intro => 'Intro',
    SectionKind.groove => 'Groove',
  };
  return '$name · ${_barsLabel(s.bars)}';
}

/// The white sheet: the whole exercise as pages, the groove first, then
/// every variation, each under its label. No playhead.
class _PreviewSheet extends StatelessWidget {
  const _PreviewSheet({
    required this.exercise,
    required this.pageBars,
    required this.pageMax,
    required this.gutter,
    required this.labelSize,
    required this.scrolls,
  });

  final GuidedExercise exercise;
  final int pageBars;
  final double pageMax;
  final double gutter;
  final double labelSize;

  /// Wide: scrolls inside its (capped) height; narrow: as high as its
  /// pages, the screen scrolls.
  final bool scrolls;

  @override
  Widget build(BuildContext context) {
    final labelStyle = PracticeTypography.label.copyWith(
        fontSize: labelSize,
        height: 1.2,
        letterSpacing: 0.6,
        color: const Color(0xFF1C1C1C));
    final pages = guidedPreviewPages(exercise, pageBars: pageBars);
    final column = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < pages.length; i++) ...[
          if (i > 0) const SizedBox(height: AppSpacing.md),
          Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: Text(_pageLabel(exercise, pages[i]),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: labelStyle),
          ),
          RepaintBoundary(
            child: GuidedPageView(
              exercise: exercise,
              page: pages[i],
              maxStaffHeight: pageMax,
              fullPageBars: pageBars,
            ),
          ),
        ],
      ],
    );
    final padding = EdgeInsets.fromLTRB(
        gutter, AppSpacing.sm, gutter, scrolls ? AppSpacing.lg : AppSpacing.md);
    return ColoredBox(
      key: const Key('guided-preview-sheet'),
      color: Colors.white,
      child: scrolls
          ? SingleChildScrollView(padding: padding, child: column)
          : Padding(padding: padding, child: column),
    );
  }
}

/// Settings and Start in the lower right of the wide stage: dark, a little
/// see-through, so the photo stays the picture.
class _StagePanel extends StatelessWidget {
  const _StagePanel({
    required this.exercise,
    required this.bpm,
    required this.teacher,
    required this.along,
    required this.onBpm,
    required this.onTeacher,
    required this.onAlong,
    required this.onStart,
  });

  final GuidedExercise exercise;
  final int bpm;
  final bool teacher;
  final bool along;
  final ValueChanged<int> onBpm;
  final ValueChanged<bool> onTeacher;
  final ValueChanged<bool> onAlong;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: PracticeColors.inset.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TempoRow(
            bpm: bpm,
            onChanged: onBpm,
            step: guidedTempoStep,
            min: exercise.minBpm,
            max: exercise.maxBpm,
          ),
          GuidedSwitchRow(
            key: const Key('guided-teacher'),
            title: 'Teacher',
            value: teacher,
            onChanged: onTeacher,
          ),
          const Divider(height: 1, color: Color(0x1FFFFFFF)),
          GuidedSwitchRow(
            key: const Key('guided-along'),
            title: 'Play along',
            value: along,
            onChanged: onAlong,
          ),
          const SizedBox(height: AppSpacing.sm),
          GuidedAccentButton(
              key: const Key('guided-start'),
              icon: Icons.play_arrow_rounded,
              label: 'Start',
              onPressed: onStart),
          if (isDesktopPlatform) ...[
            const SizedBox(height: AppSpacing.sm),
            const _KeyHint(),
          ],
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
