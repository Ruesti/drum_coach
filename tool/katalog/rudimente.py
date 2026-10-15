"""Die zwölf Rudiment-Blätter (Katalog Schritt 3a), frei komponiert.

Regel (Uli, 30.09.): jede Übung so abwechslungsreich und groovy wie möglich.
Jedes Blatt: 8 Zeilen à 2 Takte mit Wiederholung + Challenge 8 Takte.
Notenschrift siehe sheetlang.py. Texte Englisch (App-Sprache).
"""
from __future__ import annotations

from blatt import Sheet, print_table
from sheetlang import Line


SHEETS: list[Sheet] = [
    Sheet(
        id='single_stroke_roll', name='Single Stroke Roll', min_bpm=60, target_bpm=200,
        difficulty='beginner', skills=['control'], genres=[], count_lines=2,
        description='Alternating single strokes, R L R L. The first and most used rudiment: even strokes at every tempo.',
        pattern='R8 L8 R8 L8 R8 L8 R8 L8',
        lines=[
            'R8 L8 R8 L8 R8 L8 R8 L8 | R8 L8 R8 L8 R4 L4',
            'R8 L8 R8 L8 R16 L16 R16 L16 R8 L8 | R16 L16 R16 L16 R8 L8 R4 -4',
            'R16 L16 R16 L16 R16 L16 R16 L16 R8 L8 R8 L8 | R16 L16 R16 L16 R8 L8 R16 L16 R16 L16 R4',
            'R16> L16 R16 L16 R16> L16 R16 L16 R16> L16 R16 L16 R16> L16 R16 L16 | R16> L16 R16 L16 R8> L8 R16> L16 R16 L16 R4>',
            'R8 L8 R8 -8 L8 R8 L8 -8 | R16 L16 R16 L16 -8 R8 L8 R8 L4',
            '3(R8 L8 R8) 3(L8 R8 L8) R4 L4 | 3(R8 L8 R8) 3(L8 R8 L8) 3(R8 L8 R8) 3(L8 R8 L8)',
            'R8 L8> R8 L8> R16 L16 R16 L16 R8 L8> | R16 L16 R16 L16 R16 L16 R16 L16 R8> L8 R8> L8',
            'R16 L16 R16 L16 R32 L32 R32 L32 R32 L32 R32 L32 R8 L8 R4 | R8 L8 R16 L16 R16 L16 R4> -4',
        ],
        challenge=(
            'R8 L8 R8 L8 R8 L8 R8 L8 | R16 L16 R16 L16 R8 L8 R4 L4 | '
            'R16> L16 R16 L16 R16> L16 R16 L16 R16> L16 R16 L16 R16> L16 R16 L16 | R8 L8 R8 -8 L8 R8 L8 -8 | '
            '3(R8 L8 R8) 3(L8 R8 L8) R4 L4 | R8 L8> R8 L8> R16 L16 R16 L16 R8 L8> | '
            'R32 L32 R32 L32 R32 L32 R32 L32 R8 L8 R16 L16 R16 L16 R4 | R8 L8 R8 L8 R4> -4'
        ),
        lesson={
            'Why it matters': 'Every fill, every roll, every fast passage on the kit is built from single strokes. If they are even, everything else sounds even.',
            'How to play it': 'Alternate the hands, R L R L, each stroke from the same height, the stick rebounding by itself. The left hand should be indistinguishable from the right.',
            'Practice tips': 'Start slow enough that every stroke is a choice, not a reflex. Play each line soft, medium and loud. Lead with the left hand every other pass. When the strokes start to crowd each other, drop one tempo step.',
            'Where you hear it': 'Snare fills around the toms, the surf-rock rolls of the sixties, every "one-two-three-four" count-in on a hi-hat. The plainest sound in drumming, and the most exposed.',
        },
    ),
    Sheet(
        id='double_stroke_roll', name='Double Stroke Roll', min_bpm=60, target_bpm=180,
        difficulty='beginner', skills=['control'], genres=[], count_lines=2,
        description='Two strokes per hand, R R L L. The second stroke is the hard one: it has to be as loud as the first.',
        pattern='R8 R8 L8 L8 R8 R8 L8 L8',
        lines=[
            'R8 R8 L8 L8 R8 R8 L8 L8 | R8 R8 L8 L8 R4 L4',
            'R16 R16 L16 L16 R16 R16 L16 L16 R8 R8 L8 L8 | R16 R16 L16 L16 R8 R8 L4 R4',
            'R16 R16 L16 L16 R16 L16 R16 L16 R16 R16 L16 L16 R16 L16 R16 L16 | R16 R16 L16 L16 R8 L8 R16 R16 L16 L16 R4',
            'R16> R16 L16 L16 R16> R16 L16 L16 R16> R16 L16 L16 R16> R16 L16 L16 | R16> R16 L16 L16 R8> L8 R16> R16 L16 L16 R4>',
            'R16 R16 L16 L16 -8 R8 L16 L16 R16 R16 -8 L8 | R16 R16 L16 L16 R16 R16 L16 L16 -8 R8 L4',
            'R8> L16 L16 R16 R16 L8> R8> L16 L16 R16 R16 L8> | R16> L16 L16 R16 R16 L16> R16> L16 L16 R16 R16 L16> R4>',
            '3(R8 R8 L8) 3(L8 R8 R8) 3(L8 L8 R8) 3(R8 L8 L8) | R8 R8 L8 L8 R4 L4',
            'R32 R32 L32 L32 R32 R32 L32 L32 R8 L8 R32 R32 L32 L32 R32 R32 L32 L32 R8> L8> | R32 R32 L32 L32 R32 R32 L32 L32 R32 R32 L32 L32 R32 R32 L32 L32 R4> -4',
        ],
        challenge=(
            'R8 R8 L8 L8 R8 R8 L8 L8 | R16 R16 L16 L16 R16 R16 L16 L16 R8 L8 R4 | '
            'R16> R16 L16 L16 R16> R16 L16 L16 R16> R16 L16 L16 R16> R16 L16 L16 | R16 R16 L16 L16 -8 R8 L16 L16 R16 R16 -8 L8 | '
            '3(R8 R8 L8) 3(L8 R8 R8) 3(L8 L8 R8) 3(R8 L8 L8) | R8> L16 L16 R16 R16 L8> R8> L16 L16 R16 R16 L8> | '
            'R32 R32 L32 L32 R32 R32 L32 L32 R8 L8 R32 R32 L32 L32 R32 R32 L32 L32 R8> L8> | R8 R8 L8 L8 R4> -4'
        ),
        lesson={
            'Why it matters': 'Doubles are the engine behind rolls, paradiddles and every "fast but relaxed" sound. They also teach the stick to do half the work.',
            'How to play it': 'Two strokes with each hand, R R L L. Slow: two wrist strokes. Fast: one wrist stroke and a controlled rebound, the fingers pulling the second stroke up to full volume.',
            'Practice tips': 'Listen for the second stroke of each pair, it wants to hide. Line 6 is the six stroke roll, line 8 the real roll in thirty-second notes: start it at a tempo where the doubles still sound like two separate notes.',
            'Where you hear it': 'The long snare roll before a chorus, the press rolls of marching bands, the buzz of a drum corps. Any time a drummer sounds faster than their hands are moving.',
        },
    ),
    Sheet(
        id='single_paradiddle', name='Single Paradiddle', min_bpm=60, target_bpm=120,
        difficulty='beginner', skills=['control', 'coordination'], genres=[], count_lines=2,
        description='R L R R, L R L L. Two singles and a double; the lead hand switches every group.',
        pattern='R8 L8 R8 R8 L8 R8 L8 L8',
        lines=[
            'R8 L8 R8 R8 L8 R8 L8 L8 | R8 L8 R8 R8 L4 R4',
            'R16 L16 R16 R16 L8 R8 L16 R16 L16 L16 R8 L8 | R16 L16 R16 R16 L16 R16 L16 L16 R4 L4',
            'R16 L16 R16 R16 -8 L8 R16 L16 R16 R16 -8 L8 | L16 R16 L16 L16 -8 R8 L16 R16 L16 L16 R4',
            'R16 L16> R16 R16 L16 R16> L16 L16 R16 L16> R16 R16 L16 R16> L16 L16 | R16 L16> R16 R16 L8 R8> L4 R4',
            'R8 L8 R8 R8 L8 R8 L8 L8 | R8 R8 L8 R8 L8 L8 R8 L8',
            'R16 R16 L16 L16 R8> L8> R16 L16 R16 R16 L8> R8> | L16 R16 L16 L16 R16 L16 R16 R16 L16 R16 L16 L16 R4>',
            '3(R8 L8 R8) 3(R8 L8 R8) 3(L8 L8 R8) 3(L8 R8 R8) | 3(L8 R8 L8) 3(L8 R8 L8) R4> L4>',
            'R16 -16 R16 R16 L16 -16 L16 L16 R16 -16 R16 R16 L16 -16 L16 L16 | R16 L16 R16 R16 L16 R16 L16 L16 R4> -4',
        ],
        challenge=(
            'R8 L8 R8 R8 L8 R8 L8 L8 | R16 L16 R16 R16 L8 R8 L16 R16 L16 L16 R8 L8 | '
            'R16 L16> R16 R16 L16 R16> L16 L16 R16 L16> R16 R16 L16 R16> L16 L16 | R16 L16 R16 R16 -8 L8 R16 L16 R16 R16 -8 L8 | '
            'R8 R8 L8 R8 L8 L8 R8 L8 | R16 R16 L16 L16 R8> L8> R16 L16 R16 R16 L8> R8> | '
            '3(R8 L8 R8) 3(R8 L8 R8) 3(L8 L8 R8) 3(L8 R8 R8) | R16 L16 R16 R16 L16 R16 L16 L16 R4> -4'
        ),
        lesson={
            'Why it matters': 'The paradiddle joins singles and doubles and switches the lead hand by itself. On the kit that is what moves you freely between the hands: fills, grooves split between snare and toms, anything "mixed".',
            'How to play it': 'One stroke right, one left, then two right: R L R R. Then the mirror image, L R L L. Say it out loud: pa-ra-did-dle.',
            'Practice tips': 'The double must not be quieter than the singles. First accent the first stroke of each group, then play everything even. Line 5 is the inverted paradiddle (R R L R L L R L), line 8 leaves the second stroke out, so you hear where the groove sits.',
            'Where you hear it': 'Steve Gadd builds the groove of "50 Ways to Leave Your Lover" from paradiddles; funk players move it between hi-hat and snare. It is the sound of a drummer thinking in hands, not in beats.',
        },
    ),
    Sheet(
        id='double_paradiddle', name='Double Paradiddle', min_bpm=50, target_bpm=100,
        difficulty='intermediate', skills=['control', 'coordination'], genres=[],
        description='R L R L R R, L R L R L L. A six-note paradiddle that lives in triplets and crosses the beat in sixteenths.',
        pattern='3(R8 L8 R8) 3(L8 R8 R8) 3(L8 R8 L8) 3(R8 L8 L8)',
        lines=[
            '3(R8 L8 R8) 3(L8 R8 R8) 3(L8 R8 L8) 3(R8 L8 L8) | 3(R8 L8 R8) 3(L8 R8 R8) L4> R4>',
            '3(R8> L8 R8) 3(L8 R8 R8) 3(L8> R8 L8) 3(R8 L8 L8) | 3(R8> L8 R8) 3(L8 R8 R8) L8> R8 L4',
            'R16> L16 R16 L16 R16 R16 L16> R16 L16 R16 L16 L16 R4> | L16> R16 L16 R16 L16 L16 R16> L16 R16 L16 R16 R16 L4>',
            '6(R16 L16 R16 L16 R16 R16) 6(L16 R16 L16 R16 L16 L16) R4 L4 | 6(R16 L16 R16 L16 R16 R16) 6(L16 R16 L16 R16 L16 L16) 6(R16 L16 R16 L16 R16 R16) L4>',
            '3(R8 L8 R8) 3(L8 R8 R8) -4 L4 | 3(L8 R8 L8) 3(R8 L8 L8) -4 R4',
            '3(R8 L8 R8) 3(L8 R8 R8) L8 R8 L8 R8 | 3(L8 R8 L8) 3(R8 L8 L8) R8 L8 R4',
            '3(R8> L8 R8) 3(L8> R8 R8) 3(L8> R8 L8) 3(R8> L8 L8) | 3(R8 L8 R8>) 3(L8 R8 R8>) 3(L8 R8 L8>) 3(R8 L8 L8>)',
            'R16 L16 R16 L16 R16 R16 -8 L16 R16 L16 R16 L16 L16 -8 | R16 L16 R16 L16 R16 R16 L16 R16 L16 R16 L16 L16 R4>',
        ],
        challenge=(
            '3(R8 L8 R8) 3(L8 R8 R8) 3(L8 R8 L8) 3(R8 L8 L8) | 3(R8> L8 R8) 3(L8 R8 R8) L8> R8 L4 | '
            'R16> L16 R16 L16 R16 R16 L16> R16 L16 R16 L16 L16 R4> | 6(R16 L16 R16 L16 R16 R16) 6(L16 R16 L16 R16 L16 L16) R4 L4 | '
            '3(R8 L8 R8) 3(L8 R8 R8) -4 L4 | 3(L8 R8 L8) 3(R8 L8 L8) R8 L8 R4 | '
            'R16 L16 R16 L16 R16 R16 -8 L16 R16 L16 R16 L16 L16 -8 | 3(R8> L8 R8) 3(L8 R8 R8) L4> -4'
        ),
        lesson={
            'Why it matters': 'Six notes per group: in triplets it falls on the beat every two beats, in sixteenths it drifts across the bar. That drift is the most useful thing about it, it is how you phrase in threes over a four-beat groove.',
            'How to play it': 'Four singles and a double: R L R L R R, then L R L R L L. Keep the double as even as the singles.',
            'Practice tips': 'Count the triplets out loud, "1 trip let 2 trip let". Line 3 and line 8 put the six-note group on sixteenths: feel where the accents land against the beat before you speed up.',
            'Where you hear it': 'Jazz and shuffle fills, anything in 12/8, the triplet rolls around the kit in rock ballads. Whenever a fill feels like it is rolling rather than marching.',
        },
    ),
    Sheet(
        id='paradiddle_diddle', name='Paradiddle-Diddle', min_bpm=60, target_bpm=100,
        difficulty='intermediate', skills=['control', 'coordination'], genres=[],
        description='R L R R L L. Two singles and two doubles; the lead hand stays the same, so the pattern rolls.',
        pattern='3(R8 L8 R8) 3(R8 L8 L8) 3(R8 L8 R8) 3(R8 L8 L8)',
        lines=[
            '3(R8 L8 R8) 3(R8 L8 L8) 3(R8 L8 R8) 3(R8 L8 L8) | 3(R8 L8 R8) 3(R8 L8 L8) R4 L4',
            '3(R8> L8 R8) 3(R8 L8 L8) 3(R8> L8 R8) 3(R8 L8 L8) | 3(R8> L8 R8) 3(R8 L8 L8) R8> L8 R4',
            '6(R16 L16 R16 R16 L16 L16) 6(R16 L16 R16 R16 L16 L16) R4> L4 | 6(R16 L16 R16 R16 L16 L16) R4> 6(R16 L16 R16 R16 L16 L16) L4>',
            'R16> L16 R16 R16 L16 L16 R16> L16 R16 R16 L16 L16 R4 | L16> R16 L16 L16 R16 R16 L16> R16 L16 L16 R16 R16 L4',
            '3(R8 L8 R8) 3(R8 L8 L8) -4 R4 | 3(R8 L8 R8) 3(R8 L8 L8) R8 -8 L4',
            '3(R8 L8 R8) 3(R8 L8 L8) R8 L8 R8 L8 | 3(R8 L8 R8) 3(R8 L8 L8) 3(R8 L8 R8) L4>',
            '3(R8 L8 R8>) 3(R8 L8 L8) 3(R8 L8 R8>) 3(R8 L8 L8) | 3(R8 L8 R8) 3(R8> L8 L8) 3(R8 L8 R8) 3(R8> L8 L8)',
            '3(R8 -8 R8) 3(R8 L8 L8) 3(R8 -8 R8) 3(R8 L8 L8) | 3(R8 L8 R8) 3(R8 L8 L8) R4> -4',
        ],
        challenge=(
            '3(R8 L8 R8) 3(R8 L8 L8) 3(R8 L8 R8) 3(R8 L8 L8) | 3(R8> L8 R8) 3(R8 L8 L8) R8> L8 R4 | '
            '6(R16 L16 R16 R16 L16 L16) 6(R16 L16 R16 R16 L16 L16) R4> L4 | R16> L16 R16 R16 L16 L16 R16> L16 R16 R16 L16 L16 R4 | '
            '3(R8 L8 R8) 3(R8 L8 L8) -4 R4 | 3(R8 L8 R8) 3(R8 L8 L8) R8 L8 R8 L8 | '
            '3(R8 -8 R8) 3(R8 L8 L8) 3(R8 -8 R8) 3(R8 L8 L8) | 3(R8 L8 R8) 3(R8 L8 L8) R4> -4'
        ),
        lesson={
            'Why it matters': 'Because the lead hand never changes, the paradiddle-diddle rolls like a wheel. It is the quickest way to a smooth sextuplet and to fills that sound like one long motion.',
            'How to play it': 'R L R R L L, then again R L R R L L. Right hand leads every group (play it left-led as well, line 4).',
            'Practice tips': 'The two doubles in a row are the trap: the second one, L L, tends to rush. Put the accent on the first note (line 2) and let the rest be a quiet, even stream.',
            'Where you hear it': 'Fast triplet fills in rock and fusion, the "rolling" tom fills of big-band drummers, drum corps hybrids. When a fill sounds like it is falling down the stairs in a good way.',
        },
    ),
    Sheet(
        id='flam', name='Flam', min_bpm=60, target_bpm=120,
        difficulty='intermediate', skills=['control'], genres=[],
        description='A quiet grace note just before the main stroke, played with the other hand. One fat note instead of two.',
        pattern='R4f> L4f> R4f> L4f>',
        lines=[
            'R4f L4f R4f L4f | R8f L8 R8f L8 R4f L4f',
            'R8f L8 R8 L8 R8f L8 R8 L8 | R8f L8 R8 L8 R4f L4f',
            'R16f L16 R16 L16 R16f L16 R16 L16 R16f L16 R16 L16 R16f L16 R16 L16 | R16f L16 R16 L16 R8f L8 R4f L4f',
            'R4f> -8 L8 R4f> -8 L8 | R8f> L8 R8 L8 R4f> -4',
            'R16f L16 R16 R16 L16f R16 L16 L16 R16f L16 R16 R16 L16f R16 L16 L16 | R8f L8 R8 R8 L8f R8 L8 L8',
            'R8 L8f R8 L8f R8 L8f R8 L8f | R8 L8f R8 L8f R4 L4f',
            '3(R8f L8 R8) 3(L8f R8 L8) 3(R8f L8 R8) 3(L8f R8 L8) | R4f L4f R4f L4f',
            'R8.f L16 R8.f L16 R8.f L16 R8.f L16 | R8f L8 R16 L16 R16 L16 R4f L4f',
        ],
        challenge=(
            'R4f L4f R4f L4f | R8f L8 R8 L8 R8f L8 R8 L8 | '
            'R16f L16 R16 L16 R16f L16 R16 L16 R16f L16 R16 L16 R16f L16 R16 L16 | R4f> -8 L8 R4f> -8 L8 | '
            'R16f L16 R16 R16 L16f R16 L16 L16 R16f L16 R16 R16 L16f R16 L16 L16 | R8 L8f R8 L8f R8 L8f R8 L8f | '
            'R8.f L16 R8.f L16 R8.f L16 R8.f L16 | R8f L8 R8 L8 R4f> -4'
        ),
        lesson={
            'Why it matters': 'A flam makes a single note sound bigger without hitting harder. It is the drummer\'s way of putting weight on a beat, the backbeat with a flam is a different backbeat.',
            'How to play it': 'The grace note comes from low (a few centimetres), the main note from high; both move at the same time and land almost together. Right flam: l R. Left flam: r L.',
            'Practice tips': 'Keep the grace note quiet and close: too wide and it becomes two notes, too tight and it becomes one. Line 5 is the flam paradiddle, line 8 the flam in a dotted, swinging rhythm.',
            'Where you hear it': 'Marching snare lines, the heavy backbeat in rock and metal, the opening accent of a fill. Wherever one note has to count for two.',
        },
    ),
    Sheet(
        id='flam_accent', name='Flam Accent', min_bpm=50, target_bpm=100,
        difficulty='intermediate', skills=['control'], genres=[],
        description='Flam on the first note of each triplet, hands alternating: lR L R, rL R L. The flam carries the accent.',
        pattern='3(R8f> L8 R8) 3(L8f> R8 L8) 3(R8f> L8 R8) 3(L8f> R8 L8)',
        lines=[
            '3(R8f> L8 R8) 3(L8f> R8 L8) 3(R8f> L8 R8) 3(L8f> R8 L8) | 3(R8f> L8 R8) 3(L8f> R8 L8) R4f> L4f>',
            '3(R8f> L8 R8) 3(L8f> R8 L8) R4f> L4 | 3(R8f> L8 R8) L4 3(R8f> L8 R8) L4',
            'R16f> L16 R16 L16f> R16 L16 R16f> L16 R16 L16f> R16 L16 R16f> L16 R16 L16f> | R16 L16 R16f> L16 R16 L16f> R16 L16 R4f> L4',
            '3(R8f> L8 -8) 3(L8f> R8 -8) 3(R8f> L8 -8) 3(L8f> R8 -8) | 3(R8f> L8 R8) 3(L8f> R8 L8) R4f> -4',
            '3(R8f> L8 R8) 3(L8 R8 L8) 3(R8f> L8 R8) 3(L8 R8 L8) | 3(R8f> L8 R8) 3(L8f> R8 L8) 3(R8 L8 R8) L4>',
            '3(R8f L8 R8>) 3(L8f R8 L8>) 3(R8f L8 R8>) 3(L8f R8 L8>) | 3(R8f> L8 R8) 3(L8f> R8 L8) R4f> L4f>',
            '3(R8f> -8 L8) 3(R8f> -8 L8) 3(R8f> -8 L8) 3(R8f> -8 L8) | 3(R8f> L8 R8) 3(L8f> R8 L8) 3(R8f> L8 R8) 3(L8f> R8 L8)',
            '6(R16f> L16 R16 L16f> R16 L16) 6(R16f> L16 R16 L16f> R16 L16) R4f> L4 | 3(R8f> L8 R8) 3(L8f> R8 L8) 3(R8f> L8 R8) L4>',
        ],
        challenge=(
            '3(R8f> L8 R8) 3(L8f> R8 L8) 3(R8f> L8 R8) 3(L8f> R8 L8) | 3(R8f> L8 R8) 3(L8f> R8 L8) R4f> L4 | '
            'R16f> L16 R16 L16f> R16 L16 R16f> L16 R16 L16f> R16 L16 R16f> L16 R16 L16f> | R16 L16 R16f> L16 R16 L16f> R16 L16 R4f> L4 | '
            '3(R8f> L8 -8) 3(L8f> R8 -8) 3(R8f> L8 -8) 3(L8f> R8 -8) | 3(R8f> -8 L8) 3(R8f> -8 L8) 3(R8f> -8 L8) 3(R8f> -8 L8) | '
            '6(R16f> L16 R16 L16f> R16 L16) 6(R16f> L16 R16 L16f> R16 L16) R4f> L4 | 3(R8f> L8 R8) 3(L8f> R8 L8) R4f> -4'
        ),
        lesson={
            'Why it matters': 'The flam accent is the triplet with a backbone: a heavy first note, two light ones. It teaches hands to change roles every beat, flam, tap, tap, with the lead switching sides.',
            'How to play it': 'lR L R, then rL R L, as eighth-note triplets. The flam is loud (accent), the two taps are low and even.',
            'Practice tips': 'Keep the taps really low, the contrast is the point. Line 3 moves the three-note group onto sixteenths, so the accents drift across the beats, line 7 turns it into a shuffle.',
            'Where you hear it': 'Marching and drum corps music, swing drummers phrasing in threes, the 12/8 blues ballad where every beat has a weighted first note.',
        },
    ),
    Sheet(
        id='flam_tap', name='Flam Tap', min_bpm=50, target_bpm=150,
        difficulty='intermediate', skills=['control'], genres=['drumCorps'],
        description='A flam followed by a tap with the same hand: lR R, rL L. A double stroke that starts with a flam.',
        pattern='R8f R8 L8f L8 R8f R8 L8f L8',
        lines=[
            'R8f R8 L8f L8 R8f R8 L8f L8 | R8f R8 L8f L8 R4f L4',
            'R16f R16 L16f L16 R16f R16 L16f L16 R16f R16 L16f L16 R16f R16 L16f L16 | R16f R16 L16f L16 R8f R8 L4f R4',
            'R8f R8 L8f L8 R4f L4f | R8f R8 L8f L8 R8f R8 L4f',
            'R8f R8 -4 L8f L8 -4 | R8f R8 L8f L8 R8f R8 -4',
            '3(R8f R8 L8) 3(R8f R8 L8) 3(L8f L8 R8) 3(L8f L8 R8) | R8f R8 L8f L8 R4f L4',
            'R8f R8> L8f L8> R8f R8> L8f L8> | R16f R16> L16f L16> R16f R16> L16f L16> R4f> L4>',
            'R8f R8 L16 L16 R16 R16 L8f L8 R16 R16 L16 L16 | R8f R8 L8f L8 R16f R16 L16f L16 R4>',
            'R8 L8f L8 R8f R8 L8f L8 R8f | R8 L8f L8 R8f R8 L8f -4',
        ],
        challenge=(
            'R8f R8 L8f L8 R8f R8 L8f L8 | R16f R16 L16f L16 R16f R16 L16f L16 R16f R16 L16f L16 R16f R16 L16f L16 | '
            'R8f R8 L8f L8 R4f L4f | R8f R8 -4 L8f L8 -4 | '
            '3(R8f R8 L8) 3(R8f R8 L8) 3(L8f L8 R8) 3(L8f L8 R8) | R8f R8> L8f L8> R8f R8> L8f L8> | '
            'R8f R8 L16 L16 R16 R16 L8f L8 R16 R16 L16 L16 | R8f R8 L8f L8 R4f> -4'
        ),
        lesson={
            'Why it matters': 'Flam tap is double strokes with a flam on the first one, a rudiment that sounds like a small march by itself. It trains the grace note hand to get out of the way instantly.',
            'How to play it': 'lR R, then rL L. The flam\'s grace note (the other hand) is low; the main stroke and the tap are played by the same hand.',
            'Practice tips': 'The tap wants to be louder than the flam, do not let it. Line 6 reverses that on purpose. Line 8 puts the flam on the "and", which is where it lives in a lot of grooves.',
            'Where you hear it': 'Drum corps and pipe-band snare parts, military marches, and the crisp "ta-da" figures in big-band shout choruses.',
        },
    ),
    Sheet(
        id='single_drag', name='Single Drag', min_bpm=60, target_bpm=120,
        difficulty='intermediate', skills=['control'], genres=[],
        description='Two quiet grace notes (a short double) before the main stroke: llR, rrL. A buzz that lands on a note.',
        pattern='R4d L4d R4d L4d',
        lines=[
            'R4d L4d R4d L4d | R8d L8 R8d L8 R4d L4d',
            'R8d L8 R8 L8 R8d L8 R8 L8 | R8d L8 R8 L8 R4d L4',
            'R16d L16 R16 L16 R16d L16 R16 L16 R16d L16 R16 L16 R16d L16 R16 L16 | R16d L16 R16 L16 R8d L8 R4d L4',
            'R8d L8> L8d R8> R8d L8> L8d R8> | R8d L8> L8d R8> R4d> L4>',
            'R4d -8 L8 R4d -8 L8 | R8d L8 R8d L8 R4d> -4',
            '3(R8d L8 R8) 3(L8d R8 L8) 3(R8d L8 R8) 3(L8d R8 L8) | R4d L4d R4d L4d',
            'R8d L8 R16 R16 L16 L16 R8d L8 R16 R16 L16 L16 | R8d L8 R8d L8 R16d L16 R16 L16 R4d>',
            'R8 L16 R16d L8 R16 L16d R8 L16 R16d L8 R16 L16d | R8d L8 R8d L8 R4d> -4',
        ],
        challenge=(
            'R4d L4d R4d L4d | R8d L8 R8 L8 R8d L8 R8 L8 | '
            'R16d L16 R16 L16 R16d L16 R16 L16 R16d L16 R16 L16 R16d L16 R16 L16 | R8d L8> L8d R8> R8d L8> L8d R8> | '
            'R4d -8 L8 R4d -8 L8 | 3(R8d L8 R8) 3(L8d R8 L8) 3(R8d L8 R8) 3(L8d R8 L8) | '
            'R8d L8 R16 R16 L16 L16 R8d L8 R16 R16 L16 L16 | R8d L8 R8d L8 R4d> -4'
        ),
        lesson={
            'Why it matters': 'The drag is the rudiment that connects notes: a short double leading into a stroke. Rolls, ruffs and most "textured" snare playing grow out of it.',
            'How to play it': 'Two low bounced strokes with one hand, then the main stroke with the other: llR. Then rrL. The graces are quick and quiet, the main note full.',
            'Practice tips': 'Let the two grace notes bounce from one wrist motion, do not play them as two separate taps. Line 4 is the single drag tap (drag, accented tap), line 8 puts the drag on the "a" so it pulls into the next beat.',
            'Where you hear it': 'Snare drum solos and marches, the ornamented backbeats of New Orleans drumming, the brushwork of jazz drummers. Everywhere a note gets a little lead-in.',
        },
    ),
    Sheet(
        id='five_stroke_roll', name='Five Stroke Roll', min_bpm=60, target_bpm=140,
        difficulty='intermediate', skills=['control'], genres=['drumCorps'], new_seed=True, grid='sixteenth',
        description='Two doubles and an accent: R R L L R, L L R R L. The shortest roll that already sounds like a roll.',
        pattern='R32 R32 L32 L32 R8> L32 L32 R32 R32 L8> R32 R32 L32 L32 R8> L32 L32 R32 R32 L8>',
        lines=[
            'R32 R32 L32 L32 R8> L32 L32 R32 R32 L8> R32 R32 L32 L32 R8> L32 L32 R32 R32 L8> | R32 R32 L32 L32 R8> L32 L32 R32 R32 L8> R4> L4>',
            'R16 R16 L16 L16 R8> L16 L16 R16 R16 L8> R4> | L16 L16 R16 R16 L8> R16 R16 L16 L16 R8> L4>',
            'R8 L32 L32 R32 R32 L8> R8 L32 L32 R32 R32 L8> R4 | L8 R32 R32 L32 L32 R8> L8 R32 R32 L32 L32 R8> L4',
            'R32 R32 L32 L32 R8> L16 R16 L16 R16 L32 L32 R32 R32 L8> R16 L16 R16 L16 | R32 R32 L32 L32 R8> L32 L32 R32 R32 L8> R4> L4>',
            'R32 R32 L32 L32 R8> -4 L32 L32 R32 R32 L8> -4 | R32 R32 L32 L32 R8> L32 L32 R32 R32 L8> R4> -4',
            'R16 R16 L16 L16 R4> L16 L16 R16 R16 L4> | R16 R16 L16 L16 R4> L8> R8 L4',
            'R16 R16 L16 L16 R16> L16 L16 R16 R16 L16> R16 R16 L16 L16 R16> L16 | L16 L16 R16 R16 L16> R16 R16 L16 L16 R16> L8 R4',
            'R32 R32 L32 L32 R32 R32 L32 L32 R32 R32 L32 L32 R32 R32 L32 L32 R4> -4 | R32 R32 L32 L32 R8> L32 L32 R32 R32 L8> R4> -4',
        ],
        challenge=(
            'R32 R32 L32 L32 R8> L32 L32 R32 R32 L8> R32 R32 L32 L32 R8> L32 L32 R32 R32 L8> | R16 R16 L16 L16 R8> L16 L16 R16 R16 L8> R4> | '
            'R8 L32 L32 R32 R32 L8> R8 L32 L32 R32 R32 L8> R4 | R32 R32 L32 L32 R8> -4 L32 L32 R32 R32 L8> -4 | '
            'R16 R16 L16 L16 R4> L16 L16 R16 R16 L4> | R16 R16 L16 L16 R16> L16 L16 R16 R16 L16> R16 R16 L16 L16 R16> L16 | '
            'R32 R32 L32 L32 R32 R32 L32 L32 R32 R32 L32 L32 R32 R32 L32 L32 R4> -4 | R32 R32 L32 L32 R8> L32 L32 R32 R32 L8> R4> -4'
        ),
        lesson={
            'Why it matters': 'Rolls are how a snare drum sustains a note. The five stroke roll is the smallest one, and once its two doubles are even, every longer roll is the same motion continued.',
            'How to play it': 'R R L L R: two doubles, then an accented single that ends the roll, alternating the lead each time. Written as thirty-second notes into an eighth, or as sixteenths into an eighth (line 2).',
            'Practice tips': 'The accent is a full stroke, the doubles are low and bouncy: hear the roll as a run-up to the accent, not as five equal notes. Line 7 writes the five notes as plain sixteenths, so the accent drifts, line 8 chains doubles into a long roll.',
            'Where you hear it': 'Marches and rudimental solos, the "flam-flam-roll" of a drumline cadence, the snare crescendo rolls of orchestral music. Short rolls punctuate; long rolls build.',
        },
    ),
    Sheet(
        id='seven_stroke_roll', name='Seven Stroke Roll', min_bpm=50, target_bpm=120,
        difficulty='intermediate', skills=['control'], genres=['drumCorps'], new_seed=True, grid='sixteenthTriplet',
        description='Three doubles and an accent: R R L L R R L. Six fast notes into one landing.',
        pattern='6(R16 R16 L16 L16 R16 R16) L4> 6(L16 L16 R16 R16 L16 L16) R4>',
        lines=[
            '6(R16 R16 L16 L16 R16 R16) L4> 6(L16 L16 R16 R16 L16 L16) R4> | 6(R16 R16 L16 L16 R16 R16) L4> R4> L4>',
            'R16 R16 L16 L16 R16 R16 L8> L16 L16 R16 R16 L16 L16 R8> | R16 R16 L16 L16 R16 R16 L8> R4 L4',
            'R32 R32 L32 L32 R32 R32 L16> R32 R32 L32 L32 R32 R32 L16> R32 R32 L32 L32 R32 R32 L16> R32 R32 L32 L32 R32 R32 L16> | R32 R32 L32 L32 R32 R32 L16> R4> L4 R4',
            '6(R16 R16 L16 L16 R16 R16) L4> -4 R4 | 6(L16 L16 R16 R16 L16 L16) R4> -4 L4',
            '6(R16 R16 L16 L16 R16 R16) L8> R8 L8 R8 L16 R16 L16 R16 | 6(L16 L16 R16 R16 L16 L16) R4> L8 R8 L4',
            '3(R8 R8 L8) 3(L8 R8 R8) L4> R4 | 3(L8 L8 R8) 3(R8 L8 L8) R4> L4',
            '6(R16> R16 L16 L16 R16 R16) L4 6(L16> L16 R16 R16 L16 L16) R4 | 6(R16> R16 L16 L16 R16 R16) L4> R4> L4>',
            '6(R16 R16 L16 L16 R16 R16) 6(L16 L16 R16 R16 L16 L16) R4> -4 | 6(R16 R16 L16 L16 R16 R16) L4> 6(L16 L16 R16 R16 L16 L16) R4>',
        ],
        challenge=(
            '6(R16 R16 L16 L16 R16 R16) L4> 6(L16 L16 R16 R16 L16 L16) R4> | R16 R16 L16 L16 R16 R16 L8> L16 L16 R16 R16 L16 L16 R8> | '
            'R32 R32 L32 L32 R32 R32 L16> R32 R32 L32 L32 R32 R32 L16> R32 R32 L32 L32 R32 R32 L16> R32 R32 L32 L32 R32 R32 L16> | 6(R16 R16 L16 L16 R16 R16) L4> -4 R4 | '
            '6(L16 L16 R16 R16 L16 L16) R8> L8 R8 L8 R16 L16 R16 L16 | 3(R8 R8 L8) 3(L8 R8 R8) L4> R4 | '
            '6(R16 R16 L16 L16 R16 R16) 6(L16 L16 R16 R16 L16 L16) R4> -4 | 6(R16 R16 L16 L16 R16 R16) L4> R4> -4'
        ),
        lesson={
            'Why it matters': 'Seven strokes fill exactly a beat of sextuplets before the landing, so this roll teaches you to start a roll on the beat and finish it on the next one, the most common roll in written music.',
            'How to play it': 'R R L L R R L: three doubles as a sextuplet, then the accent on the next beat with the other hand. Alternate the lead.',
            'Practice tips': 'Count "1 and a 2": the roll is the "1 and a", the accent the "2". Line 3 compresses it into thirty-seconds within one beat, line 6 opens it into a shuffle, line 8 chains two rolls into a thirteen-stroke.',
            'Where you hear it': 'Concert band and orchestral snare parts, drum corps cadences, the roll into a crash at the top of a chorus.',
        },
    ),
    Sheet(
        id='swiss_army_triplet', name='Swiss Army Triplet', min_bpm=50, target_bpm=110,
        difficulty='advanced', skills=['control', 'coordination'], genres=['drumCorps'], new_seed=True, grid='triplet',
        description='A flam, a tap with the same hand, then the other hand: lR R L, as triplets. Fast and oddly comfortable.',
        pattern='3(R8f> R8 L8) 3(R8f> R8 L8) 3(R8f> R8 L8) 3(R8f> R8 L8)',
        lines=[
            '3(R8f> R8 L8) 3(R8f> R8 L8) 3(R8f> R8 L8) 3(R8f> R8 L8) | 3(R8f> R8 L8) 3(R8f> R8 L8) R4f> L4',
            '3(R8f> R8 L8) 3(L8f> L8 R8) 3(R8f> R8 L8) 3(L8f> L8 R8) | 3(R8f> R8 L8) 3(L8f> L8 R8) R4f> L4f>',
            'R16f> R16 L16 R16f> R16 L16 R16f> R16 L16 R16f> R16 L16 R16f> R16 L16 R16f> | R16 L16 R16f> R16 L16 R16f> R16 L16 R4f> L4',
            '3(R8f> R8 -8) 3(R8f> R8 -8) 3(R8f> R8 L8) 3(R8f> R8 L8) | 3(R8f> R8 -8) 3(R8f> R8 L8) R4f> -4',
            '3(R8f> R8 L8) 3(R8f> L8 R8) 3(L8f> L8 R8) 3(L8f> R8 L8) | 3(R8f> R8 L8) 3(L8f> R8 L8) R4f> L4',
            '3(R8f R8 L8>) 3(R8f R8 L8>) 3(R8f R8 L8>) 3(R8f R8 L8>) | 3(R8f> R8 L8) 3(R8f> R8 L8) R4f> L4>',
            '3(R8f> -8 L8) 3(R8f> -8 L8) 3(R8f> R8 L8) 3(R8f> R8 L8) | 3(R8f> -8 L8) 3(R8f> R8 L8) R4f> L4',
            '6(R16f> R16 L16 R16f> R16 L16) 6(R16f> R16 L16 R16f> R16 L16) R4f> L4 | 6(R16f> R16 L16 R16f> R16 L16) R4f> 3(R8f> R8 L8) R4f>',
        ],
        challenge=(
            '3(R8f> R8 L8) 3(R8f> R8 L8) 3(R8f> R8 L8) 3(R8f> R8 L8) | 3(R8f> R8 L8) 3(L8f> L8 R8) 3(R8f> R8 L8) 3(L8f> L8 R8) | '
            'R16f> R16 L16 R16f> R16 L16 R16f> R16 L16 R16f> R16 L16 R16f> R16 L16 R16f> | R16 L16 R16f> R16 L16 R16f> R16 L16 R4f> L4 | '
            '3(R8f> R8 -8) 3(R8f> R8 -8) 3(R8f> R8 L8) 3(R8f> R8 L8) | 3(R8f> R8 L8) 3(R8f> L8 R8) 3(L8f> L8 R8) 3(L8f> R8 L8) | '
            '6(R16f> R16 L16 R16f> R16 L16) 6(R16f> R16 L16 R16f> R16 L16) R4f> L4 | 3(R8f> R8 L8) 3(R8f> R8 L8) R4f> -4'
        ),
        lesson={
            'Why it matters': 'The Swiss army triplet is the fastest way to play flammed triplets, because the lead hand plays two notes in a row and never has to cross. It is the secret behind many impossible-looking fills.',
            'How to play it': 'lR R L: a flam (left grace, right main), a right tap, a left tap, as an eighth-note triplet. Same lead every group; line 2 alternates it.',
            'Practice tips': 'Think "flam-a-dee": the first two notes belong to one hand. Keep the left tap at the height of the right tap. Line 5 pairs it with the flam accent so you feel the difference, line 8 doubles the speed.',
            'Where you hear it': 'Drum corps, Scottish and Basel pipe-band drumming, and fusion drummers who want a flammed triplet fill at tempos where the flam accent falls apart.',
        },
    ),
]


def all_parsed() -> dict[str, list[Line]]:
    """Alle Blätter geparst und geprüft; wirft bei Fehlern."""
    return {s.id: s.parsed() for s in SHEETS}


if __name__ == '__main__':
    print_table(SHEETS)
