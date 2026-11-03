import sys, os
sys.path.insert(0, r"C:\Temp\lead\thumb")
import importlib.util
spec = importlib.util.spec_from_file_location("y", r"C:\Temp\lead\thumb\y1993.py")
y = importlib.util.module_from_spec(spec); spec.loader.exec_module(y)
from PIL import Image
F57 = y.F57
F57.update({'Z': ["11111", "00001", "00010", "00100", "01000", "10000", "11111"],
            'V': ["10001", "10001", "10001", "10001", "10001", "01010", "00100"],
            'F': ["11111", "10000", "11110", "10000", "10000", "10000", "10000"],
            'P': ["11110", "10001", "10001", "11110", "10000", "10000", "10000"]})
INK, RED, YEL = y.INK, y.RED, y.YEL


def card(title, lines, name):
    A = y.Art(); A.desktop(); A.menubar(["FILE", "EDIT", "VIEW", "SPECIAL"])
    top = A.window(6, 20, 120, 116, title)
    A.R(7, top, 119, 115, YEL)
    total = 27 + sum(7 + 7 * s for _, s, _ in lines)                     # centre the stack in the window
    yy = top + (115 - top - total) // 2 + 1
    A.big("1993", 63, yy, INK, RED, scale=3); yy += 27 + 7
    for text, scale, col in lines:
        w = A.tw(text, F57, scale=scale) + 1
        x = 63 - w // 2
        if scale > 1:                                                     # bold: a shadow, then the face twice
            sh = RED if col == INK else INK                          # as the 1993: red under black, black under red
            A.text(text, x + 2, yy + 2, sh, F57, scale=scale)
            A.text(text, x + 3, yy + 2, sh, F57, scale=scale)
        A.text(text, x, yy, col, F57, scale=scale)
        A.text(text, x + 1, yy, col, F57, scale=scale)
        yy += 7 * scale + 7
    return A.save(name)


g = card("PROJECT ZOMBOID", [("THE UI VERSION.", 1, INK), ("ALL OF IT.", 2, RED)], "thumb_G_1993_the_ui_version.png")
h = card("UPDATE", [("PZ UI.", 2, INK), ("ALL OF IT.", 2, RED)], "thumb_H_1993_pz_ui.png")
sheet = Image.new("RGB", (2 * 540 + 40, 540 + 200), (27, 40, 56))
for i, im in enumerate((g, h)):
    sheet.paste(im.resize((512, 512), Image.NEAREST), (20 + i * 540, 20))
    sheet.paste(im.resize((160, 160), Image.LANCZOS), (20 + i * 540, 552))
    sheet.paste(im.resize((96, 96), Image.LANCZOS), (200 + i * 540, 552))
sheet.save(os.path.join(y.OUT, "thumb_GH_sheet.png"))
print("ok")
