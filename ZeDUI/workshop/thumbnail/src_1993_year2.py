"""The director's line, Nov 3 2026: "The year is 1993, and so is the user interface. All of it." """
import os
import importlib.util
spec = importlib.util.spec_from_file_location("yr", r"C:\Temp\lead\thumb\year.py")
yr = importlib.util.module_from_spec(spec); spec.loader.exec_module(yr)
y, F57, INK, RED, YEL = yr.y, yr.F57, yr.INK, yr.RED, yr.YEL
F57['B'] = ["11110", "10001", "10001", "11110", "10001", "10001", "11110"]
F57['D'] = ["11110", "10001", "10001", "10001", "10001", "10001", "11110"]
from PIL import Image
BLUE = (30, 76, 196)
GREEN = (24, 140, 64)       # the band behind THE YEAR IS (the director)
WHITE = (255, 255, 255)        # primary blue: the red, yellow, blue and black of the early 90s (the director)


def card(name, bg):
    A = y.Art(); A.desktop(); A.menubar(["FILE", "EDIT", "VIEW", "SPECIAL"])
    top = A.window(6, 15, 120, 121, "PROJECT ZOMBOID")
    A.R(7, top, 119, 120, bg)
    stack = [("THE YEAR IS", 1, WHITE, "BAND", 5), ("1993", 0, None, None, 5), ("AND SO IS THE", 1, BLUE, False, 2),
             ("USER INTERFACE.", 1, BLUE, False, 5), ("ALL OF IT.", 2, RED, "ALL", 0)]
    total = sum((27 if s == 0 else (18 if b == 'ALL' else 7 * s)) + g for _, s, _, b, g in stack)
    band_h = 13
    rest = total - (7 + 5)
    yy0 = top + band_h + (116 - (top + band_h) - rest) // 2
    yy = top + 3
    for text, s, col, bold, g in stack:
        if s == 0:
            A.big("1993", 63, yy, INK, RED, scale=3); yy += 27 + g
        else:
            if bold == "ALL":
                # ALL in the 1993's heavy face (two-pixel strokes), red on a black shadow; OF IT. beside it on its
                # baseline (the director: "the word all")
                HV = {'A': ["011110", "110011", "110011", "110011", "111111", "110011", "110011", "110011", "110011"],
                      'L': ["110000", "110000", "110000", "110000", "110000", "110000", "110000", "110000", "111111"]}
                hs, hg = 2, 2                                   # scale, gap in cells
                wa = (3 * 6 + 2 * hg) * hs
                wo = A.tw("OF IT.", F57, scale=s) + 1
                sp = 7
                x = 63 - (wa + sp + wo) // 2
                for dx, dy, c in ((2, 2, INK), (0, 0, col)):
                    xx = x
                    for ch in "ALL":
                        for j, row in enumerate(HV[ch]):
                            for i, b in enumerate(row):
                                if b == "1":
                                    A.R(xx + i * hs + dx, yy + j * hs + dy, xx + i * hs + hs - 1 + dx, yy + j * hs + hs - 1 + dy, c)
                        xx += (6 + hg) * hs
                base = yy + 9 * hs                              # ALL's baseline
                ox = x + wa + sp
                A.text("OF IT.", ox, base - 7 * s, col, F57, scale=s)
                A.text("OF IT.", ox + 1, base - 7 * s, col, F57, scale=s)
                yy += 9 * hs + g
            else:
                # the small lines, tracked out (the director: "The letters sit too close to each other ... I want to
                # make it readable"): two clear pixels between letters, after the 1-pixel bold
                TR = 3
                if bold == "BAND":                                     # edge to edge across the window, under the title bar
                    A.R(7, top, 119, top + band_h - 1, GREEN)
                    A.R(7, top + band_h - 1, 119, top + band_h - 1, (16, 96, 44))
                w = A.tw(text, F57, gap=TR) + 1
                x = 63 - w // 2
                A.text(text, x, yy, col, F57, gap=TR); A.text(text, x + 1, yy, col, F57, gap=TR)
                yy = yy0 if bold == "BAND" else yy + 7 * s + g
    # BETA on caution tape (the director, Nov 3 2026: "a beta strip across it ... pixel art, caution tape"): yellow,
    # black stripes on the slant, a black edge top and bottom, BETA on two plates
    TY0, TY1 = 116, 127
    TAPE, INKT = (246, 206, 38), (20, 20, 20)
    A.R(0, TY0, 127, TY1, TAPE)
    for yy_ in range(TY0 + 1, TY1):
        for xx in range(128):
            if ((xx + yy_) // 4) % 2 == 0: A.P(xx, yy_, INKT)
    A.R(0, TY0, 127, TY0, INKT); A.R(0, TY1, 127, TY1, INKT)
    A.R(0, TY0 + 1, 127, TY0 + 1, (255, 232, 120))                     # a lit edge along its top
    for cx in (32, 96):
        w = A.tw("BETA", F57) + 1
        x0 = cx - w // 2 - 5
        A.R(x0, TY0 + 2, x0 + w + 9, TY1 - 1, TAPE)
        A.text("BETA", x0 + 5, TY0 + 3, INKT, F57)
    return A.save(name)


j1 = card("thumb_J_1993_and_so_is_the_ui.png", YEL)
j2 = card("thumb_J2_1993_and_so_is_the_ui_white.png", (255, 255, 255))
sheet = Image.new("RGB", (2 * 540 + 40, 540 + 200), (27, 40, 56))
for i, im in enumerate((j1, j2)):
    sheet.paste(im.resize((512, 512), Image.NEAREST), (20 + i * 540, 20))
    sheet.paste(im.resize((160, 160), Image.LANCZOS), (20 + i * 540, 552))
    sheet.paste(im.resize((96, 96), Image.LANCZOS), (200 + i * 540, 552))
sheet.save(os.path.join(y.OUT, "thumb_J_sheet.png"))
print("ok")
