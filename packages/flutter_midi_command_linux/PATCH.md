# Lokaler Patch gegenüber flutter_midi_command_linux 1.4.0

Grund: docs/BERICHT_ETAPPE2_§0.md. Zwei Änderungen in
`lib/src/alsa_seq_linux_device.dart`:

1. `_seqRxIsolateEntry`: `rxUs = DateTime.now().microsecondsSinceEpoch` direkt
   nach `snd_seq_event_input`, als fünftes Element der `'midi'`-Nachricht;
   der Listener im Haupt-Isolate übernimmt es als `timestamp` (statt
   `DateTime.now().millisecondsSinceEpoch` dort). Ergebnis: Stempel in µs
   Epoche, unabhängig von der Last des Haupt-Isolates.
2. Geräte-Erkennung: Ports ohne `SND_SEQ_PORT_TYPE_HARDWARE` erscheinen,
   wenn sie `SND_SEQ_PORT_TYPE_MIDI_GENERIC` tragen (virtuelle Ports für den
   Integrationstest).

Beim Update der Bibliothek beide Stellen neu anwenden
(`tool/midi/spike/patch_plugin.py`, `patch_plugin2.py`) oder den
Upstream-Stand prüfen.
