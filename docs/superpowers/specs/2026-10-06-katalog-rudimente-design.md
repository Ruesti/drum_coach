# Design-Spec: Katalog Schritt 3a — zwölf Rudiment-Blätter

Datum 06.10.2026 · Branch `katalog-rudimente` (von `main` 253367c) · Status:
Entwurf; Kuration der komponierten Blätter durch den Auftraggeber vor dem Bau.

Vorlagen: Pad-Brief `docs/concept/BRIEF_PAD_UEBUNGEN.md` §3.1, §4, §6, §7.3;
Blattform-Spec `2026-09-30-blattform-design.md` §9 (Katalog-Regel); Drumeo
„Easy Rudiments" (Form: zehn Übungen + Challenge) und die deutschen Übungs-PDFs
in `docs/Übungen/` als Prinzipien-Quelle, nie als Zeilen-Quelle.

## 0. Entscheidungen des Auftraggebers

- 30.09.: Lektion nur auf Abruf, Übung = nur Noten, **jede Übung so
  abwechslungsreich und „groovy" wie möglich**; „wenn kein reines Rudiment,
  länger und abwechslungsreicher" (28.09.).
- 05.10.: Blattform gemergt (#29). 06.10. „Katalog": **Rubrik für Rubrik**
  (erst Rudimente, dann Fill-Stickings, dann Stücke, je ein Draft-PR, Brief
  §7.3); **zwölf Rudiments ohne Six Stroke Roll** (er steckt als Zeile im
  Double-Stroke- und im Paradiddle-Blatt).
- Aus dem Brief: 12 / 8 / 6; Claude komponiert nach Vorbildern, der
  Auftraggeber kuratiert am Pad; die 86 alten Étüden gehen erst, wenn der
  neue Kern spielbar ist (§7.4) — also nach Schritt 3c, nicht hier.

## 1. Ziel und Nicht-Ziele

**Ziel.** Zwölf Rudiment-Blätter im Katalog, jedes ein `Rudiment` mit
`lines` (Blattform), Lektionsabschnitten und Stammdaten; das Probestück
Paradiddle wird ersetzt. Die zwölf: Single Stroke Roll, Double Stroke Roll,
Single Paradiddle, Double Paradiddle, Paradiddle-diddle, Flam, Flam Accent,
Flam Tap, Drag, Five Stroke Roll, Seven Stroke Roll, Swiss Army Triplet.
Die übrigen 29 Basis-Rudiments bleiben Ein-Zeilen-Blätter (Assessment).

**Nicht-Ziele.** Fill-Stickings (3b), Stücke (3c), Entfernen der 86 Étüden
(nach 3c), Dynamikzeichen (Engine Teil 2), Tempo-Stufen-Badges, neue
Screens. Keine Änderung an Blattform-Code außer Daten.

## 2. Form eines Rudiment-Blatts

- **8 Zeilen à 2 Takte** mit Wiederholung, danach **„Challenge" 8 Takte**
  ohne Wiederholung = 24 Takte je Blatt (≤ 64 ✓).
- **Zeile 1** = das Rudiment in seiner Grundgestalt, aber schon als
  Zwei-Takt-Phrase (Takt 2 endet anders als Takt 1). Zeilen 1–2 tragen die
  Zählhilfe bei Anfänger-Blättern.
- **Zeilen 2–8** = Phrasen, keine Permutationen: das Rudiment wandert durch
  Achtel, Sechzehntel, Triolen, Viertel; Pausen setzen Luft; Akzente
  verschieben sich; Anschluss an Singles/Doubles; Synkopen; jede Zeile soll
  für sich wie ein kleiner Groove klingen und zur Band (Backing) passen.
  Steigerung grob: Grundgestalt → Verdichtung → Pausen/Synkopen → Akzent-
  wanderung → Kombination mit Nachbar-Rudiment → Verschiebung gegen den
  Puls.
- **Challenge** = acht Takte, die Zeilenmaterial neu zusammensetzen, mit
  Schluss auf der Eins des (gedachten) neunten Takts oder einem Rest.
- `sticking` (Muster für den „How"-Kasten) bleibt die Grundgestalt (ein
  Takt). `technique` = vier Abschnitte: „Why it matters", „How to play it",
  „Practice tips", „Where you hear it" (Songs nur, wenn sicher; sonst der
  musikalische Ort: Marsch, Fill, Groove).
- Stammdaten aus dem Seed (Tempo, Schwierigkeit, Tags) bleiben; `backing`
  wird bei Triolen-Blättern (Flam Accent, Swiss Army Triplet,
  Paradiddle-diddle) nicht gesetzt — der automatische Stil wählt Shuffle.

## 3. Eine Quelle, zwei Ausgaben — `tool/katalog/`

Die Blätter werden **einmal** in einer kleinen Notenschrift geschrieben
(`tool/katalog/rudimente.py`, Python-Daten) und daraus erzeugt:

1. die **Kurations-Seite** (abcjs, wie die Muster-Blätter: Nummern, `|: :|`,
   Handsatz, Zählhilfe, Überschriften) → Ulis Urteil je Blatt und Zeile;
2. der **Dart-Code** `lib/features/lessons/data/sheets/*.dart` (DSL
   `note/rest/flam/drag/line`) → der Bau.

Token je Note: `R16>` = Hand, Wert (1 2 4 8 16 32), Flags `.` punktiert, `>`
Akzent, `g` Ghost, `f` Flam (ein Vorschlag mit der anderen Hand), `d` Drag
(zwei). Pause: `-8`. Triole: `3(R8 L8 R8)`, Sextole: `6(...)`. Taktstriche
`|` nur zur Prüfung. Der Generator prüft: ganze Takte, 1–8 Takte je Zeile,
≤ 64 je Blatt, Handsatz-Länge = Notenzahl. Er ist Werkzeug, nicht
App-Code (kein Flutter-Import), wird aber mit ins Repo gelegt, damit die
Fills und Stücke denselben Weg gehen.

## 4. Ablauf

1. Komponieren der zwölf Blätter + Lektionstexte (Englisch) in
   `rudimente.py`.
2. Seite rendern (headless Chromium), sichten, veröffentlichen; Kopie
   `~/katalog-rudimente.html`. **Kurations-Gate:** Uli urteilt am Pad oder
   vom Blatt („macht Spaß, klingt nach Musik, ist messbar"); Änderungen
   gehen in `rudimente.py`, Seite erneut.
3. Nach dem Ja: Dart-Dateien generieren, Seed-Einträge der zwölf auf
   `lines`/`technique` umstellen (Probestück-Datei entfällt), Integritäts-
   tests (vorhanden) laufen, Notation-Smoke über alle Blätter, Analyzer,
   Emulator-Stichprobe (zwei Blätter), Draft-PR.
4. Bericht `docs/BERICHT_KATALOG_RUDIMENTE.md`.

## 5. Tests

- `tool/katalog`: Python-Selbsttest (Takt-Summen, Token-Parser, Zählhilfe-
  Regel identisch zu `countLabelsFor`).
- Dart: `etudes_integrity_test` (ganze Takte 1–8, ≤ 64), `seed_integrity`,
  `notation_staff_test` „every seeded exercise renders as a sheet" — alle
  vorhanden, nur Daten neu; plus ein Test: die zwölf Blätter haben 9 Zeilen,
  Zeile 9 heißt „Challenge" ohne Wiederholung, Zeilen 1–2 zählen bei
  Anfänger-Blättern.

## 6. Dateien

- Neu: `tool/katalog/rudimente.py`, `tool/katalog/build_page.py`,
  `tool/katalog/gen_dart.py`, `tool/katalog/README.md`;
  `lib/features/lessons/data/sheets/<id>_sheet.dart` × 12 (generiert).
- Ändern: `rudiments_seed.dart` (12 Einträge), `sheets/single_paradiddle_sheet.dart`
  (ersetzt durch generierte Datei), Tests, `docs/CLAUDE.md` (Hinweis auf den
  Generator).
