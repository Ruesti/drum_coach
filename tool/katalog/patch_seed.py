#!/usr/bin/env python3
"""Stellt rudiments_seed.dart auf die generierten Blätter um (Katalog 3a).

Für jedes Blatt aus rudimente.py: vorhandener Eintrag → `sticking: xPattern`,
`technique: xLesson`, `lines: xSheet`; fehlender Eintrag → neu angehängt.
Idempotent. Aufruf: patch_seed.py <lib/features/lessons/data/rudiments_seed.dart>
"""
from __future__ import annotations

import pathlib
import re
import sys

sys.path.insert(0, str(pathlib.Path(__file__).parent))
from gen_dart import camel, dart_str  # noqa: E402
from rudimente import SHEETS  # noqa: E402

GRID = {
    'five_stroke_roll': 'NoteGrid.sixteenth',
    'seven_stroke_roll': 'NoteGrid.sixteenthTriplet',
    'swiss_army_triplet': 'NoteGrid.triplet',
}


def _block(src: str, start: int, key: str) -> tuple[int, int] | None:
    """Span eines `    key: [ ... ],`-Blocks ab start (vor dem nächsten Eintragsende)."""
    end_entry = src.index('\n  ),\n', start)
    m = re.compile(rf'\n    {key}: \[').search(src, start, end_entry)
    if not m:
        return None
    i = m.start() + 1
    close = src.index('\n    ],', i) + len('\n    ],')
    return i, close


def _scalar(src: str, start: int, key: str) -> tuple[int, int] | None:
    end_entry = src.index('\n  ),\n', start)
    m = re.compile(rf'\n    {key}: [^\n]*,').search(src, start, end_entry)
    return (m.start() + 1, m.end()) if m else None


def patch(path: pathlib.Path) -> None:
    src = path.read_text()
    imports = ''.join(f"import 'sheets/{s.id}_sheet.dart';\n" for s in SHEETS)
    src = re.sub(r"(import 'sheets/[a-z_]+_sheet\.dart';\n)+", '', src)
    src = src.replace("import '../models/rudiment.dart';\n", "import '../models/rudiment.dart';\n" + imports, 1)

    new_entries = []
    for s in SHEETS:
        c = camel(s.id)
        key = f"    id: '{s.id}',"
        at = src.find(key)
        if at < 0:
            skills = ', '.join(f'Skill.{k}' for k in s.skills)
            genres = ', '.join(f'Genre.{g}' for g in s.genres)
            new_entries.append(
                f"\n  Rudiment(\n    id: '{s.id}',\n    name: {dart_str(s.name)},\n"
                f"    skills: {{{skills}}},\n"
                + (f"    genres: {{{genres}}},\n" if genres else '')
                + f"    description: {dart_str(s.description)},\n"
                f"    minBpm: {s.min_bpm},\n    targetBpm: {s.target_bpm},\n"
                f"    difficulty: Difficulty.{s.difficulty},\n"
                f"    gridUnit: {GRID[s.id]},\n"
                f"    sticking: {c}Pattern,\n    technique: {c}Lesson,\n    lines: {c}Sheet,\n  ),\n")
            continue
        # sticking
        span = _block(src, at, 'sticking') or _scalar(src, at, 'sticking')
        src = src[:span[0]] + f'    sticking: {c}Pattern,' + src[span[1]:]
        # technique
        span = _block(src, at, 'technique') or _scalar(src, at, 'technique')
        if span:
            src = src[:span[0]] + f'    technique: {c}Lesson,' + src[span[1]:]
        else:
            end = src.index('\n  ),\n', at)
            src = src[:end] + f'\n    technique: {c}Lesson,' + src[end:]
        # lines
        if not _scalar(src, at, 'lines'):
            end = src.index('\n  ),\n', at)
            src = src[:end] + f'\n    lines: {c}Sheet,' + src[end:]
    if new_entries:
        tail = src.rindex('\n];')
        src = src[:tail] + '\n  // ─── KATALOG 3a: new base rudiments ─────────────────────────────────────\n' + ''.join(new_entries).rstrip('\n') + src[tail:]
    path.write_text(src)
    print('seed patched:', len(SHEETS) - len(new_entries), 'updated,', len(new_entries), 'added')


if __name__ == '__main__':
    patch(pathlib.Path(sys.argv[1]))
