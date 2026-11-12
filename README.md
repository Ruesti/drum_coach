# DrumCoach

E-drum trainer (Linux/Android/Windows) that measures every hit via MIDI and
decides gates from the numbers.

## Stack

Flutter + Riverpod + go_router + flutter_soloud (audio) + flutter_midi_command
(E-drum MIDI input, patched Linux plugin in `packages/`) + shared_preferences +
path_provider. See `docs/CLAUDE.md` for the current architecture.

## Konzept

Gültig ist nur [`docs/KONZEPT.md`](docs/KONZEPT.md). `docs/archive/` ist Referenz, kein Auftrag.

## Development

```
flutter pub get
flutter analyze
flutter test
```
