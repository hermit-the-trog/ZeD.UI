# ZeDUI/mockups/zed_curtains_v1/build.py  (Oct 19 2026)
# Trims the two game shots to the top 470 px, cuts the apple icon from the
# inventory row, and writes one self-contained page (the app's browser opens
# local pages as snapshots): index.html -> ../zed_curtains_v1.html
import base64, os, re
from PIL import Image
HERE = os.path.dirname(os.path.abspath(__file__))
IMG = os.path.join(HERE, "img")
for n in ("clean", "today"):
    p = os.path.join(IMG, n + ".png"); im = Image.open(p)
    if im.height > 470: im.crop((0, 0, im.width, 470)).save(p)
today = Image.open(os.path.join(IMG, "today.png")).convert("RGBA")
today.crop((562, 177, 582, 197)).save(os.path.join(IMG, "apple.png"))
page = open(os.path.join(HERE, "index.html"), encoding="utf-8").read()
def inline(m):
    with open(os.path.join(HERE, m.group(1)), "rb") as f:
        return "data:image/png;base64," + base64.b64encode(f.read()).decode()
page = re.sub(r"(img/\w+\.png)", inline, page)
open(os.path.join(HERE, "..", "zed_curtains_v1.html"), "w", encoding="utf-8").write(page)
print("built", len(page) // 1024, "KB")
