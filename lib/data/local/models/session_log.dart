import 'package:isar/isar.dart';

part 'session_log.g.dart';

/// Raw per-session log (Brief Etappe 1, Phase 2): the six-week data set for
/// the assessment draft. Additive next to [PracticeSession] — nothing of the
/// existing stats/learning path changes. Onset times are stored RAW (no
/// latency subtracted); the applied calibration value sits in the header so
/// every correction stays reproducible.
@collection
class SessionLog {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late String sessionUid;

  late DateTime startedAt;
  late String exerciseId;

  /// `learn` | `analysis` — Phase 2 always writes `learn`; Phase 3 takes
  /// this field over.
  late String mode;

  late int bpm;
  late int durationSeconds;

  late String deviceModel;
  late String androidVersion;

  // Recording configuration (§1.1).
  late String audioSource;
  late int sampleRate;
  late bool autoGain;
  late bool echoCancel;
  late bool noiseSuppress;
  bool? unprocessedSupported;

  /// `none` | `wired` | `bluetooth`.
  late String headphones;

  double? latencyOffsetMs;
  int? rating;

  /// Planned click instants (epoch ms, shared time axis §1.3) and the note
  /// index each click belongs to.
  late List<double> clickTimesMs;
  late List<int> clickNoteIndices;

  late List<OnsetEvent> events;
}

@embedded
class OnsetEvent {
  double timeMs = 0;
  double peakLevel = 0;
  int? notePosition;
  String? hand;
  double? deviationMs;
}
