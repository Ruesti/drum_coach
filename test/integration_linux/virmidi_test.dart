import 'package:flutter_test/flutter_test.dart';

import 'virmidi.dart';

void main() {
  test('virmidiCard finds the card number of the virtual rawmidi port', () {
    expect(virmidiCard(['Midi Through', 'Virtual Raw MIDI 0-0']), 0);
    expect(virmidiCard(['Virtual Raw MIDI 2-0']), 2);
    expect(virmidiCard(['Midi Through', 'Millenium']), isNull);
    expect(virmidiCard(['Virtual Raw MIDI 1-1']), isNull);
    expect(virmidiCard(const []), isNull);
  });
}
