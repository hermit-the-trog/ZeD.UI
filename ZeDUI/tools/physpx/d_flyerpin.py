# ZeDUI/tools/physpx/d_flyerpin.py  (Oct 19 2026)
# The flyer map's pins (MapsTab.lua): a flyer pinned to the map with a red
# thumbtack, and the character's ballpoint tick drawn over one they have been
# to. One texel a design unit; the game draws them at a whole multiple.
#   py d_flyerpin.py  -> 42/media/textures/ZeD/map/flyer_pin.png, flyer_tick.png
import os
from PIL import Image, ImageDraw

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(HERE, "..", "..", "..", "42", "media", "textures", "ZeD", "map")
os.makedirs(OUT, exist_ok=True)

def c(h, a=255):
    h = h.lstrip("#"); return (int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16), a)

# --- the pin: 13 x 16. Paper 11 x 13 (a shadow right and below), the tack at the top
pin = Image.new("RGBA", (13, 16), (0, 0, 0, 0))
d = ImageDraw.Draw(pin)
d.rectangle((2, 3, 12, 15), fill=c("#000000", 90))           # shadow
d.rectangle((1, 2, 11, 14), fill=c("#efe8d4"))                # the paper
d.line((1, 2, 11, 2), fill=c("#fbf7ea")); d.line((1, 2, 1, 14), fill=c("#fbf7ea"))
d.line((11, 3, 11, 14), fill=c("#c9bfa3")); d.line((2, 14, 11, 14), fill=c("#c9bfa3"))
d.rectangle((3, 5, 9, 6), fill=c("#3a3a3a"))                  # the headline
for y, x2 in ((8, 9), (10, 8), (12, 9)):                      # the text
    d.line((3, y, x2, y), fill=c("#9a9384"))
d.rectangle((9, 11, 10, 13), fill=c("#d0a040"))               # a coupon corner
# the tack: a red head with a light glint, its shadow on the paper
d.point((7, 3), fill=c("#000000", 80))
d.rectangle((4, 0, 7, 2), fill=c("#c02a2a")); d.line((5, 0, 6, 0), fill=c("#e05a5a"))
d.point((5, 1), fill=c("#f4a0a0")); d.line((4, 2, 7, 2), fill=c("#7a1414"))
pin.save(os.path.join(OUT, "flyer_pin.png"))

# --- the tick: 12 x 10, blue ballpoint, a little uneven (drawn by the character)
tick = Image.new("RGBA", (12, 10), (0, 0, 0, 0))
d = ImageDraw.Draw(tick)
ink, ink2 = c("#1f3f9f"), c("#2c52c0", 200)
pts = [(0, 5), (1, 6), (2, 7), (3, 8), (4, 8), (5, 7), (6, 5), (7, 4), (8, 3), (9, 2), (10, 1), (11, 0)]
for (x, y) in pts: d.point((x, y), fill=ink)
for (x, y) in [(1, 5), (2, 6), (3, 7), (4, 7), (6, 6), (7, 5), (8, 4), (9, 3), (10, 2)]: d.point((x, y), fill=ink2)
tick.save(os.path.join(OUT, "flyer_tick.png"))

sheet = Image.new("RGBA", (40, 20), (219, 215, 192, 255))
sheet.paste(pin, (2, 2), pin); sheet.paste(pin, (20, 2), pin); sheet.paste(tick, (23, 9), tick)
sheet.resize((320, 160), Image.NEAREST).save(os.path.join(HERE, "flyerpin_sheet.png"))
print("ok")
