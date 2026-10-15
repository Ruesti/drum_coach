# tool/katalog — Blätter einmal schreiben, zweimal ausgeben

Der Katalog (Brief Pad-Übungen §7.3) wird in einer kleinen Notenschrift
komponiert und daraus erzeugt: die **Kurations-Seite** (abcjs, für Ulis
Urteil am Pad) und der **Dart-Code** (Blattform, `etude_dsl`).

```
sheetlang.py   Notenschrift: Parser, Prüfung (ganze Takte 1–8, 24er-Raster),
               Zählhilfe (wie countLabelsFor), ABC- und Dart-Ausgabe
blatt.py       Sheet: ein Blatt (8 Zeilen à line_bars Takte + Challenge 8 Takte),
               Formprüfung, Übersichtstabelle
katalog.py     Registry der Sätze: rudimente (3a), fills (3b) — Titel, Seed-Marker
rudimente.py   die zwölf Rudiment-Blätter + Lektionstexte (Daten, 2 Takte je Zeile)
fills.py       die acht Fill-Sticking-Blätter (3 Takte Time + 1 Takt Fill je Zeile)
build_page.py  Kurations-Seite → <ausgabe.html> [satz]
gen_dart.py    lib/features/lessons/data/sheets/<id>_sheet.dart (xPattern, xSheet, xLesson) [satz]
patch_seed.py  rudiments_seed.dart: Einträge auf Pattern/Lesson/Sheet umstellen, neue anhängen (alle Sätze)
```

## Notenschrift

Token je Note: `R16>` = Hand (`R`/`L`), Wert (`1 2 4 8 16 32`), Flags in
beliebiger Reihenfolge: `.` punktiert, `>` Akzent, `g` Ghost, `f` Flam (ein
Vorschlag mit der anderen Hand), `d` Drag (zwei). Pause `-8`. Triole
`3(R8 L8 R8)`, Sextole `6(R16 L16 R16 L16 R16 R16)`. Taktstriche `|` nur zur
Prüfung. Eine Zeile = 1–8 ganze Takte, ein Blatt ≤ 64 Takte.

## Blatt-Felder (blatt.py)

`line_bars` (2 Rudiment, 4 Fill; jede Zeile muss genau so lang sein),
`count_lines` (so viele erste Zeilen zählen), `backing` (Stil-Id oder None =
Automatik `autoBackingStyle`), `grid` (NoteGrid neuer Seed-Einträge),
`new_seed` (noch nicht im Basis-Katalog). Fill-Blätter: Takt 1 jeder Zeile
beginnt mit Akzent (die Eins nach dem Fill); auf der Kurationsseite steht
„Fill" über dem vierten Takt, in der App nicht.

## Ablauf

```
python3 tool/katalog/rudimente.py                      # prüft die Rudiment-Blätter
python3 tool/katalog/fills.py                          # prüft die Fill-Blätter
python3 tool/katalog/build_page.py /tmp/fills.html fills   # Kurations-Seite eines Satzes
python3 tool/katalog/gen_dart.py lib/features/lessons/data/sheets        # alle Sätze
python3 tool/katalog/patch_seed.py lib/features/lessons/data/rudiments_seed.dart
dart format lib/features/lessons/data/sheets lib/features/lessons/data/rudiments_seed.dart
flutter test test/lessons
```

Generierte Dart-Dateien nie von Hand ändern — Quelle sind `rudimente.py` und
`fills.py`. Reines Python 3, kein Flutter nötig; die Seite braucht abcjs aus
dem Netz.
