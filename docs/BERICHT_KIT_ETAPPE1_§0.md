# Bericht: Etappe 1 (Kit-Messkern + ein Gate) — §0 Bestandsaufnahme

**Datum:** 11.11.2026 · **Bezug:** `docs/KONZEPT.md` Abschnitt 6 · **Stand:** entschieden
12.11. (E1, E3, E4), E2 offen bis zur Prüfung am Set

Laut Konzept ist der bestehende Code Steinbruch, nicht Basis. Dieser Bericht
listet je Modul Zweck, Zustand und Wiederverwendung auf. Er schlägt außerdem die
Abnahme-Zahlen vor, die das Konzept in §0 festlegen lässt (Abschnitt 4). Die
Entscheidungen trifft Uli (Abschnitt 5).

## 1. Wo der Altcode liegt (wichtig)

Der Altcode liegt an **zwei** Stellen:

- **main / Tag `legacy-v0`** (`ca785b0`): Pad-App mit Katalog, Blattform und
  Mikrofon-Messung. Hier gibt es **keinen** MIDI-Code.
- **Offener PR-Stapel #33 → #38** (Spitze `trainingsraum-etappe1`, `6c754a9`):
  Etappe 2 Phase A mit MIDI-Schlagquelle, Kit-Lernen, MIDI-Kalibrierung,
  gepatchtem Linux-Plugin und Kit-Notation, dazu „geführte Übungen“ und der
  Trainingsraum. **Fast alles, was für den Messkern taugt, liegt nur hier.**

`legacy-v0` sichert nur main. Der Stapel steht als Branches auf GitHub und ist
damit nicht verloren. Ein eigener Tag würde ihn aber genauso fest sichern
(Vorschlag `legacy-v0-stapel` auf `6c754a9`, siehe Entscheidung E1).

Die Tabelle unten beschreibt die Stapelspitze, also den vollständigeren Stand.

## 2. Zustand: Tests und Messung

Geprüft am 11.11. auf dem NUC (Flutter, Linux), Stand `6c754a9`:

- **Unit- und Widget-Tests:** 1022 bestanden, 0 fehlgeschlagen, 1 übersprungen.
  Übersprungen wurde der ALSA-Integrationstest, der nur mit Schalter läuft.
- **ALSA-Integrationstest** (`tool/midi/virtual_port_test.sh`): schlägt fehl,
  weil er fest auf Soundkarte 1 eingestellt ist (`Virtual Raw MIDI 1-0`,
  `/dev/snd/midiC1D0`). Auf dem neuen NUC ist der virtuelle MIDI-Port Karte 0.
  Mit Karte 0 läuft er grün: **64 von 64 Noten, Streuung p95 unter 0,5 ms, Flams
  25 ± 1 ms**. Das ist ein Fehler im Testaufbau, nicht im Code. Die Kartennummer
  muss automatisch erkannt werden.
- **Vorversuch Zeitstempel** (Bericht Etappe 2 §0, 11.10.): Der Stempel im
  Empfangs-Isolate streut p95 um 0,05 ms, auch unter Last. Der Stempel im
  Haupt-Isolate streut unter Last p95 um 8 ms und ist damit unbrauchbar. Der
  Patch nutzt den guten Stempel.
- **Am echten Set nie geprüft:** Die Abnahme von Phase A (Modul per USB,
  Latenz-Abgleich, Trefferquote) hat leere Befundfelder. Der MegaDrum war noch
  nie an der App.

„funktioniert“ heißt unten: Tests grün und Verhalten geprüft. „ungeprüft am Set“
heißt: Tests grün, aber nie mit echter Hardware gelaufen.

## 3. Module

Wiederverwendung: **ja** = in Etappe 1 übernehmen (ggf. angepasst) ·
**nein** = nicht übernehmen · **später** = Parkplatz, nach Etappe 1 neu bewerten.

### 3.1 Messkern (Schicht 1)

| Modul | Zweck | Zustand | Wiederverwendung |
|---|---|---|---|
| `packages/flutter_midi_command_linux` (gepatcht, ~1650 Zeilen) | ALSA-Sequencer-Anbindung. Patch: µs-Stempel im Empfangs-Isolate, virtuelle Ports sichtbar (`PATCH.md`) | funktioniert (virmidi), ungeprüft am Set | **ja**, Pflicht für Linux |
| `coaching/midi/midi_port_service.dart` | Gerät wählen, öffnen, Note-On parsen, Hot-Plug | funktioniert; nur Note-On, **kein CC** (Hi-Hat-Pedalstellung fehlt) | **ja** |
| `coaching/midi/midi_timestamp_mapper.dart` | Plugin-Stempel → gemeinsame ms-Achse (Linux µs, Android ns) | funktioniert (5 Tests) | **ja** |
| `coaching/midi/kit_instrument.dart` | `KitInstrument` (18 Instrumente), `KitMapping` Note → Instrument, JSON, GM-Vorgabe | funktioniert (9 Tests); **keine MegaDrum-Vorgabe** | **ja**, das ist die Mapping-Konfiguration |
| `coaching/midi/kit_learn_session.dart` + `settings/kit_learn_screen.dart` | Lernschritt „schlag auf …“, Zuordnung je Gerät gespeichert | funktioniert, ungeprüft am Set | **ja** |
| `coaching/midi/midi_stroke_source.dart` | Schlagquelle aus Port + Mapping; unbekannte Noten bleiben mit Rohnote erhalten | funktioniert (4 Tests) | **ja** |
| `coaching/midi/midi_latency.dart` + `settings/midi_calibration_screen.dart` | Latenz-Abgleich per Mitspielen (20 Viertel → Versatz + Streuung, Flag „unsicher“), je Gerät gespeichert | funktioniert, ungeprüft am Set; misst Ausgabe + Reaktion + MIDI **zusammen** | **ja**, Messverfahren siehe Abschnitt 4.1 |
| `coaching/services/stroke_source.dart` | Schnittstelle `StrokeEvent`/`StrokeSource` | funktioniert, reines Dart | **ja** |
| `coaching/services/sequence_aligner.dart` | Abgleich Soll-Zeiten ↔ Schläge (Needleman-Wunsch) → Treffer/fehlend/zusätzlich + Abweichung | funktioniert (9 Tests), reines Dart; nur eindimensional (Zeiten) | **ja**, Kern des neuen Abgleichs |
| `coaching/services/latency_estimator.dart` | Versatzschätzung über Median + Abgleich | funktioniert (7 Tests) | **ja** |
| `coaching/services/unassigned_metrics.dart` | Median/Streuung zum nächsten Klick | funktioniert (7 Tests) | **ja** |
| `coaching/services/stroke_analysis.dart` (377 Zeilen) | Gesamtauswertung: Latenzkorrektur, Vorschläge, Abgleich, Jitter, Aussetzer, Akzente | funktioniert für **ein** Instrument (fest `KitInstrument.pad`, Zeile 57/85). Falsches Instrument wird nicht als falsch gewertet. Hängt an Pad-Typen (Hand, Mikrofon-Konstanten) | **nein** als Ganzes. Ideen übernehmen, **neu schreiben als Abgleich je Stimme** |
| `coaching/services/lapse_detector.dart` | Aussetzer im gleitenden Fenster | funktioniert (6 Tests) | **später** |
| `coaching/models/session_analysis.dart` | Ergebnistypen | funktioniert; auf Hände ausgerichtet | **später**; neue, schlanke Ergebnistypen je Schlag |
| `data/local/models/session_log*.dart` | Sitzungsprotokoll je Schlag (Rohzeit, Abweichung, Instrument, Rohnote, Velocity im Feld `peakLevel`), dazu Gerät + Mapping, Klickzeiten, Latenzversatz, Export als JSONL | funktioniert; **nur Schreiben, kein Einlesen**; viele Handy-Felder | **ja**, schlank machen + **Leser für Wiedergabe** ergänzen |
| `metronome/` (Engine 692, Renderer, Loop-Stimmen, ~1930 Zeilen) | SoLoud-Loop, Uhr = Abspielposition, `BeatEvent.plannedAt`, Wächter bei verlorenem Audiogerät | funktioniert (~50 Tests); **Ausgabelatenz nicht bekannt** | **ja** für Klick + Loop; Begleitung **später** |
| `tool/midi/spike/*`, `tool/midi/virtual_port_test.sh` | Sender über virmidi, Empfänger, Auswertung | funktioniert; Testaufbau fest auf Karte 1 | **ja** als Testgerüst für die Reproduzierbarkeit |
| Mikrofon-Weg: `mic_analysis_service`, `onset_detector`, `mic_stroke_source`, `sample_clock_map`, `recording_setup`, `latency_calibration_service` (Lautsprecher → Mikro) | Pad über Handymikrofon | funktioniert (Android) | **später** (Parkplatz „Pad/Mikrofon“) |
| `ai_coaching_service`, `exercise_generator_screen`, `coach_feedback_card` | Claude-API-Rückmeldung, Übungsgenerator | funktioniert, braucht Netz | **nein** |

### 3.2 Fähigkeitsmodell (Schicht 2)

| Modul | Zweck | Zustand | Wiederverwendung |
|---|---|---|---|
| `room/round_verdict.dart` | Rundenurteil sauber/knapp/daneben aus Messwerten (Trefferquote ≥ 95 %, Extra ≤ 5 %, \|Median\| ≤ 15 ms, Streuung ≤ 20 ms) | funktioniert; feste Schwellen, nicht je Übung | **ja** als Vorlage für das Gate (Schwellen je Übung, Velocity dazu) |
| `room/tempo_ladder.dart` | ±4 BPM nach Urteil | funktioniert | **später** (Stufen-Modell) |
| `practice/core_values.dart` | Schwellen für die drei Kernwerte (Timing 5/15 ms, Gleichmaß 10/20 ms) | funktioniert | **ja** als Quelle für Schwellen |
| `learning/bpm_progression_service.dart`, `spaced_repetition_service.dart` | Tempo und Wiederholung aus **Selbstbewertung** 1–3 | funktioniert | **nein**, widerspricht „misst Können statt Selbstauskunft“ |
| `room/session_planner.dart`, `room_progress_service.dart`, `today/` | Zeitplan (Aufwärmen + Bereich), „Weiter“ fest auf Trainingsraum; Rückfall auf Selbstbewertung | funktioniert | **nein**; nächster Schritt kommt künftig aus den Gates |
| `stats/` | Minuten pro Tag, Meisterschaft nach Bestwert | funktioniert | **später**, dann Gate-Verlauf statt Minuten |

### 3.3 Pfad, Inhalte, Oberfläche (Schicht 3)

| Modul | Zweck | Zustand | Wiederverwendung |
|---|---|---|---|
| `lessons/models/rudiment.dart` (`Voice`, `ExerciseLine.kit`, `StrokeBeat`, `NoteValue`), `pattern_playback.dart` | Übungsmodell mit mehreren Stimmen, Raster 24 Ticks pro Viertel | funktioniert; `Rudiment` trägt viel Pad-Ballast | **ja** für Voice/ExerciseLine/NoteValue/Playback; `Rudiment`-Hülle schlank neu. **Fehlt:** Soll-Zeiten je Stimme in ms für die Messung |
| `lessons/data/etude_dsl.dart` | Kleine Schreibweise für Übungen (`voice`, `foot`, `kitLine`) | funktioniert (50 Tests) | **ja** |
| `lessons/data/sheets/groove_rock8_sheet.dart` | **Basic Rock Beat liegt schon vor:** Hi-Hat Achtel, Snare 2+4, Bassdrum 1+3 (`grooveRock8PatternVoices`) | funktioniert | **ja**; Einstiegsübung in gleicher Form neu (wenige Zeilen) |
| übrige 57 Blätter, `rudiments_seed.dart`, `etudes/` | Katalog: Rudiments, Pad-Etüden, Fills, Grooves | funktioniert | **später** |
| `shared/widgets/notation_staff_widget.dart`, `kit_layout.dart`, `kit_staff_painting.dart` u. a. | Notenzeile, kann Kit-Zeilen zeichnen, mit Golden-Tests | funktioniert | **ja**, Grundlage der Feedback-Ansicht (Treffermarken je Stimme) |
| `practice/practice_session_screen.dart` (2310 Zeilen) | Übungsbildschirm: Klick, Begleitung, Messung, Ergebnis | funktioniert für Pad/Mikro; **Kit-Übungen messen nichts** (Zeile 515–518, bewusst so) | **nein**; neuer, schlanker Übungsbildschirm |
| `practice/widgets/result_sheet.dart` | Ergebnisblatt: Urteil, Selbstbewertung, drei Kernwerte | funktioniert; Abweichung je Schlag nur als Debug-Text | **teilweise**: `VerdictBanner` ja, Selbstbewertung nein. **Feedback-Ansicht je Schlag fehlt** |
| `practice/widgets/line_view`, `kit_backing`, `pulse_bar` | Zeilenansicht, Kit-Begleitung, Pulsbalken | funktioniert | `line_view` **ja**; Rest **später** |
| `guided/` (31 Dateien, ~14 000 Zeilen) | Geführte Mitspiel-Übungen mit Stimme, eigener PCM-Player | funktioniert; **keine Messung** | **später**; der PCM-Player (`sample_bank`, `pcm_sink`, `run_clock`) ist ein Kandidat für ein sample-genaues Metronom |
| `room/` (außer Urteil) | Trainingsraum, Bereiche, Planer | funktioniert | **später** |
| `lessons_screen` und Bibliothek | Katalog durchsuchen | funktioniert | **nein** (Etappe 1 hat zwei Übungen) |
| `settings/` | Einstellungen, Messquelle, MIDI-Kalibrierung, Kit-Lernen, Mikro-Kalibrierung | funktioniert | MIDI-Teile **ja**; Mikro, Credits **später** |
| `onboarding/`, `services/notification_service.dart` | Tagesziel, Erinnerungen (unter Linux ohne Funktion) | funktioniert (Android) | **nein**; Einstieg = Einstiegsübung |
| `main.dart`, `app/router.dart` | Start, ~20 Routen | funktioniert | `main.dart` als Muster, Router **nein** (neu und klein) |
| `app/theme.dart`, `design_tokens.dart`, Schriften | Optik | funktioniert | **ja** |
| `app/platform_support.dart` | Linux/Android/Desktop-Weichen | funktioniert | **ja** |
| `data/local/isar_service.dart` | Isar-Datenbank (4 Schemas) | funktioniert unter Linux; `CleanTempo` tot. Isar 3 wird stromaufwärts kaum noch gepflegt (Einschätzung) | **ja** für Etappe 1; vor neuen Schemas Alternative prüfen |
| `tool/katalog/`, `tool/stimme/`, Bild-Werkzeuge | Katalog-Generator, Stimmclips, Fotos | funktioniert | **später** |

### 3.4 Abhängigkeiten (`pubspec.yaml`)

- **behalten:** `flutter_midi_command` (+ gepatchtes Linux-Plugin), `flutter_soloud`,
  riverpod, go_router, isar, path_provider, shared_preferences, intl, google_fonts
- **Parkplatz:** `record`, `permission_handler` (Mikrofon), `http` (KI),
  `flutter_local_notifications`, `timezone`, `share_plus`, `wakelock_plus`, `fl_chart`
- Die Beschreibung lautet noch „Android app … practice pad“.

## 4. Abnahme-Zahlen: Vorschläge

Das Konzept lässt diese Zahlen in §0 festlegen. Es sind **Vorschläge**. Schwellen
für das Gate lassen sich erst mit echten Messwerten am Set sauber einstellen.

### 4.1 Latenz (Konzept: „Restfehler ≤ X ms“)

Die Gesamtlatenz hat drei Teile: Klick-Ausgabe (Audio), MIDI-Eingang (Modul +
USB) und die Reaktion des Spielers. Der heutige Mitspiel-Abgleich misst alle drei
zusammen. Vorschlag:

- **Messung ohne Mensch (bevorzugt):** Der Klick-Ausgang geht per Kabel in einen
  Trigger-Eingang des MegaDrum (Loopback). Dann misst die App
  Audio-Ausgabe + MIDI-Eingang objektiv. Geht das mit dem MegaDrum nicht, bleibt
  der Mitspiel-Abgleich als Rückfall.
- **X = 2 ms (Loopback):** Nach der Kompensation liegt der Median der
  Loopback-Klicks innerhalb ±2 ms um null, die Streuung p95 ≤ 2 ms, in zwei
  Läufen nacheinander.
- **Rückfall Mitspielen: X = 3 ms**, nämlich zwei Abgleiche nacheinander mit
  Versatz-Differenz ≤ 3 ms. Diese Zahl stand schon in der Abnahme von Phase A.
- Dokumentiert werden: Gerät, Audio-Ausgang, Puffergröße, gemessener Versatz,
  Streuung.

### 4.2 Messkern reproduzierbar

- **Referenzdateien:**
  - **synthetisch**: MIDI-Folgen mit bekannten Abweichungen (z. B. +7 ms, fehlender
    Schlag, falsches Instrument, Flam), erzeugt vom vorhandenen Sender.
  - **echt**: am MegaDrum aufgenommene Läufe, gespeichert als JSONL im
    Sitzungsformat.
- **Kriterium:** Dieselbe Datei ergibt bei jedem Lauf **bitgleich** dieselbe
  Auswertung je Schlag. Bei synthetischen Dateien trifft die gemessene
  Abweichung den Sollwert auf ±0,1 ms genau. Jeder Fall (fehlend, zusätzlich,
  falsches Instrument) wird richtig erkannt.
- Läuft als normaler Test ohne Oberfläche, plus ein virmidi-Durchlauf mit
  automatisch erkannter Kartennummer.

### 4.3 Gate „Basic Rock Beat“

Vorschlag Stufe 1. Die Startwerte lehnen sich an das bisherige Rundenurteil
„sauber“ an, und Velocity ist neu dazugekommen:

| Größe | Schwelle |
|---|---|
| Dauer | 16 Takte am Stück |
| Tempo | 80 BPM |
| Trefferquote je Stimme (Hi-Hat, Snare, Bassdrum) | ≥ 95 % |
| Falsches Instrument | ≤ 2 % der Schläge |
| Zusätzliche Schläge | ≤ 5 % |
| Timing-Median (latenzkompensiert) | \|Median\| ≤ 15 ms |
| Timing-Streuung | ≤ 20 ms |
| Velocity-Konstanz Snare auf 2+4 | Standardabweichung ≤ 12 (MIDI-Einheiten 0–127), Platzhalter bis zu echten Daten |

Bestehen nur, wenn alle Zeilen erfüllt sind. Die Ansicht zeigt je Zeile Ist-Wert
und Schwelle, damit das Ergebnis aus den Messwerten nachvollziehbar ist.

### 4.4 Einstiegsübung

Konzept: Viertel Hi-Hat, Bassdrum auf 1 und 3, 8 Takte bei 70 BPM „ohne Abbruch“.
Vorschlag, was „ohne Abbruch“ heißt: Trefferquote ≥ 80 % je Stimme und keine
Lücke von mehr als einem Takt. Es gibt bewusst **keine** Timing-Schwelle, denn
die Übung prüft nur, ob jemand durchhalten kann.

## 5. Entscheidungen für Uli

- **E1 — Wo baut Etappe 1 auf?**
  - Empfehlung: **neu ab main**. Die Module mit „ja“ werden gezielt vom Stapel
    herüberkopiert (MIDI-Schicht, Plugin, Aligner, Latenz, Metronom, Modell + DSL,
    Notation, Theme). Vorher setzen wir den Tag `legacy-v0-stapel` auf `6c754a9`.
  - Danach können die PRs #33–#38 ohne Merge geschlossen werden. Der Stand bleibt
    über den Tag erhalten.
  - Alternative: den Stapel mergen und dann Altes entfernen. Das ist mehr
    Aufräumarbeit, und es entsteht genau der „Basis statt Steinbruch“-Effekt, den
    das Konzept vermeiden will.
- **E2 — Latenzmessung:** Loopback-Kabel (Klick → MegaDrum-Trigger) als
  Hauptweg? Dafür muss jemand am Set prüfen, ob ein freier Trigger-Eingang ein
  Line-Signal sauber auslöst.
- **E3 — Zahlen aus Abschnitt 4** so übernehmen oder ändern.
- **E4 — Plattform Etappe 1:** nur Linux-Desktop (wie seit 23.10. beim
  Drum-Coach üblich) oder Android mitziehen?

### Entschieden (Uli, 12.11.2026)

- **E1:** wie empfohlen. Etappe 1 baut neu ab main, die „ja“-Module werden vom
  Stapel herübergeholt. Der Tag `legacy-v0-stapel` (`6c754a9`) ist gesetzt, und
  die PRs #33–#38 sind ohne Merge geschlossen.
- **E2:** offen. Ob das Loopback-Kabel funktioniert, wird am Set geprüft. Bis
  dahin gilt der Rückfall „Mitspielen, 3 ms“.
- **E3:** Die Zahlen aus Abschnitt 4 sind so übernommen.
- **E4:** **Linux, Android und Windows.** Was das für die Zeitstempel heißt:
  - **Linux:** Stempel im Empfangs-Isolate, µs, gemessen p95 0,05 ms.
  - **Android:** Systemstempel aus `android.media.midi` (ns, monotone Uhr), vom
    Umrechner schon unterstützt. Gemessen ist er nie.
  - **Windows:** `flutter_midi_command_windows` 1.4.0 reicht den Treiberstempel
    von WinMM durch (`dwParam2` bei `MM_MIM_DATA`, ms seit `midiInStart`). Die
    Quelle ist gut, aber **nur auf 1 ms genau**. Der Umrechner braucht eine
    neue Einheit dafür. Gemessen ist das nie. Windows hat kein virmidi, deshalb
    braucht der Reproduzierbarkeitstest dort einen eigenen Weg, z. B. loopMIDI,
    oder er läuft nur auf Linux und den Referenzdateien.
  - Abnahme der Zeitstempel je Plattform: ein Lauf mit dem MegaDrum, die
    Streuung der Stempel liegt unter 1 ms (Windows: unter 1,5 ms wegen der
    ms-Auflösung).

## 6. Was Etappe 1 neu bauen muss

1. **Abgleich je Stimme** (Hi-Hat, Snare, Bassdrum getrennt, falsches Instrument
   als eigener Fall). Er ersetzt `stroke_analysis.dart` und baut auf
   `sequence_aligner.dart` auf.
2. **Soll-Zeiten je Stimme in ms** aus dem Übungsmodell.
3. **Leser für aufgezeichnete Sitzungen** (JSONL → Schlagfolge) für Referenzläufe.
4. **MegaDrum-Mapping-Vorgabe**, vom Gerät per Kit-Lernen bestätigt.
5. **Messung der Ausgabelatenz** (Loopback) bzw. Aufteilung des Versatzes.
6. **Gate mit Schwellen je Übung** auf Basis von `round_verdict.dart`, dazu
   Velocity-Konstanz.
7. **Eine Feedback-Ansicht**: Kit-Notenzeile mit Treffermarken je Schlag
   (früh/spät, fehlend, falsch, zusätzlich) und die Gate-Tabelle Ist ↔ Schwelle.
8. **Schlanker Übungsbildschirm** und Einstiegsübung.
9. **Testaufbau:** virmidi-Kartennummer automatisch erkennen.

Hi-Hat-Pedalstellung (CC 4) und offene/geschlossene Hi-Hat bleiben in Etappe 1
außen vor. Die beiden Übungen brauchen nur die geschlossene Hi-Hat.
