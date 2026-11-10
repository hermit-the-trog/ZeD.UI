"""Punch list 139, first draft (Nov 10 2026): ZeD's pointer set. The resting hand (the director: "ZeD pixel-art hand, so
the whole set matches") and the drag pointers, which are the menu icons themselves with their marks, each cut out with a
1 px paper rim so it reads on any ground. The red dot on the zoomed copies is the hotspot (where the click lands): the
finger's tip on the hand; the top left corner of the icon's live area on a drag pointer, where the finger tip was.
Run from the repo root: python3 ZeDUI/mockups/zed_pointer_v1/pointer_v1.py"""
import re
from PIL import Image, ImageDraw, ImageFont, ImageFilter

OUT = 'ZeDUI/mockups/zed_pointer_v1/pointer_v1.png'
W = '42/media/textures/ZeD/wheel/'
INK, PAPER = (0x14, 0x14, 0x14), (0xF2, 0xF2, 0xF2)
ADD, REM = (0x0B, 0x63, 0xB0), (0xC2, 0x41, 0x0C)
marks = dict(re.findall(r'\["(\w+)"\] = "(add|remove)"', open('42/media/lua/shared/ZeD/ContextPxIcons.lua').read()))

# the hand, 16 x 16: o outline (ink), . paper inside, blank clear
HAND16 = [
    "     oo         ",
    "    o..o        ",
    "    o..o        ",
    "    o..o        ",
    "    o..ooo      ",
    "    o..o..ooo   ",
    " oo o..o..o..oo ",
    "o..oo........o.o",
    "o...o..........o",
    " o.............o",
    "  o............o",
    "  o...........o ",
    "   o..........o ",
    "   o.........o  ",
    "    o........o  ",
    "    oooooooooo  ",
]
HOT_HAND = (5, 0)

def hand():
    im = Image.new('RGBA', (16, 16), (0, 0, 0, 0))
    for y, r in enumerate(HAND16):
        for x, ch in enumerate(r):
            if ch == 'o': im.putpixel((x, y), INK + (255,))
            elif ch == '.': im.putpixel((x, y), PAPER + (255,))
    return im

def drag(id_):
    """the 16 icon in ink, its mark in colour, a 1 px paper rim round it"""
    a = Image.open(W + '16/zw_%s.png' % id_).convert('RGBA').getchannel('A').point(lambda q: 255 if q > 128 else 0)
    rim = a.filter(ImageFilter.MaxFilter(3))
    im = Image.new('RGBA', (16, 16), (0, 0, 0, 0))
    im.paste(Image.new('RGBA', (16, 16), PAPER + (255,)), (0, 0), rim)
    im.paste(Image.new('RGBA', (16, 16), INK + (255,)), (0, 0), a)
    if id_ in marks:
        m = Image.open(W + '16/zw_%s_mk.png' % id_).convert('RGBA').getchannel('A').point(lambda q: 255 if q > 128 else 0)
        im.paste(Image.new('RGBA', (16, 16), (ADD if marks[id_] == 'add' else REM) + (255,)), (0, 0), m)
    return im

SET = [("At rest", hand(), HOT_HAND), ("Drop: floor", drag("to_floor"), (1, 1)), ("Put in", drag("tray_out"), (1, 1)),
       ("Take", drag("tray_in"), (1, 1)), ("Equip", drag("equip"), (1, 1)), ("Can't drop here", drag("warning"), (1, 1))]

F = ImageFont.truetype('/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf', 12)
FB = ImageFont.truetype('/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf', 13)
K, cw = 8, 150
Wd = 20 + cw * len(SET)
img = Image.new("RGB", (Wd, 460), (0x1c, 0x1b, 0x1a)); d = ImageDraw.Draw(img)
d.text((20, 10), "ZeD's pointer set, draft 1 (punch list 139): zoomed 8x with the hotspot in red, then true size on four grounds",
       fill=(232, 228, 220), font=FB)
for i, (name, im, hot) in enumerate(SET):
    x = 20 + i * cw
    d.text((x, 34), name, fill=(232, 228, 220), font=FB)
    # zoomed on a checker
    for yy in range(16):
        for xx in range(16):
            c = (0x3a, 0x3a, 0x3a) if (xx + yy) % 2 else (0x30, 0x30, 0x30)
            d.rectangle([x + xx * K, 56 + yy * K, x + xx * K + K - 1, 56 + yy * K + K - 1], fill=c)
    big = im.resize((16 * K, 16 * K), Image.NEAREST)
    img.paste(big, (x, 56), big)
    hx, hy = hot
    d.rectangle([x + hx * K + 2, 56 + hy * K + 2, x + hx * K + K - 3, 56 + hy * K + K - 3], fill=(230, 40, 40))
grounds = [("Dark window", (0x14, 0x14, 0x14)), ("Light window", (0xBE, 0xBE, 0xBE)), ("Menu paper", PAPER), ("The world", (0x5a, 0x6b, 0x3c))]
y = 200
for gname, g in grounds:
    d.rectangle([20, y, Wd - 20, y + 44], fill=g)
    d.text((24, y + 2), gname, fill=(128, 128, 128), font=F)
    for i, (name, im, hot) in enumerate(SET):
        x = 20 + i * cw + 60
        img.paste(im, (x, y + 14), im)
        im2 = im.resize((32, 32), Image.NEAREST)
        img.paste(im2, (x + 26, y + 6), im2)
    y += 52
d.text((20, y + 4), "True size at 1x (16 px) and 2x (32 px). A drag pointer is the menu's own icon with its mark; the rim keeps it on any ground.",
       fill=(190, 186, 178), font=F)
img.crop((0, 0, Wd, y + 30)).save(OUT)
print(OUT)
