"""Kleine Notenschrift für den Katalog (Blattform, Schritt 3).

Eine Zeile ist eine Folge von Token, Takte durch `|` getrennt (nur zur Prüfung):

    R16>  Hand R, Sechzehntel, Akzent        -8    Achtelpause
    L8.   Hand L, punktierte Achtel          R4f   Flam: ein Vorschlag mit der anderen Hand
    R8d   Drag: zwei Vorschläge              R16g  Ghost
    3(R8 L8 R8)  Achteltriole                6(R16 L16 R16 L16 R16 R16)  Sextole

Flags in beliebiger Reihenfolge: . > g f d. Werte: 1 2 4 8 16 32.
Aus derselben Quelle entstehen die abcjs-Kurationsseite und der Dart-Code
(etude_dsl: note / rest / flam / drag / line). Reines Python, kein Flutter.
"""
from __future__ import annotations

import re
from dataclasses import dataclass

TPQ = 24  # Ticks je Viertel, wie PatternPlayback / countLabelsFor
_TOKEN = re.compile(r'^([RL])(32|16|8|4|2|1)([.>gfd]*)$')
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

    @property
    def rest(self) -> bool:
        return self.hand is None

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
    return n


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


def line_to_abc(line: Line, beats_per_bar: int = 4) -> str:
    """Notenzeile als ABC-Takte; Balkengruppen je Zählzeit, Pausen brechen sie."""
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


def sheet_bars(lines: list[Line]) -> int:
    return sum(ln.bars for ln in lines)


def check_sheet(lines: list[Line]) -> None:
    total = sheet_bars(lines)
    if total > 64:
        raise ValueError(f'sheet has {total} bars (> 64)')
