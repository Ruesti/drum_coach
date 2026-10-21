#!/usr/bin/env python3
"""Geführte Übungen (Plan 2 Katalog): die Daten, aus denen gen_gefuehrt.py
lib/features/guided/data/guided_catalog.dart und tool/stimme/saetze_gefuehrt.py erzeugt.

Stand Task 2: zwei Fixture-Übungen, Noten und Texte 1:1 wie demo_exercise.dart
(demoKitExercise, demoPadExercise) — nur technische Prüfung des Generators
(Entscheidung P2-R1). Task 5 ersetzt sie durch komponierte Inhalte.

Aufruf: python3 gefuehrt.py  → prüft alle Übungen und druckt eine Übersicht.
"""
from __future__ import annotations

from gefuehrt_blatt import GuidedSheet, Variation, check_catalog


def kit(**tracks: str) -> str:
    """Spuren als Keywords → Spurentext (Reihenfolge = Stimmen-Reihenfolge)."""
    return '\n'.join(f'{k}: {v}' for k, v in tracks.items())


# ── Kit: rock eighths (wie demoKitExercise) ───────────────────────────────────
HH8 = 'R8 R8 R8 R8 R8 R8 R8 R8'
HH8_O4 = 'R8 R8 R8 R8 R8 R8 R8 -8'  # „4 +" gehört der offenen Hi-Hat (HO-Spur)
HO_4AND = '-2 -4 -8 R8'
SN_24 = '-4 L4> -4 L4>'
SN_GHOST_2E = '-4 L16> L16g -8 -4 L4>'
BD_13 = 'K4 -4 K4 -4'
BD_13AND = 'K4 -4 K8 K8 -4'

ROCK8 = GuidedSheet(
    id='guided_kit_rock8',
    name='Rock 8ths',
    description='Rock eighths with three building variations.',
    package='kit', difficulty='intermediate',
    default_bpm=100, min_bpm=60, max_bpm=140, grid='sixteenth',
    groove=kit(HH=HH8, SN=SN_24, BD=BD_13),
    variations=(
        Variation(kit(HH=HH8, SN=SN_24, BD=BD_13AND),
                  'Next up: add the bass drum on the and of three.'),
        Variation(kit(HH=HH8, SN=SN_GHOST_2E, BD=BD_13AND),
                  'Now add a soft ghost note on the snare, on the e of two.'),
        Variation(kit(HH=HH8_O4, HO=HO_4AND, SN=SN_GHOST_2E, BD=BD_13AND),
                  'Last one: open the hi-hat on the and of four.', after=None),
    ),
)

# ── Pad: eighths (wie demoPadExercise) ────────────────────────────────────────
PAD_EIGHTHS = GuidedSheet(
    id='guided_pad_eighths',
    name='Eighths',
    description='Alternating eighths with accents, doubles and paradiddles.',
    package='pad', difficulty='beginner',
    default_bpm=90, min_bpm=60, max_bpm=130, grid='eighth',
    groove='R8 L8 R8 L8 R8 L8 R8 L8',
    variations=(
        Variation('R8> L8 R8> L8 R8> L8 R8> L8',
                  'Next up: accent the first note of every beat.'),
        Variation('R8 R8 L8 L8 R8 R8 L8 L8',
                  'Now switch to doubles: right right, left left.'),
        Variation('R8> L8 R8 R8 L8> R8 L8 L8',
                  'Last one: play paradiddles. Right left right right, left right left left.',
                  after=None),
    ),
)

SHEETS: list[GuidedSheet] = [ROCK8, PAD_EIGHTHS]


def bars(s: GuidedSheet) -> int:
    """Geplante Takte wie GuidedExercise.barsAt: Einzähltakt + Abschnitte (ohne Verlängerung)."""
    n = len(s.variations)
    return 1 + n * (s.groove_bars + s.variation_bars) + s.groove_bars + 1


def print_table(sheets: list[GuidedSheet]) -> None:
    check_catalog(sheets)
    for s in sheets:
        sec = round(bars(s) * 4 * 60 / s.default_bpm)
        print(f'{s.id:24s} {s.package:3s}  {s.difficulty:12s} {len(s.variations)} Variationen  '
              f'{bars(s):3d} Takte  {sec // 60}:{sec % 60:02d} bei {s.default_bpm} BPM')
    print(len(sheets), 'Übungen ok')


if __name__ == '__main__':
    print_table(SHEETS)
