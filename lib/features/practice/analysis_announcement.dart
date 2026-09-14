import '../coaching/models/session_analysis.dart';

/// The one sentence the player must not miss on the feedback sheet, with its
/// tone. Extracted so the priority order is testable: the user overlooked
/// the verdict entirely while it sat as faint small print between the
/// numbers (14.09.) — the UI renders this as a prominent banner instead.
class Announcement {
  final String text;

  /// True = the run cleared the gates (green banner); false = coach verdict
  /// or measurement problem (orange banner).
  final bool positive;

  const Announcement(this.text, {required this.positive});
}

/// Banner for the feedback sheet, or null when none applies (learn mode
/// keeps its calm inline hint — a permanent mode, not a verdict).
Announcement? analysisAnnouncement(SessionAnalysis analysis,
    {required bool analysisMode}) {
  if (analysis.signalTooWeak) {
    return const Announcement(
      'Recording too quiet to analyze — move the phone closer to the pad.',
      positive: false,
    );
  }
  if (!analysisMode) return null;
  final al = analysis.alignment;
  if (al == null) return null;
  if (analysis.timing != null) {
    return const Announcement(
      'Clean run — hand analysis below.',
      positive: true,
    );
  }
  final lapses = al.lapses;
  if (lapses.isNotEmpty) {
    String mmss(double ms) {
      final s = (ms / 1000).round();
      return '${s ~/ 60}:${(s % 60).toString().padLeft(2, '0')}';
    }

    final first = lapses.first;
    if (lapses.length == 1) {
      final durS = (first.durationMs / 1000).round().clamp(1, 999);
      return Announcement(
        'Fell off at ${mmss(first.startMs)} for ~$durS s — not solid yet.',
        positive: false,
      );
    }
    return Announcement(
      '${lapses.length} breakdowns (first at ${mmss(first.startMs)}) — not '
      'solid yet.',
      positive: false,
    );
  }
  if (al.jitterLimitExceeded) {
    return const Announcement(
      'Too unsteady for hand analysis — not solid yet.',
      positive: false,
    );
  }
  return const Announcement(
    'Too many dropped notes for hand analysis — not solid yet.',
    positive: false,
  );
}
