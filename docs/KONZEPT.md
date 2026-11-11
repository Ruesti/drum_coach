Status: Gültiges Konzept. Ersetzt alle früheren Konzeptdokumente.
BERICHT_NEUKONZEPT.md, BERICHT_NEUKONZEPT_ERGAENZUNG.md, BRIEF_SONG_UEBUNGEN.md,
BRIEF_ETAPPE1_PAD.md → docs/archive/. Was dort steht und hier fehlt, gilt nicht.
Stand: 11.11.2026 · Fassung 1
1. Kern
Die App hört deine Schläge, vergleicht sie mit dem Soll und sagt dir, was du korrigieren sollst.
Alles, was dazu nicht beiträgt, steht auf dem Parkplatz (Abschnitt 7).
2. Vision
Die App begleitet einen Drummer vom Einstieg bis „100". Sie misst, wo jemand steht,
und beantwortet: „Was mache ich jetzt?" Fortschritt = bestandene Gates, nicht
konsumierte Inhalte oder Kalenderwochen.
Keine Mechanik ist auf eine Einzelperson zugeschnitten. Ziele, Stil und Niveau
bestimmt der Nutzer; die App misst Können statt Selbstauskunft.
3. Rahmen
Instrument: Drum-Kit via MIDI (E-Drums). Pad/Mikrofon → Parkplatz.
„Null": Sitzt am Set und kann einen Takt durchhalten. Griff, Haltung und
Set-Aufbau liegen außerhalb der App. Keine Lehrerfigur.
Einstieg wird gemessen: Einstiegsübung (Platzhalter: Viertel Hi-Hat,
Bassdrum auf 1 und 3, 8 Takte bei 70 BPM ohne Abbruch). Wer sie nicht schafft,
bekommt den Hinweis „erst Grundlagen" statt eines unpassenden Pfads.
„100": Alle Gates der höchsten Stufe bestanden und ein beliebiger
importierter Song innerhalb definierter Toleranzen spielbar.
Genre-neutral: Stufen und Gates sind stilunabhängig formuliert.
Rock/Punk/Metal ist der erste Inhaltsstrang, nicht das Modell.
4. Architektur — drei Schichten, von unten gebaut
Messkern: MIDI-Eingang, Mapping Note → Instrument, Latenzmessung und
-kompensation, Abgleich Ist/Soll pro Schlag. Ohne UI testbar.
Fähigkeitsmodell: Gates mit Zahlen (Tempo, Timing-Streuung, Velocity-
Konstanz, Fehlerquote, Dauer). Bestimmt Stand und nächsten Schritt.
Pfad und Inhalte: Grooves, Fills, Rudiments, Songs. Wächst langfristig;
Schicht 1 und 2 müssen von Anfang an tragen.
5. Messgrößen pro Schlag
Timing-Abweichung in ms (latenzkompensiert)
Velocity
Instrument richtig / falsch
Schlag fehlend / zusätzlich
Hand-Zuordnung wird über MIDI nicht gemessen und daher nicht behauptet.
6. Etappe 1 — Kit-Messkern + ein Gate
Umfang
MIDI-Eingang vom MegaDrum, Mapping-Konfiguration
Latenz messen und kompensieren
Metronom + Soll-Pattern
Abweichung pro Schlag (Abschnitt 5)
Eine Feedback-Ansicht
Eine Übung mit einem Gate: Basic Rock Beat (Achtel)
Einstiegsübung (Abschnitt 3)
Abnahme (Zahlen festzulegen in §0)
Latenz: gemessen, dokumentiert, kompensiert; Restfehler ≤ X ms
Messkern gegen aufgezeichnete MIDI-Referenzdateien: Ergebnis reproduzierbar
Gate „Basic Rock Beat" mit definierten Schwellen; Bestehen/Nichtbestehen
nachvollziehbar aus den Messwerten
Codebasis: Bestehender Code ist Steinbruch, nicht Basis.
Vor dem Neustart: Stand per Git-Tag legacy-v0 sichern (nichts wird gelöscht).
§0 enthält eine Bestandsaufnahme des Altcodes: je Modul Zweck, Zustand
(funktioniert / defekt / unbekannt), Wiederverwendung (ja / nein / später, Parkplatz).
7. Parkplatz
Nicht Teil der aktuellen Arbeit; wird erst nach Etappe 1 neu bewertet.
Pad-Training mit Handymikrofon (inkl. Lern-/Analysemodus)
Song-Import (Demucs + ADTOF)
Groove-Progression in voller Breite (Varianten via Becken/Half-/Double-Time)
Off-Kit-Übungen (Widerstandstrainer)
ComfyUI-Bilder/-Videos
Hybrid-Rudiments
Weitere Genres
8. Offene Fragen
MIDI-Routing neben Superior Drummer: gleicher Rechner? Betriebssystem?
(Windows: ggf. virtueller Splitter nötig; Linux/ALSA: unkritisch — Einschätzung)
Abgrenzung zu Melodics: Melodics bietet E-Kit-Feedback via MIDI am
Desktop. Unterscheidungsmerkmal (Fähigkeitsmodell mit Gates? Linux?)
konkret prüfen und festhalten — Einschätzung, nicht verifiziert.
Stufen-Modell: Anzahl Stufen und Gates bis „100"
