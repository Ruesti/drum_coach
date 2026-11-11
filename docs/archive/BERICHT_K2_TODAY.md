# Bericht K2, Schritt 1: Today

**Datum:** 16.09.2026 · **Branch:** `k2-today` (auf `k1-english-pass`) ·
**Plan:** `docs/superpowers/plans/2026-09-15-k2-today.md` · **Entwurf:**
`docs/design/ENTWURF_K2_LEICHT_UND_KLAR.md` (Entscheidungen 15.09.)

## Was gebaut wurde

1. **Helle Papier-Palette für die App**, der Übungs-Screen bleibt dunkel
   (Entscheidung „Mischung"). Die Token-Namen blieben, nur die Werte wurden
   hell; der Übungs-Screen nutzt `PracticeColors`/`PracticeTypography` in
   einem dunklen Theme-Wrapper, gemeinsame Widgets wählen ihre Farben über
   `AppPalette.of(context)`.
2. **Schriften als Assets.** Space Grotesk und IBM Plex Mono liegen unter
   `assets/google_fonts/` (OFL, Hashes gegen das google_fonts-Paket geprüft);
   Nachladen aus dem Netz ist aus. Nebeneffekt: Tests laufen auf jeder
   Maschine gleich, vorher hingen sie am Font-Cache.
3. **Navigation mit drei Tabs** Today · Library · Progress. Die Routine hat
   keinen Tab mehr, bleibt aber als Route erreichbar; alte Pfade leiten um.
4. **Today** ersetzt das Dashboard: „Continue the path" mit dem nächsten
   Schritt (erster offener Block des Programmtags, sonst Routine-Item, sonst
   Einrichten / Ruhetag / Tag erledigt / Programm fertig) und einem Knopf,
   „Practice freely" in die Library, darunter Streak und Tagesminuten.

## Was bewusst noch nicht drin ist

- Illustration über dem Pfad-Schritt (kommt mit K3/K4, Stil offen).
- Umbau des Übungs-Screens (K2 Schritt 2) und des Ergebnis-Blatts (Schritt 3).
- Library und Progress sind nur umbenannt, nicht neu gestaltet (K4).

## Tests

281 Tests grün, `flutter analyze` ohne Fehler (12 vorbestehende
„experimental"-Warnungen aus Isar/SoLoud). Testläufe auf der GPU-Box, weil
der NUC nachts nicht genug freien Speicher zum Kompilieren hatte.

## Gerätetest (17.09., S23 Ultra, Release-Build)

Installiert über den Laptop, Screenshots per adb: Today, Library, Progress,
Übungs-Screen. Befund:

- **Today** wie im Entwurf: heller Papier-Look, „Continue the path" mit
  „Single Stroke Roll · Day 16 · Step 1 of 3" und „Start · 3 min",
  „Practice freely", Streak und Minuten. Zurück aus dem Übungs-Screen landet
  sauber auf Today.
- **Library / Progress** hell und lesbar: Filter-Chips, Schwierigkeits-Badges,
  Heatmap, Balken, BPM-Kurve funktionieren auf hellem Grund.
- **Übungs-Screen** dunkel mit hellem Notenblatt, Steuerung dunkel — noch im
  alten Aufbau (K2 Schritt 2).
- **Ein Fehler gefunden und behoben:** Nach dem dunklen Übungs-Screen blieben
  die Symbole der Android-Statusleiste weiß und waren auf Today kaum lesbar
  (Today hat keine AppBar, die den Stil zurücksetzt). Today setzt den
  Overlay-Stil jetzt selbst; Test dazu.

Abnahme durch den Auftraggeber: Urteil „leicht / luftig / klar" am Gerät,
dazu der K1-Durchklick (kein deutscher Nutzertext).
