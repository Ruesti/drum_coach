"""Ein Blatt des Katalogs: Daten + Formprüfung (Katalog 3a/3b).

Ein Blatt hat 8 Zeilen gleicher Länge (`line_bars` Takte, mit Wiederholung).
Rudiment-Blätter (3a): 2 Takte je Zeile; Fill-Blätter (3b): 4 Takte je Zeile
(3 Time + 1 Fill).
"""
from __future__ import annotations

from dataclasses import dataclass

# Werte = Dart-Enum TrainingArea (lib/features/room/training_area.dart)
AREAS = ('handTechnique', 'rudiments', 'feet', 'coordination', 'groove', 'metal', 'fills')

from sheetlang import KitLine, Line, check_hands, check_sheet, parse_kit_line, parse_line


@dataclass
class Sheet:
    id: str
    name: str
    min_bpm: int
    target_bpm: int
    difficulty: str  # beginner | intermediate | advanced
    skills: list[str]
    genres: list[str]
    description: str
    pattern: str  # ein Takt, Grundgestalt (PATTERN-Kasten)
    lines: list[str]  # 8 Zeilen à line_bars Takte
    lesson: dict[str, str]
    count_lines: int = 0  # so viele erste Zeilen tragen die Zählhilfe (Kit-Blätter: immer 0)
    new_seed: bool = False  # noch nicht im Basis-Katalog
    line_bars: int = 2  # Takte je Zeile (2 Rudiment, 4 Fill)
    backing: str | None = None  # Stil-Id, None = Automatik (autoBackingStyle)
    grid: str = 'eighth'  # NoteGrid für neue Seed-Einträge
    kit: bool = False  # Spuren-Blatt (Phase B.1): Zeilen als `HH: … / SN: … / BD: …`
    limbs: tuple[str, ...] = ('hands',)  # Limb-Tags des Seed-Eintrags
    area: str | None = None  # Trainingsraum-Bereich (Dart-Enum-Name aus AREAS)
    song: str | None = None  # Songhinweis als Text ("Like in: …")
    fill_bar: bool = True  # 4-Takt-Zeile: Takt 4 ist ein Fill-Takt (Kurationsseite); Technik-Blätter: False

    def __post_init__(self):
        if self.area is not None and self.area not in AREAS:
            raise ValueError(f'{self.id}: unknown area {self.area!r}, expected one of {AREAS}')

    def _parse(self, text: str, where: str = '', **kw) -> Line | KitLine:
        if not self.kit:
            return parse_line(text, **kw)
        kl = parse_kit_line(text, **kw)
        try:
            check_hands(kl)
        except ValueError as e:
            raise ValueError(f'{self.id} {where}: {e}') from None
        return kl

    def parsed(self) -> list[Line | KitLine]:
        if self.kit and self.count_lines:
            raise ValueError(f'{self.id}: kit sheets carry no count syllables (count_lines must be 0)')
        out = [self._parse(t, f'line {i + 1}', counts=i < self.count_lines) for i, t in enumerate(self.lines)]
        check_sheet(out)
        if len(self.lines) != 8:
            raise ValueError(f'{self.id}: {len(self.lines)} lines, expected 8')
        for i, ln in enumerate(out):
            if ln.bars != self.line_bars:
                raise ValueError(f'{self.id}: line {i + 1} has {ln.bars} bars, expected {self.line_bars}')
        return out

    def pattern_line(self) -> Line | KitLine:
        ln = self._parse(self.pattern, 'pattern', repeat=False)
        if ln.bars != 1:
            raise ValueError(f'{self.id}: pattern has {ln.bars} bars, expected 1')
        return ln


def print_table(sheets: list[Sheet]) -> None:
    """Prüft alle Blätter und druckt eine Übersicht (Skript-Aufruf der Datenmodule)."""
    for s in sheets:
        lines = s.parsed()
        s.pattern_line()
        bars = sum(ln.bars for ln in lines)
        notes = sum((sum(len(t.notes) for t in ln.tracks) if isinstance(ln, KitLine) else len(ln.notes))
                    for ln in lines)
        print(f'{s.id:24s} {len(lines)} Zeilen  {bars:2d} Takte  {notes:3d} Noten')
    print(len(sheets), 'Blätter ok')
