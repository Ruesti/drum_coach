# Bericht: Katalog Schritt 3b — acht Fill-Sticking-Blätter

Datum 10.10.2026 · Branch `katalog-fills` (gestapelt auf `katalog-rudimente`,
Draft-PR #30) · Spec `docs/superpowers/specs/2026-10-10-katalog-fills-design.md`.

## 1. Entscheidungen des Auftraggebers

- 10.10.: **die acht = die sechs aus dem Brief plus Doubles-Fill und
  Roll-Fill** (Sechzehntel-Singles, Doubles, Paradiddle, Triolen, Flam,
  Sextolen, Sechser-Gruppen, Roll).
- Brief §3.2: drei Takte einstimmiges Time-Muster plus ein Takt Fill, als
  Vier-Takt-Phrase geloopt; die Band kommt aus dem Loop und läuft im
  Fill-Takt weiter; Erfolg = Fill getroffen und die Eins danach sauber.
- Aus 3a: jede Übung so abwechslungsreich und groovy wie möglich; Lektion
  nur auf Abruf; Rubrik für Rubrik, je ein Draft-PR.

## 2. Was gebaut wurde

- **Werkzeug `tool/katalog/`** kann jetzt mehrere Blattsätze: `blatt.py`
  hält die Klasse `Sheet` (neu: `line_bars` 2 oder 4, geprüft; `backing`
  Stil-Id oder Automatik; `grid` für neue Seed-Einträge), `katalog.py` die
  Registry der Sätze `rudimente` (3a) und `fills` (3b) mit Titel,
  Einleitung und Seed-Marker. `build_page.py`, `gen_dart.py` und
  `patch_seed.py` laufen über die Registry; ein Satzname als Argument
  wählt einen aus. `sheetlang.line_to_abc` schreibt auf Wunsch Text über
  Takte — die Kurationsseite zeigt „Fill" über dem vierten Takt, die App
  nicht. Die zwölf Rudiment-Dateien bleiben beim Regenerieren byte-gleich.
- **Acht Blätter** (`fills.py`), je 8 Zeilen à 4 Takte mit Wiederholung +
  Challenge 8 Takte (zweimal 3 + 1) = 40 Takte: Sixteenth Singles (60–130,
  beginner), Doubles (60–120, beginner), Paradiddle (60–120, funk),
  Triplet (60–130, Shuffle), Flam (60–110), Sextuplet (50–100, advanced,
  Band `rock8`), Six-Note Groups (60–110, advanced, funk), Roll (60–110,
  advanced, 32tel). Time-Muster wechseln von Zeile zu Zeile aus einem
  Vorrat (Viertel mit Backbeat, Achtel, Rock-Hände R R L> R, Sechzehntel
  mit Backbeat, Half-Time-Hände, Galopp, Shuffle-Hände, harter Shuffle,
  Paradiddle-Time); der Fill-Takt beginnt mit der Grundform und wandert
  durch Akzent-Gruppen, halben Takt, einen Schlag, Auftakt ab „und von 2",
  Löcher, 32tel-Ausbruch. **Takt 1 jeder Zeile beginnt mit Akzent — die
  Eins nach dem Fill.** Anfänger-Blätter zählen in Zeile 1–2. Lektion in
  vier Abschnitten mit Hör-Hinweis („listen for …").
- **Ein Blatt, ein Feel.** Die Band ist je Übung: das Triolen-Blatt lebt im
  Shuffle (Shuffle-Hände als Time; Automatik wählt `shuffle`, auch auf der
  punktierten Zeile über das Raster), das Sextolen-Blatt setzt `rock8`
  ausdrücklich (die Automatik würde wegen der Tuplets Shuffle wählen),
  Paradiddle und Sechser-Gruppen tragen Genre funk (Band `funk16`).
- **Generiert**: `lib/features/lessons/data/sheets/fill_*_sheet.dart` × 8;
  `rudiments_seed.dart`: acht neue Einträge unter „KATALOG 3b: fill
  stickings" (Skill `fill` + control/coordination, Raster und Band aus den
  Daten). In der Library findet sie der Skill-Chip „Fill".

## 3. Abweichungen und Fallen

- Auf dem Handy liegt **eine Reihe je Takt**, sobald eine Zeile Sechzehntel
  enthält (die feinste Note bestimmt die Mindestbreite; so auch in 3a bei
  den Roll-Blättern). Eine Vier-Takt-Zeile ist damit vier Reihen: ohne
  Zählband passen alle vier ins Fenster (die ganze Phrase), mit Zählband
  drei — der Fill-Takt rutscht dann beim Spielen herein. Keine Änderung am
  Blattform-Code (Nicht-Ziel der Spec).
- Der Options-Text sagt „Rock 8ths · automatic" auch beim ausdrücklichen
  Standard des Sextolen-Blatts — die Wahl ist aus Nutzersicht immer
  automatisch, das Ergebnis stimmt (ohne den Standard stünde dort Shuffle).
- Die Playwright-Erweiterung sucht nach einem Plugin-Update wieder das
  System-Chrome; die Kurationsseite wurde direkt mit dem gebündelten
  Chromium gerendert (`.superpowers/tmp/render_page.py`).
- Brief §3.2 nennt zusätzlich Fills aus den ausgewerteten Songs (Battery);
  das bleibt ein eigener Schritt, wenn die Transkriptions-Auswertung steht.
  Der Fill-Einstieg als eigener Messwert (Brief §5 Punkt 5) ist Engine,
  nicht Katalog.

## 4. Tests

Ganze Suite lokal **450 grün**, Analyzer die 12 bekannten Warnungen.
Neu: `etudes_integrity_test` „the eight fill sheets" (9 Zeilen, Zeilen 1–8
je vier Takte mit Wiederholung, Challenge 8 Takte ohne, 40 Takte, erste
Note jeder Zeile akzentuiert, Muster = ein Takt, Skill fill, vier
Lektionstitel, Zählhilfe nur bei Anfängern), `auto_backing_test` (Sextolen
rock8, Triolen shuffle, Paradiddle funk16), `rudiment_tags_test` (acht
`fill_*`, nie Drum Corps; der Drum-Corps-Zähler bleibt 10). Python:
`python3 tool/katalog/fills.py` prüft Takt-Summen und Form (8 × 40 Takte).

## 5. Sichtprüfung

Kurations-Seite (alle acht Blätter als Noten, „Fill" über dem vierten
Takt, Lektion eingeklappt):

https://claude.ai/artifact/8uwBHRFkp1NtYU9LzYQkbs

Emulator (Debug-Build, NUC-Emulator: Library mit Fill-Filter, Sixteenth
Singles Fill vor dem Start, im Blatt-Modus und im Lauf mit dem Cursor im
Fill-Takt, Sextuplet Fill mit Band „Rock 8ths", Info-Seite):

https://claude.ai/artifact/Hj8J7t91WX91fzBNUEVHRo

## 6. Stand und nächste Schritte

Draft-PR offen, gestapelt auf #30 (erst #30 mergen, dann dieser PR).
Kurations-Gate: Uli urteilt je Blatt und Zeile; Änderungen gehen in
`fills.py`, Seite und Dart werden neu erzeugt. Danach 3c Stücke (6, 8–16
Takte, Form), dann die 86 alten Étüden entfernen (Brief §7.4).
