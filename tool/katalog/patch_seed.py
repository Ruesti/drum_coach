#!/usr/bin/env python3
"""Stellt rudiments_seed.dart auf die generierten Blätter um (Katalog 3a/3b).

Für jedes Blatt aller Sätze (katalog.py): vorhandener Eintrag → `sticking: xPattern`,
`technique: xLesson`, `lines: xSheet`; fehlender Eintrag → neu angehängt.
Idempotent. Aufruf: patch_seed.py <lib/features/lessons/data/rudiments_seed.dart>  (alle Sätze)
"""
from __future__ import annotations

import pathlib
import re
import sys

sys.path.insert(0, str(pathlib.Path(__file__).parent))
from gen_dart import camel, dart_str  # noqa: E402
from katalog import SETS, all_sheets  # noqa: E402


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


def _entry(s) -> str:
    c = camel(s.id)
    skills = ', '.join(f'Skill.{k}' for k in s.skills)
    genres = ', '.join(f'Genre.{g}' for g in s.genres)
    return (
        f"\n  Rudiment(\n    id: '{s.id}',\n    name: {dart_str(s.name)},\n"
        f"    skills: {{{skills}}},\n"
        + (f"    genres: {{{genres}}},\n" if genres else '')
        + f"    description: {dart_str(s.description)},\n"
        f"    minBpm: {s.min_bpm},\n    targetBpm: {s.target_bpm},\n"
        f"    difficulty: Difficulty.{s.difficulty},\n"
        f"    gridUnit: NoteGrid.{s.grid},\n"
        + (f"    backing: '{s.backing}',\n" if s.backing else '')
        + f"    sticking: {c}Pattern,\n    technique: {c}Lesson,\n    lines: {c}Sheet,\n  ),\n")


def _update(src: str, at: int, c: str) -> str:
    """Vorhandener Eintrag: sticking/technique/lines auf die generierten Namen."""
    span = _block(src, at, 'sticking') or _scalar(src, at, 'sticking')
    src = src[:span[0]] + f'    sticking: {c}Pattern,' + src[span[1]:]
    span = _block(src, at, 'technique') or _scalar(src, at, 'technique')
    if span:
        src = src[:span[0]] + f'    technique: {c}Lesson,' + src[span[1]:]
    else:
        end = src.index('\n  ),\n', at)
        src = src[:end] + f'\n    technique: {c}Lesson,' + src[end:]
    if not _scalar(src, at, 'lines'):
        end = src.index('\n  ),\n', at)
        src = src[:end] + f'\n    lines: {c}Sheet,' + src[end:]
    return src


def patch(path: pathlib.Path) -> None:
    src = path.read_text()
    imports = ''.join(f"import 'sheets/{s.id}_sheet.dart';\n" for s in all_sheets())
    src = re.sub(r"(import 'sheets/[a-z_]+_sheet\.dart';\n)+", '', src)
    src = src.replace("import '../models/rudiment.dart';\n", "import '../models/rudiment.dart';\n" + imports, 1)

    updated = added = 0
    for st in SETS:
        new_entries = []
        for s in st.sheets:
            at = src.find(f"    id: '{s.id}',")
            if at < 0:
                new_entries.append(_entry(s))
            else:
                src = _update(src, at, camel(s.id))
                updated += 1
        if new_entries:
            marker = f'\n  // ─── {st.seed_marker} ' + '─' * max(0, 70 - len(st.seed_marker)) + '\n'
            tail = src.rindex('\n];')
            src = src[:tail] + marker + ''.join(new_entries).rstrip('\n') + src[tail:]
            added += len(new_entries)
    path.write_text(src)
    print('seed patched:', updated, 'updated,', added, 'added')


if __name__ == '__main__':
    patch(pathlib.Path(sys.argv[1]))
