# Brief: Erweiterung Drum Coach zu Notation, Übungsgenerator und Song-Sync

> **An Claude Code:** Dies ist ein Auftrags-Brief, kein Implementierungsplan.
> Bevor du irgendetwas schreibst, führe **Phase 0** aus und lege mir das Ergebnis vor.
> Nichts löschen, nichts umbenennen, keine Migration starten, bevor Phase 0 abgenommen ist.

---

## Phase 0 — Bestandsaufnahme (zuerst, ohne Code)

Untersuche die Repo und liefere mir ein Dokument `docs/AUDIT.md` mit:

1. **Was existiert bereits?** Verzeichnisstruktur, Architektur-Schichten, State-Management, Persistenz, Sync-Pfad, Testabdeckung.
2. **Welches Datenmodell gibt es heute für Übungen?** Wie werden Übungen gespeichert, kategorisiert, geplant?
3. **Existiert bereits eine Wiederholungs-/Lernlogik** (SM-2, Leitner, Gates, Streaks)? Wo hängt sie, wovon hängt sie ab?
4. **Welche Plattformen sind heute gebaut?** Was fehlt für Android / iOS / Desktop?
5. **Welche Teile kollidieren mit dem Zielbild unten?** Konkret benennen, mit Datei-Pfaden.
6. **Migrationsvorschlag**: Was bleibt, was wird erweitert, was wird ersetzt. Mit Reihenfolge und Risiko pro Schritt.

Erst nach meiner Freigabe von `docs/AUDIT.md` fängst du an zu bauen.

---

## Das Zielbild in einem Satz

Eine Drum-Coach-App auf **Android, iOS und Desktop**, in der **jede** Übung und jeder Song als **Notenzeile** dargestellt wird — Übungen für das Practice Pad unterwegs, Übungen am Set zuhause, und echte Songs sowohl synthetisch abgespielt als auch synchron zu echtem Audio/Video.

---

## Grundprinzip (nicht verhandelbar)

**Die App synthetisiert aus Notation, sie streamt kein Audio.**

Wiedergabe entsteht aus einem Score-Modell plus Klangerzeugung. Dadurch sind Tempoänderung, Loop, Einzelspur-Stummschaltung, Count-in und Ausschnitts-Extraktion trivial — kein Time-Stretching, keine Artefakte, keine Audio-Lizenzfragen.

Echtes Audio/Video ist ein **zweites, getrenntes System** (siehe Abschnitt „Song-Sync"). Es darf den synthetischen Pfad nicht infizieren. Der Pad-Modus kennt echtes Audio überhaupt nicht.

---

## Datenmodell

### Ein Übungstyp, drei Herkünfte

```
Exercise
  id
  source: generated | authored | excerpt
  tags: [...]            // mehrachsig, siehe unten
  voicing: pad | kit     // Darstellungsmodus
  ...Lernmetadaten (bestehende SM-2/Gate-Logik hängt hier)
```

- `generated` — parametrisch erzeugt (Rudiment, Sticking, Groove, Fill, Koordinationsübung)
- `authored` — von Hand notiert (stilistisch echte Grooves, Solo-Phrasen, alles mit Gefühl)
- `excerpt` — Verweis auf einen importierten Score

**Kritisch:** Die Lernlogik (Planung, Wiederholung, Fortschritt) hängt am `Exercise` und ist von der Herkunft unabhängig. Nicht drei parallele Systeme bauen.

### Excerpt ist ein Zeiger, keine Kopie

```
Excerpt
  score_id
  bar_from, bar_to
  track_index
```

Ein Ausschnitt aus einem Song kopiert keine Noten heraus — er verweist. Wie ein Lesezeichen. Damit bleibt die Rechtefrage beim importierten Score, und Änderungen am Score schlagen durch.

### Tags sind Achsen, keine Ordner

Kein Kategorienbaum. Ein Linear-Fill trainiert gleichzeitig Fill, Koordination und Weak Hand — in einem Baum läge er immer falsch.

Achsen mindestens:

- **Skill**: Groove, Fill, Koordination, Ausdauer, Kontrolle, Independence
- **Genre**: Rock, Funk, Jazz, Latin, Metal, Drum Corps, …
- **Subdivision**: 8tel, Triolen, 16tel, 16tel-Triolen, 32tel
- **Gliedmaßen**: Hände, Füße, Doublebass, alle vier
- **Tempo-Zone**: Kontrolle / Arbeitstempo / Chops
- **Modus-Eignung**: pad-tauglich, set-erforderlich

Die Lernlogik soll aus den Achsen Lücken ableiten können („linke Hand seit drei Wochen nicht bedient").

---

## Übungen: generieren statt katalogisieren

Der größte Hebel des ganzen Projekts. Statt hunderte Notendateien als Assets: eine **Grammatik**, aus der die App Notenbild und Klick zur Laufzeit baut.

### Sticking-Grammatik (Fundament)

Eine Übung wird beschrieben durch: Sticking-Folge (`RLRR LRLL`), Subdivision, Akzentmaske, Länge, Tempo-Vorgabe.

Daraus generiert sich:

- **Rudiments** — alle PAS-Rudiments als Parametersätze, nicht als Assets
- **Sticking-Pattern & Permutationen** — Paradiddle-Varianten, Rotationen, Akzentverschiebungen
- **Ausdauerübungen** — dieselbe Folge über Zeit/Taktzahl mit Tempo-Ramp
- **Drum-Corps-Material** — Rudiment-Ketten, Akzent-Tap-Kombinationen

### Füße nutzen dieselbe Grammatik

`RLRR` ist zunächst nur eine Abfolge. Ob Hände oder Füße ist eine **Zuweisung**, keine eigene Engine. Bassdrum-Kontrolle, Doublebass-Singles, Heel-Toe unterscheiden sich in der Notation nicht — nur im Hinweistext und in der Kit-Zuordnung.

### Grooves = Instrumentierungsregel über ein Raster

Ein Genre ist keine Sammlung von Dateien, sondern ein Parametersatz: was liegt auf der Hi-Hat/Ride, wo sitzt die Snare, welches Bassdrum-Muster, welches Feel (gerade/Shuffle). Rock, Funk, Bossa, Songo, Punk sind dieselbe Maschine mit anderen Werten.

### Fills = Rudiment + Orchestrierung

Ein Sticking über Snare/Tom1/Tom2/Floor/Becken verteilt ergibt aus **einem** Baustein dutzende Fills. Die Orchestrierungsregel ist ein eigener, wiederverwendbarer Parameter.

### Koordination = zwei Stimmen übereinander

Ostinato in den Füßen, Pattern in den Händen, gegeneinander verschiebbar. Kombinatorik statt Katalog.

### Was von Hand notiert wird

Stilistisch charakteristische Grooves, Solo-Phrasen, alles wo Gefühl drinsteckt. Bewusst wenig.

---

## Modi statt Kategorien

Diese Dinge sind **keine** Übungsarten, sondern Schalter auf beliebige bestehende Übungen. Als Modi gebaut verdoppeln sie den Bestand ohne neuen Inhalt.

- **Speed / Tempo-Trainer** — Ramp über eine beliebige Übung. Zieht hoch bis Fehlergrenze, merkt sich die erreichte Grenze pro Übung und schreibt sie in die Lernhistorie.
- **Weak Hand / Left-Hand Lead** — Sticking gespiegelt. Kein neuer Inhalt, ein Schalter.
- **Chops** — keine Kategorie, sondern eine Tempo-Zone. Dieselbe Übung bei 60 ist Kontrolle, bei 160 ist sie Chops.
- **Loop** — Taktbereich beliebig eingrenzbar, in jedem Modus.
- **Count-in / Metronom / Klick-Subdivision** — global.

---

## Zwei Darstellungsmodi: Pad und Kit

Dieselbe Übung, zwei Renderer. Unterschied liegt in `voicing`, nicht in der Logik.

- **Pad-Modus (unterwegs)** — einzeilige Notation, nur Sticking, Akzente und Subdivision. Klick statt Kit-Sound. Muss **vollständig offline** funktionieren und akkuschonend sein. Kein Song-Sync, kein Video.
- **Kit-Modus (zuhause)** — volle Kit-Notation mit Instrumentenzuordnung, synthetische Wiedergabe mit Drum-Sounds, Einzelspur-Steuerung, Songs.

---

## Notation & Wiedergabe: technische Richtung

**Vorschlag: alphaTab** (Open Source, MPL) — rendert und spielt Guitar-Pro-Formate (gp3–gp7) und MusicXML, bringt Synth, Taktbereich-Loop, Tempofaktor und Track-Steuerung mit.

**Deine Aufgabe in Phase 0:** Prüfe den **aktuellen** Stand der Integrationsmöglichkeiten für unser Framework. Bewerte:

1. Natives/gebundenes Modul, falls verfügbar und ausgereift
2. Fallback: Web-Variante in einem WebView hinter einer schmalen Bridge
3. Alternativen, falls sich beides als untragbar erweist

**Architektur-Anforderung:** Der Renderer/Player sitzt hinter einem **eigenen Interface**. Die Kernlogik (Übungsmodell, Generator, Lernlogik) darf ihn nicht kennen. Wenn wir die Rendering-Technologie später tauschen, ist das ein isolierter Umbau — kein Durchgriff in den Kern.

Der **Generator** erzeugt ein neutrales internes Score-Modell. Erst der Renderer übersetzt in das Format der gewählten Engine.

---

## Song-Import

- Songs kommen **ausschließlich aus dem Import des Nutzers** (eigene Guitar-Pro-/MusicXML-Dateien)
- **Kein mitgelieferter Katalog.** Keine Score-Dateien im Repo, in Assets oder auf unseren Servern
- **Keine Weitergabe von Score-Dateien über den Sync-Pfad.** Scores bleiben lokal auf dem Gerät des Nutzers
- Import-UI: Datei wählen, Tracks anzeigen, Drum-Track identifizieren, Metadaten erfassen

---

## Song-Sync mit echtem Audio/Video

Ein **getrenntes** System. Der Score bleibt die metrische Wahrheit; das Medium ist eine zweite Zeitachse, die über Ankerpunkte drangeklebt wird.

### SyncMap

```
SyncMap
  score_id
  media_ref          // YouTube-ID oder lokaler Dateipfad
  anchors: [{ bar, ms }, ...]
```

- **Ankerliste, nicht ein einzelner Offset + BPM.** Echte Aufnahmen driften; ein linearer Fit über den ganzen Song bricht auseinander.
- Zwischen Ankern linear interpolieren — reicht für Drums weit.
- **Erzeugung durch Tap-Along**: Nutzer hört den Song und tippt auf jede Takt-Eins, die App snapt auf die nächste Taktgrenze. Anker müssen nachträglich einzeln korrigierbar/verschiebbar sein.
- Die SyncMap ist **Nutzerdaten** — sync- und teilbar, ohne dass Audio unsere Infrastruktur berührt.

### Zwei Medienquellen

- **YouTube** — ausschließlich über den offiziellen eingebetteten Player. `playbackRate` (0.25–2.0, tonhöhenkorrekt) und `seekTo` für Loops. **Kein Audio-Extract, kein Download, kein lokales Cachen des Streams — auch nicht „nur temporär".** Loop ist hier nicht lückenlos; Rebuffer-Latenz einplanen und in der UI ehrlich machen.
- **Lokale Datei des Nutzers** — bevorzugt, passt zur Offline-Philosophie. Plattform-Player mit tonhöhenerhaltendem Time-Stretching. Nur der Pfad wird gespeichert, nie die Datei kopiert.

### Der eigentliche Gewinn

Aus `SyncMap + bar_from/bar_to` fällt die **Ausschnitts-Extraktion auf dem echten Song** heraus: vier Takte Fill, geloopt, mit Original-Audio, bei 70 % Tempo — und als vollwertige Übung mit Lernhistorie im System. Das ist der Punkt, an dem wir mehr können als ein reiner Player: bei uns ist ein Loop eine Übungseinheit mit Fortschritt, nicht nur ein Abspielbereich.

---

## Plattformen

- **Android und iOS** — Kernplattformen, Pad-Modus muss auf dem Handy unterwegs vollständig offline laufen
- **Desktop** (Windows/macOS/Linux) — für den Kit-Modus zuhause: größere Notendarstellung, Song-Arbeit, Sync-Erstellung
- Gemeinsame Kernlogik. Plattformunterschiede nur in Rendering, Audio-Ausgabe und Medien-Player.

---

## Rechtliche Leitplanken

Diese Punkte sind bewusst gesetzt und sollen so bleiben:

1. Kein mitgelieferter Song-/Score-Katalog, kein Score-Sharing über unsere Server
2. Keine Umgehung fremder Bezahlschranken, kein Scraping fremder Dienste
3. Kein Extrahieren, Herunterladen oder Zwischenspeichern von Streaming-Audio
4. Die klassischen Method Books (Stick Control, Syncopation, Bass Drum Control u. a.) sind geschützt. Das **Prinzip** nachzubauen ist frei, die konkreten Übungsfolgen abzuschreiben nicht. Da wir generieren, ist das kein Konflikt — es soll bewusst so bleiben. Keine abgetippten Seitenfolgen aus solchen Büchern als Assets.

---

## Reihenfolge des Umbaus (Vorschlag, in Phase 0 zu schärfen)

1. `docs/AUDIT.md` — Bestandsaufnahme, Migrationsplan **← Abnahme durch mich**
2. Datenmodell vereinheitlichen: ein `Exercise`-Typ, Tag-Achsen, bestehende Lernlogik anschließen
3. Notation-Interface + Renderer-Anbindung, zunächst nur Anzeige
4. Sticking-Generator + Pad-Modus (kleinster vollständiger Wertkreis, offline)
5. Wiedergabe, Loop, Tempo, Count-in im synthetischen Pfad
6. Kit-Modus: Grooves, Fill-Orchestrierung, Koordination
7. Modi: Speed-Ramp, Weak Hand
8. Song-Import + Excerpt-Zeiger
9. SyncMap: Tap-Along-Editor, YouTube-Embed, lokale Datei
10. Sync/Backup der Nutzerdaten (Übungen, Fortschritt, SyncMaps — **keine Scores**)

Jeder Schritt einzeln lauffähig und abnehmbar. Keine mehrwöchige Baustelle ohne funktionierenden Zwischenstand.

---

## Was ich von dir erwarte

- **Erst fragen, dann bauen**, wenn etwas im Bestand dem Zielbild widerspricht
- Bestehenden Code respektieren: erweitern statt neu schreiben, wo möglich — und begründen, wo nicht
- Bei jeder Design-Entscheidung, die Zeiger vs. Kopie, Generator vs. Asset, oder Modus vs. Kategorie betrifft: im Zweifel die Variante aus diesem Brief, oder Rückfrage
- Keine stillen Abhängigkeiten auf schwergewichtige Bibliotheken ohne Rückfrage

**Nächster Schritt: `docs/AUDIT.md`.**
