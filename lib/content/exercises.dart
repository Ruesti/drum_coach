import '../measure/kit.dart';
import '../measure/targets.dart';
import '../skill/gate.dart';

class Exercise {
  const Exercise({
    required this.id,
    required this.title,
    required this.bpm,
    required this.bars,
    required this.beatsPerBar,
    required this.barHits,
    required this.gate,
  });

  final String id;
  final String title;
  final int bpm;
  final int bars;
  final int beatsPerBar;
  final List<TargetHit> barHits;
  final GateSpec gate;

  double get barMs => beatsPerBar * 60000 / bpm;

  /// All target times, sorted by time, then by voice index.
  List<TargetTime> targetTimes({required double firstBeatMs}) {
    final quarterMs = 60000 / bpm;
    final raw = <TargetTime>[];
    for (var bar = 0; bar < bars; bar++) {
      for (final h in barHits) {
        raw.add(TargetTime(
          index: 0,
          voice: h.voice,
          bar: bar,
          timeMs:
              firstBeatMs + bar * barMs + h.tick * quarterMs / ticksPerQuarter,
        ));
      }
    }
    raw.sort((a, b) {
      final c = a.timeMs.compareTo(b.timeMs);
      return c != 0 ? c : a.voice.index.compareTo(b.voice.index);
    });
    return [
      for (var i = 0; i < raw.length; i++)
        TargetTime(
          index: i,
          voice: raw[i].voice,
          bar: raw[i].bar,
          timeMs: raw[i].timeMs,
        ),
    ];
  }
}

const entryExercise = Exercise(
  id: 'entry',
  title: 'Entry exercise',
  bpm: 70,
  bars: 8,
  beatsPerBar: 4,
  barHits: [
    TargetHit(Voice.hiHat, 0),
    TargetHit(Voice.hiHat, 24),
    TargetHit(Voice.hiHat, 48),
    TargetHit(Voice.hiHat, 72),
    TargetHit(Voice.kick, 0),
    TargetHit(Voice.kick, 48),
  ],
  gate: GateSpec(minHitRatePerVoice: 0.80, maxHitGapBars: 1),
);

const basicRockBeat = Exercise(
  id: 'rock8',
  title: 'Basic Rock Beat',
  bpm: 80,
  bars: 16,
  beatsPerBar: 4,
  barHits: [
    TargetHit(Voice.hiHat, 0),
    TargetHit(Voice.hiHat, 12),
    TargetHit(Voice.hiHat, 24),
    TargetHit(Voice.hiHat, 36),
    TargetHit(Voice.hiHat, 48),
    TargetHit(Voice.hiHat, 60),
    TargetHit(Voice.hiHat, 72),
    TargetHit(Voice.hiHat, 84),
    TargetHit(Voice.snare, 24),
    TargetHit(Voice.snare, 72),
    TargetHit(Voice.kick, 0),
    TargetHit(Voice.kick, 48),
  ],
  gate: GateSpec(
    minHitRatePerVoice: 0.95,
    maxWrongRate: 0.02,
    maxExtraRate: 0.05,
    maxAbsMedianMs: 15,
    maxSpreadMs: 20,
    maxSnareVelocitySd: 12,
  ),
);

const exercises = [entryExercise, basicRockBeat];

Exercise exerciseById(String id) => exercises.firstWhere(
      (e) => e.id == id,
      orElse: () => throw ArgumentError('Unknown exercise id: $id'),
    );
