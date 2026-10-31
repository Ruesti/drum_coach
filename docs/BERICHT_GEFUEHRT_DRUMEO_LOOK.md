# Bericht: Geführte Übungen im Drumeo-Look (Tasks 1–9)

Branch `spec-trainingsraum` (aufgesetzt auf `spec-gefuehrte-uebungen`), Stand fc3662f. Tests: 979 grün, `flutter analyze` ohne Fehler (13 Hinweise, alle schon vorher da).

## Was gebaut wurde
- **Bühne oben, weißes Notenblatt darunter, Bedienleiste**: Beim Üben steht oben ein Foto (die „Bühne"), darunter ein weißes Blatt mit Seiten zu je vier Takten. Der Abspielzeiger läuft in Blau über die Noten. Unten die Bedienleiste.
- **Vier-Takt-Seiten**: Das Blatt zeigt eine Zeile = vier Takte. Die Notenlinien sind so groß wie möglich (ca. 57 px Höhe bei 1920 Breite, 39 px bei 1366, 78 px bei 2560); das Blatt nimmt bis zu 50 % der Höhe, das Foto wird entsprechend kleiner.
- **Vorschau**: Die ganze Übung als Notenblatt, die Einstellungen liegen auf der Bühne. Auf schmalen Fenstern gibt es Zwei-Takt-Seiten.
- **Zeit und Dauer**: Zeilen können länger als ein Takt sein, der Ablauf (run plan) spielt sie richtig. Die Dauer der Übungen änderte sich leicht: Das Runden auf volle Vier-Takt-Abschnitte machte einige Übungen länger, alle innerhalb von ±10 % (bis etwa +8 %, z. B. Triplet Flams 5:06 → 5:30, Linear Shift und Accent Walk 5:04 → 5:25).
- **Inhalte**: Acht Übungen (Backbeat Walk, Funk Sixteenths, Half-Time Shuffle, Linear Shift, Accent Walk, Fives & Sixes, Paradiddle, Triplet Flams) sind jetzt Vier-Takt-Zeilen: Takt 1–3 wie bisher, Takt 4 eine Steigerung. Gesprochene Ansagen wurden geprüft und passen zu allen vier Takten (kein Neu-Rendern nötig). Variationen haben jetzt einen Titel (zwei bis fünf Wörter, nur englisch als `titleEn`).
- Fotos: Kontaktbogen `~/drum-coach-fotos-4zu3.png`. Kurationsseite: https://claude.ai/artifact/KRzCx2Jdmqfh7gjAxUAXG7

## Wo läuft es
Auf dem PC (GPU-Box) im eigenen Checkout `~/drum-coach-trainingsraum` (git worktree, fc3662f). Bundle: `~/drum-coach-trainingsraum/build/linux/x64/release/bundle/drum_coach`. Gestartet mit DISPLAY=:0 auf der rechten Bildschirmhälfte. Gebaut mit `flutter build linux --release` (Flutter unter /snap/bin). Der alte Checkout `~/projects/drum_coach` blieb unberührt (hat lokale Änderungen). Laptop: nicht versucht (siehe unten).

## Bildschirmfoto
`/home/uli/drum-coach-drumeo-look-start.png` zeigt nur den Startbildschirm. Auf dem PC ist kein xdotool installiert, ich konnte also nicht sicher in die geführte Übung navigieren. Die Übungsansicht wurde nur per Golden-Tests geprüft, nicht live am PC. Bitte kurz selbst: Library oder Today öffnen, Übung starten.

## Offene Punkte für Uli
- **Notenhöhe bei kleinen Fenstern / kleineres Foto**: Das Blatt nimmt bis zu 50 % der Höhe, das Foto wird dadurch klein. Bei dichten Sechzehntel-Seiten sind die Linien kleiner (ca. 40 px). Bitte beurteilen.
- **Triplet Flams V2, Takt 4** sieht dicht aus (Hilfsklammern der Triolen gegen Vorschlagnoten). Bei der Kuration ansehen.
- Zurückgestellte Kleinigkeiten (aus progress.md):
  - Validierung prüft in Dart nur „Titel nicht leer", die 2–5 Wörter nur im Test/Python.
  - `pageLine`: Triolen-Gruppierung nach Anzahl 3/6 kann bei gemischten Gruppen/Pausen fälschlich fehlschlagen; nicht ganze Zeile gibt RangeError statt ArgumentError; `_splitBars` wird je Aufruf neu berechnet.
  - Doppelter Code `_rowBars`/`fullBars` in guided_page_view.dart; Geometrie-Schleife wird je Build neu gerechnet; leerer Streifen unter den Noten bei maximaler Höhe.
  - Eine dichte Seite verkleinert alle Seiten der Übung (gemeinsamer Maßstab); Fit-Cache wird bei 64 Einträgen geleert.
  - `_StagePanel`/`_SettingsPanel` doppelt; nicht erreichbare Label-Zweige (Ending/Intro); Ecken beim schmalen Blatt; Umbruch bei 820 px (schon vorher); Panel verdeckt bei 900 px Breite das Foto.
  - ImageFiltered tileMode, Vollständigkeitsprüfung der Fokus-Tabelle, Docstring zum schmalen Blatt.
  - Lange Kommentarzeile in run_plan_test.dart.
