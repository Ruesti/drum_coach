> **Status: Konzept. Kein Arbeitsauftrag.** Aktive Etappe siehe `docs/BRIEF_ETAPPE1_PAD.md`.

# Briefing: drum_coach als Song-Übungs- und Content-Zentrale

**Stand:** 05.09.2026 · **Zweck:** Grundlage für eine Konzept-/Design-Session. Alles Nötige steht in diesem Dokument; kein Zugriff auf Repo oder Maschinen erforderlich.

---

## 1. Vision

drum_coach (bestehende Flutter-App für Schlagzeug-Übungen am Practice Pad) soll zur **Drum-Coach- und Content-Zentrale** ausgebaut werden. Kern-Anwendungsfall:

> „Ich möchte **diese Zeile** aus **diesem Song** lernen und üben."

Gewünscht ist die Funktionalität, die Songsterr heute bietet — Noten synchron zum Song sehen, Bereich markieren, loopen, Geschwindigkeit variieren — aber **komplett in der eigenen App**, ohne Abo, plus dem entscheidenden Mehrwert: **den markierten Ausschnitt als dauerhafte Übung speichern**, die dann im bestehenden Übungssystem lebt (Notation, Metronom, Fortschritt, adaptives Programm).

Absehbar entsteht dabei viel Inhalt, der fürs Handy zu umfangreich wird — Zielbild ist: **auf dem Handy anstoßen/üben, auf Tablet/Desktop kuratieren und ausbauen**. Perspektivisch könnte eine Play-Store-Version entstehen; deshalb dürfen keine rechtlichen Abkürzungen eingebaut werden.

## 2. Rechtliche Leitplanken (recherchiert, bindend fürs Konzept)

- **Songsterr:** Die Nutzungsbedingungen verbieten ausdrücklich automatisierte Tools/Skripte/KI-Agenten, die Plus-(Bezahl-)Funktionen umgehen. Ein automatisches Anzapfen von Songsterr-Daten aus der App heraus ist damit ausgeschlossen — unabhängig vom Abo-Status. Songsterr ist künftig nur noch Referenz zum Nachschauen, keine Datenquelle.
- **YouTube:** Herunterladen/Extrahieren von Audio verstößt gegen die YouTube-Nutzungsbedingungen, und Google entfernt Play-Store-Apps, die das tun — dieser Weg ist versperrt. **Erlaubt** ist das Einbetten des offiziellen YouTube-Players (so macht es Songsterr selbst): Der Stream läuft über YouTube, die App synchronisiert nur ihre Notation dazu. Der offizielle Player kann von Haus aus 0,25×–2× Geschwindigkeit **mit Tonhöhen-Erhalt** sowie Springen/Loopen über die Player-Schnittstelle.
- **Lokale Dateien:** Audio, das der Nutzer besitzt (CD-Rip, Kauf-Download, eigene Aufnahme), ist unproblematisch.

## 3. Validierter Durchbruch: eigene Transkriptions-Pipeline (Machbarkeitstest bestanden)

Statt fremder Tab-Datenbanken erzeugt eine **lokale KI-Pipeline** die Drum-Noten direkt aus einer Audiodatei. Am 05.09.2026 auf der eigenen GPU-Maschine (RTX 3090) end-to-end getestet mit „Battery" (Metallica, Remaster — schnelles Thrash-Schlagzeug als Härtetest):

1. **Demucs v4** (Meta, Open Source, Modell `htdemucs_ft`): trennt die Drum-Spur aus der fertigen Aufnahme heraus („Quellentrennung"). Dauer: ~12 Sekunden GPU-Zeit für einen 5:15-Song. Ergebnis-Qualität der isolierten Drum-Spur: vom Nutzer als sehr gut bewertet.
2. **ADTOF** (Forschungs-Tool, Open Source): transkribiert die isolierte Drum-Spur zu MIDI mit 5 Klassen — Kick (35), Snare (38), Hi-Hat (42), Tom (47), Becken/Ride (49) — inklusive Anschlagstärke.

**Testergebnis Battery:** 2.475 Noten (930 Kick, 573 Snare, 710 Hi-Hat, 100 Tom, 162 Becken). Erste erkannte Note bei exakt 38 Sekunden = der Band-Einsatz nach dem Akustik-Intro. **Das heißt: Die erzeugten Noten sind inhärent synchron zum Original-Audio** — das Sync-Problem (Noten ↔ Song) ist damit strukturell gelöst, weil die Noten aus genau diesem Audio berechnet werden. Nutzer-Urteil nach Anhören (isolierte Spur + hörbar gemachtes MIDI) und Notenansicht in MuseScore: „von der Qualität absolut überrascht" (positiv).

**Bekannte Grenzen der Pipeline:**
- Schnellste Doublebass-Sechzehntel (~187 BPM) werden teils zusammengefasst/ausgelassen — bei Extrem-Tempo ist Nachkorrektur nötig; normale Grooves sind gut.
- Das rohe Transkriptions-MIDI hat **kein Tempo-Raster**: Noten liegen auf echten Zeitpunkten (Sekunden), nicht auf Zählzeiten. Tempo-Erkennung und Quantisierung (Einrasten aufs Notenraster) sind Aufgabe des App-Imports.
- Die Pipeline läuft auf Desktop-Systemen (Linux/Windows/macOS; GPU empfohlen, CPU geht langsamer) — **nicht auf dem Handy**. Sie läuft einmal pro Song auf einem fähigen Rechner; die App konsumiert nur die kleinen Ergebnisse (MIDI + Audio).

## 4. Relevanter Bestand der App (worauf das Konzept aufsetzen kann)

- **Notations-Engine:** eigene 5-Linien-Notation mit gemischten Notenwerten (Ganze bis 32tel, punktiert), Triolen/Sextolen, Flams/Drags (Grace Notes), Akzenten, Ghost Notes; Layout bricht an Taktgrenzen um. Datenmodell: `StrokeBeat`-Liste pro Übung, internes Zeitraster 24 Ticks pro Viertel.
- **Metronom/Playback-Engine:** Timing-Isolat (eigener Thread) mit beliebigem Tick-Faktor, Pattern-Wiedergabe über Pro-Tick-Lautstärken (`PatternPlayback`), Beat-Cursor in der Notation läuft synchron mit. Audio via `flutter_soloud`; „Speed ohne Tonhöhenänderung" ist damit machbar (Wiedergabetempo ändern + Tonhöhe per Filter gegenkompensieren).
- **Übungssystem:** Übungen mit Min-/Ziel-BPM, Schwierigkeit, Sammlungen, pro Übung gemerktes Tempo mit Bewertungs-Logik (Struggled/OK/Solid → Tempo-Anpassung), adaptives Trainingsprogramm, Spaced Repetition. Ein Song-Ausschnitt sollte einfach eine weitere Übungsquelle werden (`ExerciseSource.excerpt` existiert im Datenmodell bereits als Platzhalter).
- **Plattform:** Flutter — läuft auf Android, iOS, Windows, macOS, Linux. Es existiert eine separate Desktop-Roadmap (P1 Plattform-Bootstrap in Arbeit, P2 MIDI-Eingang vom E-Kit, P3 Mehrspur-Notation, P4 Desktop-UX). **Synergie:** Der Song-Import (MIDI-Datei → interne Notation) teilt sich Grundlagen mit P2/P3 (MIDI-Noten → Voices mappen; mehr als eine Stimme darstellen). Die heutige Notation ist Einzelspur (Sticking) — Kick/Hi-Hat/Becken gleichzeitig darstellen ist ein bekannter, noch offener Umbau (P3).

## 5. Architektur-Eckpunkte (bereits durchdacht, als Ausgangspunkt)

- **Quellen-neutrale App-Seite:** Die App importiert MIDI + Audio, egal woher (eigene Pipeline, gekaufte MIDI, DAW-Export). Keine Kopplung an einen Dienst.
- **Zwei Abspielquellen:** (a) lokale Audiodatei — voller Funktionsumfang inkl. eigenem Zeitdehnungs-Playback; (b) YouTube-Embed — für Songs ohne eigene Datei, Player übernimmt Speed/Seek, App synchronisiert Notation über die Player-Zeit (ein Ankerpunkt genügt bei konstantem Tempo).
- **Play-Store-Weiche:** Für Fremdnutzer ohne GPU-Rechner bräuchte es später einen Transkriptions-Dienst (Server, laufende Kosten) oder „bring deine eigene MIDI". Fürs Eigennutzungs-MVP irrelevant, sollte die Architektur aber nicht verbauen.

## 6. Offene Design-Fragen (das eigentliche Arbeitsprogramm der Session)

1. **Workflow-Split Handy/Desktop:** Wo passiert was? Z. B.: Handy = Wunsch anstoßen + fertige Übung üben; Desktop/Tablet = Ausschnitt wählen, Tempo prüfen, Noten korrigieren. Oder alles auf jedem Gerät?
2. **Pipeline-Anbindung:** Wie kommt ein neuer Song in die App? (Manuell Dateien rüberkopieren? Watch-Ordner? Kleiner Dienst auf der GPU-Box, den die App anstößt?)
3. **Tempo & Quantisierung:** Wie wird aus zeitbasiertem MIDI ein sauberes Notenbild? (Tempo schätzen aus Notenabständen? Nutzer tippt Tempo/Ankerpunkt? Taktart-Annahme 4/4 mit Override?) Wie geht man mit Tempo-Schwankungen um?
4. **Ausschnitt-Auswahl-UI:** In der Notation markieren (wie Songsterr)? In einer Wellenform? Beides synchron?
5. **Übungs-Format:** Was speichert ein Song-Ausschnitt? (Notenausschnitt, Audio-Referenz + Zeitfenster, Ursprungs-Song-Metadaten, eigenes Tempo-Gedächtnis wie bestehende Übungen?)
6. **Mehrspur-Darstellung:** Ausschnitte enthalten Kick/Snare/Hi-Hat/Becken gleichzeitig — wie viel Mehrspur-Notation braucht das MVP, und wie verhält sich das zur Desktop-Roadmap P3?
7. **Korrektur-Editor:** Wie leichtgewichtig kann Nachkorrektur einzelner erkannter Noten sein (falsch erkannte/fehlende Schläge), ohne einen vollen Noteneditor zu bauen?
8. **Etappenschnitt:** Was ist das kleinste Stück mit echtem Nutzwert? (Vorschlag zur Diskussion: lokale Datei + Loop + Zeitdehnung ohne Notation als Etappe 1; MIDI-Import + Notation als Etappe 2; YouTube-Embed als Etappe 3.)

## 7. Was ausdrücklich NICHT Teil des Konzepts sein soll

- Songsterr-Scraping oder -Automatisierung (ToS-Verstoß)
- YouTube-Audio-Download (ToS-Verstoß, Play-Store-K.-o.)
- Transkription auf dem Handy (technisch unrealistisch)
- Blast-Beat-perfekte Erkennung (bekannte Modell-Grenze; Korrektur-Editor ist der Ausgleich)

