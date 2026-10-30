"""Before (today's plaques, the pipeline's own drive previews) beside after (the brand lockups), 2x."""
import os
from PIL import Image, ImageDraw
OUT = r"C:\Users\danie\Zomboid\mods\ZeD-UI\ZeDUI\tools\dashpx\out"
ORDER = ["luxury", "nyala", "cossette", "d6", "dashelite", "primani", "dart", "horizon", "wagon", "suv", "van", "bulldriver", "rancher"]
PICK = ["d6", "bulldriver", "van", "luxury", "horizon", "primani", "dashelite", "suv"]
after_sheet = Image.open(r"C:\Temp\brand_insitu_v3.png").convert("RGBA")
TW, TH = 612, 224
rows = []
for did in PICK:
    i = ORDER.index(did)
    a = after_sheet.crop(((i % 3) * (TW + 12), (i // 3) * (TH + 12), (i % 3) * (TW + 12) + TW, (i // 3) * (TH + 12) + 150))
    b = Image.open(os.path.join(OUT, did, "live_drive_1x.png")).convert("RGBA").crop((494, 0, 800, 75))
    b = b.resize((b.width * 2, b.height * 2), Image.NEAREST)
    rows.append((b, a))
W = TW * 2 + 20; H = 30 + sum(150 + 10 for _ in rows)
s = Image.new("RGBA", (W, H), (16, 16, 16, 255)); dr = ImageDraw.Draw(s)
dr.text((8, 8), "NOW: the plaques", fill=(220, 220, 220, 255)); dr.text((TW + 28, 8), "BRANDED", fill=(220, 220, 220, 255))
y = 30
for b, a in rows:
    s.paste(b, (0, y)); s.paste(a, (TW + 20, y)); y += 160
s.save(r"C:\Temp\brand_before_after_2x.png"); print(s.size)
