import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('vendored flutter_midi_command_linux carries the §0 patch', () {
    final src = File(
            'packages/flutter_midi_command_linux/lib/src/alsa_seq_linux_device.dart')
        .readAsStringSync();
    expect(src, contains('final rxUs = DateTime.now().microsecondsSinceEpoch;'));
    expect(src, contains("tag == 'midi' && message.length == 5"));
    expect(src, contains('SND_SEQ_PORT_TYPE_MIDI_GENERIC) == 0'));
    expect(src, isNot(contains(
        'final timestamp = DateTime.now().millisecondsSinceEpoch;')));
  });

  test('pubspec overrides the linux implementation with the vendored copy', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    expect(pubspec, contains('flutter_midi_command: 1.4.0'));
    expect(pubspec, contains('path: packages/flutter_midi_command_linux'));
  });
}
