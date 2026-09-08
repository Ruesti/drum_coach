import 'dart:convert';

import 'package:drum_coach/data/local/models/session_log.dart';
import 'package:drum_coach/data/local/session_log_codec.dart';
import 'package:flutter_test/flutter_test.dart';

SessionLog _sample() {
  return SessionLog()
    ..sessionUid = '1757354000000-single_stroke_roll'
    ..startedAt = DateTime.utc(2026, 9, 8, 18, 30)
    ..exerciseId = 'single_stroke_roll'
    ..mode = 'learn'
    ..bpm = 74
    ..durationSeconds = 17
    ..deviceModel = 'SM-S918B'
    ..androidVersion = '14'
    ..audioSource = 'voice_recognition'
    ..sampleRate = 16000
    ..autoGain = false
    ..echoCancel = false
    ..noiseSuppress = false
    ..unprocessedSupported = false
    ..headphones = 'wired'
    ..latencyOffsetMs = 69
    ..rating = 2
    ..clickTimesMs = [1000.5, 1500.5]
    ..clickNoteIndices = [0, 1]
    ..events = [
      OnsetEvent()
        ..timeMs = 1074.2
        ..peakLevel = 0.31
        ..notePosition = 0
        ..hand = 'R'
        ..deviationMs = 4.7,
      OnsetEvent()
        ..timeMs = 1290.0
        ..peakLevel = 0.12,
    ];
}

void main() {
  group('sessionLogToJsonl', () {
    test('first line is the session header with every brief field', () {
      final lines = sessionLogToJsonl(_sample()).trim().split('\n');
      final header = jsonDecode(lines.first) as Map<String, dynamic>;
      expect(header['type'], 'session');
      expect(header['sessionUid'], '1757354000000-single_stroke_roll');
      expect(header['startedAt'], '2026-09-08T18:30:00.000Z');
      expect(header['exerciseId'], 'single_stroke_roll');
      expect(header['mode'], 'learn');
      expect(header['bpm'], 74);
      expect(header['durationSeconds'], 17);
      expect(header['deviceModel'], 'SM-S918B');
      expect(header['androidVersion'], '14');
      expect(header['audioSource'], 'voice_recognition');
      expect(header['sampleRate'], 16000);
      expect(header['autoGain'], false);
      expect(header['echoCancel'], false);
      expect(header['noiseSuppress'], false);
      expect(header['unprocessedSupported'], false);
      expect(header['headphones'], 'wired');
      expect(header['latencyOffsetMs'], 69);
      expect(header['rating'], 2);
      expect(header['clickTimesMs'], [1000.5, 1500.5]);
      expect(header['clickNoteIndices'], [0, 1]);
    });

    test('each onset becomes one line, surplus onsets with nulls', () {
      final lines = sessionLogToJsonl(_sample()).trim().split('\n');
      expect(lines.length, 3);
      final assigned = jsonDecode(lines[1]) as Map<String, dynamic>;
      expect(assigned['type'], 'onset');
      expect(assigned['timeMs'], 1074.2);
      expect(assigned['peakLevel'], 0.31);
      expect(assigned['notePosition'], 0);
      expect(assigned['hand'], 'R');
      expect(assigned['deviationMs'], 4.7);

      final surplus = jsonDecode(lines[2]) as Map<String, dynamic>;
      expect(surplus['notePosition'], isNull);
      expect(surplus['hand'], isNull);
      expect(surplus['deviationMs'], isNull);
    });
  });
}
