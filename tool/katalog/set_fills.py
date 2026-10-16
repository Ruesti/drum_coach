"""Acht Fill-Blätter mit echter Time und „Rund ums Set" (Phase B.4), frei komponiert.

Die Fill-Takte stammen aus fills.py (Katalog 3b); hier werden sie über
Snare und Toms verteilt (orchestrate), die drei Time-Takte davor sind ein
Groove aus grooves.py, der Fuß hält im Fill-Takt die Time, und die Eins
danach ist ein Crash (jede Zeile wird geloopt: Takt 1 beginnt mit dem
Crash). Texte Englisch (App-Sprache).
"""
from __future__ import annotations

import fills
from blatt import Sheet, print_table
from fills import FILLS
from grooves import (BD13, BD_FUNK, BD_ROCK16, C1_1, HH16A, HH16_NO1, HH8, HH8_NO1, SHUF, SHUF_NO1,
                     SN24, kit)
from sheetlang import TPQ, _parse_token


def orchestrate(fill: str, plan: list[str | None]) -> dict[str, str]:
    """Verteilt einen Fill-Takt beat-weise auf Trommeln: plan[i] = Spur der Zählzeit i (z. B. 'T1~').

    Tuplet-Gruppen bleiben zusammen (sie liegen in einer Zählzeit); eine Note, die eine
    Zählzeit überschreitet, wird abgelehnt. Fuß-Tokens gehen auf eigene Spuren (`K`→'BD',
    `P`→'HP', Seiten bleiben); Hand-Tokens auf plan[i]. Eine Spur bekommt in einer Zählzeit
    nur dann Noten, wenn sie dort spielt, sonst `-4`; in einer gemischten Tuplet-Gruppe
    werden die fremden Tokens zu Pausen gleichen Werts. Ohne Fuß-Tokens: Verhalten wie
    in Teil 1 (jede Plan-Spur, Tokens unverändert).
    """
    beats: list[list[tuple[str, object, int]]] = [[] for _ in range(4)]  # (Token, Note, Gruppe)
    raws: list[list[str]] = [[] for _ in range(4)]
    tick = 0
    tuplet = 0
    group = 0
    has_feet = False
    for raw in fill.split():
        tok = raw
        if tok.startswith(('3(', '6(')):
            tuplet, tok = int(tok[0]), tok[2:]
            group += 1
        closing = tok.endswith(')')
        if closing:
            tok = tok[:-1]
        n = _parse_token(tok)
        n.tuplet = tuplet
        has_feet = has_feet or n.is_foot
        beat, in_beat = divmod(tick, TPQ)
        if beat > 3 or in_beat + n.ticks() > TPQ:
            raise ValueError(f'{tok} crosses beat {beat + 1} in: {fill}')
        beats[beat].append((tok, n, group if tuplet else 0))
        raws[beat].append(raw)
        tick += n.ticks()
        if closing:
            tuplet = 0
    if tick != 4 * TPQ:
        raise ValueError(f'fill is {tick / TPQ:g} quarters long: {fill}')
    if len(plan) != 4:
        raise ValueError(f'plan needs four beats: {plan}')
    if not has_feet:
        for i in range(4):
            if plan[i] is None and any(not n.rest for _, n, _ in beats[i]):
                raise ValueError(f'beat {i + 1}: plan entry is None but the fill has hand notes there')
        out: dict[str, str] = {}
        for drum in dict.fromkeys(d for d in plan if d is not None):
            out[drum] = ' '.join(' '.join(raws[i]) if plan[i] == drum else '-4' for i in range(4))
        return out

    groups = [{g for _, _, g in b if g} for b in beats]
    if any(groups[i] & groups[j] for i in range(4) for j in range(i + 1, 4)):
        raise ValueError(f'a tuplet group straddles a beat in: {fill}')

    def track_of(i: int, n) -> str | None:
        if n.rest:
            return None
        if n.is_foot:
            return 'BD' if n.hand == 'K' else 'HP'
        if not plan[i]:
            raise ValueError(f'beat {i + 1} has hand notes but no drum in plan {plan}: {fill}')
        return plan[i]

    playing = [{track_of(i, n) for _, n, _ in beats[i]} - {None} for i in range(4)]
    order = [plan[i] for i in range(4) if plan[i] in playing[i]]
    order += [t for t in ('BD', 'HP') if any(t in p for p in playing)]
    out = {}
    for track in dict.fromkeys(order):
        bars = []
        for i in range(4):
            if track not in playing[i]:
                bars.append('-4')
                continue
            bars.append(_beat_for(track, i, beats[i], track_of))
        out[track] = ' '.join(bars)
    return out


_RESTS = [(24, '-4'), (18, '-8.'), (12, '-8'), (9, '-16.'), (6, '-16'), (3, '-32')]


def rest_tokens(pos: int, length: int) -> list[str]:
    """Pausen für `length` Ticks ab Position `pos` in der Zählzeit, möglichst wenige Zeichen."""
    out = []
    while length:
        for v, tok in _RESTS:
            aligned = {24: pos % 24 == 0, 18: pos % 24 in (0, 6), 12: pos % 6 == 0, 6: pos % 6 == 0}.get(v, True)
            if v <= length and aligned:
                out.append(tok)
                pos += v
                length -= v
                break
        else:
            raise ValueError(f'no rest for {length} ticks at {pos}')
    return out


def _beat_for(track: str, i: int, items, track_of) -> str:
    """Eine Zählzeit für eine Spur: eigene Tokens, fremde als Pausen (außerhalb von Tuplets verschmolzen)."""
    out: list[str] = []
    pos = 0
    rest = 0  # angesammelte Pause (Ticks) außerhalb von Tuplets

    def flush():
        nonlocal rest
        if rest:
            out.extend(rest_tokens(pos - rest, rest))
            rest = 0

    k = 0
    while k < len(items):
        tok, n, g = items[k]
        if g:
            members = []
            while k < len(items) and items[k][2] == g:
                members.append(items[k])
                k += 1
            ticks = sum(m[1].ticks() for m in members)
            if any(track_of(i, m[1]) == track for m in members):
                flush()
                toks = [m[0] if track_of(i, m[1]) == track else
                        ('-' + str(m[1].value) + ('.' if m[1].dotted else '')) for m in members]
                toks[0] = f'{n.tuplet}(' + toks[0]
                toks[-1] += ')'
                out.extend(toks)
            else:
                rest += ticks
            pos += ticks
            continue
        if track_of(i, n) == track:
            flush()
            out.append(tok)
        else:
            rest += n.ticks()
        pos += n.ticks()
        k += 1
    flush()
    return ' '.join(out)


# Trommel-Pläne je Zeile (Zählzeit 1–4). Toms und Crash immer mit `~` (Instrument-Klasse).
PLANS: list[list[str]] = [
    ['SN', 'SN', 'T1~', 'F1~'],
    ['SN', 'T1~', 'T2~', 'F1~'],
    ['SN', 'SN', 'SN', 'T1~'],
    ['T1~', 'T1~', 'F1~', 'F1~'],
    ['SN', 'SN', 'SN', 'F1~'],
    ['SN', 'T1~', 'SN', 'F1~'],
    ['T1~', 'T2~', 'F1~', 'F2~'],
    ['SN', 'T1~', 'F1~', 'SN'],
]

GROOVES: dict[str, tuple[dict[str, str], dict[str, str]]] = {  # (Takt 1 mit Crash, Time-Takt)
    'rock8': ({'C1~': C1_1, 'HH': HH8_NO1, 'SN': SN24, 'BD': BD13}, {'HH': HH8, 'SN': SN24, 'BD': BD13}),
    'rock16': ({'C1~': C1_1, 'HH': HH16_NO1, 'SN': SN24, 'BD': BD_ROCK16},
               {'HH': HH16A, 'SN': SN24, 'BD': BD_ROCK16}),
    'funk16': ({'C1~': C1_1, 'HH': HH16_NO1, 'SN': SN24, 'BD': BD_FUNK}, {'HH': HH16A, 'SN': SN24, 'BD': BD_FUNK}),
    'shuffle': ({'C1~': C1_1, 'HH': SHUF_NO1, 'SN': SN24, 'BD': BD13}, {'HH': SHUF, 'SN': SN24, 'BD': BD13}),
}


def fill_bar(fill: str, plan: list[str | None]) -> dict[str, str]:
    """Der Fill-Takt als Spuren; hat der Fill keine eigene Kick, hält der Fuß 1 und 3."""
    bar = orchestrate(fill, plan)
    if 'BD' not in bar:
        bar['BD'] = BD13
    return bar


def phrase(groove: str, fill: str, plan: list[str | None]) -> str:
    first, time = GROOVES[groove]
    return kit(first, time, time, fill_bar(fill, plan))


_PAD = {s.id: s for s in fills.SHEETS}


def set_fill(pad_id: str, *, groove: str, name: str, description: str, lesson: dict[str, str], **kw) -> Sheet:
    """Kit-Fassung des Pad-Blatts pad_id: Tempo, Stufe und Raster wie das Original."""
    fills_ = FILLS[pad_id]
    pad = _PAD[pad_id]
    kw.setdefault('min_bpm', pad.min_bpm)
    kw.setdefault('target_bpm', pad.target_bpm)
    kw.setdefault('difficulty', pad.difficulty)
    kw.setdefault('grid', pad.grid)
    kw.setdefault('kit', True)
    kw.setdefault('limbs', ('allFour',))
    kw.setdefault('line_bars', 4)
    kw.setdefault('new_seed', True)
    kw.setdefault('genres', [])
    kw.setdefault('skills', ['fill', 'coordination'])
    return Sheet(
        id='set_' + pad_id, name=name, description=description, lesson=lesson,
        pattern=kit({**orchestrate(fills_[0], PLANS[0]), 'BD': BD13}),
        lines=[phrase(groove, fills_[i], PLANS[i]) for i in range(8)],
        **kw,
    )


# ── Rund ums Set ─────────────────────────────────────────────────────────────
_S4 = 'R16 L16 R16 L16'
_AROUND: list[tuple[str, str, list[str]]] = [  # (Becken auf der Eins, Figur, Plan)
    ('C1~', ' '.join([_S4] * 4), ['SN', 'T1~', 'T2~', 'F1~']),
    ('C1~', ' '.join([_S4] * 4), ['T1~', 'T2~', 'F1~', 'F2~']),
    ('C1~', ' '.join(['R16 L16 R16 R16 L16 R16 L16 L16'] * 2), ['SN', 'T1~', 'SN', 'F1~']),
    ('CH~', ' '.join(['6(R16 L16 R16 L16 R16 L16)'] * 4), ['SN', 'T1~', 'T2~', 'F1~']),
    ('CH~', 'R16> L16 R16 L16 R16 L16 R16> L16 R16 L16 R16 L16 R16> L16 R16 L16', ['SN', 'SN', 'T1~', 'F1~']),
    ('CH~', ' '.join(['R16 R16 L16 L16'] * 4), ['T1~', 'T1~', 'F1~', 'F2~']),
    ('RB', 'R4f> L4f> R4f> L4f>', ['SN', 'T1~', 'F1~', 'F2~']),
    ('RB', f'{_S4} {_S4} R32 L32 R32 L32 R32 L32 R32 L32 {_S4}', ['SN', 'T1~', 'F1~', 'F2~']),
]


def _around_bars(i: int) -> tuple[dict[str, str], dict[str, str]]:
    cym, figure, plan = _AROUND[i]
    first = {cym: 'R4> -4 -2' if cym == 'RB' else C1_1, 'HH': HH8_NO1, 'SN': SN24, 'BD': BD13}
    return first, {**orchestrate(figure, plan), 'BD': BD13}


# ── Lektionen ────────────────────────────────────────────────────────────────
_TOMS = ('Toms accept any tom and the crash any crash, so a kit with fewer drums plays the sheet too: '
         'the mid tom and the second floor tom go to the nearest tom you have.')

LESSON_SIXTEENTHS = {
    'Why it matters': 'At the pad ("Sixteenth Singles Fill") you learned to leave the groove and land on the one. On the kit the same singles travel over snare and toms, the kick keeps 1 and 3 going underneath, and the one after the fill is a crash with the kick: exactly what the band hears.',
    'How to play it': 'Three bars of rock eighths: hi-hat eighths, snare on 2 and 4, kick on 1 and 3; bar 1 starts with the crash instead of the hi-hat. In the fill bar both hands leave the hat. Line 1 plays two beats on the snare, beat 3 on the high tom, beat 4 on the floor tom, and the right hand starts every drum. The kick does not stop: 1 and 3, under the fill too.',
    'Practice tips': 'Line 2 walks down one drum per beat (snare, high tom, mid tom, floor tom) and doubles from eighths to sixteenths halfway. Line 4 puts the accents in threes across high tom and floor tom; line 7 visits all four toms and leaves holes. Line 8 plays the thirty-second burst on the floor tom and comes back to the snare for beat 4. If the crash is late, play the fill on the snare alone first, like the pad sheet, then add the toms. ' + _TOMS,
    'Where you hear it': 'The tom run before the chorus in nearly every rock and pop song; the tom break in "In the Air Tonight" is the famous example.',
}

LESSON_DOUBLES = {
    'Why it matters': 'R R L L on the kit is two notes on one drum before the hands move on, so the fill can travel fast while each hand moves only once per pair. It is the pad sheet "Doubles Fill" with drums under it.',
    'How to play it': 'Rock eighths for three bars, crash on the one of bar 1. In the fill bar line 1 plays two beats of doubles on the snare, beat 3 on the high tom and beat 4 on the floor tom; the kick keeps 1 and 3. Both notes of a pair go on the same drum and sound equally loud, then the next pair moves.',
    'Practice tips': 'Line 2 starts with eighth-note doubles on snare and high tom and switches to sixteenth doubles on mid tom and floor tom. Line 4 accents the first note of every pair between high tom and floor tom; line 7 starts with an accented quarter on the high tom and runs down mid tom, floor tom and second floor tom. Line 8 puts the thirty-second doubles on the floor tom and returns to the snare. ' + _TOMS,
    'Where you hear it': 'Classic rock fills and the first fill most teachers hand out: R R L L down the toms, crash on one.',
}

LESSON_PARADIDDLE = {
    'Why it matters': 'A paradiddle around the kit is the funk fill: the double inside each group hands the lead to the other hand, so the accents dance between drums without you steering them. It is the pad sheet "Paradiddle Fill" orchestrated.',
    'How to play it': 'Three bars of funk sixteenths: accented hi-hat sixteenths, backbeat on 2 and 4, kick on 1, the "a" of 1, the "and" of 2, 3 and the "a" of 3; bar 1 begins with the crash. In the fill bar the kick simplifies to 1 and 3. Line 1 plays the first paradiddle on the snare, then R L R R on the high tom and L R L L on the floor tom, one group per beat.',
    'Practice tips': 'Line 2 accents the first note of every group and walks snare, high tom, mid tom, floor tom, so each accent opens a new drum. Line 4 is the inverted paradiddle on high tom and floor tom, line 5 the paradiddle-diddle on the snare with the last four on the floor tom, line 7 the double paradiddle over all four toms. Back to the funk kick right after the crash: that switch is the hard part. ' + _TOMS,
    'Where you hear it': 'Funk and fusion drumming, Steve Gadd, David Garibaldi: fills where the accents seem to jump between snare and toms.',
}

LESSON_TRIPLETS = {
    'Why it matters': 'In a shuffle only a triplet fill fits, and on the kit the triplets roll down the toms in the same lilt as the hi-hat. This is the pad sheet "Triplet Fill" with the shuffle groove around it.',
    'How to play it': 'Three bars of shuffle: the hi-hat plays the first and last note of each triplet, snare on 2 and 4, kick on 1 and 3; bar 1 opens with the crash. In line 1 the fill plays two beats of triplets on the snare, beat 3 on the high tom and beat 4 on the floor tom, one triplet per drum, while the kick keeps 1 and 3.',
    'Practice tips': 'Line 4 is R L L twice on the high tom and twice on the floor tom: the right hand leads every drum change. Line 5 plays the dotted shuffle on the snare and ends with one triplet on the floor tom. Line 7 travels all four toms with a rest at the start of beats 2 and 4, line 8 plays doubles inside the triplets, snare, high tom, floor tom and back to the snare. Count "1 trip let" until the fill swings like the hat. ' + _TOMS,
    'Where you hear it': 'Blues shuffles, slow 12/8 ballads and every triplet tom fill in a swung rock song.',
}

LESSON_FLAMS = {
    'Why it matters': 'Flams on the toms are the biggest sound a fill can make with slow hands. The pad sheet "Flam Fill" taught the fat single note; here each flam lands on a drum, and on 1 and 3 together with the kick.',
    'How to play it': 'Rock eighths for three bars, crash on the one of bar 1. Line 1 plays four flammed quarters: snare, snare, high tom, floor tom. Grace note low and just ahead on the same drum as the main note, main note full height, the kick on 1 and 3 in unison with the flams.',
    'Practice tips': 'Line 2 puts a flam on every beat on a new drum, snare down to floor tom. Line 5 runs sixteenths on the snare and answers with one accented flam on the floor tom on 4. Line 6 is the pataflafla split over snare, high tom, snare and floor tom; line 7 places the syncopated flams on all four toms with rests between. Every flam must still sound like one note when the drum changes. ' + _TOMS,
    'Where you hear it': 'John Bonham\'s flammed tom fills, the big single hits before a chorus in rock and metal, marching drum lines.',
}

LESSON_SEXTUPLETS = {
    'Why it matters': 'Sextuplets down the toms are the fast, rolling fill of rock and fusion. The pad sheet "Sextuplet Fill" gave you six even notes per beat; on the kit they have to change drums on the beat and still meet the kick and the crash on time.',
    'How to play it': 'Three bars of rock eighths, crash on the one of bar 1. In line 1 two beats of sextuplets sit on the snare, beat 3 on the high tom, beat 4 on the floor tom. The kick plays 1 and 3 together with the first note of each six. Change drums with the right hand on the first note of the beat.',
    'Practice tips': 'Line 2 accents each six and walks snare, high tom, mid tom, floor tom. Line 4 swaps sixteenths and sextuplets on the high tom, then again on the floor tom: the gear change happens on one drum. Line 5 is R L R R L L on the snare for three beats and on the floor tom for beat 4, line 7 R L L R L L over all four toms. Start slow enough that six really are six. ' + _TOMS,
    'Where you hear it': 'Rock and fusion tom runs at the end of a chorus, Mike Portnoy, Vinnie Colaiuta.',
}

LESSON_SIX_GROUPS = {
    'Why it matters': 'Groups of six over four beats put the accents on 1, the "and" of 2 and 4, while the drums in this sheet change on the beats. Accent and drum run against each other, and that friction is what makes the fill sound modern. It is the pad sheet "Six-Note Groups Fill" on the kit.',
    'How to play it': 'Three bars of funk sixteenths, crash on the one of bar 1; in the fill bar the kick keeps 1 and 3. Line 1: beats 1 and 2 on the snare with accents on 1 and on the "and" of 2, beat 3 on the high tom, beat 4 on the floor tom with the accent on 4. Accented notes full height, the rest low and even.',
    'Practice tips': 'Line 2 is the paradiddle-diddle over snare, high tom, mid tom and floor tom. Line 4 plays the double paradiddle on high tom and floor tom, the left-hand accent on the "and" of 2. Line 5 is R L L in threes on the snare, accents on 1, the "a" of 1, the "and" of 2 and the "e" of 3, and a group of four on the floor tom. Clap the accents first, then play them on the drums. ' + _TOMS,
    'Where you hear it': 'Funk, fusion and gospel drumming, the over-the-bar phrases of Dave Weckl and Jojo Mayer.',
}

LESSON_ROLL = {
    'Why it matters': 'A roll that moves down the toms turns a crescendo into a fall. The pad sheet "Roll Fill" taught the thirty-second double-stroke roll; on the kit it ends on a crash and the kick holds the time underneath.',
    'How to play it': 'Three bars of rock sixteenths: hi-hat sixteenths with accents on the quarters, backbeat on 2 and 4, kick on 1, 3 and the "and" of 3; bar 1 begins with the crash. In the fill bar the kick plays 1 and 3. Line 1 plays eighths on the snare and the high tom, then one beat of roll on the floor tom into the crash.',
    'Practice tips': 'Toms are softer than a snare: press a little more for an even roll. Line 2 rolls on the mid tom and the floor tom, line 4 breaks the roll with an accented release on the high tom and again on the floor tom, line 7 rolls the whole bar and moves one tom down every beat. Line 8 plays doubles on the floor tom and ends with single thirty-seconds on the snare. ' + _TOMS,
    'Where you hear it': 'The roll into a chorus, big-band and show drumming, and the rolling tom fall at the end of rock ballads.',
}

LESSON_AROUND = {
    'Why it matters': 'Toms and cymbals are where the kit stops being a pad. This sheet sends plain stickings round all four toms and gives each line a different cymbal on the one: crash in lines 1 to 3, china in lines 4 to 6, ride bell in lines 7 and 8. Your hands learn the distances, and the cymbal becomes a choice.',
    'How to play it': 'Each line has two bars: a rock eighths groove with the line\'s cymbal on the one instead of the hi-hat, then the figure, one drum per beat, kick on 1 and 3 underneath. Line 1 plays sixteenths on snare, high tom, mid tom and floor tom; line 2 the same from the high tom down to the second floor tom. Move in a flat arc with the sticks low and arrive on each drum on the beat.',
    'Practice tips': 'Line 3 alternates paradiddles between the snare and the toms. Line 4 plays sextuplets down the toms, line 5 accents 6-6-4 (1, the "and" of 2, and 4) while the drums change on the beats, line 6 is doubles on high tom, floor tom and second floor tom. Line 7 is one flam per drum, line 8 has a beat of thirty-seconds on the floor tom; both return to the ride bell, played with the shoulder of the stick. The china accepts any crash, the toms any tom, so fewer drums work too.',
    'Where you hear it': 'Tom runs at the end of a drum solo, china accents in metal and fusion, and the ride bell on top of rock choruses and Latin grooves.',
}


SHEETS: list[Sheet] = [
    set_fill(
        'fill_sixteenth_singles', groove='rock8', name='Sixteenth Singles Fill (Kit)',
        description='The pad fill spread over snare and toms, with three bars of rock groove before it and a crash on the one after it.',
        lesson=LESSON_SIXTEENTHS,
    ),
    set_fill(
        'fill_doubles', groove='rock8', name='Doubles Fill (Kit)',
        description='The pad doubles over snare and toms: two notes per drum, then move on, crash on the one.',
        lesson=LESSON_DOUBLES,
    ),
    set_fill(
        'fill_paradiddle', groove='funk16', name='Paradiddle Fill (Kit)',
        description='The pad paradiddles over snare and toms after a funk groove, with the kick simplifying to 1 and 3 under the fill.',
        lesson=LESSON_PARADIDDLE,
    ),
    set_fill(
        'fill_triplets', groove='shuffle', name='Triplet Fill (Kit)',
        description='The pad triplets rolling over snare and toms out of a shuffle groove, crash on the one.',
        lesson=LESSON_TRIPLETS,
    ),
    set_fill(
        'fill_flams', groove='rock8', name='Flam Fill (Kit)',
        description='The pad flams spread over snare and toms after a rock groove: big notes, slow hands, crash on the one.',
        lesson=LESSON_FLAMS,
    ),
    set_fill(
        'fill_sextuplets', groove='rock8', name='Sextuplet Fill (Kit)',
        description='The pad sextuplets running down snare and toms over a rock groove, the kick on 1 and 3 underneath.',
        lesson=LESSON_SEXTUPLETS,
    ),
    set_fill(
        'fill_six_groups', groove='funk16', name='Six-Note Groups Fill (Kit)',
        description='The pad groups of six over snare and toms after a funk groove: the accents drift while the drums change on the beat.',
        lesson=LESSON_SIX_GROUPS,
    ),
    set_fill(
        'fill_roll', groove='rock16', name='Roll Fill (Kit)',
        description='The pad rolls moving down snare and toms after a rock sixteenths groove, into a crash on the one.',
        lesson=LESSON_ROLL,
    ),
    Sheet(
        id='set_around_the_kit', name='Around the Kit', min_bpm=60, target_bpm=120,
        difficulty='intermediate', skills=['fill', 'coordination'], genres=[], grid='sixteenth',
        description='Simple stickings around all four toms, one drum per beat, with crash, china or ride bell on the one.',
        pattern=kit(_around_bars(0)[1]),
        lines=[kit(*_around_bars(i)) for i in range(8)],
        lesson=LESSON_AROUND,
        line_bars=2, kit=True, limbs=('allFour',), new_seed=True,
    ),
]

if __name__ == '__main__':
    print_table(SHEETS)
