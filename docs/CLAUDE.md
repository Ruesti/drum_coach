# DrumCoach – Claude Code Context

Only valid concept: `docs/KONZEPT.md`. `docs/archive/` is reference, not a task.

E-drum trainer: every hit is measured via MIDI, gates are decided from the numbers.

## Layer rule
- Platforms: Linux, Android, Windows. Platform-only code only in `lib/midi/` and `lib/audio/`.
- `lib/measure/`, `lib/skill/`, `lib/content/` are pure Dart: no `package:flutter`, no plugins, no `dart:ui`.
- E-drum kit via MIDI only. No microphone, no pad mode, no self-rating, no AI coaching.
- Without a latency calibration for the active device, no gate verdict is produced.
- UI strings in English.

## File map
- `lib/main.dart` – app entry
- `lib/midi/` – MIDI input (platform code)
- `lib/audio/` – sound output (platform code)
- `lib/measure/` – timing/velocity measurement core
- `lib/skill/` – skill model and gates
- `lib/content/` – exercise content
- `packages/flutter_midi_command_linux/` – patched Linux MIDI plugin
- `test/architecture_test.dart` – enforces the layer rule

## Tests
- `flutter test`
- `tool/midi/virtual_port_test.sh` (virtual MIDI port test)
