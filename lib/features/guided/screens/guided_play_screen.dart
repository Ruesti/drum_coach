import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/design_tokens.dart';
import '../../../app/platform_support.dart';
import '../../../app/theme.dart';
import '../../../data/local/settings_service.dart';
import '../../practice/backdrop.dart';
import '../../practice/widgets/tempo_row.dart';
import '../data/guided_lookup.dart';
import '../guided_format.dart';
import '../guided_pages.dart';
import '../guided_rig_provider.dart';
import '../guided_run_controller.dart';
import '../guided_shortcuts.dart';
import '../models/guided_exercise.dart';
import '../run_clock.dart';
import '../run_plan.dart';
import '../widgets/guided_backdrop.dart';
import '../widgets/guided_banner.dart';
import '../widgets/guided_layout.dart';
import '../widgets/guided_page_view.dart';
import '../widgets/guided_panel.dart';
import '../widgets/guided_stage.dart';
import '../widgets/guided_timeline_bar.dart';

/// `/guided/:id/play`: plays one guided exercise in the Drumeo-lesson look
/// (Spec 2026-10-29, Teil 1.3): the photo stage on top (title, bar count,
/// "coming up", teacher banner, 3 · 2 · 1 · GO), the white sheet with the
/// page being played (four written-out bars, blue playhead) and the next
/// page dimmed under it, and one dark control bar (play, time, timeline,
/// tempo, Teacher, Play along, keys). Pages turn with the first beat of
/// the next page, no scrolling.
///
/// From [guidedWide] on over the full window ([UncappedContent]); narrower
/// the stage is a strip, the pages have two bars and the controls stack as
/// on the phone practice screen. Leaving (Back, Esc, Stop) stops the player
/// and pops with a [GuidedPlayResult].
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
    // The whole window: the photo fills it, the content keeps only the
    // gutters (Uli 27.10., round 2).
    return UncappedContent(
      maxWidth: double.infinity,
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

  // The pages only change at a page turn (or a new plan): cut them out of
  // the line once, not on every playhead step.
  Object? _pagesKey;
  ({GuidedPage now, GuidedPage? next})? _pagesCache;

  /// The page being played and the one after it, [pageBars] bars each.
  ({GuidedPage now, GuidedPage? next}) _pages(int pageBars) {
    final p = _pos;
    final inRun = p != null && p.sectionIndex >= 0;
    final key = (
      inRun ? p.sectionIndex : -1,
      inRun ? p.barInSection ~/ pageBars : 0,
      pageBars,
      _run.plan,
    );
    if (key != _pagesKey || _pagesCache == null) {
      _pagesKey = key;
      _pagesCache = guidedPagesAt(_ex, _run.plan, p, pageBars: pageBars);
    }
    return _pagesCache!;
  }

  /// `Groove`, `Variation 2 · Kick on the 16ths`, `Ending`.
  String _pageName(GuidedPage page) {
    final s = _ex.sections[page.sectionIndex];
    return switch (s.kind) {
      SectionKind.variation =>
        'Variation ${guidedVariationNumber(_ex, page.sectionIndex)}'
            '${s.titleEn == null ? '' : ' · ${s.titleEn}'}',
      SectionKind.outro => 'Ending',
      SectionKind.intro => 'Intro',
      SectionKind.groove => 'Groove',
    };
  }

  /// `Bar 3 / 8`: bar in the section and its length from the plan; null in
  /// the count-in.
  String? get _barCount {
    final p = _pos;
    if (p == null || p.sectionIndex < 0) return null;
    final bars = _run.plan
        .where((s) => s.sectionIndex == p.sectionIndex)
        .fold<int>(0, (n, s) => n + s.bars);
    if (bars <= 0) return null;
    return 'Bar ${p.barInSection + 1} / $bars';
  }

  // ── Build ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    Widget page = Scaffold(
      backgroundColor: PracticeColors.base,
      body: Theme(
        data: drumCoachPracticeTheme,
        child: Material(
          color: Colors.transparent,
          child: _run.finished
              ? GuidedStage(
                  key: const Key('guided-stage'),
                  photo: widget.photo,
                  child: _EndView(
                    exercise: _ex,
                    playedMs: _run.elapsedMs,
                    bpm: _run.bpm,
                    onAgain: () => unawaited(_run.start()),
                    onLibrary: () {
                      unawaited(_run.stop());
                      context.go('/library');
                    },
                  ),
                )
              : LayoutBuilder(
                  builder: (context, c) => guidedWide(c.maxWidth)
                      ? _wide(c.biggest)
                      : _narrow(c.biggest)),
        ),
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

  Widget get _backButton => IconButton(
        tooltip: 'Back',
        onPressed: _leave,
        constraints: const BoxConstraints.tightFor(width: 44, height: 44),
        icon: const Icon(Icons.arrow_back, color: PracticeColors.textPrimary),
      );

  Text _status({required double fontSize}) => Text(_statusLine,
      key: const Key('guided-status'),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: PracticeTypography.label.copyWith(
          fontSize: fontSize,
          color: _run.error != null
              ? PracticeColors.struggled
              : PracticeColors.textSecondary,
          shadows: _shadow));

  /// Phone header on the stage strip: back, name, status, time.
  Widget _narrowHeader() {
    final time = Text.rich(
      TextSpan(children: [
        TextSpan(
            text: guidedMmss(_run.elapsedMs),
            style: PracticeTypography.label.copyWith(
                fontSize: 17,
                color: PracticeColors.textPrimary,
                shadows: _shadow,
                fontFeatures: const [FontFeature.tabularFigures()])),
        TextSpan(
            text: ' / ~${guidedMmss(_run.totalMs)}',
            style: PracticeTypography.label.copyWith(
                fontSize: 13,
                color: PracticeColors.textSecondary,
                shadows: _shadow,
                fontFeatures: const [FontFeature.tabularFigures()])),
      ]),
      key: const Key('guided-time'),
    );
    return Row(
      children: [
        _backButton,
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_ex.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style:
                      PracticeTypography.subtitle.copyWith(shadows: _shadow)),
              const SizedBox(height: 2),
              _status(fontSize: 12),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        time,
      ],
    );
  }

  Widget _countdown(int countdown, {required double size}) => KeyedSubtree(
        key: const Key('guided-countdown'),
        child: TweenAnimationBuilder<double>(
          key: ValueKey(countdown),
          tween: Tween(begin: 0.6, end: 1),
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOutBack,
          builder: (_, v, child) => Opacity(
              opacity: ((v - 0.6) / 0.4).clamp(0.0, 1.0),
              child: Transform.scale(scale: v, child: child)),
          child: GuidedCountdown(remaining: countdown, size: size),
        ),
      );

  /// "Coming up" with the next variation's explanation. On the stage
  /// without the notes ([showLine] false): they are on the sheet.
  Widget? _banner({required bool large, required bool showLine}) {
    final i = _comingVariation;
    if (i == null) return null;
    final v = _ex.sections[i];
    return GuidedBanner(
      key: const Key('guided-banner'),
      exercise: _ex,
      variation: guidedVariationNumber(_ex, i),
      text: v.textEn!,
      line: v.line,
      lineMaxHeight: 200,
      large: large,
      showLine: showLine,
    );
  }

  /// The white sheet: the page being played (with the blue playhead) and,
  /// dimmed under it, the next one, each with its label. Pages turn
  /// without scrolling; the sheet keeps its height when no next page is
  /// left (the outro).
  Widget _sheet({
    required int pageBars,
    required double pageMax,
    required double gutter,
    required double labelSize,
  }) {
    final pages = _pages(pageBars);
    final p = _pos;
    final countIn = p == null || p.sectionIndex < 0;
    final labelStyle = PracticeTypography.label.copyWith(
        fontSize: labelSize,
        height: 1.2,
        letterSpacing: 0.6,
        color: const Color(0xFF1C1C1C));
    Widget label(String key, String text, {bool dim = false}) => Padding(
          padding: const EdgeInsets.only(bottom: 2),
          child: Text(text,
              key: Key(key),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: dim
                  ? labelStyle.copyWith(color: const Color(0xFF8A8A8A))
                  : labelStyle),
        );
    Widget view(GuidedPage page, {int? tick, bool dimmed = false}) =>
        RepaintBoundary(
          child: GuidedPageView(
            exercise: _ex,
            page: page,
            activeTick: tick,
            dimmed: dimmed,
            maxStaffHeight: pageMax,
            fullPageBars: pageBars,
          ),
        );

    final next = pages.next;
    return ColoredBox(
      key: const Key('guided-sheet'),
      color: Colors.white,
      child: Padding(
        padding: EdgeInsets.fromLTRB(gutter, AppSpacing.sm, gutter, 0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            label('guided-label-now',
                countIn ? 'Count-in' : 'Now · ${_pageName(pages.now)}'),
            KeyedSubtree(
              key: const Key('guided-now'),
              child: view(pages.now,
                  tick: countIn ? null : guidedPageTick(pages.now, p)),
            ),
            // Air between the kick stems above and the next label.
            const SizedBox(height: AppSpacing.sm),
            if (next != null) ...[
              label('guided-label-next', 'Next · ${_pageName(next)}',
                  dim: true),
              KeyedSubtree(
                key: const Key('guided-next'),
                child: view(next, dimmed: true),
              ),
            ] else
              // Same height as a next page: the stage does not jump.
              Visibility(
                visible: false,
                maintainSize: true,
                maintainAnimation: true,
                maintainState: true,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [label('guided-label-spare', ''), view(pages.now)],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _playButtons({double? toggleWidth}) {
    final toggle = GuidedAccentButton(
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
    );
    return Row(
      children: [
        if (toggleWidth == null)
          Expanded(child: toggle)
        else
          SizedBox(width: toggleWidth, child: toggle),
        const SizedBox(width: AppSpacing.sm),
        GuidedGhostButton(
          key: const Key('guided-play-stop'),
          icon: Icons.stop_rounded,
          tooltip: 'Stop',
          onPressed: _leave,
        ),
      ],
    );
  }

  TempoRow get _tempo => TempoRow(
        bpm: _run.bpm,
        onChanged: _run.setBpm,
        step: guidedTempoStep,
        min: _ex.minBpm,
        max: _ex.maxBpm,
      );

  GuidedTimelineBar get _timeline => GuidedTimelineBar(
        key: const Key('guided-timeline'),
        segments: _segments,
        progress: _run.progress,
        current: _currentSegment,
      );

  // Control bar widths (wide).
  static const _toggleW = 156.0;
  static const _tempoW = 220.0;
  static const _teacherW = 136.0;
  static const _alongW = 156.0;
  static const _controlsPad = 8.0;

  /// Width the control bar needs without the timeline and the key hint.
  static const _controlsFixed = 2 * AppSpacing.screenPadding +
      _toggleW +
      AppSpacing.sm +
      56 +
      AppSpacing.lg +
      48 +
      2 * AppSpacing.md +
      56 +
      AppSpacing.lg +
      _tempoW +
      AppSpacing.md +
      _teacherW +
      AppSpacing.sm +
      _alongW;

  /// Most of the window height the sheet may take (wide layout).
  static const _sheetShare = 0.5;

  /// The timeline keeps at least this much before the key hint moves
  /// from the control bar onto the stage.
  static const _minTimeline = 360.0;

  /// Wide layout (Drumeo lesson): photo stage on top, the white sheet with
  /// two four-bar pages, the dark control bar in one row at the bottom.
  Widget _wide(Size size) {
    final hintW = isDesktopPlatform
        ? GuidedKeyHint.widthOf(context, guidedPlayKeyHint)
        : 0.0;
    final hintInBar = isDesktopPlatform &&
        size.width - _controlsFixed - AppSpacing.lg - hintW >= _minTimeline;
    final hintOnStage = isDesktopPlatform && !hintInBar;
    // Sheet: at most half the window for two pages and their labels — the
    // spec's fixed rule (staff readable at 1920x1080) beats the 38 %
    // Richtwert. Pages that are wider than high take less (the sheet is
    // only as high as its pages), the stage gets the rest.
    final labelSize = size.height >= 1000 ? 14.0 : 13.0;
    final pageMax = ((_sheetShare * size.height -
                2 * AppSpacing.sm -
                2 * (labelSize * 1.2 + 2)) /
            2)
        .clamp(90.0, 420.0);
    return Column(
      key: const Key('guided-wide'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: GuidedStage(
            key: const Key('guided-stage'),
            photo: widget.photo,
            child: _wideStage(hint: hintOnStage),
          ),
        ),
        _sheet(
          pageBars: 4,
          pageMax: pageMax,
          gutter: AppSpacing.screenPadding,
          labelSize: labelSize,
        ),
        _wideControls(hint: hintInBar),
      ],
    );
  }

  /// Overlays of the wide stage: title top left, bar count and "coming up"
  /// top right, banner and countdown bottom centre.
  Widget _wideStage({required bool hint}) {
    final p = _pos;
    final countdown = p?.countdown;
    final banner = _banner(large: true, showLine: false);
    final coming = _comingVariation;
    final barCount = _barCount;
    final tag = '${_ex.package == GuidedPackage.kit ? 'SET' : 'PAD'}'
        ' · ${_ex.difficulty.label.toUpperCase()}';
    return Stack(
      children: [
        Positioned(
          left: AppSpacing.sm,
          top: AppSpacing.md,
          right: AppSpacing.screenPadding + 320,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _backButton,
              const SizedBox(width: AppSpacing.sm),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(tag,
                        style: PracticeTypography.label.copyWith(
                            color: PracticeColors.accent,
                            letterSpacing: 1.4,
                            shadows: _shadow)),
                    const SizedBox(height: 2),
                    Text(_ex.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: PracticeTypography.title
                            .copyWith(shadows: _shadow)),
                    const SizedBox(height: 2),
                    _status(fontSize: 14),
                  ],
                ),
              ),
            ],
          ),
        ),
        Positioned(
          right: AppSpacing.screenPadding,
          top: AppSpacing.md + 4,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 320),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (barCount != null)
                  Text(barCount,
                      key: const Key('guided-bar-count'),
                      style: PracticeTypography.label.copyWith(
                          fontSize: 20,
                          color: PracticeColors.textPrimary,
                          shadows: _shadow,
                          fontFeatures: const [FontFeature.tabularFigures()])),
                if (coming != null) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                      'Coming up: ${_ex.sections[coming].titleEn ?? 'Variation ${guidedVariationNumber(_ex, coming)}'}',
                      key: const Key('guided-coming-up'),
                      textAlign: TextAlign.right,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: PracticeTypography.label.copyWith(
                          fontSize: 14,
                          color: PracticeColors.accent,
                          shadows: _shadow)),
                ],
              ],
            ),
          ),
        ),
        if (banner != null || countdown != null)
          Positioned(
            left: AppSpacing.screenPadding,
            right: AppSpacing.screenPadding,
            bottom: AppSpacing.lg,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                // Side by side: a low stage (1280x720) keeps most of the
                // photo free.
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (countdown != null) _countdown(countdown, size: 96),
                    if (countdown != null && banner != null)
                      const SizedBox(width: AppSpacing.md),
                    if (banner != null) Flexible(child: banner),
                  ],
                ),
              ),
            ),
          ),
        if (hint)
          const Positioned(
            right: AppSpacing.screenPadding,
            bottom: AppSpacing.md,
            child: GuidedKeyHint(guidedPlayKeyHint),
          ),
      ],
    );
  }

  /// One dark row: Play/Pause + Stop, time, the timeline, total, tempo,
  /// Teacher, Play along and (when it fits) the key hint.
  Widget _wideControls({required bool hint}) {
    final tabular = const [FontFeature.tabularFigures()];
    return Container(
      key: const Key('guided-controls'),
      color: PracticeColors.inset,
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.screenPadding, vertical: _controlsPad),
      child: Row(
        children: [
          _playButtons(toggleWidth: _toggleW),
          const SizedBox(width: AppSpacing.lg),
          SizedBox(
            width: 48,
            child: Text(guidedMmss(_run.elapsedMs),
                key: const Key('guided-time'),
                textAlign: TextAlign.right,
                style: PracticeTypography.label.copyWith(
                    fontSize: 16,
                    color: PracticeColors.textPrimary,
                    fontFeatures: tabular)),
          ),
          const SizedBox(width: AppSpacing.md),
          // The bar's labels hang under the track: centre the track.
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 14),
              child: _timeline,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          SizedBox(
            width: 56,
            child: Text('~${guidedMmss(_run.totalMs)}',
                key: const Key('guided-total'),
                style: PracticeTypography.label.copyWith(
                    fontSize: 14,
                    color: PracticeColors.textMuted,
                    fontFeatures: tabular)),
          ),
          const SizedBox(width: AppSpacing.lg),
          SizedBox(width: _tempoW, child: _tempo),
          const SizedBox(width: AppSpacing.md),
          SizedBox(width: _teacherW, child: _teacherChip),
          const SizedBox(width: AppSpacing.sm),
          SizedBox(width: _alongW, child: _alongChip),
          if (hint) ...[
            const SizedBox(width: AppSpacing.lg),
            const GuidedKeyHint(guidedPlayKeyHint),
          ],
        ],
      ),
    );
  }

  Widget get _teacherChip => _ToggleChip(
        key: const Key('guided-teacher'),
        icon: Icons.record_voice_over_outlined,
        label: 'Teacher',
        value: _run.options.teacher,
        onChanged: _setTeacher,
      );

  Widget get _alongChip => _ToggleChip(
        key: const Key('guided-along'),
        icon: Icons.music_note_outlined,
        label: 'Play along',
        value: _run.options.playAlong,
        onChanged: _setAlong,
      );

  /// Phone and narrow windows: the stage as a strip with the title, the
  /// timeline, the sheet with two 2-bar pages, banner / explanation, and
  /// the controls as before at the bottom.
  Widget _narrow(Size size) {
    final p = _pos;
    final countdown = p?.countdown;
    final b = _banner(large: false, showLine: false);
    final s =
        p == null || p.sectionIndex < 0 ? null : _ex.sections[p.sectionIndex];
    final varText =
        s != null && s.kind == SectionKind.variation ? s.textEn : null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 0.3 * size.height,
          child: GuidedStage(
            key: const Key('guided-stage'),
            photo: widget.photo,
            child: Stack(
              children: [
                SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(4, AppSpacing.sm, 16, 0),
                    child: _narrowHeader(),
                  ),
                ),
                if (countdown != null)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: AppSpacing.md,
                    child: Center(child: _countdown(countdown, size: 96)),
                  ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg, AppSpacing.md, AppSpacing.lg, 0),
          child: _timeline,
        ),
        // The sheet stays on top: it must not jump when the banner comes
        // and goes. Taller content scrolls.
        Expanded(
          child: SingleChildScrollView(
            key: const Key('guided-main-scroll'),
            padding: const EdgeInsets.only(top: AppSpacing.sm),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _sheet(
                  pageBars: 2,
                  pageMax: 130,
                  gutter: AppSpacing.md,
                  labelSize: 12,
                ),
                if (varText != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                        AppSpacing.lg, AppSpacing.md, AppSpacing.lg, 0),
                    child: Text(
                      varText,
                      key: const Key('guided-now-text'),
                      style: PracticeTypography.body.copyWith(
                          fontSize: 15,
                          height: 1.35,
                          color: PracticeColors.textSecondary),
                    ),
                  ),
                if (b != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                        AppSpacing.lg, AppSpacing.md, AppSpacing.lg, 0),
                    child: b,
                  ),
                const SizedBox(height: AppSpacing.md),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _tempo,
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(child: _teacherChip),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(child: _alongChip),
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

/// Compact on/off pill for the controls (phone and the wide bottom bar).
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
