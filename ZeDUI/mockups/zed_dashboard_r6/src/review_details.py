"""round 6 review sheet: the key, the ash trays, the taxi, the van's sticker (zoomed x3)"""
import os, json
from PIL import Image, ImageDraw, ImageFont
import build
F = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf", 18)
F2 = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf", 14)
FP = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf", 13)
K = 3
def load(did):
    d = os.path.join("out", did)
    base = Image.open(os.path.join(d, f"dash_{did}.png")).convert("RGBA")
    doc = json.load(open(os.path.join(d, f"dash_{did}.json")))
    spr = {k: Image.open(os.path.join(d, f"{k}.png")).convert("RGBA") for k in doc["sprites"] if os.path.exists(os.path.join(d, f"{k}.png"))}
    return base, doc, spr
TOP = 14     # room over the plate for a sprite that rises above it (the hula girl)


def comp(base, doc, spr, st, box):
    im = Image.new("RGBA", (base.width, base.height + TOP), (0, 0, 0, 0))
    im.alpha_composite(base, (0, TOP))
    for p in doc["parts"]:
        if p["t"] != "sprite": continue
        v = st.get(p["src"]); w = p.get("when", True)
        ok = (v == w) if isinstance(w, (str, int)) and not isinstance(w, bool) else (bool(v) == bool(w))
        if ok and p["sprite"] in spr: im.alpha_composite(spr[p["sprite"]], (p["x"], p["y"] + TOP))
    bg = Image.new("RGBA", im.size, (52, 60, 40, 255)); bg.alpha_composite(im)
    x0, y0, x1, y1 = box
    c = bg.crop((x0, y0 + TOP - (TOP if y0 <= 0 else 0), x1, y1 + TOP)); return c.resize((c.width * K, c.height * K), Image.NEAREST)
def hula_tile():
    import v6
    fr = v6.hula_frames(); w, h = fr[0].size; z = 6
    t = Image.new("RGBA", (3 * w * z + 2 * 10 + 20, h * z + 20), (52, 60, 40, 255))
    for i, f in enumerate(fr): t.alpha_composite(f.resize((w * z, h * z), Image.NEAREST), (10 + i * (w * z + 10), 10))
    return t


def key_box(doc):
    h_ = [h for h in doc["hits"] if h["id"] == "ignition"][0]
    cx, cy = h_["x"] + h_["w"] // 2, h_["y"] + h_["h"] // 2
    return (cx - 26, cy - 24, cx + 42, cy + 26)


def px_text(img, t, x, y, color, k):
    """the 3 x 5 face, drawn at k onto a tile (for live text the review's composite does not draw)"""
    from engine import FONTS
    f = FONTS["35"]; d_ = ImageDraw.Draw(img); cx = x
    for ch in t:
        g = f.get(ch, f[" "])
        for ry, row in enumerate(g):
            for rx, bt in enumerate(row):
                if bt == "1": d_.rectangle([cx + rx * k, y + ry * k, cx + (rx + 1) * k - 1, y + (ry + 1) * k - 1], fill=color)
        cx += (len(g[0]) + 1) * k


sections = []
base, doc, spr = load("nyala")
sections.append(("1  The key, right-most on the lower row, turns: OFF, ON, START (the game shows START while it cranks, then ON)",
                 [(t.upper(), comp(base, doc, spr, {"keyPos": t}, key_box(doc))) for t in ("off", "on", "start")]))
b1, d1, s1 = load("nyala"); b2, d2, s2 = load("d6"); b3, d3, s3 = load("taxi"); b4, d4, s4 = load("ambulance")
def abox(a): return (a[0] - 6, a[1] - 6, a[0] + 84, a[1] + 54)
sections.append(("2  Right of the radio: the ash tray and lighter, open on used cars; NO SMOKING on the emergency vehicles", [
    ("closed (Nyala)", comp(b1, d1, s1, {}, abox(d1["meta"]["ash"]))), ("open, 2 butts", comp(b2, d2, s2, {"ashOpen": 1}, abox(d2["meta"]["ash"]))),
    ("open, 4 butts", comp(b2, d2, s2, {"ashOpen": 2}, abox(d2["meta"]["ash"]))),
    ("open, 6 butts (the taxi's)", comp(b3, d3, s3, {"ashOpen": 3}, abox(d3["meta"]["ash"]))), ("ambulance, police, fire, ranger", comp(b4, d4, s4, {}, (700, 58, 790, 118)))]))
def taxi_tile(st):
    t = comp(b3, d3, s3, st, (506, 0, 800, 70))
    lx, ly, lw, lh = d3["meta"]["license"]
    px_text(t, "TAXI - CAB 26", (lx + 24 - 506) * K, (ly + 13 + TOP) * K, (26, 26, 26), K)
    return t


sections.append(("3  Taxi: the fare meter runs while the flag is down (fare and extras), a hula girl on the dash top", [
    ("flag up: FOR HIRE; the cab's licence under her", taxi_tile({"meterOn": False, "hula": 0})),
    ("flag down: meter running, the hula girl swaying", taxi_tile({"meterOn": True, "hula": 1})),
    ("her three frames: still, swung left, swung right", hula_tile())]))
def deco(name):
    """a game decal on its die-cut vinyl: the art's outline grown 2 px in white, a dark cut line round that"""
    from PIL import ImageFilter
    im = Image.open(os.path.join(build.DECALS, name)).convert("RGBA")
    a = im.getchannel("A").point(lambda v: 255 if v > 40 else 0)
    cut = a.filter(ImageFilter.MaxFilter(5)); line = cut.filter(ImageFilter.MaxFilter(3))
    out = Image.new("RGBA", im.size, (0, 0, 0, 0))
    out.paste((40, 36, 30, 255), (0, 0), line); out.paste((244, 242, 234, 255), (0, 0), cut)
    out.alpha_composite(im); return out


bv, dv, sv = load("van")
sx, sy, sw, sh_ = dv["meta"]["sticker"]
ax_, ay_, aw_, ah_ = dv["meta"]["ash"]
vbox = (min(sx, ax_) - 6, sy - 4, max(sx + sw, ax_ + 74) + 6, sy + sh_ + 4)
def van_tile(st, decal=None):
    t = comp(bv, dv, sv, st, (0, 1, 800, 172)).resize((800, 171), Image.NEAREST)
    t = t.crop((0, 0, 800, 171)); t2 = Image.new("RGBA", (800, 172)); t2.paste(t, (0, 1)); t = t2
    if decal:
        im = deco(decal); t.alpha_composite(im, (sx + (sw - im.width) // 2, sy + (sh_ - im.height) // 2))
    c = t.crop(vbox); return c.resize((c.width * K, c.height * K), Image.NEAREST)
tiles = [("Spiffo's van: the game's logo", van_tile({}, "Buisness_SpiffosDECAL.png")),
         ("Fossoil van", van_tile({}, "Buisness_FossoilDECAL.png")),
         ("McCoy Logging van", van_tile({}, "Buisness_McCoysDECAL.png")),
         ("any other company's van", van_tile({"vanRight": "nosmoke"})),
         ("a private van: the ash tray", van_tile({"vanRight": "ash"})),
         ("a private van, open", van_tile({"vanRight": "ash", "ashOpen": 2}))]
sections.append(("4  The van, right of the radio: a business with a logo in the game wears it; any other company van says NO SMOKING; a private van has its ash tray", tiles))
pad = 20
W_ = max(sum(t.width for _, t in tl) + pad * (len(tl) + 1) for _, tl in sections)
H_ = sum(max(t.height for _, t in tl) + 74 for _, tl in sections) + pad
out = Image.new("RGB", (W_, H_), (24, 24, 26)); dr = ImageDraw.Draw(out)
y = pad
for title, tl in sections:
    dr.text((pad, y), title, fill=(236, 232, 222), font=F); y += 30
    x = pad
    for lab, t in tl:
        out.paste(t.convert("RGB"), (x, y)); dr.text((x, y + t.height + 4), lab, fill=(160, 156, 146), font=F2); x += t.width + pad
    y += max(t.height for _, t in tl) + 44
out.save("../review/dash_r6_details.png"); print(out.size)
