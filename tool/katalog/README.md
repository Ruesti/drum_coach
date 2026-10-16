# tool/katalog — Blätter einmal schreiben, zweimal ausgeben

Der Katalog (Brief Pad-Übungen §7.3) wird in einer kleinen Notenschrift
komponiert und daraus erzeugt: die **Kurations-Seite** (abcjs, für Ulis
Urteil am Pad) und der **Dart-Code** (Blattform, `etude_dsl`).

```
sheetlang.py   Notenschrift: Parser, Prüfung (ganze Takte 1–8, 24er-Raster),
               Zählhilfe (wie countLabelsFor), ABC- und Dart-Ausgabe
blatt.py       Sheet: ein Blatt (8 Zeilen à line_bars Takte + Challenge 8 Takte),
               Formprüfung, Übersichtstabelle
katalog.py     Registry der Sätze: rudimente (3a), fills (3b), grooves (B.4a), set_fills (B.4b),
               feet (B.4c, 7 Blätter), set_more (B.4c, 5 Blätter) — Titel, Seed-Marker
rudimente.py   die zwölf Rudiment-Blätter + Lektionstexte (Daten, 2 Takte je Zeile)
fills.py       die acht Fill-Sticking-Blätter (3 Takte Time + 1 Takt Fill je Zeile)
feet.py        die sieben Fuß-Blätter: feet_kick_control, feet_kick_sixteenths,
               feet_double_bass_eighths, feet_double_bass_sixteenths,
               feet_double_bass_triplets, feet_hihat_foot, feet_ostinatos
set_more.py    fünf weitere Kit-Blätter: set_fill_linear, set_fill_double_bass,
               groove_linear, groove_kick_sixteenths, groove_halftime_shuffle
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

## Spuren (Phase B.1)

Für Kit-Blätter (`Sheet(kit=True, limbs=(…))`) ist eine Zeile ein Block mit einer
Zeile je Instrument: `HH: R8 R8 …` / `SN: -4 L4> -4 L4>` / `BD: K4 -4 K4 -4`.
Spurköpfe: `HH HO HP SN SR BD T1 T2 F1 F2 C1 C2 RD RB CH SP` (Tabelle `TRACKS`).
Hände spielen `R L`, Füße (`BD`, `HP`) `K` (Kick) und `P` (Hi-Hat-Pedal); Fußnoten
tragen weder Flam noch Drag. Fußseiten-Flags `r`/`l` an Fußnoten (`K16r`, `K8l`) sagen,
welcher Fuß tritt (Double Bass); die App zeigt sie als zweite Buchstabenzeile unter den
Füßen, die Kurationsseite nicht. `~` am Kopf (`T1~:`) setzt die Instrument-Klasse
(`accepts`: Toms/Crashes/Becken). Alle Spuren einer Zeile gleich viele ganze Takte.

Handprüfung (`check_hands`, läuft in `Sheet.parsed()`): eine Hand spielt nie zwei Trommeln
auf demselben Tick — zwei Hand-Spuren mit demselben Buchstaben auf einem Einsatz-Tick sind
ein Fehler. Ein Vorschlag (Flam/Drag) zählt als Gegenhand auf dem Tick seiner Hauptnote;
Füße sind ausgenommen.

Dart: `kitLine([voice(KitInstrument.x, [...]) …])`, Füße als `foot(...)`; `xPatternVoices`
ist der Pattern-Takt aller Stimmen, `xPattern` ist `xPatternVoices.first.beats` (dasselbe
Objekt). ABC: zwei Stimmen `[V:H]` (Hände, Hals oben) und `[V:F]` (Füße, Hals unten) auf
einem Schlagzeug-System, Akkorde `[cg]`. Triolen/Sextolen der Schichten bekommen `(3`/`(6:4:6`-Klammern wie die Pad-Zeilen
(eine Klammer je Zählzeit, Lücken als Pausen auf dem Tuplet-Raster).

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
python3 tool/katalog/feet.py                           # prüft die Fuß-Blätter
python3 tool/katalog/set_more.py                       # prüft Linear/Double-Bass-Fill/Grooves
python3 tool/katalog/build_page.py /tmp/fills.html fills   # Kurations-Seite eines Satzes
python3 tool/katalog/gen_dart.py lib/features/lessons/data/sheets        # alle Sätze
python3 tool/katalog/patch_seed.py lib/features/lessons/data/rudiments_seed.dart
dart format lib/features/lessons/data/sheets lib/features/lessons/data/rudiments_seed.dart
flutter test test/lessons
```

Generierte Dart-Dateien nie von Hand ändern — Quelle sind `rudimente.py` und
`fills.py`. Reines Python 3, kein Flutter nötig; die Seite braucht abcjs aus
dem Netz.
