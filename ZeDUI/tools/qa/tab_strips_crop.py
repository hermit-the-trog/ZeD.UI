"""ZeDUI/tools/qa/tab_strips_crop.py  (Oct 30 2026)
Punch list 21's clean capture: crops each strip_* screenshot to its drawer card (the card's top
strip down to the window's bottom edge, so the footer band is in it), from the "ZEDQA g3z rect"
lines in console.txt; writes a contact sheet per window and measurements.md: the logged tab
header and footer heights, and per card the first full-width line below its top edge (where the
header strip ends) and the last one above the footer.
Run with the ComfyUI venv's Python (numpy, Pillow):  python tab_strips_crop.py [out_dir]
"""
import os, re, sys
import numpy as np
from PIL import Image, ImageDraw, ImageFont

ZOMBOID = r"C:\Users\danie\Zomboid"
SHOTS = os.path.join(ZOMBOID, "Screenshots")
OUT = sys.argv[1] if len(sys.argv) > 1 else os.path.join(ZOMBOID, r"mods\ZeD-UI\ZeDUI\qa\Oct30_tab_strips_clean")
RX = re.compile(r"ZEDQA g3z rect (\S+) drawer (\d+) (\d+) (\d+) (\d+) window (\d+) (\d+) (\d+) (\d+) header (\d+) footer (\d+) tab (\S+)")


def rects():
    """From console.txt and the runner's reports (console.txt starts over at each launch, so a retake's
    run would lose the first run's lines); the latest line per shot wins."""
    import glob
    out = {}
    reports = sorted(glob.glob(os.path.join(ZOMBOID, r"mods\ZeD-UI\ZeDUI\qa\regression\*_fullscreen4k.md")),
                     key=os.path.getmtime)[-4:]
    for path in reports + [os.path.join(ZOMBOID, "console.txt")]:
        with open(path, encoding="utf-8", errors="replace") as f:
            for line in f:
                m = RX.search(line)
                if m:
                    g = m.groups()
                    out[g[0]] = dict(dx=int(g[1]), dy=int(g[2]), dw=int(g[3]), dh=int(g[4]),
                                     wx=int(g[5]), wy=int(g[6]), ww=int(g[7]), wh=int(g[8]),
                                     header=int(g[9]), footer=int(g[10]), tab=g[11])
    return out


def shot(name):
    for p in (os.path.join(SHOTS, name), os.path.join(SHOTS, name + ".png")):
        if os.path.exists(p):
            return Image.open(p).convert("RGB")
    return None


def edges(card):
    """Rows where 85% of the card's width changes from the row above: full-width lines (the cards are
    see-through, so a line is found by its edges, not its colour)."""
    a = np.asarray(card.convert("L")).astype(np.int32)[:, 4:-4]
    frac = (np.abs(a[1:] - a[:-1]) > 5).mean(axis=1)
    return [y + 1 for y in range(len(frac)) if frac[y] > 0.85]


def main():
    os.makedirs(OUT, exist_ok=True)
    R = rects()
    crops = {"c": [], "w": []}
    rows = []
    for name in sorted(R):
        r = R[name]
        img = shot("strip_c_window" if name == "strip_w_window" else name)   # one shot holds both windows
        if img is None:
            rows.append(f"| {name} | no screenshot | | | |")
            continue
        if name.endswith("_window") or r["dw"] == 0:   # the Loot tabs have no drawer card: the window
            img.crop((r["wx"], r["wy"], r["wx"] + r["ww"], r["wy"] + r["wh"])).save(os.path.join(OUT, name + ".png"))
            continue
        box = (r["dx"], r["dy"], r["dx"] + r["dw"], r["wy"] + r["wh"])
        card = img.crop(box)
        card.save(os.path.join(OUT, name + ".png"))
        e = edges(card)
        H = card.height
        top = [y for y in e if 4 < y < 200]
        head = next((y for y in top if y in (63, 64, 65)), None)
        wfoot = r["footer"]
        band = [H - y for y in e if H - wfoot - 80 < y < H - wfoot - 4]   # a band just above the window footer
        rows.append(f"| {name.replace('strip_', '')} | {head if head else 'none'} | {top[0] if top else '-'} | "
                    f"{(max(band) - wfoot) if band else 'none'} | {wfoot} |")
        crops[name.split("_")[1]].append((name, card))
    font = None
    try:
        font = ImageFont.truetype("arial.ttf", 28)
    except OSError:
        font = ImageFont.load_default()
    for k, items in crops.items():
        if not items:
            continue
        scale = 0.5
        cells = [(n, c.resize((int(c.width * scale), int(c.height * scale)), Image.LANCZOS)) for n, c in items]
        cols = min(6, len(cells))
        cw = max(c.width for _, c in cells) + 20
        ch = max(c.height for _, c in cells) + 50
        nrows = (len(cells) + cols - 1) // cols
        sheet = Image.new("RGB", (cols * cw, nrows * ch), (24, 24, 28))
        d = ImageDraw.Draw(sheet)
        for i, (n, c) in enumerate(cells):
            x, y = (i % cols) * cw + 10, (i // cols) * ch + 40
            sheet.paste(c, (x, y))
            d.text((x, y - 34), n.replace("strip_", ""), fill=(230, 230, 230), font=font)
        sheet.save(os.path.join(OUT, f"sheet_{'character' if k == 'c' else 'world'}.png"))
    with open(os.path.join(OUT, "measurements.md"), "w", encoding="utf-8") as f:
        f.write("# Tab cards, Oct 30 2026 (4K, scale 1.75)\n\n")
        f.write("Screen px, measured on the crops (each card 840 px wide, 2072 tall from its top edge to the "
                "window's bottom edge). Header strip: the standard tab header (65 px, its 2 px groove at 63-65) "
                "where the card has one. First line: the first full-width line below the card's top edge, "
                "whatever draws it. Card footer band: a band of the card's own above the window footer. "
                "Window footer: the window's own footer band (the same on every tab).\n\n")
        f.write("| Card | Header strip | First line | Card footer band | Window footer |\n|---|---|---|---|---|\n")
        f.write("\n".join(rows) + "\n")
    print("\n".join(rows))


if __name__ == "__main__":
    main()
