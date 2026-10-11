#!/usr/bin/env python3
"""Patcht die lokale Kopie von flutter_midi_command_linux: Zeitstempel (µs, Wanduhr)
direkt im Rx-Isolate nach snd_seq_event_input statt ms im Haupt-Isolate."""
import sys
p = sys.argv[1]
s = open(p, encoding="utf-8").read()

old1 = """      final result = alsa.snd_seq_event_input(seq, eventPtrPtr);
      if (result < 0) {
        break;
      }
"""
new1 = old1 + "      final rxUs = DateTime.now().microsecondsSinceEpoch;\n"
assert s.count(old1) == 1, "Stelle 1 nicht eindeutig"
s = s.replace(old1, new1)

old2 = """          args.sendPort.send(<Object?>[
            'midi',
            event.ref.source.client,
            event.ref.source.port,
            bytes,
          ]);"""
new2 = """          args.sendPort.send(<Object?>[
            'midi',
            event.ref.source.client,
            event.ref.source.port,
            bytes,
            rxUs,
          ]);"""
assert s.count(old2) == 1, "Stelle 2 nicht eindeutig"
s = s.replace(old2, new2)

old3 = "if (tag == 'midi' && message.length == 4) {"
new3 = "if (tag == 'midi' && message.length == 5) {"
assert s.count(old3) == 1, "Stelle 3 nicht eindeutig"
s = s.replace(old3, new3)

old4 = "        final timestamp = DateTime.now().millisecondsSinceEpoch;\n"
new4 = "        final timestamp = message[4] as int; // µs aus dem Rx-Isolate\n"
assert s.count(old4) == 1, "Stelle 4 nicht eindeutig"
s = s.replace(old4, new4)

open(p, "w", encoding="utf-8").write(s)
print("Plugin gepatcht:", p)
