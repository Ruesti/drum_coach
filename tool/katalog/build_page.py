#!/usr/bin/env python3
"""Baut die Kurations-Seite eines Katalog-Satzes (abcjs) aus den Daten in katalog.py.

Aufruf: build_page.py <ausgabe.html> [satz]   (satz: rudimente | fills | grooves | set_fills; ohne = alle Sätze)
"""
from __future__ import annotations

import html
import json
import pathlib
import sys
from dataclasses import replace

sys.path.insert(0, str(pathlib.Path(__file__).parent))
from katalog import select  # noqa: E402
from sheetlang import (KIT_ABC_HEADER, TPQ, KitLine, counts_words, kit_line_to_abc, line_to_abc,  # noqa: E402
                       sticking_words)

HDR = ('X:1\\nT:\\nM:4/4\\nL:1/8\\nK:perc\\n%%stretchlast 1\\n%%staffsep 92\\n'
       'V:1 clef=perc stafflines=1\\n')


def _rows(ln, bars_per_row: int = 2, fill_every: int = 0):
    """Teilt eine lange Zeile in Reihen zu je [bars_per_row] Takten (wie die App).

    `fill_every` = 4: jeder vierte Takt ist ein Fill-Takt und bekommt „Fill" darüber.
    """
    from sheetlang import TPQ, Line
    bar_ticks = 4 * TPQ
    rows, cur, tick = [], [], 0
    for n in ln.notes:
        cur.append(n)
        tick += n.ticks()
        if tick % (bar_ticks * bars_per_row) == 0:
            rows.append(cur)
            cur = []
    if cur:
        rows.append(cur)
    out = []
    for i, notes in enumerate(rows):
        sub = Line(notes, repeat=False, counts=ln.counts)
        marks = {}
        if fill_every:
            for k in range(bars_per_row):
                if (i * bars_per_row + k + 1) % fill_every == 0:
                    marks[k] = 'Fill'
        abc = line_to_abc(sub, marks=marks or None)  # endet mit ' |'
        if i == 0 and ln.repeat:
            abc = '|: ' + abc
        if i == len(rows) - 1:
            abc = abc[:-2] + (' :|' if ln.repeat else ' |]')
        out.append((abc, sub))
    return out


def abc_for_sheet(sheet) -> str:
    parts = []
    fill_every = 4 if sheet.line_bars == 4 and sheet.fill_bar else 0
    for i, ln in enumerate(sheet.parsed()):
        label = f'{i + 1} {ln.title}' if ln.title else str(i + 1)
        parts.append(f'P:{label}\\n')
        for abc, sub in _rows(ln, fill_every=fill_every):
            parts.append(f'{abc}\\nw: {sticking_words(sub)}\\n')
            if ln.counts:
                parts.append(f'w: {counts_words(sub)}\\n')
    return HDR + ''.join(parts)


def abc_for_pattern(sheet) -> str:
    ln = sheet.pattern_line()
    return HDR + f'{line_to_abc(ln)}\\nw: {sticking_words(ln)}\\n'


def _kit_rows(kl, bars_per_row: int = 4, fill_every: int = 0) -> str:
    """Kit-Zeile als ABC, Zeilen über [bars_per_row] Takte in Reihen geteilt.

    abcjs bricht nicht selbst um: eine zu lange Reihe macht das SVG breiter, und `responsive`
    verkleinert dann das ganze Blatt. `fill_every` = 4: „Fill" über jedem vierten Takt."""
    def marks_for(first_bar: int, bars: int):
        return {k: 'Fill' for k in range(bars) if fill_every and (first_bar + k + 1) % fill_every == 0} or None

    if kl.bars <= bars_per_row:
        return kit_line_to_abc(kl, marks=marks_for(0, kl.bars))
    row_ticks = bars_per_row * 4 * TPQ
    per_track = []  # je Spur: Liste der Reihen (Noten)
    for t in kl.tracks:
        rows, cur, tick = [], [], 0
        for n in t.notes:
            cur.append(n)
            tick += n.ticks()
            if tick % row_ticks == 0:
                rows.append(cur)
                cur = []
        if cur:
            rows.append(cur)
        per_track.append(rows)
    n_rows = len(per_track[0])
    if any(len(r) != n_rows for r in per_track):
        raise ValueError(f'kit line {kl.title!r}: notes cross a row boundary')
    out = []
    for r in range(n_rows):
        bars = min(bars_per_row, kl.bars - r * bars_per_row)
        tracks = [replace(t, notes=rows[r], bars=bars) for t, rows in zip(kl.tracks, per_track)]
        sub = KitLine(tracks, repeat=False, counts=kl.counts, bars=bars)
        for v in kit_line_to_abc(sub, marks=marks_for(r * bars_per_row, bars)).splitlines():
            head, body = v.split(' ', 1)  # '[V:H]', '… |'
            if r == 0 and kl.repeat:
                body = '|: ' + body
            if r == n_rows - 1 and kl.repeat:
                body = body[:-2] + ' :|'
            out.append(f'{head} {body}\n')
    return ''.join(out)


def abc_for_kit_sheet(sheet) -> str:
    """Kit-Blatt: zwei Stimmen auf einem System (Hände oben, Füße unten), echte Zeilenumbrüche."""
    parts = []
    fill_every = 4 if sheet.line_bars == 4 and sheet.fill_bar else 0
    for i, ln in enumerate(sheet.parsed()):
        label = f'{i + 1} {ln.title}' if ln.title else str(i + 1)
        parts.append(f'P:{label}\n' + _kit_rows(ln, fill_every=fill_every))
    return KIT_ABC_HEADER + ''.join(parts)


def abc_for_kit_pattern(sheet) -> str:
    return KIT_ABC_HEADER + kit_line_to_abc(sheet.pattern_line())


# Schrift + Grundstil der Kurations-Seiten (auch build_gefuehrt_page.py).
STYLE = '''<link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Space+Grotesk:wght@400;500;700&family=Space+Mono:wght@400;700&display=swap">
<style>
  :root { --bg:#FAF8F3; --fg:#17181A; --fg2:#6A6760; --line:#E3DFD5; --accent:#E8531E; --paper:#FFFFFF; }
  @media (prefers-color-scheme: dark) { :root:not([data-theme="light"]) { --bg:#151617; --fg:#F1EEE6; --fg2:#A5A29A; --line:#2E2F31; --accent:#FF6A33; color-scheme:dark; } }
  :root[data-theme="dark"] { --bg:#151617; --fg:#F1EEE6; --fg2:#A5A29A; --line:#2E2F31; --accent:#FF6A33; color-scheme:dark; }
  body { margin:0; background:var(--bg); color:var(--fg); font-family:"Space Grotesk","Helvetica Neue",Arial,sans-serif; padding-block:32px 48px; padding-inline:16px; }
  main { max-width:920px; margin:0 auto; }
  .eyebrow { font-family:"Space Mono",ui-monospace,monospace; font-size:12px; letter-spacing:.08em; text-transform:uppercase; color:var(--accent); margin:0 0 6px; }
  h1 { font-size:28px; margin:0 0 8px; text-wrap:balance; }
  .lead { color:var(--fg2); margin:0 0 12px; line-height:1.5; max-width:72ch; }
  .toc { font-size:13px; color:var(--fg2); line-height:1.8; margin:0 0 24px; }
  .toc a { color:var(--fg); text-decoration:none; border-bottom:1px solid var(--line); }
  .sheet { background:var(--paper); color:#111; border-radius:14px; padding:24px 22px 18px; margin:0 0 24px; border:1px solid var(--line); }
  .sheet .eyebrow { color:#777; }
  .sheet h2 { font-size:24px; margin:0 0 2px; }
  .sheet .sub { color:#555; margin:0 0 10px; font-size:15px; }
  .box { background:#EFECE4; border-radius:8px; padding:6px 10px 0; margin:0 0 6px; }
  .abc svg { max-width:100%; height:auto; }
  details.lesson { margin:8px 0 0; font-size:14px; color:#333; }
  details.lesson summary { cursor:pointer; color:#555; font-size:13px; }
  details.lesson h4 { margin:10px 0 2px; font-size:13px; text-transform:uppercase; letter-spacing:.04em; color:#2F3F5C; }
  details.lesson p { margin:0; line-height:1.5; }
</style>'''

KIT_LEGEND = ('Hände Hals oben, Füße Hals unten · x = Becken/Hi-Hat · Raute = Glocke · '
              'Crash/China/Splash auf der Hilfslinie · Kick erster Zwischenraum · Pedal unter der ersten Linie'
              ' · Fußseiten R/L nur in der App')


def main(out: pathlib.Path, set_key: str | None) -> None:
    sets = select(set_key)
    SHEETS = [sh for st in sets for sh in st.sheets]
    sections = []
    data = {}
    for s in SHEETS:
        lines = s.parsed()
        bars = sum(ln.bars for ln in lines)
        data[s.id] = abc_for_kit_sheet(s) if s.kit else abc_for_sheet(s)
        data[s.id + '_pattern'] = abc_for_kit_pattern(s) if s.kit else abc_for_pattern(s)
        lesson = ''.join(
            f'<h4>{html.escape(k)}</h4><p>{html.escape(v)}</p>' for k, v in s.lesson.items())
        sections.append(f'''
  <section class="sheet" id="{s.id}">
    <p class="eyebrow">{len(lines)} Zeilen · {bars} Takte · {s.difficulty} · ♩ = {s.min_bpm}–{s.target_bpm}{' · Band ' + s.backing if s.backing else ''}{' · NEU im Katalog' if s.new_seed else ''}</p>
    <h2>{html.escape(s.name)}</h2>
    <p class="sub">{html.escape(s.description)}</p>
    <div class="box"><div class="abc" id="abc_{s.id}_pattern"></div></div>
    <div class="abc" id="abc_{s.id}"></div>
    <details class="lesson"><summary>Lektion (nur auf Abruf in der App)</summary>{lesson}</details>
  </section>''')
    toc = ' · '.join(f'<a href="#{s.id}">{html.escape(s.name)}</a>' for s in SHEETS)
    step = ' + '.join(st.step for st in sets)
    title = ' und '.join(st.title for st in sets)
    lead = ' '.join(st.lead for st in sets)
    legend = (f'\n  <p class="legend" style="font-size:13px; color:var(--fg2); margin:0 0 12px; padding:8px 12px; '
              f'border:1px solid var(--line); border-radius:8px; max-width:72ch">{html.escape(KIT_LEGEND)}</p>'
              if any(sh.kit for sh in SHEETS) else '')
    page = f'''<title>{html.escape(title)} Kuration</title>
{STYLE}
<main>
  <p class="eyebrow">drum_coach · Katalog Schritt {step} · Kuration</p>
  <h1>{html.escape(title)}</h1>
  <p class="lead">{html.escape(lead)}</p>{legend}
  <p class="toc">{toc}</p>
  {''.join(sections)}
</main>
<script src="https://cdnjs.cloudflare.com/ajax/libs/abcjs/6.4.4/abcjs-basic-min.js"></script>
<script>
const DATA = {json.dumps(data)};
const opts = {{ responsive: 'resize', staffwidth: 800, paddingtop: 0, paddingbottom: 0, add_classes: true,
  format: {{ partsfont: 'Space Grotesk 13 bold', vocalfont: 'Space Mono 12', partsbox: true }} }};
for (const [id, abc] of Object.entries(DATA)) {{ ABCJS.renderAbc('abc_' + id, abc.replace(/\\\\n/g, '\\n'), opts); }}
</script>
'''
    out.write_text(page)
    print('Seite', len(page) // 1024, 'KB,', len(SHEETS), 'Blätter')


if __name__ == '__main__':
    main(pathlib.Path(sys.argv[1]), sys.argv[2] if len(sys.argv) > 2 else None)
