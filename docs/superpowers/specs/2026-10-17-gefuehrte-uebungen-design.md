# Geführte Übungen — 5-Minuten-Groove mit Variationen und Ansage-Stimme

Stand: Entwurf 17.10.2026 · Branch `spec-gefuehrte-uebungen` (gestapelt auf
`worktree-etappe2-phase-b`, Draft-PR #35) · Status: **von Uli freigegeben 18.10. 11:06** (Rückfragen F1–F3 beantwortet 17.10. 23:54).

Vorbild: Drumeo Method (Uli hat am 17.10. eine Lektion durchgespielt). Prinzipien
übernehmen, keine Inhalte kopieren.

## 0. Ulis Wünsche (Wortlaut sinngemäß, 17.10.)

- Übungen von **ca. 5 Minuten**: ein **Grundgroove**, zu dem **immer wieder eine
  Variation** dazukommt. Bei Drumeo sagt der Lehrer an — drum_coach soll das selbst
  ansagen, „ohne teuren Lehrer".
- Gut an Drumeo: **gute Grooves mit eingebauter Herausforderung** und **Zeiten zum
  Relaxen**; **kurzer Countdown vor jeder Änderung**; **Name und Schwierigkeit**
  der Übung vorher sichtbar und auswählbar.
- Schlecht an Drumeo: Tempo nicht änderbar. → drum_coach: **Tempo änderbar, auch
  während der Übung**.
- **Lehrer an- und abschaltbar.**
- Ablauf: **nach jeder schweren Variation zurück zum einfachen Grundgroove**;
  **Anfang und Ende mit Crash** o. ä.
- Die Stimme soll **wie ein Lehrer erklären**, was sich ändert (nicht nur „Variation 2").
- **Set und Pad gleich beide** (gleicher Ablauf, eigene Inhalte).
- Umfang: **eine Handvoll pro Schwierigkeitsgrad** (je Paket).
- **Timing messen** — „ist ja eine Hauptfunktion der App"; Auswertung **je Abschnitt**.
- Anti-Ziel: **langweilige Übungen**.
- Wunsch **kleine Hintergrundband** zu den Grooves — **ausdrücklich zweiter Schritt**
  („zuerst Übungen, dann Band").
- Rückfragen (17.10. 23:54): **F1 Kopfhörer** und **F2 Mitspielen** wie vorgeschlagen
  (siehe 3.4a/3.8), **F3 Bildschirmtexte Englisch**.

## 1. Ist-Zustand (Branch `worktree-etappe2-phase-b`, 2098c55)

- Modell: `Rudiment` (id, name, `difficulty`, minBpm/targetBpm, `gridUnit`,
  `beatsPerBar`, `sheet` = Zeilen), `ExerciseLine` (Pad-Zeile oder `.kit(List<Voice>)`).
  Folgen: `SheetPlan.sequence(...)`, Grenzen `maxSequenceBars = 64`,
  `maxSequenceRepeats = 4`.
- Katalog: Python-Generatoren `tool/katalog/*.py` → Dart-Dateien in
  `lib/features/lessons/data/sheets/`; Grooves in `grooves.py`, Set-Fills
  `set_fills.py`, Pad-Fills `fills.py`; Kuration über eine HTML-Seite.
- Wiedergabe (`metronome_engine.dart`, `loop_voices.dart`,
  `click_loop_renderer.dart`): rendert **eine ganze Schleife als WAV** (200–400 ms,
  Hintergrund-Isolat) und loopt sie in SoLoud. Max. 64 Takte. `setBpm` = Neu-Rendern
  und Neustart (nicht nahtlos, Position geht verloren). Kein Einzähler.
  `beatStream` liefert `BeatEvent(beatIndex, plannedAt)`.
- Klänge: `flutter_soloud ^3.2.0`; einziges Sample `assets/audio/snare.mp3`, Rest
  synthetisch (`backing_sounds.dart`, `stroke_sounds.dart`). **Kein Crash-Klang**
  (Becken spielen den Musterklang, `kit_backing.dart`).
- **Keine Sprachausgabe**, keine Sprachaufnahmen.
- Schwierigkeit: `Difficulty` (beginner/intermediate/advanced/professional, Label +
  Farbe), angezeigt in Bibliothek, Sammlung, Info-Seite.
- Messung: Pad über Mikrofon (`coaching/services/onset_detector.dart`,
  `stroke_analysis.dart`, Latenz-Kalibrierung) vorhanden. **Set nicht messbar** bis
  Etappe 2 Teil 2 (MIDI, B.3) — der Screen zeigt `NOT MEASURABLE`.
- Plattformen: Android (S23) und Linux-Desktop (Bundle auf dem Laptop bauen, glibc).

## 2. Ziel, Nicht-Ziele, Anti-Ziele

**Ziel.** Eine neue Übungsform „geführte Übung": ein festgelegter Ablauf von ca.
5 Minuten aus Grundgroove und Variationen, den die App abspielt, ansagt, (beim Pad)
misst und je Abschnitt auswertet. Zwei Pakete (Set, Pad), je ca. 5 Übungen pro
Schwierigkeitsgrad → ca. 40 Übungen.

**Nicht-Ziele (diese Spec).**
- Hintergrundband (Bass/Akkorde) — eigener zweiter Schritt, eigene Spec.
- Messung am Set — kommt mit Etappe 2 Teil 2 und wird dann angeschlossen.
- Eigene Übungen zusammenstellen, Fortschritt/Programm-Einbindung (Heute, Routine).
- Andere Taktarten als 4/4 (falls ein Inhalt 6/8 bräuchte: weglassen).
- Video, Lehrer-Bild, Avatar.

**Anti-Ziele (wäre ein Fehlschlag, auch wenn es technisch läuft).**
- **Langweilig**: Grooves, die keiner spielen will; Variationen ohne Reiz; ewig
  gleiche Ansagen.
- Ansage überrumpelt: Wechsel ohne Vorwarnung oder Erklärung mitten in der schweren
  Stelle.
- Tempowechsel bricht die Übung ab oder holpert hörbar.
- Stimme und Schlagzeug kommen sich in die Quere (Aussetzer, Ducking, Latenz).

## 3. Entwurf

### 3.1 Ablauf einer Übung

```
Crash · Grundgroove (Einspielen)
  → Erklärung (Stimme, während Groove) → Countdown (letzter Takt) → Variation 1
  → Grundgroove (Relaxen) → Erklärung → Countdown → Variation 2
  → … (3–5 Variationen)
  → Grundgroove → Schluss mit Crash auf der Eins
```

- **Variationen bauen aufeinander auf** oder steigern sich (meist; Kuration
  entscheidet). Nach jeder Variation kommt **immer** der Grundgroove (Ulis Regel).
- **Optional (Kurations-Entscheidung je Übung):** eine letzte „Kombi"-Variation, die
  zwei vorherige abwechselt.
- **Länge:** Zielwert 5 min ± 1 bei Standardtempo. Abschnittslängen in Takten
  (typisch Groove 4–8, Variation 8–16). Bei anderem Tempo ändert sich die Dauer, die
  Taktzahl nicht (Ausnahme 3.3).
- **Einstieg:** vor dem ersten Crash ein Einzähler (1 Takt, Klicks + Stimme
  „eins, zwei, drei, vier" bzw. nur Klicks bei Lehrer aus).

### 3.2 Ansage („Lehrer")

- Die Stimme **erklärt wie ein Lehrer**, was sich ändert, z. B. „Gleich kommt die
  Bassdrum zusätzlich auf die Und von drei." / Pad: „Jetzt Akzent auf jeder ersten
  Sechzehntel." Kurz (≤ ~4 s), konkret, freundlich. Dazu gibt es wenige Lob- oder
  Übergangssätze („Gut — zurück zum Groove.", „Letzte Runde.").
- **Wann:** die Erklärung läuft **im Grundgroove vor dem Wechsel** und ist fertig,
  bevor der Countdown beginnt; der **Countdown liegt im letzten Takt** vor dem
  Wechsel auf den Schlägen 2–4 + Eins („drei, zwei, eins, los"/„jetzt").
- **Sprache:** Bildschirmtexte (Banner, Zeile über den Noten, Liste, Vorschau)
  **Englisch** wie die übrige App (Ulis Antwort F3). Stimme **Deutsch** *(meine
  Entscheidung aus dem Gespräch; F3 betraf nur den Bildschirm)*. Folge: jede
  Erklärung hat **zwei Texte** (`textEn` für den Bildschirm, `speechDe` für den Clip),
  beide im Katalog-Werkzeug an einer Stelle gepflegt und auf der Kurationsseite
  nebeneinander gezeigt. Die Sprache der Stimme ist eine Katalog-Einstellung, damit ein
  Wechsel auf Englisch nur ein Neu-Rendern der Clips ist.
- **Lehrer aus:** gleicher Ablauf; statt Stimme ein **Hinweis-Banner** mit demselben
  Erklärtext, Countdown als Zahlen im Banner + betonter Klick auf den Countdown-
  Schlägen. Schalter im Übungs-Screen, Einstellung wird gemerkt.
- **Text auf dem Bildschirm:** der Erklärtext steht während der Variation auch als
  Zeile über den Noten (sonst vergisst man, was gerade dran ist).

**Wie die Stimme entsteht (meine Entscheidung, durch Spike zu bestätigen, §5 Phase 0):**
Die Sätze werden **beim Katalog-Bau** mit einer guten Offline-Sprachsynthese (z. B.
Piper, deutsche Stimme) zu **kurzen Audiodateien vorgerendert** und als Assets
mitgeliefert; abgespielt werden sie **über SoLoud**, in denselben Ablauf eingeplant
wie die Schläge. Gründe: (1) Dauer jedes Satzes ist vorher bekannt → exakte Planung
vor dem Countdown; (2) kein zweites Audio-System neben SoLoud (Risiko Android-Audio-
Fokus/Ducking entfällt); (3) gleiche Stimme auf Android und Linux-Desktop; (4) gleich
gute Qualität ohne Abhängigkeit von der Geräte-Sprachausgabe. Countdown-Wörter und
Zahlen sind ein fester kleiner Satz an Clips. Die Stimme wird **nicht** zeitgedehnt;
Countdown-Wörter beginnen auf dem jeweiligen Schlag.
Rückfallebene, falls Vorrendern scheitert: `flutter_tts` (Geräte-Sprachausgabe).

### 3.3 Tempo

- Standardtempo je Übung + erlaubter Bereich (wie `minBpm`/`targetBpm`).
- **Änderbar vor und während der Übung** (Tempo-Regler wie heute; Desktop ±).
  Der neue Wert greift **ab dem nächsten Takt**, nahtlos, die Übung läuft an
  derselben Stelle weiter.
- Ist die Relax-Phase bei hohem Tempo zu kurz für Erklärung + Countdown, wird sie
  automatisch **um ganze Takte verlängert** (Berechnung aus Clip-Dauer und Tempo).

### 3.4 Wiedergabe-Umbau (größter technischer Brocken)

Die heutige Ein-Schleifen-WAV trägt das nicht (64-Takt-Grenze, Neustart bei
Tempowechsel). Neu nötig: ein **Ablauf-Spieler**, der einen linearen Plan aus
Abschnitten abspielt — Takt für Takt bzw. in kurzen vorgerenderten Stücken
(z. B. je Takt oder je Abschnitt) — und dabei
- Tempo an Taktgrenzen nahtlos wechselt,
- Sprach-Clips, Crash und Countdown-Klicks auf Schläge plant,
- eine Positions-Uhr liefert (Abschnitt, Takt, Schlag) für Anzeige und Messung,
- Pause/Fortsetzen und Stopp kann.

Wie genau (Takt-weises Rendern mit Vorlauf, SoLoud-Scheduling, Streaming) ist
**Entscheidung des Bauenden**; Vorgabe ist nur: kein hörbarer Übergang zwischen
Takten, Jitter nicht schlechter als die heutige Schleife (bestehendes Jitter-Gate),
die vorhandene Schleifen-Wiedergabe für normale Zeilen bleibt unberührt.

### 3.4a Was die App mitspielt (Ulis Antwort F2)

- **Umschaltbar** im Übungs-Screen, Einstellung gemerkt: **„Groove mitspielen"**
  (die App spielt den laufenden Abschnitt — Grundgroove bzw. Variation — als
  Schlagzeugklang, man spielt mit, wie mit dem Lehrer bei Drumeo) **oder „nur Klick"**
  (Viertel-Klick, man spielt allein). Standard: Groove mitspielen.
- Klangquellen wie heute: Pad-Zeilen im Musterklang, Set-Zeilen mit
  `kit_backing`-Klängen (Kick/Hi-Hat-Samples, Rest Musterklang) + Crash-Sample.
- Countdown-Klick-Betonung (Lehrer aus) liegt auf dem Klick; in „Groove mitspielen"
  läuft für den Countdown-Takt zusätzlich ein Klick mit.
- Stimme liegt über dem Mix; Lautstärke-Balance Stimme : Schlagzeug ist ein Regler
  in ⋯ (Standard so, dass die Stimme klar über dem Groove liegt).

### 3.5 Klänge

- **Crash-Sample** neu (CC0/frei lizenziert, wie `snare.mp3`), auch für die
  Becken-Noten der bestehenden Set-Übungen nutzbar (Nebengewinn, nicht Pflicht).
- Pad-Übungen: Start/Schluss statt Crash ein deutlich anderer Akzent (z. B. derselbe
  Crash leise oder Glocke) — *meine Entscheidung, Kuration darf ändern*.

### 3.6 Liste und Auswahl

- Neuer Bereich **„Geführt"** in der Bibliothek *(Ort: meine Entscheidung)*,
  Umschalter **Set | Pad**, darunter Karten gruppiert oder filterbar nach
  Schwierigkeit. Karte: **Name, Schwierigkeit (bestehende Farbe/Label), Dauer bei
  Standardtempo, Tempo**, ein Satz Beschreibung („Rock-Achtel mit wandernder
  Bassdrum").
- Antippen → Vorschau: Abschnittsliste (Groove, V1…Vn mit Kurztext), Tempo-Wahl,
  Lehrer-Schalter, **Start**.

### 3.7 Übungs-Screen (während der Übung)

- Oben: Name, Abschnitt („Variation 2 von 4"), Fortschrittsbalken der 5 Minuten.
- Mitte: **Noten der aktuellen Zeile** (Grundgroove oder Variation) mit Cursor wie
  heute; während der Erklärung erscheint **die kommende Variation gedimmt darunter**,
  damit man sie vorher lesen kann.
- Banner: Erklärtext / Countdown.
- Unten: Tempo, Lehrer an/aus, Pause, Stopp.

### 3.8 Messung und Auswertung

- **Kopfhörer-Regel (Ulis Antwort F1):** gemessen wird **nur mit Kopfhörern**. Die
  App prüft vor dem Start (bestehende `audioRouteChanges`-Erkennung): mit Kopfhörern
  → Messung an; ohne → Hinweis „Plug in headphones to measure your timing", die
  Übung läuft trotzdem, **ohne Messung**. Werden die Kopfhörer mitten in der Übung
  abgezogen, endet die Messung ab dort (Auswertung nur für die Abschnitte davor).
  Grund: Stimme und Crash aus dem Lautsprecher würde das Mikrofon als Schläge zählen.
- **Pad:** Mikrofon-Messung (oder MIDI, falls ein Pad per MIDI angeschlossen ist —
  bestehende `StrokeSource`-Wahl) wie bei normalen Pad-Übungen, über den ganzen
  Ablauf; jeder Schlag wird seinem Abschnitt zugeordnet.
- **Set:** bis Teil 2 nicht messbar (wie heute `NOT MEASURABLE`, keine falsche Zahl).
  Der Ablauf liefert die Abschnitts-Zuordnung so, dass Teil 2 sich nur anschließen
  muss.
- **Auswertung je Abschnitt** nach der Übung: Grundgroove (zusammengefasst über alle
  Relax-Phasen) und jede Variation einzeln, mit denselben Kennzahlen wie die normale
  Ergebnis-Seite (Timing-Abweichung, Streuung, Trefferquote) und einem klaren
  Hinweis, welche Variation am wackligsten war („V3 üben"). Antippen einer
  Variation → normale Zeilen-Übung mit genau dieser Zeile (Schleife).
- Ergebnis wird im Sitzungs-Log gespeichert (Format nach Muster des bestehenden
  Logs; Details: Bauender).

### 3.9 Datenmodell und Katalog

- Neues Modell `GuidedExercise`: id, name, Beschreibung, Paket (kit/pad),
  `Difficulty`, Standard-BPM + Bereich, `beatsPerBar`/`gridUnit`, Liste von
  `GuidedSection` (Art: intro/groove/variation/outro, `ExerciseLine` der Zeile,
  Takte, Erklärtext + Clip-Id, optional Satz nach dem Abschnitt).
- Erzeugt über ein neues Katalog-Werkzeug `tool/katalog/gefuehrt.py` (wiederverwendet
  `grooves.py`-Bausteine und die DSL), das auch die **Sprach-Clips rendert** und die
  **Kurationsseite** baut (Noten je Abschnitt + Erklärtext + Abspielknopf für die
  Clips).
- Inhalte **komponiert, nicht kopiert** (wie 3a/3b). Leitlinie gegen Langeweile:
  bekannte, musikalische Groove-Stile (Rock, Funk, Shuffle, Disco, Half-Time, Bossa,
  Linear …) und je Übung ein roter Faden (z. B. „Bassdrum wandert", „Ghost Notes
  dazu", „Hi-Hat öffnen"). Pad: Grundmuster (Singles, Achtel/Sechzehntel, Triolen)
  mit Akzent-, Doppelschlag-, Paradiddle-, Flam-Variationen.
- **Lieferung in Runden** zur Kuration durch Uli: Runde 1 = je Paket 1 Übung pro
  Schwierigkeit (8 Übungen) zum Kalibrieren von Ton und Länge, dann der Rest.

## 4. Abnahme (Uli am S23 und Desktop)

1. Liste zeigt Set und Pad, je Schwierigkeit ~5 Übungen mit Name, Schwierigkeit, Dauer.
2. Eine Übung läuft ~5 min durch: Crash → Groove → Erklärung → Countdown → Variation
   → Groove … → Crash; nie ein Wechsel ohne Ansage + Countdown.
3. Tempo mitten in der Übung hoch/runter: kein Neustart, kein hörbarer Holperer.
4. Lehrer aus: Banner + Countdown statt Stimme, Ablauf identisch.
5. Pad: Auswertung je Abschnitt; Set: ehrlich „noch nicht messbar".
6. Uli findet die Übungen **nicht langweilig** (Kuration Runde 1).

## 5. Reihenfolge (Vorschlag)

- **Phase 0 — Wegwerf-Spike** (Pflicht vor allem anderen): vorgerenderter deutscher
  Sprach-Clip + Schlagzeug gleichzeitig über SoLoud auf dem S23 und Linux; dazu ein
  Ablauf über > 64 Takte mit Tempowechsel am Taktende. Ergebnis entscheidet 3.2/3.4.
- **Phase 1 — Ablauf-Spieler** (3.4) + Crash-Sample + Countdown.
- **Phase 2 — Modell, Katalog-Werkzeug, Sprach-Clips, Runde 1 Inhalte** (8 Übungen).
- **Phase 3 — Liste, Vorschau, Übungs-Screen, Lehrer-Schalter.**
- **Phase 4 — Pad-Messung + Auswertung je Abschnitt.**
- **Phase 5 — restliche Inhalte** (Runden bis ~40).
- Danach: Set-Messung (mit Etappe 2 Teil 2), dann **Hintergrundband** (eigene Spec).

## 6. Rückfragen an Uli (beantwortet 17.10.)

- **F1 Kopfhörer/Lautsprecher:** Messung nur mit Kopfhörern, ohne läuft die Übung
  ohne Messung → 3.8.
- **F2 Was spielt die App mit:** umschaltbar Groove mitspielen / nur Klick → 3.4a.
- **F3 Sprache der Bildschirmtexte:** Englisch → 3.2.

## 7. Meine Entscheidungen (zur Prüfung beim Lesen)

- **Basis:** gebaut wird gestapelt auf `worktree-etappe2-phase-b` (#35). Phase 0–2
  (Spike, Ablauf-Spieler, Modell/Katalog) berühren dessen Baustellen kaum; Phase 3–4
  (Screens, Log, „Variation antippen → Zeile üben") erst, wenn #35 nach Ulis
  Gerätetest (ab 24.10.) steht, sonst Rebase.
- Stimme Deutsch trotz englischer Bildschirmtexte (zwei Texte je Erklärung).

- Vorgerenderte Clips über SoLoud statt Geräte-Sprachausgabe.
- Erklärung im Groove davor, Countdown im letzten Takt („drei, zwei, eins, los").
- Tempo greift ab nächstem Takt; Relax-Phase verlängert sich bei Bedarf automatisch.
- Ort „Geführt" in der Bibliothek, Umschalter Set | Pad.
- Kommende Variation gedimmt sichtbar während der Erklärung; Erklärtext bleibt
  während der Variation stehen.
- Set-Messung erst mit Teil 2; bis dahin ehrlich „nicht messbar".
- Runde 1 = 8 Übungen (je Paket eine pro Schwierigkeit).
- Pad-Start/-Schluss mit Crash leise oder Glocke statt vollem Crash.
