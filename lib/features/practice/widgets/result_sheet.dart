import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../app/design_tokens.dart';
import '../../../data/local/models/session_log.dart';
import '../../coaching/models/session_analysis.dart';
import '../../coaching/widgets/coach_feedback_card.dart';
import '../analysis_announcement.dart';
import '../core_values.dart';

/// The coach verdict as a banner nobody can miss — the faint inline line
/// was overlooked outright (14.09.). Light-theme colours (result sheet).
class VerdictBanner extends StatelessWidget {
  const VerdictBanner({super.key, required this.announcement});
  final Announcement announcement;

  @override
  Widget build(BuildContext context) {
    final color =
        announcement.positive ? AppColors.solidStreak : AppColors.accent;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: color, width: 1.2),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            announcement.positive
                ? Icons.check_circle_outline
                : Icons.report_gmailerrorred_outlined,
            size: 20,
            color: color,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(announcement.text,
                style: AppTypography.body.copyWith(
                    color: color, fontWeight: FontWeight.w700, height: 1.3)),
          ),
        ],
      ),
    );
  }
}

/// The one light result sheet (K2 step 3, decided 15.09.): verdict banner,
/// the self-rating right under it, three plain-language core values,
/// everything else behind "Measurement details".
class ResultSheet extends StatefulWidget {
  const ResultSheet({
    super.key,
    required this.rudimentName,
    required this.bpm,
    required this.durationSeconds,
    required this.analysisMode,
    required this.analysis,
    required this.announcement,
    required this.ladderResult,
    required this.sessionLog,
    required this.coachFeedback,
    required this.coachLoading,
    required this.coachEnabled,
    required this.onRate,
    required this.onDone,
    required this.onExport,
  });

  final String rudimentName;
  final int bpm;
  final int durationSeconds;
  final bool analysisMode;
  final SessionAnalysis? analysis;
  final Announcement? announcement;

  /// Arrive after the sheet is open (ladder dialog, save, coach call).
  final ValueListenable<String?> ladderResult;
  final ValueListenable<SessionLog?> sessionLog;
  final ValueListenable<String?> coachFeedback;
  final ValueListenable<bool> coachLoading;
  final bool coachEnabled;

  /// Saves the session; Done stays locked until it completes. A thrown
  /// error releases the rating and shows a hint.
  final Future<void> Function(int rating) onRate;
  final VoidCallback onDone;
  final VoidCallback onExport;

  @override
  State<ResultSheet> createState() => _ResultSheetState();
}

class _ResultSheetState extends State<ResultSheet> {
  int? _rating;
  bool _saving = false;
  String? _saveError;

  Future<void> _rate(int r) async {
    if (_rating != null) return; // saved once
    setState(() {
      _rating = r;
      _saving = true;
      _saveError = null;
    });
    try {
      await widget.onRate(r);
      if (mounted) setState(() => _saving = false);
    } catch (e) {
      debugPrint('save failed: $e');
      if (!mounted) return;
      setState(() {
        _rating = null;
        _saving = false;
        _saveError = "Couldn't save the session — tap a rating to try again.";
      });
    }
  }

  bool get _doneEnabled => _rating != null && !_saving;

  String get _duration {
    final m = widget.durationSeconds ~/ 60;
    final s = widget.durationSeconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final a = widget.analysis;
    final hasMic = a != null && (a.hasData || a.signalTooWeak);
    final values = a == null
        ? const <CoreValue>[]
        : coreValues(a, analysisMode: widget.analysisMode);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                  color: AppColors.textFaint,
                  borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 16),
          const _Eyebrow('SESSION COMPLETE'),
          const SizedBox(height: 4),
          Text(widget.rudimentName, style: AppTypography.title),
          const SizedBox(height: 2),
          Text(
            '${widget.bpm} BPM · $_duration · '
            '${widget.analysisMode ? 'analysis' : 'learn'}',
            style: AppTypography.body
                .copyWith(fontSize: 13, color: AppColors.textMuted),
          ),
          if (hasMic && widget.announcement != null) ...[
            const SizedBox(height: 16),
            VerdictBanner(announcement: widget.announcement!),
          ],
          const SizedBox(height: 20),
          const _Eyebrow('HOW DID IT FEEL?'),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _RatingChip(
                    label: 'Struggled',
                    sub: 'same BPM',
                    selected: _rating == 1,
                    onTap: () => _rate(1)),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _RatingChip(
                    label: 'OK',
                    sub: '+2 BPM',
                    selected: _rating == 2,
                    onTap: () => _rate(2)),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _RatingChip(
                    label: 'Solid',
                    sub: '+5 BPM',
                    selected: _rating == 3,
                    onTap: () => _rate(3)),
              ),
            ],
          ),
          if (_saveError != null)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(_saveError!,
                  style: AppTypography.body.copyWith(
                      fontSize: 13,
                      color: AppColors.struggled,
                      fontWeight: FontWeight.w600)),
            ),
          ValueListenableBuilder<String?>(
            valueListenable: widget.ladderResult,
            builder: (_, text, __) => text == null
                ? const SizedBox.shrink()
                : Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.stairs_outlined,
                            size: 16, color: AppColors.accent),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(text,
                              style: AppTypography.body.copyWith(
                                  fontSize: 13,
                                  color: AppColors.accent,
                                  fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ),
                  ),
          ),
          const SizedBox(height: 20),
          if (values.isNotEmpty)
            Column(
              children: [
                for (var i = 0; i < values.length; i++)
                  _CoreValueRow(values[i], last: i == values.length - 1),
              ],
            )
          else if (!hasMic)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'No mic analysis this time',
                style: AppTypography.body
                    .copyWith(fontSize: 13, color: AppColors.textMuted),
              ),
            ),
          // Only once a request is on its way — before that the card would
          // show an error for a state that is simply "not asked yet".
          if (widget.coachEnabled && _rating != null) ...[
            const SizedBox(height: 16),
            ValueListenableBuilder<bool>(
              valueListenable: widget.coachLoading,
              builder: (_, loading, __) => ValueListenableBuilder<String?>(
                valueListenable: widget.coachFeedback,
                builder: (_, text, __) => CoachFeedbackCard(
                    feedback: text, isLoading: loading, hasAnalysis: hasMic),
              ),
            ),
          ],
          if (hasMic) ...[
            const SizedBox(height: 16),
            _DetailsSection(analysis: a, analysisMode: widget.analysisMode),
          ],
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: Colors.white,
                disabledBackgroundColor: AppColors.inset,
                disabledForegroundColor: AppColors.textMuted,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.card)),
              ),
              onPressed: _doneEnabled ? widget.onDone : null,
              child: Text('Done',
                  style: AppTypography.subtitle.copyWith(
                      color: _doneEnabled
                          ? Colors.white
                          : AppColors.textMuted)),
            ),
          ),
          ValueListenableBuilder<SessionLog?>(
            valueListenable: widget.sessionLog,
            builder: (_, log, __) => log == null
                ? const SizedBox.shrink()
                : Center(
                    child: TextButton.icon(
                      onPressed: widget.onExport,
                      icon: const Icon(Icons.ios_share, size: 16),
                      label: const Text('Export session (JSONL)'),
                      style: TextButton.styleFrom(
                          foregroundColor: AppColors.textMuted),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _Eyebrow extends StatelessWidget {
  const _Eyebrow(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Text(text,
      style: AppTypography.label.copyWith(
          fontSize: 11, letterSpacing: 0.9, color: AppColors.textMuted));
}

class _RatingChip extends StatelessWidget {
  const _RatingChip({
    required this.label,
    required this.sub,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final String sub;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: selected
            ? AppColors.accent.withValues(alpha: 0.14)
            : AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
          side: BorderSide(
              color: selected ? AppColors.accent : AppColors.textFaint,
              width: selected ? 1.5 : 1),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.card),
          onTap: onTap,
          // Minimum height, not fixed: large fonts or narrow phones may wrap.
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 56),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(label,
                      textAlign: TextAlign.center,
                      style: AppTypography.body.copyWith(
                          fontWeight: FontWeight.w700,
                          color: selected
                              ? AppColors.accent
                              : AppColors.textPrimary)),
                  const SizedBox(height: 2),
                  Text(sub,
                      textAlign: TextAlign.center,
                      style: AppTypography.label.copyWith(
                          fontSize: 11, color: AppColors.textMuted)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CoreValueRow extends StatelessWidget {
  const _CoreValueRow(this.value, {required this.last});
  final CoreValue value;
  final bool last;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
              color: last ? Colors.transparent : AppColors.textFaint,
              width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value.head, style: AppTypography.subtitle),
          const SizedBox(height: 3),
          Text(value.sub,
              style: AppTypography.body
                  .copyWith(fontSize: 13, color: AppColors.textMuted)),
        ],
      ),
    );
  }
}

/// The old measurement rows and raw values, folded away.
class _DetailsSection extends StatelessWidget {
  const _DetailsSection({required this.analysis, required this.analysisMode});
  final SessionAnalysis analysis;
  final bool analysisMode;

  String _signed(double v) => '${v > 0 ? '+' : ''}${v.toStringAsFixed(1)} ms';

  @override
  Widget build(BuildContext context) {
    final t = analysis.timing;
    final d = analysis.dynamics;
    final u = analysis.unassigned;
    final al = analysis.alignment;
    final rowStyle = AppTypography.body.copyWith(fontSize: 12);
    Widget row(String label, String value) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Row(children: [
            Text(label, style: rowStyle.copyWith(color: AppColors.textMuted)),
            const Spacer(),
            Text(value,
                style: rowStyle.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600)),
          ]),
        );
    const border = Border(
        top: BorderSide(color: AppColors.textFaint),
        bottom: BorderSide(color: AppColors.textFaint));
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        childrenPadding: const EdgeInsets.only(bottom: 8),
        shape: border,
        collapsedShape: border,
        title: Text('Measurement details',
            style: AppTypography.body.copyWith(color: AppColors.textSecondary)),
        children: [
          if (u != null) ...[
            row(
                'Timing vs click',
                '${_signed(u.timingMedianMs)} median · '
                    '±${u.timingSpreadMs.toStringAsFixed(1)} ms'),
            row('Evenness', '±${u.intervalSpreadMs.toStringAsFixed(1)} ms'),
            if (u.dynamicsSpread != null)
              row('Dynamics spread', '${(u.dynamicsSpread! * 100).round()}%'),
            row('Strokes', '${u.playedCount} / ${u.expectedCount} expected'),
          ],
          if (al != null)
            row('Matched / missed / extra',
                '${al.hitCount} / ${al.missedCount} / ${al.extraCount}'),
          if (analysis.latencyOffsetAppliedMs != 0)
            row('Latency correction',
                '−${analysis.latencyOffsetAppliedMs.toStringAsFixed(0)} ms'),
          if (t != null) ...[
            row('R hand', _signed(t.rightHandDeviationMs)),
            row('L hand', _signed(t.leftHandDeviationMs)),
            row('Consistency', '±${t.jitterMs.toStringAsFixed(1)} ms jitter'),
            if (d != null)
              row(
                  'Dynamics R / L',
                  '${(d.rightHandLevel * 100).round()}% / '
                      '${(d.leftHandLevel * 100).round()}%'),
          ] else if (!analysisMode && !analysis.signalTooWeak)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                'Learn mode — timing and evenness without hand analysis. '
                'Mistakes are normal here.',
                style: rowStyle.copyWith(color: AppColors.textMuted),
              ),
            ),
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Levels (×100): ${analysis.peakLevels.map((p) => (p * 100).round()).join(' ')}\n'
                'Deviation (ms): ${analysis.deviationsMs.map((v) => v.round()).join(' ')}\n'
                'Recording: ${analysis.recordingSetup ?? 'unknown'}',
                style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 11,
                    fontFamily: 'monospace'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
