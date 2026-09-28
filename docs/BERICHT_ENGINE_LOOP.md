# Bericht Engine Teil 1 — Backing-Loop (28.09.2026)

Spec: `docs/superpowers/specs/2026-09-28-engine-loop-design.md`,
Plan: `docs/superpowers/plans/2026-09-28-engine-loop.md`, Branch `engine-loop`
(gestapelt auf `k2-result`, Draft-PR #26).

Entscheidungen des Auftraggebers (28.09.): Engine-Phase in der Reihenfolge
**Loop → Dynamik → Messung**; der Loop ist **nur zum Hören** (Band aus dem
Handy), gespielt wird weiter einstimmig am Pad; Besetzung **Kick + Hi-Hat**;
Katalog-Zielgröße 12 / 8 / 6.

## Was gebaut wurde

Zu jeder Pad-Übung kann jetzt eine kleine Band aus Kick und Hi-Hat mitlaufen.
Sie steckt in derselben gerenderten Schleife wie das Muster, ist also
sample-genau synchron, passt in jedes Tempo ohne Zeitdehnung und hat ihre
eigene Lautstärke.

- **Klänge** (`lib/features/metronome/backing_sounds.dart`): synthetisch wie
  Klick und Rim, keine Samples, keine Lizenzen. Kick = Tonsturz 150 → 48 Hz
  mit kurzem Anschlag (~180 ms); Hi-Hat = gefiltertes Rauschen, geschlossen
  ~60 ms, Akzent („leicht offen") ~160 ms. Deterministisch, damit Tests und
  Renders stabil sind.
- **Stil-Vorrat** (`backing_styles.dart`): sechs Stile, je ein Takt 4/4 auf
  dem 24-Tick-Raster.

  | Stil | Feel | Kick | Hi-Hat |
  |---|---|---|---|
  | Rock 8ths | gerade | 1, 3 | Achtel, Viertel lauter |
  | Rock 16ths | gerade | 1, 3, „&" von 3 | Sechzehntel, drei Pegel |
  | Half-time | gerade | 1, „&" von 2 | Achtel, 1 und 3 betont |
  | Shuffle | Shuffle | 1, 3 | je Viertel 1 und dritte Triole |
  | Swing | Swing | leise „Feder" auf 1–4 | Ride-Muster spang-a-lang |
  | Funk 16ths | gerade | 1, „a" von 1, „&" von 2, 3, „a" von 3 | Sechzehntel |

  Übungen mit zwei Vierteln je Takt nehmen die ersten zwei Viertel des
  Stils. Jede Übung kann in ihren Daten einen Standard-Stil mitbringen
  (`Rudiment.backing`); die heutigen Übungen bringen keinen mit.
- **Mischer** (`click_loop_renderer.dart`, `loop_voices.dart`): Der Renderer
  mischt jetzt eine Liste von Stimmen (Muster, Klick-Spur, Kick, Hi-Hat) mit
  eigener Lautstärke statt fest „Muster plus Puls". Ein weicher Begrenzer
  (linear bis 0,8, darüber sanft bis höchstens 0,98) ersetzt das harte
  Abschneiden; vier Stimmen verzerren nicht mehr. Die Schleife ist so lang
  wie das kleinste gemeinsame Vielfache von Muster und Takt, damit der
  Stil-Takt ganz bleibt (19 der 41 Basis-Rudiments sind kürzer als ein Takt).
  Ohne Backing ändert sich nichts.
- **Bedienung:** Im „⋯"-Blatt ein Abschnitt BACKING mit „Off" und den sechs
  Stilen sowie ein Level-Regler (0–100 %, nur mit Stil aktiv). Die Wahl wird
  je Übung gemerkt (auch ein bewusstes „Off"), der Pegel global (Standard
  70 %).
- **Kopfhörer-Regel im Analyse-Modus:** Das Mikro würde Band und Klick-Spur
  mithören. Beide laufen im Analyse-Modus nur mit erkannten Kopfhörern;
  ohne bleiben sie stumm, die Schalter sind gesperrt mit dem Hinweis „Off
  while analysing without headphones — the mic would hear it". Die
  Kopfhörer werden beim Start abgefragt und bei jedem Wechsel, den das
  Metronom als Routenwechsel meldet (neuer Zähler `audioRouteChanges` im
  Metronom-Zustand). Im Lern-Modus keine Einschränkung.
- **Nebenbei behoben:** Vorschlagsnoten (Flam, Drag) wurden im Beat-Log als
  eigene Sollnoten mit dem Index der Vornote geführt und verzerrten die
  Hand-Werte. Das Log nimmt jetzt nur Hauptnoten
  (`PatternPlayback.isOnsetTick`).
- **Werkzeug:** `dart run tool/render_backing_demo.dart <ordner> [bpm]
  [takte]` rendert jeden Stil als WAV, einmal mit Achtel-Muster, einmal
  solo.

## Klang-Gate (28.09.)

Vor dem UI-Bau wurden alle sechs Stile bei 90 BPM über acht Takte gerendert
(12 Dateien, je 21,3 s, Spitzen 0,59–0,98) und als Hör-Seite mit zwölf
Playern vorgelegt:
https://claude.ai/artifact/9B7a4amq2jMGZ8r15SSgvv (Dateien in
`~/backing-demo/`). Urteil des Auftraggebers 12:45: „Ja, weiterbauen" —
Klänge und Stile blieben unverändert.

## Tests

- `backing_sounds_test.dart` (7): Längen, Spitzen, Nulldurchgangsrate
  (Kick tief, Hi-Hat Rauschen), deterministisch.
- `backing_styles_test.dart` (10): Katalog-Integrität, Eins immer hörbar,
  Auflösung gespeichert/Standard/Off/unbekannt, Kachelung über zwei Takte
  und bei 2/4.
- `click_loop_renderer_test.dart` (12, umgestellt): Stimmen mischen additiv,
  Gain wirkt, ungleiche Längen werfen, Begrenzer ohne Flat-Top, kgV.
- `loop_voices_test.dart` (7): ohne Backing Zyklus = Muster; Puls; Backing
  streckt auf ganze Takte und kachelt das Muster; 2/4; kein Backing außerhalb
  der 24-Tick-Uhr; Zyklus über 64 Takte lässt das Backing weg.
- `backing_provider_test.dart` (4): Zustand, unbekannte Kennung → Off,
  Pegel geklemmt, Routenwechsel-Zähler.
- `settings_backing_test.dart` (2), `pattern_playback_test.dart` (+1
  `isOnsetTick`).
- `practice_session_screen_test.dart` (+3): BACKING-Abschnitt mit Off und
  sechs Stilen, Wahl je Übung gemerkt, Slider nur mit Stil; Level-Regler
  schreibt den Pegel; Analyse-Modus ohne Kopfhörer stumm, mit Kopfhörern
  an, Wechsel über Routenwechsel-Meldung in beide Richtungen.
- Ganze Suite auf der GPU-Box: **375 Tests grün** (vorher 338), Analyzer nur
  die 12 bekannten `experimental_member_use`-Warnungen.

## Entscheidungen beim Bauen (Ledger)

- Begrenzer-Decke 0,98 statt asymptotisch 1,0: tanh erreicht für einen
  Dauerpegel numerisch 1,0, vier Stimmen lagen exakt auf 32767 (Test „kein
  Flat-Top" rot); die Spec verlangt „immer < 1,0". Kosten: 0,2 dB weniger
  Maximalpegel.
- Kopfhörer-Abfrage beim Screen-Start und bei jedem Routenwechsel, nicht
  beim Öffnen des Blatts: Der abgewartete Kanal-Aufruf vor dem Blatt ließ
  fünf bestehende Optionen-Tests ohne Kanal-Mock scheitern und ist
  redundant, weil Ein-/Ausstecken sofort gemeldet wird. Spec §6 angepasst.
- Die Anschlag-Klänge (Klick, Rim, Puls) wurden in `stroke_sounds.dart`
  als reine Funktionen herausgelöst, damit das Demo-Werkzeug ohne Flutter
  läuft; der Engine delegiert dorthin, sein Klang ist unverändert.

## Sichtprüfung

- Emulator (AVD s23, kein Ton beurteilbar): „⋯"-Blatt mit BACKING-Abschnitt,
  Stil gewählt, Level-Regler aktiv. Screenshots
  `~/k2-practice-screens/emu/b1_options.png`, `b2_style.png`, Seite
  `backing-emulator.html` daneben.
- Klang: Hör-Seite des Klang-Gates (oben).

## Offen

- Gerätetest am S23 mit Kabel-Kopfhörern: Stil wählen, Tempo ändern (Loop
  bleibt synchron), Analyse-Modus mit und ohne Kopfhörer, Flam-Übung messen
  (Hand-Werte plausibel).
- Das „⋯"-Blatt ist mit dem BACKING-Abschnitt länger und scrollt auf dem
  Handy; wenn das stört, zwei Blätter oder ein eigener Backing-Dialog.
- Bass als dritte Stimme (Entscheidung 28.09.: später).
- Feel der Übung selbst und feel-bewusste Jitter-Sperre (Teil 3), Dynamik
  (Teil 2), Aussetzen der Band im Fill-Takt als Option, Velocity-Layer für
  die Snare.
- Bluetooth-Kopfhörer verzögern das Gehörte; die Latenz-Kalibrierung deckt
  das nicht ab, Kabel empfohlen.
