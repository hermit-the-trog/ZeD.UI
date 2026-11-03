"""Workshop thumbnail, 'this UI is 1993' (the director, Nov 3 2026: "it does not even need to say the mod's name ...
This just needs to tell people, yo, this UI is 1993"). Pixel art on a 128 grid, x8 = 1024, nearest."""
import os, sys
from PIL import Image, ImageDraw, ImageEnhance
sys.path.insert(0, r"C:\Temp\lead\thumb")
G, K = 128, 8
OUT = r"C:\Users\you\Zomboid\ZeD_design_refs\thumbnail"
SHOT = r"C:\Users\you\Zomboid\mods\ZeD-UI\ZeDUI\qa\Oct29_two_widths\zqa_tww_after_walkie.png"
INK, WHT, GRY, LG = (16, 16, 16), (255, 255, 255), (136, 136, 136), (204, 204, 204)
TEAL, TEALD = (31, 122, 98), (18, 78, 62)
RED, YEL = (210, 36, 44), (240, 196, 40)
F35 = {'A': ["010", "101", "111", "101", "101"], 'B': ["110", "101", "110", "101", "110"], 'C': ["011", "100", "100", "100", "011"],
       'D': ["110", "101", "101", "101", "110"], 'E': ["111", "100", "110", "100", "111"], 'F': ["111", "100", "110", "100", "100"],
       'H': ["101", "101", "111", "101", "101"], 'I': ["111", "010", "010", "010", "111"], 'K': ["101", "101", "110", "101", "101"],
       'L': ["100", "100", "100", "100", "111"], 'M': ["10001", "11011", "10101", "10001", "10001"], 'N': ["1001", "1101", "1011", "1001", "1001"],
       'O': ["010", "101", "101", "101", "010"], 'P': ["110", "101", "110", "100", "100"], 'R': ["110", "101", "110", "101", "101"],
       'S': ["011", "100", "010", "001", "110"], 'T': ["111", "010", "010", "010", "010"], 'U': ["101", "101", "101", "101", "111"],
       'V': ["101", "101", "101", "101", "010"], 'W': ["10001", "10001", "10101", "10101", "01010"], 'Y': ["101", "101", "010", "010", "010"],
       'Z': ["111", "001", "010", "100", "111"], 'J': ["001", "001", "001", "101", "010"], ' ': ["00", "00", "00", "00", "00"], '.': ["0", "0", "0", "0", "1"], '!': ["1", "1", "1", "0", "1"]}
F57 = {'W': ["10001", "10001", "10001", "10101", "10101", "11011", "10001"], 'E': ["11111", "10000", "11110", "10000", "10000", "10000", "11111"],
       'L': ["10000", "10000", "10000", "10000", "10000", "10000", "11111"], 'C': ["01111", "10000", "10000", "10000", "10000", "10000", "01111"],
       'O': ["01110", "10001", "10001", "10001", "10001", "10001", "01110"], 'M': ["10001", "11011", "10101", "10001", "10001", "10001", "10001"],
       'T': ["11111", "00100", "00100", "00100", "00100", "00100", "00100"], 'Y': ["10001", "10001", "01010", "00100", "00100", "00100", "00100"],
       'U': ["10001", "10001", "10001", "10001", "10001", "10001", "01110"], 'R': ["11110", "10001", "10001", "11110", "10010", "10001", "10001"],
       'I': ["111", "010", "010", "010", "010", "010", "111"], 'S': ["01111", "10000", "10000", "01110", "00001", "00001", "11110"],
       'N': ["10001", "11001", "10101", "10011", "10001", "10001", "10001"], 'H': ["10001", "10001", "11111", "10001", "10001", "10001", "10001"],
       'A': ["01110", "10001", "10001", "11111", "10001", "10001", "10001"], 'K': ["10001", "10010", "10100", "11000", "10100", "10010", "10001"],
       ' ': ["000", "000", "000", "000", "000", "000", "000"], '.': ["0", "0", "0", "0", "0", "0", "1"]}
# big numerals, a heavy 6 x 9 face (two-cell strokes), scaled again when drawn
BIG = {'1': ["001100", "011100", "111100", "001100", "001100", "001100", "001100", "001100", "111111"],
       '9': ["011110", "110011", "110011", "110011", "011111", "000011", "000011", "110011", "011110"],
       '3': ["011110", "110011", "000011", "000011", "001110", "000011", "000011", "110011", "011110"]}


class Art:
    def __init__(s, bg=TEAL):
        s.im = Image.new("RGB", (G, G), bg); s.px = s.im.load(); s.d = ImageDraw.Draw(s.im)
    def P(s, x, y, c):
        if 0 <= x < G and 0 <= y < G: s.px[x, y] = c
    def R(s, x0, y0, x1, y1, c): s.d.rectangle([x0, y0, x1, y1], fill=c)
    def text(s, t, x, y, c, font=F35, gap=1, scale=1):
        for ch in t:
            g = font.get(ch, font[' '])
            for j, row in enumerate(g):
                for i, b in enumerate(row):
                    if b == '1':
                        s.R(x + i * scale, y + j * scale, x + i * scale + scale - 1, y + j * scale + scale - 1, c)
            x += (len(g[0]) + gap) * scale
        return x
    @staticmethod
    def tw(t, font=F35, gap=1, scale=1): return (sum(len(font.get(ch, font[' '])[0]) + gap for ch in t) - gap) * scale
    def desktop(s, a=TEAL, b=TEALD):
        for y in range(G):
            for x in range(G):
                s.px[x, y] = b if (x + 2 * y) % 4 == 0 else a     # the classic dithered desktop
    def menubar(s, items):
        s.R(0, 0, G - 1, 9, WHT); s.R(0, 10, G - 1, 10, INK)
        x = 4
        # a small Z mark where the menu bar's logo sits
        s.R(x, 2, x + 5, 2, INK); s.P(x + 4, 3, INK); s.P(x + 3, 4, INK); s.P(x + 2, 5, INK); s.P(x + 1, 6, INK); s.R(x, 7, x + 5, 7, INK)
        x += 12
        for it in items:
            x = s.text(it, x, 3, INK) + 6
    def window(s, x0, y0, x1, y1, title):
        s.R(x0 + 1, y0 + 1, x1 + 1, y1 + 1, INK)                       # the one-pixel drop shadow
        s.R(x0, y0, x1, y1, WHT); s.d.rectangle([x0, y0, x1, y1], outline=INK)
        ty = y0 + 1
        for y in range(ty + 1, ty + 9, 2): s.R(x0 + 2, y, x1 - 2, y, INK)   # the title bar's pinstripes
        s.R(x0, ty + 10, x1, ty + 10, INK)
        s.R(x0 + 7, ty + 1, x0 + 15, ty + 9, WHT); s.d.rectangle([x0 + 8, ty + 2, x0 + 14, ty + 8], outline=INK)   # close box
        w = s.tw(title) + 8; cx = (x0 + x1) // 2
        s.R(cx - w // 2, ty + 1, cx + w // 2, ty + 9, WHT)
        s.text(title, cx - s.tw(title) // 2, ty + 3, INK)
        return y0 + 12
    def button(s, x0, y0, x1, y1, label, default=True):
        if default:
            s.d.rounded_rectangle([x0 - 3, y0 - 3, x1 + 3, y1 + 3], radius=5, outline=INK, width=2)
        s.d.rounded_rectangle([x0, y0, x1, y1], radius=3, fill=WHT, outline=INK)
        s.text(label, (x0 + x1) // 2 - s.tw(label) // 2 + 1, (y0 + y1) // 2 - 2, INK)
    def cursor(s, x, y):
        A = ["1", "11", "121", "1221", "12221", "122221", "1222221", "12222221", "122222221", "1222221111",
             "1221221", "121 1221", "11  1221", "1    1221", "     1221", "      11"]
        for j, row in enumerate(A):
            for i, ch in enumerate(row):
                if ch == "1": s.P(x + i, y + j, INK)
                elif ch == "2": s.P(x + i, y + j, WHT)
    def big(s, t, cx, y, c, shadow, scale=3, gap=2):
        w = (len(t) * 6 + (len(t) - 1) * gap) * scale
        x = cx - w // 2
        for dx, dy, col in ((2, 2, shadow), (0, 0, c)):
            xx = x
            for ch in t:
                for j, row in enumerate(BIG[ch]):
                    for i, b in enumerate(row):
                        if b == '1': s.R(xx + i * scale + dx, y + j * scale + dy, xx + i * scale + scale - 1 + dx, y + j * scale + scale - 1 + dy, col)
                xx += (6 + gap) * scale
        return w
    def save(s, name):
        big = s.im.resize((G * K, G * K), Image.NEAREST)
        big.save(os.path.join(OUT, name)); return big


# ---------------------------------------------------------------- D: WELCOME TO / 1993 / OK
D = Art(); D.desktop(); D.menubar(["FILE", "EDIT", "VIEW", "SPECIAL"])
top = D.window(6, 20, 120, 116, "YOUR UI")
D.text("WELCOME TO", 63 - D.tw("WELCOME TO", F57) // 2, top + 8, INK, F57)
D.big("1993", 63, top + 22, INK, RED, scale=3)
D.button(84, 98, 110, 108, "OK")
D.cursor(106, 106)
d_img = D.save("thumb_D_welcome_to_1993.png")

# ---------------------------------------------------------------- E: YOUR UI IS NOW / 1993, yellow, louder
E = Art(); E.desktop(TEAL, TEALD); E.menubar(["FILE", "EDIT", "VIEW", "SPECIAL"])
top = E.window(6, 20, 120, 116, "UPDATE")
E.R(7, top, 119, 115, YEL)
E.text("YOUR UI IS NOW", 63 - E.tw("YOUR UI IS NOW", F57) // 2, top + 7, INK, F57)
E.big("1993", 63, top + 21, INK, RED, scale=3)
E.button(84, 98, 110, 108, "OK")
E.cursor(106, 106)
e_img = E.save("thumb_E_your_ui_is_now_1993.png")

# ---------------------------------------------------------------- F: 1993 huge over the real UI in a window
F = Art(); F.desktop(); F.menubar(["FILE", "EDIT", "VIEW", "SPECIAL"])
F.big("1993", 64, 14, YEL, INK, scale=3)
top = F.window(6, 50, 120, 120, "PROJECT ZOMBOID")
f_img = F.im.resize((G * K, G * K), Image.NEAREST)
shot = Image.open(SHOT).convert("RGB")
cx0, cy0, cx1, cy1 = 7 * K, top * K, 120 * K, 120 * K
w, h = cx1 - cx0, cy1 - cy0
crop = shot.crop((280, 40, 280 + int(w / 0.62), 40 + int(h / 0.62))).resize((w, h), Image.LANCZOS)
f_img.paste(crop, (cx0, cy0))
f_img.save(os.path.join(OUT, "thumb_F_1993_over_ui.png"))

# ---------------------------------------------------------------- the check at Steam's sizes
sheet = Image.new("RGB", (3 * 540 + 40, 540 + 200), (27, 40, 56))
for i, im in enumerate((d_img, e_img, f_img)):
    sheet.paste(im.resize((512, 512), Image.NEAREST), (20 + i * 540, 20))
    sheet.paste(im.resize((160, 160), Image.LANCZOS), (20 + i * 540, 552))
    sheet.paste(im.resize((96, 96), Image.LANCZOS), (200 + i * 540, 552))
sheet.save(os.path.join(OUT, "thumb_1993_sheet.png"))
print("ok")
