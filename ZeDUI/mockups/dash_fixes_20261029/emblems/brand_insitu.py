"""Proof (writes nothing in the repo): every civilian dash with its console plaques taken out and its maker's brand
lockup in their place, centred in the clear field; then the drive preview with the live parts, as the game draws it.
usage (from tools/dashpx): py -3.14 C:\\Temp\\brand_insitu.py out.png"""
import sys, os, copy, json
sys.path.insert(0, os.getcwd()); sys.path.insert(0, r"C:\Temp")
import numpy as np
from PIL import Image
import dashlib
import designs as DZ
import build as BU
import radios
import brand as BR
from brand_slots import clear_field

sys.path.insert(0, os.path.join(os.getcwd(), "..", "physpx"))
import d_heads as DH

REMOVED = {}
CURVY = {"dashelite", "primani"}
MODEL_ELSEWHERE = {"horizon", "wagon"}          # these dashes already wear the model's name on the driver's side


def patched_badge(b, x, y, w, h, style="flat", role="label", font="35", scale=1, color="#d8dade", plate=None, align="c",
                  shadow=None, check=True):
    if x >= 494 and role in ("make", "model", "full", "sub"):
        REMOVED.setdefault(b.id, []).append(dict(role=role, x=x, y=y, w=w, h=h))
        return
    return ORIG(b, x, y, w, h, style=style, role=role, font=font, scale=scale, color=color, plate=plate, align=align,
                shadow=shadow, check=check)


import brand_slots
ORIG = brand_slots.ORIG          # the real badge(): brand_slots swapped its own in on import
dashlib.badge = patched_badge; DZ.badge = patched_badge


def model_line(did):
    """(model, performance tag)"""
    if did in MODEL_ELSEWHERE: return "", ""      # the curved dashes print nothing on the rim: their model is in the mark
    n = BU.badge_names(did)
    m, s = n["badge_model"], n["badge_sub"]
    return m, (s if s and s not in m else "")


VL = DZ.vent_louvered


def narrow_vents(b, x, y, w, h, **kw):
    """the Primani's console vents at the boxy consoles' 88 px, so the brand gets an 88 px slot between them"""
    if b.id == "primani" and w == 100:
        w = 88
        if x > 600: x += 12
    return VL(b, x, y, w, h, **kw)


DZ.vent_louvered = narrow_vents


heads = {}
for k in radios.KINDS:
    img, parts, sprites_, warns = DH.build(k)
    heads[k] = (img, parts, sprites_)
blank = radios.blank()

shots, log = [], []
for did in DZ.ORDER:
    title = DZ.DESIGNS[did][0]
    maker = title.split()[0].lower()
    if maker not in BR.SPEC: continue
    _, cabin, seed, fn, *_ = DZ.DESIGNS[did]
    b = dashlib.Build(did, cabin, seed=seed, title=title); fn(b)
    BR.use(b.d)
    if did in CURVY:
        fx, fy, fw, fh = clear_field(b.d, 646, 46)
    else:
        rem = REMOVED.get(did, [])
        xs = [r["x"] for r in rem] + [r["x"] + r["w"] for r in rem]; ys = [r["y"] for r in rem] + [r["y"] + r["h"] for r in rem]
        fx, fy, fw, fh = clear_field(b.d, int((min(xs) + max(xs)) / 2), int((min(ys) + max(ys)) / 2))
    model, sub = model_line(did)
    form = "h"
    w, h = BR.size(maker, model, "h", sub)
    if w + 6 > fw or h + 4 > fh:
        ws, hs = BR.size(maker, model, "s", sub)
        if ws + 6 <= fw and hs + 4 <= fh: form, w, h = "s", ws, hs
    x0, y0 = fx + (fw - w) // 2, fy + (fh - h) // 2
    BR.draw(maker, x0, y0, model, form, sub=sub)
    fits = w + 6 <= fw and h + 4 <= fh
    log.append(f"{did:10s} {maker:9s} field {fw}x{fh} lockup {w}x{h} form {form} {'fits' if fits else 'DOES NOT FIT'}  model '{model}' tag '{sub}'")
    base = b.d.render()
    sprites = {}
    for name, src, vfn, when in b.variants:
        d2 = copy.deepcopy(b.d); vfn(d2)
        spr, at = BU.cut_variant(base, d2.render())
        if spr is None: continue
        sprites[name] = spr
        b.part("sprite", src=src, when=when, sprite=name, x=at[0], y=at[1], w=spr.width, h=spr.height)
    for name, im in getattr(b, "extra", {}).items(): sprites[name] = im
    for k in BU.TAB_SPRITES:
        if any(p.get("sprite") == k for p in b.parts): sprites[k] = BU.tab_sprite(k)
    sprites["hu_blank"] = blank
    doc = {"id": did, "title": title, "cabin": cabin, "w": dashlib.W, "h": dashlib.H,
           "meta": {kk: vv for kk, vv in b.meta.items() if kk != "face_mask"}, "parts": b.parts, "hits": b.hits,
           "sprites": {k: [im.width, im.height] for k, im in sprites.items()}}
    img = BU.preview(did, base, sprites, doc, heads=heads, state="drive", k=1)
    shots.append(img.convert("RGBA").crop((494, 0, 800, 112)))
print("\n".join(log))
w, h = shots[0].size
cols = 3; rows = (len(shots) + cols - 1) // cols
sheet = Image.new("RGBA", (cols * (w + 6), rows * (h + 6)), (0, 0, 0, 255))
for i, s in enumerate(shots): sheet.paste(s, ((i % cols) * (w + 6), (i // cols) * (h + 6)))
sheet.resize((sheet.width * 2, sheet.height * 2), Image.NEAREST).save(sys.argv[1])



