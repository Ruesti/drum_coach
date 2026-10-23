import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/design_tokens.dart';
import '../../../app/platform_support.dart';
import '../../../data/local/settings_service.dart';
import '../../practice/backdrop.dart';
import '../../practice/widgets/tempo_row.dart';
import '../data/guided_lookup.dart';
import '../guided_format.dart';
import '../guided_rig_provider.dart';
import '../guided_run_controller.dart';
import '../guided_shortcuts.dart';
import '../models/guided_exercise.dart';
import '../run_clock.dart';
import '../run_plan.dart';
import '../widgets/guided_backdrop.dart';
import '../widgets/guided_banner.dart';
import '../widgets/guided_layout.dart';
import '../widgets/guided_line_view.dart';
import '../widgets/guided_panel.dart';
import '../widgets/guided_timeline_bar.dart';

/// `/guided/:id/play`: plays one guided exercise (Plan 3a, Task 5) — the
/// notes of the line playing with the cursor, the "coming up" banner with
/// the explanation and the next variation, the big 3 · 2 · 1 · GO, the
/// whole run as a timeline, live tempo / Teacher / Play along, and a calm
/// end view.
///
/// Desktop first: from [guidedWide] two columns (notes and banner left,
/// timeline and controls right) over the full window ([UncappedContent]);
/// narrower one column like the phone practice screen. Leaving (Back, Esc,
/// Stop) stops the player and pops with a [GuidedPlayResult].
class GuidedPlayScreen extends ConsumerStatefulWidget {
  const GuidedPlayScreen({
    super.key,
    required this.id,
    this.bpm,
    this.teacher,
    this.playAlong,
    this.photo,
  });

  /// From the route: `?bpm=<n>&teacher=<1|0>&along=<1|0>` (what the
  /// preview pushes). Missing values fall back to the exercise's default
  /// tempo and the remembered settings.
  factory GuidedPlayScreen.fromQuery(String id, Map<String, String> query,
      {String? photo}) {
    bool? flag(String k) => switch (query[k]) {
          '1' => true,
          '0' => false,
          _ => null,
        };
    return GuidedPlayScreen(
      id: id,
      bpm: int.tryParse(query['bpm'] ?? ''),
      teacher: flag('teacher'),
      playAlong: flag('along'),
      photo: photo,
    );
  }

  final String id;
  final int? bpm;
  final bool? teacher;
  final bool? playAlong;

  /// Fixed backdrop photo for tests/goldens.
  final String? photo;

  @override
  ConsumerState<GuidedPlayScreen> createState() => _GuidedPlayScreenState();
}

/// What the play screen pops with: tempo and switches as they were when
/// leaving, so the preview shows (and the next Start sends) those.
typedef GuidedPlayResult = ({int bpm, bool teacher, bool along});

class _GuidedPlayScreenState extends ConsumerState<GuidedPlayScreen> {
  late final GuidedExercise? _ex = guidedExerciseById(widget.id);

  // One photo for the whole visit (loading, playing, end view).
  late final String _photo = widget.photo ?? nextBackdrop();

  void _leave([GuidedPlayResult? result]) {
    if (context.canPop()) {
      context.pop(result);
    } else {
      context.go('/library');
    }
  }

  @override
  Widget build(BuildContext context) {
    final ex = _ex;
    Widget simple(Widget child) {
      Widget page = Scaffold(
        backgroundColor: PracticeColors.base,
        body: GuidedBackdrop(playing: false, photo: _photo, child: child),
      );
      if (isDesktopPlatform) {
        page = CallbackShortcuts(
          bindings: {
            const SingleActivator(LogicalKeyboardKey.escape): () => _leave(),
          },
          child: Focus(autofocus: true, child: page),
        );
      }
      return page;
    }

    final Widget screen;
    if (ex == null) {
      screen = simple(_Message(text: 'Exercise not found', onBack: _leave));
    } else {
      screen = ref.watch(guidedRigProvider).when(
            data: (rig) => _PlayPage(
              rig: rig,
              exercise: ex,
              bpm: widget.bpm,
              options: RunOptions(
                teacher: widget.teacher ?? SettingsService.guidedTeacher,
                playAlong: widget.playAlong ?? SettingsService.guidedPlayAlong,
              ),
              photo: _photo,
              onLeave: _leave,
            ),
            loading: () => simple(Stack(
              children: [
                const Center(
                    child: CircularProgressIndicator(
                        color: PracticeColors.accent)),
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    child: IconButton(
                      key: const Key('guided-loading-back'),
                      tooltip: 'Back',
                      onPressed: _leave,
                      icon: const Icon(Icons.arrow_back,
                          color: PracticeColors.textPrimary),
                    ),
                  ),
                ),
              ],
            )),
            error: (e, _) => simple(_Message(
                text: 'Could not load the player: $e', onBack: _leave)),
          );
    }
    return UncappedContent(
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: screen,
      ),
    );
  }
}

class _PlayPage extends StatefulWidget {
  const _PlayPage({
    required this.rig,
    required this.exercise,
    required this.bpm,
    required this.options,
    required this.photo,
    required this.onLeave,
  });

  final GuidedRig rig;
  final GuidedExercise exercise;
  final int? bpm;
  final RunOptions options;
  final String photo;
  final ValueChanged<GuidedPlayResult> onLeave;

  @override
  State<_PlayPage> createState() => _PlayPageState();
}

class _PlayPageState extends State<_PlayPage> {
  late final GuidedRunController _run = GuidedRunController(
    player: widget.rig.player,
    clips: widget.rig.clips,
    exercise: widget.exercise,
    bpm: widget.bpm,
    options: widget.options,
  )..addListener(_changed);

  void _changed() => setState(() {});

  GuidedExercise get _ex => _run.exercise;

  @override
  void initState() {
    super.initState();
    // The preview's Start brought us here: play right away.
    unawaited(_run.start());
  }

  @override
  void dispose() {
    _run
      ..removeListener(_changed)
      ..dispose(); // stops the player
    super.dispose();
  }

  void _leave() {
    unawaited(_run.stop());
    widget.onLeave((
      bpm: _run.bpm,
      teacher: _run.options.teacher,
      along: _run.options.playAlong,
    ));
  }

  void _toggle() {
    if (_run.finished) return;
    unawaited(_run.toggle());
  }

  void _setTeacher(bool v) {
    _run.setOptions(RunOptions(teacher: v, playAlong: _run.options.playAlong));
    unawaited(SettingsService.setGuidedTeacher(v));
  }

  void _setAlong(bool v) {
    _run.setOptions(RunOptions(teacher: _run.options.teacher, playAlong: v));
    unawaited(SettingsService.setGuidedPlayAlong(v));
  }

  // ── What is on screen ────────────────────────────────────────────────

  RunPosition? get _pos {
    final p = _run.position;
    return p == null || p.sectionIndex >= _ex.sections.length ? null : p;
  }

  /// Section whose notes are shown: the one playing; before the first
  /// groove (count-in, an empty intro) the first groove, without cursor.
  int get _nowSection {
    final p = _pos;
    final secs = _ex.sections;
    if (p != null && p.sectionIndex >= 0) {
      final s = secs[p.sectionIndex];
      if (s.line.beats.isNotEmpty) return p.sectionIndex;
    }
    final g = secs.indexWhere((s) => s.kind == SectionKind.groove);
    return g < 0 ? 0 : g;
  }

  bool get _cursorOn {
    final p = _pos;
    return p != null && p.sectionIndex == _nowSection;
  }

  /// The variation coming next while its explanation runs (the groove
  /// right before it); null otherwise.
  int? get _comingVariation {
    final p = _pos;
    if (p == null || p.sectionIndex < 0) return null;
    final secs = _ex.sections;
    final i = p.sectionIndex;
    if (secs[i].kind != SectionKind.groove) return null;
    if (i + 1 >= secs.length || secs[i + 1].kind != SectionKind.variation) {
      return null;
    }
    return i + 1;
  }

  String get _statusLine {
    if (_run.error != null) return 'Stopped — ${_run.error}';
    final p = _pos;
    if (p == null) return _run.running ? 'Get ready…' : 'Stopped';
    return guidedSectionLine(_ex, p);
  }

  List<GuidedTimelineSegment> get _segments => [
        for (final s in _run.plan)
          GuidedTimelineSegment(
            ms: s.ms,
            kind: s.sectionIndex < 0
                ? GuidedSegmentKind.countIn
                : switch (_ex.sections[s.sectionIndex].kind) {
                    SectionKind.variation => GuidedSegmentKind.variation,
                    SectionKind.outro => GuidedSegmentKind.outro,
                    _ => GuidedSegmentKind.groove,
                  },
            label: s.sectionIndex >= 0 &&
                    _ex.sections[s.sectionIndex].kind == SectionKind.variation
                ? 'V${guidedVariationNumber(_ex, s.sectionIndex)}'
                : null,
          ),
      ];

  int? get _currentSegment {
    final p = _pos;
    if (p == null) return null;
    final i = _run.plan.indexWhere((s) => s.sectionIndex == p.sectionIndex);
    return i < 0 ? null : i;
  }

  // ── Build ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    Widget page = Scaffold(
      backgroundColor: PracticeColors.base,
      body: GuidedBackdrop(
        playing: _run.running || _run.finished,
        photo: widget.photo,
        child: _run.finished
            ? _EndView(
                exercise: _ex,
                playedMs: _run.elapsedMs,
                bpm: _run.bpm,
                onAgain: () => unawaited(_run.start()),
                onLibrary: () {
                  unawaited(_run.stop());
                  context.go('/library');
                },
              )
            : LayoutBuilder(
                builder: (context, c) =>
                    guidedWide(c.maxWidth) ? _wide() : _narrow()),
      ),
    );
    if (isDesktopPlatform) {
      page = CallbackShortcuts(
        // The end view only listens to Esc: tempo and switches belong to
        // a run, and Space does not start a new one (Again does).
        bindings: _run.finished
            ? {const SingleActivator(LogicalKeyboardKey.escape): _leave}
            : guidedShortcuts(
                primary: _toggle,
                bumpBpm: _run.bump,
                toggleTeacher: () => _setTeacher(!_run.options.teacher),
                togglePlayAlong: () => _setAlong(!_run.options.playAlong),
                leave: _leave,
              ),
        child: Focus(autofocus: true, child: page),
      );
    }
    // System back leaves like the Back button: stop, pop with the result.
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _leave();
      },
      child: page,
    );
  }

  Widget _header({required bool large}) {
    final total = _run.totalMs;
    final time = Text.rich(
      TextSpan(children: [
        TextSpan(
            text: guidedMmss(_run.elapsedMs),
            style: PracticeTypography.label.copyWith(
                fontSize: large ? 22 : 17,
                color: PracticeColors.textPrimary,
                fontFeatures: const [FontFeature.tabularFigures()])),
        TextSpan(
            text: ' / ~${guidedMmss(total)}',
            style: PracticeTypography.label.copyWith(
                fontSize: large ? 15 : 13,
                color: PracticeColors.textMuted,
                fontFeatures: const [FontFeature.tabularFigures()])),
      ]),
      key: const Key('guided-time'),
    );
    return Row(
      children: [
        IconButton(
          tooltip: 'Back',
          onPressed: _leave,
          constraints: const BoxConstraints.tightFor(width: 44, height: 44),
          icon: const Icon(Icons.arrow_back, color: PracticeColors.textPrimary),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_ex.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: (large
                          ? PracticeTypography.title
                          : PracticeTypography.subtitle)
                      .copyWith(shadows: _shadow)),
              const SizedBox(height: 2),
              Text(_statusLine,
                  key: const Key('guided-status'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: PracticeTypography.label.copyWith(
                      fontSize: large ? 13 : 12,
                      color: _run.error != null
                          ? PracticeColors.struggled
                          : PracticeColors.textSecondary,
                      shadows: _shadow)),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        time,
      ],
    );
  }

  /// "NOW · V2" + the explanation while a variation plays, then the notes
  /// with the cursor and, in the countdown, the big number over them.
  Widget _now({required bool large, double? notesMax}) {
    final si = _nowSection;
    final s = _ex.sections[si];
    final p = _pos;
    final isVar = s.kind == SectionKind.variation && _cursorOn;
    final tag = p == null || p.sectionIndex < 0
        ? 'COUNT-IN'
        : switch (s.kind) {
            SectionKind.variation => 'V${guidedVariationNumber(_ex, si)}',
            SectionKind.outro => 'ENDING',
            _ => 'GROOVE',
          };
    final countdown = p?.countdown;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Text('NOW',
                style: PracticeTypography.label.copyWith(
                    color: PracticeColors.textPrimary, letterSpacing: 1.4)),
            const SizedBox(width: AppSpacing.sm),
            Text(tag,
                style: PracticeTypography.label.copyWith(
                    color: isVar
                        ? PracticeColors.accent
                        : PracticeColors.textMuted)),
          ],
        ),
        if (isVar) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            s.textEn!,
            key: const Key('guided-now-text'),
            style: PracticeTypography.body.copyWith(
                fontSize: large ? 17 : 15,
                height: 1.35,
                color: PracticeColors.textSecondary,
                shadows: _shadow),
          ),
        ],
        const SizedBox(height: AppSpacing.sm),
        Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            KeyedSubtree(
              key: const Key('guided-now'),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.card),
                child: GuidedLineView(
                  exercise: _ex,
                  line: s.line,
                  activeTick: _cursorOn && p != null
                      ? lineTickFor(p, s.line, _ex.gridUnit)
                      : null,
                  maxStaffHeight: notesMax,
                ),
              ),
            ),
            if (countdown != null)
              KeyedSubtree(
                key: const Key('guided-countdown'),
                child: TweenAnimationBuilder<double>(
                  key: ValueKey(countdown),
                  tween: Tween(begin: 0.6, end: 1),
                  duration: const Duration(milliseconds: 160),
                  curve: Curves.easeOutBack,
                  builder: (_, v, child) => Opacity(
                      opacity: ((v - 0.6) / 0.4).clamp(0.0, 1.0),
                      child: Transform.scale(scale: v, child: child)),
                  child: GuidedCountdown(
                      remaining: countdown, size: large ? 150 : 112),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget? _banner({required bool large, double? lineMax}) {
    final i = _comingVariation;
    if (i == null) return null;
    final v = _ex.sections[i];
    return GuidedBanner(
      key: const Key('guided-banner'),
      exercise: _ex,
      variation: guidedVariationNumber(_ex, i),
      text: v.textEn!,
      line: v.line,
      lineMaxHeight: lineMax,
      large: large,
    );
  }

  Widget _playButtons() => Row(
        children: [
          Expanded(
            child: GuidedAccentButton(
              key: const Key('guided-play-toggle'),
              icon: !_run.running || _run.showResume
                  ? Icons.play_arrow_rounded
                  : Icons.pause_rounded,
              label: !_run.running
                  ? 'Start'
                  : _run.showResume
                      ? 'Resume'
                      : 'Pause',
              onPressed: _toggle,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          GuidedGhostButton(
            key: const Key('guided-play-stop'),
            icon: Icons.stop_rounded,
            tooltip: 'Stop',
            onPressed: _leave,
          ),
        ],
      );

  TempoRow get _tempo => TempoRow(
        bpm: _run.bpm,
        onChanged: _run.setBpm,
        step: guidedTempoStep,
        min: _ex.minBpm,
        max: _ex.maxBpm,
      );

  Widget _wide() {
    return Padding(
      key: const Key('guided-wide'),
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.xxl, AppSpacing.lg, AppSpacing.xxl, AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _header(large: true),
          const SizedBox(height: AppSpacing.lg),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: LayoutBuilder(builder: (context, c) {
                    final banner = _comingVariation != null;
                    // Room for the staffs once labels, text and the
                    // banner's own lines are taken off.
                    final room = c.maxHeight - (banner ? 190 : 110);
                    final notesMax = banner
                        ? (room * 0.58).clamp(120.0, 300.0)
                        : room.clamp(140.0, 400.0);
                    final lineMax = (room * 0.42).clamp(90.0, 200.0);
                    final b = _banner(large: true, lineMax: lineMax);
                    return SingleChildScrollView(
                      key: const Key('guided-main-scroll'),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _now(large: true, notesMax: notesMax),
                          if (b != null) ...[
                            const SizedBox(height: AppSpacing.lg),
                            b,
                          ],
                        ],
                      ),
                    );
                  }),
                ),
                const SizedBox(width: AppSpacing.xl),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: GuidedPanel(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              GuidedPanelLabel('SEQUENCE',
                                  trailing: '${_ex.variationCount} VARIATIONS'),
                              Expanded(
                                child: GuidedTimelineBar(
                                  key: const Key('guided-timeline'),
                                  axis: Axis.vertical,
                                  segments: _segments,
                                  progress: _run.progress,
                                  current: _currentSegment,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      GuidedPanel(
                        padding: const EdgeInsets.fromLTRB(
                            AppSpacing.cardPadding,
                            AppSpacing.md,
                            AppSpacing.cardPadding,
                            AppSpacing.xs),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _tempo,
                            const SizedBox(height: AppSpacing.sm),
                            const Divider(height: 1, color: Color(0x1FFFFFFF)),
                            GuidedSwitchRow(
                              key: const Key('guided-teacher'),
                              title: 'Teacher',
                              subtitle: 'A voice explains each variation',
                              value: _run.options.teacher,
                              onChanged: _setTeacher,
                            ),
                            const Divider(height: 1, color: Color(0x1FFFFFFF)),
                            GuidedSwitchRow(
                              key: const Key('guided-along'),
                              title: 'Play along',
                              subtitle: 'Hear the notes played with you',
                              value: _run.options.playAlong,
                              onChanged: _setAlong,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _playButtons(),
                      if (isDesktopPlatform) ...[
                        const SizedBox(height: AppSpacing.sm),
                        const GuidedKeyHint(guidedPlayKeyHint),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _narrow() {
    final b = _banner(large: false, lineMax: 200);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, AppSpacing.sm, 16, 0),
          child: _header(large: false),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg, AppSpacing.md, AppSpacing.lg, 0),
          child: GuidedTimelineBar(
            key: const Key('guided-timeline'),
            segments: _segments,
            progress: _run.progress,
            current: _currentSegment,
          ),
        ),
        // Notes stay at the top: they must not jump when the banner comes
        // and goes. Taller content scrolls.
        Expanded(
          child: SingleChildScrollView(
            key: const Key('guided-main-scroll'),
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg, vertical: AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _now(large: false),
                if (b != null) ...[
                  const SizedBox(height: AppSpacing.lg),
                  b,
                ],
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _tempo,
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: _ToggleChip(
                      key: const Key('guided-teacher'),
                      icon: Icons.record_voice_over_outlined,
                      label: 'Teacher',
                      value: _run.options.teacher,
                      onChanged: _setTeacher,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: _ToggleChip(
                      key: const Key('guided-along'),
                      icon: Icons.music_note_outlined,
                      label: 'Play along',
                      value: _run.options.playAlong,
                      onChanged: _setAlong,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              _playButtons(),
            ],
          ),
        ),
      ],
    );
  }
}

const _shadow = [Shadow(color: Color(0x99000000), blurRadius: 8)];

/// Compact on/off pill for the phone controls (the wide layout uses
/// [GuidedSwitchRow]).
class _ToggleChip extends StatelessWidget {
  const _ToggleChip({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final on = value;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.pill),
        onTap: () => onChanged(!value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            color: on
                ? PracticeColors.accent.withValues(alpha: 0.16)
                : PracticeColors.base.withValues(alpha: 0.55),
            border: Border.all(
                color: on
                    ? PracticeColors.accent.withValues(alpha: 0.7)
                    : PracticeColors.textFaint),
          ),
          child: Row(
            children: [
              Icon(icon,
                  size: 18,
                  color: on ? PracticeColors.accent : PracticeColors.textMuted),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: PracticeTypography.body.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: on
                            ? PracticeColors.textPrimary
                            : PracticeColors.textMuted)),
              ),
              Text(on ? 'ON' : 'OFF',
                  style: PracticeTypography.label.copyWith(
                      color: on
                          ? PracticeColors.accent
                          : PracticeColors.textMuted)),
            ],
          ),
        ),
      ),
    );
  }
}

/// The end of the run: calm, centered on the backdrop. No measurements yet
/// (Plan 3b).
class _EndView extends StatelessWidget {
  const _EndView({
    required this.exercise,
    required this.playedMs,
    required this.bpm,
    required this.onAgain,
    required this.onLibrary,
  });

  final GuidedExercise exercise;
  final double playedMs;
  final int bpm;
  final VoidCallback onAgain;
  final VoidCallback onLibrary;

  @override
  Widget build(BuildContext context) {
    return Center(
      key: const Key('guided-end'),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: GuidedPanel(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.xl, AppSpacing.xxl, AppSpacing.xl, AppSpacing.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: PracticeColors.accent.withValues(alpha: 0.14),
                      border: Border.all(
                          color: PracticeColors.accent.withValues(alpha: 0.6),
                          width: 2),
                    ),
                    child: const Icon(Icons.check_rounded,
                        size: 34, color: PracticeColors.accent),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text('Done',
                    textAlign: TextAlign.center,
                    style: PracticeTypography.display),
                const SizedBox(height: AppSpacing.xs),
                Text(exercise.name,
                    textAlign: TextAlign.center,
                    style: PracticeTypography.subtitle
                        .copyWith(color: PracticeColors.textSecondary)),
                const SizedBox(height: AppSpacing.xl),
                Row(
                  children: [
                    Expanded(
                        child: _Stat(
                            label: 'PLAYED', value: guidedMmss(playedMs))),
                    Container(
                        width: 1, height: 44, color: const Color(0x1FFFFFFF)),
                    Expanded(
                        child:
                            _Stat(label: 'TEMPO', value: '$bpm', unit: 'BPM')),
                  ],
                ),
                const SizedBox(height: AppSpacing.xl),
                GuidedAccentButton(
                  key: const Key('guided-again'),
                  icon: Icons.replay_rounded,
                  label: 'Again',
                  onPressed: onAgain,
                ),
                const SizedBox(height: AppSpacing.md),
                GuidedGhostButton(
                  key: const Key('guided-back-library'),
                  icon: Icons.library_music_outlined,
                  label: 'Back to library',
                  onPressed: onLibrary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value, this.unit});
  final String label;
  final String value;
  final String? unit;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label,
            style: PracticeTypography.label
                .copyWith(color: PracticeColors.textMuted)),
        const SizedBox(height: AppSpacing.xs),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(value,
                style: PracticeTypography.numericXl
                    .copyWith(fontSize: 34, height: 1)),
            if (unit != null) ...[
              const SizedBox(width: 6),
              Text(unit!,
                  style: PracticeTypography.label
                      .copyWith(color: PracticeColors.textMuted)),
            ],
          ],
        ),
      ],
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.text, required this.onBack});
  final String text;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(text,
                  textAlign: TextAlign.center, style: PracticeTypography.title),
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
