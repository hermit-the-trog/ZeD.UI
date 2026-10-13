"""
Preview and validate the baked SDF fonts.

Run from the repo root:
    py -3.14 ZeDUI/tools/fonts/preview_sdf.py            # all roles
    py -3.14 ZeDUI/tools/fonts/preview_sdf.py body       # a subset

For each role it reads 42/media/fonts/sdf/<role>.fnt + its pages (face size and spread
come from the .fnt), lays the test string out with the .fnt metrics only (xoffset /
yoffset / xadvance, no kerning, like the engine) and renders it at 1x, 2x and 4x of the
face by sampling the distance field the way the GPU does:
    nearest  >= 0.5     texel lookup, hard threshold
    bilinear >= 0.5     GL_LINEAR lookup, hard threshold
    sdf.frag (atom)     GL_LINEAR + the shader's smoothstep with the threshold the engine's
                        PZAPI text atoms pass (AtomUIText: 0.125 / screen scale, a band of
                        about +-1 screen px)
    raw alpha           GL_LINEAR, no shader: what UIElement.DrawText / drawTextZoomed
                        shows, because that path never binds sdf.frag - the field itself
                        is the alpha (edge at 0.5, ramp of +-spread texels)
    vs TTF              bilinear >= 0.5 over the TTF outline itself (FreeType at >= 512
                        px/em, area-averaged, >= 50% coverage, same pen positions):
                        black both, red SDF only, blue TTF only
then, at the role's UI size (generate_fonts.py 1x px, i.e. 1080p) and at twice that (the
4K rig's root scale), three rows: the TTF's ideal anti-aliased render, raw alpha and
sdf.frag (atom). Faint guides: blue = baseline, grey = line box (lineHeight).

Console: per-role glyph count, pages, lineHeight, base; atlas checks (boxes inside the
page, no overlaps, nothing inked on a box edge = no clipping); per face zoom the share of
pixels that differ from the TTF outline plus the "gross" ones (more than 1 px off) -
those should be 0 up to 2x; per UI size the coverage error against the ideal render
(sum |coverage - ideal| / ideal ink), the median opacity the raw-alpha path gives pixels
the glyph fully covers, and the alpha the atom threshold leaves on empty quad area (it
goes above 0 once the +-1 px band outgrows the field's +-spread texels, i.e. below
1/spread zoom).
Output: ZeDUI/tools/fonts/preview_<role>.png
"""

import math
import re
import sys
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw, ImageFont

sys.dont_write_bytecode = True      # no __pycache__ in the repo
sys.path.insert(0, str(Path(__file__).resolve().parent))
import bake_sdf  # noqa: E402  (roles, font lookup, output folder)

TEXT = "Chevalier Nyala 88.3 FM 21°C · POLICE UNIT 78 fjgq"
SCALES = [1, 2, 4]
UI_PX = {"sec": 11, "body": 13, "stat": 11, "head": 15, "title": 9}  # generate_fonts.py 1x
UI_ROOT_SCALES = [1, 2]       # 1080p, 4K rig
MARGIN = 6          # face px around the line
LABEL_W = 210       # label column, output px
OUT = Path(__file__).resolve().parent


def parse_fnt(path):
    info, common, pages, chars = {}, {}, {}, {}
    for line in path.read_text(encoding="ascii").splitlines():
        tag, _, rest = line.partition(" ")
        kv = dict(re.findall(r'(\w+)=("[^"]*"|\S+)', rest))
        if tag == "info":
            info = {"size": int(kv["size"]), "pad": int(kv["padding"].split(",")[0])}
        elif tag == "common":
            common = {k: int(v) for k, v in kv.items()}
        elif tag == "page":
            pages[int(kv["id"])] = kv["file"].strip('"')
        elif tag == "char":
            chars[int(kv["id"])] = {k: int(v) for k, v in kv.items()}
    return info, common, pages, chars


def layout(text, chars):
    pen, quads = 0, []
    for ch in text:
        c = chars.get(ord(ch))
        if c is None:
            print(f"    ! U+{ord(ch):04X} not in font")
            continue
        quads.append((pen, c))
        pen += c["xadvance"]
    return quads, pen


def sample(a, u, v, bilinear):
    """Sample page `a` (float, texel centres at i+0.5) at texel coords u (cols), v (rows)."""
    n = a.shape[0]
    if not bilinear:
        iu = np.clip(np.floor(u).astype(int), 0, n - 1)
        iv = np.clip(np.floor(v).astype(int), 0, n - 1)
        return a[np.ix_(iv, iu)]
    uu, vv = u - 0.5, v - 0.5
    i0, j0 = np.floor(uu).astype(int), np.floor(vv).astype(int)
    fx, fy = (uu - i0)[None, :], (vv - j0)[:, None]
    i0c, i1c = np.clip(i0, 0, n - 1), np.clip(i0 + 1, 0, n - 1)
    j0c, j1c = np.clip(j0, 0, n - 1), np.clip(j0 + 1, 0, n - 1)
    top = a[np.ix_(j0c, i0c)] * (1 - fx) + a[np.ix_(j0c, i1c)] * fx
    bot = a[np.ix_(j1c, i0c)] * (1 - fx) + a[np.ix_(j1c, i1c)] * fx
    return top * (1 - fy) + bot * fy


def render_field(quads, width, common, pages, z, bilinear):
    """Max-combined field of all glyph quads at zoom z (any positive float)."""
    w_px = math.ceil((width + 2 * MARGIN) * z)
    h_px = math.ceil((common["lineHeight"] + 2 * MARGIN) * z)
    out = np.zeros((h_px, w_px), np.float32)
    for pen, c in quads:
        if c["width"] == 0:
            continue
        qx0, qy0 = (MARGIN + pen + c["xoffset"]) * z, (MARGIN + c["yoffset"]) * z
        qx1, qy1 = qx0 + c["width"] * z, qy0 + c["height"] * z
        # destination pixels whose centres fall inside the quad
        px0, px1 = max(0, math.ceil(qx0 - 0.5)), min(w_px, math.ceil(qx1 - 0.5))
        py0, py1 = max(0, math.ceil(qy0 - 0.5)), min(h_px, math.ceil(qy1 - 0.5))
        if px1 <= px0 or py1 <= py0:
            continue
        u = c["x"] + (np.arange(px0, px1) + 0.5 - qx0) / z
        v = c["y"] + (np.arange(py0, py1) + 0.5 - qy0) / z
        s = sample(pages[c["page"]], u, v, bilinear)
        region = out[py0:py1, px0:px1]
        np.maximum(region, s, out=region)
    return out


def shader(field, z, spread=None):
    """sdf.frag smoothstep with the threshold PZAPI text atoms pass
    (AtomUIText.getSdfThreshold: 0.125 / screen scale, whatever the atlas spread)."""
    w = 0.125 / z
    t = np.clip((field - (0.5 - w)) / (2 * w), 0, 1)
    return t * t * (3 - 2 * t)


def ttf_coverage(role_ttf, quads, width, common, face, z):
    """The TTF's ideal area coverage at zoom z: rendered at >= 512 px/em (so FreeType
    hinting, which moves edges by up to ~1 px at 32-128 px, is negligible) and
    area-averaged down."""
    ss = max(1, math.ceil(512 / (face * z)))
    w_px = math.ceil((width + 2 * MARGIN) * z)
    h_px = math.ceil((common["lineHeight"] + 2 * MARGIN) * z)
    font = ImageFont.truetype(role_ttf, round(face * z * ss))
    img = Image.new("L", (w_px * ss, h_px * ss), 0)
    d = ImageDraw.Draw(img)
    for pen, c in quads:
        d.text((round((MARGIN + pen) * z * ss), round((MARGIN + common["base"]) * z * ss)),
               chr(c["id"]), font=font, fill=255, anchor="ls")
    cov = np.asarray(img).reshape(h_px, ss, w_px, ss).sum(axis=(1, 3), dtype=np.uint32)
    return cov.astype(np.float32) / (255.0 * ss * ss)


def dilate(m):
    p = np.pad(m, 1)
    out = np.zeros_like(m)
    for dy in range(3):
        for dx in range(3):
            out |= p[dy:dy + m.shape[0], dx:dx + m.shape[1]]
    return out


def to_rgb(cov, common, z):
    """Coverage (0..1) -> RGB row with guides."""
    h, w = cov.shape
    rgb = np.full((h, w, 3), 255.0, np.float32)
    for y, col in (((MARGIN) * z, (205, 205, 205)),
                   ((MARGIN + common["lineHeight"]) * z, (205, 205, 205)),
                   ((MARGIN + common["base"]) * z, (150, 190, 255))):
        yy = min(h - 1, int(round(y)))
        rgb[yy, :, :] = col
    rgb *= (1 - np.clip(cov, 0, 1))[..., None]
    return rgb.astype(np.uint8)


def diff_rgb(sdf, ref):
    rgb = np.full(sdf.shape + (3,), 255, np.uint8)
    rgb[sdf & ref] = (0, 0, 0)
    rgb[sdf & ~ref] = (230, 30, 30)
    rgb[~sdf & ref] = (40, 90, 255)
    return rgb


def atlas_checks(chars, pages, common):
    issues, max_edge = [], 0.0
    occ = {pid: np.zeros_like(a, dtype=bool) for pid, a in pages.items()}
    for cid, c in chars.items():
        if c["width"] == 0:
            continue
        x, y, w, h, p = c["x"], c["y"], c["width"], c["height"], c["page"]
        if x < 0 or y < 0 or x + w > common["scaleW"] or y + h > common["scaleH"]:
            issues.append(f"U+{cid:04X} box outside page")
            continue
        if occ[p][y:y + h, x:x + w].any():
            issues.append(f"U+{cid:04X} overlaps another box")
        occ[p][y:y + h, x:x + w] = True
        box = pages[p][y:y + h, x:x + w]
        edge = max(box[0].max(), box[-1].max(), box[:, 0].max(), box[:, -1].max())
        max_edge = max(max_edge, float(edge))
        if edge >= 0.5:
            issues.append(f"U+{cid:04X} inked on its box edge (clipped)")
        if box.max() < 0.5:
            issues.append(f"U+{cid:04X} has no inside pixels")
    return issues, max_edge


def label(img, text, y, font):
    ImageDraw.Draw(img).text((8, y + 2), text, fill=(90, 90, 90), font=font)


def preview_role(role, ttf_name):
    fnt = bake_sdf.OUT_DIR / f"{role}.fnt"
    info, common, page_files, chars = parse_fnt(fnt)
    face, spread = info["size"], float(info["pad"])
    pages = {pid: np.asarray(Image.open(bake_sdf.OUT_DIR / f).convert("RGBA"))[..., 3]
             .astype(np.float32) / 255.0 for pid, f in page_files.items()}
    print(f"  {role:<5} face {face}px  glyphs {len(chars)}  pages {len(pages)}  "
          f"lineHeight {common['lineHeight']}  base {common['base']}  "
          f"H xadvance {chars[ord('H')]['xadvance']}")
    issues, max_edge = atlas_checks(chars, pages, common)
    print(f"        atlas: {'OK' if not issues else '; '.join(issues[:6])}  "
          f"(max alpha on a box edge {max_edge:.3f})")

    quads, width = layout(TEXT, chars)
    ttf_path = bake_sdf._find_font(ttf_name)
    rows = []   # (label, rgb)
    for z in SCALES:
        near = render_field(quads, width, common, pages, z, bilinear=False)
        bil = render_field(quads, width, common, pages, z, bilinear=True)
        sdf = bil >= 0.5
        ref = ttf_coverage(ttf_path, quads, width, common, face, z) >= 0.5
        xor = sdf ^ ref
        gross = (sdf & ~dilate(ref)) | (ref & ~dilate(sdf))
        near_x = (near >= 0.5) ^ ref
        print(f"        {z}x: bilinear vs TTF {100.0 * xor.sum() / max(1, (sdf | ref).sum()):5.2f}% "
              f"px differ, gross {int(gross.sum())};  nearest vs TTF "
              f"{100.0 * near_x.sum() / max(1, ((near >= 0.5) | ref).sum()):5.2f}%")
        rows.append((f"{z}x nearest >= .5", to_rgb((near >= 0.5).astype(np.float32), common, z)))
        rows.append((f"{z}x bilinear >= .5", to_rgb(sdf.astype(np.float32), common, z)))
        rows.append((f"{z}x sdf.frag (atom)", to_rgb(shader(bil, z, spread), common, z)))
        rows.append((f"{z}x raw alpha (DrawText)", to_rgb(bil, common, z)))
        rows.append((f"{z}x vs TTF (diff)", diff_rgb(sdf, ref)))
    for root in UI_ROOT_SCALES:
        px = UI_PX.get(role, 13) * root
        z = px / face
        bil = render_field(quads, width, common, pages, z, bilinear=True)
        ideal = ttf_coverage(ttf_path, quads, width, common, face, z)
        raw, shd = np.clip(bil, 0, 1), shader(bil, z, spread)
        ink = max(float(ideal.sum()), 1e-6)
        solid = ideal >= 0.95
        solid_raw = f"{np.median(raw[solid]):.2f}" if solid.any() else "n/a"
        haze = float(shader(np.zeros(1, np.float32), z, spread)[0])  # field 0 = empty quad
        print(f"        {px}px ({z:.3f}x): coverage error vs ideal AA  raw "
              f"{100 * np.abs(raw - ideal).sum() / ink:4.1f}%  sdf.frag "
              f"{100 * np.abs(shd - ideal).sum() / ink:4.1f}%;  raw opacity on solid px "
              f"{solid_raw};  sdf.frag haze on empty quad area {haze:.3f}")
        rows.append((f"{px}px TTF ideal AA", to_rgb(ideal, common, z)))
        rows.append((f"{px}px raw alpha (DrawText)", to_rgb(raw, common, z)))
        rows.append((f"{px}px sdf.frag (atom)", to_rgb(shd, common, z)))

    pad = 6
    total_w = LABEL_W + max(r.shape[1] for _, r in rows) + pad
    total_h = sum(max(r.shape[0], 20) + pad for _, r in rows) + pad
    sheet = Image.new("RGB", (total_w, total_h), (244, 244, 240))
    try:
        lab_font = ImageFont.load_default(size=15)
    except TypeError:
        lab_font = ImageFont.load_default()
    y = pad
    for text, rgb in rows:
        sheet.paste(Image.fromarray(rgb, "RGB"), (LABEL_W, y))
        label(sheet, text, y, lab_font)
        y += max(rgb.shape[0], 20) + pad
    out = OUT / f"preview_{role}.png"
    sheet.save(out, optimize=True)
    print(f"        -> {out}")


def main(argv):
    wanted = set(argv) or {r[0] for r in bake_sdf.ROLES}
    print('SDF preview: "%s"' % TEXT.encode("ascii", "backslashreplace").decode())
    for role, ttf_name, _label, _slot in bake_sdf.ROLES:
        if role in wanted:
            preview_role(role, ttf_name)


if __name__ == "__main__":
    main(sys.argv[1:])
