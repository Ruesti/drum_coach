# DrumCoach

An Android app for practicing drum rudiments on a practice pad. Metronome,
sticking notation, spaced-repetition routine, a 12-week Stick Control
program, and optional AI coaching feedback from a phone microphone.

Built for practicing at arm's length from the phone — read
[`docs/design/60-cm-kontext-und-startpunkt`](docs/design/60-cm-kontext-und-startpunkt)
for the design rationale ("60cm": legibility at a glance beats subtlety).

## Stack

Flutter + Riverpod + go_router + Isar (local storage). See `docs/CLAUDE.md`
for the current architecture and `docs/AUDIT.md` / `docs/PHASES.md` for
project history.

## Development

```
flutter pub get
flutter analyze
flutter test
```
