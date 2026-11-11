# Competitor Scan: Drum-Lern-Apps

> Recherchiert am 2026-08-03 via WebSearch/WebFetch (Playwright-Browser auf diesem Host nicht verfügbar, da Chrome-Channel fehlt — siehe Hinweis am Ende). Ziel: Einordnung des eigenen Ansatzes (generative Notation, Pad/Kit-Modi, kein Song-Katalog) gegenüber existierenden Produkten.

## Fokusachsen

1. **Notation & Übungsdarstellung** — echte Notenschrift vs. Video vs. Mikrofon-Erkennung vs. generativ
2. **Lernlogik & Fortschritt** — Wiederholung, Scoring, Streaks, Gates, adaptive Schwierigkeit
3. **Plattformen & Offline-Fähigkeit**
4. **Preismodell**

---

## Übersichtstabelle

| App | Notation & Darstellung | Lernlogik & Fortschritt | Plattformen & Offline | Preis |
|---|---|---|---|---|
| **Drumeo** | Videobasiert: >1500 Song-Breakdowns von echten Trainern, kein Notation-Rendering, kein generativer Content | Strukturiertes 10-Level-Curriculum ("Drumeo Method"), aber keine erkennbare Spaced-Repetition/Gate-Logik | Web, iOS, Android; Offline nicht erwähnt | Abo, 7 Tage kostenlos, 90-Tage-Geld-zurück; Zubehör auch einzeln kaufbar |
| **Melodics** | Mikrofon-/Audioerkennung auf echtem Kit oder Pad (kein extra Hardware nötig), MIDI/Bluetooth für E-Drums; visuelle Notationsform selbst nicht dokumentiert | 500+ Lektionen (Rudiments, Grooves, Fills, Drills, Songs), Loop/Slow-down-Tools, Fortschrittstracking; kein explizites Streak/Scoring-System belegt | iPhone/iPad/Mac; Offline nicht dokumentiert | 20 Lektionen gratis, danach Abo: 34,99 $/Monat oder 179,99 $/Jahr |
| **Yousician** | **Kein offizielles Drums-Angebot mehr** — Startseite listet nur Gitarre/Bass/Klavier/Ukulele/Gesang. Referenzwert: Grundmodell ist Mikrofon-Audioerkennung mit Echtzeit-Feedback (Alternative zu Notation) | Lektionspläne von Musiklehrern, 9000+ Lektionen (andere Instrumente), Scoring auf Timing/Präzision | Android, iOS, PC | 7 Tage Premium+ Trial, danach Abo; Familienplan für 4 Accounts |
| **Drumless** | **Kein Notation-Tool** (Korrektur ggü. erster Web-Recherche) — reines KI-Stem-Separation-Tool: trennt Drums aus beliebigem Song heraus für Playalong-Zwecke | Kein Rudiment-Trainer, keine Streaks/Fortschrittslogik belegt | Web-only (Upload/Drag&Drop), Mobile-Apps existieren, Offline nicht dokumentiert | 1-Minuten-Gratistest, dann 0,99 $ (Monat 1) → 2,99 $/Monat oder 14,90 $/Jahr |
| **Drumr** | **Echte Notation** mit Sample-Sounds; Cursor folgt jeder Note; 600+ interaktive Scores (Rudiments, Grooves, Fills, Charts, Songs, Playalongs, Marching Percussion); Kit-Animation + Practice-Pad-Sticking-Ansicht | Performance-Analyse pro Note (früh/spät/verpasst), Aktivitätsringe, Tempocharts, Awards/Streaks, proaktive Coaching-Empfehlungen, kuratierte Lernpfade, Measure-Loops, Tempo-Modi (linear/steigend/up-down) | iPhone, iPad, Mac; **funktioniert offline**, nur Videos/Playalongs brauchen Internet; MIDI/USB für E-Drums | Kostenlos mit 7-Tage-Trial, danach Abo (Preis nicht spezifiziert) |
| **Groove Scribe** | Grid-basierter Klick-Editor: Sofort-Playback, generiert lesbare Notation aus Tempo/Orchestrierung/Akzenten/Ghost-Notes/Stickings | Reines Editor-Tool ohne Fortschrittsverfolgung — kein Lernsystem | Web-only, Browser, kein Offline-Modus | Kostenlos, Open Source |
| **RTFactory Rudiments** | Liste der 40 PAS-Rudiments, visuelle Notendarstellung, Wisch/Shake zum Wechseln | Tempo-Trainer (40–220 BPM, automatische Steigerung), geführter Übungsmodus (Runden/Wiederholungen/Pausen konfigurierbar), Performance-Rating, Übungsstatistiken pro Rudiment | iPad-optimiert (auch iPhone/iPod), eingeschränkt macOS; Offline nicht explizit erwähnt | 0,99 $ einmalig, keine In-App-Käufe |
| **421Grid** | Drumline-Übungsgenerator: 4-2-1-Struktur, editierbar über Accents/Subdivisions (Triolen, Fünfergruppen, 16tel)/alternative Stickings/Beat/Direction | Keine Fortschrittsverfolgung dokumentiert — Fokus auf "unlimited variations" statt Tracking | iPad/iPhone/Mac (M1+)/Vision; **vollständig offline** ("No internet? No problem.") | 1,99 $ einmalig |

---

## Was das für drum_coach bedeutet

**Notation als Kern ist eine Lücke, kein Nischending.** Nur Drumr und (rudimentär) Groove Scribe/RTFactory zeigen echte Notenschrift statt Video oder Mikrofon-Feedback. Die großen Player (Drumeo, Melodics) setzen auf Video-Content bzw. Audioerkennung — beides skaliert nicht generativ und bindet an Lizenz-/Aufnahme-Aufwand. Der im Brief festgelegte Weg (Synthese aus Notation statt Audio-Streaming) trifft eine echte Lücke zwischen "Video-Bibliothek" und "Mikrofon-Spielzeug".

**Drumr ist der nächstgelegene Konkurrent** — echte Notation, Rudiments+Grooves+Fills+Songs in einem Modell, Offline-Fähigkeit für den Übungsteil, Performance-Analyse pro Note. Unterscheidung zu drum_coach: Drumr scheint kuratierte/kaufsame Scores zu nutzen statt eines Sticking-Generators; die generative Grammatik (ein Baustein → Rudiments, Fills, Koordination, Ausdauer) bleibt der eigene Hebel.

**421Grid bestätigt den generativen Ansatz im Kleinen.** Es ist im Prinzip ein Prototyp der im Brief beschriebenen Sticking-Grammatik (Sticking × Subdivision × Akzentmaske), nur ohne Lernlogik und ohne Kit-Modus. Zeigt: Der Markt für "generiere Übungen aus Parametern statt Asset-Katalog" existiert, ist aber unterentwickelt — niemand verbindet es mit SM-2/Gates/Tags wie im Brief vorgesehen.

**Mikrofon-Erkennung (Melodics, früher Yousician) ist eine valide Alternative zur Notation-Wiedergabe**, aber löst ein anderes Problem (Ist-Erkennung vs. Soll-Darstellung) und ersetzt keine Partitur. Für den Pad-Modus (unterwegs, Klick statt Kit-Sound) ist Mikrofon-Feedback ohnehin ungeeignet.

**Drumless zeigt eine Randtechnologie fürs Song-Sync-Feature**: KI-Stem-Separation, um Drums aus echten Songs herauszurechnen bzw. zu isolieren. Relevant als mögliche Zusatzfunktion für den Song-Import (z. B. Referenzspur zur Kontrolle), aber kein Notation-Konkurrent und rechtlich in eine andere Kategorie einzuordnen als das im Brief beschriebene reine Score-Sync-Modell (SyncMap + Anker).

**Preismodelle clustern um Abo (Drumeo, Melodics, Yousician, Drumless) vs. Einmalkauf für Nischen-Tools (RTFactory, 421Grid).** Drumr als engster Konkurrent fährt ebenfalls Abo mit Trial.

---

## Hinweis zur Methodik

Playwright (MCP) konnte auf diesem Host nicht verwendet werden: Der Server erwartet einen system­weiten Chrome-Channel (`/opt/google/chrome/chrome`), dessen Installation Root-Rechte braucht, die in dieser Session nicht verfügbar sind. Die Recherche erfolgte stattdessen über WebSearch/WebFetch direkt gegen die öffentlichen Marketing-/App-Store-Seiten. Eine erste automatisierte Zusammenfassung zur App "Drumless" enthielt fehlerhafte Angaben (Notation-Generierung, Rudiment-Trainer), die beim direkten Nachlesen der Seite nicht bestätigt wurden und hier korrigiert sind — Einzelangaben aus schnellen Suchzusammenfassungen sollten vor Verwendung im Produkt-Briefing gegen die Originalquelle geprüft werden.
