import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../content/analysis.dart';
import '../content/exercises.dart';
import '../measure/session_record.dart';
import '../skill/gate.dart';
import 'lane_view.dart';

/// What the `/feedback` route gets via go_router `extra`: the saved record
/// (the lane view needs stroke velocities), its analysis and the file path.
class FeedbackArgs {
  const FeedbackArgs(
      {required this.record, required this.analysis, required this.path});

  final SessionRecord record;
  final SessionAnalysis analysis;
  final String path;
}

String bannerText(GateResult g) => switch (g.status) {
      GateStatus.passed => 'PASSED',
      GateStatus.failed => 'NOT PASSED',
      GateStatus.notMeasurable => g.reason == 'no-strokes'
          ? 'NOT MEASURABLE (no hits received)'
          : 'NOT MEASURABLE (calibrate first)',
    };

/// Rates (hit, wrong, extra) are fractions; shown as percent.
bool _isRate(GateCriterion c) =>
    c.id.startsWith('hitRate.') || c.id == 'wrongRate' || c.id == 'extraRate';

String _value(GateCriterion c, double v) =>
    _isRate(c) ? '${(v * 100).toStringAsFixed(1)} %' : v.toStringAsFixed(1);

/// The one feedback view: verdict, lane view, gate table, file path.
class FeedbackScreen extends StatelessWidget {
  const FeedbackScreen({super.key, required this.args});

  final FeedbackArgs args;

  @override
  Widget build(BuildContext context) {
    final a = args.analysis;
    final gate = a.gate;
    final scheme = Theme.of(context).colorScheme;
    final bannerColor = switch (gate.status) {
      GateStatus.passed => laneOnTime,
      GateStatus.failed => laneMissed,
      GateStatus.notMeasurable => laneExtra,
    };
    return Scaffold(
      appBar: AppBar(
        title: Text(a.exercise.title),
        automaticallyImplyLeading: false,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            decoration: BoxDecoration(
              color: bannerColor.withValues(alpha: 0.2),
              border: Border.all(color: bannerColor),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(bannerText(gate),
                style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: bannerColor)),
          ),
          if (a.exercise.id == entryExercise.id &&
              gate.status == GateStatus.failed)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text('Start with the basics first'),
            ),
          const SizedBox(height: 20),
          LaneView(analysis: a, record: args.record),
          const SizedBox(height: 20),
          for (final c in gate.criteria) GateRow(criterion: c),
          const SizedBox(height: 20),
          Text(args.path,
              style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12)),
          const SizedBox(height: 16),
          Row(
            children: [
              OutlinedButton(
                  onPressed: () => context.go('/'), child: const Text('Home')),
              const SizedBox(width: 12),
              FilledButton(
                  onPressed: () => context.go('/run/${a.exercise.id}'),
                  child: const Text('Again')),
            ],
          ),
        ],
      ),
    );
  }
}

/// One gate criterion: label, actual (1 decimal), threshold with ≤/≥, ✓/✗.
class GateRow extends StatelessWidget {
  const GateRow({super.key, required this.criterion});

  final GateCriterion criterion;

  @override
  Widget build(BuildContext context) {
    final c = criterion;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(c.label)),
          SizedBox(
            width: 90,
            child: Text(c.actual == null ? '–' : _value(c, c.actual!),
                textAlign: TextAlign.right),
          ),
          SizedBox(
            width: 100,
            child: Text('${c.atMost ? '≤' : '≥'} ${_value(c, c.threshold)}',
                textAlign: TextAlign.right),
          ),
          SizedBox(
            width: 32,
            child: Text(c.passed ? '✓' : '✗',
                textAlign: TextAlign.right,
                style: TextStyle(color: c.passed ? laneOnTime : laneMissed)),
          ),
        ],
      ),
    );
  }
}
