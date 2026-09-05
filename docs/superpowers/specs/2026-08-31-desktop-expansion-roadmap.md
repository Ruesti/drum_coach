# Roadmap: Desktop-Ausbau (Windows/macOS/Linux) + E-Kit-Integration

**Datum:** 2026-08-31
**Status:** Design validiert (Phase 1), Phasen 2–4 grob skizziert

## Kontext

DrumCoach ist heute vollständig auf Handy + Practice Pad ausgelegt (README:
„60cm-Kontext" — Lesbarkeit auf Armlänge). Der Nutzer hat zwei
Übungssituationen: unterwegs am Practice Pad (Handy), zuhause am vollen
E-Drum-Kit mit **Superior Drummer** als Sound-Engine. Ziel ist, die App
perspektivisch auch am Desktop nutzbar zu machen, mit MIDI-Anbindung ans
E-Kit und langfristig eigenen Mehrspur-Übungen (Grooves/Fills) für das volle
Kit — **zusätzlich** zur bestehenden Pad-Erfahrung, nicht als Ersatz.

## Warum das nötig ist

Laut `docs/AUDIT.md` existieren zwar Flutter-Desktop-Scaffolds
(linux/macos/windows), sie wurden aber nie gebaut, nie getestet, und es
fehlen grundlegende Plattform-Rechte (macOS-Entitlements) für Features, die
die App bereits hat (Mikrofon-Coaching, Netzwerk). Bevor über
MIDI-Anbindung oder Mehrspur-Notation nachgedacht werden kann, muss die App
überhaupt zuverlässig in einem Desktop-Fenster laufen.

## Locked Decisions (mit dem Nutzer abgestimmt)

- Zwei Übungssituationen bleiben nebeneinander bestehen: Pad/unterwegs
  (Handy) und Kit/zuhause (Desktop) — kein Ersatz.
- Zuhause läuft Superior Drummer als Sound-Engine; drum_coach soll das E-Kit
  über **MIDI** lesen (Note-Events), nicht über Mikrofon-Erkennung.
- Alle drei Desktop-Betriebssysteme sind Ziel. Windows und Linux sind für
  den Nutzer selbst testbar (eigener PC mit Superior Drummer bzw.
  Linux-Laptop); macOS ist ohne Testgerät nur CI-verifizierbar.
- Übungsinhalte sollen langfristig über reine Sticking-Rudiments
  hinausgehen (Kick/Hi-Hat/Toms/Becken, Grooves/Fills) — das ist der größte
  Umbau und kommt erst nach der MIDI-Anbindung.
- Jede Phase durchläuft eigenständig Spec → Plan → Umsetzung; diese Roadmap
  ist die Klammer.

## Bausteine

| # | Baustein | Kern | Hängt an | Eigene Spec |
|---|----------|------|----------|-------------|
| **P1** | Desktop-Plattform-Bootstrap | Scaffolds neu generieren, Entitlements, Feature-Gating (AI-Coaching, Notifications), CI-Matrix | — | `2026-08-31-desktop-platform-bootstrap-design.md` |
| **P2** | MIDI-Eingang vom E-Kit | Kit/Superior-Drummer-MIDI als neue Eingabequelle, Note-Events lesen | P1 | (folgt) |
| **P3** | Mehrspur-Notation & Groove/Fill-Content | Notation-Engine um Kick/Hi-Hat/Toms/Becken erweitern, neue Übungsautorenschaft, Mehrspur-Erkennung | P2 | (folgt) |
| **P4** | Desktop-UX für große Bildschirme | Eigenes Layout für den Kit-Kontext, ggf. gemeinsame Fortschrittshistorie Pad/Kit | P1 (kann parallel zu P2/P3 laufen) | (folgt) |

### P2 — MIDI-Eingang (Kurzskizze)

Technischer Kern der Kit-Anbindung: MIDI-Note-Events vom E-Kit oder per
Superior-Drummer-MIDI-Passthrough lesen, auf Voices (Snare/Kick/Hi-Hat/
Toms/Becken) mappen. Setzt eine laufende Desktop-Plattform (P1) voraus.
Welche Flutter-MIDI-Bibliothek und ob direkter Kit- oder
Superior-Drummer-Passthrough-Zugriff, ist noch offen.

### P3 — Mehrspur-Notation & Content (Kurzskizze)

Größter Umbau: die bestehende Notation-Engine (aktuell Einzelspur/Sticking,
siehe `2026-08-09-notation-engine-note-values-design.md`) müsste um mehrere
gleichzeitige Voices erweitert werden; neue Erkennungslogik vergleicht
Mehrspur-MIDI-Performance gegen eine Referenz. Umfang (welche Voices
zuerst, wie viele Übungen) ist noch offen.

### P4 — Desktop-UX (Kurzskizze)

Eigenes Layout für den „Zuhause"-Kontext (großer Bildschirm statt Handy in
Armlänge); ob Fortschritt/Spaced-Repetition zwischen Pad- und
Kit-Praxis geteilt wird, ist noch offen.

## Verifikation (übergreifend)

Diese Maschine (NUC, headless) kann keine Flutter-UI rendern. Windows- und
Linux-Builds werden über die `cross-machine-test-deploy`-Skill auf dem
Windows-PC (Superior Drummer) bzw. Linux-Laptop verifiziert. macOS hat
aktuell kein Testgerät — Verifikation dort ist auf CI-Build-Erfolg
beschränkt, bis ggf. ein Mac verfügbar wird.
