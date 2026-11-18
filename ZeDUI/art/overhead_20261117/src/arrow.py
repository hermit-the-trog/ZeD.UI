"""ZeD's foraging arrow (Nov 17 2026, the director: "What about the arrow that points from the character towards a
discovered item when foraging?"). The game's is a homing point (ISBaseIcon:addWorldMarker -> getWorldMarkers():
addPlayerHomingPoint, tinted 0.8 grey): an arrowhead on a ring round the feet, turned toward each find. ZeD's belongs
to the magnifier pin: a chrome rim and the pin's dark glass, an ink line round it. The game turns the picture to any
angle, so it is drawn smooth (8x, box-filtered down) with no light direction baked in, and the glare sits at the tip,
part of the shape. 32 x 32, tip up, like the game's arrow_triangle."""
import os
from PIL import Image, ImageDraw
W = H = 32; SS = 8
INK, RIM_HI, RIM_LO, GLASS, GLARE = (12, 12, 14, 255), (221, 226, 232, 255), (132, 138, 148, 255), (27, 34, 41, 255), (236, 244, 250, 150)

def shape(inset=0.0):
    t = (16, 1.8 + inset * 2.1); l = (2.6 + inset * 1.8, 29.4 - inset * 0.9)       # the game's arrow fills its 32 x 32;
    r = (29.4 - inset * 1.8, 29.4 - inset * 0.9); n = (16, 21.6 - inset * 1.1)      # so does this one
    return [(x * SS, y * SS) for x, y in (t, r, n, l)]

def arrow(kind):
    im = Image.new("RGBA", (W * SS, H * SS), (0, 0, 0, 0)); d = ImageDraw.Draw(im)
    o = shape(0)
    d.line(o + [o[0]], fill=INK, width=int(2.4 * SS), joint="curve")      # the ink line
    d.polygon(o, fill=RIM_HI)
    d.polygon(shape(1.3), fill=RIM_LO)                                    # the rim's inner edge, the chrome turning in
    if kind == "glass":
        d.polygon(shape(2.0), fill=GLASS)                                 # the glass
        g = shape(2.0); t, l = g[0], g[3]
        d.line([(t[0] - 0.9 * SS, t[1] + 3.2 * SS), (t[0] - 3.4 * SS, t[1] + 9.0 * SS)], fill=GLARE, width=int(1.1 * SS))
    else:
        d.polygon(shape(2.0), fill=RIM_HI)
    return im.resize((W, H), Image.BOX)

if __name__ == "__main__":
    os.makedirs("art/arrow", exist_ok=True)
    for k in ("glass", "solid"): arrow(k).save(f"art/arrow/forage_arrow_{k}.png")
    print("ok")
