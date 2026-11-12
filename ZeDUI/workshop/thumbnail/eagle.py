"""A bald eagle in flight, facing right, wing raised (the director, Nov 11 2026: it has to be dead on, easy to
recognize as a bald eagle). Built from shapes on a pixel grid, then outlined: white head and tail, hooked yellow beak,
dark brown body, a broad wing with fingered primaries, yellow feet."""
import sys
from PIL import Image, ImageDraw

W, H = 62, 38
K = (20, 13, 8)
BR, BRD, BRL = (92, 56, 28), (58, 34, 16), (124, 82, 42)
WH, WHS = (246, 244, 238), (200, 198, 192)
YE, YED = (242, 186, 34), (186, 124, 14)


def sprite():
    im = Image.new("RGBA", (W, H), (0, 0, 0, 0)); d = ImageDraw.Draw(im)
    # far wing, a darker tip showing above the near wing's leading edge
    d.polygon([(34, 19), (30, 10), (27, 4), (29, 3), (33, 8), (38, 17)], fill=BRD)
    # tail: a white fan
    d.polygon([(21, 22), (7, 19), (4, 21), (4, 25), (7, 28), (21, 27)], fill=WH)
    d.line([(7, 27), (20, 27)], fill=WHS)
    # body
    d.ellipse([17, 18, 45, 30], fill=BR)
    d.ellipse([20, 25, 42, 30], fill=BRD)
    # near wing: broad, raised up and back
    d.polygon([(38, 20), (31, 13), (24, 7), (17, 2), (12, 1), (8, 4), (6, 9), (9, 14), (14, 19), (20, 23), (30, 23)], fill=BR)
    d.polygon([(36, 20), (30, 15), (24, 10), (20, 8), (22, 13), (28, 19)], fill=BRL)       # coverts, catching light
    # primaries: five fingers at the tip, splayed
    for (x0, y0, x1, y1) in ((14, 2, 9, -3), (11, 3, 5, 0), (9, 6, 2, 4), (8, 10, 1, 9), (9, 13, 2, 14)):
        d.line([(x0, y0), (x1, y1)], fill=BRD, width=2)
    d.line([(12, 16), (20, 22)], fill=BRD)                                                     # trailing edge
    # head and neck: white
    d.ellipse([39, 12, 53, 24], fill=WH)
    d.polygon([(38, 18), (42, 15), (44, 26), (40, 27)], fill=WH)
    d.line([(41, 24), (45, 25)], fill=WHS)
    # beak: big, yellow, hooked
    d.polygon([(51, 15), (56, 16), (59, 18), (59, 21), (57, 22), (57, 20), (52, 21)], fill=YE)
    d.point([(58, 21), (57, 21)], fill=YED); d.line([(52, 20), (56, 20)], fill=YED)
    # eye, under a brow
    d.point([(49, 16)], fill=K); d.line([(48, 15), (50, 15)], fill=WHS)
    # feet tucked under
    d.rectangle([28, 30, 33, 31], fill=YE); d.point([(28, 32), (30, 32), (32, 32)], fill=YED)
    # outline: every empty pixel touching a filled one turns ink
    px = im.load(); filled = {(x, y) for x in range(W) for y in range(H) if px[x, y][3]}
    for x in range(W):
        for y in range(H):
            if (x, y) in filled: continue
            if any((x + dx, y + dy) in filled for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1))):
                px[x, y] = K + (255,)
    return im


if __name__ == "__main__":
    s = sprite()
    bg = Image.new("RGB", (s.width + 8, s.height + 8), (0x1a, 0x1a, 0x1e)); bg.paste(s, (4, 4), s)
    bg.resize((bg.width * 10, bg.height * 10), Image.NEAREST).save(sys.argv[1])
