#!/usr/bin/env python3
"""Baut die Kurations-Seite der geführten Übungen (gefuehrt.py): je Übung Kopf, Ablauf,
Noten von Groove und Variationen (abcjs) und die gesprochene Erklärung als eingebetteter Clip.

Aufruf: python3 tool/katalog/build_gefuehrt_page.py <ausgabe.html>
"""
from __future__ import annotations

import base64
import html
import json
import pathlib
import sys

sys.path.insert(0, str(pathlib.Path(__file__).parent))
from build_page import HDR, KIT_LEGEND, STYLE, _kit_rows, _rows  # noqa: E402
from gefuehrt import SHEETS, bars  # noqa: E402
from gefuehrt_blatt import GuidedSheet  # noqa: E402
from sheetlang import KIT_ABC_HEADER, sticking_words  # noqa: E402

VOICE = pathlib.Path(__file__).resolve().parents[2] / 'assets' / 'voice'
PACKAGE = {'kit': 'Set', 'pad': 'Pad'}


def duration_label(s: GuidedSheet) -> str:
    """Geplante Dauer bei Standardtempo wie in der App (ohne automatische Verlängerung)."""
    sec = int(bars(s) * 240 / s.default_bpm + 0.5)  # like Dart .round()
    return f'~{sec // 60}:{sec % 60:02d}'


def flow(s: GuidedSheet) -> str:
    parts = ['Einzählen 1']
    for i in range(1, len(s.variations) + 1):
        parts += [f'Groove {s.groove_bars}', f'V{i} {s.variation_bars}']
    return ' · '.join(parts + [f'Groove {s.groove_bars}', 'Schluss 1'])


def line_abc(s: GuidedSheet, ln) -> str:
    if s.package == 'kit':
        return KIT_ABC_HEADER + _kit_rows(ln)
    return HDR + ''.join(f'{abc}\\nw: {sticking_words(sub)}\\n' for abc, sub in _rows(ln))


def _clip(clip_id: str, text: str, manifest: dict) -> str:
    wav = VOICE / f'{clip_id}.wav'
    entry = manifest.get(clip_id)
    if entry is None or not wav.exists():
        return f'<p class="warn">Clip {clip_id} fehlt — Stimmen-Werkzeug laufen lassen.</p>'
    warn = ('' if entry.get('text') == text else
            f'<p class="warn">Clip spricht noch: „{html.escape(entry.get("text", ""))}“</p>')
    b64 = base64.b64encode(wav.read_bytes()).decode('ascii')
    return (f'<div class="clip"><audio controls preload="none" data-clip="{clip_id}" '
            f'src="data:audio/wav;base64,{b64}"></audio>'
            f'<span class="ms">{entry["ms"] / 1000:.1f} s</span></div>{warn}')


def main(out: pathlib.Path, sheets: list[GuidedSheet] | None = None) -> None:
    sheets = SHEETS if sheets is None else sheets
    manifest = {c['id']: c for c in json.loads((VOICE / 'manifest.json').read_text())['clips']}
    data, sections = {}, []
    for s in sheets:
        groove, vs = s.parsed()
        data[f'{s.id}_g'] = line_abc(s, groove)
        blocks = [f'<h3>Groove</h3><div class="box"><div class="abc" id="abc_{s.id}_g"></div></div>']
        for i, (v, ln) in enumerate(zip(s.variations, vs), 1):
            data[f'{s.id}_v{i}'] = line_abc(s, ln)
            blocks.append(
                f'<h3>Variation {i}</h3><div class="abc" id="abc_{s.id}_v{i}"></div>'
                f'<p class="say">{html.escape(v.text)}</p>{_clip(s.clip_id(i), v.text, manifest)}')
        sections.append(f'''
  <section class="sheet" id="{s.id}">
    <p class="eyebrow">{PACKAGE[s.package]} · {s.difficulty} · ♩ = {s.min_bpm}–{s.max_bpm} (Standard {s.default_bpm}) · {duration_label(s)}</p>
    <h2>{html.escape(s.name)}</h2>
    <p class="sub">{html.escape(s.description)}</p>
    <p class="flow">{flow(s)}</p>
    {''.join(blocks)}
  </section>''')
    toc = ' · '.join(f'<a href="#{s.id}">{html.escape(s.name)}</a>' for s in sheets)
    legend = (f'\n  <p class="legend">{html.escape(KIT_LEGEND)}</p>'
              if any(s.package == 'kit' for s in sheets) else '')
    page = f'''<title>Geführte Übungen Kuration</title>
{STYLE}
<style>
  .legend {{ font-size:13px; color:var(--fg2); margin:0 0 12px; padding:8px 12px; border:1px solid var(--line); border-radius:8px; max-width:72ch; }}
  .sheet h3 {{ font-size:13px; text-transform:uppercase; letter-spacing:.06em; color:#2F3F5C; margin:18px 0 4px; }}
  .flow {{ font-family:"Space Mono",ui-monospace,monospace; font-size:12px; color:#555; margin:0 0 6px; }}
  .say {{ font-size:17px; font-weight:500; margin:4px 0 6px; }}
  .clip {{ display:flex; align-items:center; gap:10px; flex-wrap:wrap; }}
  .clip audio {{ max-width:100%; }}
  .ms {{ font-family:"Space Mono",ui-monospace,monospace; font-size:12px; color:#777; }}
  .warn {{ color:#B3261E; font-size:14px; margin:4px 0; }}
</style>
<main>
  <p class="eyebrow">drum_coach · Geführte Übungen · Kuration</p>
  <h1>Geführte Übungen</h1>
  <p class="lead">Je Übung Groove und Variationen mit der gesprochenen Erklärung. Dauer bei Standardtempo, ohne automatische Verlängerung für lange Ansagen.</p>{legend}
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
    print('Seite', len(page) // 1024, 'KB,', len(sheets), 'Übungen')


if __name__ == '__main__':
    main(pathlib.Path(sys.argv[1]))
