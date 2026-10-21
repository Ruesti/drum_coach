"""Geführte Übung (Plan 2 Katalog): ein Grundgroove + 3-5 Variationen mit gesprochener
englischer Erklärung. Daten + Formprüfung, Muster wie blatt.Sheet.
"""
from __future__ import annotations

import re
from dataclasses import dataclass

from sheetlang import KitLine, Line, check_hands, parse_kit_line, parse_line

PACKAGES = ('kit', 'pad')
DIFFICULTIES = ('beginner', 'intermediate', 'advanced', 'professional')
MAX_WORDS = 16


@dataclass(frozen=True)
class Variation:
    line: str  # Pad-Token oder Kit-Spurentext ("HH: …\nSN: …\nBD: …")
    text: str  # englische Erklärung, angezeigt und gesprochen
    after: str | None = 'after_good'  # Clip nach dieser Variation; None bei der letzten


@dataclass(frozen=True)
class GuidedSheet:
    id: str
    name: str
    description: str
    package: str  # 'kit' | 'pad'
    difficulty: str  # beginner|intermediate|advanced|professional
    default_bpm: int
    min_bpm: int
    max_bpm: int
    grid: str  # NoteGrid-Name wie blatt.Sheet.grid (nur gespeichert, Dart prüft)
    groove: str
    variations: tuple[Variation, ...]
    groove_bars: int = 12
    variation_bars: int = 24

    def _err(self, field: str, msg: str) -> ValueError:
        return ValueError(f'{self.id} {field}: {msg}')

    def _parse(self, text: str, where: str) -> Line | KitLine:
        try:
            if self.package == 'kit':
                ln = parse_kit_line(text)
                check_hands(ln)
            else:
                ln = parse_line(text)
        except ValueError as e:
            raise self._err(where, str(e)) from None
        # the parsers already enforce whole 4/4 bars and equal track lengths
        if ln.bars not in (1, 2):
            raise self._err(where, f'{ln.bars} bars, expected 1 or 2 whole 4/4 bars')
        return ln

    def _check_fields(self) -> None:
        if not re.fullmatch(r'guided_[a-z0-9_]+', self.id):
            raise self._err('id', "must match guided_[a-z0-9_]+")
        if self.id.startswith('demo_'):
            raise self._err('id', 'demo ids are reserved')
        if self.package not in PACKAGES:
            raise self._err('package', f'{self.package!r} not in {PACKAGES}')
        if self.difficulty not in DIFFICULTIES:
            raise self._err('difficulty', f'{self.difficulty!r} not in {DIFFICULTIES}')
        if not 40 <= self.min_bpm <= self.default_bpm <= self.max_bpm <= 240:
            raise self._err('bpm', 'need 40 <= min <= default <= max <= 240')
        if not 3 <= len(self.variations) <= 5:
            raise self._err('variations', f'{len(self.variations)} variations, expected 3-5')
        for i, v in enumerate(self.variations, 1):
            last = i == len(self.variations)
            if last and v.after is not None:
                raise self._err(f'variation {i} after', 'last variation must have after=None')
            if not last and v.after is None:
                raise self._err(f'variation {i} after', 'only the last variation may have after=None')
            n = len(v.text.split())
            if n == 0 or n > MAX_WORDS:
                raise self._err(f'variation {i} text', f'{n} words, expected 1-{MAX_WORDS}')
            if any(ord(c) >= 128 for c in v.text):
                raise self._err(f'variation {i} text', 'ASCII only (no emojis, no typographic dashes)')

    def parsed(self) -> tuple[Line | KitLine, list[Line | KitLine]]:
        self._check_fields()
        groove = self._parse(self.groove, 'groove')
        vs = [self._parse(v.line, f'variation {i}') for i, v in enumerate(self.variations, 1)]
        return groove, vs

    def clip_id(self, n: int) -> str:
        return f'g_{self.id}_v{n}'


def check_catalog(sheets: list[GuidedSheet]) -> None:
    seen: set[str] = set()
    for s in sheets:
        if s.id in seen:
            raise ValueError(f'{s.id}: duplicate id')
        seen.add(s.id)
        s.parsed()
