"""The clock radio in the dark while the character sleeps (brief: ZeDUI/mockups/zed_fish_sleep_DESIGN_BRIEF.md;
director, Oct 16 2026: "the oldschool red number clock"; the reference a GE woodgrain clock radio): a walnut-grain top
with its snooze bar and buttons, a black case, a chrome bezel round smoked glass, the AM / FM dial on the right with
its red needle. Parody brand GENERIC ELECTRIC with a GE roundel.

330 x 84 plate pixels, transparent. Every segment drawn dark (unlit), the AM / PM dots, the colon and the ALARM lamp
unlit: the game lights them live (Overrides/Sleeping.lua) at exactly these places:
  digits: top left x = 36 + (0, 22, 52, 74), y = 26, each 16 x 34, stroke 3
  colon (80, 35) and (80, 48); AM dot (25, 29), PM dot (25, 54); ALARM lamp (132, 54); all 3 x 3
usage: python d_clockradio.py [mod root]   (default ./out/mod/ZeD-UI) -> media/textures/ZeD/props/clock_radio.png"""
import os
import sys

from physlib import *            # noqa: F401,F403
from engine import add_ramp

add_ramp("case_black", "#1c1c1f")
add_ramp("smoked", "#170b0a")
add_ramp("seg_off", "#2c100d")
add_ramp("dial_print", "#c9c5bc", light=1.05)
add_ramp("needle_red", "#e23a22", light=1.1)
add_ramp("plinth", "#121214")

W, H = 330, 84
DX, DY = 36, 26
DIGIT_X = (0, 22, 52, 74)
DW, DH, DT = 16, 34, 3
COLON = ((80, 35), (80, 48))
AM, PM, ALARM = (25, 29), (25, 54), (132, 54)


def segments(x, y):
    """a digit's seven segments, as the game lights them (Overrides/Sleeping.lua digit())"""
    half = DH // 2
    return {"a": (x + 2, y, DW - 4, DT), "d": (x + 2, y + DH - DT, DW - 4, DT), "g": (x + 2, y + half - 1, DW - 4, DT),
            "b": (x + DW - DT, y + 2, DT, half - 3), "c": (x + DW - DT, y + half + 1, DT, half - 3),
            "f": (x, y + 2, DT, half - 3), "e": (x, y + half + 1, DT, half - 3)}


def clock_radio(worn=True):
    p = Plate("clock_radio", W, H, seed=37)
    d = p.d
    # the plinth under the case, set back
    d.slab(Mask(W, H).rrect(11, 70, 308, 13, 2).get(), Z_FACE - 0.6, "plinth", bevel=1.2, polish=0.3)
    # the case: black, softly rounded
    case = Mask(W, H).rrect(3, 11, 324, 63, 3).get()
    d.slab(case, Z_FACE + 1.0, "case_black", bevel=2.4, polish=0.55)
    d.grain_pebble(case, 0.02, seed=3)
    # the walnut-grain top, a lip over the case's top edge
    top = Mask(W, H).rrect(2, 3, 326, 12, 2).get()
    d.slab(top, Z_FACE + 2.0, "walnut", bevel=1.6, polish=0.45)
    d.grain_wood(top, scale=1.0, seed=8)
    # the snooze bar and the buttons on top
    for (x, w_) in ((21, 26), (143, 14), (163, 14), (183, 14), (203, 14)):
        d.slab(Mask(W, H).rrect(x, 0, w_, 5, 1).get(), Z_FACE + 2.6, "case_black", bevel=0.8, polish=0.6)
    d.slab(Mask(W, H).rrect(266, 1, 5, 4, 1).get(), Z_FACE + 2.6, "chrome", bevel=0.6, polish=1.0)
    # the chrome bezel round the smoked glass
    window(d, 10, 19, 310, 50, 1.2, face="smoked", bezel="chrome", r=1, bezel_t=2, on=Z_FACE + 1.0, lens=True)
    # the glass's printing: AM / PM, ALARM, the brand, the dial
    d.text("AM", 14, 27, "dial_print", font="35", flatlight=True)
    d.text("PM", 14, 52, "dial_print", font="35", flatlight=True)
    d.text("ALARM", 137, 53, "dial_print", font="35", flatlight=True)
    d.paint(ring(d, 185.5, 36.5, 6.6, 7.8), "dial_print", flatlight=True)
    d.text("GE", 186, 34, "dial_print", font="35", align="c", flatlight=True)
    d.text("GENERIC", 186, 48, "dial_print", font="35", align="c", flatlight=True)
    d.text("ELECTRIC", 186, 55, "dial_print", font="35", align="c", flatlight=True)
    d.paint(rbox(d, 209, 24, 1, 41), "dial_print", flatlight=True)
    d.text("FM", 213, 27, "dial_print", font="35", flatlight=True)
    d.text("AM", 213, 51, "dial_print", font="35", flatlight=True)
    for x, t in ((228, "88"), (243, "92"), (258, "96"), (275, "100"), (293, "104"), (311, "108")):
        d.text(t, x, 27, "dial_print", font="35", align="c", flatlight=True)
    for x, t in ((228, "55"), (243, "65"), (258, "80"), (275, "100"), (293, "130"), (311, "160")):
        d.text(t, x, 51, "dial_print", font="35", align="c", flatlight=True)
    d.paint(rbox(d, 223, 40, 94, 1), "dial_print", flatlight=True)
    for x in range(224, 317, 2):
        d.paint(rbox(d, x, 38 if x % 10 == 4 else 39, 1, 3 if x % 10 == 4 else 1), "dial_print", flatlight=True)
    d.paint(rbox(d, 250, 25, 2, 40), "needle_red", flatlight=True)
    # the unlit segments, the dots, the colon and the ALARM lamp: dark, ready for the game to light
    for dx in DIGIT_X:
        for (x, y, w_, h_) in segments(DX + dx, DY).values():
            d.paint(rbox(d, x, y, w_, h_), "seg_off", flatlight=True)
    for (x, y) in COLON + (AM, PM, ALARM):
        d.paint(rbox(d, x, y, 3, 3), "seg_off", flatlight=True)
    if worn:
        import wear as WR
        WR.scuffs(d, WR.mat_mask(d, "case_black"), 0.0012, seed=4, amount=0.05)
    return p


def render():
    return clock_radio().d.render(chrome_env="room")


def export(root):
    dd = os.path.join(root, "42", "media", "textures", "ZeD", "props")
    os.makedirs(dd, exist_ok=True)
    render().save(os.path.join(dd, "clock_radio.png"))
    print("wrote clock_radio.png to", dd)


if __name__ == "__main__":
    export(sys.argv[1] if len(sys.argv) > 1 else os.path.join(os.path.dirname(os.path.abspath(__file__)), "out", "mod", "ZeD-UI"))
