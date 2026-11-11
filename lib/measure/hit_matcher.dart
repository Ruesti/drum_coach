/// Per-voice matching of received kit strokes against target times: hit,
/// missed, wrong instrument, extra, ignored.
library;

import 'dart:math' as math;

import 'kit.dart';
import 'sequence_aligner.dart';
import 'stroke.dart';
import 'targets.dart';

enum HitKind { hit, missed, wrongInstrument }

class TargetOutcome {
  const TargetOutcome({
    required this.target,
    required this.kind,
    this.strokeIndex,
    this.deviationMs,
  });

  final TargetTime target;
  final HitKind kind;

  /// Index into the input strokes list; null for [HitKind.missed].
  final int? strokeIndex;

  /// Corrected stroke time minus target time; set for [HitKind.hit] and
  /// [HitKind.wrongInstrument].
  final double? deviationMs;
}

class MatchResult {
  const MatchResult({
    required this.targets,
    required this.extraStrokeIndices,
    required this.ignoredStrokeIndices,
  });

  /// One outcome per input target, in input order.
  final List<TargetOutcome> targets;

  /// In-window strokes matched to no target (sorted stroke indices).
  final List<int> extraStrokeIndices;

  /// Strokes outside the exercise window, e.g. count-in or after the end
  /// (sorted stroke indices).
  final List<int> ignoredStrokeIndices;
}

const double _maxWindowMs = 250;

/// Matches [strokes] against [targets]. Stroke times are corrected by
/// subtracting [latencyOffsetMs]. The window `w` is
/// min(250, half the smallest gap between consecutive same-voice targets).
MatchResult matchHits({
  required List<TargetTime> targets,
  required List<Stroke> strokes,
  required double latencyOffsetMs,
}) {
  final corrected = [for (final s in strokes) s.timeMs - latencyOffsetMs];

  if (targets.isEmpty) {
    return MatchResult(
      targets: const [],
      extraStrokeIndices: const [],
      ignoredStrokeIndices: [for (var i = 0; i < strokes.length; i++) i],
    );
  }

  // Target indices per voice, in time order.
  final byVoice = <Voice, List<int>>{};
  for (var i = 0; i < targets.length; i++) {
    byVoice.putIfAbsent(targets[i].voice, () => []).add(i);
  }
  for (final list in byVoice.values) {
    list.sort((a, b) {
      final c = targets[a].timeMs.compareTo(targets[b].timeMs);
      return c != 0 ? c : a.compareTo(b);
    });
  }

  // Step 2: window.
  var w = _maxWindowMs;
  for (final list in byVoice.values) {
    for (var k = 1; k < list.length; k++) {
      final gap = targets[list[k]].timeMs - targets[list[k - 1]].timeMs;
      w = math.min(w, 0.5 * gap);
    }
  }
  var first = targets.first.timeMs;
  var last = targets.first.timeMs;
  for (final t in targets) {
    first = math.min(first, t.timeMs);
    last = math.max(last, t.timeMs);
  }

  final ignored = <int>[];
  final inWindow = <int>[];
  for (var i = 0; i < strokes.length; i++) {
    final c = corrected[i];
    if (c < first - w || c > last + w) {
      ignored.add(i);
    } else {
      inWindow.add(i);
    }
  }

  final kinds = List<HitKind>.filled(targets.length, HitKind.missed);
  final strokeOf = List<int?>.filled(targets.length, null);
  final devOf = List<double?>.filled(targets.length, null);
  final used = <int>{};

  // Step 3: alignment per voice.
  for (final entry in byVoice.entries) {
    final targetIdx = entry.value;
    final strokeIdx = [
      for (final i in inWindow)
        if (voiceOf(strokes[i].instrument) == entry.key) i,
    ];
    final aligned = alignSequences(
      expectedMs: [for (final t in targetIdx) targets[t].timeMs],
      onsetMs: [for (final s in strokeIdx) corrected[s]],
      maxMatchDevMs: w,
    );
    for (final note in aligned.notes) {
      if (!note.hit) continue;
      final t = targetIdx[note.noteIndex];
      final s = strokeIdx[note.onsetIndex!];
      kinds[t] = HitKind.hit;
      strokeOf[t] = s;
      devOf[t] = note.deviationMs;
      used.add(s);
    }
  }

  // Step 4: wrong instrument for still-missed targets, in time order.
  final missed = [
    for (var t = 0; t < targets.length; t++)
      if (kinds[t] == HitKind.missed) t,
  ]..sort((a, b) {
      final c = targets[a].timeMs.compareTo(targets[b].timeMs);
      return c != 0 ? c : a.compareTo(b);
    });
  for (final t in missed) {
    final target = targets[t];
    int? best;
    var bestDist = double.infinity;
    for (final s in inWindow) {
      if (used.contains(s)) continue;
      if (voiceOf(strokes[s].instrument) == target.voice) continue;
      final dist = (corrected[s] - target.timeMs).abs();
      if (dist > w) continue;
      if (dist < bestDist || (dist == bestDist && s < best!)) {
        best = s;
        bestDist = dist;
      }
    }
    if (best != null) {
      kinds[t] = HitKind.wrongInstrument;
      strokeOf[t] = best;
      devOf[t] = corrected[best] - target.timeMs;
      used.add(best);
    }
  }

  // Step 5: everything else in the window is extra.
  final extras = [
    for (final s in inWindow)
      if (!used.contains(s)) s,
  ];

  return MatchResult(
    targets: [
      for (var t = 0; t < targets.length; t++)
        TargetOutcome(
          target: targets[t],
          kind: kinds[t],
          strokeIndex: strokeOf[t],
          deviationMs: devOf[t],
        ),
    ],
    extraStrokeIndices: extras,
    ignoredStrokeIndices: ignored,
  );
}
