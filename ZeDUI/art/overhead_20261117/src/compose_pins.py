from PIL import Image, ImageDraw
import sys
sys.path.insert(0, ".")
P = "art/pins"; I = "packparse/items"
GEOM = {"A": (29, 28, 16, 22), "B": (29, 26, 21.5, 25.5)}
def pin(opt, item=None, state="glass", poison=False):
    im = Image.open(f"{P}/pin{opt}_back.png").copy()
    cx, cy, ri, ro = GEOM[opt]
    if item and state != "unknown":
        it = Image.open(f"{I}/{item}.png").convert("RGBA")
        im.alpha_composite(it, (int(round(cx - 16)), int(round(cy - 16))))
    im.alpha_composite(Image.open(f"{P}/pin{opt}_{state}.png"))
    if poison:
        im.alpha_composite(Image.open(f"{P}/poison_mark.png"), (int(cx + ri * 0.62), int(cy + ri * 0.5)))
    return im
CASES = [("Found", "Item_MushroomChanterelle", "glass", False), ("Found", "Item_BeautyBerries", "glass", False),
         ("Found", "Item_Cricket", "glass", False), ("Hint", "Item_Frog", "hint", False), ("Unknown", None, "unknown", False),
         ("Poison", "Item_MushroomFlyAminita", "glass", True)]
if __name__ == "__main__":
    k = 4
    rows = []
    for opt in ("vanilla", "A", "B"):
        cells = []
        for lab, item, st, po in CASES:
            if opt == "vanilla":
                n = {"Item_MushroomChanterelle": "pinIconMushrooms", "Item_BeautyBerries": "pinIconBerries", "Item_Cricket": "pinIconInsects",
                     "Item_Frog": "pinIconAnimals", None: "pinIconUnknown", "Item_MushroomFlyAminita": "pinIconMushrooms"}[item]
                im = Image.open(f"/mnt/user-data/uploads/ZeD_design_refs/overhead_refs_20261115/{n}.png").convert("RGBA")
            else:
                im = pin(opt, item, st, po)
            cells.append((lab, im))
        rows.append((opt, cells))
    cw, ch = 60 * k + 30, 90 * k + 40
    S = Image.new("RGBA", (170 + cw * 6, 30 + ch * 3), (78, 96, 62, 255))
    d = ImageDraw.Draw(S)
    for r, (opt, cells) in enumerate(rows):
        y = 20 + r * ch
        d.text((12, y + 150), {"vanilla": "The game's", "A": "A  Pin with lens", "B": "B  Magnifier"}[opt], fill=(255, 255, 255))
        for c, (lab, im) in enumerate(cells):
            x = 170 + c * cw
            S.alpha_composite(im.resize((60 * k, 90 * k), Image.NEAREST), (x, y))
            d.text((x + 4, y + 90 * k + 6), lab, fill=(235, 235, 225))
    S.save("pins_sheet_4x.png"); print(S.size)
