# Neue Übungsansicht, Trainingsraum, Song-Import — Gesamtbild

Stand: Entwurf 29.10.2026 · Branch `spec-trainingsraum` (gestapelt auf
`spec-gefuehrte-uebungen`, Draft-PR #36) · Status: **von Uli freigegeben 29.10. 22:19** (Teil 1 zum Bau; Teil 2/3 als Richtung)

Drei Vorhaben, die aufeinander aufbauen. **Teil 1 ist ausgearbeitet und wird als
Nächstes gebaut.** Teil 2 und 3 stehen hier nur als Richtung; jedes bekommt vor dem
Bau ein eigenes Design-Dokument.

Vorbild: Drumeo (Musora). Uli hat am 28.10. eine Lektion aus der Drumeo Method
(Pfad 9, Lektion 10 „Two Funky Kicks“) in Firefox laufen lassen und findet den Look
„super“. Prinzipien übernehmen, keine Inhalte kopieren. Bildschirmfoto der Lektion:
NUC `~/drumeo-look.png`; Pfad-Übersicht der Method: NUC `~/drumeo-method-stufen.md`.

## 0. Ulis Wünsche (sinngemäß, 28./29.10.)

- „Bau den drum coach in diesem Look um.“ Von drei Entwürfen
  (https://claude.ai/artifact/QpGrbCgaEnnW8S8z7RCrYA) gefällt **Entwurf A** am
  besten: Bühne mit Foto oben, weißes Notenblatt unten. **„Das Foto etwas breiter.“**
- Was heute stört: **„Zu wenig Inhalt in der Notenzeile“** (ein Takt mit
  Wiederholungszeichen) und **„die Hintergrundbilder sind überdeckt oder
  abgeschnitten“**.
- Die Übungen sollen **herausfordernder** sein; das gezeigte Drumeo-Stück ist „nur
  intermediate“.
- 400 Lektionen wie bei Drumeo sind **zu viel**; Freischalten nach Veröffentlichung
  will er nicht. Was an Drumeo fehlt: **Tempo frei wählen**. „Entweder man kommt mit
  oder nicht.“
- Ziel: **verschiedene Grooves und Techniken mit steigendem Schwierigkeitsgrad**, die
  man lernen und üben kann; **Techniken und Spielweisen (Möller usw.)**; **alle
  möglichen Techniken und Groove-Vokabular**. „Wenn es erst zu schwer ist, dann
  langsam.“ **Hand, Fuß, Koordination und Independence** sollen trainiert werden.
- Ablauf einer Einheit: **erst aufwärmen, dann einen Bereich vertiefen**. Am Anfang
  Übungen, die **Bewegungsabläufe instinktiv** werden lassen, dann immer mehr Technik
  und Vokabular. **Gerne an reale Musikstücke angelehnt**: Groove mit Songnamen reicht;
  **Mitspielen zum echten Song später über Import, den Import aber auf jeden Fall
  planen.**
- Reihenfolge (bestätigt 29.10.): **erst die Ansicht, dann der Trainingsraum, dann der
  Import.**

Vorgaben, die weiter gelten: nur die **Linux-Desktop-Version** bauen und testen
(seit 23.10.; auf PC/GPU-Box oder Laptop selbst bauen, keine APK); **UI-Texte
Englisch**; Klänge und Lizenzen wie in Optik-Runde 2.

---

## Teil 1 — Neue Übungsansicht (Entwurf A)

### 1.1 Ist-Zustand (Branch `spec-gefuehrte-uebungen`, 99f08d7)

- Geführte Übungen: Vorschau `/guided/:id` (`guided_preview_screen.dart`) und
  Spielbildschirm (`guided_play_screen.dart`). 8 Übungen im Katalog
  (`guided_catalog.dart`, erzeugt von `tool/katalog/gefuehrt.py`): je Paket (Set, Pad)
  eine pro Stufe beginner/intermediate/advanced/professional.
- Hintergrund: `GuidedBackdrop` legt ein **Hochformat-Foto** (1080×1890, 37 Stück in
  `assets/illustrations/practice/`) mit `BoxFit.cover` übers ganze Fenster. Auf
  2560×1440 bleibt davon nur ein schmaler Querstreifen; Karten und Noten liegen
  darüber. Daher „überdeckt und abgeschnitten“.
- Noten: `GuidedLineView` zeichnet eine Zeile über den `LineView` des Übungsbildschirms
  (der einzige Notenweg der App). Laufanzeige als dünne Linie (Optik-Runde 2).
- Modell: `GuidedSection` = eine `ExerciseLine` × `bars`. **Eine Zeile darf schon mehrere
  Takte lang sein** (`lineTickFor` kennt das), der Katalog nutzt aber nur Zeilen von
  **einem Takt**, die 8- oder 16-mal wiederholt werden. Daher „zu wenig Inhalt“.

### 1.2 Ziel, Nicht-Ziele, Anti-Ziele

**Ziel.** Vorschau und Spielbildschirm der geführten Übungen sehen aus wie Entwurf A:
oben eine Bühne mit dem ganzen Foto, darunter ein weißes Notenblatt über die volle
Fensterbreite mit ausgeschriebenen Takten, unten eine Steuerleiste. Die 8 vorhandenen
Übungen bekommen ausgeschriebene Zeilen mit vier unterschiedlichen Takten.

**Nicht-Ziele.**
- Neue Übungen, neue Bereiche, Lehrplan (→ Teil 2).
- Video statt Foto. Uli verfolgt die Video-Versuche in einer eigenen Sitzung. Die Bühne
  soll aber so gebaut sein, dass dort später ein Video laufen kann (siehe 1.3).
- Andere Bildschirme (Bibliothek, Heute, normale Übungen) umbauen.
- Handy-Layout neu gestalten. Es darf nur nicht brechen.

**Anti-Ziele.**
- Das Foto ist wieder beschnitten oder verdeckt.
- Die Noten sind auf einem Laptop-Bildschirm (1366×768 / 1920×1080) zu klein zum
  Mitlesen.
- Die Zeile springt so, dass man beim Spielen die Stelle verliert.
- Das Notenblatt wirkt wie Karteikarten (Rahmen, Schatten, abgerundete Kärtchen je Takt).

### 1.3 Entwurf

**Aufteilung des Fensters (breites Layout, `guidedWide`).**

| Bereich | Höhe (Richtwert) | Inhalt |
|---|---|---|
| Bühne | ~55 % | Foto, Titel, Lehrer-Banner, Countdown |
| Notenblatt | ~38 % | weiß, zwei Zeilen à vier Takte |
| Steuerleiste | ~7 % | dunkel, Wiedergabe, Zeitstrahl, Tempo, Schalter |

Die Höhen sind Richtwerte. Feste Regel: Das Notenblatt bekommt so viel Höhe, dass zwei
Zeilen bei 1920×1080 mit einer Notenlinienhöhe von mindestens ~60 px passen. Den Rest
bekommt die Bühne.

**Bühne.**
- Hintergrund der Bühne: dieselbe Fotodatei, weichgezeichnet und abgedunkelt, füllt die
  ganze Bühnenbreite (wie Entwurf A).
- Davor das Foto selbst, **breiter als in Entwurf A** (Ulis Wunsch): Ausschnitt mit
  Seitenverhältnis **4:3**, in voller Bühnenhöhe, mittig. Oben und unten wird dafür ein
  Stück abgeschnitten. Der Ausschnitt ist so ausgerichtet, dass Person und Schlagzeug
  ganz drin bleiben. *(Meine Wahl: 4:3 ist bei den Hochformat-Fotos die breiteste Form,
  bei der noch Kopf und Trommeln im Bild bleiben. Uli prüft das am Gerät.)* Weil die
  Motive verschieden sitzen, bekommt jedes Foto einen Ausrichtungswert (vertikal,
  Standard etwas über der Mitte). Die Werte stehen in einer Tabelle neben `backdrop.dart`
  und werden einmal per Kontaktbogen geprüft.
- Kein dunkler Schleier über dem eigentlichen Foto. Lesbarkeit der Texte kommt aus einem
  Verlauf nur am oberen Rand und aus der dunklen Unschärfe links und rechts.
- Oben links: Paket · Stufe (Kleinschrift, Akzentfarbe), Name der Übung, aktueller
  Abschnitt mit Kurztext. Oben rechts: „Bar 3 / 8“ und darunter „Coming up: …“ (nächste
  Variation).
- Das Lehrer-Banner (`GuidedBanner`) und der Countdown vor Wechseln stehen in der
  Bühne unten mittig, über dem Foto, ohne das Gesicht zu verdecken.
- Die Bühne ist ein eigenes Widget mit einer Stelle für den Inhalt (heute Foto). Ein
  späteres Video kann es ersetzen, ohne dass Notenblatt oder Steuerleiste sich ändern.

**Notenblatt.**
- Weiße Fläche (`#FFFFFF`), schwarze Noten, volle Fensterbreite mit dem üblichen Gutter.
  Keine Karten, keine Rahmen pro Takt.
- **Oben die aktuelle Zeile, darunter die nächste**, jede mit einer kleinen Beschriftung
  darüber: „Now · Variation 2“ und „Next · Groove“ (bzw. „Next · Variation 3“). Die
  untere Zeile ist blass (wie Entwurf A).
- **Eine Zeile zeigt vier Takte** des Ablaufs, so wie sie gespielt werden. Bei einer
  ausgeschriebenen Zeile von vier Takten sind das die vier unterschiedlichen Takte; bei
  einer kürzeren Zeile wird sie wiederholt ausgeschrieben, nie als Wiederholungszeichen.
  Liegt ein Abschnittswechsel innerhalb der nächsten vier Takte, zeigt die untere Zeile
  den neuen Abschnitt ab seinem Beginn.
- **Seiten gehören zu einem Abschnitt.** Weil alle Abschnitte (außer dem Outro) ganze
  Vier-Takt-Phrasen sind (siehe 1.4), ist jede Seite genau eine Phrase. Das Outro (1 Takt)
  ist eine kurze letzte Seite: ein Takt in normaler Taktbreite, links bündig. Während des
  Einzähltakts zeigt die obere Zeile schon die erste Seite des Grooves, der Laufstrich
  steht noch am Anfang.
- **Seitenweise weiter wie bei Drumeo.** Der Laufstrich wandert über die vier Takte der
  oberen Zeile. Mit dem ersten Schlag des fünften Taktes rückt die untere Zeile nach
  oben, und darunter erscheint die nächste. Kein Scrollen, keine Animation, die das Auge
  ablenkt (höchstens ein kurzes Überblenden ≤ 150 ms).
- Laufstrich: senkrechte Linie über die volle Notenhöhe, **blau und halbtransparent wie
  im Entwurf**. *(Meine Wahl: Auf Weiß ist das Orange der App schlechter vom roten
  Akzent-Zeichen zu unterscheiden, und Uli hat den Entwurf mit Blau gewählt.)* Keine
  Notenfärbung.
- Pad-Übungen: dieselbe Fläche, einzeilige Pad-Notation mit Sticking (R/L) unter den
  Noten, wie heute.
- Takte gleich breit verteilt über die volle Zeilenbreite (`fillWidth`). Notenhöhe
  skaliert mit der Fenstergröße, Untergrenze siehe oben.

**Steuerleiste.**
- Dunkel, über die volle Breite: Wiedergabe/Pause, verstrichene Zeit, Zeitstrahl mit den
  Abschnitten (Groove und Variationen farblich getrennt, gespielte Abschnitte kräftig),
  Gesamtzeit, Tempo (♩ = …, mit den bekannten Tasten änderbar), Teacher an/aus,
  Play along an/aus.
- Das sind die bisherigen Bedienelemente (`GuidedTimelineBar`, Tempo-Zeile,
  `_ToggleChip`), nur neu angeordnet. Tastenkürzel bleiben.

**Vorschau (`/guided/:id`).**
- Gleiche Aufteilung: Bühne oben mit Foto, Name, Beschreibung, Dauer, Stufe, Tempo-Wahl,
  Teacher/Play-along-Schaltern und der Start-Schaltfläche.
- Das Notenblatt darunter zeigt die **ganze Übung als Notenblatt**: Groove und jede
  Variation einmal, jede als Zeile mit ihren (bis zu) vier Takten und einer Beschriftung
  („Groove · 8 bars“, „Variation 1 · Kick on the 16ths · 8 bars“). Bei vielen Variationen
  scrollt das Notenblatt in sich, die Bühne bleibt stehen.
- Das Ende-Fenster (`_EndView`) bekommt keinen Umbau, nur die neue Bühne als Hintergrund.

**Schmales Layout (< 1000 px).** Bleibt im Kern wie heute. Die Bühne wird ein
Foto-Streifen oben, darunter dieselben zwei Notenzeilen mit je **zwei** Takten. Es reicht,
dass nichts bricht; die bestehenden 412×915-Tests laufen weiter.

### 1.4 Inhalte: die 8 Übungen ausgeschrieben

*(Meine Wahl, damit die neue Ansicht nicht leer wirkt; der große Inhaltsumbau ist
Teil 2.)*
- Jede Groove- und Variationszeile der 8 Übungen wird im Katalog-Werkzeug
  (`tool/katalog/gefuehrt.py`) zu einer **Zeile von vier Takten**: Takt 1 bis 3 die
  bisherige Figur bzw. eine verwandte Abwandlung, Takt 4 mit einer kleinen Steigerung
  (zusätzliche Bassdrum, Ghost Note, Akzentverschiebung, kurzer Fill-Ansatz).
- **Abschnittslängen werden Vielfache von vier Takten.** Heute sind Variationen 18, 20
  oder 24 Takte lang, Grooves teils 10 oder 12, das Outro 1 Takt. Groove und Variation
  werden in `gefuehrt.py` auf das nächste Vielfache von 4 gerundet (z. B. 18 → 20,
  10 → 12). Die Gesamtdauer bleibt ungefähr bei 5 Minuten (±10 %). Das Outro bleibt
  1 Takt. *(Meine Wahl.)*
- **Verlängerung für die Ansage nur in ganzen Vier-Takt-Phrasen.** `buildRun` verlängert
  heute einen Groove vor einer Variation um so viele Einzeltakte, wie die Ansage braucht
  (abhängig vom Tempo, am Abschnittsanfang). Neu: um ganze Vier-Takt-Phrasen. So bleibt
  jede Seite eine ganze Phrase, und der Steigerungstakt (Takt 4) liegt immer direkt vor
  dem Seitenwechsel bzw. dem Abschnittswechsel. Seiten zählen ab Abschnittsbeginn
  (`barInSection`), wie heute. *(Meine Wahl.)*
- **Kurzname je Variation.** Für „Now · Variation 2 · …“, „Coming up: …“ und die
  Vorschau bekommt jede Variation ein neues Katalogfeld `titleEn` (2–5 Wörter, z. B.
  „Kick on the 16ths“). Es wird zusammen mit den Zeilen kuratiert. Generator, Modell
  (`GuidedSection`) und Kurationsseite bekommen das Feld. *(Meine Wahl.)*
- Stufe und Charakter jeder Übung bleiben. Ansage-Texte (`textEn`) und Sprachclips
  werden nur angepasst, wenn die Variation sich inhaltlich ändert. Neue Clips werden mit
  dem bestehenden Stimm-Werkzeug erzeugt.
- Die Kuration läuft wie bei Plan 2 über eine Kurationsseite, auf der Uli die Zeilen
  ansieht und abnickt, bevor sie in den Katalog gehen.

### 1.5 Abnahme

- Uli am PC (Fenster 2560×1440) und, wenn erreichbar, am Laptop. Linux-Bundle auf der
  jeweiligen Maschine bauen.
- Prüfpunkte: Foto ganz zu sehen, 4:3-Ausschnitt mit Person und Schlagzeug; Noten
  über die volle Breite; vier Takte pro Zeile, keine Wiederholungszeichen; Zeilenwechsel
  ohne Stelle-Verlieren; Laufstrich synchron, auch nach Tempowechsel; bei 1920×1080
  noch gut lesbar; Handy-Größe bricht nicht.
- Goldens bei 2560×1440, 1920×1080 und 412×915 neu erzeugen und ansehen.

---

## Teil 2 — Trainingsraum (Richtung, eigenes Dokument folgt)

**Was es ist.** Kein Kurs zum Durchklicken, sondern ein Trainingsraum: Jede Technik
und jeder Groove ist eine Übung, die man **in jedem Tempo** übt, langsam beginnend, bis
sie im Zieltempo sitzt. Zu schwer heißt langsamer, nicht überspringen.

**Bereiche, je mit steigenden Stufen** *(Einteilung mein Vorschlag, im eigenen Dokument
mit Uli festzulegen)*:
- **Hände, Technik und Spielweisen:** Möller, Free Stroke, Doppelschläge, Rudiments,
  Akzente, Ghost Notes.
- **Füße:** Heel-up und Heel-down, Doppelschläge mit dem Fuß, Hi-Hat-Fuß.
- **Koordination und Independence:** Ostinato in einer Hand oder einem Fuß, die anderen
  variieren dazu.
- **Groove-Vokabular:** Rock, Funk, Shuffle, Halftime, 6/8 und 12/8, Latin und weitere,
  je von einfach bis verziert. Grooves dürfen nach realen Songs benannt sein (nur der
  Groove als Noten, keine Aufnahmen).
- **Fills und Übergänge.**

**Einheit.** Erst **Aufwärmen** (wenige Minuten, Hände und Füße), dann **einen
Bereich vertiefen**. Der Bereich wird vorgeschlagen und ist frei wählbar.

**Lernweg.** Für Anfänger zuerst Grundübungen, bis die Bewegungen von allein laufen,
dann zunehmend Technik und Vokabular. Anspruch nach oben deutlich über Drumeo-Method-
Niveau (die Method endet etwa bei Mittelstufe).

**Umfang.** Deutlich kleiner als Drumeo (dort ~400 Lektionen), aber breit: eine
Handvoll Übungen je Bereich und Stufe, vollständig verfügbar, nichts wird freigeschaltet.

**Im eigenen Dokument zu klären:** genaue Bereiche und Stufen; wie Tempo-Stufen und
„sitzt“ gemessen werden (Pad über Mikrofon, Set über MIDI aus Etappe 2); Verhältnis zu
den bestehenden Formen (geführte Übungen, Katalog-Blätter Rudiments/Fills aus
PR #30/#32, Heute-Bildschirm, adaptives Programm); wie Techniken wie Möller erklärt
werden (Text, Stimme, später vielleicht Video); Startumfang.

---

## Teil 3 — Song-Import (Richtung, eigenes Dokument folgt)

**Was es ist.** Eigene Songs zum Mitspielen: Uli gibt eine Audiodatei aus seiner
Sammlung, die GPU-Box trennt das Schlagzeug ab (Demucs) und schreibt es in Noten
(ADTOF). Beides ist auf der GPU-Box schon erprobt. Daraus wird eine Übung, die zum
echten Song läuft, auch verlangsamt.

**Im eigenen Dokument zu klären:** Ausschnitt wählen (Teil eines Songs als Übung);
variables Tempo von Song und Übung; Korrektur der automatisch erkannten Noten; wo die
Audiodatei liegt (nur lokal, keine Weitergabe); Ablauf zwischen App und GPU-Box.
