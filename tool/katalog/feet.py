"""Sieben Fuß-Blätter (Phase B.4c): Kick, Double Bass, Hi-hat-Fuß, Ostinati.

Jedes Blatt: 8 Zeilen à 2 Takte mit Wiederholung, als
Spuren (sheetlang: `HH: … / SN: … / BD: …`). Die Hände halten einfache Time,
die Füße tragen die Übung: Kick-Kontrolle, Sechzehntel-Kombinationen, Double
Bass mit Fußseiten (`K8r`/`K8l`, R/L nur in der App), Hi-hat-Fuß und
Fuß-Ostinati unter Latin- und Jazz-Händen. Regel (Uli, 30.09.): so
abwechslungsreich und groovy wie möglich. Texte Englisch (App-Sprache).
"""
from __future__ import annotations

from blatt import Sheet, print_table
from grooves import (
    BD1_3A, BD13, BD_ALL, BD_DBL, BD_SW, C1_1, HH8, HH16, HH16A, HP24, HP_ALL, RIDE8, RIDE_SW,
    RIDE_SW_A, SHUF, SHUF_NO1, SN3, SN24, SN24G, SN_SW2, SN_SW4, SR4, kit, two,
)

# ── Takt-Vokabular (je ein Takt) ─────────────────────────────────────────────
# Hände
HHQ = 'R4 R4 R4 R4'
HHQ_NO1 = '-4 R4 R4 R4'  # die Eins gehört dem Crash
RDQ = 'R4 R4 R4 R4'  # Ride-Viertel (Spur RD)
RB_Q = 'R4 R4 R4 R4'  # Glocken-Viertel (Spur RB)
BON_SN = '3(R8 L8 -8) 3(R8 L8 -8) 3(R8 L8 -8) 3(R8 L8 -8)'  # Bonham-Dreier: Hände 1+2 der Triole
BOSSA_SR = 'L4 -8 L8 -4 L4'  # Cross-Stick auf 1, „2 +", 4 (Bossa-Clave)
# Samba-Snare: Sechzehntel R L, Akzent auf jedem dritten (1 +, 2 e, 3, 3 a, 4 +)
SAMBA_SN = 'R16g L16g R16> L16g R16g L16> R16g L16g R16> L16g R16g L16> R16g L16g R16> L16g'
# Kick Control (ohne Seite)
BD_AND = '-8 K8 -4 -8 K8 -4'  # nur „1 +" und „3 +"
BD_1E = 'K16 K16 -8 -4 K16 K16 -8 -4'  # Doppel auf 1 e, 3 e
BD_3A = 'K4 -4 -8. K16 -4'  # 1 und „3 a"
BD_GAPS = '-4 K4 -4 -8 K8'  # 2 und „4 +"
BD_MIX = 'K4 -8 K8 -8. K16 K4'  # 1, „2 +", „3 a", 4
# Kick Sixteenths — eine Kombination je Zählzeit auf 1 und 3, 2 und 4 Pause
BD_C_1E = 'K16 K16 -8 -4 K16 K16 -8 -4'
BD_C_1A = 'K8. K16 -4 K8. K16 -4'
BD_C_1PA = 'K8 K16 K16 -4 K8 K16 K16 -4'
BD_C_EP = '-16 K16 K8 -4 -16 K16 K8 -4'
BD_C_EA = '-16 K16 -16 K16 -4 -16 K16 -16 K16 -4'
BD_C_ALL = 'K16 K16 K16 K16 -4 K16 K16 K16 K16 -4'
BD_C_PA = '-8 K16 K16 -4 -8 K16 K16 -4'
BD_C_A1 = '-8. K16 K4 -8. K16 K4'  # „a" von 1 in die 2, „a" von 3 in die 4
# Double Bass (mit Seite)
BD_R8 = 'K8r K8l K8r K8l K8r K8l K8r K8l'
BD_L8 = 'K8l K8r K8l K8r K8l K8r K8l K8r'  # linker Fuß führt
BD_R8_13 = 'K8r K8l -4 K8r K8l -4'  # Paare auf 1 und 3, Pause auf 2 und 4
BD_R8_ANDS = '-8 K8r K8l -8 -8 K8r K8l -8'  # Paare ab „1 +" und „3 +" in die 2 und die 4
BD_R8_332 = 'K8r> K8l K8r K8l> K8r K8l K8r> K8l'  # 3+3+2: Akzente auf 1, „2 +", 4
BD_R8_H = 'K8r K8l K8r K8l K4r K4r'  # halber Takt Teppich, dann Viertel
BD_R8_BURST = 'K4r -4 K8r K8l K8r K8l'  # Ausbruch auf 3–4
HH_332 = 'R4.> R4.> R4>'  # Hi-Hat mit den 3+3+2-Akzenten der Füße
BD_R16 = 'K16r K16l K16r K16l K16r K16l K16r K16l K16r K16l K16r K16l K16r K16l K16r K16l'
BD_R16_H = 'K16r K16l K16r K16l K16r K16l K16r K16l K4r K4r'
BD_R16_B3 = 'K4r K4r K16r K16l K16r K16l K4r'  # Burst auf 3
BD_R16_GAP = 'K16r K16l K16r -16 K16r K16l K16r -16 K16r K16l K16r -16 K16r K16l K16r -16'  # Lücke auf „a"
BD_R16_24 = 'K4r K16r K16l K16r K16l K4r K16r K16l K16r K16l'  # Teppich nur auf 2 und 4
BD_GALLOP = 'K8r K16r K16l K8r K16r K16l K8r K16r K16l K8r K16r K16l'  # Galopp 8-16-16 je Zählzeit (R R L)
BD_R3 = '3(K8r K8l K8r) 3(K8l K8r K8l) 3(K8r K8l K8r) 3(K8l K8r K8l)'
BD_R3_24 = 'K4r 3(K8l K8r K8l) K4r 3(K8l K8r K8l)'
BD_R6 = ('6(K16r K16l K16r K16l K16r K16l) 6(K16r K16l K16r K16l K16r K16l) '
         '6(K16r K16l K16r K16l K16r K16l) 6(K16r K16l K16r K16l K16r K16l)')
BD_R6_B = 'K4r K4r 6(K16r K16l K16r K16l K16r K16l) K4r'  # Sextolen-Burst auf 3
BD_R3_PAIR = '3(K8r K8l -8) 3(K8r K8l -8) 3(K8r K8l -8) 3(K8r K8l -8)'  # Paare auf 1 und „trip", Pause auf „let"
BD_FSHUF = '3(K8r -8 K8l) 3(K8r -8 K8l) 3(K8r -8 K8l) 3(K8r -8 K8l)'  # Fuß-Shuffle
BON_BD = '3(-8 -8 K8r) 3(-8 -8 K8r) 3(-8 -8 K8r) 3(-8 -8 K8r)'  # Bonham-Dreier: Kick auf der 3. Triole
# Hi-hat-Fuß / Ostinati
HP_OFF = '-8 P8 -8 P8 -8 P8 -8 P8'  # Chick auf jedem „+"
SAMBA_BD = 'K8. K16 K8. K16 K8. K16 K8. K16'  # Kick auf 1 und „a" jeder Zählzeit
BOSSA_BD = 'K4 -8 K8 K4 -8 K8'  # 1, „2 +", 3, „4 +"


def feet_sheet(**kw) -> Sheet:
    """Wie `grooves.groove`, aber `limbs` und `skills` gibt jedes Blatt selbst an."""
    kw.setdefault('kit', True)
    kw.setdefault('line_bars', 2)
    kw.setdefault('new_seed', True)
    kw.setdefault('genres', [])
    return Sheet(**kw)


def _hands(bd: str, hh: str = HH8) -> dict[str, str]:
    return {'HH': hh, 'SN': SN24, 'BD': bd}


# Kick Control
KC = [_hands(BD13), _hands(BD1_3A), _hands(BD_DBL), _hands(BD_AND),
      _hands(BD_1E), _hands(BD_3A), _hands(BD_ALL)]
KC_8 = (_hands(BD_GAPS), _hands(BD_MIX))

# Kick Sixteenths
KS = [_hands(BD_C_1E), _hands(BD_C_1A), _hands(BD_C_1PA), _hands(BD_C_EP),
      _hands(BD_C_EA, HH16), _hands(BD_C_ALL, HH16), _hands(BD_C_PA, HH16), _hands(BD_C_A1, HH16)]

# Double Bass Eighths — jede Zeile eine eigene Idee (S23-Test 16.10.: „die Zeilen unterscheiden sich kaum")
DB8_1 = {'HH': HHQ, 'SN': SN24, 'BD': BD_R8}  # Grundteppich, rechts führt
DB8_2 = {'HH': HHQ, 'SN': SN24, 'BD': BD_L8}  # links führt
DB8_3 = {'HH': HH8, 'SN': SN24, 'BD': BD_R8_13}  # Paare auf 1 und 3, Hi-Hat-Achtel
DB8_4 = {'RD': RDQ, 'SN': SN24, 'BD': BD_R8_ANDS}  # Paare auf den „+", Ride
DB8_5 = {'HH': HH_332, 'SN': SN24, 'BD': BD_R8_332}  # 3+3+2 mit Akzenten
DB8_6 = {'RD': RDQ, 'SN': SN24, 'BD': BD_R8_H}  # halber Takt Teppich, dann Viertel, Ride
DB8_7 = {'HH': HH8, 'SN': SN3, 'BD': BD_R8}  # Half-time: Snare nur auf 3
DB8_8A = {'C1~': C1_1, 'HH': HHQ_NO1, 'SN': SN24, 'BD': BD13}  # Crash, schlichte 1 und 3
DB8_8B = {'HH': HHQ, 'SN': SN24, 'BD': BD_R8_BURST}  # Ausbruch auf 3–4

# Double Bass Sixteenths
DB16_1 = {'HH': HHQ, 'SN': SN24, 'BD': BD_R16}
DB16_3 = {'HH': HHQ, 'SN': SN24, 'BD': BD_R16_B3}
DB16_4 = {'HH': HHQ, 'SN': SN3, 'BD': BD_R16}
DB16_8 = {'HH': HHQ, 'SN': SN24, 'BD': BD_R16_24}

# Double Bass Triplets
DB3_1 = {'HH': SHUF, 'SN': SN24, 'BD': BD_R3}
DB3_3 = {'HH': SHUF, 'SN': SN24, 'BD': BD_FSHUF}
DB3_4 = {'SN': BON_SN, 'BD': BON_BD}  # Bonham-Dreier: Hände R L, Kick — keine Hi-Hat (Hände sind belegt)
DB3_8 = {'C1~': C1_1, 'HH': SHUF_NO1, 'SN': SN24, 'BD': BD_R3}

# Hi-hat Foot
HF_1 = {'RD': RIDE8, 'SN': SN24, 'BD': BD13, 'HP': HP24}
HF_3 = {'RD': RIDE8, 'SN': SN24, 'BD': BD13, 'HP': HP_OFF}
HF_5 = {'RD': RIDE8, 'SN': SN24, 'BD': BD_DBL, 'HP': HP24}
HF_8 = {'RD': RIDE8, 'SN': SN24, 'BD': BD_MIX, 'HP': HP24}

# Foot Ostinatos
FO_1 = {'HH': HH8, 'SR': BOSSA_SR, 'BD': BOSSA_BD}
FO_3 = {'HH': HH16, 'SN': SN24, 'BD': SAMBA_BD, 'HP': HP24}
FO_5 = {'RD': RIDE_SW, 'HP': HP24, 'BD': BD_SW}
FO_8 = {'RD': RIDE_SW_A, 'HP': HP24, 'BD': BD_SW, 'SR': SR4}

LESSON_KICK_CONTROL = {
    'Why it matters': 'The kick is where the band feels the downbeat and where the bass player locks in. A kick that lands exactly under the hi-hat, at the same volume every time, makes even a simple groove sound expensive; a kick that drifts makes the whole band drift.',
    'How to play it': 'Heel up, the ball of the foot on the pedal, and let the leg drop from the hip so the beater strikes and comes straight back off the head — the hi-hat and snare stay exactly as they are while only the foot changes.',
    'Practice tips': 'Line 1 is the reference: kick on 1 and 3 locked to the hat. Lines 2 and 4 move the kick to the "and", line 3 and line 5 ask for two strokes in a row (the second one as loud as the first), line 7 is four-on-the-floor. Line 8 puts the kick on 2 and the "and" of 4 in its first bar — count out loud so the snare does not pull the foot along — and mixes 1, the "and" of 2, the "a" of 3 and 4 in its second bar.',
    'Where you hear it': 'AC/DC "Back in Black" with Phil Rudd, Led Zeppelin "When the Levee Breaks" with John Bonham, and every four-on-the-floor dance track from disco to house.',
}

LESSON_KICK_SIXTEENTHS = {
    'Why it matters': 'Most groove variation lives in the kick between the eighth notes: "1 e", "1 a", "e and". Each of these small combinations has its own feel, and being able to play any of them on demand is what lets you copy a groove from a record or follow the bass player.',
    'How to play it': 'Heel up for both strokes of a double, the first from the leg, the second a quick ankle rebound (or a short slide up the pedal) — keep both notes even and the hands completely steady above them.',
    'Practice tips': 'Every line repeats one combination on 1 and 3 and rests on 2 and 4, so you hear it clearly. Lines 1–4 keep eighth hats so the sixteenths fall between the hand strokes; lines 5–8 switch to sixteenth hats so every kick lines up with a hat stroke. Line 6 is four kicks in a row — keep it soft and even before you go faster.',
    'Where you hear it': 'David Garibaldi with Tower of Power ("What Is Hip?"), Clyde Stubblefield on James Brown "Funky Drummer", Chad Smith with the Red Hot Chili Peppers, and almost every funk and fusion groove.',
}

LESSON_DB8 = {
    'Why it matters': 'An even stream of eighths split between two feet is the first double bass skill: one foot plays the beats, the other the "ands", and together they sound like one drummer with a very fast kick. Every faster double bass pattern grows out of this, and the variations here teach you to start, stop, group and accent the stream with either foot.',
    'How to play it': 'Two pedals (or a double pedal), heel up and loose, both feet at the same height and the same volume. Line 1 is the reference: right foot on every beat, left foot on every "and", hat quarters and the backbeat on 2 and 4 above. The R and L under the feet tell you which foot plays.',
    'Practice tips': 'Line 2 is the same stream with the left foot leading — slow, until the left foot is as steady as the right. Line 3 plays a pair R L on 1 and 3 and rests on 2 and 4 under eighth hats; line 4 starts each pair on the "and" so it runs into the beat, with the right hand on the ride. Line 5 groups the eighths 3+3+2 with accents on 1, the "and" of 2 and 4, and the hat plays the same accents. Line 6 is half a bar of stream and two right-foot quarters on the ride, line 7 the full stream under a half-time snare on 3 and eighth hats, line 8 a crash with a plain 1 and 3 and then a burst on 3 and 4. Start slow — 60 is fine.',
    'Where you hear it': 'Motörhead "Overkill" with Phil Taylor, Judas Priest and Accept in the early-80s heavy metal era, and the steady double-bass choruses of countless metal songs before they speed up to sixteenths.',
}

LESSON_DB16 = {
    'Why it matters': 'Sixteenth double bass is the sound of thrash and modern metal: a rolling carpet under the riff that makes the music feel relentless. It is also the hardest stamina test for the feet, which is why it is practised in short bursts first.',
    'How to play it': 'R L R L on every sixteenth, right foot leads on each beat, both feet equally loud; heel up and let the ankles do most of the work at speed while the legs stay relaxed and the hands keep plain quarters and backbeats.',
    'Practice tips': 'Lines 2, 3 and 8 are bursts — half a bar, one beat, or only on 2 and 4 — so the feet rest between them. Line 1 and line 5 are the full carpet; line 4 puts it under a half-time backbeat; line 6 starts with a crash and gallops — an eighth and two sixteenths on every beat, R R L, so the left foot always leads into the next beat; line 7 leaves the "a" of every beat open, which trains the right foot to restart each group. Raise the tempo only when line 1 stays even for a whole minute.',
    'Where you hear it': 'Metallica "One" (the machine-gun outro with Lars Ulrich), Slayer with Dave Lombardo ("Raining Blood", "Angel of Death"), Dream Theater with Mike Portnoy, Pantera "Cowboys from Hell".',
}

LESSON_DB3 = {
    'Why it matters': 'Triplets between the feet give a rolling, galloping feel that straight sixteenths cannot: the accent wanders from foot to foot and the groove swings. Combined with the hands, triplets also give the famous Bonham trick of hands-hands-kick.',
    'How to play it': 'Alternate R L R, L R L so the leading foot changes every beat, both feet equally loud and heel up; for the Bonham triplet the hands play two triplet notes (R L) on the snare and the right foot finishes the group with the kick.',
    'Practice tips': 'Line 1 is the full triplet stream under a shuffle hat; line 2 rests the feet on 1 and 3, line 3 plays a foot shuffle (long-short). Line 4 is the Bonham triplet on its own — hands R L, kick — keep the three notes perfectly even. Lines 5 and 6 go to sextuplets: burst first, then the whole bar. Line 7 plays pairs R L on the first two triplet notes of every beat and rests on the third, under quarter hats and a half-time snare on 3; line 8 is the full stream with a crash on the one.',
    'Where you hear it': 'John Bonham in Led Zeppelin "Good Times Bad Times" (his famous kick triplets — he played them with one foot; this sheet splits them between both feet), the shuffle feel of "Fool in the Rain", and the rolling triplet double bass of power metal.',
}

LESSON_HIHAT_FOOT = {
    'Why it matters': 'The left foot is the drummer\'s fourth limb, and in most beginners it does nothing. A crisp hi-hat "chick" on 2 and 4 — or on every quarter — gives the groove a second pulse, frees the right hand for the ride and is the base of jazz, Latin and fusion playing.',
    'How to play it': 'Heel down and rock the toes onto the hi-hat pedal so the cymbals close with a short, crisp "chick", lift them just enough to open again — the ride, snare and kick keep going exactly as before.',
    'Practice tips': 'Line 1 is the reference: chick on 2 and 4 with the snare. Line 2 chicks every quarter, line 3 every "and" — the hardest, because foot and hand alternate. Lines 4, 5 and 8 move the kick while the left foot stays put; line 6 moves the right hand to the bell; line 7 drops the cymbal entirely so the pedal is the only time-keeper.',
    'Where you hear it': 'Jazz drummers from Philly Joe Jones to Jeff Hamilton (feathered kick, hi-hat on 2 and 4), Steve Gadd and Dave Weckl in fusion, and rock ballads where the ride takes over and the foot keeps the hat alive.',
}

LESSON_OSTINATOS = {
    'Why it matters': 'An ostinato is a foot pattern that never changes while the hands do something else. Bossa nova, samba and jazz all rest on one: once the feet run on autopilot, the hands are free to play the clave, the samba sticking or the comping above them.',
    'How to play it': 'Let the feet play the pattern alone until it runs without thinking — right foot heel up for the kick, left foot heel down on the hi-hat pedal — and then add the hands one at a time.',
    'Practice tips': 'Lines 1 and 2 are bossa nova: kick on 1, "2 +", 3, "4 +", the cross-stick clave on top. Lines 3 and 4 are samba: kick on 1 and the "a" of every beat, hi-hat foot on 2 and 4, then the hands play the accented samba sticking on the snare. Lines 5–8 are jazz: feathered quarters on the kick, chick on 2 and 4, ride pattern and comping on top.',
    'Where you hear it': 'Antônio Carlos Jobim and João Gilberto "The Girl from Ipanema" and "Desafinado" (bossa), Airto Moreira and Duduka Da Fonseca (samba on the kit), and the jazz ride-and-foot feel of Jimmy Cobb and Elvin Jones.',
}

SHEETS: list[Sheet] = [
    feet_sheet(
        id='feet_kick_control', name='Kick Control', min_bpm=60, target_bpm=130,
        difficulty='beginner', skills=['coordination'], grid='eighth', limbs=('feet',),
        description='The hands keep a plain rock beat while the kick moves: on and off the beat, doubles, four-on-the-floor.',
        pattern=kit(KC[0]),
        lines=[two(b) for b in KC] + [kit(*KC_8)],
        lesson=LESSON_KICK_CONTROL,
    ),
    feet_sheet(
        id='feet_kick_sixteenths', name='Kick Sixteenths', min_bpm=60, target_bpm=120,
        difficulty='intermediate', skills=['coordination', 'control'], grid='sixteenth', limbs=('feet',),
        description='Eight sixteenth-note kick combinations on 1 and 3 under a steady backbeat, first with eighth hats, then with sixteenths.',
        pattern=kit(KS[0]),
        lines=[two(b) for b in KS],
        lesson=LESSON_KICK_SIXTEENTHS,
    ),
    feet_sheet(
        id='feet_double_bass_eighths', name='Double Bass Eighths', min_bpm=60, target_bpm=160,
        difficulty='intermediate', skills=['endurance', 'coordination'], genres=['metal'], grid='eighth',
        limbs=('doubleBass',),
        description='Eighth notes split between two feet: either foot leading, pairs, 3+3+2 accents, half-time and bursts under hat or ride and a backbeat.',
        pattern=kit(DB8_1),
        lines=[
            two(DB8_1),
            two(DB8_2),
            two(DB8_3),
            two(DB8_4),
            two(DB8_5),
            two(DB8_6),
            two(DB8_7),
            kit(DB8_8A, DB8_8B),
        ],
        lesson=LESSON_DB8,
    ),
    feet_sheet(
        id='feet_double_bass_sixteenths', name='Double Bass Sixteenths', min_bpm=60, target_bpm=140,
        difficulty='advanced', skills=['endurance', 'coordination'], genres=['metal'], grid='sixteenth',
        limbs=('doubleBass',),
        description='Sixteenth-note double bass, right foot leading, from short bursts to a full rolling carpet under the backbeat.',
        pattern=kit(DB16_1),
        lines=[
            two(DB16_1),
            two({'HH': HHQ, 'SN': SN24, 'BD': BD_R16_H}),
            two(DB16_3),
            two(DB16_4),
            two({'HH': HH8, 'SN': SN24, 'BD': BD_R16}),
            kit({'C1~': C1_1, 'HH': HHQ_NO1, 'SN': SN24, 'BD': BD_GALLOP}, {'HH': HHQ, 'SN': SN24, 'BD': BD_GALLOP}),
            two({'HH': HHQ, 'SN': SN24, 'BD': BD_R16_GAP}),
            two(DB16_8),
        ],
        lesson=LESSON_DB16,
    ),
    feet_sheet(
        id='feet_double_bass_triplets', name='Double Bass Triplets', min_bpm=60, target_bpm=140,
        difficulty='advanced', skills=['endurance', 'coordination'], genres=['rock'], grid='triplet',
        limbs=('doubleBass',),
        description='Triplets and sextuplets between the feet under a shuffle hat, plus the Bonham triplet of hands and kick.',
        pattern=kit(DB3_1),
        lines=[
            two(DB3_1),
            two({'HH': SHUF, 'SN': SN24, 'BD': BD_R3_24}),
            two(DB3_3),
            two(DB3_4),
            two({'HH': SHUF, 'SN': SN24, 'BD': BD_R6_B}),
            two({'HH': HHQ, 'SN': SN24, 'BD': BD_R6}),
            two({'HH': HHQ, 'SN': SN3, 'BD': BD_R3_PAIR}),
            two(DB3_8),
        ],
        lesson=LESSON_DB3,
    ),
    feet_sheet(
        id='feet_hihat_foot', name='Hi-hat Foot', min_bpm=60, target_bpm=140,
        difficulty='intermediate', skills=['independence', 'coordination'], grid='eighth', limbs=('feet',),
        description='The left foot closes the hi-hat on 2 and 4, on every quarter or on every "and" while the ride, snare and kick keep a groove.',
        pattern=kit(HF_1),
        lines=[
            two(HF_1),
            two({'RD': RIDE8, 'SN': SN24, 'BD': BD13, 'HP': HP_ALL}),
            two(HF_3),
            two({'RD': RIDE8, 'SN': SN24, 'BD': BD1_3A, 'HP': HP24}),
            two(HF_5),
            two({'RB': RB_Q, 'SN': SN24, 'BD': BD13, 'HP': HP24}),
            two({'SN': SN24G, 'BD': BD13, 'HP': HP_ALL}),
            two(HF_8),
        ],
        lesson=LESSON_HIHAT_FOOT,
    ),
    feet_sheet(
        id='feet_ostinatos', name='Foot Ostinatos', min_bpm=60, target_bpm=140,
        difficulty='advanced', skills=['independence', 'groove'], genres=['latin', 'jazz'], grid='sixteenth',
        limbs=('allFour',),
        description='Foot patterns that never change — bossa nova, samba and jazz — while the hands play clave, samba sticking and ride on top.',
        pattern=kit(FO_1),
        lines=[
            two(FO_1),
            two({'RD': RIDE8, 'SR': BOSSA_SR, 'BD': BOSSA_BD, 'HP': HP24}),
            two(FO_3),
            two({'SN': SAMBA_SN, 'BD': SAMBA_BD, 'HP': HP24}),  # Hände ganz auf der Snare (keine Hi-Hat)
            two(FO_5),
            two({'RD': RIDE_SW, 'HP': HP24, 'BD': BD_SW, 'SN': SN_SW4}),
            two({'RD': RIDE_SW, 'HP': HP24, 'BD': BD_SW, 'SN': SN_SW2}),
            two(FO_8),
        ],
        lesson=LESSON_OSTINATOS,
    ),
]

if __name__ == '__main__':
    print_table(SHEETS)
