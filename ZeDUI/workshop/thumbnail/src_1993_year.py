"""The director's line, Nov 3 2026: "The year is 1993. This is your UI. All of it." """
import sys, os
import importlib.util
spec = importlib.util.spec_from_file_location("gh", r"C:\Temp\lead\thumb\gh.py")
gh = importlib.util.module_from_spec(spec); spec.loader.exec_module(gh)
y, F57, INK, RED, YEL = gh.y, gh.F57, gh.INK, gh.RED, gh.YEL
from PIL import Image


def line(A, text, yy, col, scale, bold):
    w = A.tw(text, F57, scale=scale) + 1
    x = 63 - w // 2
    if bold:
        sh = RED if col == INK else INK
        o = 1 if scale == 1 else 2                      # the shadow's offset follows the size
        A.text(text, x + o, yy + o, sh, F57, scale=scale); A.text(text, x + o + 1, yy + o, sh, F57, scale=scale)
    A.text(text, x, yy, col, F57, scale=scale)
    if bold or scale == 1: A.text(text, x + 1, yy, col, F57, scale=scale)
    return 7 * scale


def card(name, title, bg=YEL):
    A = y.Art(); A.desktop(); A.menubar(["FILE", "EDIT", "VIEW", "SPECIAL"])
    top = A.window(6, 20, 120, 116, title)
    A.R(7, top, 119, 115, bg)
    stack = [("THE YEAR IS", 1, INK, False, 5), ("1993", 0, None, None, 6), ("THIS IS YOUR UI.", 1, INK, False, 7),
             ("ALL OF IT.", 2, RED, True, 0)]
    total = sum((27 if s == 0 else 7 * s) + g for _, s, _, _, g in stack)
    yy = top + (115 - top - total) // 2 + 1
    for text, s, col, bold, g in stack:
        if s == 0:
            A.big("1993", 63, yy, INK, RED, scale=3); yy += 27 + g
        else:
            yy += line(A, text, yy, col, s, bold) + g
    return A.save(name)


i1 = card("thumb_I_the_year_is_1993.png", "PROJECT ZOMBOID")
i2 = card("thumb_I2_the_year_is_1993_white.png", "PROJECT ZOMBOID", bg=(255, 255, 255))
sheet = Image.new("RGB", (2 * 540 + 40, 540 + 200), (27, 40, 56))
for i, im in enumerate((i1, i2)):
    sheet.paste(im.resize((512, 512), Image.NEAREST), (20 + i * 540, 20))
    sheet.paste(im.resize((160, 160), Image.LANCZOS), (20 + i * 540, 552))
    sheet.paste(im.resize((96, 96), Image.LANCZOS), (200 + i * 540, 552))
sheet.save(os.path.join(y.OUT, "thumb_I_sheet.png"))
print("ok")
