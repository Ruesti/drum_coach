"""Linear Fill, Double Bass Fill, Linear Groove, Sixteenth Kick Groove, Half-time Shuffle (Phase B.4c).

Die beiden Fill-Blätter bringen ihre Füße selbst mit: Fuß-Tokens im Fill
(`K16`, `K16r`/`K16l`) legt `orchestrate` auf die Kick-Spur, die Hände wandern
wie in set_fills Zählzeit für Zählzeit über Snare und Toms; drei Takte
`rock16` davor, die Eins danach ist ein Crash. Die Grooves: 8 Zeilen à 2 Takte
+ Challenge 8 Takte. Linear = nie zwei Stimmen auf demselben Tick (is_linear).
Regel (Uli, 30.09.): so abwechslungsreich und groovy wie möglich. Texte
Englisch (App-Sprache).
"""
from __future__ import annotations

from blatt import Sheet, print_table
from grooves import (C1_1, HH8, HH8_NO1, HH16R, HP24, SHUF_NO1, SN3, SN24, SN24G, SN24G3, groove, kit, two)
from set_fills import GROOVES, challenge, fill_bar, orchestrate, phrase, rest_tokens  # noqa: F401
from sheetlang import TPQ, KitLine, parse_kit_line


def is_linear(kl: KitLine, bars: set[int] | None = None) -> bool:
    """Kein Tick mit zwei Einsätzen (über alle Spuren); mit `bars` nur in diesen Takten (0-basiert)."""
    seen: set[int] = set()
    for t in kl.tracks:
        tick = 0
        for n in t.notes:
            if not n.rest and (bars is None or tick // (4 * TPQ) in bars):
                if tick in seen:
                    return False
                seen.add(tick)
            tick += n.ticks()
    return True


# ── Linearer Groove ──────────────────────────────────────────────────────────
# Sechzehntel-Indizes 0–15; kein Tick doppelt
LIN_A = {'HH': '-16 R16 -16 R16 -16 R16 R16 -16 R16 R16 -16 R16 -16 R16 R16 R16',
         'SN': '-8 L16g -16 L16> -16 -4 L16g -16 L16> -8.',
         'BD': 'K16 -8. -8 -16 K16 -2'}  # HH 1,3,5,6,8,9,11,13,14,15 · SN 2g,4>,10g,12> · BD 0,7

_LIN_CH = {'h': ('HH', 'R16'), 'H': ('HH', 'R16>'), 'o': ('HO', 'R16'),
           'g': ('SN', 'L16g'), 'S': ('SN', 'L16>'), 'K': ('BD', 'K16')}


def lin(pattern: str) -> dict[str, str]:
    """Ein linearer Takt aus 16 Zeichen (je Sechzehntel eine Stimme, Leerzeichen/| egal).

    h Hi-Hat · H Hi-Hat mit Akzent · o offene Hi-Hat · g Ghost · S Backbeat · K Kick · . Pause
    """
    slots = [c for c in pattern if c not in ' |']
    if len(slots) != 16 or any(c not in _LIN_CH and c != '.' for c in slots):
        raise ValueError(f'linear bar needs 16 slots of {"".join(_LIN_CH)}.: {pattern!r}')
    out: dict[str, str] = {}
    for key in ('HH', 'HO', 'SN', 'BD'):
        if not any(_LIN_CH.get(c, ('',))[0] == key for c in slots):
            continue
        beats = []
        for b in range(4):
            toks, rest = [], 0
            for s in range(4):
                ch = _LIN_CH.get(slots[4 * b + s])
                if ch and ch[0] == key:
                    if rest:
                        toks += rest_tokens((s * 6) - rest, rest)
                        rest = 0
                    toks.append(ch[1])
                else:
                    rest += 6
            if rest:
                toks += rest_tokens(TPQ - rest, rest)
            beats.append(' '.join(toks))
        out[key] = ' '.join(beats)
    return out


LIN_2 = lin('K h g h | S h K h | h K g h | S h g h')  # Kick auf „2 +" und „3 e"
LIN_3 = lin('K K h g | S h g h | K h K h | S h g h')  # Kick-Doppel auf 1 e, Kick auf 3 und „3 +"
LIN_4 = lin('K h g h | K h g h | K h g K | S h g h')  # nur ein Backbeat, auf 4
LIN_5 = lin('K h g h | S g h K | h g K h | S g h h')  # Ghost nach jedem Backbeat
LIN_6A = lin('K h h g | S h h g | K h h g | S h K h')  # Hat-Paare, Ghost auf jedem „a"
LIN_6B = lin('K h g h | S h K K | h h g h | S g K h')  # Kick-Doppel „2 +", „2 a"
LIN_7 = lin('K g h g | S h K h | K g h g | h K h g')  # Backbeat nur auf 2, Ghosts um die Kick
LIN_8 = lin('K h g h | S h h K | h h g h | S h K o')  # Abschluss: offene Hat auf „4 a"

LINEAR_LINES = [
    two(LIN_A),
    two(LIN_2),
    two(LIN_3),
    two(LIN_4),
    two(LIN_5),
    kit(LIN_6A, LIN_6B),
    two(LIN_7),
    kit(LIN_A, LIN_8),
]

# ── Kick-Sechzehntel-Grooves ─────────────────────────────────────────────────
BD_K16A = 'K4 -8. K16 K4 -8. K16'  # 1, „2 a", 3, „4 a"
BD_K16E = 'K4 -16 K16 -8 K4 -16 K16 -8'  # 1, „2 e", 3, „4 e"
BD_K16B = 'K8. K16 -4 K8. K16 -4'  # 1, „1 a", 3, „3 a"
BD_K16C = 'K4 -4 K8. K16 -8 K8'  # 1, 3, „3 a", „4 +"

K16_1 = {'HH': HH8, 'SN': SN24, 'BD': BD_K16A}
K16_2 = {'HH': HH8, 'SN': SN24, 'BD': BD_K16E}
K16_3 = {'HH': HH8, 'SN': SN24, 'BD': BD_K16B}
K16_4 = {'HH': HH8, 'SN': SN24, 'BD': BD_K16C}
K16_5 = {'HH': HH16R, 'SN': SN24G, 'BD': BD_K16A}
K16_6 = {'HH': HH16R, 'SN': SN24G3, 'BD': BD_K16E}
K16_7 = {'HH': HH8, 'SN': SN3, 'BD': BD_K16C}
K16_8A = {'C1~': C1_1, 'HH': HH8_NO1, 'SN': SN24, 'BD': BD_K16A}
K16_8B = {'HH': HH8, 'SN': SN24, 'BD': BD_K16B}

# ── Half-time Shuffle ────────────────────────────────────────────────────────
HTS_HH = '3(R8 -8 R8) 3(R8 -8 R8) 3(R8 -8 R8) 3(R8 -8 R8)'
HTS_SN = '3(-8 L8g -8) 3(-8 L8g -8) 3(L8> -8 L8g) 3(-8 L8g -8)'  # Ghosts auf der Mitte, Backbeat auf 3
HTS_BD = 'K4 3(-8 -8 K8) -2'  # 1 und „let" von 2
HTS_SN_DENSE = '3(-8 L8g L8g) 3(-8 L8g L8g) 3(L8> -8 L8g) 3(-8 L8g L8g)'  # Ghosts auch auf „let"
HTS_SN_FLAM = '3(-8 L8g -8) 3(-8 L8g -8) 3(L8f> -8 L8g) 3(-8 L8g -8)'  # Backbeat als Flam
HTS_BD_4L = 'K4 3(-8 -8 K8) -4 3(-8 -8 K8)'  # dazu „let" von 4
HTS_HH_NO3 = '3(R8 -8 R8) 3(R8 -8 R8) 3(-8 -8 R8) 3(R8 -8 R8)'  # Hat setzt auf 3 aus: die rechte Hand spielt den Vorschlag
HTS_HH_O4 = '3(R8 -8 R8) 3(R8 -8 R8) 3(R8 -8 R8) 3(R8 -8 -8)'  # „let" von 4 offen (HO-Spur)
HTS_HO_4L = '-2. 3(-8 -8 R8)'

HTS_1 = {'HH': HTS_HH, 'SN': HTS_SN, 'BD': HTS_BD}
HTS_2 = {'HH': HTS_HH, 'SN': SN3, 'BD': HTS_BD}
HTS_4 = {'HH': HTS_HH, 'SN': HTS_SN, 'BD': HTS_BD_4L}
HTS_8A = {'C1~': C1_1, 'HH': SHUF_NO1, 'SN': HTS_SN, 'BD': HTS_BD}

# ── Fills mit eigenen Füßen ──────────────────────────────────────────────────
_X4 = lambda s: ' '.join([s] * 4)  # noqa: E731
LINEAR_FILLS: list[tuple[str, list[str | None]]] = [
    (_X4('R16 L16 K16 K16'), ['SN', 'SN', 'T1~', 'F1~']),
    (_X4('R16 L16 R16 K16'), ['SN', 'T1~', 'T2~', 'F1~']),
    (_X4('R16 K16 L16 K16'), ['SN', 'SN', 'F1~', 'F1~']),
    ('R16 L16 K16 R16 L16 K16 R16 L16 K16 R16 L16 K16 R16 L16 K16 K16', ['SN', 'T1~', 'T2~', 'F1~']),
    (_X4('R16 L16 L16 K16'), ['SN', 'T1~', 'F1~', 'F2~']),
    ('R16 L16 K16 K16 R16 L16 R16 K16 R16 L16 K16 K16 R16 L16 R16 K16', ['SN', 'SN', 'T1~', 'F1~']),
    (_X4('R8 K16 K16'), ['T1~', 'T2~', 'F1~', 'F2~']),
    (_X4('6(R16 L16 K16 R16 L16 K16)'), ['SN', 'T1~', 'T2~', 'F1~']),
]

_H = 'R16 L16 R16 L16'  # eine Zählzeit Hände
_F = 'K16r K16l K16r K16l'  # eine Zählzeit Füße
_H6 = '6(R16 L16 R16 L16 R16 L16)'
_F6 = '6(K16r K16l K16r K16l K16r K16l)'
_H32 = 'R32 L32 R32 L32 R32 L32 R32 L32'
DOUBLE_BASS_FILLS: list[tuple[str, list[str | None]]] = [
    (f'{_H} {_H} {_F} {_F}', ['SN', 'T1~', None, None]),
    (f'{_H} {_F} {_F} {_F}', ['SN', None, None, None]),
    (f'{_H} {_H} {_H} {_F}', ['SN', 'T1~', 'F1~', None]),
    (f'{_H} {_F} {_H} {_F}', ['SN', None, 'T1~', None]),
    (f'{_F} {_F} {_H} {_H}', [None, None, 'T1~', 'F1~']),
    (f'{_H6} {_H6} {_F6} {_F6}', ['SN', 'T1~', None, None]),
    (f'{_H32} {_H32} {_F} {_F}', ['SN', 'T1~', None, None]),
    (f'{_F} {_F} {_F} {_F}', [None, None, None, None]),
]


def feet_fill(*, id: str, fills_: list[tuple[str, list[str | None]]], challenge_lines: tuple[int, int],
              **kw) -> Sheet:
    """Fill-Blatt am Set mit eigenen Fuß-Tokens: drei Takte rock16, ein Fill-Takt, Crash auf der Eins."""
    a, b = challenge_lines
    kw.setdefault('kit', True)
    kw.setdefault('line_bars', 4)
    kw.setdefault('new_seed', True)
    kw.setdefault('genres', [])
    return Sheet(
        id=id,
        pattern=kit(fill_bar(*fills_[0])),
        lines=[phrase('rock16', f, p) for f, p in fills_],
        challenge=challenge('rock16', *fills_[a - 1], *fills_[b - 1]),
        **kw,
    )


# ── Lektionen ────────────────────────────────────────────────────────────────
_TOMS = ('Toms accept any tom and the crash any crash, so a kit with fewer drums plays the sheet too.')

LESSON_LINEAR_FILL = {
    'Why it matters': 'A linear fill never plays two things at once: hands and kick take turns, one note per sixteenth. Because the kick fills the gaps, the fill sounds bigger and faster than your hands alone could play it, and it moves around the kit without ever losing the pulse.',
    'How to play it': 'Three bars of rock sixteenths: alternating hi-hat sixteenths with accents on the quarters, snare on 2 and 4, kick on 1, 3 and the "and" of 3; bar 1 starts with the crash. In the fill bar line 1 plays R L kick kick on every beat: the hands on the snare for beats 1 and 2, on the high tom for beat 3 and the floor tom for beat 4, the two kicks on the "and" and the "a". The kick belongs to the fill here, so it does not keep 1 and 3.',
    'Practice tips': 'Say the sticking out loud, "R L K K", before you play it. Line 2 is R L R kick walking snare, high tom, mid tom, floor tom; line 3 alternates hand and kick (R K L K). Line 4 groups R L K in threes over four beats and ends with two kicks, so the accent of the group drifts across the beat. Line 7 is an eighth on the tom and two kicks, line 8 the sextuplet R L K twice per beat. Keep the kicks at the volume of the hands; a booming kick breaks the line. ' + _TOMS,
    'Where you hear it': 'Gospel and fusion drummers build whole solos from hand-foot groupings; the sextuplet R L K in line 8 is the hands-hands-kick triplet that became a John Bonham trademark.',
}

LESSON_DOUBLE_BASS_FILL = {
    'Why it matters': 'In metal the feet take part in the fill: the hands play a beat or two on the drums, then the double bass finishes the bar as a sixteenth roll. It is a huge sound for little hand movement, and it trains the switch between hands and feet that every faster metal fill needs.',
    'How to play it': 'Three bars of rock sixteenths, crash on the one of bar 1. In the fill bar line 1 plays R L R L on the snare for beat 1, on the high tom for beat 2, then the feet take beats 3 and 4 with alternating sixteenths, right foot on every beat and left foot in between. Hands and feet never overlap; the right foot starts on the beat right after the last left-hand note.',
    'Practice tips': 'Line 2 plays one beat of hands and three beats of feet, line 3 three beats of hands and one of feet. Line 4 swaps hands and feet every beat, line 5 starts with the feet and ends with the hands on high tom and floor tom. Line 6 does the same in sextuplets, line 7 puts thirty-seconds in the hands before the feet, and line 8 is a whole bar of feet into the crash. Keep both feet even; if the left foot is weaker, practise line 8 slowly first.',
    'Where you hear it': 'Thrash and death metal: Dave Lombardo with Slayer, Gene Hoglan with Death and Strapping Young Lad, and the hand-and-feet fills of modern metal drummers in almost every breakdown.',
}

LESSON_LINEAR_GROOVE = {
    'Why it matters': 'A linear groove never stacks two sounds: hi-hat, snare and kick each get their own sixteenths. The result is transparent and busy at once, with every note audible, and it is the heart of the funk drumming of the 70s. It also trains you to place every limb exactly, because nothing hides behind a unison.',
    'How to play it': 'Line 1: kick on 1 and the "a" of 2, backbeat on 2 and 4, ghost notes on the "and" of 1 and of 3, and the right hand on the hi-hat on every sixteenth that is left. The hi-hat does not play with the kick or the snare; the left hand plays only the snare.',
    'Practice tips': 'Count sixteenths out loud ("1 e and a") and play line 1 at 60 until it flows. Lines 2 and 3 move the kick ("and" of 2, doubles on "1 e"), line 4 leaves only one backbeat, on 4, line 5 puts a ghost right after each backbeat. Line 6 is two different bars, line 7 keeps the backbeat on 2 only and surrounds the kicks with ghosts, line 8 ends on an open hi-hat on the "a" of 4; close it with the foot on the next one. Ghosts stay barely audible, backbeats loud.',
    'Where you hear it': 'David Garibaldi with Tower of Power ("Oakland Stroke", "What Is Hip?"), Steve Gadd\'s sticking-based grooves such as "50 Ways to Leave Your Lover", and funk and fusion drumming ever since.',
}

LESSON_KICK16_GROOVE = {
    'Why it matters': 'Rock and funk grooves get their personality from where the kick falls between the eighths. Moving one kick to the "e" or the "a" of a beat changes the whole feel while the hands stay the same, and each of these patterns is one you will meet on records.',
    'How to play it': 'Hi-hat eighths and backbeat on 2 and 4 stay fixed. Line 1 puts the kick on 1, the "a" of 2, 3 and the "a" of 4; each "a" is the sixteenth right before the next beat and falls between two hi-hat notes. Heel up, short strokes, and land the "a" exactly halfway between the hat strokes.',
    'Practice tips': 'Line 2 moves the extra kicks to the "e" of 2 and 4, line 3 doubles them on 1 and 3 ("1 a", "3 a"), line 4 plays 1, 3, the "a" of 3 and the "and" of 4. Lines 5 and 6 switch to sixteenth hats, played with the right hand alone so the left hand is free for the ghost notes on the snare, and every kick has a hat partner. Line 7 is half-time with the backbeat on 3, line 8 opens with a crash. Count the sixteenths aloud before you play a line.',
    'Where you hear it': 'Rock and funk records everywhere: Zigaboo Modeliste with the Meters, Jeff Porcaro with Toto, John Bonham with Led Zeppelin and Chad Smith with the Red Hot Chili Peppers all lean on kicks on the "e" and the "a".',
}

LESSON_HALFTIME_SHUFFLE = {
    'Why it matters': 'The half-time shuffle is one of the hardest and most famous grooves on the kit: a shuffle hi-hat, the backbeat only on 3, and ghost notes on the middle triplet notes that fill every gap. When it sits, it rolls like nothing else; when it does not, everyone hears it.',
    'How to play it': 'Right hand on the hi-hat: the first and last note of every triplet, never the middle. Left hand: a soft ghost on the middle triplet note of every beat, except on 3, where it plays the loud backbeat on the beat and a ghost on the "let". The kick plays 1 and the "let" of 2. Ghosts at the lowest height the stick can manage.',
    'Practice tips': 'Line 2 drops the ghosts so you hear the frame: shuffle hat, kick, backbeat on 3. Line 3 makes the ghosts denser, also on the "let" with the hat. Line 4 adds a kick on the "let" of 4, line 5 opens the hi-hat on the "let" of 4, line 6 moves the right hand to the ride while the foot closes the hat on 2 and 4, line 7 plays the backbeat as a flam (the hat skips beat 3, because the right hand plays the grace note), line 8 begins with a crash. Practise the hands alone until the ghosts are even.',
    'Where you hear it': 'Bernard Purdie on Steely Dan "Babylon Sisters" (the Purdie shuffle), Jeff Porcaro on Toto "Rosanna", John Bonham on Led Zeppelin "Fool in the Rain".',
}


SHEETS: list[Sheet] = [
    feet_fill(
        id='set_fill_linear', name='Linear Fill (Kit)', min_bpm=60, target_bpm=120,
        difficulty='intermediate', grid='sixteenth', limbs=('allFour',), skills=['fill', 'coordination'],
        description='Hands and kick take turns, one note per sixteenth, around snare and toms after a rock sixteenths groove.',
        fills_=LINEAR_FILLS, challenge_lines=(1, 4), lesson=LESSON_LINEAR_FILL,
    ),
    feet_fill(
        id='set_fill_double_bass', name='Double Bass Fill (Kit)', min_bpm=60, target_bpm=140,
        difficulty='advanced', grid='sixteenth', limbs=('doubleBass',), skills=['fill', 'endurance'],
        genres=['metal'],
        description='The hands start the fill on snare and toms and both feet finish it with a sixteenth-note roll, crash on the one.',
        fills_=DOUBLE_BASS_FILLS, challenge_lines=(1, 8), lesson=LESSON_DOUBLE_BASS_FILL,
    ),
    groove(
        id='groove_linear', name='Linear Groove', min_bpm=60, target_bpm=120,
        difficulty='intermediate', skills=['groove', 'coordination'], genres=['funk'], grid='sixteenth',
        description='Hi-hat, snare and kick never play together: every sixteenth belongs to one voice, with ghost notes between the backbeats.',
        pattern=kit(LIN_A),
        lines=LINEAR_LINES,
        challenge=kit(LIN_A, LIN_A, LIN_3, LIN_3, LIN_5, LIN_5, LIN_A, LIN_8),
        lesson=LESSON_LINEAR_GROOVE,
    ),
    groove(
        id='groove_kick_sixteenths', name='Sixteenth Kick Groove', min_bpm=60, target_bpm=120,
        difficulty='intermediate', skills=['groove', 'coordination'], genres=['rock', 'funk'], grid='sixteenth',
        description='A steady rock backbeat with the kick on the "e" and "a" between the eighths, from eighth to sixteenth hats.',
        pattern=kit(K16_1),
        lines=[two(K16_1), two(K16_2), two(K16_3), two(K16_4), two(K16_5), two(K16_6), two(K16_7),
               kit(K16_8A, K16_8B)],
        challenge=kit(K16_1, K16_1, K16_2, K16_2, K16_5, K16_5, K16_8A, K16_8B),
        lesson=LESSON_KICK16_GROOVE,
    ),
    groove(
        id='groove_halftime_shuffle', name='Half-time Shuffle', min_bpm=60, target_bpm=110,
        difficulty='advanced', skills=['groove', 'control'], genres=['rock', 'funk'], grid='triplet',
        description='Shuffle hi-hat, backbeat on 3 and ghost notes on the middle triplet notes: the Purdie shuffle.',
        pattern=kit(HTS_1),
        lines=[
            two(HTS_1),
            two(HTS_2),
            two({'HH': HTS_HH, 'SN': HTS_SN_DENSE, 'BD': HTS_BD}),
            two(HTS_4),
            two({'HH': HTS_HH_O4, 'HO': HTS_HO_4L, 'SN': HTS_SN, 'BD': HTS_BD}),
            two({'RD': HTS_HH, 'HP': HP24, 'SN': HTS_SN, 'BD': HTS_BD}),
            two({'HH': HTS_HH_NO3, 'SN': HTS_SN_FLAM, 'BD': HTS_BD}),
            kit(HTS_8A, HTS_1),
        ],
        challenge=kit(HTS_1, HTS_1, HTS_2, HTS_2, HTS_4, HTS_4, HTS_8A, HTS_1),
        lesson=LESSON_HALFTIME_SHUFFLE,
    ),
]


def _check_linear() -> None:
    lin_sheet = next(s for s in SHEETS if s.id == 'groove_linear')
    for i, kl in enumerate(lin_sheet.parsed()):
        if not is_linear(kl):
            raise ValueError(f'groove_linear line {i + 1} is not linear')
    if not is_linear(lin_sheet.pattern_line()):
        raise ValueError('groove_linear pattern is not linear')
    fill_sheet = next(s for s in SHEETS if s.id == 'set_fill_linear')
    for i, kl in enumerate(fill_sheet.parsed()):
        fill_bars = {3} if i < 8 else {3, 7}
        if not is_linear(kl, fill_bars):
            raise ValueError(f'set_fill_linear {"challenge" if i == 8 else f"line {i + 1}"}: fill bar is not linear')
    for s in SHEETS[:2]:
        for i, f in enumerate(s.lines):
            if 'K16' not in f.split('BD:')[1].split('\n')[0]:
                raise ValueError(f'{s.id} line {i + 1}: the fill has no kick of its own')


if __name__ == '__main__':
    print_table(SHEETS)
    _check_linear()
    print('linear ok')
