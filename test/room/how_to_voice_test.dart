import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

const _techSheets = [
  'tech_grip_rebound',
  'tech_full_stroke_tap',
  'tech_even_singles',
  'tech_accent_basics',
  'tech_single_hand_control',
  'tech_down_up_strokes',
  'tech_moving_accents',
  'tech_doubles_control',
  'tech_ghost_accent_contrast',
  'tech_speed_bursts',
];

void main() {
  test('manifest lists a how-to clip with a WAV for each technique sheet', () {
    final manifest =
        jsonDecode(File('assets/voice/manifest.json').readAsStringSync())
            as Map<String, dynamic>;
    final ids = {
      for (final c in manifest['clips'] as List<dynamic>)
        (c as Map<String, dynamic>)['id'] as String,
    };
    for (final id in _techSheets) {
      expect(ids.contains('h_$id'), isTrue, reason: 'h_$id missing');
      expect(File('assets/voice/h_$id.wav').existsSync(), isTrue);
    }
  });
}
