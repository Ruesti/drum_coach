import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/design_tokens.dart';
import '../../app/platform_support.dart';
import '../../app/theme.dart';
import '../practice/practice_shortcuts.dart';
import 'data/demo_exercise.dart';
import 'data/guided_catalog.dart';
import 'guided_format.dart';
import 'guided_player.dart';
import 'guided_rig_provider.dart';
import 'guided_run_controller.dart';
import 'models/guided_exercise.dart';
import 'run_plan.dart';

/// Tempo step of the ± buttons and keys.
const int guidedBpmStep = 4;

/// `Name · Difficulty · ~m:ss`: planned length at the default tempo, without
/// the planner's extension for long explanations (same as the curation page).
String guidedExerciseLabel(GuidedExercise ex) =>
    '${ex.name} · ${ex.difficulty.label} · ${guidedDurationLabel(ex)}';

/// Dropdown entries: the two demos, then the catalog, Set before Pad, each
/// group under a disabled header.
List<DropdownMenuItem<GuidedExercise>> _exerciseItems() {
  DropdownMenuItem<GuidedExercise> header(String t) => DropdownMenuItem(
        enabled: false,
        child: Text(t,
            style: const TextStyle(
                fontSize: 12,
                letterSpacing: 1.2,
                color: PracticeColors.textMuted)),
      );
  DropdownMenuItem<GuidedExercise> item(GuidedExercise ex) => DropdownMenuItem(
        key: ValueKey('guided-exercise-${ex.id}'),
        value: ex,
        child: Text(guidedExerciseLabel(ex), overflow: TextOverflow.ellipsis),
      );
  return [
    header('DEMOS'),
    item(demoKitExercise),
    item(demoPadExercise),
    for (final (title, package) in [
      ('SET', GuidedPackage.kit),
      ('PAD', GuidedPackage.pad),
    ]) ...[
      header(title),
      for (final ex in guidedCatalog)
        if (ex.package == package) item(ex),
    ],
  ];
}

/// Hidden listening page (`/debug/guided`, long press on the version line
/// in Settings): plays a whole guided exercise (demo or catalog) — count-in, crash,
/// groove, explanation, countdown, variations, outro crash.
class DebugGuidedScreen extends ConsumerWidget {
  const DebugGuidedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rig = ref.watch(guidedRigProvider);
    return Theme(
      data: drumCoachPracticeTheme,
      child: rig.when(
        data: (r) => _GuidedPage(rig: r),
        loading: () =>
            const Scaffold(body: Center(child: CircularProgressIndicator())),
        error: (e, _) => Scaffold(
          appBar: AppBar(title: const Text('Guided demo')),
          body: Center(
            child: Text('Could not load the player: $e',
                style: const TextStyle(color: PracticeColors.struggled)),
          ),
        ),
      ),
    );
  }
}

class _GuidedPage extends StatefulWidget {
  const _GuidedPage({required this.rig});
  final GuidedRig rig;

  @override
  State<_GuidedPage> createState() => _GuidedPageState();
}

class _GuidedPageState extends State<_GuidedPage> {
  late final GuidedRunController _run = GuidedRunController(
    player: widget.rig.player,
    clips: widget.rig.clips,
    exercise: demoKitExercise,
  )..addListener(_changed);

  void _changed() => setState(() {});

  @override
  void initState() {
    super.initState();
    assert(() {
      GuidedPlayer.debugLogRenderTimes = true;
      return true;
    }());
  }

  @override
  void dispose() {
    _run
      ..removeListener(_changed)
      ..dispose();
    assert(() {
      GuidedPlayer.debugLogRenderTimes = false;
      return true;
    }());
    super.dispose();
  }

  GuidedExercise get _ex => _run.exercise;
  int get _bpm => _run.bpm;
  RunOptions get _options => _run.options;
  bool get _running => _run.running;
  bool get _showResume => _run.showResume;
  String? get _error => _run.error;

  Future<void> _toggle() => _run.toggle();
  Future<void> _stop() => _run.stop();
  void _bump(int delta) => _run.bump(delta);
  void _setOptions(RunOptions o) => _run.setOptions(o);
  void _choose(GuidedExercise ex) => _run.choose(ex);

  @override
  Widget build(BuildContext context) {
    final pos = _run.position;
    final text = guidedVariationText(_ex, pos?.sectionIndex ?? -1);
    final total = _run.totalMs;
    final elapsed = _run.elapsedMs;
    final scaffold = Scaffold(
      appBar: AppBar(title: const Text('Guided demo')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_error != null) ...[
            Text('Error: $_error',
                key: const ValueKey('guided-error'),
                style: const TextStyle(color: PracticeColors.struggled)),
            const SizedBox(height: 12),
          ],
          InputDecorator(
            decoration: const InputDecoration(
              labelText: 'Exercise',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<GuidedExercise>(
                key: const ValueKey('guided-exercise'),
                isExpanded: true,
                value: _ex,
                items: _exerciseItems(),
                onChanged: _running
                    ? null
                    : (ex) {
                        if (ex != null) _choose(ex);
                      },
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(_ex.description,
              style: const TextStyle(color: PracticeColors.textMuted)),
          const SizedBox(height: 16),
          Row(
            children: [
              IconButton.filledTonal(
                key: const ValueKey('guided-bpm-down'),
                tooltip: 'Slower',
                onPressed: () => _bump(-guidedBpmStep),
                icon: const Icon(Icons.remove),
              ),
              Expanded(
                child: Column(
                  children: [
                    Text('$_bpm',
                        style: const TextStyle(
                            fontSize: 40, fontWeight: FontWeight.w600)),
                    Text('BPM · ${_ex.minBpm}–${_ex.maxBpm}',
                        style:
                            const TextStyle(color: PracticeColors.textMuted)),
                  ],
                ),
              ),
              IconButton.filledTonal(
                key: const ValueKey('guided-bpm-up'),
                tooltip: 'Faster',
                onPressed: () => _bump(guidedBpmStep),
                icon: const Icon(Icons.add),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  key: const ValueKey('guided-start'),
                  style: FilledButton.styleFrom(
                      backgroundColor: PracticeColors.accent,
                      padding: const EdgeInsets.symmetric(vertical: 16)),
                  onPressed: _toggle,
                  icon: Icon(!_running || _showResume
                      ? Icons.play_arrow
                      : Icons.pause),
                  label: Text(!_running
                      ? 'Start'
                      : _showResume
                          ? 'Resume'
                          : 'Pause'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  key: const ValueKey('guided-stop'),
                  style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16)),
                  onPressed: _running ? _stop : null,
                  icon: const Icon(Icons.stop),
                  label: const Text('Stop'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            key: const ValueKey('guided-teacher'),
            contentPadding: EdgeInsets.zero,
            title: const Text('Teacher'),
            subtitle: const Text('Voice: count-in, explanations, countdown'),
            value: _options.teacher,
            onChanged: (v) => _setOptions(
                RunOptions(teacher: v, playAlong: _options.playAlong)),
          ),
          SwitchListTile(
            key: const ValueKey('guided-playalong'),
            contentPadding: EdgeInsets.zero,
            title: const Text('Play along'),
            subtitle: const Text('Off: only a quarter click'),
            value: _options.playAlong,
            onChanged: (v) => _setOptions(
                RunOptions(teacher: _options.teacher, playAlong: v)),
          ),
          const Divider(height: 32),
          Text(
              pos == null
                  ? (_running ? 'Starting…' : 'Stopped')
                  : guidedStatusLine(_ex, pos),
              key: const ValueKey('guided-status'),
              style: const TextStyle(fontSize: 16)),
          const SizedBox(height: 12),
          if (text != null) ...[
            Text(text.coming ? 'COMING UP' : 'NOW',
                style: const TextStyle(
                    fontSize: 12,
                    letterSpacing: 1.2,
                    color: PracticeColors.textMuted)),
            const SizedBox(height: 4),
            Text(text.text,
                key: const ValueKey('guided-text'),
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: text.coming
                        ? PracticeColors.textSecondary
                        : PracticeColors.live)),
          ],
          const SizedBox(height: 16),
          LinearProgressIndicator(
            value: _run.progress,
            minHeight: 6,
            color: PracticeColors.accent,
            backgroundColor: PracticeColors.raised,
          ),
          const SizedBox(height: 6),
          Text('${guidedMmss(elapsed)} / ~${guidedMmss(total)}',
              style: const TextStyle(color: PracticeColors.textMuted)),
          if (isDesktopPlatform) ...[
            const SizedBox(height: 24),
            const Text('Keys: Space start/pause · ↑↓ or +/− tempo · Esc stop',
                style: TextStyle(color: PracticeColors.textFaint)),
          ],
        ],
      ),
    );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: isDesktopPlatform
          ? CallbackShortcuts(
              bindings: practiceShortcuts(
                toggle: () => unawaited(_toggle()),
                bumpBpm: (d) => _bump(d.sign * guidedBpmStep),
                leave: () {
                  if (_running) {
                    unawaited(_stop());
                  } else {
                    unawaited(Navigator.maybePop(context));
                  }
                },
              ),
              child: Focus(autofocus: true, child: scaffold),
            )
          : scaffold,
    );
  }
}
