# Übungs-Hintergründe

Generiert am 28.09.2026 mit Qwen-Image (Apache 2.0) auf der eigenen GPU-Box,
gleiches Rezept wie der Today-Satz (`../today/README.md`): echte Räume, eng
geschnitten, Mischung aus Action und ruhigen Momenten, Menschen gemischt.
Hochformat für den Übungs-Screen (Entscheidung Auftraggeber 28.09.: „Bild per
Zufallsgenerator in jeder Übung, ca. 30 Fotos" → alle 36 Kandidaten
übernommen).

Der Übungs-Screen zieht bei jedem Öffnen eines dieser Fotos zufällig
(`lib/features/practice/backdrop.dart`), nie zweimal hintereinander dasselbe.

18 Motive × 2 Seeds (5 und 77), Dateiname `pNN_<motiv>_s<seed>.jpg`:

| Motiv | Stimmung |
|---|---|
| p01 garage_teen | Garage, Teenager, Action |
| p02 jazz_bar | Jazz-Bar, Besen, ruhig |
| p03 loft_woman | Loft, Fill, Action |
| p04 basement_metal | Keller, Metal, Action |
| p05 school_room | Musikraum, Mädchen, ruhig |
| p06 church_gospel | Gospel, Acrylkit, Action |
| p07 rooftop_dusk | Dachterrasse, Dämmerung, ruhig |
| p08 club_red | Club, rotes Kit, Action |
| p09 studio_glass | Studio, Playback, ruhig |
| p10 home_kid | Wohnzimmer, Kind, ruhig |
| p11 festival_day | Festival, Tageslicht, Action |
| p12 practice_pad | Hände am Pad, ruhig |
| p13 theater_orch | Theater, Altmeister, ruhig |
| p14 bar_woman | Pub-Gig, Lederjacke, Action |
| p15 rehearsal_foam | Proberaum, Beanie, Action |
| p16 daylight_plant | Heller Raum, Anfängerin, ruhig |
| p17 stone_cellar | Gewölbekeller, Bandana, Action |
| p18 evening_loft | Loft, Abendlicht, Handtuch, ruhig |

Render-Rezept: Text-zu-Bild ohne Referenzbild, 768×1344, euler/simple,
24 Steps, cfg 3,0 (`render_practice36.py` beim Auftraggeber), dann auf
1080 px Breite verkleinert, JPEG q84.
