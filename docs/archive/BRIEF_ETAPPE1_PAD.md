# Brief: Etappe 1 — Pad-Training unterwegs

**Datum:** 06.09.2026 · **Zeitrahmen:** sechs Reisewochen ab sofort (bis ca. Mitte
Oktober) · **Gerät:** S23 Ultra, Practice-Pad, Mikrofon, Kopfhörer · **Laptop dabei**

**Bezug:** `BERICHT_NEUKONZEPT.md`, `BERICHT_NEUKONZEPT_ERGAENZUNG.md` (Fassung 2).
Dieser Brief setzt die Ergänzung für die erste Etappe um. Alles Nötige steht hier;
die beiden Dokumente liefern Hintergrund, keine zusätzlichen Anforderungen.

---

## Leitprinzip

> **Messung glaubwürdig vor Features. Nichts, was nicht dem Pad dient.**

Die sechs Wochen sind zweierlei: Üben, und der erste echte Datensatz für den
Assessment-Entwurf im Oktober. Deshalb steht die Integrität der Messung vor
allem anderen. Eine Zahl, die manchmal falsch ist, ist schlechter als keine.

Ausgangsbasis ist PR #14 (gemergt). Debug-Build ist für das eigene Gerät
ausreichend; das Release-Build-Problem (`isar_flutter_libs`/compileSdk) wird in
dieser Etappe nicht angefasst, es sei denn, es blockiert den Gerätetest.

---

## §0 — Bestandsaufnahme vor dem ersten Code

Claude Code beantwortet diese Fragen aus dem Code und legt sie als
`BERICHT_ETAPPE1_§0.md` ab. Erst danach beginnt Phase 1. Antworten, die eine
Annahme dieses Briefs widerlegen, führen zu einer Rückfrage, nicht zu stillem
Umdeuten.

1. **Hand-Zuordnung:** Wie ordnet die Mic-Analyse heute Onsets den Händen zu?
   Positionszählung (Onset n ↔ Note n), zeitliche Nächste-Nachbar-Suche, oder
   ein Abgleich, der Auslassungen erkennt? Was passiert bei einem fehlenden oder
   zusätzlichen Schlag?
2. **Aufnahmeweg:** Welches Plugin nimmt auf, mit welcher Android-`AudioSource`?
   Sind Pegelregelung (AGC), Rauschunterdrückung und Echo-Cancellation aktiv?
   Ist `UNPROCESSED` auf dem S23 Ultra verfügbar? Wie ist die Verstärkung gesetzt?
3. **Zeitbasis:** Auf welcher Zeitachse liegen Onset-Zeitstempel (Aufnahme-Puffer)
   und Klick-Zeitpunkte (Metronom-Thread)? Werden sie heute irgendwo aufeinander
   bezogen? Gibt es eine Latenz-Korrektur?
4. **Session-Datenmodell:** Was speichert eine Session heute in Isar? Liegen
   Roh-Onsets vor oder nur Aggregate (Mittelwerte, Abweichung pro Hand)?
5. **Tagesstruktur:** Wie entsteht die heutige Tagesliste (Routine) und die
   Tagesblöcke des Programms? Wo ist die Stelle, an der eine variable Dosis
   eingehängt werden kann?
6. **Kopfhörer-Erkennung:** Gibt es bereits eine Abfrage, ob Kopfhörer stecken
   (kabelgebunden/Bluetooth)?

---

## Phase 1 — Messung glaubwürdig

### 1.1 Roher Aufnahmeweg
- Aufnahme über `AudioSource.UNPROCESSED`, falls verfügbar; sonst
  `VOICE_RECOGNITION` mit ausdrücklich deaktivierten Effekten (AGC, NS, AEC).
- Feste Verstärkung, keine automatische Anpassung.
- **Abnahme:** Test mit abwechselnd lautem und leisem Schlag über 20 Schläge.
  Der Pegelunterschied muss im Rohsignal erhalten bleiben (Verhältnis der
  Spitzenwerte stabil, keine Angleichung über die Zeit). Ergebnis als Zahl in
  den Bericht.

### 1.2 Sequenzabgleich statt Positionszählung
- Erwartete Notenfolge (aus Übung + gewähltem BPM) und erkannte Onsets werden als
  zwei Sequenzen gegeneinander ausgerichtet (Alignment mit Kosten für
  Auslassung, Einfügung und Zeitabweichung). Ergebnis pro erwarteter Note:
  getroffen (mit Onset) oder ausgelassen; pro Onset: zugeordnet oder überzählig.
- Hand-Zuordnung folgt ausschließlich aus dem Sticking der **zugeordneten** Note.
  Nicht zugeordnete Onsets bekommen keine Hand.
- **Vertrauensmaß** pro Durchlauf: Anteil getroffener Noten, abzüglich
  überzähliger Onsets. Unter einer Schwelle (Vorschlag: 90 % getroffen, < 5 %
  überzählig) werden **keine Hand-Werte** ausgegeben, nur die
  zuordnungsfreien Größen.
- **Abnahme:** Übung R L R L, ein Schlag bewusst ausgelassen. Vorher: alle
  folgenden Hände vertauscht. Nachher: eine Auslassung erkannt, Hand-Zuordnung
  danach korrekt. Beide Ergebnisse als Tabelle in den Bericht.

### 1.3 Latenz-Bezug zwischen Klick und Aufnahme
- Onset-Zeitstempel und Klick-Zeitpunkte auf eine gemeinsame Zeitachse bringen.
- Einmalige Kalibrierung: Klick über Lautsprecher abspielen, aufnehmen, Versatz
  zwischen geplantem und aufgenommenem Klick messen und speichern. Bei
  Kopfhörer: gespeicherter Wert wird verwendet; zusätzlich wird der mittlere
  Versatz aller Onsets eines Durchlaufs als systematischer Anteil ausgewiesen
  (nicht stillschweigend abgezogen).
- **Abnahme:** Kalibrierung liefert reproduzierbaren Wert (drei Durchläufe,
  Streuung < 5 ms). Wert im Bericht.

### 1.4 Zuordnungsfreie Messgrößen
Unabhängig vom Alignment, immer verfügbar:
- Timing-Abweichung gegen Klick (Median, Streuung)
- Gleichmäßigkeit: Streuung der Onset-Abstände
- Dynamik-Streuung: Streuung der Spitzenpegel (nur bei rohem Aufnahmeweg)
- Schlagzahl Ist/Soll

**Phase-1-Bericht:** `BERICHT_ETAPPE1_P1.md` mit allen Abnahmewerten und
Gerätetest. Erst danach Phase 2.

---

## Phase 2 — Roh-Logging jeder Session

Zweck: Sechs Wochen Material für den Assessment-Entwurf. Nichts wird
weggerechnet, was später gebraucht werden könnte.

**Pro Session (Kopf):** Session-ID, Zeitpunkt, Übungs-ID, Modus (Lernen/Analyse,
ab Phase 3), gewähltes BPM, Dauer, Gerät, Aufnahmekonfiguration (AudioSource,
Sample-Rate, Verstärkung, Effekte an/aus), Kopfhörer ja/nein, gespeicherter
Latenz-Wert, Selbstbewertung nach der Session.

**Pro Ereignis:** Onset-Zeitstempel (Sample-genau, in ms auf der gemeinsamen
Zeitachse), Spitzenpegel, Alignment-Ergebnis (zugeordnete Notenposition oder
„überzählig"), abgeleitete Hand (falls zugeordnet und über Schwelle),
Klick-Zeitpunkte des Durchlaufs.

**Ablage:** In Isar, zusätzlich **Export als Datei** (JSONL, eine Datei pro
Session oder pro Tag) über den Teilen-Dialog, damit die Daten unterwegs den
Weg zum Laptop finden.

**Abnahme:** Eine echte Übungssession exportieren, auf dem Laptop öffnen, alle
Felder befüllt. Beispieldatei in den Bericht.

**Phase-2-Bericht:** `BERICHT_ETAPPE1_P2.md`.

---

## Phase 3 — Lern- und Analysemodus

- **Lernmodus** (Standard): alle zuordnungsfreien Größen, tolerantes
  Vertrauensmaß, keine Hand-Werte. Fehler sind hier normal.
- **Analysemodus** (manuell einschaltbar pro Übung): zusätzlich Hand-Balance
  (Timing und Pegel pro Hand), strenge Schwelle aus 1.2. Fällt der Durchlauf
  unter die Schwelle, sagt die App das: *„Zu viele Aussetzer für eine
  Hand-Analyse — das sitzt noch nicht."*
- Der Modus wird pro Übung gemerkt und im Session-Log festgehalten.
- **Nicht in dieser Phase:** der automatische Vorschlag der App, in den
  Analysemodus zu wechseln. Dafür braucht es die Daten aus Phase 2.

**Abnahme:** Gerätetest beider Modi an derselben Übung; die UI zeigt im
Lernmodus keine Hand-Werte, im Analysemodus nur über der Schwelle.

**Phase-3-Bericht:** `BERICHT_ETAPPE1_P3.md`.

---

## Phase 4 — Variable Tagesdosis

- Die Tagesliste hat einen **Minimal-Kern** (5–10 Min: das, was heute am
  wichtigsten ist — nach heutiger Logik: fälligste Wiederholung plus eine
  Technik-Übung) und **optionale Blöcke**, die man dranhängt, wenn Zeit ist.
- Der Tag gilt nach dem Kern als abgeschlossen. Der Streak zählt Anwesenheit,
  nicht Pensum.
- Kein Kalender-Rückstand: ein ausgefallener Tag verschiebt nichts, er kostet
  nur Zeit.

**Abnahme:** Gerätetest über drei Tage mit 10, 30 und 0 Minuten. Kein
„Rückstand"-Zustand, Streak korrekt, Kern immer sinnvoll gewählt.

**Phase-4-Bericht:** `BERICHT_ETAPPE1_P4.md`.

---

## Phase 5 — Ein-Antwort-Startbildschirm (optional)

Nur wenn Phase 1–4 stabil laufen. Der Startbildschirm zeigt **eine** Übung mit
Tempo, Dauer und einem Satz, warum sie jetzt dran ist; ein Tipp startet sie.
Programm/Sammlungen/Routine bleiben dahinter erreichbar. Keine Designarbeit —
funktionaler Umbau mit vorhandenen Bausteinen.

---

## Ausdrücklich nicht in dieser Etappe

- MIDI, Desktop-Client (PR #12), Song-Import, Transkriptions-Pipeline
- Mehrspur-Notation, Notations-Politur, UI-Redesign
- Content-Überarbeitung der 86 generierten Übungen
- Onboarding-Fragen, Zielprofil, Gates, automatischer Modus-Vorschlag
- Datenabgleich Handy ↔ Desktop (Export als Datei genügt)
- Release-Build-Fix (nur wenn er den Gerätetest blockiert)

---

## Arbeitsweise

- Jede Phase endet mit Gerätetest und Bericht. Der Bericht enthält die
  Abnahmewerte als Zahlen, nicht als Beschreibung.
- Phasen werden nicht parallel begonnen. Phase 1 blockiert alles Weitere.
- Änderungen an der Session-Datenstruktur werden vor der Umsetzung als Schema
  im Bericht angekündigt, weil die Daten der sechs Wochen davon abhängen.
- Rückfragen an den Auftraggeber, wenn §0 eine Annahme dieses Briefs widerlegt
  oder eine Abnahme nicht erreicht wird.
