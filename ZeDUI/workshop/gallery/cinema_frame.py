"""The gallery's full-screen breaks as a picture on a cinema screen (the director, Nov 4 2026): the screenshot fills
about 90% of the frame with a slight big-screen texture, red stage curtains at each side, and a row of dark navy heads
and seat backs along the foot. Pixel art drawn at 1/4 scale and enlarged without smoothing; no subtitles.
usage: py cinema_frame.py <in.png> <out.jpg>
"""
import sys, random
from PIL import Image, ImageDraw, ImageFilter, ImageEnhance

W, H = 1920, 1080
S = 4                                   # pixel-art scale
SW, SH = 1700, 956                      # the screen (90%)
SX, SY = (W - SW) // 2, 34


def screen(src):
    im = Image.open(src).convert("RGB").resize((SW, SH), Image.LANCZOS)
    # projector light: a touch brighter in the middle, darker at the edges; a little warm; fine grain
    im = ImageEnhance.Contrast(im).enhance(1.04)
    vign = Image.new("L", (SW, SH), 0)
    d = ImageDraw.Draw(vign)
    for i in range(60):
        a = int(255 * (i / 60) ** 1.6)
        d.rectangle([i * 6, i * 4, SW - i * 6, SH - i * 4], outline=a, width=6)
    vign = vign.filter(ImageFilter.GaussianBlur(40))
    dark = ImageEnhance.Brightness(im).enhance(0.72)
    im = Image.composite(im, dark, vign)
    warm = Image.new("RGB", (SW, SH), (255, 236, 205))
    im = Image.blend(im, warm, 0.05)
    rnd = random.Random(7)
    noise = Image.effect_noise((SW // 2, SH // 2), 18).resize((SW, SH)).convert("RGB")
    im = Image.blend(im, noise, 0.035)
    return im


def art():
    """the theatre at 1/4 scale: walls, curtains, valance, seats and heads (RGBA, transparent over the screen)"""
    w, h = W // S, H // S
    a = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    d = ImageDraw.Draw(a)
    sx, sy, sw, sh = SX // S, SY // S, SW // S, SH // S
    wall = (14, 10, 18, 255)
    d.rectangle([0, 0, w, sy - 1], fill=wall)
    d.rectangle([0, 0, sx - 1, h], fill=wall)
    d.rectangle([sx + sw, 0, w, h], fill=wall)
    d.rectangle([0, sy + sh, w, h], fill=wall)
    for i in range(3):
        c = (70 - i * 18, 56 - i * 14, 60 - i * 14, 255)
        d.rectangle([sx - 1 - i, sy - 1 - i, sx + sw + i, sy + sh + i], outline=c)
    # curtains: a very dark maroon velvet (the director, Nov 4). Real drape: a few deep folds run from the rod to the
    # floor; each fold keeps its share of the curtain's width at every height, so the folds bunch together into the
    # gold tie-back and fan out again below it. Five flat tones per fold (trough, shade, mid, light, ridge), no
    # blending, so it stays pixel art; the inner edge is one smooth curve with a single lit line.
    import math
    tones = [(18, 2, 5), (27, 3, 8), (37, 5, 11), (48, 8, 14), (60, 11, 18)]
    edge_lit = (74, 16, 23)
    ramp = tones                                 # (the valance below uses the same tones)
    folds = 4.5
    tie = 0.62
    top_w, tie_w, foot_w = sx + 16, sx - 5, sx + 10   # pulled in hard at the tie-back (an hourglass)
    def edge_at(t):
        if t < tie:
            return top_w + (tie_w - top_w) * (t / tie) ** 0.8
        return tie_w + (foot_w - tie_w) * ((t - tie) / (1 - tie)) ** 1.3
    for side in (0, 1):
        for y in range(0, h):
            t = y / h
            e = edge_at(t)
            ei = int(round(e))
            for x in range(ei + 1):
                u = (x + 0.5) / e * folds               # the fold coordinate: its share of the width
                c = 0.5 - 0.5 * math.cos(2 * math.pi * u)   # 0 in a trough, 1 on a ridge
                c *= 0.75 + 0.25 * (x / max(1.0, e))    # the wall side a little darker
                col = tones[min(4, int(c * 5))]
                if x == ei:
                    col = edge_lit                      # the lit inner edge
                px = x if side == 0 else w - 1 - x
                a.putpixel((px, y), col + (255,))
        # the gold sash round the gathered curtain, and its tassel hanging from the knot
        ty = int(h * tie)
        for x in range(0, tie_w + 2):
            px = x if side == 0 else w - 1 - x
            for y in range(ty - 1, ty + 2):
                a.putpixel((px, y), (176, 138, 56, 255) if y == ty - 1 else (130, 98, 34, 255))
        kx = tie_w + 1
        for dy in range(2, 9):
            for dx in range(-1, 2 if dy > 5 else 1):
                px = (kx + dx) if side == 0 else w - 1 - (kx + dx)
                a.putpixel((px, ty + dy), (150, 116, 44, 255) if dx < 1 else (110, 84, 30, 255))
    # valance: swags across the top, above the screen
    for x in range(w):
        k = x % 24
        sag = int(5 + 3 * (1 - ((k - 12) / 12) ** 2))
        for y in range(sag + 1):
            if y == sag:
                c = (176, 138, 56)                      # the gold fringe
            elif k in (0, 23):
                c = tones[0]                            # the fold between two swags
            else:
                c = tones[min(4, 1 + int(3 * (1 - abs(k - 12) / 12)))] if y >= sag - 2 else tones[2]
            a.putpixel((x, y), c + (255,))
    # the audience (the director, Nov 4): only the tops of heads along the foot, over low seat backs, in a very dark
    # navy; one fan gives the head beside him rabbit ears, and a couple on date night lean together (her head on his
    # shoulder). The middle stays clear so the game's hotbar and hint strip show (art x 186-294).
    import math
    rim = (34, 46, 86, 255)
    base = h
    d.rectangle([0, base - 4, w, h], fill=(6, 8, 20, 255))
    for x0 in (-20, 40, 100, 300, 360, 420):
        d.rounded_rectangle([x0 + 4, base - 10, x0 + 54, base + 4], radius=4, fill=(7, 10, 25, 255))

    def head(hx, top, rx, ry, shade, style="plain", tilt=0, seed=0):
        """a head drawn on its own layer with a hair style, tilted by `tilt` degrees, pasted with its rim light.
        styles: spiky, curly, part (a part down the middle), long (wavy strands to the shoulders)"""
        rr = random.Random(seed)
        pad = 16
        lw, lh = rx * 2 + pad * 2, ry * 2 + pad * 2
        L = Image.new("RGBA", (lw, lh), (0, 0, 0, 0))
        g = ImageDraw.Draw(L)
        c = shade + (255,)
        lite = tuple(min(255, v + 7) for v in shade) + (255,)      # a strand catching a little light
        deep = tuple(max(0, v - 4) for v in shade) + (255,)        # the shadow between strands
        cx, cy = lw // 2, lh // 2
        if style == "long":
            g.ellipse([cx - rx - 3, cy - ry - 2, cx + rx + 3, cy + ry + 14], fill=c)
        g.ellipse([cx - rx, cy - ry, cx + rx, cy + ry], fill=c)
        if style == "spiky":
            x = -rx + 2
            while x <= rx - 2:
                k = abs(x) / rx
                base_y = cy - int(ry * math.sqrt(max(0.0, 1 - k * k))) + 3
                tip = base_y - rr.randint(8, 11) + int(4 * k)
                lean = int(x * 0.35)
                g.polygon([(cx + x - 2, base_y), (cx + x + 2, base_y), (cx + x + lean, tip)], fill=c)
                x += 4
        if style == "curly":
            for i in range(26):
                ang = math.pi * (1.0 + i / 25.0)
                bx = cx + int((rx + 1) * math.cos(ang))
                by = cy + int((ry + 1) * math.sin(ang))
                r0 = rr.randint(3, 4)
                g.ellipse([bx - r0, by - r0, bx + r0, by + r0], fill=c)
            for i in range(22):                                       # the curls inside
                ang = rr.uniform(math.pi * 1.05, math.pi * 1.95)
                dist = rr.uniform(0.25, 0.85)
                bx = cx + int(rx * dist * math.cos(ang)); by = cy + int(ry * dist * math.sin(ang))
                g.arc([bx - 2, by - 2, bx + 2, by + 2], 180, 360, fill=lite)
        if style == "part":
            for i in range(-rx + 3, rx - 2, 3):                       # strands combed out from the part
                side = 1 if i > 0 else -1
                y0 = cy - int(ry * math.sqrt(max(0.0, 1 - (i / rx) ** 2))) + 2
                g.line([(cx + i, y0), (cx + i + side * 2, y0 + 6)], fill=lite)
        if style == "long":
            for i in range(-rx, rx + 1, 4):
                y0 = cy - int(ry * math.sqrt(max(0.0, 1 - (min(abs(i), rx - 1) / rx) ** 2))) + 3
                pts = [(cx + i + (1 if (j // 3) % 2 else 0), y0 + j) for j in range(0, ry * 2 + 8)]
                g.line(pts, fill=lite)
        # rim light: the top-most opaque pixel of each column
        px = L.load()
        for x in range(lw):
            for y in range(lh):
                if px[x, y][3]:
                    if abs(x - cx) < rx - 1 or style in ("spiky", "curly"):
                        px[x, y] = rim
                    break
        if style == "part":                                           # the part itself: a dark line, no rim
            for y in range(lh):
                if px[cx, y][3]:
                    for k in range(9):
                        if y + k < lh: px[cx, y + k] = deep
                    break
        if tilt:
            L = L.rotate(tilt, resample=Image.NEAREST, center=(cx, cy + ry))
        a.alpha_composite(L, (hx - cx, top + ry - cy))

    # the rabbit ears: a forearm up from below the frame, behind the first head, a fist with two fingers in a V
    hand = (8, 12, 30, 255)
    d.line([(102, h), (81, 238)], fill=hand, width=10)                     # the forearm
    d.polygon([(73, 236), (87, 236), (91, 248), (77, 250)], fill=hand)     # the wrist, joined to the fist
    d.rounded_rectangle([72, 227, 86, 241], radius=4, fill=hand)            # the fist
    d.ellipse([84, 231, 89, 238], fill=hand)                                # the folded thumb
    for (x0, y0, x1, y1) in ((76, 229, 73, 210), (82, 229, 84, 210)):       # the two fingers, close together
        d.line([(x0, y0), (x1, y1)], fill=hand, width=4)
        d.ellipse([x1 - 2, y1 - 2, x1 + 2, y1 + 2], fill=hand)              # rounded tips
        d.point([(x1 - 1, y1 - 2), (x1, y1 - 2)], fill=rim)
    head(70, 245, 14, 17, (8, 12, 30), "spiky", seed=3)
    head(148, 243, 16, 18, (10, 14, 34), "curly", seed=5)
    # date night: he sits up, she leans over onto his shoulder
    head(402, 236, 16, 18, (9, 13, 32), "part")
    head(383, 241, 14, 17, (10, 15, 36), "long", tilt=-38)
    return a.resize((W, H), Image.NEAREST)


def main(src, out):
    frame = Image.new("RGB", (W, H), (14, 10, 18))
    frame.paste(screen(src), (SX, SY))
    layer = art()
    frame.paste(layer, (0, 0), layer)
    frame.save(out, quality=92, subsampling=0)
    print("wrote", out)


if __name__ == "__main__":
    main(sys.argv[1], sys.argv[2])
