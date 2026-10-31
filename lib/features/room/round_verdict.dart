import '../coaching/models/session_analysis.dart';

/// Thresholds echo lib/features/practice/core_values.dart
/// (timing 5/15 ms, evenness 10/20 ms).
const double kCleanMinHitRate = 0.95;
const double kCleanMaxExtraRate = 0.05;
const double kCleanMaxTimingMedianMs = 15;
const double kCleanMaxTimingSpreadMs = 20;
const double kOffMaxHitRate = 0.80;
const double kOffMinTimingSpreadMs = 40;

/// How a practice round went: clean, close (nearly) or off.
enum RoundVerdict { clean, close, off }

/// Verdict for one round. Null = not measurable (nothing to judge).
/// Missing alignment/unassigned data on otherwise measured input counts as
/// "not enough data" and yields [RoundVerdict.close].
RoundVerdict? verdictOf(SessionAnalysis? a) {
  if (a == null || a.notMeasurable) return null;
  if (a.signalTooWeak || !a.hasData) return RoundVerdict.close;
  final al = a.alignment;
  final un = a.unassigned;
  if (al == null || un == null) return RoundVerdict.close;
  if (al.hitRate < kOffMaxHitRate ||
      un.timingSpreadMs > kOffMinTimingSpreadMs) {
    return RoundVerdict.off;
  }
  if (al.hitRate >= kCleanMinHitRate &&
      al.extraRate <= kCleanMaxExtraRate &&
      un.timingMedianMs.abs() <= kCleanMaxTimingMedianMs &&
      un.timingSpreadMs <= kCleanMaxTimingSpreadMs) {
    return RoundVerdict.clean;
  }
  return RoundVerdict.close;
}

/// Self rating (3 good, 2 so-so, 1 bad) as verdict.
RoundVerdict verdictOfRating(int rating) => rating >= 3
    ? RoundVerdict.clean
    : rating == 2
        ? RoundVerdict.close
        : RoundVerdict.off;
