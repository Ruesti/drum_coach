# Today-Illustrationen

Generiert am 23.09.2026 mit Qwen-Image (Apache 2.0) auf der eigenen GPU-Box,
Stil nach acht Runden mit dem Auftraggeber: echte Fotos in echten Räumen, eng
geschnitten, Format 16:9, 1080×608.

Seit 29.09.2026 zeigt Today ein Vollbild-Foto aus dem Hochformat-Vorrat
`../practice/` (Zufall, siehe `lib/features/practice/backdrop.dart`); die
sieben zustandsbezogenen 16:9-Bilder (Phase 1–4, Ruhetag, Einrichten, Tag
erledigt) sind bis auf eines entfernt.

| Datei | Verwendung | Motiv |
|---|---|---|
| done.jpg | Willkommens-Screen (Vollbild) | warm: Loft im Abendlicht, Arme hoch |

Render-Rezept: Text-zu-Bild ohne Referenzbild, 1344×768, euler/simple,
24 Steps, cfg 3,0, Seed 5 (render_final16.py beim Auftraggeber), Ausschnitt
auf 16:9 mittig, dann auf 1080×608 verkleinert.
