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
def comp(base, doc, spr, st, box):
    im = base.copy()
    for p in doc["parts"]:
        if p["t"] != "sprite": continue
        v = st.get(p["src"]); w = p.get("when", True)
        ok = (v == w) if isinstance(w, (str, int)) and not isinstance(w, bool) else (bool(v) == bool(w))
        if ok and p["sprite"] in spr: im.alpha_composite(spr[p["sprite"]], (p["x"], p["y"]))
    bg = Image.new("RGBA", im.size, (52, 60, 40, 255)); bg.alpha_composite(im)
    c = bg.crop(box); return c.resize((c.width * K, c.height * K), Image.NEAREST)
def hula_tile():
    import v6
    fr = v6.hula_frames(); w, h = fr[0].size; z = 6
    t = Image.new("RGBA", (3 * w * z + 2 * 10 + 20, h * z + 20), (52, 60, 40, 255))
    for i, f in enumerate(fr): t.alpha_composite(f.resize((w * z, h * z), Image.NEAREST), (10 + i * (w * z + 10), 10))
    return t


sections = []
base, doc, spr = load("nyala")
sections.append(("1  The key, right of the column, turns: OFF, ON, START (the game shows START while it cranks, then ON)",
                 [(t.upper(), comp(base, doc, spr, {"keyPos": t}, (272, 116, 340, 166))) for t in ("off", "on", "start")]))
b1, d1, s1 = load("nyala"); b2, d2, s2 = load("d6"); b3, d3, s3 = load("taxi"); b4, d4, s4 = load("ambulance")
def abox(a): return (a[0] - 6, a[1] - 6, a[0] + 84, a[1] + 54)
sections.append(("2  Right of the radio: the ash tray and lighter, open on used cars; NO SMOKING on the emergency vehicles", [
    ("closed (Nyala)", comp(b1, d1, s1, {}, abox(d1["meta"]["ash"]))), ("open, 2 butts", comp(b2, d2, s2, {"ashOpen": 1}, abox(d2["meta"]["ash"]))),
    ("open, 4 butts", comp(b2, d2, s2, {"ashOpen": 2}, abox(d2["meta"]["ash"]))),
    ("open, 6 butts (the taxi's)", comp(b3, d3, s3, {"ashOpen": 3}, abox(d3["meta"]["ash"]))), ("ambulance, police, fire, ranger", comp(b4, d4, s4, {}, (700, 58, 790, 118)))]))
sections.append(("3  Taxi: the fare meter runs while the flag is down (fare and extras), a hula girl on the dash top", [
    ("flag up: FOR HIRE", comp(b3, d3, s3, {"meterOn": False, "hula": 0}, (506, 0, 800, 70))),
    ("flag down: meter running, the hula girl swaying", comp(b3, d3, s3, {"meterOn": True, "hula": 1}, (506, 0, 800, 70))),
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
    t = comp(bv, dv, sv, st, (0, 0, 800, 172)).resize((800, 172), Image.NEAREST)
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
