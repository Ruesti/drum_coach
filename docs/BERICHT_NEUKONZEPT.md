# Drum-Coach: Standort-Bericht für die Neukonzeption

**Datum:** 05.09.2026 · **Zweck:** Grundlage für eine Konzept-Session in claude.ai.
Dieses Dokument ist bewusst in sich geschlossen — es setzt keinen Zugriff auf den
Code voraus und fasst zusammen: was die App heute kann, was die Praxistests ergeben
haben, warum die App die Erwartungen verfehlt, was technisch behalten werden kann,
und welche Fragen das neue Konzept beantworten muss.

---

## 1. Was die App heute ist

Eine Flutter-App (Android, S23 Ultra als Testgerät) zum Üben am Practice-Pad.
Kernscreens:

| Bereich | Inhalt |
|---|---|
| **Dashboard** | Streak, Tagesziel, Einstiegskarten zu Programm/Sammlungen/Routine |
| **Routine** | Tagesliste aus Spaced Repetition („Wiederholen nach Vergessenskurve"): fällige Übungen mit BPM- und Dauer-Vorschlag |
| **Trainingsprogramm** | Adaptives Programm: Dauer (Wochen), Startniveau, Übungspool wählbar; pro Tag 3 Blöcke (Warmup · Technik · Tempo-Leiter), Wochenrhythmus 5 Übungstage + 1 leichter Tag + 1 Ruhetag; Stufenaufstieg über „Clean Pass"-Abfrage |
| **Lessons** | Erklärseiten pro Übung (Sticking, Beschreibung) |
| **Übungs-Sammlungen** | Rudiment-Étüden, Technik-Studien, Pad-Workouts — Browse nach Schwierigkeit |
| **Practice-Session** | Notenzeile mit Playback-Cursor, Metronom (Klick/Rim/Snare-Sample), ±5/±1-BPM, Countdown-Timer, Session-Timer, Mikrofon-Analyse (Timing/Dynamik pro Hand), Bewertung nach der Session (+2/+5 BPM Progression), KI-Feedback (Claude-API optional) |
| **Stats** | Verlauf, Streak, Bestwerte |

**Übungsbestand:** 41 Basis-Rudiments (Seed) + ~86 generierte Übungen in drei
Sammlungen (50 Rudiment-Étüden = 10 Rudiments × 5 Schwierigkeitsstufen, 6
Technik-Studien, 30 Pad-Workouts, zuletzt als „Grooves" neu komponiert). Die
Übungen sind über eine interne Kurzsprache (DSL) definiert und wurden von Claude
generiert — nicht von einem Schlagzeuger kuratiert.

**Technik-Stack (funktioniert, getestet — 183 automatisierte Tests):**
- Notation-Engine mit echter Musiknotenschrift (Bravura/SMuFL-Font), gemischte
  Notenwerte, Triolen/Sextolen, Akzente, 2 Takte/Zeile, Auto-Scroll
- Metronom in einem eigenen Thread (präzises Timing), Pattern-Clock 24 Ticks
  pro Viertel, pro-Note-Lautstärken, echtes Snare-Sample
- Mikrofon-Onset-Erkennung (frisch repariert: erkennt jetzt auch schnelle
  Schlagfolgen zuverlässig, Sample-genaue Zeitstempel)
- Lokale Datenbank (Isar): Sessions, Fortschritt pro Übung, Spaced-Repetition-Werte
- Adaptions-Mechanik: BPM-Progression durch Selbstbewertung, „sauberes Tempo"
  pro Übung, Stufenaufstieg im Programm

**Offene Stände (Stand heute):** PR #14 (alle Gerätetest-Fixes + eingemergte
Drafts #11/#13) ist bereit; PR #12 (Desktop-Bootstrap Windows/macOS/Linux) liegt
als Draft bereit — die Desktop-Version hat also schon ein technisches Fundament.
Bekanntes Problem: Release-Build scheitert an einer veralteten Bibliothek
(`isar_flutter_libs`/compileSdk) — Tests laufen bisher als Debug-Build.

---

## 2. Was die Praxistests ergeben haben

Zwei Gerätetest-Runden (04./05.09.) haben ~14 konkrete Bugs gefunden und behoben
(Mic-Erkennung, BPM-Leak zwischen Übungen, Timer-Verlust, fehlender
Tages-Abschluss, Tempo-Leiter ohne Leiter-Verhalten, Regressionen durch
ungemergte Branches). Diese handwerklichen Probleme sind gelöst — **aber der
eigentliche Befund liegt tiefer:**

> „Generell gefällt mir die App noch nicht sehr bzw. erfüllt nicht meine
> Erwartungen/Wünsche."

Die vier Kernkritikpunkte:

1. **Trainingsprogramm ≈ Routine.** Beide liefern am Ende dasselbe Erlebnis:
   eine Liste „Übung X, Y BPM, Z Minuten". Das Programm war als **Boot Camp**
   gedacht: den User da abholen, wo er steht — **eventuell mit einer Prüfung des
   Könnens (Assessment)** — und dann gezielte Übungen, um die Grundfähigkeiten
   messbar zu verbessern.
2. **Übungsqualität.** Die generierten Übungen sind nicht alle interessant,
   machen nicht durchgehend Spaß, zu wenig abwechslungsreich. Erwartung:
   musikalisch sinnvolle, motivierende Stücke — nicht Pattern-Permutationen.
3. **Notation & UI.** Referenz ist **Drumeo**: dort sind die Noten „sehr schön
   und übersichtlich gezeichnet". Die eigene Notation ist technisch gut, aber
   nicht auf diesem Niveau. Die UI soll insgesamt „mehr crisp" werden — es gab
   bereits einen Design-Durchgang („60cm-Redesign"), der reicht aber nicht.
4. **Alle Lessons und Übungen sind zu überarbeiten.** Der Content als Ganzes
   steht zur Disposition, nicht nur einzelne Stücke.

Außerdem geplant: **eine Desktop-Version nebenbei** (Fundament existiert, s. o.).

---

## 3. Analyse: Warum die App die Erwartung verfehlt

**a) Das Programm ist ein Tagesblock-Generator, kein Curriculum.**
Es wählt aus einem Pool nach Schwierigkeit und rotiert — es hat kein Bild vom
Können des Users und keine Ziele („nach 4 Wochen: Doubles sauber bei 120 BPM").
Es misst nichts am Anfang (kein Assessment), verfolgt keine benannten
Grundfähigkeiten (z. B. Handausgleich L/R, Timing-Präzision, Tempo-Ausdauer,
Dynamik-Kontrolle), und feiert keine Meilensteine. Deshalb fühlt es sich wie die
Routine an: beide sind Listen, keine Reise.

**b) Ironie: Die Messtechnik für ein Assessment existiert bereits.**
Die Mikrofon-Analyse liefert heute schon Timing-Abweichung pro Hand, Jitter
(Gleichmäßigkeit) und Lautstärke-Balance L/R. Das wird aber nur als Statistik
nach der Session angezeigt — es steuert nichts. Ein Boot-Camp-Konzept könnte
genau darauf aufbauen: Eingangstest → Schwächenprofil → gezielter Plan →
Wiederholungstest.

**c) Content-Strategie „generiert" hat ihre Grenze erreicht.**
Die DSL kann jede Übung ausdrücken, aber Generierung ersetzt keine Komposition.
Drumeo-Content funktioniert, weil er von Musikern für ein Gefühl von Fortschritt
und Groove geschrieben ist. Fürs neue Konzept ist zu entscheiden: kuratierter
Kern-Katalog (weniger, aber gut — ggf. an echten Standardwerken wie Stick
Control / Syncopation orientiert) plus Generierung nur für Drill-Varianten.

**d) UI ist funktional, nicht „crisp".**
Standard-Material-Bausteine, viele kleine Chips/Zeilen, Information dicht
gepackt. Drumeo setzt auf große, ruhige Flächen, wenige klare Aktionen pro
Screen, hochwertige Notendarstellung als Herzstück. Der bestehende Design-Brief
(`docs/design/BRIEF_UI_CLAUDE_DESIGN.md`) und der Competitor-Scan
(`docs/COMPETITOR_SCAN.md`) sind als Vorarbeiten vorhanden.

---

## 4. Was behalten werden sollte (Assets)

Das neue Konzept startet nicht bei null. Erhaltenswert, weil solide und getestet:

1. **Notation-Engine** (Bravura, gemischte Notenwerte, Cursor, Auto-Scroll) —
   Layout-Politur nötig, kein Neubau.
2. **Metronom-Engine** (Thread-präzise, Pattern-Clock, Samples).
3. **Mic-Analyse** (Onset-Erkennung, Timing/Dynamik pro Hand) — der Rohstoff
   für Assessment und messbare Gates.
4. **Fortschritts-Datenmodell** (Sessions, per-Übung-BPM, Spaced Repetition,
   sauberes Tempo) — die Mechanik ist da, ihr fehlt nur die Dramaturgie.
5. **Tempo-Leiter-Mechanik** (Stufen, Clean-Pass, folgt jetzt dem manuell
   gewählten Tempo) — als Baustein innerhalb eines echten Programms.
6. **Desktop-Bootstrap** (PR #12) und die Test-Infrastruktur (183 Tests,
   Gerätetest-Workflow über den Laptop).

---

## 5. Fragen, die das neue Konzept beantworten muss

Für die claude.ai-Session — am besten in dieser Reihenfolge:

**Produktkern**
1. Wer ist der User (nur du, oder perspektivisch andere)? Welches Level, welches
   Equipment (nur Pad? später Set?), wie viel Zeit pro Tag realistisch?
2. Was ist das Versprechen des Boot Camps in einem Satz? (z. B. „In 8 Wochen
   von X nach Y, messbar.")
3. Welche **Grundfähigkeiten** soll die App benennen und messen? Vorschlag als
   Startpunkt: Timing-Präzision, Hand-Balance (L/R), Tempo-Spektrum,
   Dynamik-Kontrolle, Ausdauer, Vokabular (Rudiments beherrscht).

**Assessment & Programm**
4. Wie sieht der Eingangstest aus? (z. B. 3–5 kurze Messaufgaben mit Mikrofon:
   Singles bei Wohlfühltempo, Maximaltempo 30 s sauber, Doubles, Dynamik-Wechsel
   — daraus ein Schwächenprofil.)
5. Wie oft wird nachgemessen (wöchentliche „Prüfung"? Levels mit Abzeichen)?
6. Wodurch unterscheidet sich das Programm sichtbar von der Routine — oder wird
   die Routine ins Programm integriert (eine einzige tägliche Reise statt zwei
   paralleler Listen)?

**Content**
7. Kuratierter Kern-Katalog: Wie viele Stücke, welche Quellen/Vorbilder, welcher
   Anteil Groove/Musik vs. Drill? Was passiert mit den bestehenden 86
   generierten Übungen (aussortieren, überarbeiten, behalten)?
8. Brauchen Übungen Audio-Vorspiel (Play-Along wie bei Drumeo) zusätzlich zur
   Notation?

**UI/UX**
9. Was genau bedeutet „crisp" — welche 2–3 Referenz-Screens von Drumeo (oder
   anderen) definieren die Messlatte? (Screenshots in die Session mitnehmen.)
10. Notations-Politur konkret: Was fehlt gegenüber Drumeo (Stichdicke,
    Abstände, Balken-Layout, Taktzahlen, Zählzeiten unter den Noten …)?

**Plattform**
11. Rolle der Desktop-Version: vollwertiger Client, Übungs-Editor („Studio" zum
    Kuratieren des Contents?), oder Anzeige-Companion? Was zuerst?

---

## 6. Empfehlung für den Ablauf

1. **Konzept-Session in claude.ai** mit diesem Bericht + 2–3 Drumeo-Screenshots
   → Produktkonzept („Boot Camp"-Definition, Fähigkeiten-Modell, Assessment-
   Design, Content-Strategie, UI-Leitplanken).
2. Daraus einen **Umsetzungs-Brief** ableiten (wie bei früheren Briefs in
   `docs/archive/`), den Claude Code phasenweise abarbeitet — die vorhandenen
   Assets aus Abschnitt 4 als Bausteine.
3. Erst danach Content-Überarbeitung im großen Stil — gegen die neuen
   Qualitätskriterien, nicht vorher.

*Verweise im Repo (falls die Session doch Code-Kontext braucht):
`docs/COMPETITOR_SCAN.md`, `docs/design/BRIEF_UI_CLAUDE_DESIGN.md`,
`docs/archive/STICK_CONTROL_PROGRAM.md` (ursprüngliche Programm-Spec),
`docs/PHASES.md`, PR #14 (aktueller Stand), PR #12 (Desktop).*
