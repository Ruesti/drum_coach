"""Sechs Grooves und ein Hi-Hat-Blatt (Phase B.4), frei komponiert.

Jedes Blatt: 8 Zeilen à 2 Takte mit Wiederholung + Challenge 8 Takte, als
Spuren (sheetlang: `HH: … / SN: … / BD: …`). Zeile 1 ist der Groove der
gleichnamigen Band-Stimme (backing_styles.dart), die Zeilen 2–8 variieren
Kick, Hi-Hat (Akzent, offen), Snare (Ghosts, Cross-Stick) und den Crash
auf der Eins. Regel (Uli, 30.09.): so abwechslungsreich und groovy wie
möglich. Texte Englisch (App-Sprache).
"""
from __future__ import annotations

from blatt import Sheet, print_table


def kit(*bars: dict[str, str]) -> str:
    """Takte als Spur-Dicts → Spurentext; eine Spur, die in einem Takt fehlt, pausiert dort."""
    keys: list[str] = []
    for b in bars:
        for k in b:
            if k not in keys:
                keys.append(k)
    return '\n'.join(f'{k}: ' + ' | '.join(b.get(k, '-1') for b in bars) for k in keys)


# ── Takt-Vokabular (je ein Takt) ─────────────────────────────────────────────
# Hi-Hat / Ride
HH8 = 'R8 R8 R8 R8 R8 R8 R8 R8'
HH8A = 'R8> R8 R8> R8 R8> R8 R8> R8'  # Akzent auf den Zählzeiten
HH8_HT = 'R8> R8 R8 R8 R8> R8 R8 R8'  # Half-time: Akzent auf 1 und 3
HH8_NO1 = '-8 R8 R8 R8 R8 R8 R8 R8'  # die Eins gehört dem Crash
HH8_O4 = 'R8 R8 R8 R8 R8 R8 R8 -8'  # „4 +" offen (HO-Spur)
HH8_O24 = 'R8 R8 R8 -8 R8 R8 R8 -8'  # „2 +" und „4 +" offen
HH8_DISCO = 'R8 -8 R8 -8 R8 -8 R8 -8'  # jedes „+" offen
HH16 = 'R16 L16 R16 L16 R16 L16 R16 L16 R16 L16 R16 L16 R16 L16 R16 L16'
HH16A = 'R16> L16 R16 L16 R16> L16 R16 L16 R16> L16 R16 L16 R16> L16 R16 L16'
HH16_NO1 = '-16 L16 R16 L16 R16 L16 R16 L16 R16 L16 R16 L16 R16 L16 R16 L16'
HH16R = ' '.join(['R16'] * 16)  # nur rechte Hand: die linke ist frei für Ghosts
HH16AR = ' '.join(['R16> R16 R16 R16'] * 4)  # dto., Akzent auf den Zählzeiten
HH16_O = 'R16 L16 R16 L16 R16 L16 R16 -16 R16 L16 R16 L16 R16 L16 R16 -16'  # „a" von 2 und 4 offen
HO_4A = '-2 -4 -8 R8'
HO_2A4A = '-4 -8 R8 -4 -8 R8'
HO_ALL = '-8 R8 -8 R8 -8 R8 -8 R8'
HO_1 = 'R4 -2.'
HO_16 = '-4 -8. R16 -4 -8. R16'  # „a" von 2 und 4
SHUF = '3(R8 -8 R8) 3(R8 -8 R8) 3(R8 -8 R8) 3(R8 -8 R8)'
SHUF_A = '3(R8> -8 R8) 3(R8> -8 R8) 3(R8> -8 R8) 3(R8> -8 R8)'
SHUF_NO1 = '3(-8 -8 R8) 3(R8 -8 R8) 3(R8 -8 R8) 3(R8 -8 R8)'
RIDE_SW = 'R4 3(R8 -8 R8) R4 3(R8 -8 R8)'
RIDE_SW_A = 'R4> 3(R8 -8 R8) R4> 3(R8 -8 R8)'
RIDE8 = 'R8 R8 R8 R8 R8 R8 R8 R8'
HP24 = '-4 P4 -4 P4'
HP1 = 'P4 -4 -2'
HP_ALL = 'P4 P4 P4 P4'
# Snare
SN24 = '-4 L4> -4 L4>'
SN3 = '-2 L4> -4'  # Half-time
SN24G = '-4 L4> -16 L16g -8 L4>'  # Ghost auf „e" von 3
SN24G2 = '-8 L16g -16 L4> -8 L16g -16 L4>'  # Ghosts auf „+" von 1 und 3
SN24G3 = '-16 L16g -8 L4> -16 L16g -8 L4>'  # Ghosts auf „e" von 1 und 3
SN_FUNK = '-4 L4> -8 L16g L16g L4>'  # Ghosts auf „3 +" und „3 a"
SN3G = '-4 -8 L16g L16g L4> -4'  # Ghosts vor der 3
SN24_T = '-4 L4> 3(-8 -8 L8g) L4>'  # Shuffle: Ghost auf „3 let"
SN_SW4 = '-2 -4 3(-8 -8 L8)'  # Swing: „a" von 4
SN_SW2 = '-4 3(-8 -8 L8) -2'  # Swing: „a" von 2
SN_SW3 = '-2 3(L8 -8 L8) -4'
SN_SW24 = '-4 3(-8 -8 L8) -4 3(-8 -8 L8)'
SN_SW2A = '-4 L4> -2'
SN_24_4A = '-4 L4> -4 -8 L8>'
SR3 = '-2 L4 -4'  # Cross-Stick auf 3
SR4 = '-2 -4 L4'
# Kick
BD13 = 'K4 -4 K4 -4'
BD1_3A = 'K4 -4 -8 K8 -4'  # 1 und „3 +"
BD1_2A_3 = 'K4 -8 K8 K4 -4'  # 1, „2 +", 3
BD1_2a_3 = 'K4 -8. K16 K4 -4'  # 1, „2 a", 3
BD_ROCK16 = 'K4 -4 K8 K8 -4'  # 1, 3, „3 +"
BD_R16B = 'K4 -16 K16 -8 K4 -8. K16'  # 1, „2 e", 3, „4 a"
BD_HALF = 'K4 -8 K8 -2'  # 1 und „2 +"
BD_HT2 = 'K4 -8 K8 -4 -8 K8'  # 1, „2 +", „4 +"
BD_FUNK = 'K8. K16 -8 K16 -16 K8. K16 -4'  # 1, „1 a", „2 +", 3, „3 a"
BD_FUNK2 = 'K4 -8. K16 -4 K8 K8'  # 1, „2 a", 4, „4 +"
BD_FUNK3 = 'K8 -8 K8 -8 -4 K8. K16'  # 1, 2, 4, „4 a"
BD_DBL = 'K8 K8 -4 K8 K8 -4'
BD_ALL = 'K4 K4 K4 K4'
BD_SHUF13 = 'K4 -4 3(K8 -8 K8) -4'  # 1, 3, „3 let"
BD_SHUF_ALL = '3(K8 -8 K8) -4 3(K8 -8 K8) -4'
BD_SW = 'K4g K4g K4g K4g'  # feathered: leise Viertel
BD_SW4 = 'K4g K4g K4g 3(K8g -8 K8)'
# Crash
C1_1 = 'R4> -4 -2'

LESSON_ROCK8 = {
    'Why it matters': 'The rock eighth groove is the sentence every other groove is a variation of: hi-hat keeps the eighths, snare marks 2 and 4, the kick says where the song leans. If this one sits, the rest of the kit is details.',
    'How to play it': 'Right hand on the hi-hat, loose wrist, every eighth the same. Left hand hits 2 and 4 as a backbeat — louder than the hi-hat, never rushed. The kick lands under the hi-hat on 1 and 3 so that two sounds become one.',
    'Practice tips': 'Play line 1 until the three limbs feel like one hand. Then take the kick variations slowly; the hi-hat must not flinch when the kick moves. Lines 4 and 7 add the open hat and the crash — keep the backbeat in place.',
    'Where you hear it': 'AC/DC "Back in Black", most of the Beatles, every pop song with a drummer. Count-in, hi-hat, go.',
}


def groove(**kw) -> Sheet:
    kw.setdefault('kit', True)
    kw.setdefault('limbs', ('allFour',))
    kw.setdefault('line_bars', 2)
    kw.setdefault('new_seed', True)
    kw.setdefault('genres', [])
    kw.setdefault('count_lines', 2)
    return Sheet(**kw)


def two(bar: dict[str, str]) -> str:
    return kit(bar, bar)


R8_1 = {'HH': HH8, 'SN': SN24, 'BD': BD13}
R8_2 = {'HH': HH8, 'SN': SN24, 'BD': BD1_3A}
R8_3 = {'HH': HH8, 'SN': SN24, 'BD': BD1_2A_3}
R8_4 = {'HH': HH8_O4, 'HO': HO_4A, 'SN': SN24, 'BD': BD13}
R8_5 = {'HH': HH8, 'SN': SN24G, 'BD': BD13}
R8_6 = {'HH': HH8, 'SN': SN24, 'BD': BD_DBL}
R8_7 = {'C1~': C1_1, 'HH': HH8_NO1, 'SN': SN24, 'BD': BD13}
R8_8 = {'HH': HH8A, 'SN': SN24, 'BD': BD1_2a_3}

R16_1 = {'HH': HH16, 'SN': SN24, 'BD': BD_ROCK16}
R16_3 = {'HH': HH16A, 'SN': SN24, 'BD': BD_ROCK16}
R16_4 = {'HH': HH16, 'SN': SN24, 'BD': BD1_2a_3}
R16_8 = {'HH': HH16, 'SN': SN24, 'BD': BD_R16B}

HT_1 = {'HH': HH8_HT, 'SN': SN3, 'BD': BD_HALF}
HT_3 = {'HH': HH8_HT, 'SN': SN3, 'BD': BD_HT2}
HT_6 = {'HH': HH8_O4, 'HO': HO_4A, 'SN': SN3, 'BD': BD_HALF}
HT_8 = {'HH': HH16, 'SN': SN3, 'BD': BD_HALF}

SH_1 = {'HH': SHUF, 'SN': SN24, 'BD': BD13}
SH_2 = {'HH': SHUF, 'SN': SN24, 'BD': BD_SHUF13}
SH_3 = {'HH': SHUF, 'SN': SN24, 'BD': BD_SHUF_ALL}
SH_8 = {'HH': SHUF_A, 'SN': SN24, 'BD': BD_SHUF_ALL}

SW_1 = {'RD': RIDE_SW, 'HP': HP24, 'BD': BD_SW}
SW_2 = {'RD': RIDE_SW, 'HP': HP24, 'BD': BD_SW, 'SN': SN_SW4}
SW_5 = {'RD': RIDE_SW, 'HP': HP24, 'BD': BD_SW, 'SN': SN_SW2A}
SW_8 = {'RD': RIDE_SW_A, 'HP': HP24, 'BD': BD_SW, 'SN': SN_SW24}

FK_1 = {'HH': HH16A, 'SN': SN24, 'BD': BD_FUNK}
FK_2 = {'HH': HH16AR, 'SN': SN_FUNK, 'BD': BD_FUNK}
FK_4 = {'HH': HH16_O, 'HO': HO_16, 'SN': SN24, 'BD': BD_FUNK}
FK_8 = {'HH': HH16AR, 'SN': SN24G3, 'BD': BD_FUNK2}

HO_L1 = {'HH': HH8_O4, 'HO': HO_4A, 'SN': SN24, 'BD': BD13}
HO_L2 = {'HH': HH8_O24, 'HO': HO_2A4A, 'SN': SN24, 'BD': BD13}
HO_L3 = {'HH': HH8_DISCO, 'HO': HO_ALL, 'SN': SN24, 'BD': BD_ALL}
HO_L7 = {'HH': 'R8 R8 R8 -8 R8 R8 R8 R8', 'HO': '-4 -8 R8 -2', 'SN': SN24, 'BD': BD1_2A_3}

LESSON_ROCK16 = {
    'Why it matters': 'Sixteenths on the hi-hat fill every gap the eighth groove leaves open, so the same backbeat suddenly drives harder. It is the groove of mid-tempo rock and pop where the song needs motion without more speed.',
    'How to play it': 'Alternate R L on the hi-hat. On 2 and 4 the left hand hits the snare together with the right-hand hat note, then jumps straight back for the next sixteenth on the hat. The kick plays 1, 3 and the "and" of 3, always together with a right-hand hi-hat note.',
    'Practice tips': 'Start line 1 slowly enough that the hi-hat stays even through the backbeat; the stroke before and after the snare tends to go quiet. Line 3 accents the quarters on the hat. Line 5 adds a ghost note on the "e" of 3, which falls on a left-hand hat note, so the right hand plays all sixteenths on the hat alone there and the left hand stays on the snare. Line 8 puts the kick on "e" and "a" — count the sixteenths out loud before you play it.',
    'Where you hear it': 'The Doobie Brothers "Long Train Runnin\'", Boz Scaggs "Lowdown" with Jeff Porcaro, and a great many 70s and 80s soft-rock and pop sixteenth-hat grooves.',
}

LESSON_HALFTIME = {
    'Why it matters': 'Half-time keeps the tempo but puts one backbeat in the bar instead of two, on 3. The song suddenly feels twice as wide and heavy without anyone slowing down — the classic move for a big chorus or a slow, crushing riff.',
    'How to play it': 'Hi-hat eighths with an accent on 1 and 3, the snare only on 3, hard and full. The kick plays 1 and the "and" of 2 and leaves the back half of the bar open so the snare can breathe.',
    'Practice tips': 'The danger is rushing the snare on 3: let the space before it hang. Line 4 swaps the backbeat for a cross-stick, line 5 adds ghost notes in front of it, line 8 doubles the hi-hat to sixteenths over the same slow backbeat — big feel, busy surface.',
    'Where you hear it': 'The Police "Walking on the Moon" (Stewart Copeland\'s backbeat on 3), the big half-time choruses of Foo Fighters, countless metal breakdowns and the slow, wide drops of modern pop.',
}

LESSON_SHUFFLE = {
    'Why it matters': 'The shuffle swings the eighths: each beat is a triplet with the middle note left out, long-short, long-short. It is the bounce of blues, boogie and roadhouse rock, and a straight drummer sounds stiff the moment the band starts to shuffle.',
    'How to play it': 'Right hand on the hi-hat plays the first and third note of every triplet, never the middle. Snare on 2 and 4 on the first triplet note, kick on 1 and 3. Keep the short note light so the long one carries.',
    'Practice tips': 'Count "1-trip-let, 2-trip-let" and only play "1" and "let". Line 3 doubles the kick into the shuffle rhythm, line 4 adds a ghost on the "let" of 3, line 6 moves the right hand to the ride while the foot closes the hi-hat on 2 and 4.',
    'Where you hear it': 'Stevie Ray Vaughan "Pride and Joy" with Chris Layton, ZZ Top "La Grange" with Frank Beard, early Fleetwood Mac blues records and every twelve-bar blues jam.',
}

LESSON_SWING = {
    'Why it matters': 'In jazz the ride cymbal is the time: "ding, ding-a-ding" carries the whole band, the hi-hat foot locks 2 and 4, and the snare is free to talk. This is the groove of small-group jazz and big-band swing.',
    'How to play it': 'Ride on every quarter, plus the last triplet note after 2 and after 4 — "ding, ding-a ding, ding-a". The left foot closes the hi-hat on 2 and 4 with a crisp "chick", the kick feathers soft quarters you feel more than hear.',
    'Practice tips': 'Line 1 is ride, hat and feathered kick only — get it light and steady first; line 6 adds one real kick on the "let" of 4 as a pickup into the next bar. Lines 2, 3, 5 and 7 add single snare comments; keep them conversational, not a backbeat. Line 8 accents the ride on 1 and 3 and answers on the "a" of 2 and 4.',
    'Where you hear it': 'Miles Davis "So What" with Jimmy Cobb, Art Blakey and the Jazz Messengers, Count Basie with Sonny Payne, Dave Brubeck "Take Five" in its own 5/4 way — the ride pattern is the same language.',
}

LESSON_FUNK16 = {
    'Why it matters': 'Funk puts the groove in the sixteenths: an accented hat, a snare backbeat that never moves, and a kick that dances around the beat. Ghost notes between the backbeats make it feel alive rather than mechanical.',
    'How to play it': 'Hi-hat sixteenths alternating, accent on every quarter. Snare backbeat on 2 and 4 loud, ghost notes barely touching the head. The kick plays 1, the "a" of 1, the "and" of 2, 3 and the "a" of 3 — syncopated, but every note still lines up with a hat stroke.',
    'Practice tips': 'Play the kick pattern alone against the hat first, then add the backbeat, then the ghosts. Ghosts must be quiet: if they sound like backbeats, the groove collapses. In lines 2, 7 and 8 some ghosts fall on a left-hand hat note, so the right hand plays the sixteenths on the hat alone there and the left hand stays on the snare. Line 4 opens the hat on the "a" of 2 and 4, line 6 moves the second backbeat to the "and" of 4.',
    'Where you hear it': 'James Brown "Cold Sweat" and "Funky Drummer" with Clyde Stubblefield, Tower of Power with David Garibaldi, the Meters with Zigaboo Modeliste, and Red Hot Chili Peppers with Chad Smith.',
}

LESSON_HIHAT_OPEN = {
    'Why it matters': 'The hi-hat is two instruments in one: closed it ticks, open it washes. Opening it on the right note and closing it exactly on the next makes a plain beat breathe — the difference between a drum machine and a drummer.',
    'How to play it': 'Lift the left foot just before the open note so the cymbals ring loosely, then press it down again on the next count so the "chick" lands in time. The open note gets the stick, the close gets the foot; both matter as much as the snare.',
    'Practice tips': 'Line 1 opens only on the "and" of 4, line 2 on both "ands" of 2 and 4, line 3 is the disco beat with every "and" open over four-on-the-floor. Lines 4 and 5 practise the foot alone: a pedal "chick" on 1, then the foot keeping quarters under a ride.',
    'Where you hear it': 'Disco on every offbeat (Chic "Le Freak", Gloria Gaynor "I Will Survive"), the hi-hat barks in AC/DC\'s rock grooves, and Stewart Copeland\'s splashy hats in the Police.',
}

SHEETS: list[Sheet] = [
    groove(
        id='groove_rock8', name='Rock 8ths Groove', min_bpm=60, target_bpm=140,
        difficulty='beginner', skills=['groove', 'coordination'], genres=['rock'], grid='eighth',
        description='Hi-hat eighths, backbeat on 2 and 4, kick on 1 and 3 — the groove the band played for you at the pad. Now you are the band.',
        pattern=kit(R8_1),
        lines=[
            two(R8_1),
            kit(R8_1, R8_2),
            two(R8_3),
            two(R8_4),
            kit(R8_5, {'HH': HH8, 'SN': SN24G, 'BD': BD1_3A}),
            two(R8_6),
            kit(R8_7, R8_3),
            two(R8_8),
        ],
        challenge=kit(R8_1, R8_1, R8_3, R8_3, R8_4, R8_4, R8_8, R8_8),
        lesson=LESSON_ROCK8,
    ),
    groove(
        id='groove_rock16', name='Rock 16ths Groove', min_bpm=60, target_bpm=120,
        difficulty='intermediate', skills=['groove', 'coordination'], genres=['rock'], grid='sixteenth',
        description='Sixteenth notes on the hi-hat with both hands over a rock backbeat — the same groove, twice the motion.',
        pattern=kit(R16_1),
        lines=[
            two(R16_1),
            kit({'HH': HH16, 'SN': SN24, 'BD': BD13}, R16_1),
            two(R16_3),
            two(R16_4),
            two({'HH': HH16R, 'SN': SN24G, 'BD': BD_ROCK16}),
            two({'HH': HH16, 'SN': SN24, 'BD': BD_DBL}),
            kit({'C1~': C1_1, 'HH': HH16_NO1, 'SN': SN24, 'BD': BD_ROCK16}, R16_1),
            two(R16_8),
        ],
        challenge=kit(R16_1, R16_1, R16_3, R16_3, R16_4, R16_4, R16_8, R16_8),
        lesson=LESSON_ROCK16,
    ),
    groove(
        id='groove_halftime', name='Half-time Groove', min_bpm=60, target_bpm=110,
        difficulty='beginner', skills=['groove', 'coordination'], genres=['rock'], grid='eighth',
        description='One backbeat per bar, on 3: the tempo stays, the groove feels twice as big.',
        pattern=kit(HT_1),
        lines=[
            two(HT_1),
            two({'HH': HH8_HT, 'SN': SN3, 'BD': BD13}),
            two(HT_3),
            two({'HH': HH8_HT, 'SR': SR3, 'BD': BD_HALF}),
            two({'HH': HH8_HT, 'SN': SN3G, 'BD': BD_HALF}),
            two(HT_6),
            kit({'C1~': C1_1, 'HH': HH8_NO1, 'SN': SN3, 'BD': BD_HALF}, HT_3),
            two(HT_8),
        ],
        challenge=kit(HT_1, HT_1, HT_3, HT_3, HT_6, HT_6, HT_8, HT_8),
        lesson=LESSON_HALFTIME,
    ),
    groove(
        id='groove_shuffle', name='Shuffle Groove', min_bpm=60, target_bpm=130,
        difficulty='intermediate', skills=['groove', 'coordination'], genres=['rock'], grid='triplet',
        description='Long-short triplet eighths on the hi-hat, backbeat on 2 and 4 — the bounce of blues and boogie rock.',
        pattern=kit(SH_1),
        lines=[
            two(SH_1),
            two(SH_2),
            two(SH_3),
            two({'HH': SHUF, 'SN': SN24_T, 'BD': BD13}),
            kit(SH_1, SH_2),
            two({'RD': SHUF, 'HP': HP24, 'SN': SN24, 'BD': BD13}),
            kit({'C1~': C1_1, 'HH': SHUF_NO1, 'SN': SN24, 'BD': BD13}, SH_2),
            two(SH_8),
        ],
        challenge=kit(SH_1, SH_1, SH_2, SH_2, SH_3, SH_3, SH_8, SH_8),
        lesson=LESSON_SHUFFLE,
    ),
    groove(
        id='groove_swing', name='Swing Ride', min_bpm=60, target_bpm=180,
        difficulty='intermediate', skills=['groove', 'coordination'], genres=['jazz'], grid='triplet',
        description='The jazz ride pattern with the hi-hat foot on 2 and 4 and a feathered kick, plus snare comments in between.',
        pattern=kit(SW_1),
        lines=[
            two(SW_1),
            two(SW_2),
            two({'RD': RIDE_SW, 'HP': HP24, 'BD': BD_SW, 'SN': SN_SW2}),
            two({'RD': RIDE_SW, 'HP': HP24, 'BD': BD_SW, 'SR': SR4}),
            two(SW_5),
            two({'RD': RIDE_SW, 'HP': HP24, 'BD': BD_SW4}),
            two({'RD': RIDE_SW, 'HP': HP24, 'BD': BD_SW, 'SN': SN_SW3}),
            two(SW_8),
        ],
        challenge=kit(SW_1, SW_1, SW_2, SW_2, SW_5, SW_5, SW_8, SW_8),
        lesson=LESSON_SWING,
    ),
    groove(
        id='groove_funk16', name='Funk 16ths Groove', min_bpm=60, target_bpm=110,
        difficulty='advanced', skills=['groove', 'coordination'], genres=['funk'], grid='sixteenth',
        description='Accented sixteenth hats, a syncopated kick and ghost notes around a backbeat that never moves.',
        pattern=kit(FK_1),
        lines=[
            two(FK_1),
            two(FK_2),
            two({'HH': HH16A, 'SN': SN24, 'BD': BD_FUNK2}),
            two(FK_4),
            two({'HH': HH16A, 'SN': SN24G2, 'BD': BD_FUNK}),
            two({'HH': HH16A, 'SN': SN_24_4A, 'BD': BD_FUNK3}),
            kit({'C1~': C1_1, 'HH': HH16_NO1, 'SN': SN24, 'BD': BD_FUNK}, FK_2),
            two(FK_8),
        ],
        challenge=kit(FK_1, FK_1, FK_2, FK_2, FK_4, FK_4, FK_8, FK_8),
        lesson=LESSON_FUNK16,
    ),
    groove(
        id='groove_hihat_open', name='Open Hi-hat', min_bpm=60, target_bpm=130,
        difficulty='intermediate', skills=['groove', 'control'], genres=['rock'], grid='eighth',
        description='Open the hi-hat on the offbeats and close it with the foot right on the next count — from one open note per bar to the disco beat.',
        pattern=kit(HO_L1),
        lines=[
            two(HO_L1),
            two(HO_L2),
            two(HO_L3),
            two({'HH': HH8_O4, 'HO': HO_4A, 'HP': HP1, 'SN': SN24, 'BD': BD13}),
            two({'RD': RIDE8, 'HP': HP_ALL, 'SN': SN24, 'BD': BD13}),
            kit({'HH': HH8_NO1, 'HO': HO_1, 'SN': SN24, 'BD': BD13}, {'HH': HH8, 'SN': SN24, 'BD': BD13}),
            two(HO_L7),
            two({'HH': HH16_O, 'HO': HO_16, 'SN': SN24, 'BD': BD_ROCK16}),
        ],
        challenge=kit(HO_L1, HO_L1, HO_L2, HO_L2, HO_L3, HO_L3, HO_L7, HO_L7),
        lesson=LESSON_HIHAT_OPEN,
    ),
]

if __name__ == '__main__':
    print_table(SHEETS)
