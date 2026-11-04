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
    # curtains: velvet folds (a light ridge, a mid, a dark trough), gathered to a gold tie-back
    ramp = [(70, 6, 14), (96, 10, 20), (124, 16, 26), (150, 26, 32), (176, 40, 44), (150, 26, 32), (124, 16, 26), (96, 10, 20)]
    tie = 0.62
    top_w, tie_w, foot_w = sx + 14, sx + 3, sx + 12
    for side in (0, 1):
        for y in range(0, h):
            t = y / h
            if t < tie:
                edge = top_w + (tie_w - top_w) * (t / tie) ** 0.7
            else:
                edge = tie_w + (foot_w - tie_w) * ((t - tie) / (1 - tie)) ** 1.4
            edge = int(edge)
            for x in range(edge + 1):
                # folds squeeze toward the tie-back
                squeeze = 1.0 - 0.45 * max(0.0, 1 - abs(t - tie) / 0.35)
                k = int((x * squeeze) / 1.6) % len(ramp)
                c = ramp[k]
                if x >= edge - 1:
                    c = tuple(min(255, v + 30) for v in c)        # the lit inner edge
                px = x if side == 0 else w - 1 - x
                a.putpixel((px, y), c + (255,))
        ty = int(h * tie)
        for x in range(0, tie_w + 3):
            px = x if side == 0 else w - 1 - x
            for y in range(ty - 1, ty + 2):
                a.putpixel((px, y), (222, 178, 70, 255) if y == ty - 1 else (176, 132, 44, 255))
    # valance: swags across the top, above the screen
    for x in range(w):
        k = x % 24
        sag = int(5 + 3 * (1 - ((k - 12) / 12) ** 2))
        for y in range(sag + 1):
            c = ramp[(y + 2) % len(ramp)] if y < sag else (222, 178, 70)
            a.putpixel((x, y), c + (255,))
    # the audience: seat backs and heads in dark navy, just over the screen's foot (the game's belt stays clear)
    rnd = random.Random(11)
    navy = [(12, 18, 44), (14, 22, 52), (10, 15, 36)]
    base = h
    d.rectangle([0, base - 5, w, h], fill=(7, 10, 26, 255))
    x = -4
    while x < w:
        seat_w = rnd.randint(16, 20)
        d.rounded_rectangle([x + 1, base - 9, x + seat_w - 2, base], radius=2, fill=(9, 13, 32, 255))
        if rnd.random() < 0.85:
            c = rnd.choice(navy) + (255,)
            hx = x + seat_w // 2 + rnd.randint(-2, 2)
            rx, ry = rnd.randint(4, 5), rnd.randint(5, 6)
            hy = base - 12 - rnd.randint(0, 3)
            # neck and rounded shoulders
            d.rectangle([hx - 1, hy + ry - 1, hx + 1, hy + ry + 2], fill=c)
            d.ellipse([hx - rx - 4, hy + ry, hx + rx + 4, hy + ry + 10], fill=c)
            d.ellipse([hx - rx, hy - ry, hx + rx, hy + ry], fill=c)
            style = rnd.random()
            if style < 0.2:      # a cap brim
                d.rectangle([hx - rx, hy - ry + 1, hx + rx + 2, hy - ry + 2], fill=c)
            elif style < 0.4:    # long hair
                d.ellipse([hx - rx - 1, hy - 1, hx + rx + 1, hy + ry + 4], fill=c)
            for dx in range(-rx + 2, rx - 1):
                if 0 <= hx + dx < w: a.putpixel((hx + dx, hy - ry), (44, 58, 100, 255))
        x += seat_w
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
