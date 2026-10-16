# Design-Spec: Katalog Schritt 3b — acht Fill-Sticking-Blätter

Datum 10.10.2026 · Branch `katalog-fills` (gestapelt auf `katalog-rudimente`,
Draft-PR #30) · Status: Entwurf; Kuration der komponierten Blätter durch den
Auftraggeber am Pad oder vom Blatt.

Vorlagen: Pad-Brief `BRIEF_PAD_UEBUNGEN.md` §3.2 (Fill-Stickings), §4
(Karteikarte), §6 (komponiert, nicht kopiert), §7.3; Spec 3a
`2026-10-06-katalog-rudimente-design.md` (Werkzeug, Lektionsform); Befund G
„Fill setzen, wieder einsteigen". Vorbilder (Stick Control, Syncopation,
Drumeo-Fill-Lektionen, Rock-Fill-Standards) liefern Prinzipien, keine Zeilen.

## 0. Entscheidungen des Auftraggebers

- 10.10.: **die acht = die sechs aus dem Brief plus Doubles-Fill und
  Roll-Fill**: Sechzehntel-Singles, Doubles, Paradiddle, Triolen, Flam,
  Sextolen, Sechser-Gruppen, Roll.
- Brief §3.2: **3 Takte Time-Muster plus 1 Takt Fill**, geloopt als
  Vier-Takt-Phrase; Time einstimmig (Achtel R L oder ein Rudiment als Time);
  die Band kommt aus dem Loop und läuft im Fill-Takt weiter, damit die Eins
  danach sitzt. Erfolg = Fill getroffen und die Eins danach sauber.
- Aus 3a: jede Übung so abwechslungsreich und groovy wie möglich; Lektion nur
  auf Abruf; Rubrik für Rubrik, je ein Draft-PR.

## 1. Ziel und Nicht-Ziele

**Ziel.** Acht Fill-Blätter im Katalog als `Rudiment`-Einträge mit `lines`,
Skill `fill`, Lektion und Stammdaten, erzeugt über dasselbe Werkzeug wie 3a.

**Nicht-Ziele.** Der Fill-Einstieg als eigener Messwert (Brief §5 Punkt 5,
Engine); Text „Fill" über dem System in der App (§5 Punkt 3) — die
Kurationsseite zeigt ihn, die App nicht; ein Aussetzen der Band im Fill-Takt
(bewusst nicht, Brief §3.2); Fills aus Song-Auszügen (Battery) — eigener
Schritt, wenn die Transkriptions-Auswertung steht; Stücke (3c); Entfernen der
86 Étüden (nach 3c). Keine Änderung an Blattform-Code außer Daten.

## 2. Form eines Fill-Blatts

- **8 Zeilen à 4 Takte** mit Wiederholung: Takt 1–3 Time, Takt 4 Fill;
  danach **Challenge 8 Takte** ohne Wiederholung (zweimal 3 + 1 mit zwei
  verschiedenen Fills) = **40 Takte** je Blatt (≤ 64 ✓). Auf dem Handy
  (zwei Takte je Reihe) ist eine Zeile zwei Reihen, das Fenster zeigt zwei
  Zeilen.
- **Takt 1 jeder Zeile beginnt mit Akzent**: das ist die Eins nach dem Fill,
  der „Crash". Beim Wiederholen der Zeile und im Blatt-Modus landet jeder
  Fill genau dort.
- **Time-Muster** wechseln von Zeile zu Zeile aus einem kleinen Vorrat, alle
  einstimmig: Viertel mit Backbeat (`R4 L4> R4 L4>`), Achtel, „Rock-Hände"
  (`R8 R8 L8> R8 R8 R8 L8> R8` — rechts die Hi-Hat-Achtel, links die Snare
  auf 2 und 4), Sechzehntel mit Backbeat, Half-Time-Hände (Snare auf 3),
  Galopp (`R4 L8 L8`), Shuffle-Hände (nur Triolen-Blatt), Paradiddle-Time
  (Paradiddle-Blatt).
- **Fill-Takt**: Zeile 1 die Grundform des Fill-Typs über den ganzen Takt;
  danach Varianten: Akzent-Gruppen, halber Takt (Time auf 1–2, Fill auf 3–4),
  ein Schlag Fill (nur Zählzeit 4), Auftakt ab „und von 2", Löcher (Pausen),
  Verdopplung (32tel-Ausbruch), Mischung mit dem Nachbar-Typ.
- **Ein Blatt, ein Feel.** Die Band ist je Übung, nicht je Zeile: das
  Triolen-Blatt lebt im Shuffle (Shuffle-Hände als Time, Automatik wählt
  `shuffle`), alle anderen Blätter sind gerade. Das Sextolen-Blatt setzt
  `backing: rock8` ausdrücklich, weil die Automatik bei Tuplets sonst Shuffle
  wählt; Paradiddle und Sechser-Gruppen tragen Genre `funk` (Band `funk16`).
- **PATTERN-Kasten** (Info-Seite, `sticking`) = der Fill-Takt der Zeile 1.
  **Lektion** vier Abschnitte wie 3a: Why it matters · How to play it
  (mit dem Hör-Hinweis „listen for …") · Practice tips · Where you hear it
  (musikalischer Ort; Songs nur, wenn sicher).
- **Zählhilfe** in Zeile 1–2 bei Anfänger-Blättern (Sechzehntel-Singles,
  Doubles).

| id | Name | Stufe | Tempo | Raster | Band |
|---|---|---|---|---|---|
| fill_sixteenth_singles | Sixteenth Singles Fill | beginner | 60–130 | 16tel | Automatik (rock16) |
| fill_doubles | Doubles Fill | beginner | 60–120 | 16tel | Automatik (rock16) |
| fill_paradiddle | Paradiddle Fill | intermediate | 60–120 | 16tel | funk16 (Genre funk) |
| fill_triplets | Triplet Fill | intermediate | 60–130 | Triolen | Automatik (shuffle) |
| fill_flams | Flam Fill | intermediate | 60–110 | 16tel | Automatik |
| fill_sextuplets | Sextuplet Fill | advanced | 50–100 | 16tel-Triolen | rock8 (explizit) |
| fill_six_groups | Six-Note Groups Fill | advanced | 60–110 | 16tel | funk16 (Genre funk) |
| fill_roll | Roll Fill | advanced | 60–110 | 32tel | Automatik (rock16) |

Skills: alle `fill`, dazu `control` (Singles, Doubles, Flam, Sextolen,
Roll) oder `coordination` (Paradiddle, Triolen, Sechser-Gruppen). Kein
Drum-Corps-Tag (der Zähler bleibt 10).

## 3. Werkzeug — `tool/katalog/`

- `blatt.py`: die Klasse `Sheet` (aus `rudimente.py` herausgelöst) mit neuen
  Feldern `line_bars` (2 bei Rudimenten, 4 bei Fills; geprüft), `backing`
  (Stil-Id oder None) und `grid` (NoteGrid-Name für neue Seed-Einträge,
  ersetzt die GRID-Tabelle in `patch_seed.py`).
- `katalog.py`: Registry der Sätze — `rudimente` (3a) und `fills` (3b) mit
  Titel, Einleitung und Seed-Marker; alle Generatoren laufen über sie.
- `fills.py`: die acht Blätter + Lektionstexte (Daten, Englisch).
- `build_page.py <html> [satz]`, `gen_dart.py <dir> [satz]`,
  `patch_seed.py <seed>` (alle Sätze; neue Einträge je Satz unter eigenem
  Marker, `backing`/`gridUnit` aus den Daten). Die Kurationsseite schreibt
  „Fill" über den vierten Takt jeder Vier-Takt-Gruppe (abcjs-Annotation,
  `sheetlang.line_to_abc(marks=…)`), die App nicht.

## 4. Ablauf

1. Komponieren der acht Blätter in `fills.py`; `python3 tool/katalog/fills.py`
   prüft Takt-Summen und Form.
2. Kurationsseite rendern, sichten, veröffentlichen; Kopie
   `~/katalog-fills.html`. Kurations-Gate: Uli urteilt („macht Spaß, klingt
   nach Musik, ist messbar"); Änderungen gehen in `fills.py`.
3. Dart-Dateien generieren, Seed anhängen (acht neue Einträge unter
   „KATALOG 3b"), `dart format`, Tests, Analyzer, Emulator-Stichprobe,
   Draft-PR auf #30, Bericht `docs/BERICHT_KATALOG_FILLS.md`.

## 5. Tests

- Python: `fills.py` als Skript (jede Zeile 4 ganze Takte, Challenge 8, 40
  je Blatt, 24er-Raster).
- Dart, neu: `etudes_integrity_test` „the eight fill sheets": 9 Zeilen,
  Zeilen 1–8 je 4 Takte mit Wiederholung, Challenge 8 Takte ohne, 40 Takte,
  Muster = ein Takt, Skill `fill`, vier Lektionstitel, Zählhilfe nur bei den
  beiden Anfänger-Blättern, erste Note jeder Zeile akzentuiert;
  `auto_backing_test`: das Sextolen-Blatt spielt gerade (`rock8`), das
  Triolen-Blatt Shuffle, Paradiddle `funk16`; `rudiment_tags_test`:
  drumCorps bleibt 10. Vorhanden und nur Daten neu: `seed_integrity`,
  `notation_staff_test` (alle Blätter rendern), `lessons_screen_meta_test`.

## 6. Dateien

- Neu: `tool/katalog/blatt.py`, `tool/katalog/katalog.py`,
  `tool/katalog/fills.py`; `lib/features/lessons/data/sheets/fill_*_sheet.dart`
  × 8 (generiert); `docs/BERICHT_KATALOG_FILLS.md`.
- Ändern: `tool/katalog/{rudimente,sheetlang,build_page,gen_dart,patch_seed}.py`,
  `tool/katalog/README.md`, `rudiments_seed.dart` (acht Einträge angehängt),
  Tests, `docs/CLAUDE.md` (Hinweis 3b).
