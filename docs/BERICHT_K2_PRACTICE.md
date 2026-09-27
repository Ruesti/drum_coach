# Bericht K2 Schritt 2 — Practice-Screen (26.09.2026)

Spec: `docs/superpowers/specs/2026-09-25-k2-practice-design.md`,
Plan: `docs/superpowers/plans/2026-09-25-k2-practice.md`, Branch `k2-practice`.

## Was gebaut wurde

Der Übungs-Screen folgt jetzt dem K2-Entwurf vom 15.09.: Notenblatt und
Zählwerk sind das Herz, die Steuerung darunter ist kompakt, Seltenes liegt
hinter „⋯". Der Screen bleibt dunkel.

- **Kopfzeile ohne AppBar:** Zurück, Name der Übung, darunter eine
  Kontextzeile. Today gibt seinen Pfad-Schritt („Day 9 · Step 2 of 3 · 84 BPM")
  über den neuen Query-Parameter `ctx` mit; ohne `ctx` steht die Stufe der
  Übung („Beginner"). Rechts der Modus-Chip mit Mikro-Symbol „ANALYSIS" oder
  „LEARN", nur bei eingeschalteter Mikro-Analyse; ein Tipp wechselt den Modus.
  Info-Knopf, Modus-Symbol und die zwei Uhren der alten Kopfzeile sind weg.
- **Notenblatt** mit 16 px Rand als Papierkarte, füllt den freien Platz.
- **Klick-Spur statt Zählwerk** (Auftraggeber 27.09. nach dem Emulator-Test:
  „Das Zählwerk mag ich nicht, lieber ein mitlaufender Metronom-Klick,
  wählbar"): ein eigener kurzer, heller Puls auf jedem Viertel als zweite
  Stimme im gerenderten Loop, neben den Muster-Noten. Schalter „Click track"
  im „⋯"-Blatt, Standard an, in den Einstellungen gemerkt; im Analyse-Modus
  immer aus (das Mikro würde ihn als Schläge hören). Das Zählwerk-Widget ist
  gelöscht, der Platz geht ans Notenblatt.
- **Steuerung:** Leiter-Chips wie bisher (Label „LADDER"), dann `TempoRow`
  mit Minus, großer BPM-Zahl, Plus. Plus/Minus springen 4 BPM (eine
  Leiterstufe), ein Tipp auf die Zahl öffnet den Eingabe-Dialog. Schieberegler
  und ±1/±5-Knöpfe entfallen.
- **Hauptknopf** orange: „Start  8 min" vor dem Start (Label und Zeit mit
  Abstand, ohne Mittelpunkt), „Stop 07:32" laufend (Restzeit, bei ∞ die
  verstrichene Zeit), „Resume 07:32" pausiert. Pausiert
  erscheint darunter eine volle Zeile „Finish", die das Bewertungs-Blatt
  öffnet. Zeitablauf beendet die Sitzung automatisch wie bisher.
- **„⋯"-Blatt:** Dauer (5/10/15/∞ plus Vorschlag „8 min ✦", nur vor dem
  Start änderbar, danach der Hinweis „Duration is set once the session runs"),
  Klang (Click/Rim/Snare), „About this exercise" (Erklärung), „Done".
- **Unverändert:** Messung, Mikro, Alignment, Bewertungs- und Feedback-Blatt
  (Schritt 3 „Result").

## Entscheidungen

| Frage | Entscheidung | Wer/Wann |
|---|---|---|
| Ein Knopf für Stop und Finish? | Stop pausiert; pausiert erscheint „Finish" | Auftraggeber 25.09. |
| Schrittweite Plus/Minus | 4 BPM, Feinwert über Dialog (Tipp auf Zahl) | Spec |
| Finish neben Resume und ⋯? | Nein: eigene Zeile darunter — drei nebeneinander liefen auf 360 dp um 80 px über | Umsetzung 26.09. (Ruling im Ledger) |
| Sitzungsuhr (Tageszeit) in der Kopfzeile | Entfällt hier. Der Provider läuft weiter (Snapshot nutzt ihn), wird aber derzeit nirgends angezeigt — Today/Progress zeigen die Minuten aus den gespeicherten Sitzungen. Ob Today/Progress ihn anzeigen oder er wegfällt: Entscheidung in Schritt 3 | Spec + Review 26.09. |
| Kontextzeile beim freien Üben | Vorerst die Stufe der Übung; K4 (Bibliothek) darf das ändern | Spec §6 |

## Review-Befunde (frischer Reviewer, 26.09.) und Fixes

- **Zählwerk bei Mustern kürzer als ein Takt** (wichtig, behoben): die Spec-Formel
  brach den Tick am Muster um; bei 19 von 41 Übungen im Seed (Schleife 2, 3, 5,
  6 oder 7 Schläge) blieben dadurch Ziffern dauerhaft grau. Jetzt zählt das
  Zählwerk aus dem globalen Tick des Motors, der Cursor auf dem Blatt folgt
  weiter der Schleife. Test: Six Stroke Roll bei Tick 80 → „4" leuchtet.
- **Zeitablauf bei offenem „⋯"-Blatt** (hochgestuft, behoben): die Bewertung
  stapelte sich auf das Blatt, der letzte Pop schloss das Blatt statt den
  Screen. Jetzt schließt der Auto-Abschluss das Blatt zuerst. Test dazu.
- Kleinere Punkte (zurückgestellt, siehe Ledger): Blatt ohne Scroll-Reserve bei
  großer Systemschrift, Dauer-Sperre erst ab der zweiten Sekunde, Layout-Sprung
  beim Erscheinen der Finish-Zeile, Tastatur-Resize des Scaffolds, kein
  Deaktiviert-Zustand von ± bei 40/240, Kopfzeile 17/13 px statt 22 px.
- Folgeticket Inhalt: Seed-Muster auf ganze Takte bringen oder `beatsPerBar`
  setzen (wie `barCountOrThrow` es für Étüden schon erzwingt).

## Tests

| Bereich | Datei | Tests |
|---|---|---|
| Zählwerk + Takt-Rechnung | `test/features/practice/beat_counter_test.dart` | 5 |
| Tempo-Zeile (±4, Klemmung, Dialog) | `test/features/practice/tempo_row_test.dart` | 3 |
| Route mit `ctx` | `test/features/program/practice_route_test.dart`, `test/features/today/next_step_test.dart` | 3 + angepasst |
| Screen: Zustände, Kontext, Zählwerk, Leiter-Rebase, Modus-Chip, Überlauf, ⋯-Blatt | `test/features/practice/practice_session_screen_test.dart` | 15 |

Screen-Tests laufen auf Handy-Fläche 1080×2340 (dpr 3), damit Überläufe
auffallen. Der Modus-Chip-Test beantwortet den Methodenkanal von
permission_handler selbst (Mikrofon = 7, granted = 1), weil der echte Screen
beim Einschalten der Mikro-Analyse eine Berechtigung anfragt.

Ganze Suite auf der GPU-Box: **302 Tests grün**, `flutter analyze` nur die 12
bekannten `experimental_member_use`-Warnungen.

## Gerätetest S23

Steht aus — der Laptop war beim Abschluss der Umsetzung (26.09., nachts)
nicht erreichbar. Vorgesehen: Release-Build aus
`~/agent-test-checkouts/drum_coach-k2-practice`, Screenshots bereit, laufend,
pausiert, „⋯"-Blatt nach `~/k2-practice-screens/`. Vor jedem adb-Tipp wird
geprüft, dass `com.example.drum_coach` im Vordergrund ist.

| Zustand | Screenshot | Befund |
|---|---|---|
| bereit | ausstehend | |
| laufend | ausstehend | |
| pausiert | ausstehend | |
| ⋯-Blatt | ausstehend | |

## Offen

- Feinschritte ±1 nur über den Dialog; falls das am Pad stört: Langdruck.
- Kontextzeile beim freien Üben aus der Bibliothek (K4).
- Schritt 3 „Result": Bewertung ins Ergebnis-Blatt, Klartext-Kernwerte.
