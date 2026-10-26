"""The three ham sets narrowed for small screens (mockup v1, Oct 25 2026; director: "Yes, mock up a narrower ham layout
for small screens").

The full sets are 400 wide. Where the tab cannot hold 400 at the plates' whole zoom (a small screen, or a large UI scale
on a 1920 or 2560 screen with the inventory open beside the tab), the same set's face is drawn rearranged into a walkie's
width, 200, in the same 220 panel: a ham then fits wherever a walkie does. Everything on the wide face is kept, with the
same hit ids, so the radio's workings and the controller's stops are unchanged:
  vol, tune (turn) | chup, chdn, mem | mic, mute, scan | p1..p6 (the army set) | the display, the band marker, RANGE
Read top to bottom like the walkies: the maker, the display, the dial and the speaker, the keys, the switches.

Written for ZeDUI/tools/physpx (run from there, or with it on the path).
"""
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
TOOLS = os.path.normpath(os.path.join(HERE, "..", "..", "..", "tools", "physpx"))
if TOOLS not in sys.path: sys.path.insert(0, TOOLS)

from physlib import *            # noqa: F401,F403,E402
import wear as WR                # noqa: E402
import d_props as PR             # noqa: E402
import d_walkie as DW            # noqa: E402

NARROW_W = 200


def ham_civ_n(worn_=True):
    """Premium Technologies Ham Radio, narrow: brushed silver; the PWR lamp by the maker's name, the grey LCD across,
    the big DIAL under its green arc with the round speaker beside it, VOL and the MIC socket under the speaker, the
    three grey keys, the three green switches, the RANGE plate"""
    p = Plate("ham_civilian_n", NARROW_W, 280, seed=331, title="Premium Technologies Ham Radio (narrow)")
    d = p.d
    face = Mask(p.W, p.H).rrect(0, 0, p.W, p.H, 3).get()
    d.slab(face, Z_FACE, "ham_silver", bevel=2.4, polish=0.7)
    d.grain_brushed(face, 0.04, seed=332)
    chrome_frame(d, 3, 3, p.W - 6, p.H - 6, Z_FACE - 0.4, t=1, mat="ham_silver", z=0.7)
    DW.corner_screws(p, inset=9)
    p.label("PREMIUM TECHNOLOGIES", 16, 12, "paint_k", font="57", auto_ink=False)
    p.label("TWO-WAY  -  10-500 MHZ", 16, 23, "paint_k", auto_ink=False)
    d.dome(176, 15, 3.2, 3.2, 1.2, "jewel_red_off", polish=0.9, on=Z_FACE)
    p.lamp(disc(d, 176, 15, 3.0), "radioOn", "#ff3a2e")
    p.label("PWR", 176, 21, "paint_k", align="c", auto_ink=False)
    DW.display(p, "walkie", "lcdgrey", 18, 36, 164, 44, DW.lay_walkie(164), bezel="blackp")
    DW.arc_dial(p, 60, 132, 30, 35)
    PR.radio_knob(p, 60, 132, 22, mat="blackp", skirt=1.4, ridges=40, pid="tune", label="DIAL", label_y=168, lab_mat="paint_k")
    DW.dot_grille(p, 150, 116, 26)
    PR.radio_knob(p, 136, 164, 11, mat="blackp", pid="vol", label="VOL", label_y=179, lab_mat="paint_k")
    DW.mic_jack(p, 172, 164)
    DW.keypad(p, 18, 192, [("chup", "CH", "up"), ("chdn", "CH", "down"), ("mem", "MEM", None)], kw=52, kh=15, gx=4, mat="hamgrey")
    p.label("HOLD MEM TO NAME", 100, 212, "paint_k", align="c", auto_ink=False)
    DW.toggle_key(p, "mic", 18, 224, 52, 13, "MIC")
    DW.toggle_key(p, "mute", 74, 224, 52, 13, "MUTE")
    DW.toggle_key(p, "scan", 130, 224, 52, 13, "SCAN")
    PR.range_strip(p, 100, 260, w=80, mat="blackp", ink="#ecead8")
    if worn_:
        WR.grime(d, face, amount=0.18, seed=333)
        WR.scuffs(d, WR.mat_mask(d, "ham_silver"), 0.001, seed=334, amount=0.08)
    return p


def ham_army_n(worn_=True):
    """US ARMY COMM. Ham Radio, narrow: the olive case round its grey panel; the maker's name and the TX lamp, the red
    LED display, the FREQ dial under its green arc beside the six memory keys and VOL, the three small keys, the green
    switches, the RANGE strip with the MIC socket, the louvred speaker along the foot"""
    p = Plate("ham_army_n", NARROW_W, 300, seed=341, title="US ARMY COMM. Ham Radio (narrow)")
    d = p.d
    case = Mask(p.W, p.H).rrect(0, 0, p.W, p.H, 4).get()
    d.slab(case, Z_FACE + 1.0, "ham_olive", bevel=2.6, polish=0.4)
    d.grain_pebble(case, 0.04, seed=342)
    inset = Mask(p.W, p.H).rrect(10, 10, p.W - 20, p.H - 20, 2).get()
    d.slab(inset, Z_FACE, "ham_inset", bevel=0.8, polish=0.4, on=0.0)
    p.label("US ARMY COMM.", 20, 18, "paint_c", font="57", auto_ink=False)
    d.dome(166, 21, 3.0, 3.0, 1.2, "jewel_red_off", polish=0.9, on=Z_FACE)
    p.lamp(disc(d, 166, 21, 2.8), "micLive", "#ff3a2e")
    p.label("TX", 172, 19, "paint_c", auto_ink=False)
    DW.display(p, "walkie", "led", 22, 36, 156, 44, DW.lay_walkie(156), bezel="blackp", lens=True)
    DW.arc_dial(p, 62, 134, 28, 33, labels=("0.2", "250", "500", "1000"))
    PR.radio_knob(p, 62, 134, 20, mat="blackp", ridges=40, pid="tune", label="FREQ", label_y=168)
    for i in range(6):
        PR.radio_key(p, f"p{i + 1}", 122 + (i % 3) * 18, 98 + (i // 3) * 18, 14, 13, str(i + 1), mat="blackp", z=1.6)
    p.label("MEM", 149, 134, "paint_c", align="c", auto_ink=False)
    PR.radio_knob(p, 134, 158, 10, mat="blackp", pid="vol", label=None)
    p.label("VOL", 150, 156, "paint_c", auto_ink=False)
    for i, (pid, ic) in enumerate((("chup", "up"), ("chdn", "down"), ("mem", None))):
        PR.radio_key(p, pid, 22 + i * 22, 184, 18, 12, None if ic else "M", mat="blackp", icon=ic, z=1.8)
    p.label("HOLD MEM TO NAME", 92, 188, "paint_c", auto_ink=False)
    DW.toggle_key(p, "mic", 22, 206, 48, 13, "MIC", ink="paint_c")
    DW.toggle_key(p, "mute", 76, 206, 48, 13, "MUTE", ink="paint_c")
    DW.toggle_key(p, "scan", 130, 206, 48, 13, "SCAN", ink="paint_c")
    PR.range_strip(p, 82, 244, w=116, mat="blackp", ink="#ecead8")
    DW.mic_jack(p, 164, 241, mat="steel", ink="paint_c")
    for k in range(3):
        d.well(Mask(p.W, p.H).rrect(24, 260 + k * 9, 152, 4, 2).get(), 1.6, "mesh", bevel=0.6)              # the speaker
    for (x, y) in ((5, 5), (p.W - 6, 5), (5, p.H - 6), (p.W - 6, p.H - 6)): screw(p, x, y, on=Z_FACE + 1.0, mat="ham_olive")
    if worn_:
        ol = WR.mat_mask(d, "ham_olive")
        WR.grime(d, d.solid, amount=0.30, seed=343)
        WR.chips(d, WR.face(d, Z_FACE + 1.0, ol), 0.006, seed=344, near=2.0, mat="steel")
        WR.scuffs(d, ol, 0.0015, seed=345, amount=0.12)
    return p


def ham_make_n(worn_=True, mic_live=False):
    """Makeshift Ham Radio, narrow: the crate stood on end; on its board the character display and the red lamp, the
    three tact switches with the TUNE and VOL pots, the TALK / LISTEN toggle, MUTE, the taped HOLD MEM and the MIC
    socket, the big ringed speaker below"""
    p = Plate("ham_makeshift_n", NARROW_W, 290, seed=351, title="Makeshift Ham Radio (narrow)")
    d = p.d
    crate = Mask(p.W, p.H).rect(0, 0, p.W, p.H).get()
    d.slab(crate, Z_FACE + 1.4, "crate", bevel=1.4, polish=0.25)
    d.grain_wood(crate, 1.0, seed=352)
    board = Mask(p.W, p.H).rect(12, 12, p.W - 24, p.H - 24).get()
    d.slab(board, Z_FACE, "crate_face", bevel=0.8, polish=0.3, on=0.0)
    d.grain_wood(board, 0.6, seed=353)
    for (x, y) in ((6, 6), (p.W - 7, 6), (6, p.H - 7), (p.W - 7, p.H - 7)): screw(p, x, y, on=Z_FACE + 1.4, mat="steel")
    DW.display(p, "hamchar", "char", 24, 26, 16 * 8 + 4, 26, DW.lay_char(16), bezel="blackp")
    d.dome(172, 32, 3.0, 3.0, 1.2, "jewel_red_off", polish=0.9, on=Z_FACE)
    p.lamp(disc(d, 172, 32, 2.8), "radioOn", "#ff3a2e")
    for i, (pid, lab) in enumerate((("chdn", "CH-"), ("mem", "MEM"), ("chup", "CH+"))):
        x = 26 + i * 32
        PR.tact(p, pid, x, 66, 12, 12, None)
        d.text(lab, x + 6, 82, "paint_k", align="c", flatlight=True)
    PR.pot(p, "tune", 134, 72, 10)
    PR.pot(p, "vol", 168, 72, 10)
    d.text("TUNE", 134, 88, "paint_k", align="c", flatlight=True)
    d.text("VOL", 168, 88, "paint_k", align="c", flatlight=True)
    bat_toggle(p, 34, 116, mic_live, on=Z_FACE)          # up = TALK: a variant (micLive) flips it
    p.hit("mic", 26, 104, 16, 24)
    d.text("TALK", 48, 108, "paint_k", flatlight=True)
    d.text("LISTEN", 48, 120, "paint_k", flatlight=True)
    DW.toggle_key(p, "mute", 92, 108, 30, 13, "MUTE", mat="blackp")
    DW.mic_jack(p, 166, 114, mat="steel", tip="blackp")
    tp = Mask(p.W, p.H).rect(64, 138, 72, 13).get()
    d.slab(tp, 0.5, "tape", bevel=0.4, polish=0.4, on=Z_FACE)
    d.text("HOLD MEM", 100, 142, "paint_b", align="c", flatlight=True)
    DW.dot_grille(p, 100, 212, 50, ring_mat="grille_ring")
    if worn_:
        WR.grime(d, d.solid, amount=0.26, seed=354)
    return p


# plate id -> (design, display kind, preview reading), as d_walkie.MODELS
MODELS = {
    "ham_civilian_n": (ham_civ_n, "walkie", dict(freq="146.520", name="Sheriff dispatch", ch=2, range_="RANGE 7.5 KM")),
    "ham_army_n": (ham_army_n, "walkie", dict(freq="245.600", name="Base camp", ch=4, mic_live=True, range_="RANGE 20 KM", ac=True)),
    "ham_makeshift_n": (ham_make_n, "hamchar", dict(freq="146.520", name="Farm", ch=1)),
}
WIDE = {"ham_civilian_n": "ham_civilian", "ham_army_n": "ham_army", "ham_makeshift_n": "ham_makeshift"}
