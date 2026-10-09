# tool/katalog — Blätter einmal schreiben, zweimal ausgeben

Der Katalog (Brief Pad-Übungen §7.3) wird in einer kleinen Notenschrift
komponiert und daraus erzeugt: die **Kurations-Seite** (abcjs, für Ulis
Urteil am Pad) und der **Dart-Code** (Blattform, `etude_dsl`).

```
rudimente.py   die zwölf Rudiment-Blätter + Lektionstexte (Daten)
sheetlang.py   Notenschrift: Parser, Prüfung (ganze Takte 1–8, 24er-Raster),
               Zählhilfe (wie countLabelsFor), ABC- und Dart-Ausgabe
build_page.py  Kurations-Seite → <ausgabe.html>
gen_dart.py    lib/features/lessons/data/sheets/<id>_sheet.dart (xPattern, xSheet, xLesson)
patch_seed.py  rudiments_seed.dart: Einträge auf Pattern/Lesson/Sheet umstellen, neue anhängen
```

## Notenschrift

Token je Note: `R16>` = Hand (`R`/`L`), Wert (`1 2 4 8 16 32`), Flags in
beliebiger Reihenfolge: `.` punktiert, `>` Akzent, `g` Ghost, `f` Flam (ein
Vorschlag mit der anderen Hand), `d` Drag (zwei). Pause `-8`. Triole
`3(R8 L8 R8)`, Sextole `6(R16 L16 R16 L16 R16 R16)`. Taktstriche `|` nur zur
Prüfung. Eine Zeile = 1–8 ganze Takte, ein Blatt ≤ 64 Takte.

## Ablauf

```
python3 tool/katalog/rudimente.py                      # prüft alle Blätter
python3 tool/katalog/build_page.py /tmp/katalog.html    # Kurations-Seite
python3 tool/katalog/gen_dart.py lib/features/lessons/data/sheets
python3 tool/katalog/patch_seed.py lib/features/lessons/data/rudiments_seed.dart
dart format lib/features/lessons/data/sheets lib/features/lessons/data/rudiments_seed.dart
flutter test test/lessons
```

Generierte Dart-Dateien nie von Hand ändern — Quelle ist `rudimente.py`.
Reines Python 3, kein Flutter nötig; die Seite braucht abcjs aus dem Netz.
