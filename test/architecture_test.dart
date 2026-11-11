import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('pure layers import no flutter or plugins', () {
    for (final dir in ['lib/measure', 'lib/skill', 'lib/content']) {
      for (final f
          in Directory(dir).listSync(recursive: true).whereType<File>()) {
        final src = f.readAsStringSync();
        expect(src.contains("package:flutter"), isFalse, reason: f.path);
        expect(src.contains("package:flutter_midi_command"), isFalse,
            reason: f.path);
        expect(src.contains("dart:ui"), isFalse, reason: f.path);
      }
    }
  });
}
