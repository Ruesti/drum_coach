# BRIEF: Training Program „Stick Control – 12 Wochen" (DrumCoach)

> **Rolle:** Hintergrund-Agent auf dem NUC (`claude --bg`), beobachtet vom Handy.
> **Spec:** `STICK_CONTROL_PROGRAM.md` — dies ist die *Anweisung*, jene die
> *Spezifikation*. Bei Konflikt gewinnt die Spec inhaltlich; diese Datei regelt
> das *Wie* (Gates, Commits, Bericht).

---

## §0 · Interview-Gate — ZUERST, kein Code davor

Beantworte diese Fragen aus dem Repo/Environment und **halte an, bis sie geklärt
sind**. Wenn etwas nicht aus dem Repo hervorgeht, frag zurück — nicht raten,
nicht implementieren.

1. **Repo & Toolchain:** Existiert das DrumCoach-Repo auf diesem Host? Läuft
   `flutter --version` und `flutter analyze` auf einem *sauberen* Checkout grün?
   Falls nein → das ist Blocker #1, melden statt weitermachen.
2. **Modell-Abgleich:** Das Seed in Spec §9.1 nimmt an: `Rudiment(key, name,
   sticking, category, minBpm, maxBpm, difficulty)`. Stimmen Feldnamen und
   `RudimentCategory`-Enumwerte mit der echten `CLAUDE.md` / dem echten Modell
   überein? Wenn nicht → Abweichungen auflisten und die Spec-Werte darauf
   abbilden, **bevor** geseedet wird.
3. **Generator:** Wo lebt der bestehende „Daily Routine Generator"? Erweitern,
   nicht neu bauen. Pfad + aktuelle Signatur nennen.
4. **Branch:** Bestätige die Branch-Konvention (eine Session = ein Branch).
   Lege `feature/training-program-stick-control` an und arbeite nur darauf.

**Erst nach beantwortetem §0 beginnt die Implementierung.**

---

## 1 · Scope

Umsetzen wie in `STICK_CONTROL_PROGRAM.md` §4, §5, §9:

- Neue Isar-Collections: `TrainingProgram`, `ProgramPhase`, `ProgramDay`
  (`DayType`: practice|light|rest), embedded `ExerciseBlock`
  (`BlockType`, `Variant`). Modell **exakt** wie §4.
- Seed: die drei Rudiments (§9.1) + das Programm „Stick Control – 12 Wochen"
  mit 4 Phasen (§2 Tempi/Gates, §9.2 `focus`/`exerciseKey`/`variants`).
- Generator erweitern, sodass er 84 `ProgramDay` aus Phasen + Wochenrhythmus
  (§5) **expandiert**, nicht hart speichert. Phase-4-Sonderfall (§9.3) beachten.
- Programm-Screen: aktueller Tag, `focus`-Text, Blöcke mit Zieltempo, Start.
  `rest` = eigener „Ruhetag"-Zustand, bricht Streak nicht.
- Gate: nach `tempoLadder` die Abfrage „Sauber & locker?" (§6). Hinter
  `cleanPassRequired`, mic-ready lassen.

### Ausdrücklich OUT OF SCOPE
- **Die Metronom-Engine wird nicht angefasst.** Kein Refactor, kein Timing-Fix.
- Keine neuen Dependencies ohne Rückfrage.
- Kein Mikro-/Audio-Analyse-Code (das ist Phase 8, nicht hier).

---

## 2 · Arbeitsweise

- **Kleine Schritte, Commit-on-green.** Nach jedem Stand, der `flutter analyze`
  grün und (wo vorhanden) Tests grün lässt: sofort committen. Aussagekräftige
  Messages, ein logischer Schritt pro Commit.
- Reihenfolge: (a) Modelle + Codegen → (b) Seed → (c) Generator → (d) Screen.
  Nach (a)–(c) ist alles headless verifizierbar; (d) ist UI und wird nur
  gebaut, nicht bewiesen.
- Keine stillen Überschreibungen. Bestehende Dateien nur gezielt ändern.

---

## 3 · Budget & Stop

- Lauf unter dem gesetzten Budget-Ceiling. Näherst du dich der Grenze:
  **aktuellen grünen Stand committen, Teil-`BERICHT` schreiben, dann stoppen** —
  nicht mitten in einem roten Zustand abbrechen.
- Der Daemon erzwingt das Ceiling via `claude stop`; deine Aufgabe ist nur,
  keinen kaputten Zustand zu hinterlassen, wenn es greift.

---

## 4 · Definition of Done (beweisbar, headless)

Jeder Punkt mit Proof-Kommando im Bericht:

- [ ] `flutter analyze` grün. → Output einfügen.
- [ ] Modelle + Isar-Codegen bauen (`dart run build_runner build`). → Output.
- [ ] Seed lädt: die drei Rudiments + das Programm existieren. → kurzer Query/Test.
- [ ] Generator erzeugt **84** `ProgramDay`; dow 6 = `light`, dow 7 = `rest`.
      → Assertion/Test-Output, der die Zählung und die Typen zeigt.
- [ ] `rest`-Tage haben leere Blockliste und zählen nicht gegen den Streak.
      → Test.
- [ ] Tempo-Leiter-Startwert = gespeichertes sauberes Tempo (nicht 0). → Test.
- [ ] Gate-Feld `cleanPassRequired` im Modell vorhanden, self-rating nicht
      hartcodiert. → Codeverweis.

### NICHT headless — bleibt beim Menschen
- „Durchlauf Tag 1 → Tag 8 inkl. Ruhetag in der laufenden App" (Spec §8).
  Der Agent baut den Screen, **verifiziert ihn aber nicht**. Im Bericht klar als
  offen markieren mit Hinweis „UI-Check am Gerät / über Cockpit durch Uli".

---

## 5 · Bericht

Schreibe `BERICHT_TRAINING_PROGRAM.md` ins Repo mit:
1. §0-Antworten (was vorgefunden, welche Modell-Abweichungen abgebildet).
2. Erledigte DoD-Punkte je mit Proof-Output.
3. Offene Punkte (mind. der UI-Check) + was der Mensch als Nächstes tun muss.
4. Commit-Range dieses Laufs (`git log --oneline`).
5. Falls durch Budget gestoppt: wo genau, und was der saubere Wiederaufsetzpunkt ist.

---

## Kickoff (auf dem NUC)

```
claude --bg
> Lies BRIEF_TRAINING_PROGRAM.md und STICK_CONTROL_PROGRAM.md.
> Arbeite §0 zuerst ab und halte für Rückfragen an, bevor du Code schreibst.
```
