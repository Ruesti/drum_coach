"""Ein Blatt des Katalogs: Daten + Formprüfung (Katalog 3a/3b).

Ein Blatt hat 8 Zeilen gleicher Länge (`line_bars` Takte, mit Wiederholung)
und eine Challenge über 8 Takte ohne Wiederholung. Rudiment-Blätter (3a):
2 Takte je Zeile; Fill-Blätter (3b): 4 Takte je Zeile (3 Time + 1 Fill).
"""
from __future__ import annotations

from dataclasses import dataclass

from sheetlang import Line, check_sheet, parse_line


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
    challenge: str  # 8 Takte
    lesson: dict[str, str]
    count_lines: int = 0  # so viele erste Zeilen tragen die Zählhilfe
    new_seed: bool = False  # noch nicht im Basis-Katalog
    line_bars: int = 2  # Takte je Zeile (2 Rudiment, 4 Fill)
    backing: str | None = None  # Stil-Id, None = Automatik (autoBackingStyle)
    grid: str = 'eighth'  # NoteGrid für neue Seed-Einträge

    def parsed(self) -> list[Line]:
        out = [parse_line(t, counts=i < self.count_lines) for i, t in enumerate(self.lines)]
        out.append(parse_line(self.challenge, repeat=False, title='Challenge'))
        check_sheet(out)
        if len(self.lines) != 8:
            raise ValueError(f'{self.id}: {len(self.lines)} lines, expected 8')
        for i, ln in enumerate(out[:-1]):
            if ln.bars != self.line_bars:
                raise ValueError(f'{self.id}: line {i + 1} has {ln.bars} bars, expected {self.line_bars}')
        if out[-1].bars != 8:
            raise ValueError(f'{self.id}: challenge has {out[-1].bars} bars')
        return out

    def pattern_line(self) -> Line:
        ln = parse_line(self.pattern, repeat=False)
        if ln.bars != 1:
            raise ValueError(f'{self.id}: pattern has {ln.bars} bars, expected 1')
        return ln


def print_table(sheets: list[Sheet]) -> None:
    """Prüft alle Blätter und druckt eine Übersicht (Skript-Aufruf der Datenmodule)."""
    for s in sheets:
        lines = s.parsed()
        s.pattern_line()
        bars = sum(ln.bars for ln in lines)
        notes = sum(len(ln.notes) for ln in lines)
        print(f'{s.id:24s} {len(lines)} Zeilen  {bars:2d} Takte  {notes:3d} Noten')
    print(len(sheets), 'Blätter ok')
