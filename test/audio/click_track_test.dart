import 'dart:math';
import 'dart:typed_data';

import 'package:drum_coach/audio/click_track.dart';
import 'package:flutter_test/flutter_test.dart';

Int16List _samples(ClickTrack t) {
  final b = t.wav.buffer.asByteData(t.wav.offsetInBytes, t.wav.length);
  final n = (t.wav.length - 44) ~/ 2;
  return Int16List.fromList(
      [for (var i = 0; i < n; i++) b.getInt16(44 + i * 2, Endian.little)]);
}

int _peak(Int16List s, int from, int count) {
  var p = 0;
  for (var i = from; i < from + count; i++) {
    p = max(p, s[i].abs());
  }
  return p;
}

int _crossings(Int16List s, int from, int count) {
  var c = 0;
  for (var i = from + 1; i < from + count; i++) {
    if ((s[i - 1] < 0) != (s[i] < 0)) c++;
  }
  return c;
}

void main() {
  test('80 BPM, 16 bars + 1 count-in bar → 68 clicks, offsets every 750 ms',
      () {
    final t = renderClickTrack(bpm: 80, bars: 16);
    expect(t.clickOffsetsMs.length, 68);
    for (var i = 0; i < 68; i++) {
      expect(t.clickOffsetsMs[i], closeTo(i * 750.0, 1e-9));
    }
    expect(t.firstBeatOffsetMs, closeTo(3000, 1e-9));
    // last click offset + one beat + 500 ms silence
    expect(t.durationMs, closeTo(67 * 750 + 750 + 500, 1e-9));
  });

  test('first click sample is at offset 0 and has the accent frequency', () {
    final t = renderClickTrack(bpm: 80, bars: 2);
    expect(t.clickOffsetsMs.first, 0);
    final s = _samples(t);
    final n = 48000 * 20 ~/ 1000;
    // zero crossings in the first 20 ms: 2 per period
    expect(_crossings(s, 0, n) / 2 / 0.020, closeTo(2000, 100));
    // beat 2 is a 1.5 kHz click starting at its offset
    const beat = 36000; // 750 ms at 48 kHz
    expect(_crossings(s, beat, n) / 2 / 0.020, closeTo(1500, 75));
    // accents are louder than the other beats, in every bar
    for (var bar = 0; bar < 3; bar++) {
      final accent = _peak(s, bar * 4 * beat, n);
      for (var b = 1; b < 4; b++) {
        expect(accent, greaterThan(_peak(s, (bar * 4 + b) * beat, n)));
      }
    }
    // silence right after the 20 ms click
    expect(_peak(s, 48000 * 25 ~/ 1000, 1000), 0);
  });

  test('count-in bars shift the first beat; other meters work', () {
    final t =
        renderClickTrack(bpm: 120, bars: 2, beatsPerBar: 3, countInBars: 2);
    expect(t.clickOffsetsMs.length, 12);
    expect(t.firstBeatOffsetMs, closeTo(3000, 1e-9));
    expect(t.clickOffsetsMs[6], closeTo(3000, 1e-9));
  });

  test('wav header: RIFF, 48000 Hz, mono, 16 bit, data length matches duration',
      () {
    final t = renderClickTrack(bpm: 80, bars: 16);
    final b = t.wav.buffer.asByteData(t.wav.offsetInBytes, t.wav.length);
    String tag(int o) => String.fromCharCodes(t.wav.sublist(o, o + 4));
    expect(tag(0), 'RIFF');
    expect(tag(8), 'WAVE');
    expect(tag(12), 'fmt ');
    expect(b.getUint16(20, Endian.little), 1); // PCM
    expect(b.getUint16(22, Endian.little), 1); // mono
    expect(b.getUint32(24, Endian.little), 48000);
    expect(b.getUint32(28, Endian.little), 96000); // byte rate
    expect(b.getUint16(32, Endian.little), 2); // block align
    expect(b.getUint16(34, Endian.little), 16);
    expect(tag(36), 'data');
    final dataLen = b.getUint32(40, Endian.little);
    expect(b.getUint32(4, Endian.little), 36 + dataLen);
    expect(t.wav.length, 44 + dataLen);
    expect(dataLen / 2 / 48000 * 1000, closeTo(t.durationMs, 0.02));
  });
}
