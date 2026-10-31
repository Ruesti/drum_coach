#!/usr/bin/env python3
"""Contact sheet of the practice photos in the stage's 4:3 window.

Reads the focus values from `backdropFocus` in lib/features/practice/backdrop.dart
(missing entries use -0.2, like the app) and draws, per photo, the full width
and the 4:3 band the stage shows (Alignment y: -1 top .. 1 bottom).

    python3 tool/backdrop_focus_sheet.py out.png [--full]

--full also shows the whole photo (dimmed, band outlined) to judge the choice.
"""
import re
import sys
from pathlib import Path

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parent.parent
DART = ROOT / "lib/features/practice/backdrop.dart"
PHOTOS = ROOT / "assets/illustrations/practice"
DEFAULT = -0.2


def focus_table():
    src = DART.read_text()
    block = re.search(r"backdropFocus = \{(.*?)\};", src, re.S).group(1)
    return {
        Path(k).name: float(v)
        for k, v in re.findall(r"'([^']+)':\s*(-?[\d.]+)", block)
    }


def band(im, y):
    w, h = im.size
    bh = round(w * 3 / 4)
    top = round((h - bh) * (y + 1) / 2)
    return top, bh


def main():
    out = sys.argv[1]
    full = "--full" in sys.argv
    table = focus_table()
    files = sorted(PHOTOS.glob("p*_s*.jpg"))
    cols, cw = 6, 320
    ch = round(cw * 1890 / 1080) if full else round(cw * 3 / 4)
    pad = 22
    rows = -(-len(files) // cols)
    sheet = Image.new("RGB", (cols * (cw + 6), rows * (ch + pad + 6)), (24, 24, 24))
    d = ImageDraw.Draw(sheet)
    for i, f in enumerate(files):
        im = Image.open(f).convert("RGB")
        y = table.get(f.name, DEFAULT)
        top, bh = band(im, y)
        x0 = (i % cols) * (cw + 6)
        y0 = (i // cols) * (ch + pad + 6)
        if full:
            t = im.resize((cw, round(cw * im.height / im.width)))
            dim = Image.blend(t, Image.new("RGB", t.size, (0, 0, 0)), 0.65)
            s = t.width / im.width
            dim.paste(t.crop((0, round(top * s), t.width, round((top + bh) * s))),
                      (0, round(top * s)))
            sheet.paste(dim, (x0, y0 + pad))
        else:
            sheet.paste(im.crop((0, top, im.width, top + bh)).resize((cw, ch)),
                        (x0, y0 + pad))
        d.text((x0 + 2, y0 + 4), f"{f.stem[:24]} {y:+.2f}", fill=(255, 255, 255))
    sheet.save(out)


if __name__ == "__main__":
    main()
