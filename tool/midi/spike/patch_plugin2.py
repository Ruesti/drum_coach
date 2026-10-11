#!/usr/bin/env python3
"""Lockert den Hardware-Filter der Geräte-Erkennung: auch virtuelle (virmidi)
Ports erscheinen. Nur für den §0-Versuch."""
import sys
p = sys.argv[1]
s = open(p, encoding="utf-8").read()
old = """          if ((portType & SND_SEQ_PORT_TYPE_HARDWARE) == 0) {
            continue;
          }
"""
new = """          // §0-Patch: virtuelle Ports (virmidi) zulassen.
          if ((portType & SND_SEQ_PORT_TYPE_HARDWARE) == 0 &&
              (portType & SND_SEQ_PORT_TYPE_MIDI_GENERIC) == 0) {
            continue;
          }
"""
assert s.count(old) == 1, "Filterstelle nicht eindeutig"
s = s.replace(old, new)
open(p, "w", encoding="utf-8").write(s)
print("Filter gelockert:", p)
