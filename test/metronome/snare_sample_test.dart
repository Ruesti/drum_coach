import 'package:drum_coach/features/metronome/snare_sample.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // SoLoud's MP3 path kept the MP3 encoder delay (25 ms of silence), so the
  // snare sounded 25 ms behind the synthetic kick and hi-hat (20.10.).
  test('recorded snare loads and starts on its first millisecond', () async {
    final pcm = await loadSnarePcm();
    expect(pcm.length, greaterThan(44100 * 0.6));
    var peak = 0.0;
    for (final v in pcm) {
      if (v.abs() > peak) peak = v.abs();
    }
    final onset = pcm.indexWhere((v) => v.abs() > 0.02 * peak);
    expect(onset, inInclusiveRange(0, 43));
  });
}
