import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:drum_coach/features/guided/models/voice_clip.dart';
import 'package:drum_coach/features/guided/voice_assets.dart';
import 'package:flutter_test/flutter_test.dart';

Uint8List _wav({int rate = 44100, int channels = 1, List<int>? pcm}) {
  final samples = pcm ?? [0, 16384, -16384, 32767];
  final b = BytesBuilder();
  void u32(int v) =>
      b.add((ByteData(4)..setUint32(0, v, Endian.little)).buffer.asUint8List());
  void u16(int v) =>
      b.add((ByteData(2)..setUint16(0, v, Endian.little)).buffer.asUint8List());
  b.add('RIFF'.codeUnits);
  u32(36 + samples.length * 2);
  b.add('WAVEfmt '.codeUnits);
  u32(16);
  u16(1);
  u16(channels);
  u32(rate);
  u32(rate * channels * 2);
  u16(channels * 2);
  u16(16);
  b.add('data'.codeUnits);
  u32(samples.length * 2);
  for (final s in samples) {
    b.add((ByteData(2)..setInt16(0, s, Endian.little)).buffer.asUint8List());
  }
  return b.toBytes();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final manifest =
      jsonDecode(File('assets/voice/manifest.json').readAsStringSync())
          as Map<String, dynamic>;
  final parsed = ClipManifest.fromJson(manifest);

  test('manifest says english', () {
    expect(manifest['lang'], 'en');
    expect(manifest['voice'], isNotEmpty);
  });

  test('every manifest id has an asset', () async {
    expect(parsed.ids, isNotEmpty);
    for (final id in parsed.ids) {
      final clip = await loadVoiceClip(id);
      expect(clip.id, id);
      expect(clip.durationMs, closeTo(parsed.durationMs(id), 1.0), reason: id);
    }
  });

  test('countdown clips each <= 600 ms', () {
    const ids = [
      'ci_one', 'ci_two', 'ci_three', 'ci_four', //
      'cd_three', 'cd_two', 'cd_one', 'cd_go',
    ];
    for (final id in ids) {
      expect(parsed.durationMs(id), lessThanOrEqualTo(600), reason: id);
    }
  });

  test('required teacher clips exist', () {
    for (final id in [
      'after_good', 'after_last', 'demo_kit_v1', 'demo_kit_v2', //
      'demo_kit_v3', 'demo_pad_v1', 'demo_pad_v2', 'demo_pad_v3',
    ]) {
      expect(parsed.ids, contains(id));
    }
  });

  test('decodeVoiceWav converts 16-bit samples to floats', () {
    final s = decodeVoiceWav(_wav());
    expect(s.length, 4);
    expect(s[1], closeTo(0.5, 1e-6));
    expect(s[2], closeTo(-0.5, 1e-6));
  });

  test('decodeVoiceWav rejects wrong rate and stereo', () {
    expect(() => decodeVoiceWav(_wav(rate: 22050)), throwsFormatException);
    expect(() => decodeVoiceWav(_wav(channels: 2)), throwsFormatException);
    expect(() => decodeVoiceWav(Uint8List(4)), throwsFormatException);
  });
}
