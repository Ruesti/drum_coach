import '../../lessons/models/rudiment.dart';

class SessionAnalysis {
  final TimingAnalysis? timing;
  final DynamicsAnalysis? dynamics;
  final int detectedHits;
  final int expectedHits;

  const SessionAnalysis({
    this.timing,
    this.dynamics,
    required this.detectedHits,
    required this.expectedHits,
  });

  bool get hasData => detectedHits > 3;
}

class TimingAnalysis {
  final double overallDeviationMs;    // positive = consistently late
  final double rightHandDeviationMs;
  final double leftHandDeviationMs;
  final double jitterMs;              // std deviation → consistency

  const TimingAnalysis({
    required this.overallDeviationMs,
    required this.rightHandDeviationMs,
    required this.leftHandDeviationMs,
    required this.jitterMs,
  });
}

class DynamicsAnalysis {
  final double rightHandLevel;  // avg amplitude 0–1
  final double leftHandLevel;

  const DynamicsAnalysis({
    required this.rightHandLevel,
    required this.leftHandLevel,
  });

  double get balance => leftHandLevel / (rightHandLevel + 0.001);
}

class MatchedHit {
  final DateTime hitTimestamp;
  final double amplitude;
  final double deviationMs;
  final Hand hand;

  const MatchedHit({
    required this.hitTimestamp,
    required this.amplitude,
    required this.deviationMs,
    required this.hand,
  });
}
