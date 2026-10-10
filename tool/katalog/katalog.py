"""Registry der Katalog-Sätze: welche Blätter es gibt und wie sie heißen.

Jeder Satz = ein Datenmodul (`rudimente.py`, `fills.py`) plus Überschriften
für die Kurationsseite und der Marker im Seed, unter dem neue Einträge
angehängt werden. Die Generatoren (build_page, gen_dart, patch_seed) laufen
über diese Liste; ein Satzname als Argument wählt einen aus.
"""
from __future__ import annotations

from dataclasses import dataclass

import fills
import rudimente
from blatt import Sheet


@dataclass(frozen=True)
class SheetSet:
    key: str
    step: str  # Katalog-Schritt, z. B. '3a'
    title: str  # Überschrift der Kurationsseite
    lead: str  # Einleitung der Kurationsseite
    seed_marker: str  # Kommentarzeile im Seed über den neuen Einträgen
    sheets: list[Sheet]


SETS: list[SheetSet] = [
    SheetSet(
        key='rudimente', step='3a', title='Zwölf Rudiment-Blätter',
        lead='Frei komponiert nach der Regel „jede Übung so abwechslungsreich und groovy wie möglich": '
             'je Blatt acht Zeilen à zwei Takte mit Wiederholung und eine Challenge über acht Takte. '
             'Oben in jedem Blatt der Kasten mit der Grundgestalt (so steht sie auf der Info-Seite), '
             'die Lektion ist eingeklappt. Sag mir je Blatt und Zeilennummer, was raus, anders oder länger soll.',
        seed_marker='KATALOG 3a: new base rudiments',
        sheets=rudimente.SHEETS,
    ),
    SheetSet(
        key='fills', step='3b', title='Acht Fill-Sticking-Blätter',
        lead='Brief §3.2: je Zeile drei Takte einstimmiges Time-Muster und ein Takt Fill, als Vier-Takt-Phrase '
             'geloopt; die Band kommt aus dem Loop und läuft im Fill-Takt weiter. Takt 1 jeder Zeile beginnt '
             'mit Akzent — das ist die Eins nach dem Fill. „Fill" steht hier über dem vierten Takt, in der App '
             'nicht. Oben im Kasten der Fill-Takt der ersten Zeile (PATTERN auf der Info-Seite), die Lektion ist '
             'eingeklappt. Sag mir je Blatt und Zeilennummer, was raus, anders oder länger soll.',
        seed_marker='KATALOG 3b: fill stickings',
        sheets=fills.SHEETS,
    ),
]


def select(key: str | None) -> list[SheetSet]:
    if key is None:
        return SETS
    for s in SETS:
        if s.key == key:
            return [s]
    raise SystemExit(f'unknown set {key!r}; known: ' + ', '.join(s.key for s in SETS))


def all_sheets() -> list[Sheet]:
    return [sh for s in SETS for sh in s.sheets]
