# Brief: Neukonzept Optik und Lerninhalte (Kritik-Runde 14.09.)

**Datum:** 14.09.2026 · **Anlass:** Kritik des Auftraggebers nach Abschluss
von Etappe 1, Phase 3 („Aussehen und Lerninhalte ziemlich schlecht", „ich
weiß nicht, wo anfangen") · **Bezug:**
`docs/concept/BERICHT_NEUKONZEPT.md` und
`BERICHT_NEUKONZEPT_ERGAENZUNG.md` (Befund G, PR #19) — dieser Brief macht
daraus einen Arbeitsauftrag in Phasen. **Etappe-1-Basis (Messung) ist
abgenommen und gemergt (PR #18).**

---

## §1 Leitbild

1. **„Leicht, luftig, modern, klar"** (Maßstab des Auftraggebers:
   Drumeo-Optik) — weniger graue Kästen, mehr Weißraum, klare Hierarchie,
   durchgehend Deutsch.
2. **Zwei Türen, jeden Tag beide offen:** *„Will ich dem Pfad folgen —
   oder habe ich heute Lust auf etwas anderes?"* Die App drängt nicht,
   sie bietet an. (Deckt sich mit der Positionierung aus der Ergänzung:
   Diese App beantwortet „Was mache ich jetzt?".)
3. **Die Messung bleibt das Rückgrat:** Fortschritt im Pfad heißt
   „gemessen geschafft" (sauber durchgespielt, kein Einbruch), nicht
   „Video abgehakt". Genau das kann kein Wettbewerber (Befund G).

## §2 Phase K1 — Sprachpass (klein, sofort) — **FREIGEGEBEN 14.09., Richtung: ENGLISCH**

Entscheidung Auftraggeber (Rückfrage 3): Die App geht **konsequent auf
Englisch** — kein Sprachmix mehr; die deutschen Texte aus Etappe 1
(Ansagen, Kalibrier-Screen, Einstellungen, Export) werden ins Englische
überführt. Das entspricht der ursprünglichen Code-Konvention („all
strings in English") und hält die App international anschlussfähig.
Keine Funktionsänderung. **Abnahme:** ein Durchklick durch alle Screens
ohne deutschen Nutzertext.

## §3 Phase K2 — Design-Pass „leicht und klar"

- **Dashboard wird „Heute":** ganz oben die zwei Türen — *„Weiter im
  Pfad: <nächster Schritt>"* (eine Karte, ein Knopf) und *„Frei üben"*
  (Bibliothek). Darunter kompakt: Streak, Tagesminuten. Der bisherige
  Karten-Stapel entfällt.
- **Übungs-Screen:** Das tote schwarze Zentrum verschwindet — Notenblatt
  und Zählwerk werden das großflächige Herz des Screens (gut lesbar auf
  Armlänge), Steuerung kompakt unten.
- **Feedback-Blatt:** Urteils-Banner (bereits umgesetzt) bleibt oben;
  darunter drei Kernwerte statt Zahlenfriedhof; alles Weitere hinter
  „Messdetails".
- **Vorgehen (Entscheidung Auftraggeber, Rückfrage 2): Entwürfe zuerst.**
  Vor der Umsetzung bekommt der Auftraggeber Mockups der Kern-Screens
  zur Sichtung. **Illustrationen aus der eigenen ComfyUI-Pipeline**
  (Hausstil) lockern die App auf — Kandidaten: Rubrik-Titelbilder,
  leere Zustände, Pfad-Stufen-Illustrationen.
- **Abnahme:** Erst Mockup-Freigabe, dann Umsetzung mit
  Screenshot-Abnahme; Auftraggeber-Urteil „leicht/luftig/klar" statt
  Checkliste.

## §4 Phase K3 — Der Pfad (geführtes Lernen)

- **Einstieg = eingebettetes Assessment** (Konzept-Ergänzung §4): kurze
  Mess-Übungen bestimmen die Startstufe — beantwortet „Wo fange ich an?"
  automatisch.
- **Stufen mit klaren Zielen:** je Stufe wenige Rudiments + Zieltempo +
  „gemessen geschafft"-Kriterium (Trefferquote, kein Einbruch, Streuung).
  Aufstieg nur über Messung. Wiederholungs-/Abruf-Mechanik nach
  Befund G (Repertoire behalten statt nur Neues stapeln).
- **Rubrik „Die wichtigsten Rudiments"** als Rückgrat des Pfads
  (PAS-Kern: Single/Double Stroke, Paradiddle, Flam, Drag …), jede mit
  deutscher Kurzanleitung: Was ist es, wofür braucht man es, worauf
  achten.
- **Abnahme:** Auftraggeber startet als „neuer Nutzer", durchläuft das
  Assessment und bekommt einen nachvollziehbaren Startpunkt + ersten
  Wochenplan.

## §5 Phase K4 — Freie Bibliothek + kuratierte Videos

- **Zweite Tür „Frei üben":** Rubriken statt Katalogliste — *Die
  wichtigsten Rudiments*, *Grooves am Pad* (neu zu erstellen:
  rudiment-angelehnte Groove-Übungen fürs Pad), *Technik-Studien*.
  Étuden bekommen sprechende Namen und einen Satz „warum".
- **Videos:** Eigenproduktion ist unrealistisch (Feststellung
  Auftraggeber). Stattdessen **kuratierte Sammlung**: pro Rudiment 1–3
  ausgewählte Lehrvideos als **YouTube-Verlinkung/offizielle
  Einbettung** — rechtlich unbedenklich, solange nur verlinkt/eingebettet
  und nichts kopiert/heruntergeladen wird; dazu jeweils eine **eigene
  deutsche Kurz-Zusammenfassung** (unser Inhalt). Kuratierungsliste wird
  dem Auftraggeber zur Sichtung vorgelegt.
- **Abnahme:** Bibliothek mit Rubriken am Gerät; Stichprobe: Rudiment
  öffnen → Anleitung + Video + Übung startbar.

## §6 Einordnung der alten Phase 4 (variable Tagesdosis)

Die geplante Etappe-1-Phase 4 („variable Tagesdosis") geht inhaltlich im
„Heute"-Modell von K2/K3 auf (Pfad-Schritt + freie Wahl statt starrer
20-Minuten-Routine). **Beschlossen 14.09.: Phase 4 alt entfällt als
eigener Block.**

## §7 Arbeitsweise

Wie in Etappe 1: TDD, jede Phase endet mit Gerätetest und kurzem Bericht,
Abnahme durch den Auftraggeber; Verfehlungen → Rückfrage statt
Umdeutung. Reihenfolge K1 → K2 → K3 → K4; K1 ist klein und kann sofort.

## §8 Rückfragen an den Auftraggeber

1. **Freigabe K1 (Sprachpass) sofort?**
2. K2-Design: reicht dir mein Geschmacksurteil entlang
   „leicht/luftig/klar" mit Screenshot-Abnahme durch dich — oder willst
   du vorher Entwürfe (Mockups) sehen?
3. Rating-Wortwahl Deutsch: „Schwer getan / Ging so / Saß" — okay oder
   andere Worte?
4. Phase 4 alt streichen (siehe §6) — ja/nein?
