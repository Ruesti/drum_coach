#!/usr/bin/env python3
"""Erzeugt die K2-Entwurfs-Artboards (Design-Components-HTML) für DrumCoach.
Richtung A (dunkel) und Richtung B (hell) aus derselben Vorlage, Farben als Literale."""
import json, pathlib

OUT = pathlib.Path(__file__).parent

DARK = dict(
    bg="#101010", sheet="#161616", scrim="#070707",
    fg="#FFFFFF", fg2="rgba(255,255,255,.72)", fg3="rgba(255,255,255,.56)", hair="rgba(255,255,255,.10)", line="rgba(255,255,255,.22)",
    accent="#FF6A2B", accentFg="#FFFFFF", accentText="#FF8A5C", accentSoft="rgba(255,106,43,.14)", accentLine="rgba(255,106,43,.45)",
    good="#57C97A", goodSoft="rgba(87,201,122,.14)", goodLine="rgba(87,201,122,.40)",
    paper="#FAF8F3", ink="#17181A", inkSoft="rgba(23,24,26,.55)", staff="rgba(23,24,26,.32)", paperAccent="#C0451A", cursor="rgba(184,119,0,.20)", cursorLine="#B87700",
    illo="rgba(255,255,255,.04)", illoLine="rgba(255,255,255,.18)",
    btn2="rgba(255,255,255,.06)",
)
LIGHT = dict(
    bg="#FAF8F3", sheet="#FFFFFF", scrim="#DAD6CE",
    fg="#17181A", fg2="rgba(23,24,26,.74)", fg3="rgba(23,24,26,.62)", hair="rgba(23,24,26,.10)", line="rgba(23,24,26,.22)",
    accent="#FF6A2B", accentFg="#FFFFFF", accentText="#C0451A", accentSoft="rgba(255,106,43,.12)", accentLine="rgba(255,106,43,.50)",
    good="#2E9E55", goodSoft="rgba(46,158,85,.12)", goodLine="rgba(46,158,85,.40)",
    paper="#FFFFFF", ink="#17181A", inkSoft="rgba(23,24,26,.55)", staff="rgba(23,24,26,.30)", paperAccent="#C0451A", cursor="rgba(184,119,0,.18)", cursorLine="#B87700",
    illo="rgba(23,24,26,.035)", illoLine="rgba(23,24,26,.16)",
    btn2="rgba(23,24,26,.05)",
)

SG = "'Space Grotesk', 'Helvetica Neue', Arial, sans-serif"
MONO = "'IBM Plex Mono', 'Courier New', monospace"

HEAD = """<!doctype html>
<html>
<head>
  <meta charset="utf-8">
  <script src="./support.js"></script>
</head>
<body>
<x-dc>
<helmet>
  <link rel="preconnect" href="https://fonts.googleapis.com">
  <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
  <link href="https://fonts.googleapis.com/css2?family=Space+Grotesk:wght@400;500;700&family=IBM+Plex+Mono:wght@400;500;600&display=swap" rel="stylesheet">
  <style>
    body { margin: 0; }
    a { color: __ACCENTTEXT__; text-decoration: none; }
    a:hover { color: __ACCENT__; }
  </style>
</helmet>
"""
FOOT = """</x-dc>
</body>
</html>
"""

def icon(name, size=24, stroke=1.8):
    d = {
        "today": '<rect x="3.5" y="5" width="17" height="15" rx="2.5"></rect><path d="M3.5 9.5h17M8 3v4M16 3v4"></path><circle cx="12" cy="14.5" r="1.6" fill="currentColor" stroke="none"></circle>',
        "library": '<rect x="3.5" y="3.5" width="7" height="7" rx="1.6"></rect><rect x="13.5" y="3.5" width="7" height="7" rx="1.6"></rect><rect x="3.5" y="13.5" width="7" height="7" rx="1.6"></rect><rect x="13.5" y="13.5" width="7" height="7" rx="1.6"></rect>',
        "progress": '<path d="M4 20V11M10 20V5M16 20v-7M22 20H2"></path>',
        "back": '<path d="M15 5l-7 7 7 7"></path>',
        "mic": '<rect x="9" y="3" width="6" height="11" rx="3"></rect><path d="M5.5 11.5a6.5 6.5 0 0 0 13 0M12 18v3M9 21h6"></path>',
        "arrow": '<path d="M5 12h14M13 6l6 6-6 6"></path>',
        "chev": '<path d="M9 6l6 6-6 6"></path>',
        "check": '<path d="M5 12.5l4.5 4.5L19 7.5"></path>',
        "stop": '<rect x="6" y="6" width="12" height="12" rx="2" fill="currentColor" stroke="none"></rect>',
        "more": '<circle cx="6" cy="12" r="1.6" fill="currentColor" stroke="none"></circle><circle cx="12" cy="12" r="1.6" fill="currentColor" stroke="none"></circle><circle cx="18" cy="12" r="1.6" fill="currentColor" stroke="none"></circle>',
        "minus": '<path d="M6 12h12"></path>',
        "plus": '<path d="M12 6v12M6 12h12"></path>',
        "info": '<circle cx="12" cy="12" r="8.5"></circle><path d="M12 11v5M12 8v.5"></path>',
    }[name]
    return (f'<svg width="{size}" height="{size}" viewBox="0 0 24 24" fill="none" stroke="currentColor" '
            f'stroke-width="{stroke}" stroke-linecap="round" stroke-linejoin="round" style="display:block">{d}</svg>')

def eyebrow(p, text, color=None):
    color = color or p["fg3"]
    return (f'<div style="font-family:{MONO};font-size:12px;font-weight:600;letter-spacing:0.08em;'
            f'text-transform:uppercase;color:{color}">{text}</div>')

def nav(p, active):
    items = [("today", "Today"), ("library", "Library"), ("progress", "Progress")]
    cells = []
    for key, label in items:
        col = p["fg"] if key == active else p["fg3"]
        w = "600" if key == active else "500"
        cells.append(
            f'<div style="display:flex;flex-direction:column;align-items:center;gap:4px;flex-grow:1;'
            f'min-height:56px;justify-content:center;color:{col}">{icon(key, 24)}'
            f'<div style="font-family:{SG};font-size:12px;font-weight:{w}">{label}</div></div>')
    return (f'<div style="display:flex;flex-direction:row;align-items:stretch;border-top:1px solid {p["hair"]};'
            f'padding:6px 16px 18px 16px;background:{p["bg"]}">' + "".join(cells) + '</div>')

def phone(p, inner, bg=None, extra=""):
    bg = bg or p["bg"]
    return (f'<div style="width:390px;height:844px;background:{bg};color:{p["fg"]};font-family:{SG};'
            f'display:flex;flex-direction:column;overflow:hidden;box-sizing:border-box;{extra}">{inner}</div>')

def btn_primary(p, label, extra="", height=56):
    return (f'<div style="display:flex;flex-direction:row;align-items:center;justify-content:center;gap:10px;'
            f'height:{height}px;border-radius:14px;background:{p["accent"]};color:{p["accentFg"]};'
            f'font-family:{SG};font-size:17px;font-weight:600">{extra}{label}</div>')

def btn_ghost(p, label, height=48):
    return (f'<div style="display:flex;flex-direction:row;align-items:center;justify-content:center;gap:8px;'
            f'height:{height}px;border-radius:14px;border:1px solid {p["line"]};color:{p["fg"]};'
            f'font-family:{SG};font-size:15px;font-weight:600">{label}{icon("arrow", 18)}</div>')

def illo(p, label, height=150):
    return (f'<div style="display:flex;align-items:center;justify-content:center;height:{height}px;'
            f'border-radius:14px;border:1px dashed {p["illoLine"]};background:{p["illo"]};'
            f'font-family:{MONO};font-size:11px;letter-spacing:0.06em;text-transform:uppercase;color:{p["fg3"]}">{label}</div>')

# ---------- Heute ----------
def today(p):
    stat = lambda num, lab: (
        f'<div style="display:flex;flex-direction:column;gap:2px;flex-grow:1">'
        f'<div style="font-family:{MONO};font-size:30px;font-weight:600;line-height:1.05;color:{p["fg"]}">{num}</div>'
        f'<div style="font-family:{SG};font-size:13px;color:{p["fg3"]}">{lab}</div></div>')
    body = (
        f'<div style="display:flex;flex-direction:column;flex-grow:1;padding:60px 20px 0 20px;gap:28px;overflow:hidden">'
        # Kopf
        f'<div style="display:flex;flex-direction:column;gap:6px">'
        f'{eyebrow(p, "Today")}'
        f'<div style="font-family:{SG};font-size:32px;font-weight:700;line-height:1.1;letter-spacing:-0.01em">Good morning.</div>'
        f'</div>'
        # Tür 1: Pfad
        f'<div style="display:flex;flex-direction:column;gap:14px">'
        f'{illo(p, "Illustration · Stage 2 (ComfyUI)", 150)}'
        f'<div style="display:flex;flex-direction:column;gap:4px">'
        f'{eyebrow(p, "Continue the path", p["accentText"])}'
        f'<div style="font-family:{SG};font-size:22px;font-weight:700;line-height:1.2">Single Paradiddle</div>'
        f'<div style="font-family:{SG};font-size:15px;color:{p["fg2"]}">Stage 2 · Step 3 of 5 · 84 BPM</div>'
        f'</div>'
        f'{btn_primary(p, "Start · 8 min")}'
        f'</div>'
        # Tür 2: frei
        f'<div style="display:flex;flex-direction:column;gap:10px;padding-top:4px;border-top:1px solid {p["hair"]}">'
        f'<div style="display:flex;flex-direction:column;gap:4px;padding-top:14px">'
        f'{eyebrow(p, "Practice freely")}'
        f'<div style="font-family:{SG};font-size:15px;color:{p["fg2"]};line-height:1.45;text-wrap:pretty">Essential rudiments, grooves on the pad, technique studies.</div>'
        f'</div>'
        f'{btn_ghost(p, "Open library")}'
        f'</div>'
        # Kompakt: Streak / Minuten
        f'<div style="display:flex;flex-direction:row;gap:20px;padding-top:18px;border-top:1px solid {p["hair"]}">'
        f'{stat("6", "day streak")}{stat("12<span style=\'color:" + p["fg3"] + "\'>/20</span>", "min today")}'
        f'</div>'
        f'</div>'
    )
    return phone(p, body + nav(p, "today"))

# ---------- Notation ----------
def n(v):
    return ("%.2f" % v).rstrip("0").rstrip(".")

def staff_svg(p, active=21, width=326):
    stick = ["R","L","R","R","L","R","L","L"] * 4     # 2 Takte Single Paradiddle in 16teln
    H = 262
    out = [f'<svg width="{width}" height="{H}" viewBox="0 0 {width} {H}" style="display:block;width:100%;height:auto">']
    s = 17.0; x0 = 50; LS = 10
    for line in range(2):
        base = 44 + line * 128
        ymid = base + 2 * LS
        for i in range(5):
            out.append(f'<line x1="0" y1="{base+i*LS}" x2="{width}" y2="{base+i*LS}" stroke="{p["staff"]}" stroke-width="1"></line>')
        out.append(f'<rect x="8" y="{ymid-10}" width="3.5" height="20" fill="{p["ink"]}"></rect><rect x="15" y="{ymid-10}" width="3.5" height="20" fill="{p["ink"]}"></rect>')
        if line == 0:
            out.append(f'<text x="28" y="{base+18}" font-family="{MONO}" font-size="19" font-weight="600" fill="{p["ink"]}">4</text>'
                       f'<text x="28" y="{base+39}" font-family="{MONO}" font-size="19" font-weight="600" fill="{p["ink"]}">4</text>')
        for k in range(16):
            idx = line * 16 + k
            x = x0 + k * s
            act = (idx == active)
            col = p["paperAccent"] if act else p["ink"]
            if act:
                out.append(f'<rect x="{n(x-8.5)}" y="{base-22}" width="17" height="92" rx="3" fill="{p["cursor"]}"></rect>'
                           f'<line x1="{n(x)}" y1="{base-22}" x2="{n(x)}" y2="{base+70}" stroke="{p["cursorLine"]}" stroke-width="1.3" opacity=".7"></line>')
            out.append(f'<ellipse cx="{n(x)}" cy="{ymid}" rx="5.4" ry="3.8" transform="rotate(-20 {n(x)} {ymid})" fill="{col}"></ellipse>')
            out.append(f'<line x1="{n(x+4.8)}" y1="{ymid-1.5}" x2="{n(x+4.8)}" y2="{ymid-35}" stroke="{col}" stroke-width="1.5"></line>')
            if k % 4 == 0:  # Akzent auf jedem Paradiddle-Anfang
                out.append(f'<path d="M{n(x-5)} {ymid-47} l10 4 l-10 4" fill="none" stroke="{col}" stroke-width="1.7" stroke-linejoin="round"></path>')
            out.append(f'<text x="{n(x)}" y="{base+64}" text-anchor="middle" font-family="{MONO}" font-size="12.5" font-weight="500" fill="{p["paperAccent"] if act else p["inkSoft"]}">{stick[idx]}</text>')
        for g in range(4):  # Balken, Gruppen zu 4
            xa = x0 + g*4*s + 4.8; xb = x0 + (g*4+3)*s + 4.8
            for yb in (ymid-36, ymid-30):
                out.append(f'<rect x="{n(xa-0.75)}" y="{yb}" width="{n(xb-xa+1.5)}" height="3.5" fill="{p["ink"]}"></rect>')
        xe = x0 + 16*s - 3
        if line == 0:
            out.append(f'<line x1="{n(xe)}" y1="{base}" x2="{n(xe)}" y2="{base+4*LS}" stroke="{p["ink"]}" stroke-width="1.3"></line>')
        else:
            out.append(f'<line x1="{n(xe-5)}" y1="{base}" x2="{n(xe-5)}" y2="{base+4*LS}" stroke="{p["ink"]}" stroke-width="1.3"></line>'
                       f'<rect x="{n(xe-1.5)}" y="{base}" width="3.5" height="{4*LS}" fill="{p["ink"]}"></rect>')
    out.append('</svg>')
    return "".join(out)

# ---------- Üben ----------
def practice(p):
    def stepbtn(name):
        return (f'<div style="display:flex;align-items:center;justify-content:center;width:44px;height:44px;'
                f'border-radius:999px;border:1px solid {p["line"]};background:{p["btn2"]};color:{p["fg"]}">{icon(name, 20)}</div>')
    def ladder(v, on):
        st = (f'background:{p["accentSoft"]};border:1px solid {p["accentLine"]};color:{p["accentText"]}' if on
              else f'border:1px solid {p["line"]};color:{p["fg3"]}')
        return (f'<div style="display:flex;align-items:center;justify-content:center;height:40px;padding:0 14px;'
                f'border-radius:999px;font-family:{MONO};font-size:12px;font-weight:600;{st}">{v}</div>')
    counter = "".join(
        f'<div style="display:flex;flex-direction:column;align-items:center;gap:6px;flex-grow:1">'
        f'<div style="font-family:{MONO};font-size:56px;font-weight:600;line-height:1;'
        f'color:{p["accent"] if n == 2 else p["fg3"]}">{n}</div>'
        f'<div style="width:22px;height:4px;border-radius:2px;background:{p["accent"] if n == 2 else "transparent"}"></div>'
        f'</div>' for n in (1, 2, 3, 4))
    body = (
        # Kopfzeile
        f'<div style="display:flex;flex-direction:row;align-items:center;gap:10px;padding:52px 16px 0 12px">'
        f'<div style="display:flex;align-items:center;justify-content:center;width:44px;height:44px;color:{p["fg"]}">{icon("back", 24)}</div>'
        f'<div style="display:flex;flex-direction:column;gap:2px;flex-grow:1;min-width:0">'
        f'<div style="font-family:{SG};font-size:17px;font-weight:600;white-space:nowrap;overflow:hidden;text-overflow:ellipsis">Single Paradiddle</div>'
        f'<div style="font-family:{SG};font-size:13px;color:{p["fg3"]}">Stage 2 · Step 3 of 5</div>'
        f'</div>'
        f'<div style="display:flex;align-items:center;gap:6px;height:44px;padding:0 12px 0 10px;border-radius:999px;'
        f'border:1px solid {p["line"]};color:{p["fg2"]};font-family:{MONO};font-size:11px;font-weight:600;letter-spacing:0.06em">'
        f'{icon("mic", 16)}ANALYSIS</div>'
        f'</div>'
        # Notenblatt
        f'<div style="display:flex;flex-direction:column;flex-grow:1;margin:14px 16px 0 16px;min-height:0;justify-content:center;'
        f'padding:16px 16px 6px 16px;border-radius:14px;background:{p["paper"]};box-sizing:border-box">'
        f'{staff_svg(p)}'
        f'</div>'
        # Zählwerk
        f'<div style="display:flex;flex-direction:row;align-items:flex-end;padding:22px 40px 0 40px;gap:8px">{counter}</div>'
        # Steuerung
        f'<div style="display:flex;flex-direction:column;gap:14px;padding:22px 16px 20px 16px">'
        f'<div style="display:flex;flex-direction:row;align-items:center;gap:8px">'
        f'<div style="font-family:{MONO};font-size:11px;letter-spacing:0.08em;text-transform:uppercase;color:{p["fg3"]};padding-right:4px">Ladder</div>'
        f'{ladder("76", False)}{ladder("80", False)}{ladder("84", True)}{ladder("88", False)}'
        f'</div>'
        f'<div style="display:flex;flex-direction:row;align-items:center;justify-content:space-between;gap:8px">'
        f'{stepbtn("minus")}'
        f'<div style="display:flex;flex-direction:row;align-items:baseline;gap:8px">'
        f'<div style="font-family:{MONO};font-size:48px;font-weight:600;line-height:1">84</div>'
        f'<div style="font-family:{MONO};font-size:12px;font-weight:600;letter-spacing:0.08em;color:{p["fg3"]}">BPM</div>'
        f'</div>'
        f'{stepbtn("plus")}'
        f'</div>'
        f'<div style="display:flex;flex-direction:row;align-items:center;gap:10px">'
        f'<div style="display:flex;flex-direction:row;align-items:center;justify-content:center;gap:10px;flex-grow:1;height:56px;'
        f'border-radius:14px;background:{p["accent"]};color:{p["accentFg"]};font-family:{SG};font-size:17px;font-weight:600">'
        f'{icon("stop", 22)}Stop<span style="font-family:{MONO};font-weight:500;opacity:.85">7:32</span></div>'
        f'<div style="display:flex;align-items:center;justify-content:center;width:56px;height:56px;border-radius:14px;'
        f'border:1px solid {p["line"]};color:{p["fg2"]}">{icon("more", 22)}</div>'
        f'</div>'
        f'</div>'
    )
    return phone(p, body)

# ---------- Ergebnis ----------
def result(p):
    def row(head, sub):
        return (f'<div style="display:flex;flex-direction:column;gap:3px">'
                f'<div style="font-family:{SG};font-size:17px;font-weight:600;line-height:1.3">{head}</div>'
                f'<div style="font-family:{MONO};font-size:12px;color:{p["fg3"]}">{sub}</div></div>')
    def kv(num, lab, sub):
        return (f'<div style="display:flex;flex-direction:column;gap:4px;flex-grow:1;flex-basis:0">'
                f'<div style="font-family:{MONO};font-size:30px;font-weight:600;line-height:1.05;letter-spacing:-0.01em">{num}</div>'
                f'<div style="font-family:{SG};font-size:14px;font-weight:600">{lab}</div>'
                f'<div style="font-family:{SG};font-size:12px;color:{p["fg3"]}">{sub}</div></div>')
    def chip(lab, sub, on):
        st = (f'background:{p["accentSoft"]};border:1px solid {p["accentLine"]};color:{p["fg"]}' if on
              else f'border:1px solid {p["line"]};color:{p["fg2"]}')
        return (f'<div style="display:flex;flex-direction:column;align-items:center;justify-content:center;gap:2px;'
                f'flex-grow:1;flex-basis:0;height:56px;border-radius:14px;{st}">'
                f'<div style="font-family:{SG};font-size:15px;font-weight:600">{lab}</div>'
                f'<div style="font-family:{MONO};font-size:12px;color:{p["fg3"]}">{sub}</div></div>')
    sheet = (
        f'<div style="display:flex;flex-direction:column;background:{p["sheet"]};border-radius:20px 20px 0 0;'
        f'padding:10px 20px 24px 20px;gap:20px;box-sizing:border-box">'
        f'<div style="width:36px;height:4px;border-radius:2px;background:{p["fg3"]};align-self:center"></div>'
        f'<div style="display:flex;flex-direction:column;gap:6px">'
        f'{eyebrow(p, "Session complete")}'
        f'<div style="font-family:{SG};font-size:22px;font-weight:700;line-height:1.2">Single Paradiddle</div>'
        f'<div style="font-family:{MONO};font-size:13px;color:{p["fg3"]}">84 BPM · 8:00 · analysis</div>'
        f'</div>'
        # Urteil
        f'<div style="display:flex;flex-direction:row;align-items:center;gap:12px;padding:14px 16px;border-radius:14px;'
        f'background:{p["goodSoft"]};border:1px solid {p["goodLine"]};color:{p["good"]}">'
        f'{icon("check", 24, 2.2)}'
        f'<div style="font-family:{SG};font-size:17px;font-weight:600;line-height:1.3;color:{p["fg"]}">Clean run — hand analysis below.</div>'
        f'</div>'
        # Selbst-Rating
        f'<div style="display:flex;flex-direction:column;gap:10px">'
        f'{eyebrow(p, "How did it feel?")}'
        f'<div style="display:flex;flex-direction:row;gap:8px">'
        f'{chip("Struggled", "same BPM", False)}{chip("OK", "+2 BPM", False)}{chip("Solid", "+5 BPM", True)}'
        f'</div>'
        f'</div>'
        # Drei Kernwerte in Klartext (Entscheidung 15.09.), Messzahl klein darunter
        f'<div style="display:flex;flex-direction:column;gap:14px;padding:18px 0 18px 0;border-top:1px solid {p["hair"]}">'
        f'{row("You miss 2 notes", "30 of 32 hit · 94 %")}'
        f'{row("You rush a little", "3 ms ahead of the click · ±11 ms spread")}'
        f'{row("Your hands are even", "±9 ms · right +2 ms · left +5 ms")}'
        f'</div>'
        # Messdetails
        f'<div style="display:flex;flex-direction:row;align-items:center;justify-content:space-between;min-height:48px;'
        f'border-top:1px solid {p["hair"]};border-bottom:1px solid {p["hair"]};color:{p["fg2"]}">'
        f'<div style="font-family:{SG};font-size:15px;font-weight:600">Measurement details</div>{icon("chev", 20)}</div>'
        f'{btn_primary(p, "Done")}'
        f'<div style="display:flex;align-items:center;justify-content:center;min-height:44px;font-family:{SG};font-size:14px;font-weight:600;color:{p["fg3"]}">Export session (JSONL)</div>'
        f'</div>'
    )
    return phone(p, sheet, bg=p["scrim"], extra="justify-content:flex-end")

def write(name, p, html):
    head = HEAD.replace("__ACCENTTEXT__", p["accentText"]).replace("__ACCENT__", p["accent"])
    (OUT / f"{name}.dc.html").write_text(head + html + "\n" + FOOT, encoding="utf-8")

write("Main", LIGHT, today(LIGHT))          # gewählt: Today hell
write("Practice", DARK, practice(DARK))     # gewählt: Üben dunkel
write("Result", LIGHT, result(LIGHT))       # gewählt: Ergebnis hell, Rating oben
write("TodayDark", DARK, today(DARK))       # Alternative
write("PracticeLight", LIGHT, practice(LIGHT))
write("ResultDark", DARK, result(DARK))

W, H = 390, 844
canvas = {
    "pages": [{"id": "page-1", "name": "Entwurf (gewählt 15.09.)"}, {"id": "page-2", "name": "Alternativen"}],
    "artboards": [
        {"file": "Main.dc.html",          "x": 0,   "y": 0, "w": W, "h": H, "title": "Today · hell", "page": "page-1"},
        {"file": "Practice.dc.html",      "x": 480, "y": 0, "w": W, "h": H, "title": "Practice · dunkel", "page": "page-1"},
        {"file": "Result.dc.html",        "x": 960, "y": 0, "w": W, "h": H, "title": "Result · hell, Rating oben", "page": "page-1"},
        {"file": "TodayDark.dc.html",     "x": 0,   "y": 0, "w": W, "h": H, "title": "Today · dunkel (nicht gewählt)", "page": "page-2"},
        {"file": "PracticeLight.dc.html", "x": 480, "y": 0, "w": W, "h": H, "title": "Practice · hell (nicht gewählt)", "page": "page-2"},
        {"file": "ResultDark.dc.html",    "x": 960, "y": 0, "w": W, "h": H, "title": "Result · dunkel (nicht gewählt)", "page": "page-2"},
    ],
    "annotations": [
        {"id": "k2-brief", "x": 1460, "y": 0, "w": 360, "page": "page-1", "text":
         "K2 · Design-Pass „leicht, luftig, modern, klar“ (Brief §3)\n\n"
         "Entscheidungen 15.09.: Mischung – Today, Library und Result hell (Papier-Ton #FAF8F3), nur der Übungs-Screen dunkel. "
         "Rating oben im Ergebnis-Blatt. Drei Tabs Today · Library · Progress. Zählwerk als Zahlen 1 2 3 4.\n\n"
         "Hausfarben und Schriften bleiben (Orange #FF6A2B, Space Grotesk + IBM Plex Mono). UI-Sprache Englisch (K1). Zahlen sind Beispielwerte."},
        {"id": "k2-heute", "x": 1460, "y": 300, "w": 360, "page": "page-1", "text":
         "Today (statt Dashboard)\n\n"
         "Zwei Türen zuerst: „Continue the path“ = nächster Schritt mit EINEM Knopf; „Practice freely“ = Bibliothek. "
         "Darunter kompakt Streak und Tagesminuten. Der alte Kartenstapel entfällt."},
        {"id": "k2-ueben", "x": 1460, "y": 560, "w": 360, "page": "page-1", "text":
         "Practice (bleibt dunkel)\n\n"
         "Notenblatt und Zählwerk (1 2 3 4, aktiver Schlag orange) sind das großflächige Herz. Kopfzeile: Name, Stufe, ein Modus-Chip mit Mikro. "
         "Unten kompakt: Leiter, BPM mit ±, ein Stop-Knopf mit Restzeit; Sound, Dauer, Feinschritte hinter „⋯“."},
        {"id": "k2-ergebnis", "x": 1460, "y": 860, "w": 360, "page": "page-1", "text":
         "Result\n\nUrteils-Banner oben, direkt darunter das Selbst-Rating (Entscheidung: Rating oben), dann drei Kernwerte in Klartext (Entscheidung 15.09.): „You miss 2 notes“, „You rush a little“, „Your hands are even“ – die Messzahl klein darunter. Alles Weitere hinter „Measurement details“."},
        {"id": "k2-illus", "x": 1460, "y": 1120, "w": 360, "page": "page-1", "text":
         "Illustrationen\n\n"
         "Gestrichelte Flächen = Platzhalter für Bilder aus der ComfyUI-Pipeline (Hausstil): Pfad-Stufen, Rubrik-Titelbilder, leere Zustände. Stil noch offen."},
        {"id": "k2-fragen", "x": 1460, "y": 1340, "w": 360, "page": "page-1", "text":
         "Noch offen\n\nIllustrationsstil (ComfyUI) – kommt mit K3/K4.\nWortlaut der Klartext-Urteile (rush / drag / miss / even) wird beim Bauen festgelegt."},
        {"id": "k2-alt", "x": 1460, "y": 0, "w": 360, "page": "page-2", "text":
         "Nicht gewählte Varianten vom 15.09.: Today dunkel, Practice hell, Result dunkel. Zum Vergleich aufbewahrt."},
    ],
    "launch": {"view": "canvas", "page": "page-1"},
}
(OUT / "canvas.json").write_text(json.dumps(canvas, ensure_ascii=False, indent=2), encoding="utf-8")
print("ok:", sorted(f.name for f in OUT.glob("*.dc.html")), "+ canvas.json")
