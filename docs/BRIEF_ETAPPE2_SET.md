# Brief: Etappe 2 — Set-Training zuhause

**Datum:** 10.10.2026 · **Zeitrahmen:** zwei Wochen bis zur Heimkehr (ca. 24.10.),
danach Abnahme am Set · **Geräte:** E-Drum-Set mit Millenium-Modul (USB-MIDI und
5-Pol-MIDI-Ausgang), Linux-Laptop, S23 Ultra per OTG-Kabel; später Windows-PC mit
Superior Drummer

**Bezug:** `concept/BERICHT_NEUKONZEPT_ERGAENZUNG.md` Abschnitte 3, 4, 5D, 5E, 5F, 7
und 9; `PHASES.md` „Etappen"; Desktop-Roadmap und P4-Entwurf aus Draft-PR #12 (nur als
Ideenquelle, siehe Entscheidungen). Dieser Brief setzt die Ergänzung für die zweite
Etappe um. Alles Nötige steht hier; die anderen Dokumente liefern Hintergrund.

Abweichung von `PHASES.md`: Dort sollte der Brief erst nach Etappe 1 plus
Assessment-Session entstehen. Er wird vorgezogen, weil das Set in zwei Wochen
erreichbar ist. Assessment und Onboarding bleiben deshalb außen vor (siehe
„Ausdrücklich nicht in dieser Etappe").

---

## Leitprinzip

> **Die App ist am Set ein stiller Zuhörer. Das Modul macht den Klang, die App
> misst, zählt und führt. Das Pad baut die Fähigkeit, das Set weist sie nach.**

Mesh-Felle sind leise, der Klang kommt aus dem Kopfhörer am Modul. Deshalb gilt am
Set nur MIDI als Messung (Ergänzung 5E). MIDI ist das digitale Signal, das das Modul
bei jedem Schlag sendet: welches Pad, wann, wie stark. Eine Zahl, die manchmal falsch
ist, bleibt schlechter als keine; ohne MIDI-Gerät zeigt die App „nicht messbar"
statt einer Zahl.

Ausgangsbasis ist `main` nach Merge der Katalog-PRs #30 und #32. Sind sie beim
Start noch offen, wird von `main` gebranchet und die Katalog-Erweiterung (Phase B.1)
wartet, bis sie drin sind.

---

## Entscheidungen vom 10.10.2026

**Geräte-Bild.** Drei Aufbauten müssen mit demselben Code funktionieren:

| Phase | Klang der Schläge | App läuft auf | MIDI-Weg |
|---|---|---|---|
| jetzt | Millenium-Modul, Kopfhörer am Modul | Linux-Laptop oder S23/Tablet per OTG | USB vom Modul |
| später, gleiche Maschine | Superior Drummer auf Windows | derselbe Windows-PC | USB, Port muss geteilt werden |
| später, getrennt | Superior Drummer auf Windows | Laptop oder Tablet | Modul-USB an Laptop, 5-Pol an den PC |

1. **Stiller Zuhörer.** Die App erzeugt am Set keine Schlagklänge. Das macht das
   Modul, später Superior Drummer. App-eigene Set-Klänge sind ein Extra für Etappe 3.
2. **Klick und Band aus der App**, per Kabel in den AUX-Eingang des Moduls, dort im
   Kopfhörer zusammen mit dem Modulklang. Annahme: Das Modul hat einen AUX-Eingang.
   Die App muss die Schläge nicht hören, deshalb braucht es keinen Weg vom Modul
   zurück in den Laptop.
3. **Schlagquelle als Baustein.** Ein- und Ausgang werden getrennte Abstraktionen
   (Ergänzung 5E), jetzt eingezogen. Zwei Umsetzungen: Mikrofon und MIDI. Jedes
   Schlag-Ereignis trägt von Anfang an Zeitpunkt, Instrument und Anschlagstärke.
4. **Volles Set im Instrument-Modell von Anfang an**: Kick, Snare mit Rand, Hi-Hat
   geschlossen/offen/Pedal, zwei Hänge-Toms, zwei Stand-Toms, zwei Crashes, Ride,
   Ride-Glocke, China, Splash. Phase A loggt alle, bewertet nur die Snare. Phase B
   bewertet alle.
5. **MIDI-Quelle geräteneutral.** Jedes Modul, jeder Port, Zuordnung per Lernschritt.
   Das Port-Teilen unter Windows (Superior Drummer belegt den Port) kommt erst, wenn
   Superior Drummer da ist; Lösungen sind bekannt (virtueller Port oder der 5-Pol-Ausgang
   des Moduls an ein zweites Gerät).
6. **Draft-PR #12 wird nicht rebased.** Er liegt 168 Commits hinter `main` und stammt
   von vor Etappe 1. Seine Ideen (Plattform-Erkennung, Notifications als No-Op auf
   dem Desktop, Tastenkürzel, Drei-Zonen-Layout) werden übernommen, der Code neu
   geschrieben. P4 (großes Desktop-Layout) bleibt Etappe 3.
7. **Notengenerierung aus MP3 (Demucs + ADTOF) bleibt Etappe 3.** Begründung und die
   zwei Garantien, die Phase B dafür gibt, stehen im eigenen Abschnitt unten.

---

## §0 — Vorversuch: MIDI-Zeitstempel unter Linux und Android

**Frage:** Liefert `flutter_midi_command` (Version 1.4.0, deckt Android-USB, Linux-ALSA
und Windows ab) Zeitstempel, die für Timing-Messung taugen? Ziel: Streuung unter
2 ms, kein Drift gegen die Metronom-Uhr.

**Probe unter Linux ohne Set:** virtueller ALSA-MIDI-Port (`snd-virmidi` oder ein
kleines Sender-Skript über die ALSA-Sequencer-Schnittstelle) sendet Noten in bekanntem
Raster, zum Beispiel 120 Schläge mit exakt 500 ms Abstand und einige Flam-Paare mit
25 ms Abstand. Die App protokolliert die empfangenen Zeitstempel. Ausgewertet werden
Median und 95-%-Streuung der Abstände, einmal mit dem Zeitstempel der Bibliothek,
einmal mit der Empfangszeit aus einer monotonen Dart-Stopuhr.

**Ergebnis:** kurzer Bericht mit beiden Zahlenreihen und der Festlegung, welche
Zeitbasis Phase A benutzt. Fällt beides durch (Streuung über 2 ms oder Flams
verschmolzen), ist das ein Entscheidungspunkt: eigene FFI-Anbindung an ALSA-Raw-MIDI
statt der Bibliothek. Das darf nicht erst am Ende der zwei Wochen auffallen.

Android lässt sich ohne Hardware nicht prüfen; dort gilt die Stopuhr-Zeitbasis bis
zum Gerätetest zuhause.

---

## Phase A — Set-Minimum

Ziel: Wenn Uli heimkommt, laufen alle vorhandenen Übungen am Set, gemessen über
MIDI, auf dem Laptop und auf dem S23.

### A.1 Schlagquelle als Baustein

Eine Schnittstelle `StrokeSource` mit `start`, `stop`, einem Strom von `StrokeEvent`
und einem Status (`bereit`, `kein Gerät`, `nicht messbar`). Fähigkeiten als Flaggen:
`liefertInstrument`, `liefertVelocity`. Beide Umsetzungen liefern **keine** Hand; die
Hand kommt weiter aus dem Soll-Sticking über den Sequenzabgleich (Etappe 1, §1.2).

`StrokeEvent`: `timeMs` auf der Metronom-Uhr, `instrument` (`KitInstrument`, siehe
A.2), `velocity` 0–1, `rawNote` (MIDI-Notennummer oder null), `source` (`mic` oder
`midi`).

- **Mikrofon-Quelle** kapselt die heutige Kette (`RecordingSetup` → `OnsetDetector`
  → `SampleClockMap`). Instrument ist immer `pad`, Velocity ist der normierte
  Spitzenpegel. Die Schwellen und Filter aus Etappe 1 bleiben unverändert in dieser
  Umsetzung, sie sind mikrofonspezifisch.
- **MIDI-Quelle** über `flutter_midi_command`: Note-On mit Velocity > 0 wird zum
  Ereignis, Note-Off, Velocity 0, Aftertouch und Choke werden verworfen. **Kein
  Mindestabstand** zwischen Ereignissen: Flams kommen vom Modul als zwei Noten mit
  20–30 ms Abstand und müssen beide ankommen. Hi-Hat-Pedalstellung (Controller 4)
  wird nur mitgeloggt.

`MicAnalysisService` wird so umgebaut, dass der Abgleich (`alignSequences`) eine
Liste von `StrokeEvent` entgegennimmt, egal woher. In Phase A filtert er auf das
Instrument, das die Übung erwartet: Übungen mit `ExerciseVoicing.pad` erwarten am Set
die Snare (einstellbar, siehe A.5). Ereignisse anderer Instrumente werden nicht
bewertet, aber geloggt (A.9).

**Vorschläge (Flam, Drag):** Heute sind Vorschlagsnoten keine erwarteten Schläge
(`PatternPlayback.isOnsetTick`), das Mikrofon verschmilzt sie über den
Mindestabstand von 50 ms mit dem Hauptschlag. Die MIDI-Quelle liefert sie einzeln.
Der Abgleich nimmt deshalb ein Ereignis, das bis 40 ms vor einem erwarteten
Hauptschlag mit Vorschlag liegt, als Vorschlag und zählt es weder als Treffer noch
als Zusatzschlag. Ob der Vorschlag gespielt wurde, wandert ins Rohlog, nicht in die
Bewertung.

### A.2 Instrument-Modell: volles Set

`KitInstrument` mit General-MIDI-Vorgabenoten (das ist die übliche Standardbelegung,
die fast jedes Modul von Haus aus sendet):

| Instrument | Vorgabe-Note | Instrument | Vorgabe-Note |
|---|---|---|---|
| `kick` | 36 | `tom1` (Hänge-Tom hoch) | 48 |
| `snare` | 38 | `tom2` (Hänge-Tom tief) | 47 |
| `snareRim` (Rand, Cross-Stick) | 37 | `floorTom1` (Stand-Tom hoch) | 45 |
| `hiHatClosed` | 42 | `floorTom2` (Stand-Tom tief) | 43 |
| `hiHatOpen` | 46 | `crash1` | 49 |
| `hiHatPedal` | 44 | `crash2` | 57 |
| `ride` | 51 | `china` | 52 |
| `rideBell` | 53 | `splash` | 55 |
| `pad` (nur Mikrofon) | — | | |

`KitMapping` ordnet jedem Instrument eine Menge von Notennummern zu (ein Pad kann
mehrere Zonen senden, zum Beispiel Fell und Rand). Vorgabe ist General MIDI. Gespeichert
pro Gerätenamen als JSON in `SettingsService`.

**Lernschritt** „Schlag auf …": Die App geht die Instrumente in Set-Reihenfolge durch
(Snare, Kick, Hi-Hat geschlossen, Hi-Hat offen, Hi-Hat-Pedal, Toms von hoch nach
tief, Crash 1, Crash 2, Ride, Ride-Glocke, China, Splash). Jeder Schritt wartet auf
eine Note und zeigt die Nummer; „überspringen" ist erlaubt (nicht jedes Set hat alles).
Eine Note, die schon vergeben ist, wird mit Hinweis umgehängt. Unter zwei Minuten
für ein volles Set. Die Zuordnung ist jederzeit in den Einstellungen änderbar.

### A.3 Port-Wahl und Geräteerkennung

Liste der MIDI-Eingänge; gibt es genau einen, wird er gewählt; sonst wird der zuletzt
benutzte vorgeschlagen. Hot-Plug: Ein- und Ausstecken während der Sitzung ändert den
Status, bricht aber keine Sitzung ab (laufende Messung endet als „nicht messbar").
Im Übungs-Screen ein Status-Chip: „MIDI: <Gerätename>" oder „kein MIDI-Gerät".

### A.4 Latenz-Abgleich MIDI ↔ Klick

Der Klick aus der App braucht Zeit bis zum Ohr (Laptop-Audio → AUX → Modul →
Kopfhörer), die MIDI-Note kommt praktisch sofort. Ohne Abgleich misst die App einen
Versatz, den sie selbst erzeugt (Ergänzung 5F).

**Ablauf:** Der Nutzer spielt sechzehn Viertel auf der Snare zum Klick. Versatz =
Median der Abstände zwischen jedem Schlag und dem nächstgelegenen Klick. Angezeigt
mit Streuung; über 10 ms Streuung gilt der Abgleich als unsicher und wird wiederholt.
Gespeichert pro Gerätenamen und Quelle (`latencyOffsetMs` existiert schon für das
Mikrofon und bekommt einen zweiten Schlüssel). Die Loopback-Kalibrierung über
Lautsprecher und Mikrofon (`LatencyCalibrationService`) bleibt für die Mikrofon-Quelle.

**Zeitbasis:** `StrokeEvent.timeMs` liegt auf derselben monotonen Uhr wie
`clickTimesMs` im Rohlog. Für MIDI wird die Zeitbasis aus §0 übernommen und beim
Sitzungsstart auf die Metronom-Uhr bezogen. Vorzeichen wie bisher: positiv = zu spät.

### A.5 Übungen am Set spielbar

Alle vorhandenen Übungen (Rudiment- und Fill-Blätter, Étüden) laufen mit der
MIDI-Quelle. Das Instrument in der „Pad-Rolle" ist einstellbar, Vorgabe Snare.
Anschlagstärke kommt exakt: `DynamicsAnalysis` bekommt eine Flagge `velocityExact`;
Akzent- und Ghost-Bewertung dürfen damit erstmals eine Zahl zeigen, die Mikrofon-Quelle
bleibt bei „grob". Blattform, Lern- und Analysemodus, Tagesdosis, Band: unverändert.

**Kopfhörer-Regel:** Die Regel „Band nur mit Kopfhörer" (Engine Teil 1) schützt das
Mikrofon vor Übersprechen. Mit der MIDI-Quelle gibt es kein Übersprechen; die Regel
gilt nur für die Mikrofon-Quelle.

### A.6 Sensorstufe an Übung und Gate

Jede Übung deklariert `requiredSensor`: `none`, `mic` oder `midi`. Vorhandene
Pad-Übungen: `mic` (MIDI erfüllt `mic` immer, umgekehrt nicht). Ist die Anforderung
mit dem aktuellen Aufbau nicht erfüllt, zeigt der Übungs-Screen „nicht messbar mit
diesem Aufbau" und keine Zahl; üben geht trotzdem.

Einstellung „Messung": `Automatisch` (MIDI, wenn verbunden, sonst Mikrofon, wenn
eingeschaltet), `Mikrofon`, `MIDI`, `Aus`. Vorgabe `Automatisch`. Der heutige
Schalter `micAnalysisEnabled` geht darin auf.

### A.7 Desktop-Client Linux

- Ziel ist ein lauffähiger Linux-Build auf dem Laptop. Flutter ist dort vorhanden;
  der NUC baut mit, sobald `clang cmake ninja-build pkg-config libgtk-3-dev
  libasound2-dev` installiert sind.
- `lib/app/platform_support.dart` neu nach dem Muster aus PR #12: `isDesktopPlatform`
  mit Test-Override. Notifications auf dem Desktop No-Op. KI-Coaching auf dem Desktop
  ausgeblendet. Die Mikrofon-Quelle ist auf dem Desktop vorhanden, aber standardmäßig
  aus und als „ungeprüft" markiert (`record_linux` ist nie getestet worden). Mit der
  Vorgabe `Automatisch` (A.6) heißt das: MIDI, wenn verbunden, sonst „nicht messbar".
- Layout: das Handy-Layout, zentriert, Inhaltsbreite gedeckelt (Blattform darf
  breiter werden, Richtwert 900 px). Kein Redesign. Mindest-Fenstergröße, damit
  nichts quetscht.
- Tastenkürzel: Leertaste Start/Stopp, Plus/Minus Tempo ±1 (mit Umschalt ±5), Esc
  Sitzung verlassen.
- Kein CI-Workflow in dieser Etappe; Build-Kommando dokumentiert in `docs/CLAUDE.md`.
- Isar und `flutter_soloud` laufen unter Linux x64; `flutter_soloud` braucht beim
  Bauen die ALSA-Header.

### A.8 Android per OTG

Dieselbe MIDI-Quelle. Android fragt beim Anstecken die USB-Berechtigung ab; das
Manifest bekommt `android.hardware.usb.host` (nicht zwingend, damit die App auch auf
Geräten ohne Host-Modus installierbar bleibt). Tablet = dieselbe App mit mehr Platz,
keine eigene Arbeit in dieser Etappe. Prüfbar nur zuhause: S23, OTG-Adapter, Modul.

### A.9 Rohlog erweitert

`SessionLog` bekommt `source`, `deviceName` und eine Momentaufnahme des `KitMapping`.
`OnsetEvent` bekommt `instrument`, `velocity` und `rawNote`. Geloggt werden **alle**
Ereignisse, auch die nicht bewerteten Instrumente (Kick und Hi-Hat während einer
Snare-Übung). Das ist der erste Datensatz für Phase B und für den Assessment-Entwurf.
Export bleibt JSONL. Isar 3 nimmt neue Felder mit Vorgabewerten ohne Migration.

### Abnahme Phase A (am Set, erster Tag zuhause)

- Modul per USB am Laptop: Gerät erkannt, Lernschritt für das volle Set unter zwei
  Minuten, Zuordnung nach Neustart noch da.
- Latenz-Abgleich zweimal hintereinander: Versatz-Differenz unter 3 ms.
- Rudiment-Blatt auf der Snare bei sauberem Spiel: Trefferquote mindestens 95 %,
  Flams werden als Flam gewertet, keine Doppelzählungen.
- Akzent-Übung: erkannte Akzente stimmen mit dem Blatt überein (Velocity-basiert).
- Kick und Hi-Hat während der Übung landen im Rohlog mit richtigem Instrument.
- S23 per OTG: dieselbe Übung läuft, Rohlog gleichwertig.
- Ohne Modul: Übungs-Screen zeigt „nicht messbar", kein Absturz, Mikrofon-Weg
  unverändert (Regressionstest am Pad).

---

## Phase B — Füße und volles Set

Ziel: Grooves und Fills über das ganze Set, mehrstimmig notiert und mehrstimmig
bewertet. Hand-Fuß-Koordination wird messbar.

### B.1 Mehrstimmiges Übungsmodell

Eine Übung besteht aus **Stimmen**. Jede Stimme ist, was heute eine ganze Übung ist:
eine Liste `StrokeBeat` auf dem Raster von 24 Ticks pro Viertel, plus ein
`KitInstrument` (oder eine Instrument-Klasse, siehe B.3). Vorhandene Pad-Übungen sind
Übungen mit genau einer Stimme `pad`. Fuß-Stimmen tragen keine Hand (`hand` wird
optional); die Hand-Zuordnung und die Sticking-Buchstaben gelten nur für
Hand-Stimmen. Eine Blatt-Zeile (`ExerciseLine`) trägt je Stimme ihre Beats, die
Zeilen-Logik der Blattform (Nummern, Wiederholungen, Fenster) bleibt stimmenblind.
`etude_dsl` und das Pad-Notenbild bleiben unverändert; `PatternPlayback` mischt
Stimmen zu Pro-Tick-Lautstärken.

Die Katalog-Notenschrift `tool/katalog/sheetlang.py` (PR #30/#32) bekommt Spuren:
eine Zeile pro Instrument, zum Beispiel `HH`, `SN`, `BD`, `T1`, `F1`, `CR`, `RD`.
Snare- und Tom-Zeilen behalten `R`/`L`, Fuß-Zeilen bekommen `K` (Kick) und `P`
(Hi-Hat-Pedal). Rudiment-Blätter ohne Spurkopf bleiben gültig (eine Stimme `pad`).

### B.2 Notenbild: Standard-Schlagzeugnotation

Fünf Linien, zwei Stimmen (Hände mit Hals nach oben, Füße mit Hals nach unten),
Positionen nach der gängigen Konvention (unten nach oben):

| Instrument | Position | Notenkopf |
|---|---|---|
| Hi-Hat-Pedal | unter der ersten Linie | x |
| Kick | erster Zwischenraum | normal |
| Stand-Tom tief | zweite Linie | normal |
| Stand-Tom hoch | zweiter Zwischenraum | normal |
| Snare | dritter Zwischenraum | normal; Rand/Cross-Stick: x |
| Hänge-Tom tief | vierte Linie | normal |
| Hänge-Tom hoch | vierter Zwischenraum | normal |
| Hi-Hat geschlossen | über der fünften Linie | x; offen: x mit „o" |
| Ride | fünfte Linie | x; Glocke: Raute |
| Crash 1 / Crash 2 | erste Hilfslinie oben | x |
| China | erste Hilfslinie oben | x mit Ring |
| Splash | erste Hilfslinie oben | x klein |

Bravura liefert x-, Rauten- und Ring-Köpfe. Gleichzeitige Schläge einer Stimme teilen
sich den Hals. Die Blattform (Zeilen, Fenster, Cursor) bleibt; die Zeile wird höher.

### B.3 Messung mehrstimmig

Der Sequenzabgleich läuft **pro Stimme** gegen ihr Soll, gefiltert auf ihr Instrument.
Eine Stimme darf eine **Instrument-Klasse** verlangen statt eines Instruments
(`anyCrash`, `anyTom`, `anyCymbal`), damit ein Fill nicht an der Wahl des Beckens
scheitert. Danach zwei neue Messgrößen:

- **Hand-Fuß-Versatz:** für alle Soll-Schläge, die Hand und Fuß auf denselben Tick
  legen, die Verteilung der Zeitdifferenz Fuß minus Hand (Median, Streuung). Das ist
  Zeile 6 des Fähigkeiten-Modells (Ergänzung 7) und nur per MIDI messbar.
- **Stimmen-Trefferquote:** Trefferquote und Streuung pro Stimme, damit sichtbar wird,
  ob die Hi-Hat oder die Kick die Zeit wegzieht.

Dynamik pro Stimme (Velocity exakt). Hand-Zuordnung bleibt Soll-abgeleitet.

### B.4 Erste Set-Übungen

- Die sechs Band-Muster (`rock8`, `rock16`, `halftime`, `shuffle`, `swing`, `funk16`)
  als spielbare Grooves: Kick, Hi-Hat, Snare auf 2 und 4. Die Band schweigt in den
  Stimmen, die der Nutzer selbst spielt.
- Die acht Fill-Blätter aus Katalog 3b mit echter Time: drei Takte Groove vom Nutzer,
  ein Takt Fill, über Snare und vier Toms, Abschluss auf Crash.
- Ein Blatt „Rund ums Set": Sechzehntel-Figuren über Snare, Tom 1, Tom 2, Stand-Tom
  1, Stand-Tom 2 mit Crash-, China- und Glocken-Abschluss.
- Hi-Hat offen/geschlossen als Stimme mit beiden Instrumenten.

Alle über `tool/katalog`, kuratiert, nicht generiert.

### B.5 Fähigkeit und Repertoire pro Kontext

`Hand-Fuß-Koordination` kommt ins Fähigkeiten-Modell mit Sensorstufe `midi`. Die
Abruf-Stufen (Befund G) werden **pro Kontext** gespeichert: eine Einheit kann am Pad
auf Stufe 3 und am Set auf Stufe 1 stehen. Gates deklarieren ihre Sensorstufe (A.6)
und weisen sich als gesperrt aus, wenn die Hardware fehlt. Das volle Gate- und
Assessment-Design bleibt ein eigener Konzeptblock.

### Abnahme Phase B

- Groove `rock8` am Set: drei Stimmen bewertet, Hand-Fuß-Versatz mit Streuung
  angezeigt, Rohlog vollständig.
- Fill-Blatt mit Toms: Instrument-Klasse `anyTom` nimmt jedes Tom, ein Schlag aufs
  falsche Instrument wird als Fehlschlag gezählt, nicht als Auslassung.
- Notenbild von sechs Grooves und drei Fills als Golden-Test; Sichtprüfung auf dem
  S23 und dem Laptop.
- Pad-Übungen unverändert (Regressionstest).

---

## Phase C — Studio (Verweis auf Etappe 3)

Nicht Teil dieses Briefs, hier nur die Reihenfolge, wie sie sich aus A und B ergibt:
Song-Import aus der MP3-Pipeline, Play-Along mit Tempo ohne Tonhöhenänderung,
Korrektur-Editor, Desktop-Layout P4, Datenabgleich Handy ↔ Laptop, Superior-Drummer-
Anbindung mit Port-Teilen unter Windows, App-eigene Set-Klänge.

---

## Notengenerierung aus MP3: Entscheidung

Empfehlung: **Etappe 3**, nicht jetzt. Drei Gründe:

1. In zwei Wochen soll am Set geübt werden. Der Import bringt drei eigene Baustellen
   mit (Tempo-Raster und Quantisierung, Ausschnitt-Wahl, Korrektur-Editor), die alle
   nichts zum Üben am Set beitragen.
2. Die Pipeline liefert fünf Klassen (Kick, Snare, Hi-Hat, Tom, Becken). Sie
   unterscheidet weder die vier Toms noch Crash, Ride, China und Glocke. Für das volle
   Set, das Phase B aufbaut, wäre das Ergebnis grob.
3. Die Pipeline ist validiert und läuft nicht weg. Sie wird nicht schlechter, wenn
   sie wartet.

**Zwei Garantien aus Phase B, damit der Import später ohne Modell-Umbau kommt:**

- `KitInstrument` trägt General-MIDI-Nummern. Die fünf Pipeline-Klassen (35, 38, 42,
  47, 49) landen direkt auf `kick`, `snare`, `hiHatClosed`, `tom2` und `crash1`.
- Das mehrstimmige Übungsmodell (B.1) nimmt eine MIDI-Datei als Stimmen auf. Der erste
  Importweg in Etappe 3 ist bewusst einfach: Tempo und Startpunkt tippt der Nutzer
  ein, die App rastet die Noten ein. Automatische Tempo-Erkennung kommt danach.

---

## Ausdrücklich nicht in dieser Etappe

- App-eigene Klänge für Schläge am Set (Modul oder Superior Drummer macht das)
- Superior-Drummer-Anbindung, Port-Teilen und Build unter Windows (erst wenn
  Superior Drummer da ist)
- Desktop-Layout P4 (Seitenleiste, Drei-Zonen-Screen), CI-Workflow
- Song-Import, MP3-Pipeline, Editor (Etappe 3)
- Onboarding-Fragen, Assessment, Ziel-Profil, vollständiges Gate-Design
- Datenabgleich Handy ↔ Laptop (Export als Datei genügt; Fortschritt am Set entsteht
  zunächst auf dem Laptop)
- BLE-MIDI; feiner Hi-Hat-Öffnungsgrad über Controller 4 (nur Logging)
- iOS, macOS, Web

---

## Technische Festlegungen

- Bibliothek `flutter_midi_command` ^1.4.0 mit `flutter_midi_command_linux`; kein
  BLE-Paket. Pub.dev nennt Android, Linux (ALSA), Windows (win32) als unterstützt.
- Zeitbasis aus §0; alle `StrokeEvent.timeMs` auf der Metronom-Uhr.
- MIDI-Quelle ohne Mindestabstand; Mikrofon-Schwellen bleiben in der Mikrofon-Quelle.
- `KitMapping` als JSON pro Gerätename in `SettingsService`; Vorgabe General MIDI.
- Isar-Schema: neue Felder in `SessionLog` und `OnsetEvent` mit Vorgabewerten.
- `lib/app/platform_support.dart` mit Test-Override; keine `Platform.is*`-Weichen
  verstreut im Code.
- Tests: Einheitstests mit synthetischen `StrokeEvent`-Strömen (JSON-Fixtures, darunter
  ein aufgezeichneter Set-Lauf aus dem Gerätetest); Abgleich mit Instrument-Filter;
  Abgleich-Mathematik der Latenz; Lernschritt und Mapping; Linux-Integrationstest
  über virtuellen ALSA-Port als Skript `tool/midi/virtual_port_test.sh`; Golden-Tests
  fürs mehrstimmige Notenbild (B).

---

## Arbeitsweise

- §0 zuerst, ein Tag, mit Bericht. Dann Phase A als Plan (writing-plans) und
  Umsetzung durch Teilagenten, jede Aufgabe mit Tests zuerst.
- Jede Phase endet mit Gerätetest und Bericht (`BERICHT_ETAPPE2_A.md`,
  `BERICHT_ETAPPE2_B.md`) nach dem Muster von Etappe 1.
- Builds: Linux auf dem Laptop (oder NUC nach Paket-Installation), APK auf dem NUC
  wie bisher. Sichtprüfung auf dem Emulator, Messung nur am Set.
- Zeitplan: §0 plus Phase A etwa zehn Tage (bis ca. 22.10.). Phase B beginnt, sobald
  A auf dem virtuellen Port grün ist, und läuft über die Heimkehr hinaus. Abnahme A am
  ersten Tag am Set; Befunde daraus fließen in B.
