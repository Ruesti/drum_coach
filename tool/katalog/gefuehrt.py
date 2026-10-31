#!/usr/bin/env python3
"""Geführte Übungen (Plan 2 Katalog): die Daten, aus denen gen_gefuehrt.py
lib/features/guided/data/guided_catalog.dart und tool/stimme/saetze_gefuehrt.py erzeugt.

Runde 1 (Task 5): acht neu komponierte Übungen, je Paket (Set, Pad) eine pro
Schwierigkeit. Die Demo-Übungen in demo_exercise.dart bleiben unverändert und
sind nicht Teil des Katalogs (Entscheidung P2-R1). Jede Übung: ein Grundgroove,
3–4 Variationen, die aufeinander aufbauen; die Erklärung sagt, was sich wo ändert.

Aufruf: python3 gefuehrt.py  → prüft alle Übungen und druckt eine Übersicht.
"""
from __future__ import annotations

from gefuehrt_blatt import GuidedSheet, Variation, check_catalog
from set_fills import rest_tokens
from sheetlang import TPQ


def kit(**tracks: str) -> str:
    """Spuren als Keywords → Spurentext (Reihenfolge = Stimmen-Reihenfolge).

    `C1_` steht für den Spurkopf `C1~` (jedes Crash-Becken).
    """
    return '\n'.join(f'{k.replace("_", "~")}: {v}' for k, v in tracks.items())


def two(a: str, b: str) -> str:
    """Zwei Takte einer Spur."""
    return f'{a} | {b}'


TRACK_ORDER = ('C1_', 'HH', 'HO', 'RD', 'T1', 'T2', 'F1', 'SN', 'BD')


def line4(*bars: dict[str, str]) -> str:
    """Vier Kit-Takte (je ein Dict Spur → Takt) → Spurentext; fehlt eine Spur in einem Takt, ist er Pause."""
    if len(bars) != 4:
        raise ValueError(f'line4 needs 4 bars, got {len(bars)}')
    keys = sorted({k for b in bars for k in b}, key=TRACK_ORDER.index)
    return kit(**{k: ' | '.join(b.get(k, '-1') for b in bars) for k in keys})


def rise(base: dict[str, str], **lift: str) -> str:
    """Vier-Takt-Zeile: drei Takte `base`, Takt 4 = `base` mit den Spuren aus `lift` (Steigerung)."""
    return line4(base, base, base, {**base, **lift})


def rise_pad(base: str, lift: str) -> str:
    """Pad: drei Takte `base`, Takt 4 = `lift`."""
    return ' | '.join([base] * 3 + [lift])


# ══ Set · beginner: Backbeat Walk ═════════════════════════════════════════════
# Rock-Achtel; die Bassdrum wandert dazu: 1·3 → + „3 und" → + „1 und";
# zuletzt jeder zweite Takt mit Crash auf der 1 statt Hi-Hat.
# Takt 4 jeder Zeile: Groove Kick auf „4 +" · V1 Snare-Doppel 4 „4 +" ·
# V2/V3 Mini-Fill Snare 4 → Standtom „4 +" (in V3 direkt ins Crash).
BW_HH = 'R8 R8 R8 R8 R8 R8 R8 R8'
BW_HH_NO1 = '-8 R8 R8 R8 R8 R8 R8 R8'  # die rechte Hand spielt auf 1 das Crash
BW_HH_FILL = 'R8 R8 R8 R8 R8 R8 R8 -8'  # „4 +" gehört dem Standtom
BW_C1 = 'R4 -4 -2'
BW_SN = '-4 L4> -4 L4>'
BW_SN_DOUBLE = '-4 L4> -4 L8> L8>'  # 4 und „4 +"
BW_SN_FILL = '-4 L4> -4 L8> -8'
BW_F1_FILL = '-2. -8 R8>'  # Standtom auf „4 +"
BW_BD = 'K4 -4 K4 -4'  # 1, 3
BW_BD_4AND = 'K4 -4 K4 -8 K8'  # dazu „4 +"
BW_BD_3AND = 'K4 -4 K8 K8 -4'  # 1, 3, „3 +"
BW_BD_1AND = 'K8 K8 -4 K8 K8 -4'  # 1, „1 +", 3, „3 +"
BW_FILL = dict(HH=BW_HH_FILL, SN=BW_SN_FILL, F1=BW_F1_FILL)

BACKBEAT_WALK = GuidedSheet(
    id='guided_kit_backbeat_walk',
    name='Backbeat Walk',
    description='Rock eighths where the bass drum walks to new spots, topped with a crash.',
    package='kit', difficulty='beginner',
    default_bpm=90, min_bpm=60, max_bpm=120, grid='eighth',
    groove=rise(dict(HH=BW_HH, SN=BW_SN, BD=BW_BD), BD=BW_BD_4AND),
    variations=(
        Variation(rise(dict(HH=BW_HH, SN=BW_SN, BD=BW_BD_3AND), SN=BW_SN_DOUBLE),
                  'Next up: add a bass drum on the and of three.', title='Kick on and of three'),
        Variation(rise(dict(HH=BW_HH, SN=BW_SN, BD=BW_BD_1AND), **BW_FILL),
                  'Now add one more bass drum, on the and of one.', title='Kick on and of one'),
        Variation(line4(dict(C1_=BW_C1, HH=BW_HH_NO1, SN=BW_SN, BD=BW_BD_1AND),
                        dict(HH=BW_HH, SN=BW_SN, BD=BW_BD_1AND),
                        dict(C1_=BW_C1, HH=BW_HH_NO1, SN=BW_SN, BD=BW_BD_1AND),
                        dict(BD=BW_BD_1AND, **BW_FILL)),
                  'Last one: every other bar, crash on one instead of the hi-hat.', title='Crash every other bar',
                  after=None),
    ),
)

# ══ Set · intermediate: Funk Sixteenths ═══════════════════════════════════════
# Sechzehntel-Hi-Hat mit einer Hand, Kick 1 · „2 +" · „3 +"; Ghosts auf „2 e",
# dann „4 a", dann offene Hat auf „4 +", zuletzt Kick-Doppel „3 +" „3 a".
FS_HH = ' '.join(['R16> R16'] * 8)  # Akzente auf den Achteln
FS_HH_O4 = ' '.join(['R16> R16'] * 6) + ' R16> R16 -8'  # „4 +" und „4 a" gehören der offenen Hat
FS_HO = '-2. -8 R8'
FS_SN = '-4 L4> -4 L4>'
FS_SN_2E = '-4 L16> L16g -8 -4 L4>'
FS_SN_2E_4A = '-4 L16> L16g -8 -4 L16> -8 L16g'
FS_BD = 'K4 -8 K8 -8 K8 -4'  # 1, „2 +", „3 +"
FS_BD_3A = 'K4 -8 K8 -8 K16 K16 -4'  # dazu „3 a"
# Takt 4 (die Ansage bleibt für alle vier Takte wahr): Groove + V3 Kick auf „4 +" ·
# V1 Kick auf „4 a" · V2 Kick auf „1 a" · V4 Sechzehntel-Fill R L R L auf der Snare (Zählzeit 4).
FS_BD_4AND = 'K4 -8 K8 -8 K8 -8 K8'
FS_BD_4A = 'K4 -8 K8 -8 K8 -8. K16'
FS_BD_1A = 'K8. K16 -8 K8 -8 K8 -4'
FS_HH_FILL = ' '.join(['R16> R16'] * 6) + ' -4'
FS_SN_FILL = '-4 L16> L16g -8 -4 R16> L16 R16> L16'

FUNK_SIXTEENTHS = GuidedSheet(
    id='guided_kit_funk_sixteenths',
    name='Funk Sixteenths',
    description='A sixteenth hi-hat funk groove that grows ghost notes, an open hat and two kicks in a row.',
    package='kit', difficulty='intermediate',
    default_bpm=95, min_bpm=70, max_bpm=120, grid='sixteenth',
    groove=rise(dict(HH=FS_HH, SN=FS_SN, BD=FS_BD), BD=FS_BD_4AND),
    variations=(
        Variation(rise(dict(HH=FS_HH, SN=FS_SN_2E, BD=FS_BD), BD=FS_BD_4A),
                  'Next up: a soft ghost note on the snare, on the e of two.', title='Ghost note on two'),
        Variation(rise(dict(HH=FS_HH, SN=FS_SN_2E_4A, BD=FS_BD), BD=FS_BD_1A),
                  'Now add a second ghost note, on the a of four.', title='Second ghost on four'),
        Variation(rise(dict(HH=FS_HH_O4, HO=FS_HO, SN=FS_SN_2E_4A, BD=FS_BD), BD=FS_BD_4AND),
                  'Now open the hi-hat on the and of four.', title='Open hat on four'),
        Variation(line4(*[dict(HH=FS_HH_O4, HO=FS_HO, SN=FS_SN_2E_4A, BD=FS_BD_3A)] * 3,
                        dict(HH=FS_HH_FILL, SN=FS_SN_FILL, BD=FS_BD_3A)),
                  'Last one: add a kick on the a of three, right before the snare.', title='Kick before the snare',
                  after=None),
    ),
    groove_bars=8, variation_bars=20,
)

# ══ Set · advanced: Half-Time Shuffle ═════════════════════════════════════════
# Shuffle-Hat (1 und „let" jeder Zählzeit), Backbeat nur auf 3, Kick 1 · „3 let".
# Ghosts in die Triolen-Mitte, dann wandert die Kick, zuletzt offene Hat.
HT_HH = ' '.join(['3(R8 -8 R8)'] * 4)
HT_HH_O4 = ' '.join(['3(R8 -8 R8)'] * 3) + ' 3(R8 -8 -8)'
HT_HO = '-2. 3(-8 -8 R8)'
HT_SN = '-2 L4> -4'
HT_SN_GHOST = '3(-8 L8g -8) 3(-8 L8g -8) 3(L8> -8 -8) 3(-8 L8g -8)'
HT_BD = 'K4 -4 3(-8 -8 K8) -4'  # 1, „3 let"
HT_BD_1L = '3(K8 -8 K8) -4 3(-8 -8 K8) -4'  # dazu „1 let"
HT_BD_4L = '3(K8 -8 K8) -4 3(-8 -8 K8) 3(-8 -8 K8)'  # dazu „4 let"
# Takt 4: Groove Tom-Triole auf 4 (Hängetom R L, Standtom R) · V1 Kick auf „2 let" ·
# V2 Kick-Triole auf 1 (1, „1 trip", „1 let") · V3 Hängetom R L, Kick „4 let" · V4 offene Hat auch auf „2 let", mit Kick.
HT_HH_FILL = ' '.join(['3(R8 -8 R8)'] * 3) + ' -4'
HT_T1_FILL = '-2. 3(R8 L8 -8)'
HT_F1_FILL = '-2. 3(-8 -8 R8)'
HT_BD_2L = 'K4 3(-8 -8 K8) 3(-8 -8 K8) -4'
HT_SN_GHOST_FILL = '3(-8 L8g -8) 3(-8 L8g -8) 3(L8> -8 -8) -4'
HT_BD_1T = '3(K8 K8 K8) -4 3(-8 -8 K8) -4'
HT_HH_O24 = '3(R8 -8 R8) 3(R8 -8 -8) 3(R8 -8 R8) 3(R8 -8 -8)'
HT_HO_24 = '-4 3(-8 -8 R8) -4 3(-8 -8 R8)'
HT_BD_2L_4L = '3(K8 -8 K8) 3(-8 -8 K8) 3(-8 -8 K8) 3(-8 -8 K8)'

HALFTIME_SHUFFLE = GuidedSheet(
    id='guided_kit_halftime_shuffle',
    name='Half-Time Shuffle',
    description='A rolling half-time shuffle: ghost notes inside the triplets, kicks that fill in, an open hat.',
    package='kit', difficulty='advanced',
    default_bpm=80, min_bpm=60, max_bpm=100, grid='triplet',
    groove=rise(dict(HH=HT_HH, SN=HT_SN, BD=HT_BD), HH=HT_HH_FILL, T1=HT_T1_FILL, F1=HT_F1_FILL),
    variations=(
        Variation(rise(dict(HH=HT_HH, SN=HT_SN_GHOST, BD=HT_BD), BD=HT_BD_2L),
                  'Next up: ghosts on the middle note of every triplet, except beat three.', title='Triplet ghost notes'),
        Variation(rise(dict(HH=HT_HH, SN=HT_SN_GHOST, BD=HT_BD_1L), BD=HT_BD_1T),
                  'Now add a kick on the let of one.', title='Kick on let of one'),
        Variation(rise(dict(HH=HT_HH, SN=HT_SN_GHOST, BD=HT_BD_4L),
                       HH=HT_HH_FILL, SN=HT_SN_GHOST_FILL, T1=HT_T1_FILL),
                  'Add one more kick on the let of four, leading into one.', title='Kick on let of four'),
        Variation(rise(dict(HH=HT_HH_O4, HO=HT_HO, SN=HT_SN_GHOST, BD=HT_BD_4L),
                       HH=HT_HH_O24, HO=HT_HO_24, BD=HT_BD_2L_4L),
                  'Last one: open the hi-hat on the let of four, with the kick.', title='Open hat on four',
                  after=None),
    ),
    groove_bars=8, variation_bars=16,
)

# ══ Set · professional: Linear Shift ══════════════════════════════════════════
# Linear: je Sechzehntel genau eine Stimme. Rechte Hand Hi-Hat (+ Standtom),
# linke Hand Snare (+ Hängetom), Kick dazwischen.
_LIN = {'h': ('HH', 'R16'), 'g': ('SN', 'L16g'), 'S': ('SN', 'L16>'), 'K': ('BD', 'K16'),
        'T': ('T1', 'L16>'), 'F': ('F1', 'R16>')}


def lin_bar(pattern: str) -> dict[str, str]:
    """Ein linearer Takt aus 16 Zeichen (h Hat · g Ghost · S Backbeat · K Kick · T Hängetom · F Standtom)."""
    slots = [c for c in pattern if c not in ' |']
    if len(slots) != 16 or any(c not in _LIN for c in slots):
        raise ValueError(f'linear bar needs 16 slots of {"".join(_LIN)}: {pattern!r}')
    out: dict[str, str] = {}
    for key in ('HH', 'T1', 'F1', 'SN', 'BD'):
        if not any(_LIN[c][0] == key for c in slots):
            continue
        toks: list[str] = []
        for b in range(4):
            rest = 0
            for s in range(4):
                tr, tok = _LIN[slots[4 * b + s]]
                if tr == key:
                    if rest:
                        toks += rest_tokens(s * 6 - rest, rest)
                        rest = 0
                    toks.append(tok)
                else:
                    rest += 6
            if rest:
                toks += rest_tokens(TPQ - rest, rest)
        out[key] = ' '.join(toks)
    return out


def lin(pattern: str) -> str:
    """Ein linearer Takt als Spurentext."""
    return kit(**lin_bar(pattern))


def lin_rise(base: str, beat3: str | None = None, beat4: str | None = None) -> str:
    """Vier lineare Takte: dreimal `base`, in Takt 4 Zählzeit 3 und/oder 4 ersetzt (je 4 Zeichen)."""
    beats = base.split('|')
    if beat3 is not None:
        beats[2] = beat3
    if beat4 is not None:
        beats[3] = beat4
    return line4(*[lin_bar(base)] * 3, lin_bar('|'.join(beats)))


# Takt 4: Groove Doppel-Kick „4 +" „4 a" · V1 zweiter Snare-Akzent auf „4 +" ·
# V2 Kick auf „4 a" · V3 Standtom auch auf 4 · V4 Tom-Lauf Standtom „3 e", Hängetom „3 +" und „4 +".
LS_G_BASE = 'K h g K | S h g h | K h h K | S h g h'  # Kick 1, „1 a", 3, „3 a"
LS_1_BASE = 'K h g h | S K g h | K h h K | S h g h'  # Kick „1 a" → „2 e"
LS_2_BASE = 'K h g h | S K g h | K h h K | h S g h'  # Backbeat 4 → „4 e"
LS_3_BASE = 'K h g h | S K g h | K h h K | h S g F'  # „4 a" Standtom-Akzent
LS_4_BASE = 'K h g h | S K g h | K h T K | h S g F'  # „3 +" Hängetom-Akzent
LS_G = lin_rise(LS_G_BASE, beat4='S h K K')
LS_1 = lin_rise(LS_1_BASE, beat4='S h S h')
LS_2 = lin_rise(LS_2_BASE, beat4='h S g K')
LS_3 = lin_rise(LS_3_BASE, beat4='F S g F')
LS_4 = lin_rise(LS_4_BASE, beat3='K F T K', beat4='h S T F')

LINEAR_SHIFT = GuidedSheet(
    id='guided_kit_linear_shift',
    name='Linear Shift',
    description='A linear sixteenth groove where kick and snare shift, then toms take the accents.',
    package='kit', difficulty='professional',
    default_bpm=90, min_bpm=70, max_bpm=110, grid='sixteenth',
    groove=LS_G,
    variations=(
        Variation(LS_1, 'Next up: move the second kick to the e of two.', title='Second kick moves earlier'),
        Variation(LS_2, 'Now push the snare on four one sixteenth later, onto the e.', title='Snare on four later'),
        Variation(LS_3, 'Now play the a of four as an accent on the floor tom.', title='Floor tom accent'),
        Variation(LS_4, 'Last one: on the and of three, left hand plays high tom instead of the hat.', title='High tom replaces hat', after=None),
    ),
    groove_bars=8, variation_bars=20,
)

# ══ Pad · beginner: Accent Walk ═══════════════════════════════════════════════
# Achtel R L; Akzent auf 1 → auf 1 und 3 → auf die „und" → 3-3-2 (1, „2 +", 4).
# Takt 4 nur in Achteln, die Ansage bleibt wahr: Groove Akzente auf 4 und „4 +" ·
# V1–V4 dieselben Akzente, alle übrigen Noten als Ghost Notes (größerer Lautstärke-Abstand).
AW_8 = 'R8 L8 R8 L8 R8 L8 R8 L8'
ACCENT_WALK = GuidedSheet(
    id='guided_pad_accent_walk',
    name='Accent Walk',
    description='Alternating eighths with an accent that walks from the beat onto the offbeats.',
    package='pad', difficulty='beginner',
    default_bpm=90, min_bpm=60, max_bpm=130, grid='eighth',
    groove=rise_pad(AW_8, 'R8 L8 R8 L8 R8 L8 R8> L8>'),
    variations=(
        Variation(rise_pad('R8> L8 R8 L8 R8 L8 R8 L8', 'R8> L8g R8g L8g R8g L8g R8g L8g'),
                  'Next up: accent beat one, keep the other notes soft.', title='Accent on one'),
        Variation(rise_pad('R8> L8 R8 L8 R8> L8 R8 L8', 'R8> L8g R8g L8g R8> L8g R8g L8g'),
                  'Now accent beats one and three.', title='Accents on one and three'),
        Variation(rise_pad('R8 L8> R8 L8> R8 L8> R8 L8>', 'R8g L8> R8g L8> R8g L8> R8g L8>'),
                  'Now accent every and, with your left hand.', title='Left hand accents the ands'),
        Variation(rise_pad('R8> L8 R8 L8> R8 L8 R8> L8', 'R8> L8g R8g L8> R8g L8g R8> L8g'),
                  'Last one: accents on one, the and of two, and four.', title='Mixed accent pattern',
                  after=None),
    ),
    groove_bars=8, variation_bars=20,
)

# ══ Pad · intermediate: Paradiddle Builder ════════════════════════════════════
# Sechzehntel-Singles → Doubles auf 4 → Paradiddle → Akzent vorn → Akzent hinten.
# Takt 4: Groove Akzente auf 4 und „4 +" · V1 Doubles auf 4 akzentuiert (R> R L> L) ·
# V2 Akzent auf 4 · V3 der Akzent auf 4 als Flam · V4 unbetonte Noten als Ghost Notes.
PD = 'R16 L16 R16 R16 L16 R16 L16 L16'  # zwei Paradiddles = zwei Zählzeiten
PARADIDDLE_BUILDER = GuidedSheet(
    id='guided_pad_paradiddle_builder',
    name='Paradiddle Builder',
    description='From sixteenth singles via doubles to paradiddles with moving accents.',
    package='pad', difficulty='intermediate',
    default_bpm=85, min_bpm=60, max_bpm=120, grid='sixteenth',
    groove=rise_pad(' '.join(['R16 L16'] * 8), ' '.join(['R16 L16'] * 6) + ' R16> L16 R16> L16'),
    variations=(
        Variation(rise_pad('R16 L16 R16 L16 R16 L16 R16 L16 R16 L16 R16 L16 R16 R16 L16 L16',
                           'R16 L16 R16 L16 R16 L16 R16 L16 R16 L16 R16 L16 R16> R16 L16> L16'),
                  'Next up: doubles on beat four. Right right, left left.', title='Doubles on beat four'),
        Variation(rise_pad(f'{PD} {PD}', f'{PD} R16 L16 R16 R16 L16> R16 L16 L16'),
                  'Now paradiddles: right left right right, left right left left.', title='Full paradiddles'),
        Variation(rise_pad(' '.join(['R16> L16 R16 R16 L16> R16 L16 L16'] * 2),
                           'R16> L16 R16 R16 L16> R16 L16 L16 R16> L16 R16 R16 L16f> R16 L16 L16'),
                  'Now accent the first note of every paradiddle.', title='Accent the first note'),
        Variation(rise_pad(' '.join(['R16 L16 R16 R16> L16 R16 L16 L16>'] * 2),
                           ' '.join(['R16g L16g R16g R16> L16g R16g L16g L16>'] * 2)),
                  'Last one: move the accent to the last note of each paradiddle.', title='Accent the last note',
                  after=None),
    ),
    groove_bars=8, variation_bars=16,
)

# ══ Pad · advanced: Triplet Flams and Drags ═══════════════════════════════════
# Achteltriolen; Akzent auf der Zählzeit → auf der letzten Triolennote →
# Flams auf der Zählzeit (Flam Accent) → jeder zweite Flam wird ein Drag.
# Takt 4: Groove Akzent auch auf der letzten Triolennote · V1 die Akzente als Flams ·
# V2 + V3 die unbetonten Triolennoten als Ghost Notes.
TRIPLET_FLAMS = GuidedSheet(
    id='guided_pad_triplet_flams',
    name='Triplet Flams and Drags',
    description='Triplets whose accents shift, then turn into flam accents and drags.',
    package='pad', difficulty='advanced',
    default_bpm=80, min_bpm=60, max_bpm=110, grid='triplet',
    groove=rise_pad('3(R8> L8 R8) 3(L8> R8 L8) 3(R8> L8 R8) 3(L8> R8 L8)',
                    '3(R8> L8 R8) 3(L8> R8 L8) 3(R8> L8 R8) 3(L8> R8 L8>)'),
    variations=(
        Variation(rise_pad('3(R8 L8 R8>) 3(L8 R8 L8>) 3(R8 L8 R8>) 3(L8 R8 L8>)',
                           '3(R8 L8 R8f>) 3(L8 R8 L8f>) 3(R8 L8 R8f>) 3(L8 R8 L8f>)'),
                  'Next up: move the accent to the last note of every triplet.', title='Accent the last note'),
        Variation(rise_pad('3(R8f> L8 R8) 3(L8f> R8 L8) 3(R8f> L8 R8) 3(L8f> R8 L8)',
                           '3(R8f> L8g R8g) 3(L8f> R8g L8g) 3(R8f> L8g R8g) 3(L8f> R8g L8g)'),
                  'Now back to accents on the beat, and play them as flams.', title='Flam accents'),
        Variation(rise_pad('3(R8f> L8 R8) 3(L8d> R8 L8) 3(R8f> L8 R8) 3(L8d> R8 L8)',
                           '3(R8f> L8g R8g) 3(L8d> R8g L8g) 3(R8f> L8g R8g) 3(L8d> R8g L8g)'),
                  'Last one: turn the flams on two and four into drags.', title='Drags on two and four',
                  after=None),
    ),
    groove_bars=12, variation_bars=20,
)

# ══ Pad · professional: Fives and Sixes ═══════════════════════════════════════
# Sechzehntel-Singles mit Akzent auf der Zählzeit; Fünfer- und Sechsergruppen über
# zwei Takte, Flam Taps, zuletzt die Fünfer mit Flams auf den Akzenten.
# Takt 4 (5-5-6 bleibt in jedem Takt): Groove Akzent auch auf „4 +" · V1 der Sechser-Akzent als Flam ·
# V2 die beiden Vierer als Flams · V3 die Taps als Ghost Notes · V4 dazu ein Flam auf der letzten Note.


FIVES = (5, 5, 6)  # je Takt: 16 = 5 + 5 + 6, schließt bei der Wiederholung sauber
SIXES = (6, 6, 6, 6, 4, 4)  # zwei Takte: 32 = 4 × 6 + 2 × 4, läuft über den Taktstrich


def grouped(groups: tuple[int, ...], *, flam: bool = False, flam_from: int | None = None,
            last_flam: bool = False) -> str:
    """Sechzehntel R L, Akzent auf der ersten Note jeder Gruppe; Summe = ganze Takte.

    Flam auf den Akzenten: alle (`flam`) oder ab Gruppe Nr. `flam_from`; `last_flam`: die
    letzte Note der Zeile (unbetont) zusätzlich als Flam.
    """
    n = sum(groups)
    if n % 16:
        raise ValueError(f'groups {groups} do not fill whole bars')
    first = 0 if flam else (len(groups) if flam_from is None else flam_from)
    starts = {sum(groups[:k]): k >= first for k in range(len(groups))}
    toks = []
    for i in range(n):
        t = ('R' if i % 2 == 0 else 'L') + '16'
        if i in starts:
            t += 'f>' if starts[i] else '>'
        elif last_flam and i == n - 1:
            t += 'f'
        toks.append(t)
        if i % 16 == 15 and i + 1 < n:
            toks.append('|')
    return ' '.join(toks)


F6_FLAM_TAPS = ' '.join(['R16f> R16 L16f> L16'] * 4)
F6_FLAM_TAPS_GHOST = ' '.join(['R16f> R16g L16f> L16g'] * 4)

FIVES_AND_SIXES = GuidedSheet(
    id='guided_pad_fives_and_sixes',
    name='Fives and Sixes',
    description='Sixteenth accents grouped in fives and sixes, one across the bar line, then flam taps.',
    package='pad', difficulty='professional',
    default_bpm=80, min_bpm=60, max_bpm=110, grid='sixteenth',
    groove=rise_pad(' '.join(['R16> L16 R16 L16'] * 4), ' '.join(['R16> L16 R16 L16'] * 3) + ' R16> L16 R16> L16'),
    variations=(
        Variation(grouped(FIVES * 4, flam_from=len(FIVES) * 4 - 1), 'Next up: accents in groups of five, five, six, every bar.',
                  title='Groups of five and six'),
        Variation(grouped(SIXES * 2, flam_from=2 * len(SIXES) - 2),
                  'Now across two bars: four groups of six, then two of four.', title='Groups across two bars'),
        Variation(' | '.join([F6_FLAM_TAPS] * 3 + [F6_FLAM_TAPS_GHOST]),
                  'Now flam taps: a flam, then a tap with the same hand.', title='Flam taps'),
        Variation(grouped(FIVES * 4, flam=True, last_flam=True),
                  'Last one: back to the five five six accents, now as flams.', title='Fives and sixes as flams',
                  after=None),
    ),
    groove_bars=8, variation_bars=16,
)

SHEETS: list[GuidedSheet] = [
    BACKBEAT_WALK, FUNK_SIXTEENTHS, HALFTIME_SHUFFLE, LINEAR_SHIFT,
    ACCENT_WALK, PARADIDDLE_BUILDER, TRIPLET_FLAMS, FIVES_AND_SIXES,
]


def is_linear(text: str) -> bool:
    """Kein Tick mit zwei Einsätzen über alle Spuren."""
    from sheetlang import parse_kit_line
    seen: set[int] = set()
    for t in parse_kit_line(text).tracks:
        tick = 0
        for n in t.notes:
            if not n.rest:
                if tick in seen:
                    return False
                seen.add(tick)
            tick += n.ticks()
    return True


def bars(s: GuidedSheet) -> int:
    """Geplante Takte wie GuidedExercise.barsAt: Einzähltakt + Abschnitte (ohne Verlängerung)."""
    n = len(s.variations)
    return 1 + n * (s.groove_bars + s.variation_bars) + s.groove_bars + 1


def print_table(sheets: list[GuidedSheet]) -> None:
    check_catalog(sheets)
    for line in [LINEAR_SHIFT.groove] + [v.line for v in LINEAR_SHIFT.variations]:
        if not is_linear(line):
            raise ValueError(f'{LINEAR_SHIFT.id}: not linear:\n{line}')
    for s in sheets:
        sec = round(bars(s) * 4 * 60 / s.default_bpm)
        print(f'{s.id:30s} {s.package:3s}  {s.difficulty:12s} {len(s.variations)} Variationen  '
              f'{bars(s):3d} Takte  {sec // 60}:{sec % 60:02d} bei {s.default_bpm} BPM')
    print(len(sheets), 'Übungen ok')


if __name__ == '__main__':
    print_table(SHEETS)
