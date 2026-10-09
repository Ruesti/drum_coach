# Bericht: Katalog Schritt 3a — zwölf Rudiment-Blätter

Datum 09.10.2026 · Branch `katalog-rudimente` (von `main` 253367c) · Spec
`docs/superpowers/specs/2026-10-06-katalog-rudimente-design.md`.

## 1. Entscheidungen des Auftraggebers

- 06.10. „Katalog": Rubrik für Rubrik (Rudimente → Fill-Stickings → Stücke,
  je ein Draft-PR); **zwölf Rudiments ohne Six Stroke Roll** (er steckt als
  Zeile im Double-Stroke- und Paradiddle-Blatt).
- 09.10. „Alles plausibel, 32 von 32, Katalog": Mikro-Probe der Blattform am
  Pad bestanden (32 von 32 Treffern auf einer Zwei-Takt-Zeile) und die zwölf
  komponierten Blätter ohne Änderungswunsch freigegeben.
- Regel aus dem Blattform-Schritt: jede Übung so abwechslungsreich und
  groovy wie möglich; Lektion nur auf Abruf.

## 2. Was gebaut wurde

- **Werkzeug `tool/katalog/`** (reines Python, README dort): kleine
  Notenschrift (`sheetlang.py`: Token wie `R16>`, `L8.`, `R4f`, `R8d`, `-8`,
  `3(…)`, `6(…)`; Prüfung ganze Takte 1–8, 24er-Raster, ≤ 64 Takte;
  Zählhilfe-Regel identisch zu `countLabelsFor`), die zwölf Blätter mit
  Lektionstexten (`rudimente.py`), die abcjs-Kurationsseite
  (`build_page.py`), der Dart-Generator (`gen_dart.py`) und die Seed-
  Umstellung (`patch_seed.py`). Eine Quelle, zwei Ausgaben.
- **Zwölf Blätter**, je 8 Zeilen à 2 Takte mit Wiederholung + Challenge über
  8 Takte = 24 Takte: Single Stroke Roll, Double Stroke Roll, Single
  Paradiddle, Double Paradiddle, Paradiddle-Diddle, Flam, Flam Accent, Flam
  Tap, Single Drag, Five Stroke Roll, Seven Stroke Roll, Swiss Army Triplet.
  Zeile 1 = Grundgestalt als Zwei-Takt-Phrase; danach Achtel/Sechzehntel/
  Triolen/Viertel, Pausen, Synkopen, wandernde Akzente, Nachbar-Rudiments
  (Six Stroke Roll, Flam Paradiddle, Single Drag Tap, 13-Stroke-Roll, Flam
  Accent im Swiss-Blatt). Anfänger-Blätter (Single/Double Stroke, Single
  Paradiddle) tragen die Zählhilfe in Zeile 1–2. Lektion in vier
  Abschnitten: Why it matters · How to play it · Practice tips · Where you
  hear it (Songs nur, wenn sicher).
- **Generierte Dateien** `lib/features/lessons/data/sheets/<id>_sheet.dart`
  (je `xPattern`, `xSheet`, `xLesson`); `rudiments_seed.dart`: neun Einträge
  auf `sticking: xPattern`, `technique: xLesson`, `lines: xSheet`, drei neue
  Basis-Rudiments (Five Stroke Roll 60–140, Seven Stroke Roll 50–120, Swiss
  Army Triplet 50–110 advanced; alle Drum Corps). Das Paradiddle-Probestück
  ist ersetzt.

## 3. Abweichungen und Fallen

- Der Flam erhielt im Muster Akzente (`R4f> …`), weil der Migrationstest von
  August sie voraussetzt; die Drag-Grundgestalt ist jetzt ein ganzer
  4/4-Takt (vorher drei Viertel) — Test angepasst.
- Der drumCorps-Zähler steigt von 7 auf 10 (drei neue Einträge).
- Tests, die „die erste Katalog-Übung" als Ein-Zeilen-Beispiel nahmen,
  nehmen jetzt `multiple_bounce_roll` (Single Stroke Roll ist ein Blatt).
- abcjs quetschte die 8-Takt-Challenge in eine Zeile → die Kurationsseite
  bricht lange Zeilen wie die App in Zweitakt-Reihen um; größerer
  Reihenabstand gegen Akzent/Handsatz-Kollisionen.
- Flutter läuft seit dem Maschinenwechsel lokal auf dem NUC
  (`/home/uli/flutter/bin`): Tests, Analyzer, APK und Emulator ohne GPU-Box.

## 4. Tests

Ganze Suite lokal **447 grün**, Analyzer nur die 12 bekannten Warnungen.
Neu/angepasst: `etudes_integrity_test` (die zwölf: 9 Zeilen, Challenge
letzte ohne Wiederholung, 24 Takte, Muster = ein Takt, vier Lektionstitel,
Zählhilfe nur bei Anfängern), `flam_drag_migration_test`,
`rudiment_tags_test`, `lesson_detail_sheet_test`, `lessons_screen_meta_test`,
`practice_session_screen_test` (9 Zeilen / 24 Takte).

## 5. Sichtprüfung

Kurations-Seite (alle zwölf Blätter als Noten, Lektion eingeklappt):

https://claude.ai/artifact/77TvavmpjY28SHWPMqEbt6

Emulator (Debug-Build, NUC-Emulator, Stichprobe Five Stroke Roll als neuer
Eintrag: Library-Kachel, Übung vor dem Start, im Lauf, Optionen, Info-Seite
mit PATTERN · THE SHEET · LESSON):

https://claude.ai/artifact/DEsvCqZws7BNcDJFDjH4vT

## 6. Stand und nächste Schritte

Draft-PR offen (siehe PR). Danach 3b Fill-Stickings (8 Blätter: 3 Takte
Time + 1 Takt Fill je Zeile, Brief §3.2) und 3c Stücke (6, 8–16 Takte, Form),
beide über dasselbe Werkzeug; erst danach die 86 alten Étüden entfernen
(Brief §7.4). Gerätetest am S23 für die neuen Blätter nach Bedarf (Blattform
selbst ist dort geprüft).
