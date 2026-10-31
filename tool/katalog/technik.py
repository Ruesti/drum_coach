"""Hände-Technik (Trainingsraum Etappe 1): zehn Pad-Blätter, Beginner + Intermediate.

Tradition Stick Control / Gladstone / Möller: erst die Bewegung (Griff, Rückprall,
Schlaghöhen), dann Kontrolle. Jedes Blatt: 8 Zeilen à 4 Takte, ausgeschrieben, von
Zeile 1 nach Zeile 8 schwerer; Takt 4 einer Zeile darf etwas „abheben“. Kein Fill-Takt
(`fill_bar=False`). Lehrtexte englisch (Why / How / Tips / Song examples), Songs nur als Text.
Notenschrift siehe sheetlang.py / README.md.
"""
from __future__ import annotations

from blatt import Sheet, print_table


def x(cell: str, n: int) -> str:
    """Eine Zählzeit-Zelle n-mal hintereinander (nur innerhalb eines Taktes)."""
    return ' '.join([cell] * n)


R16 = 'R16 L16 R16 L16'  # eine Zählzeit Sechzehntel, rechts führt
L16 = 'L16 R16 L16 R16'  # links führt
RR = 'R16 R16 L16 L16'  # Doppelschläge, rechts beginnt
LL = 'L16 L16 R16 R16'

TECH = dict(area='handTechnique', new_seed=True, line_bars=4, fill_bar=False, genres=[])

SHEETS: list[Sheet] = [
    # ───────────────────────── Beginner ─────────────────────────
    Sheet(
        id='tech_grip_rebound', name='Grip & Rebound', min_bpm=60, target_bpm=100,
        difficulty='beginner', skills=['control'], grid='eighth', count_lines=2, **TECH,
        description='Quarters and eighths with a loose grip: throw the stick, let it bounce back, catch it high. '
                    'One hand, the other hand, then both.',
        pattern='R4 L4 R8 L8 R8 L8',
        lines=[
            'R4 -4 R4 -4 | R4 R4 R4 -4 | R4 -4 R4 -4 | R4 R4 R4 R4',
            'L4 -4 L4 -4 | L4 L4 L4 -4 | L4 -4 L4 -4 | L4 L4 L4 L4',
            'R4 L4 R4 L4 | R4 L4 R4 -4 | L4 R4 L4 R4 | L4 R4 L4 -4',
            'R8 R8 R4 R8 R8 R4 | R8 R8 R8 R8 R4 -4 | L8 L8 L4 L8 L8 L4 | L8 L8 L8 L8 L4 -4',
            'R8 L8 R4 L8 R8 L4 | R8 L8 R8 L8 R4 -4 | L8 R8 L4 R8 L8 R4 | L8 R8 L8 R8 L4 -4',
            'R8 L8 R8 L8 R8 L8 R8 L8 | R8 L8 R8 L8 R4 -4 | R8 L8 R8 L8 R8 L8 R8 L8 | R8 L8 R8 L8 R8 L8 R4',
            'R4 R8 L8 R4 R8 L8 | R8 L8 R4 R8 L8 R4 | L4 L8 R8 L4 L8 R8 | L8 R8 L4 L8 R8 L4',
            'R8 R8 L8 L8 R8 R8 L8 L8 | R8 L8 R8 L8 R8 R8 L8 L8 | R8 R8 L8 L8 R8 L8 R8 L8 | R8 R8 L8 L8 R4 -4',
        ],
        lesson={
            'Why': 'Everything you will ever play rests on this: a stick that is thrown, not pushed, and a hand that '
                   'lets it come back. A relaxed rebound saves energy, sounds fuller and keeps your wrists healthy. '
                   'Learn it slowly now and it becomes the instinct under every other exercise.',
            'How': 'Hold the stick about a third from the butt end between thumb and the first joint of the index '
                   'finger; the other fingers wrap loosely, the back fingers just touch. Start with the tip high '
                   '(about 25 cm), let the wrist drop the stick into the pad and let it bounce straight back up to '
                   'the same height. Do not hold it down on the pad. The rest after each stroke is where you check: '
                   'is the stick back up, is the hand still soft?',
            'Tips': 'Watch the stick, not the hand: it should come up by itself. If the stroke sounds choked, your '
                    'grip is too tight at the back. Keep both sticks at the same height and the same angle, the '
                    'left hand copies the right. Lines 4 and 8 put two strokes in one hand: two throws, two '
                    'rebounds, no squeezing.',
            'Song examples': 'Seven Nation Army (The White Stripes): plain quarter notes, every one relaxed. Back in '
                             'Black (AC/DC): Phil Rudd plays easy eighths on the hi-hat for the whole song. '
                             'Billie Jean (Michael Jackson): a steady eighth-note hi-hat that never tightens up.',
        },
    ),
    Sheet(
        id='tech_full_stroke_tap', name='Full Stroke & Tap', min_bpm=60, target_bpm=100,
        difficulty='beginner', skills=['control'], grid='sixteenth', count_lines=2, **TECH,
        description='Two heights, two volumes: full strokes start high and come back high, taps start low and '
                    'stay low. First a whole bar of each, then one hand loud and one soft, then the heights change '
                    'inside one hand.',
        pattern='R8> L8 R8> L8 R8> L8 R8> L8',
        lines=[
            'R4> R4> R4> R4> | R4 R4 R4 R4 | R4> R4> R4> R4> | R4 R4 R4 -4',
            'L4> L4> L4> L4> | L4 L4 L4 L4 | L4> L4> L4> L4> | L4 L4 L4 -4',
            'R8> L8> R8> L8> R8> L8> R8> L8> | R8 L8 R8 L8 R8 L8 R8 L8 | R8> L8> R8> L8> R4> L4> | R8 L8 R8 L8 R4 -4',
            'R8> L8 R8> L8 R8> L8 R8> L8 | R8> L8 R8> L8 R4> -4 | R8> L8 R8> L8 R8> L8 R8> L8 | R8> L8 R8> L8 R8> L8 R4>',
            'R8 L8> R8 L8> R8 L8> R8 L8> | R8 L8> R8 L8> R8 L4> -8 | R8 L8> R8 L8> R8 L8> R8 L8> | R8 L8> R8 L8> R8 L8> -4',
            'R8> L8> R8> L8> R8 L8 R8 L8 | R8 L8 R8 L8 R8> L8> R8> L8> | R8> L8> R8 L8 R8> L8> R8 L8 | R8> L8> R8 L8 R4> -4',
            'R8> L8 R8 L8 R8> L8 R8 L8 | R8> L8 R8 L8 R8> L8 R8> L8 | R8> L8 R8 L8 R8> L8 R8 L8 | R8> L8 R8> L8 R8> L8 R4>',
            f'{x("R16> L16 R16 L16", 4)} | R8> L8 R8 L8 R8> L8 R8 L8 | {x("R16> L16 R16 L16", 4)} | R16> L16 R16 L16 R16> L16 R16 L16 R8> L8 R4>',
        ],
        lesson={
            'Why': 'Dynamics come from height, not from force. A drummer who can place a loud note and a soft note '
                   'side by side, without tensing up, can play accents, ghost notes and every groove that '
                   'breathes. These are the first two of the four basic strokes.',
            'How': 'Full stroke: start high (about 25 cm), throw the stick down, let it rebound all the way back up '
                   'to where it started. Tap: start low (about 3 to 5 cm), play, let it bounce back to the same low '
                   'height. Same loose grip, same motion, only the height changes. Loud and soft notes should have '
                   'the same tone, just a different size.',
            'Tips': 'Freeze after the last note of a bar and look: high hand high, low hand low? Do not let the taps '
                    'creep up next to the full strokes, and do not hit the full strokes harder, just from higher. '
                    'From line 7 on, one hand changes height from note to note: let the stick stop low after '
                    'the loud note, then lift it again in time.',
            'Song examples': 'Ravel\'s Boléro: the snare plays the same rhythm for fifteen minutes and starts as quiet taps. '
                             'When the Levee Breaks (Led Zeppelin): John Bonham\'s backbeat, big full strokes. '
                             'In the Air Tonight (Phil Collins): soft and sparse until the famous fill.',
        },
    ),
    Sheet(
        id='tech_even_singles', name='Even Singles', min_bpm=60, target_bpm=110,
        difficulty='beginner', skills=['control', 'endurance'], grid='sixteenth', count_lines=2, **TECH,
        description='Alternating strokes that sound like one hand: eighths, then a beat of sixteenths that walks '
                    'through the bar, then more and more sixteenths until the whole line is one even stream.',
        pattern='R16 L16 R16 L16 R8 L8 R8 L8 R4',
        lines=[
            'R8 L8 R8 L8 R4 L4 | R8 L8 R8 L8 R8 L8 R4 | R8 L8 R8 L8 R4 L4 | R8 L8 R8 L8 R8 L8 R8 L8',
            'R8 L8 R8 L8 R8 L8 R8 L8 | R8 L8 R8 L8 R8 L8 R4 | L8 R8 L8 R8 L8 R8 L8 R8 | L8 R8 L8 R8 L8 R8 L4',
            f'{R16} R8 L8 R8 L8 R4 | R8 L8 {R16} R8 L8 R4 | R8 L8 R8 L8 {R16} R4 | R8 L8 R8 L8 R8 L8 {R16}',
            f'{x(R16, 2)} R8 L8 R4 | R8 L8 {x(R16, 2)} R4 | {R16} R8 L8 {R16} R4 | R8 L8 {R16} R8 L8 {R16}',
            f'{x(R16, 3)} R4 | R4 {x(L16, 3)} | {x(L16, 3)} L4 | R8 L8 R8 L8 {R16} R4',
            f'{x(R16, 4)} | {x(R16, 3)} R4 | {x(R16, 4)} | {x(R16, 2)} R4 -4',
            f'R8 L8 {R16} R8 L8 {R16} | {R16} R8 L8 {R16} R8 L8 | R8 L8 {R16} R8 L8 {R16} | {x(R16, 2)} R8 L8 R4',
            f'{x(R16, 4)} | R8 {x("L16 R16", 7)} | {x(L16, 4)} | {x(L16, 3)} L4',
        ],
        lesson={
            'Why': 'Single strokes are the most exposed sound in drumming: every uneven note is heard. Making the '
                   'weaker hand match the stronger one is the most important technical habit there is, and it '
                   'starts here, at low volume and low speed.',
            'How': 'Alternate R L R L, both sticks from the same low-to-medium height (about 10 cm), same angle, '
                   'same spot on the pad. Each stroke rebounds back to its starting height. When you switch '
                   'from eighths to sixteenths, the hands do not get higher or tighter, they just move twice as '
                   'often.',
            'Tips': 'Record yourself or listen closely: can you hear which hand is which? Then it is not even yet. '
                    'In line 3 the beat of sixteenths walks through the bar, count it out loud. In line 8 the '
                    'single eighth note at the start of bar 2 flips the lead: from there the left hand leads.',
            'Song examples': 'Wipe Out (The Surfaris): the tom part is a long string of even singles. Sing, Sing, '
                             'Sing (Benny Goodman, Gene Krupa on drums): steady single strokes on the toms. Smells '
                             'Like Teen Spirit (Nirvana): the intro fill is sixteenth-note singles across the drums.',
        },
    ),
    Sheet(
        id='tech_accent_basics', name='Accent Basics', min_bpm=60, target_bpm=100,
        difficulty='beginner', skills=['control'], grid='sixteenth', count_lines=2, **TECH,
        description='Accents on the counts: first only on 1, then on 1 and 3, then on every beat, with the left '
                    'hand leading too, then in sixteenths and finally on the backbeat, 2 and 4.',
        pattern='R8> L8 R8 L8 R8> L8 R8 L8',
        lines=[
            'R8> L8 R8 L8 R8 L8 R8 L8 | R8> L8 R8 L8 R4 -4 | R8> L8 R8 L8 R8 L8 R8 L8 | R8> L8 R8 L8 R8 L8 R4>',
            'R8> L8 R8 L8 R8> L8 R8 L8 | R8> L8 R8 L8 R4> -4 | R8> L8 R8 L8 R8> L8 R8 L8 | R8> L8 R8> L8 R8> L8 R4>',
            'R8> L8 R8> L8 R8> L8 R8> L8 | R8> L8 R8> L8 R4> -4 | R8> L8 R8> L8 R8> L8 R8> L8 | R8> L8 R8> L8 R4> L4>',
            'L8> R8 L8> R8 L8> R8 L8> R8 | L8> R8 L8> R8 L4> -4 | L8> R8 L8> R8 L8> R8 L8> R8 | L8> R8 L8> R8 L4> R4>',
            'R16> L16 R16 L16 R8> L8 R16> L16 R16 L16 R8> L8 | R16> L16 R16 L16 R16> L16 R16 L16 R8> L8 R4> | '
            'R16> L16 R16 L16 R8> L8 R16> L16 R16 L16 R8> L8 | R16> L16 R16 L16 R16> L16 R16 L16 R16> L16 R16 L16 R4>',
            f'{x("R16> L16 R16 L16", 4)} | {x("R16> L16 R16 L16", 3)} R4> | {x("R16> L16 R16 L16", 4)} | '
            f'{x("R16> L16 R16 L16", 2)} R8> L8 R4>',
            f'{x("L16> R16 L16 R16", 4)} | {x("L16> R16 L16 R16", 3)} L4> | {x("L16> R16 L16 R16", 4)} | '
            f'{x("L16> R16 L16 R16", 2)} L8> R8 L4>',
            f'{R16} R16> L16 R16 L16 {R16} R16> L16 R16 L16 | R8 L8 R8> L8 R8 L8 R8> L8 | '
            f'{R16} R16> L16 R16 L16 {R16} R16> L16 R16 L16 | {R16} R16> L16 R16 L16 R16> L16 R16> L16 R4>',
        ],
        lesson={
            'Why': 'An accent tells the listener where the beat is. Before accents can move around, they have to '
                   'sit on the counts, loud and clear, while everything in between stays soft and even. This is '
                   'where a stream of notes turns into music.',
            'How': 'Accented note: a full stroke from high (about 25 cm). Unaccented notes: low taps (about 5 cm). '
                   'Count out loud, "1 and 2 and", and let the accent land exactly on the number. The hand that '
                   'plays the accent lifts early enough to be high in time; the stroke itself is still a throw, '
                   'not a hit.',
            'Tips': 'The notes right after an accent tend to get loud too: keep them down. Accents do not rush, they '
                    'land in time. Lines 4 and 7 put the accents in the left hand, give it the same height. Line 8 '
                    'moves the accent to 2 and 4: the backbeat, the heart of almost every rock and pop groove.',
            'Song examples': 'Superstition (Stevie Wonder): the hi-hat is a stream of sixteenths with the weight on '
                             'the beat. Walk This Way (Aerosmith): the hi-hat intro, accented eighths. Marching band '
                             'snare cadences: every count accented, everything else quiet.',
        },
    ),
    Sheet(
        id='tech_single_hand_control', name='Single-Hand Control', min_bpm=60, target_bpm=96,
        difficulty='beginner', skills=['control', 'endurance'], grid='sixteenth', count_lines=2, **TECH,
        description='One hand alone: quarters, eighths, a galloping rhythm and short bursts of sixteenths, first '
                    'right, then left, then switching hands every bar and every half bar.',
        pattern='R8 R8 R8 R8 R8 R8 R8 R8',
        lines=[
            'R4 R4 R4 R4 | R8 R8 R8 R8 R4 R4 | R4 R4 R4 R4 | R8 R8 R8 R8 R8 R8 R4',
            'L4 L4 L4 L4 | L8 L8 L8 L8 L4 L4 | L4 L4 L4 L4 | L8 L8 L8 L8 L8 L8 L4',
            'R8 R8 R4 -8 R8 R4 | R4 -8 R8 R8 R8 R4 | R8 R8 R8 R8 -8 R8 R4 | -8 R8 R8 R8 R4 -4',
            'L8 L8 L4 -8 L8 L4 | L4 -8 L8 L8 L8 L4 | L8 L8 L8 L8 -8 L8 L4 | -8 L8 L8 L8 L4 -4',
            'R8 R8 R8 R16 R16 R4 R4 | L8 L8 L8 L16 L16 L4 L4 | R8 R16 R16 R8 R8 R8 R16 R16 R4 | '
            'L8 L16 L16 L8 L8 L8 L16 L16 L4',
            'R8 R8 R8 R8 L8 L8 L8 L8 | R8 R8 R8 R8 L8 L8 L4 | R8 R8 L8 L8 R8 R8 L8 L8 | R8 R8 L8 L8 R4 L4',
            'R8 R16 R16 R8 R16 R16 R8 R8 R4 | L8 L16 L16 L8 L16 L16 L8 L8 L4 | '
            'R8 R16 R16 R8 R16 R16 R8 R16 R16 R4 | L8 L16 L16 L8 L16 L16 L8 L16 L16 L4',
            'R16 R16 R16 R16 R4 R16 R16 R16 R16 R4 | L16 L16 L16 L16 L4 L16 L16 L16 L16 L4 | '
            'R16 R16 R16 R16 R16 R16 R16 R16 R8 R8 R4 | L16 L16 L16 L16 L16 L16 L16 L16 L8 L8 L4',
        ],
        lesson={
            'Why': 'When both hands alternate, one can hide behind the other. Alone, each hand has to keep time, '
                   'keep its height and keep relaxed by itself. On the kit one hand often plays the hi-hat or ride '
                   'for minutes while the other does something else: this is where that stamina starts.',
            'How': 'Play from the wrist, stick about 10 cm high, and let every stroke rebound before the next one. '
                   'Faster notes mean a smaller, quicker wrist motion, not a tighter grip. In the sixteenths of '
                   'line 8 the fingers start helping: they close gently to play the note, and the rebound lifts the '
                   'stick back up. The resting '
                   'hand lies still on your leg.',
            'Tips': 'Count out loud, a single hand drifts in time more easily than two. Compare the left hand with '
                    'the right: same sound, same height? If the forearm gets tight, stop, shake out, start again '
                    'slower. Lines 5 and 7 use a gallop (eighth, two sixteenths): keep the eighth note long.',
            'Song examples': 'Back in Black (AC/DC): one hand plays eighths on the hi-hat for the whole song. The '
                             'one-handed sixteenth hi-hat of disco and Motown records. Billie Jean (Michael '
                             'Jackson): a single hand on the hi-hat, steady as a machine.',
        },
    ),
    # ─────────────────────── Intermediate ───────────────────────
    Sheet(
        id='tech_down_up_strokes', name='Down & Up Strokes', min_bpm=60, target_bpm=120,
        difficulty='intermediate', skills=['control'], grid='sixteenth', **TECH,
        description='The accent motion: a down stroke plays the accent and stops low, an up stroke plays a tap and '
                    'lifts the stick for the next accent. One hand first, then alternating sixteenths with the '
                    'accent on 1, e, & and a of the beat.',
        pattern='R16> L16 R16 L16 R16 L16 R16> L16 R16 L16> R16 L16 R16 L16 R16 L16>',
        lines=[
            'R8> R8 R8 R8 R8> R8 R8 R8 | R8> R8 R8 R8 R4> -4 | L8> L8 L8 L8 L8> L8 L8 L8 | L8> L8 L8 L8 L4> -4',
            'R8> R8 R8> R8 R8> R8 R8> R8 | R8> R8 R8> R8 R4> -4 | L8> L8 L8> L8 L8> L8 L8> L8 | L8> L8 L8> L8 L4> -4',
            f'{x("R16> L16 R16 L16", 4)} | {x("R16> L16 R16 L16", 2)} R8> L8 R8> L8 | {x("R16> L16 R16 L16", 4)} | '
            f'{x("R16> L16 R16 L16", 3)} R4>',
            f'{x("R16 L16 R16> L16", 4)} | {x("R16 L16 R16> L16", 2)} R8 L8> R8 L8> | {x("R16 L16 R16> L16", 4)} | '
            f'{x("R16 L16 R16> L16", 3)} R4>',
            f'{x("R16 L16> R16 L16", 4)} | {x("R16 L16> R16 L16", 2)} R8> L8> R4 | {x("R16 L16> R16 L16", 4)} | '
            f'{x("R16 L16> R16 L16", 3)} R4>',
            f'{x("R16> L16 R16 L16>", 4)} | {x("R16> L16 R16 L16>", 2)} R8> L8> R4> | {x("R16> L16 R16 L16>", 4)} | '
            f'{x("R16> L16 R16 L16>", 3)} R4>',
            'R16> L16 R16 L16> R16 L16 R16> L16 R16> L16 R16 L16> R16 L16 R16> L16 | '
            'R16> L16 R16 L16> R16 L16 R16> L16 R16 L16 R16> L16 R8> L8 | '
            'R16> L16 R16 L16> R16 L16 R16> L16 R16> L16 R16 L16> R16 L16 R16> L16 | '
            'R16> L16 R16 L16> R16 L16 R16> L16 R16> L16 R16 L16> R4>',
            f'{x("R16> L16 R16 L16", 4)} | {x("R16 L16> R16 L16", 4)} | {x("R16 L16 R16> L16", 4)} | '
            f'{x("R16 L16 R16 L16>", 3)} R4>',
        ],
        lesson={
            'Why': 'Full strokes and taps alone cannot play an accent pattern at speed: the hand that just played '
                   'loud has to play soft next, and the hand that played soft has to be up in time for the next '
                   'accent. Down and up strokes solve exactly that. Together with full stroke and tap they are the '
                   'four strokes every accent pattern is built from (Moeller, Stone, Gladstone tradition).',
            'How': 'Down stroke: start high, play the accent, and stop the stick low, just above the pad, by '
                   'gently closing the back fingers. No rebound. Up stroke: start low, play a tap, and use that '
                   'little motion to lift the stick high, ready for the next accent. So in R> R R R the right hand '
                   'goes down, tap, tap, up. Every accent is prepared one note earlier.',
            'Tips': 'Say the stroke names while you play line 1: "down, tap, tap, up". The most common fault is '
                    'lifting late, the accent then rushes or comes out weak. Second most common: the stroke after '
                    'the accent bounces up loud, stop it low. Line 8 walks the accent from 1 to e to & to a, one '
                    'bar each.',
            'Song examples': 'Superstition (Stevie Wonder): accents inside a sixteenth-note hi-hat. 50 Ways to Leave '
                             'Your Lover (Paul Simon): Steve Gadd moves accents and soft strokes in one flowing '
                             'motion. Drum-corps snare lines: down and up strokes at full speed.',
        },
    ),
    Sheet(
        id='tech_moving_accents', name='Moving Accents', min_bpm=60, target_bpm=120,
        difficulty='intermediate', skills=['control', 'coordination'], grid='sixteenth', **TECH,
        description='The accent wanders through the sixteenths: bar by bar, beat by beat, forwards and backwards, '
                    'in groups of three across the bar line, in pairs and in a 3-3-2 phrase.',
        pattern='R16> L16 R16 L16 R16 L16> R16 L16 R16 L16 R16> L16 R16 L16 R16 L16>',
        lines=[
            f'{x("R16> L16 R16 L16", 4)} | {x("R16 L16> R16 L16", 4)} | {x("R16> L16 R16 L16", 4)} | '
            f'{x("R16 L16> R16 L16", 3)} R4>',
            f'{x("R16 L16 R16> L16", 4)} | {x("R16 L16 R16 L16>", 4)} | {x("R16 L16 R16> L16", 4)} | '
            f'{x("R16 L16 R16 L16>", 3)} R4>',
            'R16> L16 R16 L16 R16> L16 R16 L16 R16 L16> R16 L16 R16 L16> R16 L16 | '
            'R16 L16 R16> L16 R16 L16 R16> L16 R16 L16 R16 L16> R16 L16 R16 L16> | '
            'R16> L16 R16 L16 R16> L16 R16 L16 R16 L16> R16 L16 R16 L16> R16 L16 | '
            'R16 L16 R16> L16 R16 L16 R16> L16 R16 L16 R16 L16> R4>',
            'R16> L16 R16 L16 R16 L16> R16 L16 R16 L16 R16> L16 R16 L16 R16 L16> | '
            'R16> L16 R16 L16 R16 L16> R16 L16 R16 L16 R16> L16 R4> | '
            'R16> L16 R16 L16 R16 L16> R16 L16 R16 L16 R16> L16 R16 L16 R16 L16> | '
            'R16> L16 R16 L16 R16 L16> R16 L16 R16 L16 R16> L16 R16 L16 R16 L16>',
            'R16 L16 R16 L16> R16 L16 R16> L16 R16 L16> R16 L16 R16> L16 R16 L16 | '
            'R16 L16 R16 L16> R16 L16 R16> L16 R16 L16> R16 L16 R4> | '
            'R16 L16 R16 L16> R16 L16 R16> L16 R16 L16> R16 L16 R16> L16 R16 L16 | '
            'R16 L16 R16 L16> R16 L16 R16> L16 R16 L16> R16 L16 R16> L16 R16 L16',
            'R16> L16 R16 L16> R16 L16 R16> L16 R16 L16> R16 L16 R16> L16 R16 L16> | '
            'R16 L16 R16> L16 R16 L16> R16 L16 R16> L16 R16 L16> R16 L16 R16> L16 | '
            'R16 L16> R16 L16 R16> L16 R16 L16> R16 L16 R16> L16 R16 L16> R16 L16 | '
            'R16> L16 R16 L16 R16> L16 R16 L16 R8> L8 R4>',
            f'{x("R16> L16> R16 L16", 4)} | {x("R16 L16 R16> L16>", 4)} | {x("R16 L16> R16> L16", 4)} | '
            'R16> L16> R16 L16 R16 L16> R16> L16 R16 L16 R16> L16> R4>',
            'R16> L16 R16 L16> R16 L16 R16> L16 R16> L16 R16 L16> R16 L16 R16> L16 | '
            'R16> L16 R16 L16> R16 L16 R16> L16 R16 L16> R16 L16 R16> L16 R16 L16 | '
            'R16> L16 R16 L16> R16 L16 R16> L16 R16> L16 R16 L16> R16 L16 R16> L16 | '
            'R16> L16 R16 L16> R16 L16 R16> L16 R16 L16> R16 L16 R4>',
        ],
        lesson={
            'Why': 'Once accents can sit anywhere in the beat, your hands stop thinking in "right hand on the beat". '
                   'Displaced accents are what make funk hi-hats, fusion fills and groups of three over four sound '
                   'the way they do. They also test your time: the accent moves, the pulse must not.',
            'How': 'Same four strokes as in Down & Up Strokes: the accent is a down stroke, the tap just before it '
                   'is an up stroke, everything else is low taps. Keep the sixteenths alternating R L R L no matter '
                   'where the accent is, so the accent changes hands by itself: on 1 and & it is the right hand, on '
                   'e and a the left.',
            'Tips': 'Tap your foot on the quarter notes, or count "1 e & a" out loud, never lose the beat. Line 6 '
                    'accents every third note: the accent starts on 1, then lands on a, then &, then e, and comes '
                    'home on beat 1 of bar 4. Line 8 is the 3-3-2 phrase you hear in countless grooves and fills.',
            'Song examples': 'Aja (Steely Dan): Steve Gadd\'s drum break, accents all over the sixteenth grid. '
                             'Funk hi-hat parts where the weight sits on the "e" or the "a". Rock fills phrased in '
                             'threes across the bar line.',
        },
    ),
    Sheet(
        id='tech_doubles_control', name='Doubles Control', min_bpm=60, target_bpm=120,
        difficulty='intermediate', skills=['control', 'endurance'], grid='sixteenth', **TECH,
        description='Double strokes from open to closed: eighth-note doubles with space, then with the second '
                    'stroke accented, then doubles changing gear between eighths and sixteenths, '
                    'finally a full bar of sixteenth-note doubles from either hand.',
        pattern='R16 R16 L16 L16 R8 R8 L16 L16 R16 R16 L8 L8',
        lines=[
            'R8 R8 -4 L8 L8 -4 | R8 R8 L8 L8 R8 R8 -4 | L8 L8 -4 R8 R8 -4 | L8 L8 R8 R8 L8 L8 -4',
            'R8 R8 L8 L8 R8 R8 L8 L8 | R8 R8 L8 L8 R4 -4 | L8 L8 R8 R8 L8 L8 R8 R8 | L8 L8 R8 R8 L4 -4',
            'R8 R8> L8 L8> R8 R8> L8 L8> | R8 R8> L8 L8> R4 -4 | L8 L8> R8 R8> L8 L8> R8 R8> | L8 L8> R8 R8> L4 -4',
            f'{RR} R8 R8 L16 L16 R16 R16 L8 L8 | {x(RR, 2)} R8 R8 L4 | {RR} R8 R8 L16 L16 R16 R16 L8 L8 | {x(RR, 3)} R4',
            f'{x(RR, 2)} R8 L8 R8 L8 | R8 L8 R8 L8 {x(RR, 2)} | {x(RR, 2)} R8 L8 R8 L8 | {x(RR, 3)} R4',
            f'{x(RR, 4)} | {x(RR, 2)} R8 R8 L8 L8 | {x(RR, 4)} | {x(RR, 3)} R4',
            f'{x(LL, 4)} | {x(LL, 2)} L8 L8 R8 R8 | {x(LL, 4)} | {x(LL, 3)} L4',
            f'{x("R16> R16 L16 L16", 4)} | {x("R16> R16 L16 L16", 3)} R8> R8 | {x("L16> L16 R16 R16", 4)} | '
            f'{x("L16> L16 R16 R16", 3)} L4>',
        ],
        lesson={
            'Why': 'Double strokes let the stick do half the work: one motion, two notes. They are the engine of '
                   'rolls, of fast fills that sound relaxed, and of every rudiment with a diddle in it. The '
                   'challenge is the second stroke: it wants to be weaker and late.',
            'How': 'Open (slow): two separate wrist strokes, each from the same height, each with full rebound. '
                   'Closed (fast): one wrist motion throws the stick, the first note rebounds, and the fingers '
                   'pull the stick back into the pad for the second note, which comes out as loud as the first. '
                   'In between there is a zone where the wrist and fingers share the work; take your time there.',
            'Tips': 'Line 3 accents the second stroke on purpose: that is the note to train. Never let the doubles '
                    'turn into a buzz, you should always hear two clear notes. Lines 4 and 5 change gear between '
                    'eighth and sixteenth doubles: the hand motion stays the same size, only the timing changes. '
                    'Line 7 starts every double with the left hand.',
            'Song examples': 'The snare roll that builds into a chorus in countless rock songs. Drum-corps and '
                             'marching snare lines, where open-to-closed double-stroke rolls are a classic warm-up. '
                             'Buddy Rich\'s big-band solos: rolls that sound faster than the hands look.',
        },
    ),
    Sheet(
        id='tech_ghost_accent_contrast', name='Ghost & Accent Contrast', min_bpm=60, target_bpm=100,
        difficulty='intermediate', skills=['control', 'coordination'], grid='sixteenth', **{**TECH, 'genres': ['funk']},
        description='The widest dynamic range: ghost notes barely touch the pad, accents are full strokes. From '
                    'eighths with one loud and one ghost hand to the funk backbeat with ghosts in between, ghosted '
                    'doubles and a shuffle in triplets.',
        pattern='R16g L16g R16g L16g R16> L16g R16g L16g R16g L16g R16g L16g R16> L16g R16g L16g',
        lines=[
            'R8> L8g R8> L8g R8> L8g R8> L8g | R8> L8g R8> L8g R4> -4 | R8> L8g R8> L8g R8> L8g R8> L8g | '
            'R8> L8g R8> L8g R8> L8g R4>',
            'R8g L8> R8g L8> R8g L8> R8g L8> | R8g L8> R8g L8> R8g L4> -8 | R8g L8> R8g L8> R8g L8> R8g L8> | '
            'R8g L8> R8g L8> R8g L8> -4',
            f'{x("R16> L16g R16g L16g", 4)} | {x("R16> L16g R16g L16g", 2)} R8> L8g R4> | '
            f'{x("R16> L16g R16g L16g", 4)} | {x("R16> L16g R16g L16g", 3)} R4>',
            'R16g L16g R16g L16g R16> L16g R16g L16g R16g L16g R16g L16g R16> L16g R16g L16g | '
            'R16g L16g R16g L16g R16> L16g R16g L16g R16g L16g R16g L16g R4> | '
            'R16g L16g R16g L16g R16> L16g R16g L16g R16g L16g R16g L16g R16> L16g R16g L16g | '
            'R16g L16g R16g L16g R16> L16g R16g L16g R16g L16g R16g L16> R16> L16g R16g L16g',
            'R16> L16g R16g L16g R16g L16g R16g L16> R16g L16g R16> L16g R16g L16g R16> L16g | '
            'R16g L16g R16g L16g R16> L16g R16g L16g R16g L16g R16g L16g R16> L16g R16g L16g | '
            'R16> L16g R16g L16g R16g L16g R16g L16> R16g L16g R16> L16g R16g L16g R16> L16g | '
            'R16> L16g R16g L16g R16g L16g R16g L16> R16g L16g R16> L16g R4>',
            f'{x("R8> L16g L16g", 4)} | {x("L8> R16g R16g", 4)} | {x("R8> L16g L16g", 4)} | '
            'R8> L16g L16g L8> R16g R16g R8> L16g L16g R4>',
            '3(R8> L8g R8g) 3(L8> R8g L8g) 3(R8> L8g R8g) 3(L8> R8g L8g) | 3(R8> L8g R8g) 3(L8> R8g L8g) R4> L4> | '
            '3(R8> L8g R8g) 3(L8> R8g L8g) 3(R8> L8g R8g) 3(L8> R8g L8g) | 3(R8> L8g R8g) 3(L8> R8g L8g) 3(R8> L8g R8g) L4>',
            'R16> L16g R16g L16g R16g L16g R16> L16g R16g L16g R16g L16> R16g L16g R16> L16g | '
            'R16g L16g R16g L16g R16> L16g R16g L16g R16g L16g R16g L16g R16> L16g R16g L16g | '
            'R16> L16g R16g L16g R16g L16g R16> L16g R16g L16g R16g L16> R16g L16g R16> L16g | '
            'R16> L16g R16g L16g R16g L16g R16> L16g R16> L16g R16> L16g R4>',
        ],
        lesson={
            'Why': 'Ghost notes are the notes you feel more than hear. Next to big accents they make a groove '
                   'sound alive instead of mechanical; this contrast is the core of funk, R&B, hip-hop and every '
                   'good shuffle. It is also the hardest dynamic job for the hands: the loudest and the quietest '
                   'note, one sixteenth apart.',
            'How': 'Ghost note: the stick starts barely 1 to 2 cm above the pad and just touches it, much softer '
                   'than a normal tap. Accent: full height, about 25 cm. Moving from accent to ghost is a down '
                   'stroke (stop low after the accent); moving from ghost to accent is an up stroke (the ghost '
                   'lifts the stick). The grip stays loose; ghosts come from low height, not from squeezing.',
            'Tips': 'Ghosts should be barely audible, but audible: you (and the microphone) must still hear '
                    'every one. If they sound like taps, go lower; if they vanish, lift a touch. The '
                    'accents must not shrink because the ghosts are low. Line 4 is the funk backbeat on 2 and 4. '
                    'Line 6 ghosts two notes with the same hand. Line 7 is a shuffle feel in triplets: accent, '
                    'ghost, ghost.',
            'Song examples': 'Rosanna (Toto): Jeff Porcaro\'s half-time shuffle, full of ghost notes. Cissy Strut '
                             '(The Meters): Zigaboo Modeliste\'s ghosted funk snare. Fool in the Rain (Led '
                             'Zeppelin): ghost notes inside a half-time shuffle.',
        },
    ),
    Sheet(
        id='tech_speed_bursts', name='Speed Bursts', min_bpm=80, target_bpm=160,
        difficulty='intermediate', skills=['endurance', 'control'], grid='sixteenth', **TECH,
        description='Short groups of fast sixteenths, then a rest to relax: four notes, eight, pickups into the '
                    'beat, twelve, a whole bar, bursts that start and land on an accent, and finally two bars '
                    'without a break.',
        pattern='R16 L16 R16 L16 R16 L16 R16 L16 R4 -4',
        lines=[
            f'{R16} R4 -2 | {L16} L4 -2 | -4 {R16} R4 -4 | -4 {L16} L4 -4',
            f'{x(R16, 2)} R4 -4 | {x(L16, 2)} L4 -4 | -4 {x(R16, 2)} R4 | -4 {x(L16, 2)} L4',
            f'-8 R16 L16 {R16} R4 -4 | -8 L16 R16 {L16} L4 -4 | -8 R16 L16 {R16} R4 -4 | -8 R16 L16 {x(R16, 2)} R4',
            f'{x(R16, 3)} R4 | -1 | {x(L16, 3)} L4 | -1',
            f'{x(R16, 4)} | R4 -4 -2 | {x(L16, 4)} | L4 -4 -2',
            f'R16> L16 R16 L16 {R16} R4> -4 | -4 L16> R16 L16 R16 {L16} L4> | R16> L16 R16 L16 R16> L16 R16 L16 '
            f'R16> L16 R16 L16 R4> | -2 R16> L16 R16 L16 R4>',
            f'{x(R16, 4)} | {x(R16, 2)} R4 -4 | {x(L16, 4)} | {x(L16, 2)} L4 -4',
            f'R16> L16 R16 L16 {x(R16, 3)} | {x(R16, 4)} | R4> -4 -2 | -4 {R16} R4> -4',
        ],
        lesson={
            'Why': 'Speed is built in short bursts, not by playing fast until it hurts. A burst lets you play a '
                   'little faster than your comfortable tempo for a moment, and the rest right after it teaches '
                   'the most important skill at speed: letting go. Over weeks the bursts get longer and the '
                   'tempo climbs.',
            'How': 'Low sticks (about 5 to 8 cm), loose grip, the stick rebounding on every note; at speed the '
                   'fingers take over more of the work from the wrists. The burst starts relaxed, not with a jolt, '
                   'and the landing note is part of it. In the rest, deliberately drop the shoulders and soften '
                   'the hands before the next burst.',
            'Tips': 'Only go as fast as the bursts stay even; uneven fast notes are not faster, just messier. If the '
                    'forearms burn, the grip is too tight or the sticks too high. Line 4 gives you a whole bar of rest '
                    'after each burst, line 5 a landing note and three beats of rest: '
                    'bar of rest: use it. Line 8 is two bars without a break, the test of everything before it.',
            'Song examples': 'In the Air Tonight (Phil Collins): one famous sixteenth-note burst around the toms, '
                             'then the groove. Tom Sawyer (Rush): Neil Peart\'s quick fills between steady grooves. '
                             'Smells Like Teen Spirit (Nirvana): the burst of a fill that kicks off the song.',
        },
    ),
]


if __name__ == '__main__':
    print_table(SHEETS)
