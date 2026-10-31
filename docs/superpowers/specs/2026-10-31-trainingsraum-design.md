# Trainingsraum — Techniken und Grooves von Beginner bis Profi

Stand: Entwurf 31.10.2026 · Branch `spec-trainingsraum` (Draft-PR #37) · Status: **von Uli freigegeben 31.10. 13:22**

Teil 2 des Gesamtbilds `2026-10-29-uebungsansicht-trainingsraum-design.md`. Teil 1 (neue Übungsansicht)
wird gerade gebaut; der Trainingsraum nutzt diese Ansicht.

## 0. Ulis Wünsche (sinngemäß, 29.–31.10.)

- **„Was mir am allerwichtigsten ist, sind die Übungen, um jede Technik zu lernen.“** Die Optik ist der Rahmen.
- Verschiedene **Grooves und Techniken mit steigendem Schwierigkeitsgrad**, „alle möglichen Techniken und Groove-Vokabular“;
  Techniken und Spielweisen wie **Möller**. **Hand, Fuß, Koordination und Independence** trainieren.
- **„Wenn es erst zu schwer ist, dann langsam.“** Jede Übung in jedem Tempo, nicht „mitkommen oder nicht“ wie bei Drumeo.
- Am Anfang Übungen, die **Bewegungsabläufe instinktiv** werden lassen, dann immer mehr Technik und Vokabular.
- Einheit: **erst aufwärmen, dann einen Bereich vertiefen.**
- Grooves **gern an reale Musikstücke angelehnt**: Groove mit Songnamen reicht (Mitspielen zum Song = Teil 3, Import).
- **Techniken von Beginner bis Profi staffeln.** Die Stufenleiter in §2 hat Uli am 31.10. bestätigt („passt so“), **plus Metal**.
- **Erklärung nur auf Wunsch**, „damit nicht jedes Mal erklärt wird“.
- **Unten anfangen: Beginner und Intermediate zuerst.**
- Nicht gewollt: 400 Lektionen, Freischalten nach Veröffentlichung, Drumeo 1:1 nachbauen (nur als Muster).

## 1. Ist-Zustand (Branch `spec-trainingsraum`)

- **Katalog:** 80 Übungen im Seed (`rudiments_seed.dart`), davon 48 Blätter aus dem Katalog-Werkzeug (`tool/katalog/`):
  Rudiments (12), Pad-Fills (8), Set-Fills (12), Füße (7), Grooves (Rock 8/16, Funk 16, Halftime, Halftime-Shuffle,
  Shuffle, Swing, Linear, Kick-16tel, offene Hi-Hat). Achsen Skill/Genre/Limb (`docs/CLAUDE.md`).
- **Geführte Übungen:** 8 Stück (Set + Pad, je eine pro Stufe), 5-Minuten-Ablauf mit Lehrerstimme.
- **Tempo-Steigerung:** `bpm_progression_service` (+5 / +2 / bleibt nach Selbsteinschätzung 3/2/1), Ziel-Tempo je Übung, „Mastered“ bei Ziel.
- **Wiederholung:** `spaced_repetition_service` (vereinfachtes SM-2), Tagesplan `routine_provider`, Trainingsprogramm `features/program`.
- **Messung:** Pad über Mikrofon; Set über MIDI (Etappe 2, Messung am Set in Arbeit). `analyzeStrokes` liefert Treffer, Timing, Gleichmäßigkeit.
- **Lehrtext:** `technique`-Abschnitte (Why / How / Tips / Song examples) auf der Info-Seite, nur auf Abruf.

## 2. Die Stufenleiter (von Uli bestätigt)

| Bereich | Beginner | Intermediate | Advanced | Profi |
|---|---|---|---|---|
| **Hände: Technik** | Griff, Rebound, Einzelschläge, Full Stroke + Tap | Down-/Up-Stroke, Akzente, Doppelschläge | Möller-Peitsche, Free Stroke, Finger-Kontrolle | Möller schnell, Push-Pull, Gladstone-Feinheiten |
| **Hände: Rudiments** | Single + Double Stroke, Paradiddle | Flam, Drag, Five/Seven Stroke Roll | Flam-Rudiments, Paradiddle-Diddle, Swiss Army | Hybrid-Rudiments, ungerade Gruppen (5er, 7er) |
| **Füße** | Heel-down, gleichmäßige Viertel, Hi-Hat-Fuß auf 2 + 4 | Heel-up, Kick auf 16tel-Positionen | Fuß-Doppelschläge (Slide, Heel-Toe) | Doppelbass, Swivel, schnelle Fuß-Triolen |
| **Koordination + Independence** | Hände + Fuß zusammen, Money Beat | Ostinato rechte Hand, Snare + Kick variieren | Ghost Notes gegen Kick-Figuren, Hi-Hat-Fuß als dritte Stimme | Vierstimmige Unabhängigkeit, Polyrhythmen (3 gegen 4) |
| **Groove-Vokabular** | Rock 8tel, einfacher Pop | Funk 16tel, Shuffle, Halftime | Linear, Bossa, Songo-Einstieg, 6/8 + 12/8 | Gospel-Chops, ungerade Takte (7/8, 5/4), Afro-Cuban |
| **Groove: Metal** | Rock-Metal 8tel, Skank-Beat langsam | Thrash/Skank, Doppelbass-8tel unter Halftime | Doppelbass-16tel-Grooves, Gallop, Blast-Beat-Einstieg | Blast Beats (Traditional, Hammer, Bomb), Doppelbass-Triolen, Breakdowns |
| **Fills** | Viertel- und 8tel-Fills um die Toms | 16tel-Fills, Crash-Übergänge | Triolen- und Flam-Fills, über den Taktstrich | Lineare Fills, Gruppierungen, Modulationen |

Jede Zelle: **eine Handvoll Übungen (Richtwert 5)**, aufeinander aufbauend.

## 3. Ziel, Nicht-Ziele, Anti-Ziele

**Ziel (Runde 1).** Der Trainingsraum mit allen 7 Bereichen in den Stufen **Beginner und Intermediate** (Richtwert 7 × 2 × 5 ≈ 70 Übungen),
jede in jedem Tempo übbar, mit Tempo-Leiter, Ziel-Tempo, Wiederholung, Erklärung auf Wunsch und einer Einheit aus Aufwärmen + Vertiefen.

**Nicht-Ziele (Runde 1).** Advanced und Profi (Runde 2, gleiche Bauart); Song-Import und Mitspielen zum Original (Teil 3);
Video-Erklärungen (eigene Sitzung); Freischalten, Punkte, Abzeichen.

**Anti-Ziele.** Langweilige Übungen; eine Erklärung, die bei jedem Start abläuft; eine Übung, die man nur im Originaltempo spielen kann;
ein Kurs, durch den man sich klicken muss, bevor man üben darf; Inhalte oder Aufmachung, die Drumeo abpausen.

## 4. Entwurf

### 4.1 Eine Übung

- **Noten** in der neuen Übungsansicht (Teil 1): Bühne mit Foto, weißes Notenblatt mit ausgeschriebenen Vier-Takt-Seiten.
  Eine Übung ist eine kurze Folge von Zeilen (wie die heutigen Blätter), die sich innerhalb der Übung steigert.
- **Tempo-Leiter.** Start bei einem Einstiegstempo (Übung) bzw. beim zuletzt sauber gespielten Tempo. Nach jeder Runde
  (Richtwert: einmal durch alle Zeilen) entscheidet die App: **sauber → +4 BPM**, knapp → bleibt, daneben → −4 BPM (nie unter Einstieg).
  „Sauber“ kommt aus der Messung (Treffer- und Timing-Werte von `analyzeStrokes`); wo nichts gemessen werden kann, entscheidet der Spieler
  mit drei Knöpfen wie heute (Struggled / OK / Solid). Tempo ist jederzeit von Hand änderbar.
- **Ziel-Tempo** je Übung. Erreicht und sauber = **„sitzt“**; die Übung geht in die Wiederholung (bestehendes SM-2).
- **Erklärung auf Wunsch:** ein Knopf „How to play“ zeigt Text (Why / How / Tips / Song examples) und spielt ihn auf Wunsch als Stimme.
  Nie automatisch.
- **Songnamen:** Grooves können „Wie in: <Song> (<Band>)“ tragen; nur der Groove als Noten, keine Aufnahmen, keine Logos.

### 4.2 Eine Einheit

- **Aufwärmen** (Richtwert 5 Min.): 2–3 kurze Übungen aus Hände + Füße der eigenen Stufe, in bequemem Tempo, keine Tempo-Leiter.
- **Vertiefen** (Rest, Richtwert 25 Min.): ein Bereich. **Vorschlag der App:** der Bereich, der am längsten nicht dran war bzw. in dem
  Übungen fällig sind; frei wählbar. Darin: fällige Wiederholungen zuerst, dann die nächste noch nicht sitzende Übung der Stufe.
- Der **Heute-Bildschirm** zeigt die Einheit als Startpunkt („Continue“) wie heute den Pfad.

### 4.3 Stufe und Lernweg

- Jeder Bereich hat **seine eigene Stufe** (man kann bei Füßen Beginner und bei Händen Intermediate sein). Start: Beginner, oder vom Spieler gewählt.
- Eine Stufe gilt als geschafft, wenn ein Großteil ihrer Übungen sitzt (Richtwert 4 von 5); die nächste Stufe ist trotzdem jederzeit offen.
- Anfänger-Übungen zielen auf **instinktive Bewegung**: wenige Figuren, viele Wiederholungen, gleichmäßiges Timing vor Tempo.

### 4.4 Inhalt

- Wird mit dem Katalog-Werkzeug (`tool/katalog/`) geschrieben, wie die bisherigen Blätter, und von Uli über Kurationsseiten abgenommen
  (pro Bereich eine Seite).
- **Vorhandene Blätter wiederverwenden**, wo sie in eine Zelle passen (z. B. Rudiment- und Füße-Blätter, Grooves), und auf Vier-Takt-Zeilen bringen.
- Jede Übung: Bereich, Stufe, Einstiegstempo, Ziel-Tempo, Lehrtext (Why/How/Tips/Song examples), optional Songname.

### 4.5 Verhältnis zum Bestehenden (Uli, 31.10.)

- **Der Trainingsraum ersetzt Trainingsprogramm und Tagesplan.** „Continue“ auf dem Heute-Bildschirm startet immer die Einheit
  (Aufwärmen + Vertiefen). `features/program` und der Tagesplan (`routine_provider`) fallen als eigene Wege weg.
- **„Das bisher Gebaute nicht komplett verwerfen.“** Schlagkontrolle, Rudiments, Pad-Übungen usw. kommen neu in den Trainingsraum,
  **bauen aber auf dem alten Stand auf**: vorhandene Blätter, Lehrtexte, Messung, Tempo-Steigerung und Wiederholung werden
  übernommen und weiterentwickelt, nicht neu erfunden. Der bisherige Fortschritt (`RudimentProgress`) bleibt erhalten, wo eine
  Übung im Trainingsraum weiterlebt (gleiche ID oder Zuordnung alt → neu).
- Die **8 geführten Übungen** bleiben eine eigene Übungsform (5-Minuten-Ablauf mit Lehrerstimme) und werden den passenden Zellen
  (Groove, Hände) als „geführte Variante“ zugeordnet. *(Meine Wahl.)*

### 4.6 Entscheidungen aus der Builder-Prüfung *(alle meine Wahl, Uli prüft beim Lesen)*

1. **Messung:** Was gemessen werden kann (Pad über Mikrofon, Set über MIDI, sobald Etappe 2 B.3 fertig ist), steuert die
   Tempo-Leiter automatisch. Alles andere — auch Fuß-Stimmen am Pad — läuft mit den drei Knöpfen. Runde 1 wartet **nicht** auf B.3.
2. **Tempo-Bereich** bleibt 40–240 BPM. Schnelle Figuren (Blast, Doppelbass) werden über die Notenwerte (16tel, 32tel) geschrieben,
   nicht über Tempo > 240.
3. **„Sitzt“** = zwei saubere Runden hintereinander im Ziel-Tempo. Im Trainingsraum ersetzt die Tempo-Leiter (+4 / 0 / −4) die
   bisherige Steigerung (+5 / +2 / 0); Mastered/Wiederholung (SM-2) wird weiterverwendet. Nur ein Fortschrittsbegriff in Heute und Stats.
4. **Bereich und Stufe** sind neue Felder je Übung (genau ein Bereich). Die Stufe nutzt das vorhandene `Difficulty`
   (beginner/intermediate/advanced/professional). Die Achsen Skill/Genre/Limb bleiben als Filter in der Bibliothek.
5. **Aufwärmen** nimmt je eine Übung aus Hände-Technik, Rudiments und Füße, jeweils aus der niedrigeren der eigenen Stufen;
   gibt es für eine Stufe noch keine Inhalte, die höchste vorhandene. Ist nichts fällig, schlägt die App den Bereich vor,
   der am längsten nicht dran war.
6. **Erklärung als Stimme** mit der vorhandenen Piper-Stimme (`tool/stimme`), wie bei den geführten Übungen.
7. **Songnamen** wählt der Bauende, nur als Text („Like in: …“), keine Transkription des echten Songs, keine Logos.
8. **Lehrtexte** englisch (App-Regel), Kurationsseiten deutsch. Je Bereich eine Kurationsrunde; Ulis Rückmeldung fließt ein,
   bevor der nächste Bereich beginnt.
9. **Stufe geschafft** ab 80 % sitzender Übungen der Zelle.

## 5. Dem Bauenden überlassen

Datenmodell und Verhältnis zu `Rudiment`/Programm/Tagesplan (ersetzen oder erweitern), genaue Schwellen für „sauber“ und „knapp“,
Rundenlänge, Navigation zum Trainingsraum, Reihenfolge der Bereiche beim Schreiben. Pläne in mehreren Etappen (Gerüst + ein Bereich zuerst, dann Bereich für Bereich mit Kuration).
