"""Kleine Notenschrift für den Katalog (Blattform, Schritt 3).

Eine Zeile ist eine Folge von Token, Takte durch `|` getrennt (nur zur Prüfung):

    R16>  Hand R, Sechzehntel, Akzent        -8    Achtelpause
    L8.   Hand L, punktierte Achtel          R4f   Flam: ein Vorschlag mit der anderen Hand
    R8d   Drag: zwei Vorschläge              R16g  Ghost
    3(R8 L8 R8)  Achteltriole                6(R16 L16 R16 L16 R16 R16)  Sextole

Flags in beliebiger Reihenfolge: . > g f d. Werte: 1 2 4 8 16 32.

Spuren (Phase B.1): ein Kit-Takt hat eine Zeile je Instrument, Kopf `HH:`
(Tabelle TRACKS). Hände spielen `R L`, Füße `K` (Kick) und `P` (Hi-Hat-Pedal);
`T1~:` setzt die Instrument-Klasse (`accepts`). Alle Spuren gleich lang.
Aus derselben Quelle entstehen die abcjs-Kurationsseite und der Dart-Code
(etude_dsl: note / rest / flam / drag / line). Reines Python, kein Flutter.
"""
from __future__ import annotations

import re
from dataclasses import dataclass

TPQ = 24  # Ticks je Viertel, wie PatternPlayback / countLabelsFor
_TOKEN = re.compile(r'^([RLKP])(32|16|8|4|2|1)([.>gfdrl]*)$')
_REST = re.compile(r'^-(32|16|8|4|2|1)(\.?)$')


@dataclass
class Note:
    hand: str | None  # 'R' | 'L' | None (Pause)
    value: int  # 1 2 4 8 16 32
    dotted: bool = False
    accent: bool = False
    ghost: bool = False
    graces: int = 0  # 0, 1 (Flam), 2 (Drag)
    tuplet: int = 0  # 0, 3 (Triole), 6 (Sextole)
    side: str | None = None  # Fußseite 'R' | 'L' (Doppelfuß), nur K/P

    @property
    def rest(self) -> bool:
        return self.hand is None

    @property
    def is_foot(self) -> bool:
        return self.hand in ('K', 'P')

    def quarters(self) -> float:
        q = 4.0 / self.value * (1.5 if self.dotted else 1.0)
        if self.tuplet:
            q *= 2 / 3
        return q

    def ticks(self) -> int:
        t = self.quarters() * TPQ
        if abs(t - round(t)) > 1e-6:
            raise ValueError(f'note {self} is not on the 24-tick grid')
        return int(round(t))


@dataclass
class Line:
    notes: list[Note]
    repeat: bool = True
    title: str | None = None
    counts: bool = False
    bars: int = 0


def parse_line(text: str, beats_per_bar: int = 4, *, repeat: bool = True,
               title: str | None = None, counts: bool = False) -> Line:
    """Parst eine Zeile und prüft ganze Takte (1..8) und das 24er-Raster."""
    notes: list[Note] = []
    tuplet = 0
    bar_ticks = beats_per_bar * TPQ
    acc = 0
    bars_seen = 0
    for raw in text.split():
        tok = raw
        if tok == '|':
            if acc != bar_ticks:
                raise ValueError(f'bar {bars_seen + 1} has {acc / TPQ:g} quarters in: {text}')
            acc = 0
            bars_seen += 1
            continue
        m = re.match(r'^([36])\((.*)$', tok)
        if m:
            if tuplet:
                raise ValueError(f'nested tuplet in: {text}')
            tuplet = int(m.group(1))
            tok = m.group(2)
        closing = tok.endswith(')')
        if closing:
            tok = tok[:-1]
        if tok:
            n = _parse_token(tok)
            n.tuplet = tuplet
            notes.append(n)
            acc += n.ticks()
        if closing:
            if not tuplet:
                raise ValueError(f'stray ) in: {text}')
            tuplet = 0
    if tuplet:
        raise ValueError(f'unclosed tuplet in: {text}')
    if acc != bar_ticks:
        raise ValueError(f'last bar has {acc / TPQ:g} quarters in: {text}')
    bars = bars_seen + 1
    if not 1 <= bars <= 8:
        raise ValueError(f'{bars} bars in one line: {text}')
    return Line(notes, repeat=repeat, title=title, counts=counts, bars=bars)


def _parse_token(tok: str) -> Note:
    m = _REST.match(tok)
    if m:
        return Note(None, int(m.group(1)), dotted=bool(m.group(2)))
    m = _TOKEN.match(tok)
    if not m:
        raise ValueError(f'bad token {tok!r}')
    hand, value, flags = m.groups()
    n = Note(hand, int(value))
    n.dotted = '.' in flags
    n.accent = '>' in flags
    n.ghost = 'g' in flags
    n.graces = 2 if 'd' in flags else 1 if 'f' in flags else 0
    if n.is_foot and n.graces:
        raise ValueError(f'foot note {tok!r} cannot carry a flam/drag')
    sides = [s for s in 'rl' if s in flags]
    if sides:
        if not n.is_foot:
            raise ValueError(f'side flag on a hand note {tok!r} (r/l belong to K/P)')
        if len(sides) > 1:
            raise ValueError(f'both sides on {tok!r}')
        n.side = sides[0].upper()
    return n


# ── Spuren (Phase B.1): eine Zeile je Instrument ─────────────────────────────

TRACKS: dict[str, tuple[str, bool]] = {  # Spurkopf → (KitInstrument, Fuß?)
    'HH': ('hiHatClosed', False), 'HO': ('hiHatOpen', False), 'HP': ('hiHatPedal', True),
    'SN': ('snare', False), 'SR': ('snareRim', False), 'BD': ('kick', True),
    'T1': ('tom1', False), 'T2': ('tom2', False), 'F1': ('floorTom1', False), 'F2': ('floorTom2', False),
    'C1': ('crash1', False), 'C2': ('crash2', False), 'RD': ('ride', False), 'RB': ('rideBell', False),
    'CH': ('china', False), 'SP': ('splash', False),
}
CLASSES: dict[str, str] = {  # Spurkopf mit `~` → InstrumentClass (Brief B.3)
    'T1': 'anyTom', 'T2': 'anyTom', 'F1': 'anyTom', 'F2': 'anyTom',
    'C1': 'anyCrash', 'C2': 'anyCrash', 'CH': 'anyCrash', 'SP': 'anyCrash',
    'RD': 'anyCymbal', 'RB': 'anyCymbal', 'HH': 'anyCymbal', 'HO': 'anyCymbal',
}
_HEAD = re.compile(r'^([A-Z][A-Z0-9])(~?):\s*(.*)$')


@dataclass
class Track:
    key: str
    instrument: str
    foot: bool
    accepts: str | None
    notes: list[Note]
    bars: int


@dataclass
class KitLine:
    tracks: list[Track]
    repeat: bool = True
    title: str | None = None
    counts: bool = False
    bars: int = 0


def is_kit_text(text: str) -> bool:
    first = next((ln.strip() for ln in text.splitlines() if ln.strip()), '')
    return bool(_HEAD.match(first))


def parse_kit_line(text: str, beats_per_bar: int = 4, *, repeat: bool = True,
                   title: str | None = None, counts: bool = False) -> KitLine:
    """Eine Zeile je Spur (`HH: …`), alle Spuren gleich lang; Füße spielen K/P, Hände R/L."""
    tracks: list[Track] = []
    for raw in text.splitlines():
        raw = raw.strip()
        if not raw:
            continue
        m = _HEAD.match(raw)
        if not m:
            raise ValueError(f'track line without head: {raw!r}')
        key, tilde, body = m.groups()
        if key not in TRACKS:
            raise ValueError(f'unknown track {key!r} (known: {" ".join(TRACKS)})')
        if any(t.key == key for t in tracks):
            raise ValueError(f'track {key} twice in: {text}')
        instrument, foot = TRACKS[key]
        line = parse_line(body, beats_per_bar)
        for n in line.notes:
            if not n.rest and n.is_foot != foot:
                raise ValueError(f'{key}: {"feet play K/P" if foot else "hands play R/L"}, got {n.hand}')
        accepts = CLASSES.get(key) if tilde else None
        if tilde and accepts is None:
            raise ValueError(f'{key} has no instrument class')
        tracks.append(Track(key, instrument, foot, accepts, line.notes, line.bars))
    if not tracks:
        raise ValueError('kit line without tracks')
    bars = {t.bars for t in tracks}
    if len(bars) != 1:
        raise ValueError(f'tracks differ in length: {sorted(bars)} bars in: {text}')
    return KitLine(tracks, repeat=repeat, title=title, counts=counts, bars=bars.pop())


# ── Zählhilfe (identisch zur Dart-Regel countLabelsFor) ───────────────────────

def count_labels(line: Line, beats_per_bar: int = 4) -> list[str | None]:
    out: list[str | None] = []
    tick = 0
    for n in line.notes:
        ticks = n.ticks()
        if n.rest:
            out.append(None)
            tick += ticks
            continue
        in_bar = tick % (beats_per_bar * TPQ)
        beat = in_bar // TPQ + 1
        t = in_bar % TPQ
        if t == 0:
            label: str | None = str(beat)
        elif n.tuplet:
            label = {8: '+', 16: 'a'}.get(t)
        else:
            label = {6: 'e', 12: '+', 18: 'a'}.get(t)
        out.append(label)
        tick += ticks
    return out


# ── abcjs ────────────────────────────────────────────────────────────────────

def _abc_len(value: int, dotted: bool) -> str:
    # L:1/8 — Achtel = 1
    base = {1: 8, 2: 4, 4: 2, 8: 1, 16: 0.5, 32: 0.25}[value]
    if dotted:
        base *= 1.5
    if base == 1:
        return ''
    if base == int(base):
        return str(int(base))
    return {0.5: '/', 0.25: '//', 0.75: '3/4', 1.5: '3/2', 0.375: '3/8'}[base]


def line_to_abc(line: Line, beats_per_bar: int = 4,
                marks: dict[int, str] | None = None) -> str:
    """Notenzeile als ABC-Takte; Balkengruppen je Zählzeit, Pausen brechen sie.

    `marks` schreibt Text über den ersten Schlag eines Takts (Taktindex ab 0),
    z. B. {3: 'Fill'} — nur für die Kurationsseite.
    """
    bar_ticks = beats_per_bar * TPQ
    bars: list[list[str]] = [[]]
    beat: list[str] = []
    tick = 0
    run = 0
    notes = line.notes
    for i, n in enumerate(notes):
        if n.tuplet and i > 0 and notes[i - 1].tuplet == n.tuplet:
            run += 1
        else:
            run = 0
        tok = ''
        if marks and tick % bar_ticks == 0 and (tick // bar_ticks) in marks:
            tok += f'"^{marks[tick // bar_ticks]}"'
        if n.tuplet and run % n.tuplet == 0:
            tok += f'({n.tuplet}'
        if n.rest:
            tok += 'z' + _abc_len(n.value, n.dotted)
        else:
            if n.graces:
                tok += '{' + 'B' * n.graces + '}'
            if n.accent:
                tok += '!>!'
            tok += 'B' + _abc_len(n.value, n.dotted)
        beat.append(tok)
        tick += n.ticks()
        next_rest = i + 1 < len(notes) and notes[i + 1].rest
        if tick % TPQ == 0 or n.rest or next_rest:
            bars[-1].append(''.join(beat))
            beat = []
        if tick % bar_ticks == 0 and i + 1 < len(notes):
            bars.append([])
    if beat:
        bars[-1].append(''.join(beat))
    body = ' | '.join(' '.join(b) for b in bars)
    return f'|: {body} :|' if line.repeat else f'{body} |'


# ── abcjs, Kit: zwei Stimmen auf einem Schlagzeug-System ─────────────────────

_ABC_PITCH = {'HP': 'D', 'BD': 'F', 'F2': 'G', 'F1': 'A', 'SN': 'c', 'SR': 'c', 'T2': 'd', 'T1': 'e',
              'RD': 'f', 'RB': '^f', 'HH': 'g', 'HO': 'g', 'C1': 'a', 'C2': 'a', 'CH': 'a', 'SP': 'a'}
# Glocke: eigene Tonhöhe `^f` (gleiche Linie wie die Ride, abcjs zeichnet im perc-Schlüssel mit
# percmap kein Kreuz) mit Rautenkopf (`harmonic`); offene Hat: „o" darüber.
_ABC_DECO = {'HO': '!open!'}
KIT_ABC_HEADER = ('X:1\nT:\nM:4/4\nL:1/8\nK:perc\n%%stretchlast 1\n%%staffsep 110\n'
                  '%%score (H F)\nV:H clef=perc stem=up\nV:F clef=perc stem=down\n'
                  '%%percmap D 44 x\n%%percmap F 36\n%%percmap G 43\n%%percmap A 45\n%%percmap c 38\n'
                  '%%percmap d 47\n%%percmap e 48\n%%percmap f 51 x\n%%percmap ^f 53 harmonic\n'
                  '%%percmap g 42 x\n%%percmap a 49 x\n')

# Lücke (Ticks, am Schlag gedeckelt) → (Wert, punktiert, Tuplet), größter passender Wert.
_GAP_VALUES = [(24, 4, False, 0), (18, 8, True, 0), (16, 4, False, 3), (12, 8, False, 0), (9, 16, True, 0),
               (8, 8, False, 3), (6, 16, False, 0), (4, 16, False, 6), (3, 32, False, 0), (2, 32, False, 3)]


def _value_for_gap(ticks: int) -> tuple[int, int, bool, int]:
    for entry in _GAP_VALUES:
        if entry[0] <= ticks:
            return entry
    raise ValueError(f'gap of {ticks} tick(s) is not drawable')


def _layer_tokens(tracks: list[Track], total: int, *, feet: bool) -> list[tuple[int, str]]:
    """(Tick, ABC-Token) je Einsatz/Pause einer Schicht — Akkord je Spalte, Pausen bis zum nächsten Einsatz.

    Je Zählzeit gerechnet (Lücken sind am Schlag gedeckelt). Eine Zählzeit mit Triolen/Sextolen
    wird auf das Tuplet-Raster (8 bzw. 4 Ticks) gelegt, Pausen füllen die Lücken (in Tuplets auch bei den
    Füßen sichtbar `z`, weil abcjs eine unsichtbare `x` dort nicht setzen kann), und der erste
    Token trägt die ABC-Klammer `(3` bzw. `(6:4:6` (wie `line_to_abc` bei den Pad-Zeilen)."""
    by_tick: dict[int, list[tuple[Track, Note]]] = {}
    tuplet_of: dict[int, int] = {}  # Zählzeit → Tuplet (0 = gerade)
    for t in tracks:
        tick = 0
        for n in t.notes:
            if not n.rest:
                by_tick.setdefault(tick, []).append((t, n))
                beat = tick // TPQ
                if n.tuplet and tuplet_of.get(beat, n.tuplet) != n.tuplet:
                    raise ValueError(f'beat {beat + 1}: triplets and sextuplets mixed in one layer')
                if n.tuplet:
                    tuplet_of[beat] = n.tuplet
            tick += n.ticks()
    rest_ch = 'x' if feet else 'z'

    def note_token(tick: int, length: str) -> str:
        notes = by_tick[tick]
        deco = '!>!' if any(n.accent for _, n in notes) else ''
        deco += ''.join(sorted({_ABC_DECO[t.key] for t, _ in notes if t.key in _ABC_DECO}))
        grace = '{B}' if any(n.graces for _, n in notes) else ''
        pitch_set = sorted({_ABC_PITCH[t.key] for t, _ in notes}, key=lambda p: (p[-1].islower(), p[-1], p))
        body = pitch_set[0] if len(pitch_set) == 1 else f'[{"".join(pitch_set)}]'
        return f'{grace}{deco}{body}{length}'

    out: list[tuple[int, str]] = []
    for beat in range(total // TPQ):
        start, end = beat * TPQ, (beat + 1) * TPQ
        tup = tuplet_of.get(beat, 0)
        first = len(out)
        if tup:
            unit = TPQ // tup
            value = 8 if tup == 3 else 16
            for tick in range(start, end, unit):
                length = _abc_len(value, False)
                # In Tuplets immer sichtbare Pause: abcjs 6.4.4 bricht bei `x` in `(3…` ab.
                out.append((tick, note_token(tick, length) if tick in by_tick else 'z' + length))
            out[first] = (start, ('(3' if tup == 3 else '(6:4:6') + out[first][1])
            continue
        ticks = [t for t in sorted(by_tick) if start <= t < end]
        cursor = start

        def rests(up_to: int) -> None:
            nonlocal cursor
            while cursor < up_to:
                g, value, dotted, _ = _value_for_gap(up_to - cursor)
                out.append((cursor, rest_ch + _abc_len(value, dotted)))
                cursor += g

        for i, tick in enumerate(ticks):
            rests(tick)
            nxt = ticks[i + 1] if i + 1 < len(ticks) else end
            g, value, dotted, _ = _value_for_gap(nxt - tick)
            out.append((tick, note_token(tick, _abc_len(value, dotted))))
            cursor = tick + g
        rests(end)
    return out


def kit_line_to_abc(kl: KitLine, beats_per_bar: int = 4, marks: dict[int, str] | None = None) -> str:
    bar_ticks = beats_per_bar * TPQ
    total = kl.bars * bar_ticks

    def voice(tokens: list[tuple[int, str]]) -> str:
        bars: list[list[str]] = [[] for _ in range(kl.bars)]
        for tick, tok in tokens:
            b = tick // bar_ticks
            if marks and tick % bar_ticks == 0 and b in marks:
                tok = f'"^{marks[b]}"' + tok
            bars[b].append((tick // TPQ, tok))

        def bar_text(bar: list[tuple[int, str]]) -> str:
            # Eine Zählzeit ohne Leerzeichen = ein Balken (ABC bricht Balken an Leerzeichen).
            beats: dict[int, list[str]] = {}
            for beat, tok in bar:
                beats.setdefault(beat, []).append(tok)
            return ' '.join(''.join(toks) for toks in beats.values())

        body = ' | '.join(bar_text(b) for b in bars)
        return f'|: {body} :|' if kl.repeat else f'{body} |'

    hands = _layer_tokens([t for t in kl.tracks if not t.foot], total, feet=False)
    feet = _layer_tokens([t for t in kl.tracks if t.foot], total, feet=True)
    return f'[V:H] {voice(hands)}\n[V:F] {voice(feet)}\n'


def sticking_words(line: Line) -> str:
    out = []
    for n in line.notes:
        if n.rest:
            continue
        out.append(f'({n.hand.lower()})' if n.ghost else n.hand)
    return ' '.join(out)


def counts_words(line: Line, beats_per_bar: int = 4) -> str:
    """Zweite Textzeile; `*` lässt eine Note ohne Silbe aus (abc)."""
    labels = count_labels(line, beats_per_bar)
    return ' '.join((c or '*') for n, c in zip(line.notes, labels) if not n.rest)


# ── Dart (etude_dsl) ─────────────────────────────────────────────────────────

_VALUE_NAMES = {1: 'whole', 2: 'half', 4: 'quarter', 8: 'eighth',
                16: 'sixteenth', 32: 'thirtySecond'}


def note_to_dart(n: Note) -> str:
    v = f'NoteValue.{_VALUE_NAMES[n.value]}'
    extras = []
    if n.dotted:
        extras.append('dotted: true')
    if n.tuplet:
        extras.append('tuplet: Tuplet.' + ('triplet' if n.tuplet == 3 else 'sextuplet'))
    if n.rest:
        return f'rest({v}' + (', ' + ', '.join(extras) if extras else '') + ')'
    if n.is_foot:
        args = []
        if n.accent:
            args.append('accent: true')
        if n.ghost:
            args.append('ghost: true')
        if n.side:
            args.append(f'side: {n.side}')
        args += extras
        return f'foot({v}' + (', ' + ', '.join(args) if args else '') + ')'
    args = []
    if n.accent:
        args.append('accent: true')
    if n.ghost:
        args.append('ghost: true')
    if n.graces and not extras and not n.ghost:
        fn = 'flam' if n.graces == 1 else 'drag'
        return f'{fn}({n.hand}, {v}' + (', accent: true' if n.accent else '') + ')'
    if n.graces:
        other = 'L' if n.hand == 'R' else 'R'
        args.append('graces: [' + ', '.join([other] * n.graces) + ']')
    args += extras
    return f'note({n.hand}, {v}' + (', ' + ', '.join(args) if args else '') + ')'


def line_to_dart(line: Line, indent: str = '  ') -> str:
    parts = [note_to_dart(n) for n in line.notes]
    opts = []
    if not line.repeat:
        opts.append('repeat: false')
    if line.title:
        opts.append(f"title: '{line.title}'")
    if line.counts:
        opts.append('counts: true')
    body = '\n'.join(indent + '  ' + p + ',' for p in parts)
    tail = (', ' + ', '.join(opts)) if opts else ''
    return f'{indent}line([\n{body}\n{indent}]{tail}),'


def voice_to_dart(t: Track, indent: str = '  ') -> str:
    notes = '\n'.join(indent + '    ' + note_to_dart(n) + ',' for n in t.notes)
    tail = f', accepts: InstrumentClass.{t.accepts}' if t.accepts else ''
    return f'{indent}  voice(KitInstrument.{t.instrument}, [\n{notes}\n{indent}  ]{tail}),'


def kit_line_to_dart(kl: KitLine, indent: str = '  ') -> str:
    opts = []
    if not kl.repeat:
        opts.append('repeat: false')
    if kl.title:
        opts.append(f"title: '{kl.title}'")
    if kl.counts:
        opts.append('counts: true')
    body = '\n'.join(voice_to_dart(t, indent) for t in kl.tracks)
    tail = (', ' + ', '.join(opts)) if opts else ''
    return f'{indent}kitLine([\n{body}\n{indent}]{tail}),'


def sheet_bars(lines: list[Line | KitLine]) -> int:
    return sum(ln.bars for ln in lines)


def check_sheet(lines: list[Line | KitLine]) -> None:
    total = sheet_bars(lines)
    if total > 64:
        raise ValueError(f'sheet has {total} bars (> 64)')


def check_hands(kl: KitLine) -> None:
    """Eine Hand spielt nie zwei Trommeln auf einmal: zwei Hand-Spuren mit demselben Buchstaben
    (R/L) auf demselben Einsatz-Tick sind ein Fehler. Füße sind ausgenommen; ein Vorschlag
    (Flam/Drag) zählt als Gegenhand auf dem Tick seiner Hauptnote."""
    seen: dict[tuple[int, str], str] = {}
    for t in kl.tracks:
        if t.foot:
            continue
        tick = 0
        for n in t.notes:
            if not n.rest:
                hands = [n.hand] + ([{'R': 'L', 'L': 'R'}[n.hand]] if n.graces else [])
                for h in hands:
                    other = seen.get((tick, h))
                    if other is not None and other != t.key:
                        bar, at = divmod(tick, 4 * TPQ)
                        raise ValueError(f'hand {h} on {other} and {t.key} at tick {tick} '
                                         f'(bar {bar + 1}, beat {at / TPQ + 1:g})')
                    seen[(tick, h)] = t.key
            tick += n.ticks()
