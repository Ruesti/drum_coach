# Bericht: Trainingsraum, Etappe 1

Branch `trainingsraum-etappe1` (aufgesetzt auf `spec-trainingsraum`), Draft-PR #38: https://github.com/Ruesti/drum_coach/pull/38
Tests: 1022 grün (1 übersprungen), `flutter analyze`: 8 Hinweise, alle schon vorher da.

## Was gebaut wurde
- **Bereich je Übung**: Jede Übung gehört jetzt zu einem von sieben Bereichen (Hände-Technik, Rudimente, Füße, Koordination, Groove, Fills, Metal). In der Bibliothek gibt es dafür eine neue Filterzeile. Der Kopf der Bibliothek scrollt mit der Liste, damit er auf kleinen Fenstern nicht die Liste erdrückt.
- **Alle vorhandenen Übungen sind eingeordnet** (Python-Katalog, Seed und Étüden). Schwierigkeiten blieben unverändert.
- **Tempo-Leiter pro Runde**: Nach jeder Runde gibt es eine Bewertung. Das Tempo geht danach um +4, 0 oder −4 BPM. „Sitzt" heißt: zwei saubere Runden hintereinander im Zieltempo. Nur so wird eine Übung „gemeistert", nicht mehr über das Verhältnis zum besten Tempo — das gilt jetzt auch fürs freie Üben aus der Bibliothek (dort höchstens „proficient"). Schon gemeisterte Übungen bleiben gemeistert.
- **Einheit auf /room**: Aufwärmen plus Vertiefen, ersetzt Programm und Tagesplan (alte Programm-Seiten sind entfernt). Auf Today steht „Today's session", darunter der Start-Knopf.
- **Aufwärmen ändert nichts am Fortschritt**: Es läuft 8 BPM unter dem gespeicherten Tempo (nie unter dem Mindesttempo). Gespeichert werden nur die Sitzung und die Wiederholungs-Planung; Tempo, bestes Tempo und Stufe bleiben, wie sie sind.
- **Neue Blätter zuerst**: In der Hände-Technik bietet der Raum die 10 neuen `tech_*`-Blätter vor den älteren Übungen gleicher Stufe an (neues Feld `roomOrder`, gesetzt vom Katalog-Werkzeug). Ein neuer Spieler beginnt mit „Grip & Rebound".
- **10 neue Hände-Technik-Übungen** (5 Anfänger, 5 Mittel), je 8 Zeilen à 4 Takte, mit englischem Lehrtext (Why / How / Tips / Song examples) und gesprochener Erklärung (Stimme).
- Kuration aller neuen Übungen: https://claude.ai/artifact/WjtQHeFseTsQPr4CAKcBYU

## Zahlen: Bereich × Stufe (Übungen)
Stand aus Task 2; Hände-Technik enthält die 10 neuen Blätter noch nicht.

| Bereich | Anfänger | Mittel | Fortgeschritten | Profi | gesamt |
|---|---|---|---|---|---|
| Hände-Technik | 20 | 24 | 10 | 0 | 54 (+10 neu = 64) |
| Rudimente | 23 | 22 | 17 | 11 | 73 |
| Füße | 1 | 3 | 2 | 0 | 6 |
| Koordination | 0 | 5 | 1 | 0 | 6 |
| Groove | 2 | 4 | 2 | 0 | 8 |
| Fills | 4 | 8 | 7 | 0 | 19 |
| Metal | 0 | 0 | 0 | 0 | 0 |

Die 10 neuen Blätter sind die Anfänger- und Mittel-Stufe der Hände-Technik (5 + 5); die genaue Aufteilung steht in task-7-report.md.

## So probierst du es auf dem PC
App läuft: Bundle `~/drum-coach-trainingsraum/build/linux/x64/release/bundle/drum_coach` (DISPLAY=:0, rechte Bildschirmhälfte).
1. **Einheit**: Today, dann Continue, dann „Today's session" (Aufwärmen + Vertiefen), Start.
2. **Bereichsfilter**: Library, Zeile „Area", Hände-Technik wählen, eine Übung `tech_*` öffnen. Das ist eine der 10 neuen.
3. **Erklärung**: In der Übung „How to play" öffnen. Dort stehen Why / How / Tips / Song examples, dazu die Stimme.

## Offene Punkte für Uli
- **Übungsansicht** hat noch den alten Look (dunkles Foto plus Zeilenansicht). Der Umbau auf den Drumeo-Look kommt erst in Etappe 2.
- **Messung am Set** gibt es erst nach Etappe 2, Teil B.3.
- **Lücken im Inhalt**: Koordination hat keine Anfänger-Übung, Metal ist leer. Das kommt in späteren Etappen.
- **Streak** kann für frühere Programm-Nutzer mit Ruhetagen kürzer werden.
- **Gerätetest nötig**: Ruckeln beim automatischen Tempo-Schritt, und späte Mikrofon-Schläge auf der letzten Note können das Rundenfenster verpassen.
- **Songbeispiele** in den neuen Lehrtexten stammen aus allgemeinem Wissen. Bitte bei der Kuration gegenlesen.
- Entscheidungen der Bauphase: „sitzt" bei Übungen ohne Messung = diese Runde „Solid" im Zieltempo und vorher schon bestes Tempo ≥ Ziel (genähert). Aufwärmen nutzt je Bereich die eigene Stufe.
- **Zurückgestellte Kleinigkeiten** (aus progress.md): Formatierungs-Umbrüche in einigen Testdateien, Import-Reihenfolge in Étüden und lessons_screen; `patch_seed` entfernt weggefallene `area`/`song`/`roomOrder` nicht; kein Zurück-Test für /room; Pause/Resume behält die Sauber-Serie; bei der reinen Bewertung ohne Mikrofon erscheint „Nailed it" nicht, wenn über Sitzungen gemeistert; Gleichstand bei fälligen Übungen nach Enum-Reihenfolge ungetestet; Geister-Ansage „just touches" könnte als stumm gelesen werden (besser „softer than a tap").

## Bildschirmfoto
`/home/uli/drum-coach-raum-etappe1-start.png`: Startbildschirm Today mit „Today's session, Warm-up + Hand technique, Start · 30 min". Ohne xdotool nicht weiter navigiert.
