# Design-Spec: Blattform — eine Übung ist ein Blatt aus nummerierten Zeilen

Datum 30.09.2026 · Branch `blattform` (von `main` 2d4cd3a) · Status: Entwurf
zur Freigabe durch den Auftraggeber.

Vorlage: die Übungs-PDFs in `docs/Übungen/` (deutsche Stickings-/Einspiel-/
Snare-Blätter und Drumeo „Easy Rudiments", 30.09.), der Pad-Brief
`docs/concept/BRIEF_PAD_UEBUNGEN.md` (§5 Punkte 3 und 4, §7 Schritt 3; liegt
auf `origin/konzept-pad-uebungen`), die vier Muster-Blätter vom 30.09.
(https://claude.ai/artifact/X5Ayknw9ovzoYRAMHLmz3b). Dieser Schritt ist vor
Engine Teil 2 (Dynamik) vorgezogen, weil der neue Katalog (Schritt 3) diese
Form braucht.

## 0. Entscheidungen des Auftraggebers (30.09.)

1. „Ich hatte dir ja mal die Übungen von Drumeo und Rudiments gegeben. Sowas
   will ich." → Blattform: nummerierte Zeilen, kurze Zellen mit
   Wiederholungszeichen, Handsatz, Tempo-Bereich.
2. Vorgehen freigegeben: Muster-Blätter → Blattform in der App (diese Spec)
   → Katalog in Blättern.
3. **Kommando zurück** zur zwischenzeitlichen Zweiteilung „Rudimente als
   Lektion, Technik als Zellen": **Die Lektion (Was, Warum, Wie, Tipps,
   Songs) gibt es nur auf Abruf. Die Übung selbst zeigt nur Noten. Jede
   Übung so abwechslungsreich und „groovy" wie möglich.**
4. Bleibt aus dem Brief: Pad einstimmig; Vorbilder liefern Prinzipien, keine
   Zeilen; Katalog-Vorgabe vom 28.09. „wenn kein reines Rudiment, länger und
   abwechslungsreicher".

Folgen für das Design: **eine** Blattform für alle Übungstypen (keine
Zellen-Form neben einer Lektionsform), das Lektions-Material lebt auf der
Info-Seite der Library und hinter „About this exercise" im Übungs-Screen,
nie auf dem Übungs-Screen selbst. Die trockenen Ein-Takt-Zellen der
Muster-Blätter 1 bis 3 sind damit kein Katalog-Ziel mehr; die Zeilen der
Blätter werden musikalische Phrasen (§9).

## 1. Ziel und Nicht-Ziele

**Ziel.** Eine Übung ist ein Blatt aus nummerierten Zeilen. Jede Zeile ist
eine Phrase von ein bis acht Takten mit oder ohne Wiederholungszeichen. Der
Übungs-Screen zeigt das ganze Blatt als Noten, spielt wahlweise **eine Zeile
im Kreis** oder **das ganze Blatt der Reihe nach** und lässt mit einem Tipp
zur nächsten Zeile springen. Die Notation bekommt dafür Nummern-Kästchen,
Wiederholungszeichen, Schlussstrich, optionale Zeilen-Überschrift und
optionale Zählhilfe. Alle 127 vorhandenen Übungen laufen unverändert als
Ein-Zeilen-Blätter. Das Lektions-Material (§7) ist auf Abruf da.

**Nicht-Ziele.** Neue Katalog-Inhalte (Schritt 3; hier nur ein Blatt als
Probestück, §9). Automatisches Weiterschalten nach n Durchläufen und
lückenloser Zeilenwechsel im laufenden Loop (§6, „Offen"). Bewertung je
Zeile. Dynamikzeichen (Engine Teil 2). Volten, Da Capo, Tempo-Stufen-Badges.
Änderungen am Backing, an der Messung oder am Ergebnis-Blatt außer dem
Durchreichen der gespielten Noten. Ein Editor für Blätter. Übersetzung: die
App bleibt Englisch, die Blätter und Lektionstexte im Katalog auch.

## 2. Begriffe

- **Blatt:** eine Übung (`Rudiment`) mit einer Liste von Zeilen.
- **Zeile:** eine Phrase aus ganzen Takten (1 bis 8), mit Nummer, optionaler
  Überschrift (z. B. „Challenge"), Wiederholung ja/nein, Zählhilfe ja/nein.
- **Muster:** die bisherige Notenliste `Rudiment.sticking`. Bei Blättern mit
  Zeilen ist sie das nackte Rudiment für den „How"-Kasten der Info-Seite;
  bei Altdaten ist sie zugleich die einzige Zeile.
- **Einheit:** was der Übungs-Screen gerade spielt und misst — eine Zeile
  oder das ganze Blatt in Folge. Eine Einheit ist eine gewöhnliche
  Notenliste; alles Nachgelagerte (Wiedergabe, Cursor, Backing-Wahl,
  Messung) sieht nur diese Liste.
- **Zeilen-Modus / Blatt-Modus:** Einheit = gewählte Zeile bzw. alle Zeilen.

## 3. Datenmodell — `lib/features/lessons/models/rudiment.dart`

```dart
class ExerciseLine {
  final List<StrokeBeat> beats;   // ganze Takte, 1..8
  final bool repeat;              // Wiederholungszeichen |: :|  (Standard true)
  final String? title;            // Text über der Zeile, z. B. 'Challenge'
  final bool counts;              // Zählhilfe unter dem Handsatz (Standard false)
  const ExerciseLine(this.beats, {this.repeat = true, this.title, this.counts = false});
}

class Rudiment {
  // … wie heute …
  final List<ExerciseLine> lines;   // Standard const []
  List<ExerciseLine> get sheet =>   // nie leer
      lines.isNotEmpty ? lines : [ExerciseLine(sticking)];
  Rudiment withSticking(List<StrokeBeat> beats); // Kopie, nur sticking getauscht
}
```

- **Altdaten:** `lines` leer → `sheet` ist die eine Zeile aus `sticking` mit
  Wiederholung. Keine Handarbeit an den 41 Seeds und 86 Étüden.
- Nummern werden nicht gespeichert: Nummer = Position in `sheet` + 1.
- `gridUnit`, `beatsPerBar`, Tempo, Tags, `backing` gelten fürs ganze Blatt.
- **Regeln (Test `etudes_integrity`):** jede Zeile besteht aus ganzen Takten
  (`barCountOrThrow`), 1 bis 8 Takte; das ganze Blatt hat höchstens 64 Takte
  (`maxBackingCycleBars`, damit der Blatt-Modus mit Band läuft); Zeilen sind
  nicht leer.
- **DSL** (`lib/features/lessons/data/etude_dsl.dart`): `line(beats,
  {repeat, title, counts})` als lesbare Kurzform; Blätter im Katalog werden
  wie heute als Dart-Listen geschrieben (`docs/Übungen/README.md`).

### 3a. Einheit — `lib/features/lessons/models/sheet_plan.dart` (neu, rein)

```dart
class SheetPlan {
  final List<StrokeBeat> beats;        // die Einheit, flach
  final List<int> lineStarts;          // Notenindex, an dem Zeile i beginnt
  factory SheetPlan.line(Rudiment r, int lineIndex);
  factory SheetPlan.wholeSheet(Rudiment r);   // alle Zeilen, je ein Durchlauf
  ({int line, int index}) locate(int noteIndex); // für den Cursor
  int get bars;
}
```

Blatt-Modus spielt jede Zeile **einmal** je Durchlauf (auch Zeilen mit
Wiederholungszeichen; das Zeichen ist Notation, der Loop ist die Übung),
dann beginnt das Blatt von vorn. Zwei Durchläufe je Zeile kämen über 64
Takte und würden die Renderzeit verdoppeln (§6); sie bleiben „Offen".

## 4. Notation

### 4a. Layout — `lib/shared/widgets/staff_layout.dart`

Keine Änderung der Rechnung. Der Blatt-Renderer ruft `computeStaffLayout` **je
Zeile** mit `leftPad` = 8 + Breite des Nummern-Kästchens (26 px) und
`rightPad` = 12 + Breite des Wiederholungszeichens (10 px), damit Kästchen
und Zeichen nicht in die Noten ragen. Ein bis zwei Takte je Zeile nehmen
damit weiterhin eine Reihe (kurze Stücke füllen die Zeile, K2-Polish); die
Challenge mit 8 Takten wird zu 4 Reihen ohne Nummern-Wiederholung.

### 4b. Zeichnen — `lib/shared/widgets/notation_staff_widget.dart`

Neues Widget `SheetStaffWidget`:

```dart
SheetStaffWidget({
  required Rudiment rudiment,
  int? activeLine,          // null = alles hell (Info-Seite)
  int? activeIndex,         // Notenindex innerhalb der aktiven Zeile
  bool autoScroll = false,
  bool showSticking = true,
  bool showCounts = true,   // wirkt nur auf Zeilen mit counts: true
  ValueChanged<int>? onLineTap,
});
```

Es stapelt je Zeile einen `_StaffPainter` (heutiger Maler, um Zeilen-Wissen
erweitert), Zeilenabstand 12 px, Reihenhöhe wie heute 104 px (mit Zählhilfe
+14 px). `NotationStaffWidget` bleibt als dünne Hülle für Ein-Zeilen-Aufrufer
(Generator-Vorschau) und delegiert an das neue Widget.

Der Maler bekommt je Zeile: `lineNumber`, `repeat`, `isLastLine`, `title`,
`countLabels` (`List<String?>` je Note oder null), `dimmed`.

| Element | Darstellung |
|---|---|
| Nummern-Kästchen | links vor der ersten Reihe der Zeile, 22 × 22 px, 1-px-Rahmen in Tinte, Zahl in der Label-Schrift der App (IBM Plex Mono, `AppTypography.label`), 12 px; vertikal auf der Mittellinie |
| Wiederholung an | `|:` zu Beginn der ersten Reihe: dicker Strich 3 px + dünner Strich + zwei Punkte im 2. und 3. Zwischenraum |
| Wiederholung aus | `:|` am Ende der letzten Reihe, gespiegelt |
| Zeile ohne Wiederholung | einfacher Taktstrich am Ende der letzten Reihe; letzte Zeile des Blatts: Schlussstrich (dünn + dick) |
| Reihenende innerhalb einer Zeile | einfacher Taktstrich (der heutige Doppelstrich an jedem Reihenende entfällt; er stand für den Loop, das sagt jetzt das Wiederholungszeichen) |
| Überschrift | `title` in der Label-Schrift 11 px, halbfett, über der ersten Reihe links, in Tinte |
| Zählhilfe | zweite Textreihe 14 px unter dem Handsatz, Label-Schrift 10 px, gedämpft; Text je Note aus §4c; nur wenn `counts` und `showCounts` |
| Handsatz | wie heute, aber in der Label-Schrift statt Systemschrift (heute `TextStyle` ohne `fontFamily`; im Test-Renderer erschienen deshalb Kästchen) |
| inaktive Zeile | ganze Zeile auf 45 % (heute: inaktive Takte); innerhalb der aktiven Zeile bleibt alles hell |
| Notenschlüssel, Taktart | Schlüssel auf jeder Reihe wie heute; Taktart nur auf der ersten Reihe des Blatts |

Tippen auf eine Zeile ruft `onLineTap(lineIndex)` (Treffer-Fläche = die
ganze Zeile inklusive Kästchen).

### 4c. Zählhilfe — `lib/shared/widgets/count_labels.dart` (neu, rein)

`List<String?> countLabelsFor(List<StrokeBeat> beats, NoteGrid grid, int
beatsPerBar)`: Position jeder Note auf dem 24er-Raster (wie
`buildPatternPlayback`), Tick innerhalb des Viertels `t`, Viertelnummer `b`
(1-basiert im Takt).

| Note | `t` | Text |
|---|---|---|
| jede | 0 | `b` |
| Triole/Sextole (Tuplet ≠ none) oder ternäres Raster | 8 / 16 | `+` / `a` |
| sonst | 6 / 12 / 18 | `e` / `+` / `a` |
| alles andere (32tel, Punktierungs-Reste) | — | null (kein Text) |

Pausen bekommen keinen Text. Tests: Achtel R L → „1 + 2 + 3 + 4 +",
Sechzehntel → „1 e + a …", Achtel-Triolen → „1 + a 2 + a …", gemischt
(Viertel, zwei Achtel, Sechzehntel-Gruppe) → „1 2 + 3 e + a".

## 5. Übungs-Screen — `lib/features/practice/practice_session_screen.dart`

Neuer Zustand: `_lineIndex` (0-basiert), `_sheetMode` (bool), `_plan`
(`SheetPlan`), `_unit` (`rudiment.withSticking(_plan.beats)`). Alles, was
heute `rudiment` für Wiedergabe, Cursor, Backing-Wahl und Messung nutzt,
nutzt `_unit`: `PatternPlayback.forRudiment(_unit)`, `autoBackingStyle(_unit,
bpm)`, `_micService.analyze(sticking: _unit.sticking)`. Kopfzeile, Ergebnis
und Speicherung nehmen weiter `rudiment` (Name, Id, Tempo).

**Start.** Zeile und Modus kommen aus (in dieser Reihenfolge) den
Routen-Parametern `?line=` (1-basiert) und `?mode=line|sheet`, sonst aus
dem Gedächtnis je Übung (`SettingsService.sheetPositionFor(id)` → Zeile und
Modus, gesetzt beim Verlassen des Screens), sonst Zeile 1 im Zeilen-Modus.
Der Pausen-Schnappschuss (`practiceSnapshotFor`) speichert Zeile und Modus
mit, damit ein unterbrochenes Üben auf derselben Zeile weitergeht.

**Zeile wechseln** (Tipp aufs Blatt, ‹ ›, Moduswechsel): `_plan` und
`_unit` neu, `_playback` neu, `metronome.setPatternVolumes(...)` und
`_applyExtras()` (Backing-Stil kann sich mit der Zeile ändern: eine
Triolen-Challenge bekommt Shuffle). Im Stand passiert sonst nichts. **Im
Lauf** baut der Engine den Loop neu und beginnt auf der Eins der neuen
Zeile — derselbe Weg wie heute bei einer Tempo-Änderung (150 ms Entprellung,
Phase springt). Das Beat-Log wird beim Wechsel geleert und das Mikro-Fenster
neu verankert, damit die Messung nur die neue Einheit sieht (heute: die
Messung setzt beim Stop an; der Wechsel zählt hier wie Stop + Start ohne
Zeitverlust: `_elapsedSeconds` läuft weiter). Der Cursor springt mit.

**Bedienung** (dunkles Übungs-Theme, K2): unter dem Notenblatt und über dem
Pulsbalken eine Zeilenleiste, 44 px hoch, nur bei Blättern mit mehr als
einer Zeile:

```
 ‹    Line 3 / 11    ›          [ Line | Sheet ]
```

‹ › wechseln die Zeile (am Rand gesperrt), die Mitte in der Label-Schrift,
rechts ein zweiteiliger Umschalter. Im Blatt-Modus zeigt die Mitte „Sheet ·
28 bars" und ‹ › sind ausgeblendet. Das Notenblatt scrollt zur aktiven Zeile
(`autoScroll`), inaktive Zeilen gedämpft. Vor dem Start ist das Blatt wie
heute 60 % durchsichtig über dem Foto.

**⋯-Blatt:** unter `SHEET` zwei Schalter „Sticking letters" (global,
Standard an, `SettingsService.showSticking`) und „Count hints" (global,
Standard an, `showCounts`; wirkt nur auf Zeilen mit Zählhilfe). „About this
exercise" bleibt und öffnet die Info-Seite (§7).

**Ergebnis.** Unverändert: ein Ergebnis für die Sitzung, Kernwerte über die
Einheit. Die Sitzung wird wie heute unter der Übungs-Id gespeichert;
`SessionLog` bekommt zwei optionale Felder `sheetLine` (int?, 1-basiert,
null = Blatt) und `sheetMode` (String?), damit spätere Auswertungen je Zeile
möglich sind (Isar-Feld-Ergänzung, rückwärtskompatibel).

**Pfad und Programm.** Routen unverändert; `practiceRouteFor` hängt nichts
an (Standard = gemerkte Position, sonst Zeile 1). Tempo-Leiter und
Clean-Pass-Gate gelten für die gespielte Einheit, wie heute fürs Muster.

## 6. Engine — keine Änderung

`buildLoopPlan` und `MetronomeEngine` bleiben unangetastet. Die Einheit ist
eine Notenliste wie bisher; der Blatt-Modus ist nur ein längeres Muster
(höchstens 64 Takte, §3). Risiko: **Renderzeit** — ein 28-Takt-Blatt bei
60 BPM ist ein Zyklus von 112 s (≈ 10 MB WAV, vier Stimmen, Begrenzer je
Sample). Jede Tempo-Änderung rendert neu. Gerätetest misst die Zeit bis zum
ersten Klick bei 60 BPM im Blatt-Modus; Grenze für „passt": unter 1 s.
Andernfalls kommt der Vorab-Render in Stücken (Zeile für Zeile, Übergabe an
der Taktgrenze) als eigener Engine-Schritt — der wäre auch die Grundlage für
lückenloses Weiterschalten und automatisches „nach n Durchläufen weiter".
Beides bewusst „Offen" (§12), weil Uli zuerst die Form am Pad beurteilen
soll.

## 7. Lektion auf Abruf — `lib/features/lessons/lesson_detail_screen.dart`

Die Info-Seite (heute: Meta-Zeile, Beschreibung, „STICKING PATTERN" mit
Notenblatt, Legende, „TECHNIQUE"-Karten, „Start Practice") wird zur
Lektionsseite, ohne neuen Screen:

1. Meta-Zeile wie heute (Tempo, Schwierigkeit, Tags).
2. Beschreibung (ein Absatz „what").
3. **Abschnitte** aus `rudiment.technique` (`TechniqueSection(title,
   body)`, vorhanden) — der Katalog füllt sie mit festen Titeln: „Why it
   matters", „How to play it" (mit dem Muster als Kasten, `NotationStaffWidget
   (rudiment)` = `sticking`, nur wenn `lines` nicht leer), „Practice tips",
   „Song examples" (Aufzählung im Body). Kein neues Modell; Blätter ohne
   Abschnitte zeigen nur Beschreibung und Blatt.
4. **„THE SHEET"**: das ganze Blatt mit `SheetStaffWidget(activeLine: null)`,
   Tipp auf eine Zeile startet die Übung dort (`/practice/<id>?line=n`).
5. „Start Practice" wie heute (gemerkte Position).

Der Übungs-Screen zeigt von alledem nichts; „About this exercise" im
⋯-Blatt führt hierher (vorhanden).

## 8. Library-Liste

`_RudimentTile` zeigt zusätzlich „11 lines · 28 bars" in der Meta-Zeile,
wenn das Blatt mehr als eine Zeile hat. Filter unverändert.

## 9. Probestück und Katalog-Regel

Der Bau enthält **ein** Blatt, damit Screen und Tests etwas Echtes haben:
das Blatt „Single Paradiddle" von der Muster-Seite (10 Zeilen à 2 Takte,
Challenge 8 Takte ohne Wiederholung) als `lines` des Seeds
`single_paradiddle`, das `sticking` bleibt das nackte Muster für den
„How"-Kasten. Inhaltlich ist es ein Platzhalter: der Katalog (Schritt 3)
komponiert nach der Regel

> **Jede Übung so abwechslungsreich und groovy wie möglich.** Ein Blatt hat
> 6 bis 10 Zeilen à 2 Takte plus wahlweise eine Challenge von 8 Takten.
> Jede Zeile ist eine Phrase: das Rudiment wandert durch Achtel, Sechzehntel
> und Viertel, mit Pausen, Akzenten und Anschlüssen, so dass die Zeile für
> sich Musik ist. Keine Zeile ist eine bloße Wiederholung des Rudiments.
> Reine Rudiments (§3.1 Brief, Assessment) bleiben Ein-Zeilen-Blätter mit
> Wiederholung. Blätter für Anfänger tragen die Zählhilfe.

und ersetzt das Probestück; die 86 alten Étüden gehen erst dann (Brief §7.4).

## 10. Fehlerpfade

- `?line=` außerhalb 1..n oder nicht numerisch → Zeile 1, kein Fehler.
- Gemerkte Zeile größer als das Blatt (Katalog geändert) → Zeile 1.
- Blatt mit mehr als 64 Takten → Integritätstest schlägt fehl; zur Laufzeit
  läuft der Blatt-Modus ohne Band (heutiges Engine-Verhalten).
- Zeilenwechsel, während der Engine noch rendert → letzter Wunsch gewinnt
  (Entprellung im Engine, wie bei schnellen Tempo-Tipps).

## 11. Tests

- `test/lessons/rudiment_model_test.dart`: `sheet` bei leeren und gefüllten
  `lines`, `withSticking` tauscht nur die Noten.
- `test/lessons/sheet_plan_test.dart` (neu): Zeile i → genau deren Noten;
  ganzes Blatt → Summe, `lineStarts` stimmen, `locate` an den Grenzen,
  `bars`.
- `test/lessons/etude_dsl_test.dart`: `line(...)`.
- `test/lessons/etudes_integrity_test.dart`: alle Zeilen aller Übungen sind
  ganze Takte, 1..8 Takte, Blatt ≤ 64 Takte.
- `test/shared/count_labels_test.dart` (neu): die vier Fälle aus §4c.
- `test/notation_staff_test.dart`: `SheetStaffWidget` zeichnet ein
  Drei-Zeilen-Blatt (mit Challenge ohne Wiederholung, Titel, Zählhilfe)
  ohne Fehler; Ein-Zeilen-Altdaten zeichnen weiter; `onLineTap` liefert die
  Zeile; Golden für ein Zwei-Zeilen-Blatt (Kästchen, Wiederholungszeichen,
  Schlussstrich).
- `test/features/practice/practice_session_screen_test.dart`: Ein-Zeilen-
  Blatt → keine Zeilenleiste; Mehrzeilen-Blatt → „Line 1 / 11", › ruft
  `setPatternVolumes` mit den Lautstärken der Zeile 2; Umschalter „Sheet" →
  Länge = Summe; `?line=3`, `?mode=sheet`; gemerkte Position; Tipp auf
  Zeile im Stand wählt sie; Wechsel im Lauf leert das Beat-Log; Messung
  bekommt die Einheit; Schalter „Sticking letters"/„Count hints".
- `test/lessons/lesson_detail_*`: Abschnitte, „THE SHEET", Tipp auf Zeile →
  Route mit `?line=`.
- `test/data/settings_service_test.dart`: `sheetPositionFor`, Snapshot mit
  Zeile und Modus, `showSticking`, `showCounts`.
- Gerätetest S23: Blatt Single Paradiddle — Zeile im Kreis mit Backing,
  Wechsel im Lauf (Eins sitzt), Blatt-Modus bei 60 und 140 BPM (Zeit bis zum
  ersten Klick, Cursor über Zeilen und Reihen), Mikro-Messung auf einer
  Zwei-Takt-Zeile, Info-Seite mit Blatt, Alt-Übung unverändert.

## 12. Offen / spätere Schritte

- Automatisches Weiterschalten nach n Durchläufen und lückenloser Wechsel
  (Vorab-Render je Zeile, §6).
- Zwei Durchläufe je Zeile im Blatt-Modus.
- Bewertung je Zeile im Ergebnis und in Progress (Felder sind vorbereitet).
- Tempo-Stufen als Badges auf der Info-Seite (heute Tempo-Bereich).
- Dynamikzeichen (Engine Teil 2), Volten und Da Capo (Brief §5.3).
- Katalog Schritt 3: 12 Rudiment-Blätter, Fills, Stücke nach §9.

## 13. Dateien

- Neu: `lib/features/lessons/models/sheet_plan.dart`,
  `lib/shared/widgets/count_labels.dart`, Tests wie in §11.
- Ändern: `rudiment.dart` (`ExerciseLine`, `lines`, `sheet`, `withSticking`),
  `etude_dsl.dart` (`line`), `rudiments_seed.dart` (Probestück),
  `notation_staff_widget.dart` (`SheetStaffWidget`, Maler), `staff_layout.dart`
  (nur Aufruf-Parameter), `practice_session_screen.dart` (Einheit,
  Zeilenleiste, Optionen, Parameter), `lib/app/router.dart` (`?line=`,
  `?mode=`), `lib/data/local/settings_service.dart` (Position, Schalter,
  Snapshot), `lib/data/local/models/session_log.dart` (+2 Felder),
  `lesson_detail_screen.dart`, `lessons_screen.dart` (Meta-Zeile),
  `docs/CLAUDE.md`, Bericht `docs/BERICHT_BLATTFORM.md`.
