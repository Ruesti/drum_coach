import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

Iterable<File> _files(String dir) =>
    Directory(dir).listSync(recursive: true).whereType<File>();

/// Import and export directives of [f].
List<String> _imports(File f) => [
      for (final l in f.readAsLinesSync())
        if (l.startsWith('import ') || l.startsWith('export ')) l,
    ];

void main() {
  test('pure layers import no flutter or plugins', () {
    for (final dir in ['lib/measure', 'lib/skill', 'lib/content']) {
      for (final f in _files(dir)) {
        final src = f.readAsStringSync();
        expect(src.contains("package:flutter"), isFalse, reason: f.path);
        expect(src.contains("package:flutter_midi_command"), isFalse,
            reason: f.path);
        expect(src.contains("dart:ui"), isFalse, reason: f.path);
      }
    }
  });

  test('layer direction is content → skill → measure', () {
    void forbid(String dir, List<String> parts) {
      for (final f in _files(dir)) {
        for (final line in _imports(f)) {
          for (final p in parts) {
            expect(line.contains(p), isFalse,
                reason: '${f.path} must not import $p: $line');
          }
        }
      }
    }

    forbid('lib/measure', ['content/', 'skill/']);
    forbid('lib/skill', ['content/']);
  });
}
