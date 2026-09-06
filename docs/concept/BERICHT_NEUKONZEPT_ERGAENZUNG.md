> **Status: Konzept. Kein Arbeitsauftrag.** Aktive Etappe siehe `docs/BRIEF_ETAPPE1_PAD.md`.

# Drum-Coach: Ergänzung zum Standort-Bericht

**Datum:** 05.09.2026 · **Stand:** nach Teil 1 der Konzept-Session (Fassung 2)
**Bezug:** `BERICHT_NEUKONZEPT.md` und `BRIEF_SONG_UEBUNGEN.md` — dieses Dokument
ergänzt und korrigiert beide, ersetzt sie nicht.

Ergebnis von Teil 1: Der Bericht beschreibt die Symptome zutreffend, aber die
Ursache liegt tiefer als seine vier Kernkritikpunkte. Es sind mehrere Themen
aufgetaucht, die dort nicht vorkommen — vor allem eine Positionierung, die den
Unterschied zum Wettbewerb erklärt, und ein Messproblem, das die Grundlage der
ganzen Idee betrifft.

**Noch offen:** Assessment-Entwurf, Content-Strategie, UI-Leitplanken (Abschnitt 9).

---

## 1. Positionierung

> **Alle anderen beantworten „was gibt es?". Diese App beantwortet „was mache ich jetzt?"**

Der Auslöser ist ein Befund aus der eigenen Drumeo-Nutzung: gut, aber zu viel —
man weiß nicht mehr, wo man anfangen soll. Der Method-Pfad ist Drumeos Antwort
darauf und funktioniert, bleibt aber ein für alle gleicher Weg. Er weiß nicht,
wo jemand steht, und vor allem nicht, wo jemand gerade *ist*. Auf „ich bin
unterwegs und habe nur ein Pad" kann keine dieser Plattformen antworten.

**Marktbeobachtung (Sept. 2026):** Drumeo hat Method und App überarbeitet.
Nutzerkritik in öffentlichen Bewertungen: neue Method schlechter als die alte
(die weiterhin im Legacy-Bereich steht), App fehleranfällig, Fortschritts-
verfolgung mangelhaft. Das Zuviel-Problem ist also real, ungelöst, und der
Marktführer hat beim Lösungsversuch Bestandskunden verärgert.

**Strukturell kann eine Videoplattform es nicht lösen.** Fortschritt bedeutet
dort abgehakte Videos und XP — das misst Konsum, nicht Können. Video weiß nicht,
was gespielt wird. Musora legt dieselbe Struktur über fünf Instrumente; ein
messwertbasierter Pfad passt nicht in dieses Modell.

**Folgerungen:**
- Nicht auf Umfang zielen. Videoproduktion, Star-Lehrer, riesige Songbibliothek
  sind deren Stärke, teuer erkauft und kein Wettbewerbsfeld.
- Der Startbildschirm ist kein Menü (Programm · Sammlungen · Routine), sondern
  **eine einzige Antwort**: eine Übung, ein Tempo, eine Dauer, plus ein Satz,
  warum ausgerechnet das jetzt dran ist. Stöbern liegt dahinter.
- Damit ist Bericht-Frage 6 beantwortet: Programm und Routine verschmelzen zu
  einer Reise, deren heutige Gestalt sich aus dem Kontext ergibt.

**Prüfsteine für die Kommerzialisierungs-Entscheidung** (Kommerzialisierung
bleibt offen — abhängig davon, ob ein konkurrenzfähiges Produkt entsteht):
1. **Verlässlichkeit der Messung.** Die gesamte Positionierung steht darauf.
   Weiche Zahlen ⇒ wieder nur eine Übungsliste mit hübscheren Diagrammen.
2. **Erkenntniswert.** Sagt die App nach einer Woche etwas über das eigene
   Spiel, das man nicht wusste?

---

## 2. Beispielnutzer (nicht das Produktmodell)

Der Auftraggeber ist der erste Nutzer, aber **keine Mechanik wird auf ihn
zugeschnitten**. Sein Profil dient als Testfall und als Herkunft der Beispiele:

| | |
|---|---|
| Level | Länger dabei, Technik nie sauber gelernt → Anfänger-Fundamente, keine Anfänger-Inhalte |
| Zeit/Tag | Schwankt stark |
| Equipment | Practice-Pad (unterwegs) + E-Drums (zuhause), gleich gewichtet |
| Ziele | 1. Songs am Set · 2. Schneller · 3. Vokabular · 4. Sauberer |

E-Drum-Setups: MegaDrum → PC (MOTU M2) → Superior Drummer; **und** MegaDrum →
Laptop, beides über Kopfhörer gemischt. Letzteres ist für das Konzept maßgeblich,
weil es der allgemeinere Fall ist.

**Verallgemeinerbare Einsicht aus diesem Profil (Regel fürs Produkt):**
Selbstauskunft zum Können ist unzuverlässig. Derselbe Nutzer sagt „Technik nie
sauber gelernt" und setzt Sauberkeit auf Platz 4. Beides stimmt — aber ein
Programm, das nur der Rangfolge folgt, überspringt das Nadelöhr.

---

## 3. Drei Eingänge: fragen, messen, erkennen

> **Nie fragen, was man messen kann. Nie messen wollen, was man fragen muss.**

| Eingang | Herkunft | steuert |
|---|---|---|
| **Ziel** | einmal gefragt | Gewichtung und Reihenfolge der Gates |
| **Können** | fortlaufend gemessen | was als Nächstes dran ist |
| **Kontext** | erkannt oder per Tipp gesetzt | Form der heutigen Einheit |

**Ziel** ist nicht messbar — ob jemand Metal nachspielen oder für ein Vorspiel
sauber werden will, steht in keinem Mikrofonsignal. Auswahl beim Onboarding:
Songs am Set · Technik/Rudiments sauber · schneller werden · Wiedereinstieg.
Das steuert nicht, *ob* eine Fähigkeit trainiert wird, sondern Gewichtung und
Route. Gleiches Modell, andere Reihenfolge.

**Kontext** ist der eigentliche Unterschied zum Wettbewerb: Welches Gerät, hängt
MIDI an, wie viel Zeit heute. Das meiste sieht die App selbst. Gleicher
Fortschritt, unterschiedliche Form — unterwegs am Pad wird die Hand-Balance
geschliffen, die für ein Groove-Gate fehlt; zuhause am Set wird das Gate abgelegt.

---

## 4. Onboarding und eingebettetes Assessment

**Kein Prüfungsblock beim ersten Start.** Bericht-Frage 4 schlägt 3–5 Messaufgaben
am Anfang vor. Dagegen sprechen drei Dinge: schlechter erster Eindruck; die
Messwerte sind die schlechtesten, die je entstehen (Nervosität, unvertraute
Mikrofonposition, kalt); und Können ist keine Momentaufnahme.

**Stattdessen:** Die ersten Sitzungen sind echtes Üben, das nebenbei misst. Die
App wählt Material, das bestimmte Fähigkeiten offenlegt, sagt aber nicht „Test".
Nach etwa einer Woche steht das Profil — erst dann benennt die App das erste
Gate. Das ist auch die ehrlichere Reihenfolge: „von deinem Stand nach Y" kann
man erst versprechen, wenn man den Stand kennt.

**Onboarding-Fragen (unter einer Minute):** Ziel · Equipment/Sensorstufe
(idealerweise erkennt die App angeschlossenes MIDI selbst) · Zeitbudget grob.
Level wird gefragt, aber nur als Saatwert für die erste Übung — die erste Messung
überschreibt ihn, und die App behandelt ihn auch so.

**Zwei Mechaniken daraus:**
- **Sicherheit pro Fähigkeit.** Jeder Wert trägt mit, wie oft und wie streuend
  gemessen wurde. Bei niedriger Sicherheit sucht die App weiter Gelegenheiten.
  Damit ist Bericht-Frage 5 beantwortet: keine Wochenprüfung nötig — gemessen
  wird ständig, ein ausdrücklicher Prüfmoment entsteht nur, wo ein Gate einen
  Nachweis verlangt.
- **Abgleich Selbstbild ↔ Messung.** Wenn sich jemand als fortgeschritten
  einstuft und die Messung zeigt eine Schieflage, ist das der wertvollste Moment
  der ersten Woche. Sachlich zeigen, ohne Häme. Das bekommt man ohne Lehrer sonst
  nicht gesagt.

---

## 5. Befunde, die im Bericht fehlen

### A. Das wichtigste Ziel liegt außerhalb der App
Bei diesem Nutzer ist Platz 1 das Set; die App ist reine Pad-App und misst
Platz 4. Verallgemeinert: **Die App muss den Kontext bedienen, in dem das Ziel
liegt** — sonst bleibt sie eine Hausaufgabensammlung, egal wie gut die Notation
aussieht.

### B. Sauberkeit ist das Nadelöhr, nicht das Ziel
**Regel:** Die App verkauft Sauberkeit nie als Ziel, nur als Hindernis vor dem
Ziel. Nicht „Timing-Präzision 87 %", sondern „Dein Fuß liegt 30 ms hinter der
Hand — deshalb wackelt der Groove bei 100 BPM." Gleiche Messung, Sprache des
Ziels.

### C. Gates statt Kalenderwochen
Bei schwankender Zeit produziert ein Kalenderplan nur uneinholbaren Rückstand.
Ein Gate ist eine Messung, keine Kalenderzeile; ein ausgefallener Tag kostet
nichts außer Zeit. Der Streak zählt Anwesenheit, nicht Tagespensum.
**Folge:** variable Tagesdosis — Minimal-Kern (5–10 Min) plus optionale Blöcke
statt drei fester Blöcke nach dem Alles-oder-nichts-Prinzip.

### D. Zwei gleichwertige Kontexte — Desktop ist nicht „nebenbei"
- **Android = Pad = unterwegs.** Mikrofon, Hände, Rudiments, kurze Einheiten.
- **Desktop = Set = zuhause.** MIDI, Grooves, Koordination, Play-Along, Editor.

Trennung inhaltlich, nicht organisatorisch: **Das Pad baut die Fähigkeit, das Set
weist sie nach.** Sonst entsteht das Programm-≈-Routine-Problem auf zwei Geräten.
PR #12 ist damit strategisch.

### E. Sensorstufen — Mikrofon versagt am E-Set
Mesh-Heads sind leise, der Klang kommt aus dem Kopfhörer. Für E-Drums ist MIDI
die einzige Möglichkeit.

| Setup | Messung | Ausgabe |
|---|---|---|
| Handy + Pad, unterwegs | Mikrofon (Hände, Timing, Dynamik grob) | App-Samples |
| Modul + Handy per OTG | MIDI, vollständig | App-Samples über AUX ins Modul |
| **Modul + Laptop** | **MIDI, vollständig** | **App-Samples im Kopfhörer** |
| Modul + PC + externer Sampler | MIDI, vollständig | externer Sampler, optional |
| kein Sensor | nichts — Selbstbewertung | App-Samples |

Zeile 3 ist der Zielfall und kommerziell der realistischste. Superior Drummer ist
ein Extra, keine Voraussetzung — die vorhandene Metronom-Engine deckt den Ausgang
als Basislösung ab. **Ein- und Ausgang sind getrennte Abstraktionen**, einzuziehen
jetzt, solange nur eine Variante existiert.

Gates deklarieren ihre nötige Sensorstufe und weisen sich offen als gesperrt aus,
wenn die Hardware fehlt — statt Messwerte vorzutäuschen.

### F. Latenz-Kalibrierung
Wenn Modul (sofort) und App-Audio (verzögert) im Kopfhörer zusammenlaufen, spielt
man gegen einen nachhinkenden Klick an — die App misst dann eine Verzerrung, die
sie selbst erzeugt hat. Nötig: niedriglatente Ausgabe plus einmaliger
Kalibrierungsschritt. Gilt auf Android genauso, dort teils schlimmer.

---

## 6. Das Mikrofon-Problem (vier getrennte Probleme)

Das ist der Prüfstein Nr. 1 aus Abschnitt 1. Wenn die Messung weich ist, trägt
die Positionierung nicht.

### 6.1 Hand-Zuordnung ist eine Annahme, keine Messung
Ein Mikrofon hört einen Schlag, nicht welche Hand ihn ausführte — beide treffen
dasselbe Pad. Eine Zuordnung über die Reihenfolge (Onset n ↔ Notenposition n)
bricht bei jedem ausgelassenen Schlag, jedem Doppelschlag, jeder Fehlerkennung:
Ab dieser Stelle sind alle Hände vertauscht, und die App meldet eine Schieflage,
die es nicht gibt. **Am unzuverlässigsten genau dort, wo sie am wichtigsten wäre**
— beim unsauberen Spieler.

**Zu prüfen im Code:** Wie ordnet die heutige Mic-Analyse zu? Falls sie
durchzählt, sind bisherige Hand-Auswertungen teilweise unbrauchbar — und das
erklärt womöglich mit, warum sich die Statistik nie nach Erkenntnis anfühlte.

**Lösung 1 — Modus-Trennung (Entscheidung des Auftraggebers):**
Beim Lernen eines neuen Patterns gehen viele Schläge schief, und die Hand-Balance
ist dort ohnehin nicht die interessante Größe. Also:

| | Lernmodus | Analysemodus |
|---|---|---|
| Timing-Präzision | ja | ja |
| Gleichmäßigkeit | ja | ja |
| Dynamik-Streuung | ja | ja |
| Tempo & Ausdauer | ja | ja |
| **Hand-Balance** | **nein** | **ja** |
| Vertrauensmaß | tolerant | streng |

Der Analysemodus wird eingeschaltet, wenn das Pattern sitzt — dann ist die
Zuordnung auch technisch verlässlich, weil wenig schiefgeht. Geht doch zu viel
daneben, ist das selbst eine Aussage: es sitzt noch nicht.

**Der Umschaltmoment ist eine Chance.** Schaltet der Nutzer selbst um („ich
glaube, das sitzt"), wird die Messung zur Prüfung dieser Einschätzung. Die App
kann den Moment aber auch vorschlagen, denn sie sieht ihn: stabile
Gleichmäßigkeit über mehrere Durchläufe plus stimmende Schlagzahl. → *„Das läuft
jetzt sauber durch — soll ich mir die Hände einzeln ansehen?"* Damit ist der
Umschalter kein Schalter, sondern der Übergang von Lernen zu Verfeinern.

**Lösung 2 — Sequenzabgleich statt Positionszählung.** Auch im Analysemodus:
Gesamtfolge gegen das Soll abgleichen, fehlende und zusätzliche Schläge erkennen,
Zuordnung danach wieder einrasten. Bleibt der Abgleich unsicher, gibt es keine
Hand-Werte.

**Konsequenz für den Song-Import:** Ein frisch importierter Song-Ausschnitt ist
immer erst Lernmodus — die Transkription liefert ohnehin kein Sticking.
**Am Set über MIDI stellt sich die Frage nicht:** dort ist das getroffene Pad
bekannt. Die Modus-Trennung ist eine reine Pad-Angelegenheit.

### 6.2 Android verarbeitet das Messsignal vor
Standard-Aufnahmewege sind für Sprache gebaut: automatische Pegelregelung,
Rauschunterdrückung, Hochpass. Die Pegelregelung zieht leise Schläge hoch und
laute herunter — also genau das, was gemessen werden soll. Eine so gemessene
Dynamik-Kontrolle wäre größtenteils die Kennlinie des Regelkreises.
**Nötig:** unbearbeiteter Aufnahmeweg, feste Verstärkung. Prüfbar durch
abwechselnd laut/leise spielen und schauen, ob der Unterschied erhalten bleibt.

### 6.3 Mit Play-Along hört das Mikrofon die App selbst
Klick oder Backing-Track über Lautsprecher landen in derselben Aufnahme; jeder
Snare-Schlag im Song wird zu einem Onset (bei „Battery" über 2.000 in fünf
Minuten). Sauber lösbar nur über **Kopfhörer** — damit Voraussetzung für jede
Messung mit Begleitung. Ob einer steckt, ist abfragbar; die App muss es
aussprechen statt still Unsinn zu messen.

### 6.4 Am E-Set gibt es nichts zu hören
Keine zu lösende Aufgabe, sondern eine Grenze. Am Set ist MIDI der Weg
(P2 der Desktop-Roadmap).

### Übergreifend: Vertrauensmaß und Mikrofon-Check
**Die App muss bereit sein, keine Zahl zu zeigen.** Unsicherer Abgleich, kein
Kopfhörer, zu lauter Raum ⇒ „nicht sicher messbar" statt einer Zahl mit
Nachkommastelle. Eine Zahl, die manchmal falsch ist, ist schlechter als keine —
genau das unterscheidet die App von XP-Punkten.

**Mikrofon-Check beim ersten Start an einem neuen Ort:** ein paar Schläge in
bekanntem Muster ⇒ Pegel, Rauschabstand, Latenz. Zwanzig Sekunden, macht aus
einer Unbekannten eine kalibrierte Größe, passt ins eingebettete Assessment.

---

## 7. Fähigkeiten-Modell (Vorschlag, Antwort auf Bericht-Frage 3)

| Fähigkeit | trainiert auf | gemessen über | Sensorstufe | Modus |
|---|---|---|---|---|
| Timing-Präzision | beide | gegen Klick | Mikrofon / MIDI | beide |
| Gleichmäßigkeit | beide | Streuung der Abstände | Mikrofon / MIDI | beide |
| Tempo-Spektrum & Ausdauer | Pad | sauberes Maximaltempo, Haltedauer | Mikrofon / MIDI | beide |
| Dynamik-Kontrolle | beide | Lautstärke grob / Velocity exakt | Mikrofon (roh!) / MIDI | beide |
| Hand-Balance L/R | Pad | Timing + Lautstärke pro Hand | Mikrofon / MIDI | **nur Analyse** |
| **Hand-Fuß-Koordination** | **nur Set** | **Versatz Fuß zu Hand** | **nur MIDI** | — |
| Vokabular | beide | per Gate geprüft | — | — |

Zeile 6 ist der Grund, warum die App bisher am Set-Ziel vorbeimisst: mit dem
Mikrofon prinzipiell nicht erfassbar, mit MIDI trivial.

**Versprechen (Vorschlag, Antwort auf Bericht-Frage 2):**

> „Das Pad baut die Hände, das Set beweist es. Von deinem gemessenen Stand zu
> einem konkreten Groove in deinem Zieltempo — in bestandenen Prüfungen, nicht in
> Kalenderwochen."

---

## 8. Song-Zentrale (Einordnung von `BRIEF_SONG_UEBUNGEN.md`)

Der Song-Brief ist kein Nebenprojekt, sondern die **Brücke zum Ziel „Songs am
Set"** — und liefert das Material, das der kuratierte Katalog nie liefern kann:
die eigenen Songs. Machbarkeit ist am 05.09. bestanden (Demucs + ADTOF, „Battery",
2.475 Noten, ~12 s GPU-Zeit, inhärent synchron zum Audio).

**Architektur-Weiche:** Importiertes wird ins bestehende interne Format übersetzt.
Ein Song ist intern dasselbe Objekt wie eine Übung, nur länger und mit
Sektionsmarken (`ExerciseSource.excerpt` existiert bereits). Sonst zwei Apps in
einem Repo.

**Der Regelkreis, den Bericht-Abschnitt 3b vermisst:** Ein Gate endet an einer
konkreten Stelle in einem echten Song. Umgekehrt liest die App aus einer
gescheiterten Stelle heraus, welche Fähigkeit fehlt, und legt die passende
Pad-Übung für unterwegs hin. Dafür genügt eine fehlerhafte Transkription.

**Herkunft wird Eigenschaft eines Stücks:**

| Herkunft | Qualität | Rolle |
|---|---|---|
| kuratiert, von Hand geprüft | verlässlich | Boot-Camp-Gates, Kern-Katalog |
| importiert (Guitar Pro, MusicXML) | menschengemacht, meist gut | Song-Bibliothek |
| auto-transkribiert | Rohmaterial | eigene Songs, nach Nachbearbeitung |

Kein Format liefert **Sticking** — ergänzen von Hand oder aus der
Instrumentenverteilung ableiten. Das ist der Punkt, an dem der Player über eine
Songsterr-Kopie hinausgeht.

**Damit ist Bericht-Frage 11 beantwortet:** Die Desktop-Version *muss* Studio
sein. Auto-Transkription ohne Editor produziert unbrauchbares Material. Der Ort
zum Zurechtschieben, Sticking-Ergänzen und Taktbereich-zur-Übung-Erklären ist der
Laptop am Modul. Das Handy bleibt Abspieler und Pad-Trainer.

---

## 9. Offene Punkte

### Konzeptblöcke (Fortsetzung der Session)
- **Assessment-Entwurf** — Prinzip steht (Abschnitt 4), Umsetzung fehlt: welche
  Übungen legen welche Fähigkeit offen, wann steht das Profil, wie wird daraus
  das erste Gate formuliert. Entscheidet, ob aus dem Konzept ein Produkt wird.
- **Content-Strategie** — Bericht-Fragen 7/8, jetzt mit Song-Import als drittem
  Faktor. Insbesondere: Was passiert mit den 86 generierten Übungen?
- **UI-Leitplanken** — Bericht-Fragen 9/10; Drumeo-Screenshots fehlen noch.

### Technische Fragen
1. **Hand-Zuordnung im Bestandscode** — durchgezählt oder abgeglichen? (Abschnitt 6.1)
2. **Roher Aufnahmeweg auf Android** — Pegelregelung und Filter abschaltbar? (6.2)
3. **Latenz-Kalibrierung** — wie und wann, vor der ersten Messung? (Abschnitt 5F)
4. **Datenabgleich Handy ↔ Desktop** — Fortschritt entsteht auf zwei Geräten,
   Isar ist lokal.
5. **MIDI-Port-Exklusivität unter Windows** — externer Sampler belegt den Port.
   Virtueller Split oder zweiter physischer Ausgang?
6. **Mehrspur-Notation (P3)** — für Song-Ausschnitte unumgänglich (Kick/Snare/
   HiHat gleichzeitig); heutige Notation ist Einzelspur.
7. **Tempo-Erkennung und Quantisierung** — aus zeitbasiertem MIDI ein Notenbild;
   Umgang mit Tempo-Schwankungen.
8. **Korrektur-Editor** — wie leichtgewichtig, ohne vollen Noteneditor?
9. **Pipeline-Anbindung** — wie kommt ein Song in die App?
10. **Importweg Guitar Pro** — Parser portieren, Plattformbrücke, selbst lesen?
11. **Urheberrecht** — bei Eigennutzung unkritisch; vor Öffnung zu klären, bevor
    Arbeit in die Song-Bibliothek fließt.
