import '../coaching/models/session_analysis.dart';

/// One plain-language line of the result sheet (decided 15.09.): the
/// sentence the drummer reads, and the measurement small under it.
class CoreValue {
  final String head;
  final String sub;
  const CoreValue(this.head, this.sub);
}

String _plural(int n, String one, String many) => n == 1 ? one : many;

/// The three core values — hits, timing, hands/evenness — or fewer when the
/// analysis lacks the data. Positive deviation = behind the click.
/// Thresholds decided 27.09.: timing 5/15 ms, hands 5 ms, evenness 10/20 ms.
List<CoreValue> coreValues(SessionAnalysis a, {required bool analysisMode}) {
  if (a.signalTooWeak) return const [];
  final out = <CoreValue>[];

  // 1. Hits
  final al = a.alignment;
  final u = a.unassigned;
  if (al != null) {
    final pct = al.expectedCount == 0
        ? 0
        : (al.hitCount * 100 / al.expectedCount).round();
    var sub = '${al.hitCount} of ${al.expectedCount} hit · $pct %';
    if (al.extraCount > 0) sub += ' · ${al.extraCount} extra';
    final head = al.missedCount > 0
        ? 'You miss ${al.missedCount} '
            '${_plural(al.missedCount, 'note', 'notes')}'
        : al.extraCount > 0
            ? 'You add ${al.extraCount} extra '
                '${_plural(al.extraCount, 'stroke', 'strokes')}'
            : 'You hit every note';
    out.add(CoreValue(head, sub));
  } else if (u != null) {
    final d = u.expectedCount - u.playedCount;
    final head = d > 0
        ? 'You miss $d ${_plural(d, 'note', 'notes')}'
        : d < 0
            ? 'You add ${-d} extra ${_plural(-d, 'stroke', 'strokes')}'
            : 'You hit every note';
    out.add(CoreValue(head, '${u.playedCount} of ${u.expectedCount} played'));
  }
  if (u == null) return out;

  // 2. Timing
  final m = u.timingMedianMs.round();
  final spread = u.timingSpreadMs.round();
  final String timingHead;
  if (m.abs() <= 5) {
    timingHead = "You're right on the click";
  } else if (m.abs() <= 15) {
    timingHead = m < 0 ? 'You rush a little' : 'You drag a little';
  } else {
    timingHead = m < 0 ? 'You rush' : 'You drag';
  }
  final timingSub = m == 0
      ? 'on the click · ±$spread ms spread'
      : '${m.abs()} ms ${m < 0 ? 'ahead of' : 'behind'} the click · '
          '±$spread ms spread';
  out.add(CoreValue(timingHead, timingSub));

  // 3. Hands (analysis mode with per-hand values) or evenness
  final t = a.timing;
  if (analysisMode && t != null) {
    final r = t.rightHandDeviationMs.round();
    final l = t.leftHandDeviationMs.round();
    final diff = r - l;
    final head = diff.abs() <= 5
        ? 'Your hands are even'
        : diff > 0
            ? 'Your right hand is late'
            : 'Your left hand is late';
    String signed(int v) => '${v >= 0 ? '+' : ''}$v ms';
    out.add(CoreValue(
        head,
        'right ${signed(r)} · left ${signed(l)} · '
        '±${t.jitterMs.round()} ms jitter'));
  } else {
    final e = u.intervalSpreadMs.round();
    final head = e <= 10
        ? 'Your strokes are even'
        : e <= 20
            ? 'Your strokes are slightly uneven'
            : 'Your strokes are uneven';
    out.add(CoreValue(head, '±$e ms between strokes'));
  }
  return out;
}
