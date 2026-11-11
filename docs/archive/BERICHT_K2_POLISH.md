# Bericht K2 Nachbesserungen — Vollbild, Noten, dunkles Progress, Library-Bild (29.09.2026)

Branch `k2-polish` von main 7680cc8. Anlass: Ulis Rückmeldung am 29.09.
morgens nach dem S23-Test: „Die Startseite hat noch kein Fullscreen-Bild. Auf
den Übungsseiten sind die Noten links im Fenster. Die könnten mittig oder auf
Fenstergröße angepasst. Die Stats-Seite müsste dunkel und die Library-Seite
braucht Bild."

## Was gebaut wurde

- **Today Vollbild.** Ein Zufallsfoto aus dem 36er-Hochformat-Vorrat füllt den
  ganzen Screen bis hinter die Statusleiste. „TODAY" und der Gruß stehen weiß
  mit Schatten auf dem Foto, ab etwa 40 % Höhe blendet das Foto ins Papier,
  darauf wie bisher Pfad-Schritt mit Start, Library-Tür, Serie und Minuten.
  Die Programm-Phase wählt kein Bild mehr; die sechs zustandsbezogenen
  16:9-Bilder sind entfernt (das Willkommensbild bleibt). Statusleisten-
  Symbole hell.
- **Noten füllen die Karte.** Das Notenblatt rechnete mit zwei Takten je
  Zeile, ein Rudiment mit einem Takt bekam die linke Hälfte. Stücke mit
  weniger Takten als eine Zeile nehmen jetzt die ganze Zeile, der
  Notenabstand wächst bis 1,5× der Komfortbreite, die Köpfe bleiben gleich.
  Eine einzelne Zeile, die trotzdem schmaler ist, wird mittig gesetzt
  (`StaffLayout.xOffset`, der Painter verschiebt die Zeile samt Schlüssel und
  Taktstrichen). Die letzte kurze Zeile eines mehrzeiligen Stücks bleibt
  links wie im Druck.
- **Progress dunkel.** Die Seite läuft im dunklen Übungs-Theme: Hintergrund,
  Karten, Kalender, Diagramme und Schrift (`PracticeColors`). Die Leiste
  unten wird auf diesem Tab ebenfalls dunkel.
- **Library mit Bild.** Randloser Fotokopf (32 % der Höhe) mit „Library" in
  Weiß darauf, unten abgedunkelt, damit der Titel auf jedem Foto liest;
  Filter und Liste darunter wie bisher.
- **Gemeinsamer Zufalls-Picker** `nextBackdrop()`: Today, Library und
  Übungs-Screen ziehen aus demselben Vorrat, nie zweimal hintereinander
  dasselbe Foto, egal auf welcher Seite es zuletzt zu sehen war.

## Tests

- `staff_layout_test.dart` (+3): Ein-Takt-Stück füllt die Zeile, schmale
  Zeile mittig, dreitaktiges Stück bleibt zwei je Zeile mit linker letzter.
- `today_screen_test.dart`: Statusleiste hell, Foto aus dem Vorrat füllt den
  Screen, kein AspectRatio mehr, Türen weiter da (die Phasenbild-Tests
  entfielen).
- `lessons_screen_hero_test.dart` (neu): kein AppBar, Titel im Fotokopf,
  Kopf = 32 % Höhe, Statusleiste hell, Liste darunter.
- `stats_screen_dark_test.dart` (neu): dunkles Theme, dunkler Hintergrund,
  Statusleiste hell.
- `backdrop_test.dart` (+1): `nextBackdrop` nie zweimal dasselbe.
- Ganze Suite auf der GPU-Box grün (siehe PR), Analyzer nur die 12
  bekannten Warnungen.

## Sichtprüfung

Emulator-Screens (Today, Library, Progress, Ein-Takt-Übung) auf der Seite im
PR; Ton nicht betroffen.

## Offen

- Progress-Diagramme: Farben der Balken und Linien sind auf dunkel
  umgestellt, Feinabstimmung nach Sichtung am Gerät.
- Today: Ruhetag und „fertig" haben kein eigenes Bild mehr, nur den Text.
