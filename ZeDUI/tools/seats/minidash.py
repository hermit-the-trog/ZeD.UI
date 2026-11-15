"""The seat picker's mini dashboard (the director, Nov 15 2026): the vehicle's own ZeD dashboard at the cabin's pixel
size ("not very detailed ... more of a suggestion"), and the whole width of the car: the stereo stack in the middle
over the console, the cluster in front of the wheel, then past the stack the passenger's side with its glove box.
The passenger's side and the driver's end cap are drawn the dashboards' way (dashpx, the same cabin colour and trim),
laid beside the real plate at its own size, and the lot taken down to 1 unit = 1 px in one go."""
import sys
import os
HERE = os.path.dirname(os.path.abspath(__file__))
DASHPX = os.environ.get("ZED_DASHPX") or os.path.join(HERE, "..", "dashpx")   # ZeDUI/tools/dashpx beside this folder
import numpy as np
from PIL import Image, ImageFilter
sys.path.insert(0, DASHPX)
import colors  # noqa: F401  (the cabin colour ramps: v_navy70 and the rest)
import designs as DZ
from dashlib import Build, box, _pebble, vent_rect, vent_round, W, H, Z_TOP, Z_BROW, Z_FACE
from engine import OUTLINE

PLATES = os.environ.get("ZED_DASH_PLATES")      # a folder of colors.py's plates (design__cabin.png); else rendered here
_PLATE = {}


def plate_img(dash):
    """the dashboard's plate in that cabin colour: colors.py's picture, from PLATES or rendered now (about a second)"""
    if dash not in _PLATE:
        f = PLATES and os.path.join(PLATES, dash + ".png")
        if f and os.path.exists(f): _PLATE[dash] = Image.open(f).convert("RGBA")
        else:
            did, cab = dash.split("__"); _PLATE[dash] = colors.plate(did, cab).convert("RGBA")
    return _PLATE[dash]
TRIM = {"van": "rubber", "cossette": "rubber", "rancher": "rubber", "dashelite": "rubber", "primani": "rubber", "suv": "rubber",
        "police": "rubber", "taxi": "rubber", "ambulance": "rubber", "fire": "rubber", "ranger": "rubber"}   # else chrome
VENTS = {"bulldriver": "round", "d6": "round", "dart": "round", "rancher": "round"}                     # else rect
COLUMN_X, STACK_X = 250, 644         # on the plate: the steering column's middle, the console's middle


def side_panel(did, cabin, w, glovebox=True):
    """a plain stretch of the dash, its outer shoulder at the right end (x = w); glovebox: the passenger's side"""
    title, _, seed, *_ = DZ.DESIGNS[did]
    b = Build(did, cabin, seed=seed, title=title)
    d = b.d; M = d.M
    top_y, x1 = 2, w - 1
    hood = M().poly([(0, top_y), (x1 - 8, top_y), (x1, top_y + 8), (x1, H), (0, H)]).get()
    d.flat(hood, Z_FACE, cabin, polish=0.15); _pebble(d, hood)
    d.ramp_h(hood & (d.YY < top_y + 7), Z_TOP, Z_BROW, axis="y", a0=top_y, a1=top_y + 7)
    d.h[hood & (d.YY >= top_y + 7) & (d.YY < 16)] = Z_BROW
    trim = TRIM.get(did, "chrome")
    lip = box(0, 14, x1 - 12, 3)
    d.cyl(0, 14, x1 - 12, 3, 1.4 if trim == "chrome" else 1.0, trim, axis="h", polish=1.0 if trim == "chrome" else 0.2,
          on=Z_BROW - 0.4, mask=lip)
    if glovebox:
        vx = x1 - 132
        if VENTS.get(did) == "round": vent_round(d, vx + 50, 40, 24, on=Z_FACE, bezel="chrome" if trim == "chrome" else "blackp")
        else: vent_rect(d, vx - 10, 26, 110, 30, on=Z_FACE, bezel="chrome" if trim == "chrome" else "blackp")
        # the glove box door, low on the dash and in front of the passenger, its latch on top; drawn bold, since the
        # mini keeps one pixel in fifteen: a wide dark gap round the door, a wide latch
        dx, dy, dw, dh = 84, 58, 330, 92
        outer = M().rrect(dx - 10, dy - 10, dw + 20, dh + 20, 8).get()
        door = M().rrect(dx, dy, dw, dh, 5).get()
        d.well(outer & ~door, 2.5, "blackp", bevel=1.0, polish=0.1)
        d.slab(door, 2.2, cabin, bevel=4.0, polish=0.25, on=Z_FACE)
        latch = trim if trim == "chrome" else "alu"
        lx = dx + dw // 2 - 50
        d.slab(M().rrect(lx, dy + 10, 100, 18, 4).get(), 1.8, latch, bevel=1.5, polish=0.9, on=Z_FACE + 2.2)
    return d.render()


def mini_dash(dash, dash_w, column_x, stack_x):
    """dash: 'design__cabin'; the mini at dash_w px, the column under column_x and the stack's middle at stack_x
    (both in px from the dash's left end). Returns (image, height)."""
    did, cab = dash.split("__")
    f = (stack_x - column_x) / (STACK_X - COLUMN_X)
    WW = int(round(dash_w / f))
    off = int(round(column_x / f - COLUMN_X))          # where the plate's x = 0 lands
    can = Image.new("RGBA", (WW, H), (0, 0, 0, 0))
    cw = min(W, off + 40)
    cap = side_panel(did, cab, cw, glovebox=False).crop((0, 0, cw, H)).transpose(Image.FLIP_LEFT_RIGHT)
    can.alpha_composite(cap, (0, 0))                   # the driver's end, out to the door
    pw = WW - (off + 792)
    pas = side_panel(did, cab, pw, glovebox=True)
    can.alpha_composite(pas, (off + 792, 0))           # the passenger's side, from under the stack's edge
    plate = plate_img(dash).crop((8, 0, W, H))
    can.alpha_composite(plate, (off + 8, 0))
    h = int(round(H * f))
    small = can.resize((dash_w, h), Image.BOX)
    a = np.array(small)
    solid = a[:, :, 3] >= 110
    rgb = Image.fromarray(a[:, :, :3]).filter(ImageFilter.UnsharpMask(1.0, 80, 2))
    rgb = np.array(rgb.quantize(10, method=Image.Quantize.MEDIANCUT).convert("RGB"))
    # one pass of despeckling: a lone pixel unlike all four neighbours takes the colour two or more of them share
    # (the switch labels' specks go; the gauges, the radio slot and the glove box are bigger than a pixel and stay)
    src = rgb.copy()
    for y in range(h):
        for x in range(dash_w):
            if not solid[y, x]: continue
            nb = [tuple(src[yy, xx]) for yy, xx in ((y - 1, x), (y + 1, x), (y, x - 1), (y, x + 1))
                  if 0 <= yy < h and 0 <= xx < dash_w and solid[yy, xx]]
            if nb and tuple(src[y, x]) not in nb:
                best = max(set(nb), key=nb.count)
                if nb.count(best) >= 2: rgb[y, x] = best
    out = np.zeros((h, dash_w, 4), np.uint8)
    out[:, :, :3] = rgb; out[:, :, 3] = np.where(solid, 255, 0)
    pad = np.pad(solid, 1)
    edge = solid & ~(pad[:-2, 1:-1] & pad[2:, 1:-1] & pad[1:-1, :-2] & pad[1:-1, 2:])
    out[edge, :3] = OUTLINE
    return Image.fromarray(out, "RGBA"), h, can


