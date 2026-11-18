from PIL import Image, ImageDraw
import compose_pins as CP
D = "/mnt/user-data/uploads/ZeD_design_refs/overhead_refs_20261115"
big = Image.open(f"{D}/zqa_m79_3840x2160_t_SportsCar_card.png").convert("RGBA")
def up(im, k): return im.resize((im.width * k, im.height * k), Image.NEAREST)
def over_head(frame, badge, headx, heady, k=2, gap=3):
    """the balloon's tail tip `gap` units above the head top, centred on it (as the bubbles)"""
    b = up(badge, k)
    bw = (badge.width - 6) // 2 * k                         # the tail's x in the badge (its body is width - shadow - 4)
    frame.alpha_composite(b, (headx - bw - k, heady - gap * k - b.height + 6 * k))
# 1) the key, walking up to the car
crop = (1560, 860, 2160, 1260)
a = big.crop(crop); b = a.copy()
hx, hy = 1932 - crop[0], 1028 - crop[1]
over_head(a, Image.open("art/overhead/CarKey.png"), hx, hy)
over_head(b, Image.open("art/overhead/CarKey_none.png"), hx, hy)
# 2) search mode on: the eye, and pins on the grass
g = big.crop((2900, 1560, 3500, 1960))
for (x, y, opt, item, st, po) in ((120, 120, "B", "Item_MushroomChanterelle", "glass", False), (300, 210, "B", "Item_Frog", "hint", False),
                                  (470, 140, "B", None, "unknown", False)):
    g.alpha_composite(CP.pin(opt, item, st, po), (x - 29, y - 88))
ga = big.crop((2900, 1560, 3500, 1960))
for (x, y, opt, item, st, po) in ((120, 120, "A", "Item_MushroomChanterelle", "glass", False), (300, 210, "A", "Item_Frog", "hint", False),
                                  (470, 140, "A", None, "unknown", False)):
    ga.alpha_composite(CP.pin(opt, item, st, po), (x - 29, y - 88))
e = big.crop(crop); over_head(e, Image.open("art/overhead/eyeconOn.png"), hx, hy)
cells = [("Walk up to a car: you have its key", a), ("... you don't", b), ("Search mode on", e),
         ("Pins A on grass, actual size at 4K", ga), ("Pins B on grass, actual size at 4K", g)]
S = Image.new("RGBA", (600 * 3 + 40, 2 * 430 + 20), (24, 24, 26, 255)); d = ImageDraw.Draw(S)
for i, (lab, im) in enumerate(cells):
    x = 10 + (i % 3) * 610; y = 10 + (i // 3) * 430
    S.alpha_composite(im, (x, y)); d.text((x, y + 404), lab, fill=(220, 220, 214))
S.save("ingame_actual_4k.png"); print(S.size)
