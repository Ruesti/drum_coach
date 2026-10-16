"""Registry der Katalog-Sätze: welche Blätter es gibt und wie sie heißen.

Jeder Satz = ein Datenmodul (`rudimente.py`, `fills.py`) plus Überschriften
für die Kurationsseite und der Marker im Seed, unter dem neue Einträge
angehängt werden. Die Generatoren (build_page, gen_dart, patch_seed) laufen
über diese Liste; ein Satzname als Argument wählt einen aus.
"""
from __future__ import annotations

from dataclasses import dataclass

import feet
import fills
import grooves
import rudimente
import set_fills
import set_more
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
    SheetSet(
        key='grooves', step='B.4a', title='Sechs Grooves und Open Hi-hat',
        lead='Phase B.4: der Groove der Band-Stimme als Blatt — Hi-Hat, Snare, Kick spielst du jetzt selbst; mit '
             'Backing spielt die App Kick und Hi-Hat der Zeile mit, ohne nur den Click. Hände Hals oben, Füße Hals unten. Sag mir je Blatt und '
             'Zeilennummer, was raus, anders oder länger soll.',
        seed_marker='PHASE B.4: kit grooves',
        sheets=grooves.SHEETS,
    ),
    SheetSet(
        key='set_fills', step='B.4b', title='Acht Fill-Blätter am Set und Rund ums Set',
        lead='Phase B.4: die acht Fill-Blätter vom Pad jetzt am Set — drei Takte Groove, im Fill-Takt wandern die '
             'Hände Zählzeit für Zählzeit über Snare und Toms, die Kick hält 1 und 3, und die Eins danach ist ein '
             'Crash. Dazu „Rund ums Set": einfache Stickings über alle vier Toms, je Zeile Crash, China oder '
             'Ride-Glocke auf der Eins. Toms und Crash mit ~ nehmen jedes Tom bzw. Crash. Sag mir je Blatt und '
             'Zeilennummer, was raus, anders oder länger soll.',
        seed_marker='PHASE B.4: kit fills',
        sheets=set_fills.SHEETS,
    ),
    SheetSet(
        key='feet', step='B.4c', title='Füße: Kick, Double Bass, Hi-hat-Fuß',
        lead='Nachtrag B.4c: Fußübungen am Set — Kick-Kontrolle, Sechzehntel-Kombinationen, Double Bass '
             '(Fußseiten R/L nur in der App), Hi-hat-Fuß, Ostinati. Sag mir je Blatt und Zeilennummer, was raus, '
             'anders oder länger soll.',
        seed_marker='PHASE B.4c: feet',
        sheets=feet.SHEETS,
    ),
    SheetSet(
        key='set_more', step='B.4c', title='Linear, Double-Bass-Fill, Kick-Sechzehntel, Half-time Shuffle',
        lead='Nachtrag B.4c: zwei Fill-Blätter, deren Füße mitspielen — Linear Fill (Hände und Kick abwechselnd, '
             'nie gleichzeitig) und Double Bass Fill (Hände beginnen, beide Füße beenden den Takt) —, dazu der '
             'Linear Groove (kein Sechzehntel doppelt belegt), der Sixteenth Kick Groove und der Half-time '
             'Shuffle. Sag mir je Blatt und Zeilennummer, was raus, anders oder länger soll.',
        seed_marker='PHASE B.4c: more fills and grooves',
        sheets=set_more.SHEETS,
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
