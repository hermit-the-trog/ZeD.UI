from PIL import Image, ImageDraw, ImageFont
import compose as C
F = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf", 22)
F2 = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf", 17)
BOX = (110, 170, 640, 440); Z = 2
rows = [("Approved Oct 24: the bubbles follow the theme. Dark, orange accent", "dark", [("speech", "Speech: what the character says"), ("thought", "Thought: the action bar's verbose progress"), ("both", "Both: the speech balloon steps right of the cloud")]),
        ("Light", "paper", [("speech", "Speech"), ("thought", "Thought"), ("both", "Both")]),
        ("The thought bubble keeps every action bar state", "dark", [("queue", "A queue: RIPPING 4/12, notched per item"), ("done", "Done: the positive colour, then it fades"), ("speech", "")])]
tw, th_ = (BOX[2] - BOX[0]) * Z, (BOX[3] - BOX[1]) * Z
pad = 24
W = pad + 3 * (tw + pad); H = pad + len(rows) * (th_ + 90)
out = Image.new("RGB", (W, H), (24, 24, 26)); dr = ImageDraw.Draw(out)
y = pad
for title, theme, tiles in rows:
    dr.text((pad, y), title, fill=(236, 232, 222), font=F); y += 34
    x = pad
    for kind, lab in tiles:
        if not lab: x += tw + pad; continue
        im = C.scene(kind, theme).crop(BOX).resize((tw, th_), Image.NEAREST)
        out.paste(im.convert("RGB"), (x, y)); dr.text((x, y + th_ + 6), lab, fill=(160, 156, 146), font=F2)
        x += tw + pad
    y += th_ + 56
out.save("zed_bubbles_v1.png"); print(out.size)
# and one tile at the real 4K size, uncropped, for scale
C.scene("both", "paper").convert("RGB").save("zed_bubbles_v1_actual_4k.png")
