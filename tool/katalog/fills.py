"""Die acht Fill-Sticking-Blätter (Katalog Schritt 3b), frei komponiert.

Brief §3.2: je Zeile drei Takte einstimmiges Time-Muster plus ein Takt Fill,
als Vier-Takt-Phrase geloopt; die Band kommt aus dem Loop und läuft im
Fill-Takt weiter. Takt 1 jeder Zeile beginnt mit Akzent — die Eins nach dem
Fill. Jedes Blatt: 8 Zeilen à 4 Takte mit Wiederholung + Challenge 8 Takte
(zweimal 3 + 1). Regel (Uli, 30.09.): so abwechslungsreich und groovy wie
möglich. Notenschrift siehe sheetlang.py. Texte Englisch (App-Sprache).
"""
from __future__ import annotations

from blatt import Sheet, print_table
from sheetlang import Line

# ── Time-Muster (ein Takt, einstimmig). *1 = mit Akzent auf der Eins (Takt 1) ──
Q1, Q = 'R4> L4> R4 L4>', 'R4 L4> R4 L4>'  # Viertel mit Backbeat
E1, E = 'R8> L8 R8 L8 R8 L8 R8 L8', 'R8 L8 R8 L8 R8 L8 R8 L8'  # Achtel
EB1, EB = 'R8> L8 R8> L8 R8 L8 R8> L8', 'R8 L8 R8> L8 R8 L8 R8> L8'  # Achtel, Backbeat
RK1, RK = 'R8> R8 L8> R8 R8 R8 L8> R8', 'R8 R8 L8> R8 R8 R8 L8> R8'  # Rock-Hände
S1 = 'R16> L16 R16 L16 R16> L16 R16 L16 R16 L16 R16 L16 R16> L16 R16 L16'  # Sechzehntel, Backbeat
S = 'R16 L16 R16 L16 R16> L16 R16 L16 R16 L16 R16 L16 R16> L16 R16 L16'
HT1, HT = 'R8> R8 R8 R8 L8> R8 R8 R8', 'R8 R8 R8 R8 L8> R8 R8 R8'  # Half-Time-Hände
G1, G = 'R4> L8 L8 R4 L8 L8', 'R4 L8 L8 R4 L8 L8'  # Galopp
SH1 = '3(R8> -8 R8) 3(L8> -8 R8) 3(R8 -8 R8) 3(L8> -8 R8)'  # Shuffle-Hände
SH = '3(R8 -8 R8) 3(L8> -8 R8) 3(R8 -8 R8) 3(L8> -8 R8)'
DS1, DS = 'R8.> L16 R8.> L16 R8. L16 R8.> L16', 'R8. L16 R8.> L16 R8. L16 R8.> L16'  # harter Shuffle
PD1 = 'R16> L16 R16 R16 L16> R16 L16 L16 R16 L16 R16 R16 L16> R16 L16 L16'  # Paradiddle-Time
PD = 'R16 L16 R16 R16 L16> R16 L16 L16 R16 L16 R16 R16 L16> R16 L16 L16'


def phrase(t1: str, t: str, fill: str) -> str:
    """Drei Takte Time (Takt 1 mit Akzent auf der Eins) und ein Takt Fill."""
    return f'{t1} | {t} | {t} | {fill}'


def challenge(t1: str, t: str, fill_a: str, fill_b: str) -> str:
    return phrase(t1, t, fill_a) + ' | ' + phrase(t1, t, fill_b)


def fill_sheet(**kw) -> Sheet:
    kw.setdefault('line_bars', 4)
    kw.setdefault('new_seed', True)
    kw.setdefault('genres', [])
    return Sheet(**kw)


# ── Blatt 1: Sixteenth Singles ───────────────────────────────────────────────
_SX = [
    'R16 L16 R16 L16 R16 L16 R16 L16 R16 L16 R16 L16 R16 L16 R16 L16',  # ganzer Takt
    'R8 L8 R8 L8 R16 L16 R16 L16 R16 L16 R16 L16',  # halber Takt
    'R16 L16 R16 L16 R8 L8 R16 L16 R16 L16 R8 L8',  # 4 + 2 + 2
    'R16> L16 R16 L16> R16 L16 R16> L16 R16 L16> R16 L16 R16> L16 R16 L16',  # 3-3-3-3-4
    'R8 L8 R8 L8 R8 L8 R16 L16 R16 L16',  # ein Schlag
    'R4> L8 R16 L16 R16 L16 R16 L16 R16 L16 R16 L16',  # Auftakt ab „und von 2"
    'R16 L16 R16 -16 L16 R16 L16 -16 R16 L16 R16 L16 R16 L16 R16 L16',  # Löcher
    'R16 L16 R16 L16 R16 L16 R16 L16 R32 L32 R32 L32 R32 L32 R32 L32 R16 L16 R16 L16',  # 32tel-Ausbruch
]

# ── Blatt 2: Doubles ─────────────────────────────────────────────────────────
_DB = [
    'R16 R16 L16 L16 R16 R16 L16 L16 R16 R16 L16 L16 R16 R16 L16 L16',
    'R8 R8 L8 L8 R16 R16 L16 L16 R16 R16 L16 L16',  # Achtel-Doubles in Sechzehntel-Doubles
    'R8 L8 R8 L8 R16 R16 L16 L16 R16 R16 L16 L16',  # halber Takt
    'R16> R16 L16> L16 R16> R16 L16> L16 R16> R16 L16> L16 R16> R16 L16> L16',  # Akzent je Paar
    'R8 L8 R8 L8 R8 L8 R16 R16 L16 L16',  # ein Schlag
    'R16 R16 L16 L16 R16 L16 R16 L16 R16 R16 L16 L16 R16 L16 R16 L16',  # Doubles/Singles im Wechsel
    'R4> L8 R16 R16 L16 L16 R16 R16 L16 L16 R16 L16',  # Auftakt
    'R16 R16 L16 L16 R16 R16 L16 L16 R32 R32 L32 L32 R32 R32 L32 L32 R16 R16 L16 L16',  # 32tel-Ausbruch
]

# ── Blatt 3: Paradiddle ──────────────────────────────────────────────────────
_PD = [
    'R16 L16 R16 R16 L16 R16 L16 L16 R16 L16 R16 R16 L16 R16 L16 L16',
    'R16> L16 R16 R16 L16> R16 L16 L16 R16> L16 R16 R16 L16> R16 L16 L16',  # akzentuiert
    'R8 L8 R8 L8 R16 L16 R16 R16 L16 R16 L16 L16',  # halber Takt
    'R16 R16 L16 R16 L16 L16 R16 L16 R16 R16 L16 R16 L16 L16 R16 L16',  # Inverted
    'R16> L16 R16 R16 L16 L16 R16> L16 R16 R16 L16 L16 R16> L16 R16 L16',  # Paradiddle-diddle 6-6-4
    'R4> L8 R16 L16 R16 R16 L16 R16 L16 L16 R16 L16',  # Auftakt
    'R16 L16 R16 L16 R16 R16 L16 R16 L16 R16 L16 L16 R16 L16 R16 L16',  # Double Paradiddle 6-6-4
    'R16 L16 R16 R16 L16 R16 L16 L16 R32 L32 R32 R32 L32 R32 L32 L32 R16 L16 R16 R16',  # 32tel
]

# ── Blatt 4: Triplets (Shuffle) ──────────────────────────────────────────────
_TR = [
    '3(R8 L8 R8) 3(L8 R8 L8) 3(R8 L8 R8) 3(L8 R8 L8)',
    '3(R8> L8 R8) 3(L8> R8 L8) 3(R8> L8 R8) 3(L8> R8 L8)',  # Akzent je Schlag
    'R4 L4> 3(R8 L8 R8) 3(L8 R8 L8)',  # halber Takt
    '3(R8> L8 L8) 3(R8> L8 L8) 3(R8> L8 L8) 3(R8> L8 L8)',  # R L L
    'R8. L16 R8.> L16 R8. L16 3(R8 L8 R8)',  # ein Schlag
    'R4> 3(-8 -8 L8) 3(R8 L8 R8) 3(L8 R8 L8)',  # Auftakt
    '3(R8 L8 R8) 3(-8 L8 R8) 3(L8 R8 L8) 3(-8 R8 L8)',  # Löcher
    '3(R8 R8 L8) 3(L8 R8 R8) 3(L8 L8 R8) 3(R8 L8 L8)',  # Doubles in Triolen
]

# ── Blatt 5: Flams ───────────────────────────────────────────────────────────
_FL = [
    'R4f> L4f> R4f> L4f>',
    'R8f L8 R8f L8 R8f L8 R8f L8',  # Flam auf jeder Zählzeit
    'R8f R8 L8f L8 R8f R8 L8f L8',  # Flam Taps
    'R16f L16 R16 L16 R16f L16 R16 L16 R16f L16 R16 L16 R16f L16 R16 L16',  # Flam je Schlag in Sechzehnteln
    'R16 L16 R16 L16 R16 L16 R16 L16 R16 L16 R16 L16 R4f>',  # Lauf in den Flam
    'R16f L16 R16 L16f R16f L16 R16 L16f R16f L16 R16 L16f R16f L16 R16 L16f',  # Pataflafla
    'R4f> -8 L8f R8f -8 L8f R8f',  # synkopierte Flams
    'R8f L16 R16 L8f R16 L16 R8f L16 R16 L8f R16 L16',  # Flam und zwei Sechzehntel
]

# ── Blatt 6: Sextuplets ──────────────────────────────────────────────────────
_X = '6(R16 L16 R16 L16 R16 L16)'
_XA = '6(R16> L16 R16 L16 R16 L16)'
_XP = '6(R16> L16 R16 R16 L16 L16)'
_XR = '6(R16> L16 L16 R16> L16 L16)'
_SE = [
    f'{_X} {_X} {_X} {_X}',
    f'{_XA} {_XA} {_XA} {_XA}',  # Akzent je Schlag
    f'R8 L8 R8 L8 {_X} {_X}',  # halber Takt
    f'R16 L16 R16 L16 {_X} R16 L16 R16 L16 {_X}',  # Sechzehntel und Sextole im Wechsel
    f'{_XP} {_XP} {_XP} {_XP}',  # R L R R L L
    f'R8 L8 R8 L8 R8 L8 {_X}',  # ein Schlag
    f'{_XR} {_XR} {_XR} {_XR}',  # R L L R L L
    f'R4> L8 R8 {_X} {_X}',  # Auftakt
]

# ── Blatt 7: Six-Note Groups ─────────────────────────────────────────────────
_SG = [
    'R16> L16 R16 L16 R16 L16 R16> L16 R16 L16 R16 L16 R16> L16 R16 L16',  # Singles 6-6-4
    'R16> L16 R16 R16 L16 L16 R16> L16 R16 R16 L16 L16 R16> L16 R16 L16',  # Paradiddle-diddle 6-6-4
    'R16> L16 R16 L16 R16> L16 R16 R16 L16 L16 R16> L16 R16 R16 L16 L16',  # 4-6-6
    'R16> L16 R16 L16 R16 R16 L16> R16 L16 R16 L16 L16 R16> L16 R16 L16',  # Double Paradiddle 6-6-4
    'R16> L16 L16 R16> L16 L16 R16> L16 L16 R16> L16 L16 R16> L16 R16 L16',  # R L L 3-3-3-3-4
    'R16> L16 R16 R16 L16 L16 R16> L16 R16 R16 L16 L16 R8> L8',  # 6-6 und zwei Achtel
    'R16> L16 R16 -16 L16 L16 R16> L16 R16 -16 L16 L16 R16> L16 R16 L16',  # Löcher
    'R4> L8 R16> L16 R16 R16 L16 L16 R16> L16 R16 L16',  # Auftakt, 6 + 4
]

# ── Blatt 8: Roll ────────────────────────────────────────────────────────────
_D = 'R32 R32 L32 L32'  # ein Achtel Wirbel
_RO = [
    f'R8 L8 R8 L8 R8 L8 {_D} {_D}',  # Nine Stroke in die Eins
    f'R8 L8 R8 L8 {_D} {_D} {_D} {_D}',  # halber Takt
    f'R16 L16 R16 L16 {_D} {_D} R16 L16 R16 L16 {_D} {_D}',  # zwei kurze Wirbel
    f'{_D} {_D} R8> L8 {_D} {_D} R8> L8',  # Wirbel mit Akzent-Auslauf
    f'R16 R16 L16 L16 R16 R16 L16 L16 {_D} {_D} {_D} {_D}',  # Doubles werden Wirbel
    f'R4> L8 R8 {_D} {_D} {_D} {_D}',  # Auftakt-Wirbel
    f'{_D} {_D} {_D} {_D} {_D} {_D} {_D} {_D}',  # ganzer Takt
    f'R16 L16 R16 L16 R16 L16 R16 L16 {_D} {_D} R32 L32 R32 L32 R32 L32 R32 L32',  # Doubles, dann Singles
]


SHEETS: list[Sheet] = [
    fill_sheet(
        id='fill_sixteenth_singles', name='Sixteenth Singles Fill', min_bpm=60, target_bpm=130,
        difficulty='beginner', skills=['fill', 'control'], count_lines=2, grid='sixteenth',
        description='Three bars of time, then a bar of sixteenth-note singles into the one. The first fill every drummer plays, and the one that has to sound the cleanest.',
        pattern=_SX[0],
        lines=[
            phrase(Q1, Q, _SX[0]),
            phrase(E1, E, _SX[1]),
            phrase(RK1, RK, _SX[2]),
            phrase(S1, S, _SX[3]),
            phrase(EB1, EB, _SX[4]),
            phrase(G1, G, _SX[5]),
            phrase(RK1, RK, _SX[6]),
            phrase(S1, S, _SX[7]),
        ],
        challenge=challenge(RK1, RK, _SX[0], _SX[3]),
        lesson={
            'Why it matters': 'A fill is a sentence with a full stop: it leaves the groove, says something, and lands on the one. Sixteenth singles are the plainest sentence there is, so every flaw shows, and every success does too.',
            'How to play it': 'Play the three time bars exactly as written, hands relaxed, then switch to even R L singles for the fill bar and hit the first note of the next bar with an accent, as if it were a crash. Listen for the landing: the accent on the one should feel inevitable, not early.',
            'Practice tips': 'Keep the band on: the hi-hat keeps counting through the fill, your job is to arrive with it. Line 5 is a one-beat fill, line 6 starts on the "and" of two, line 7 leaves holes. If the one after the fill is late, the fill was too loud or too fast; play it softer first.',
            'Where you hear it': 'Every pop and rock song with a tom fill before the chorus. On the kit the same sticking is spread over snare and toms; at the pad you learn the part that matters, getting out and back in.',
        },
    ),
    fill_sheet(
        id='fill_doubles', name='Doubles Fill', min_bpm=60, target_bpm=120,
        difficulty='beginner', skills=['fill', 'control'], count_lines=2, grid='sixteenth',
        description='Three bars of time and a bar of R R L L. Doubles make a fill sound twice as fast as the hands move, and they are easy to spread over two drums.',
        pattern=_DB[0],
        lines=[
            phrase(Q1, Q, _DB[0]),
            phrase(E1, E, _DB[1]),
            phrase(RK1, RK, _DB[2]),
            phrase(S1, S, _DB[3]),
            phrase(EB1, EB, _DB[4]),
            phrase(G1, G, _DB[5]),
            phrase(RK1, RK, _DB[6]),
            phrase(S1, S, _DB[7]),
        ],
        challenge=challenge(RK1, RK, _DB[0], _DB[3]),
        lesson={
            'Why it matters': 'With doubles, each hand only has to move half as often, so the fill can be fast and still relaxed. On the kit, R R L L is two notes on one drum and two on the next: the simplest way "around the kit".',
            'How to play it': 'Time as written, then R R L L for the fill, the second stroke of each pair as loud as the first. Land on the one with an accent. Listen for the second notes: if they go quiet, the fill thins out and the landing comes early.',
            'Practice tips': 'Line 2 goes from eighth-note doubles into sixteenth doubles, a built-in speed-up. Line 4 accents the first note of every pair, that is what a double sounds like spread across two toms. Line 8 is a short thirty-second-note burst: start it slow.',
            'Where you hear it': 'Classic rock fills, drum corps "diddle" fills, and the first fill most teachers hand out: R R L L down the toms, crash on one.',
        },
    ),
    fill_sheet(
        id='fill_paradiddle', name='Paradiddle Fill', min_bpm=60, target_bpm=120,
        difficulty='intermediate', skills=['fill', 'coordination'], genres=['funk'], grid='sixteenth',
        description='Paradiddles as a fill over a funk band. The double inside each group moves the lead hand, so the fill wanders between the hands without you steering it.',
        pattern=_PD[0],
        lines=[
            phrase(RK1, RK, _PD[0]),
            phrase(E1, E, _PD[1]),
            phrase(S1, S, _PD[2]),
            phrase(RK1, RK, _PD[3]),
            phrase(PD1, PD, _PD[4]),
            phrase(HT1, HT, _PD[5]),
            phrase(EB1, EB, _PD[6]),
            phrase(RK1, RK, _PD[7]),
        ],
        challenge=challenge(RK1, RK, _PD[1], _PD[4]),
        lesson={
            'Why it matters': 'A paradiddle fill does not sound like a roll and not like singles; it has a built-in bounce, because R L R R L R L L mixes both. On the kit it is the funk fill: accents on the snare, the doubles on the toms.',
            'How to play it': 'Time, then R L R R L R L L twice for the fill bar, land on the one. Listen for the accent (line 2): the first note of every group should stick out while the doubles stay low and even.',
            'Practice tips': 'Line 4 is the inverted paradiddle, line 5 plays paradiddle time and then crosses the beat in groups of six, line 7 is the double paradiddle in sixteenths (6 + 6 + 4). Keep the sixteenth hi-hat of the band in your ear, it tells you where the groups sit.',
            'Where you hear it': 'Funk and fusion drumming, Steve Gadd, David Garibaldi. Any fill where the accents seem to dance between snare and toms is probably a paradiddle in disguise.',
        },
    ),
    fill_sheet(
        id='fill_triplets', name='Triplet Fill', min_bpm=60, target_bpm=130,
        difficulty='intermediate', skills=['fill', 'coordination'], grid='triplet',
        description='Triplet fills over a shuffle band. The time is shuffle hands or plain quarters, the fill rolls in threes and lands on the one.',
        pattern=_TR[0],
        lines=[
            phrase(Q1, Q, _TR[0]),
            phrase(SH1, SH, _TR[1]),
            phrase(Q1, Q, _TR[2]),
            phrase(SH1, SH, _TR[3]),
            phrase(DS1, DS, _TR[4]),
            phrase(SH1, SH, _TR[5]),
            phrase(Q1, Q, _TR[6]),
            phrase(SH1, SH, _TR[7]),
        ],
        challenge=challenge(SH1, SH, _TR[0], _TR[3]),
        lesson={
            'Why it matters': 'Triplets roll where sixteenths march. In a shuffle or a 12/8 ballad a triplet fill is the only fill that fits, and it has to come from the same feel as the time, not from a different world.',
            'How to play it': 'Shuffle hands as time: right hand on the first and last note of each triplet, left hand on two and four. For the fill, even R L R L R L triplets, then the accent on the one. Listen for the swing: the fill must keep the band\'s lilt, not straighten it out.',
            'Practice tips': 'Count "1 trip let" out loud at first. Line 4 is the R L L sticking that spreads over three drums, line 5 uses the hard, dotted shuffle as time, line 8 plays doubles inside the triplets. Line 6 starts on the last note of beat two: the band keeps you honest.',
            'Where you hear it': 'Blues shuffles, "Rosanna"-style half-time shuffles, slow rock ballads in 6/8 and 12/8, every triplet fill around the toms.',
        },
    ),
    fill_sheet(
        id='fill_flams', name='Flam Fill', min_bpm=60, target_bpm=110,
        difficulty='intermediate', skills=['fill', 'control'], grid='sixteenth',
        description='Fills built from flams: fat single notes instead of fast ones. A flam fill is slow in the hands and big in the ear.',
        pattern=_FL[0],
        lines=[
            phrase(Q1, Q, _FL[0]),
            phrase(E1, E, _FL[1]),
            phrase(RK1, RK, _FL[2]),
            phrase(S1, S, _FL[3]),
            phrase(EB1, EB, _FL[4]),
            phrase(RK1, RK, _FL[5]),
            phrase(Q1, Q, _FL[6]),
            phrase(S1, S, _FL[7]),
        ],
        challenge=challenge(RK1, RK, _FL[1], _FL[7]),
        lesson={
            'Why it matters': 'Not every fill has to be fast. Four flams on the quarter notes stop a band in its tracks, and a flam on the one after a run is the fattest landing there is.',
            'How to play it': 'Time as written, then flams: the grace note low and just ahead, the main note full height. Alternate the lead hand as marked. Listen for one fat note, not two thin ones; if you hear "ta-ta", the grace note is too high or too early.',
            'Practice tips': 'Line 3 is the flam tap, line 5 runs sixteenths into an accented flam on four, line 6 is the pataflafla (flam on the first and last of four), line 7 puts flams on the off-beats with rests between them. Play everything at a tempo where every flam still sounds like one note.',
            'Where you hear it': 'Marching snare, the big single hits before a chorus in rock and metal, John Bonham\'s flammed fills. Anywhere one note has to sound like a whole drum section.',
        },
    ),
    fill_sheet(
        id='fill_sextuplets', name='Sextuplet Fill', min_bpm=50, target_bpm=100,
        difficulty='advanced', skills=['fill', 'control'], grid='sixteenthTriplet', backing='rock8',
        description='Six notes per beat over a straight band. The sextuplet fill is the fast, rolling fill of rock and fusion; the time around it stays plain eighths.',
        pattern=_SE[0],
        lines=[
            phrase(E1, E, _SE[0]),
            phrase(RK1, RK, _SE[1]),
            phrase(Q1, Q, _SE[2]),
            phrase(S1, S, _SE[3]),
            phrase(RK1, RK, _SE[4]),
            phrase(EB1, EB, _SE[5]),
            phrase(HT1, HT, _SE[6]),
            phrase(RK1, RK, _SE[7]),
        ],
        challenge=challenge(RK1, RK, _SE[1], _SE[4]),
        lesson={
            'Why it matters': 'Sextuplets are the step up from sixteenths: half as much again, with the same hands. A one-bar sextuplet fill at 90 BPM is as fast as most drummers ever need to be, and it has to end on the one as if nothing happened.',
            'How to play it': 'Straight eighths or rock hands as time, then six even singles per beat, accent on the first of each six, land on the one. The band stays in straight eighths on purpose: the sextuplets are the fill, not the feel. Listen for the accents lining up with the hi-hat.',
            'Practice tips': 'Line 4 alternates one beat of sixteenths with one beat of sextuplets, the best way to feel the gear change. Line 5 is R L R R L L (the paradiddle-diddle), line 7 is R L L twice per beat. Start slow enough that six really are six.',
            'Where you hear it': 'Rock and fusion fills, Mike Portnoy, Vinnie Colaiuta, the big tom runs at the end of a chorus. Also the "roll" effect in drum corps when played as singles.',
        },
    ),
    fill_sheet(
        id='fill_six_groups', name='Six-Note Groups Fill', min_bpm=60, target_bpm=110,
        difficulty='advanced', skills=['fill', 'coordination'], genres=['funk'], grid='sixteenth',
        description='Sixteenth-note fills phrased in groups of six: 6 + 6 + 4 over the bar. The accents drift across the beat and pull the listener along.',
        pattern=_SG[0],
        lines=[
            phrase(E1, E, _SG[0]),
            phrase(RK1, RK, _SG[1]),
            phrase(S1, S, _SG[2]),
            phrase(Q1, Q, _SG[3]),
            phrase(EB1, EB, _SG[4]),
            phrase(RK1, RK, _SG[5]),
            phrase(PD1, PD, _SG[6]),
            phrase(HT1, HT, _SG[7]),
        ],
        challenge=challenge(RK1, RK, _SG[1], _SG[3]),
        lesson={
            'Why it matters': 'Sixteen sixteenths split as 6 + 6 + 4 do not sit on the beats; the accents land on 1, the "a" of 2 and the "and" of 3, then the four remaining notes bring you home. That drift is what makes a fill sound modern instead of square.',
            'How to play it': 'Time as written, then the fill with accents exactly where marked: first note of each group of six, and the first note of the final four. Keep everything else low and even. Listen for the accents against the band: they should feel like a slow triplet laid over the groove.',
            'Practice tips': 'Line 1 is plain singles with the 6-6-4 accents, line 2 the paradiddle-diddle, line 3 the same groups turned around (4 + 6 + 6), line 5 R L L in groups of three. Clap the accents alone first, then add the hands.',
            'Where you hear it': 'Funk, fusion and gospel drumming, linear fills, the "over the bar" phrases of Dave Weckl and Jojo Mayer. Once you hear groups of six, you hear them everywhere.',
        },
    ),
    fill_sheet(
        id='fill_roll', name='Roll Fill', min_bpm=60, target_bpm=110,
        difficulty='advanced', skills=['fill', 'control'], grid='thirtySecond',
        description='Closed rolls as fills: thirty-second-note doubles that swell into the one. The classic "snare roll into the chorus".',
        pattern=_RO[0],
        lines=[
            phrase(Q1, Q, _RO[0]),
            phrase(E1, E, _RO[1]),
            phrase(RK1, RK, _RO[2]),
            phrase(S1, S, _RO[3]),
            phrase(EB1, EB, _RO[4]),
            phrase(RK1, RK, _RO[5]),
            phrase(Q1, Q, _RO[6]),
            phrase(S1, S, _RO[7]),
        ],
        challenge=challenge(RK1, RK, _RO[0], _RO[3]),
        lesson={
            'Why it matters': 'A roll is the only fill that gets louder without getting busier. One beat of roll into the one is a nine stroke roll, half a bar is a seventeen, and a whole bar announces a chorus like nothing else.',
            'How to play it': 'Time, then R R L L in thirty-second notes: one wrist stroke per pair, the second note from the rebound, pressed just enough to be even. Land on the one with the accent. Listen for a smooth hum, not a gallop; if you hear the pairs, slow down.',
            'Practice tips': 'Line 1 is the shortest roll (one beat), line 2 half a bar, line 7 the whole bar. Line 4 breaks the roll with accented releases, line 5 grows from sixteenth doubles into the roll, line 8 ends the roll with single-stroke thirty-seconds. Crescendo the long rolls by ear even though the sheet has no dynamics yet.',
            'Where you hear it': 'The snare roll before a chorus, big-band and show drumming, marching cadences, the press roll of a drum corps. Any moment where the band needs a drum roll, literally.',
        },
    ),
]


def all_parsed() -> dict[str, list[Line]]:
    """Alle Blätter geparst und geprüft; wirft bei Fehlern."""
    return {s.id: s.parsed() for s in SHEETS}


if __name__ == '__main__':
    print_table(SHEETS)
