"""The two makeshift sets as hand-wired boards, wired to the circuits in hw/nets.py (the radio: Philips' TDA7000
test circuit with National's LM386 minimum-parts amplifier; the two-way: Talking Electronics' four-transistor
walkie-talkie). On each set the display and its keys sit on a salvaged board bolted on top; its ribbon cable takes
power and ground. Every control keeps its approved place.

The board's holes are 6 px apart from (4, 4): hole (i, j) is pixel (4 + 6i, 4 + 6j).
"""
import os
import sys

from physlib import *            # noqa: F401,F403
import wear as WR
import handwire as H

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "hw"))
import nets as N                 # noqa: E402

OX, OY = 4, 4
BOARDS = {}                      # plate id -> the Board it was last built with (the checker reads it)


def hx_(i): return OX + 6 * i


def receiver(B):
    """the TDA7000 and its parts, right of the display board, above and beside the tuning capacitor. The chip's
    notch is to the right: pins 9 .. 1 run left to right along the bottom (row 7), 10 .. 18 along the top (row 4)."""
    U = H.dip(B, "U1", (66, 7), 18, along=(-1, 0), across=(0, -1), label="TDA7000")
    # the top row: the supply's capacitors stand tall to the bare bus on row 1, the others short to row 2
    H.two_lead(B, "C18", (66, 4), (66, 1), "disc", "220p")
    H.two_lead(B, "C17", (65, 4), (65, 1), "disc", "330p")
    H.two_lead(B, "C15", (63, 4), (63, 1), "disc_b", "100n")
    H.two_lead(B, "C14", (62, 4), (62, 2), "disc", "220p")
    H.two_lead(B, "C13", (61, 4), (61, 2), "disc", "220p", pins=("2", "1"))
    H.two_lead(B, "C12", (60, 4), (60, 1), "disc", "150p")
    H.two_lead(B, "C11", (59, 4), (59, 1), "disc", "3n3")
    H.two_lead(B, "C10", (59, 4), (57, 2), "disc", "330p")
    # the bottom row: pins 1, 3, 4 hang their capacitors down to the supply bus on row 9
    H.two_lead(B, "C1", (66, 7), (66, 9), "film", "150n", body_len=8)
    H.two_lead(B, "C3", (64, 7), (64, 9), "disc_b", "22n")
    H.two_lead(B, "C4", (63, 7), (63, 9), "disc", "10n")
    H.two_lead(B, "C8", (59, 7), (59, 9), "disc", "180p")
    H.two_lead(B, "C7", (58, 7), (56, 7), "disc", "3n3", pins=("2", "1"))
    # the oscillator's tank: a ladder between a supply rail (column 58) and the oscillator rail down from pin 6
    H.two_lead(B, "L1", (58, 11), (61, 11), "coil", "56nH")
    H.two_lead(B, "CP", (58, 13), (61, 13), "disc", "33p")
    H.two_lead(B, "CS", (61, 17), (61, 15), "disc", "100p")
    # the tuning capacitor under TUNE: its frame's tab up to pin 5's supply, its oscillator section's tab left
    H.polyvaricon(B, "CV", 392, 92, 36, {"1": (62, 11), "2": (61, 17)}, [(68, 15)], 15, "tune")
    return U


def receiver_wires(B):
    # first the wires with one way out
    B.wire("blue", (57, 2), (58, 4))                            # C10's far end to pin 10
    B.wire("green", (56, 7), (60, 7), via=[(112, 20), (120, 20)])   # C7's far end round C8 to pin 7
    B.wire("yellow", (61, 7), (61, 11), (61, 13), (61, 15), bare=True)   # pin 6: the oscillator rail
    # the supply: the bus across the tall capacitors' tops; pin 5 down to the bottom bus and the frame's tab
    B.wire("red", (59, 1), (60, 1), (63, 1), (65, 1), (66, 1), bare=True)
    B.wire("red", (62, 7), (62, 9), (63, 9), (64, 9), (66, 9), bare=True)
    B.wire("red", (62, 9), (62, 11), bare=True)
    B.wire("red", (58, 11), (58, 13), bare=True)
    B.wire("red", (59, 9), (62, 9))
    B.wire("red", (59, 9), (58, 11))
    B.wire("red", (66, 1), (66, 9))
    # ground at the top: pin 16 and C14 over the bus
    B.wire("black", (64, 4), (62, 2))
    # the antenna lead off the top edge
    ant = B.edge("ANT", 371, -4, entry=(122, 0))
    B.add_part("ANT", "ant", {"1": ant})
    B.wire("orange", (61, 2), ant)


def amplifier(B, switch_on):
    """the LM386 by the volume control, the power switch and its battery leads"""
    p, d = B.p, B.d
    # the power rocker (its place and click area as approved), soldered by two tabs
    from d_props import pcb_rocker
    bez = Mask(d.W, d.H).rrect(22, 26, 24, 16, 2).get()
    pcb_rocker(p, 22, 26, 24, 16, switch_on)
    H.tabs(B, "SW1", [((28.5, 41.0), (4, 7)), ((40.5, 41.0), (6, 7))], w=2.0)
    B._body("SW1", bez); B.keep_mask(bez, 2)
    B.add_part("SW1", "switch", {"1": (4, 7), "2": (6, 7)})
    # the volume control under VOL, lugs down: ground, wiper, the hot end
    H.pot(B, "VR1", 52, 92, 17, [(10, 18), (8, 18), (6, 18)], 15, "vol")
    # the amplifier: notch to the left, pins 1 .. 4 along row 13, 8 .. 5 back along row 10
    H.dip(B, "U2", (14, 13), 8, along=(1, 0), across=(0, -1), label="LM386")
    H.can(B, "C20", (19, 10), (19, 14), D=13.0)
    H.two_lead(B, "C21", (19, 10), (21, 10), "green", "0.05u", body_len=8)
    H.resistor(B, "R20", (21, 10), (21, 14), "10R")


def strip_parts(B):
    """along the bottom strip under the display board: the receiver's output load, its 1n8, the joining capacitor
    (output row 16, ground row 19, the volume control's feed row 18); 10n across the supply where the ribbon lands"""
    H.two_lead(B, "CC", (27, 16), (27, 18), "disc_b", "220n", pins=("1", "2"))
    H.resistor(B, "RL", (30, 16), (30, 19), "22k")
    H.two_lead(B, "C2", (32, 16), (32, 19), "disc", "1n8", pins=("1", "2"))
    H.two_lead(B, "C5", (53, 17), (53, 19), "disc", "10n", pins=("1", "2"))


def power_and_runs(B):
    """the battery and speaker leads off the plate's edges; output, audio and ground along the bottom strip; the
    supply under the display board"""
    bp = B.edge("BT1+", -4, 46, entry=(0, 14))
    bm = B.edge("BT1-", -4, 112, entry=(0, 36))
    B.add_part("BT1", "batt", {"+": bp, "-": bm})
    sp = B.edge("SPK1", 118, 132, entry=(38, 40))
    sm = B.edge("SPK2", 130, 132, entry=(42, 40))
    B.add_part("SPK", "spk", {"1": sp, "2": sm})
    B.wire("red", (4, 7), bp)                                    # battery + to the switch
    B.wire("black", (6, 18), bm)                                 # battery - to the volume control's ground end
    # the output: pin 5 to C20 + and C21; C20 - to the speaker
    B.wire("orange", (17, 10), (19, 10), bare=True)
    B.wire("white", (19, 14), sp)
    # ground along row 19: the volume control's end, pins 2 and 4, R20 and the speaker, the load, C5
    B.wire("black", (6, 18), (6, 19), via=[(12, 38)])
    B.add_part("J1", "ribbon", {"VP": (52, 17), "GND": (51, 19)})      # the display board's ribbon lands here
    B.wire("black", (6, 19), (15, 19), (17, 19), (21, 19), (30, 19), (32, 19), (51, 19), (53, 19))
    B.wire("black", (15, 13), (15, 19))
    B.wire("black", (17, 13), (17, 19))
    B.wire("black", (21, 14), (21, 19))
    B.wire("black", (21, 19), sm)
    # the receiver's output: pin 2 round the tuning capacitor, under it, up to row 16 and along to the load
    B.wire("white", (65, 7), (32, 16), via=[(130, 20), (138, 20), (138, 40), (120, 40), (120, 32)])
    B.wire("white", (32, 16), (30, 16), (27, 16))
    # the joining capacitor's far side along row 18 to the volume control's hot end
    B.wire("white", (27, 18), (10, 18))
    # the wiper to pin 3 under everything along the bottom edge
    B.wire("green", (8, 18), (16, 13), via=[(16, 40), (32, 40)])
    # the supply: the switch to pin 6; from there under the display board to the ribbon's tap, C5, the ladder rail
    B.wire("red", (6, 7), (16, 8), (16, 10))
    B.wire("red", (16, 8), (52, 17), (53, 17))
    B.wire("red", (53, 17), (58, 13))
    # the receiver's top ground, under the display board to the strip
    B.wire("black", (62, 2), (53, 19))


ADD_Z = Z_FACE + 3.5          # the salvaged display board stands on spacers this far above the perforated board


def tact_on(p, pid, x, y, w, h, label, on):
    """a tact switch on the display board (its click area as approved)"""
    d = p.d
    d.slab(rbox(d, x, y, w, h), 1.4, "steel", bevel=0.6, polish=0.6, on=on)
    d.dome(x + w / 2, y + h / 2, w * 0.32, h * 0.32, 1.6, "blackp", polish=0.6, on=on + 1.4)
    for (lx, ly) in ((x - 1, y + 1), (x + w, y + 1), (x - 1, y + h - 2), (x + w, y + h - 2)):
        d.flat(rbox(d, lx, ly, 1, 1), on + 0.3, "solder", polish=0.9)
    if label: p.label(label, x + w // 2, y + h + 3, "paint_w", align="c", auto_ink=False)
    p.hit(pid, x, y, w, h)


def display_board(p, x0=140, y0=12, x1=332, y1=95):
    """the salvaged display-and-keys board: a green board on four spacers, the character display, six preset keys
    and SEEK in their approved places, a ribbon header and the bits it came with"""
    d = p.d
    body = Mask(d.W, d.H).rrect(x0, y0, x1 - x0, y1 - y0, 2).get()
    d.slab(body, ADD_Z, "pcb", bevel=1.0, polish=0.55)
    d.grain_pebble(body, 0.03, seed=91)
    for (sx, sy) in ((x0 + 5, y0 + 5), (x1 - 6, y0 + 5), (x0 + 5, y1 - 6), (x1 - 6, y1 - 6)):
        d.torus(sx, sy, 2.0, 3.4, 0.8, "solder", polish=0.9, on=ADD_Z)
        screw(p, sx, sy, on=ADD_Z, mat="steel")
    # the character display module: its metal frame, then the glass the readout is drawn on
    frame = Mask(d.W, d.H).rrect(144, 18, 152, 41, 1).get()
    d.slab(frame, 1.0, "steel", bevel=0.8, polish=0.7, on=ADD_Z)
    window_glass(p, 146, 20, 148, 37, face="lcdlit", bezel="blackp", depth=1.6, on=ADD_Z + 1.0, r=1, bezel_t=2, lens=False)
    p.part("radioDisplay", kind="makeshift", style="char", x=148, y=22, w=144, h=34)
    for i in range(6):
        tact_on(p, f"p{i + 1}", 158 + i * 22, 72, 12, 12, str(i + 1), ADD_Z)
    tact_on(p, "seek", 310, 26, 14, 14, "SEEK", ADD_Z)
    # what came with it: a controller chip, its crystal, a few resistors, the ribbon header, the silkscreen
    d.slab(rbox(d, 300, 50, 22, 9), 1.6, "blackp", bevel=0.7, polish=0.55, on=ADD_Z)
    for k in range(4):
        for yy in (48, 59):
            d.flat(rbox(d, 302 + k * 5, yy, 2, 2), ADD_Z + 0.3, "solder", polish=0.9)
    d.cyl(302, 64, 9, 4, 1.6, "chrome", axis="h", polish=1.0, on=ADD_Z)
    for k, bands in enumerate((("band_n", "paint_k", "paint_o"), ("paint_y", "band_v", "paint_r"))):
        bx = 300 + k * 0
        d.cyl(bx, 72 + k * 6, 11, 4, 1.6, "resistor", axis="h", polish=0.5, on=ADD_Z)
        for bi, bm in enumerate(bands):
            d.paint(rbox(d, bx + 2 + bi * 2, 72 + k * 6, 1, 4), bm)
    d.slab(rbox(d, 300, 85, 22, 6), 2.2, "blackp", bevel=0.6, polish=0.5, on=ADD_Z)   # the 2 x 5 header
    for k in range(5):
        for yy in (86, 89):
            d.flat(rbox(d, 302 + k * 4, yy, 1, 1), ADD_Z + 2.4, "solder", polish=0.9)
    p.label("DSP-216  REV C", 150, 62, "paint_w", auto_ink=False)
    p.label("J2", 288, 86, "paint_w", auto_ink=False)
    return body


def radio_board(switch_on=True, worn=True):
    W, Hh = 440, 128
    p = Plate("radio_makeshift", W, Hh, seed=89, title="makeshift radio")
    B = H.Board(p, OX, OY, 73, 21)
    B.paint_board(0, 0, W, Hh)
    receiver(B)
    amplifier(B, switch_on)
    strip_parts(B)
    receiver_wires(B)
    power_and_runs(B)
    B.paint_wires()
    B.paint_joints()
    display_board(p)
    # the ribbon: out of the header, over the board's edge, two of its four wires soldered to the runs
    H.ribbon_paint(B, "J1", (311.0, 89.0), (311.5, 101.0), 4, {"VP": (0, (52, 17)), "GND": (1, (51, 19))})
    # masking-tape labels in marker
    H.tape(p, 24, 15, 22, 8, "PWR")
    H.tape(p, 6, 76, 22, 8, "VOL")
    H.tape(p, 381, 112, 24, 8, "TUNE")
    B.cover_holes()
    if worn:
        WR.grime(p.d, p.d.solid, amount=0.20, seed=91)
    keep_order(p, ["pwr", "p1", "p2", "p3", "p4", "p5", "p6", "seek", "vol", "tune"], ["radioDisplay", "volF", "tuneF"])
    return p, B


def keep_order(p, hit_ids, part_keys):
    """the click areas and live parts in the order the approved plate had them (focus walks the click areas in order)"""
    rank = {k: i for i, k in enumerate(hit_ids)}
    p.hits.sort(key=lambda h: rank.get(h["id"], len(rank)))
    prank = {k: i for i, k in enumerate(part_keys)}
    p.parts.sort(key=lambda q: prank.get(q.get("src") if q["t"] == "ptr" else q["t"], len(prank)))


def makeshift(switch_on=True, worn=True):
    """the plate registry's entry: the makeshift radio, checked as it is built"""
    p, B = radio_board(switch_on, worn)
    BOARDS[p.id] = B
    errs = B.check_paint() + B.check_nets(N.RADIO_NETS, N.RADIO_OPEN)
    for e in errs: p.warn("wiring: " + e)
    return p


if __name__ == "__main__" and (len(sys.argv) < 2 or sys.argv[1] != "tw"):
    p, B = radio_board()
    img = p.d.render(chrome_env="room")
    img.resize((440 * 3, 128 * 3), 0).save(os.path.join(os.path.dirname(__file__), "out", "hw", "radio3.png"))
    img.save(os.path.join(os.path.dirname(__file__), "out", "hw", "radio1.png"))
    print("paint:", B.check_paint())
    print("nets:", B.check_nets(N.RADIO_NETS, N.RADIO_OPEN))
    print("plate warnings:", p.warnings)


# =================================================================================== the makeshift two-way
def tw_rf(B):
    """Q1 and its parts: the receiver while listening, the crystal-locked transmitter while talking, left of DIAL;
    the tuning coil under DIAL. Q1 stands in a column, body to the right, its base reached from the left; the 33p
    stands beside it from the collector run, an insulated jumper taking its foot back to the emitter."""
    # the coil under DIAL: 9 turns (P1 the supply end, P2 the collector end), 2 turns to the antenna (S1, S2)
    H.slug_coil(B, "T1", 444, 92, 16, {"P1": (71, 10), "P2": (68, 15), "S1": (77, 10), "S2": (79, 15)}, 22, "tune")
    H.two_lead(B, "LA", (80, 2), (80, 6), "coil", "loading")
    H.two_lead(B, "C1", (80, 8), (80, 10), "disc", "15p")
    B.bridge((80, 10), (79, 10))
    H.to92(B, "Q1", [(63, 13), (63, 14), (63, 15)], side=-1)
    H.two_lead(B, "C4", (66, 12), (66, 16), "disc", "33p")
    # the emitter: down to the 56R and 82p, their feet joined; the 10n to the ground bus, the 390R across to it
    B.bridge((63, 15), (63, 16)); B.bridge((63, 16), (64, 16))
    H.resistor(B, "R3", (63, 16), (63, 20), "56R")
    H.two_lead(B, "C5", (64, 16), (64, 20), "disc", "82p")
    B.bridge((63, 20), (64, 20))
    H.two_lead(B, "C6", (63, 20), (63, 22), "disc_b", "10n")
    H.resistor(B, "R4", (64, 20), (68, 20), "390R")
    # the base: the 33k down from the supply run, the 39n on below it to the switch, the 15k off to the left
    H.resistor(B, "R1", (62, 10), (62, 14), "33k")
    H.two_lead(B, "C3", (62, 14), (62, 16), "disc_b", "39n")
    B.bridge((62, 14), (63, 14)); B.bridge((62, 14), (61, 14))
    H.resistor(B, "R2", (61, 14), (57, 14), "15k")
    H.two_lead(B, "C2", (60, 10), (60, 12), "disc_b", "10n")
    H.two_lead(B, "X1", (56, 19), (60, 19), "xtal", "27MHz")


def tw_switch(B, live):
    """the talk/listen switch where MIC is: its four poles' lugs, top row A then B, bottom row D then C"""
    holes = {}
    for k, nm in enumerate(("A.T", "A.C", "A.R", "B.T", "B.C", "B.R")): holes[nm] = (40 + k, 11)
    for k, nm in enumerate(("D.T", "D.C", "D.R", "C.T", "C.C", "C.R")): holes[nm] = (40 + k, 15)
    H.latch4(B, "SW1", 241, 73, 36, 18, holes, ("mic", 252, 76, 13, 13), live, cap_w=17)
    for pole in "ABCD":
        B.add_part(f"SW1{pole}", "spdt", {c: holes[f"{pole}.{c}"] for c in ("C", "T", "R")})
        B.support[f"SW1{pole}"] = set()
    # the lugs are the switch's (one body for four sections)
    B.masks["lead"]["SW1A"] = B.masks["lead"].pop("SW1")
    for pole in "BCD": B.masks["lead"][f"SW1{pole}"] = np.zeros_like(B.masks["lead"]["SW1A"])
    B.masks["body"]["SW1A"] = B.masks["body"].pop("SW1")
    for pole in "BCD": B.support["SW1A"] |= {holes[f"{pole}.{c}"] for c in ("C", "T", "R")}
    return holes


def tw_audio(B, switch_on):
    """the preamplifier and the supply: the power rocker, the volume control (lugs to the right, the hot end on top),
    the 220R and 100u, the 5k6 and 4k7 off the 100u's node, the BC547 with its collector run along row 7 and its base
    run along row 10, the 1M and 220p standing between them; a ground bus along row 12 above the volume control"""
    p, d = B.p, B.d
    from d_props import pcb_rocker
    bez = Mask(d.W, d.H).rrect(22, 30, 24, 16, 2).get()
    pcb_rocker(p, 22, 30, 24, 16, switch_on)
    H.tabs(B, "SW2", [((28.5, 45.0), (4, 8)), ((40.5, 45.0), (6, 8))], w=2.0)
    B._body("SW2", bez); B.keep_mask(bez, 2)
    B.add_part("SW2", "switch", {"2": (4, 8), "1": (6, 8)})
    H.pot(B, "VR1", 56, 98, 18, [(13, 14), (13, 16), (13, 18)], 16, "vol")
    # the supply: the 220R hangs from the supply run along row 2; its foot and the 100u's top are the preamp's supply
    H.resistor(B, "R9", (10, 6), (10, 2), "220R")
    B.bridge((10, 6), (10, 7))
    H.can(B, "C13", (10, 7), (10, 11), D=11.0)
    B.bridge((10, 11), (10, 12))
    H.resistor(B, "R5", (14, 6), (10, 6), "4k7")
    H.resistor(B, "R8", (10, 7), (14, 7), "5k6")
    # the preamplifier: legs in a triangle, body to the right; collector bridged up to the collector run, emitter
    # down onto the bus, base reached between its legs by the base run
    H.to92_tri(B, "Q2", (20, 9), (21, 10), (20, 11))
    B.bridge((20, 9), (20, 8)); B.bridge((20, 8), (20, 7))
    B.bridge((20, 11), (20, 12))
    H.two_lead(B, "C11", (17, 7), (17, 10), "disc", "220p")
    H.resistor(B, "R7", (18, 7), (18, 10), "1M")
    H.two_lead(B, "C12", (16, 10), (16, 12), "disc_b", "4n7")
    # by the volume control: the 0.47u off its hot end and the 4n7 from it up onto the bus; the 39n off its wiper and
    # the 3k9 on to the base run's riser
    H.can(B, "C9", (15, 14), (13, 14), D=7.0, sleeve="elec_b")
    B.bridge((15, 14), (16, 14))
    H.two_lead(B, "C7", (16, 14), (16, 12), "disc_b", "4n7")
    H.two_lead(B, "C10", (13, 16), (15, 16), "disc_b", "39n")
    H.resistor(B, "R6", (15, 16), (19, 16), "3k9")


def tw_out(B):
    """the output stage right of the display board, along the top ground bus: the Darlington pair (a BC547, body
    down, driving a BC338, body up; their collectors soldered together), the emitter's 100R and 33u, the speaker
    transformer, the 22n from the collectors"""
    H.to92(B, "Q3", [(60, 3), (59, 3), (58, 3)], side=-1)
    H.to92(B, "Q4", [(61, 3), (62, 3), (63, 3)], side=-1)
    B.bridge((60, 3), (61, 3))
    H.two_lead(B, "C8", (60, 2), (60, 0), "disc_b", "22n", pins=("1", "2"))
    B.bridge((60, 2), (60, 3))
    B.bridge((63, 3), (64, 3))
    H.resistor(B, "R10", (64, 3), (64, 0), "100R")
    B.bridge((64, 3), (65, 3)); B.bridge((65, 3), (66, 3))
    H.can(B, "C15", (66, 3), (66, 0), D=9.0, sleeve="elec_b")
    H.xfmr(B, "T2", 412, 8, 22, 12, {"P1": (70, 4), "P2": (68, 4), "S1": (71, 4), "S2": (69, 0)})
    H.two_lead(B, "C14", (57, 2), (57, 0), "disc_b", "22n")


def tw_display(p, x0=150, y0=12, x1=334, y1=104, notch=(239, 64, 279)):
    """the salvaged display board on the two-way: the character display, CH+ CH- MEM MUTE and the microphone lamp
    in their approved places, a notch cut out of its bottom edge for the talk/listen switch"""
    d = p.d
    nx0, ny0, nx1 = notch
    body = Mask(d.W, d.H).rrect(x0, y0, x1 - x0, y1 - y0, 2).get()
    body &= ~Mask(d.W, d.H).rect(nx0, ny0, nx1 - nx0, y1 - ny0 + 2).get()
    d.slab(body, ADD_Z, "pcb", bevel=1.0, polish=0.55)
    d.grain_pebble(body, 0.03, seed=101)
    for (sx, sy) in ((x0 + 5, y0 + 5), (x1 - 6, y0 + 5), (x0 + 5, y1 - 6), (x1 - 6, y1 - 6)):
        d.torus(sx, sy, 2.0, 3.4, 0.8, "solder", polish=0.9, on=ADD_Z)
        screw(p, sx, sy, on=ADD_Z, mat="steel")
    frame = Mask(d.W, d.H).rrect(154, 18, 172, 43, 1).get()
    d.slab(frame, 1.0, "steel", bevel=0.8, polish=0.7, on=ADD_Z)
    window_glass(p, 156, 20, 168, 39, face="lcdlit", bezel="blackp", depth=1.6, on=ADD_Z + 1.0, r=1, bezel_t=2, lens=False)
    p.part("radioDisplay", kind="hammake", style="char", x=158, y=22, w=164, h=36)
    for pid, lab, x in (("chup", "CH+", 162), ("chdn", "CH-", 192), ("mem", "MEM", 222), ("mute", "MUTE", 282)):
        tact_on(p, pid, x, 76, 13, 13, lab, ADD_Z)
    d.dome(318.5, 81, 3.0, 3.0, 1.2, "jewel_red_off", polish=0.9, on=ADD_Z)
    p.lamp(disc(d, 318.5, 81, 2.8), "micMuted", "#ff3a2e")
    p.label("HAM TX/RX", 160, 64, "paint_w", auto_ink=False)
    for k in range(4):                     # the pads the ribbon's four wires are soldered to, by the right edge
        d.flat(rbox(d, 327, 55 + k * 3, 2, 2), ADD_Z + 0.3, "solder", polish=0.9)
    return body


RIBBON_TW = {"VP": (0, (57, 8)), "GND": (3, (57, 12))}    # the two-way's ribbon: conductor, hole (the runs pass there)


def twoway_board(switch_on=True, mic_live=True, worn=True, wire=True):
    W, Hh = 500, 138
    p = Plate("radio_hammake", W, Hh, seed=101, title="makeshift two-way")
    B = H.Board(p, OX, OY, 83, 23)
    B.paint_board(0, 0, W, Hh)
    tw_rf(B)
    tw_switch(B, mic_live)
    tw_audio(B, switch_on)
    tw_out(B)
    B.add_part("J1", "ribbon", {pin: hole for pin, (_, hole) in RIBBON_TW.items()})   # lands on the supply and ground runs
    if wire:
        tw_wires(B)
    B.paint_wires()
    B.paint_joints()
    tw_display(p)
    # the ribbon: off the display board's right edge over the wires coming out from under it; the first wire (the red
    # stripe) up to the supply run, the last down to the ground run, the middle two cut short
    H.ribbon_paint(B, "J1", (328.5, 61.0), (344.0, 61.0), 4, RIBBON_TW)
    # masking-tape labels in marker; the RANGE line is printed live on the long one
    H.tape(p, 6, 5, 46, 9, "KEEP DRY", angle_px=-1)
    H.tape(p, 24, 19, 22, 8, "PWR")
    H.tape(p, 45, 117, 22, 8, "VOL")
    H.tape(p, 432, 117, 24, 8, "DIAL")
    H.tape(p, 208, 118, 84, 11)
    p.part("rangeText", x=250, y=122, color="#1d2d7a")
    B.cover_holes()
    if worn:
        WR.grime(p.d, p.d.solid, amount=0.24, seed=103)
    keep_order(p, ["pwr", "chup", "chdn", "mem", "mic", "mute", "vol", "tune"], ["radioDisplay", "lamp", "volF", "tuneF", "rangeText"])
    return p, B


def twoway(switch_on=True, mic_live=True, worn=True):
    """the plate registry's entry: the makeshift two-way, checked as it is built (a wire the router could not lay is a
    warning too, so the export refuses it)"""
    p, B = twoway_board(switch_on, mic_live, worn)
    BOARDS[p.id] = B
    errs = B.check_paint() + B.check_nets(N.TWOWAY_NETS, N.TWOWAY_OPEN) + [f"no way for {f}" for f in B.failed]
    for e in errs: p.warn("wiring: " + e)
    return p


def tw_wires(B):
    """every net of the two-way, wired; bare tinned runs for the ground buses and the transistors' nodes, colours by
    what the wire carries. Lattice nodes for vias are (2i, 2j) for hole (i, j)."""
    B.soft = True
    W = B.wire

    def n(i, j): return (2 * i, 2 * j)
    # ---------------------------------------------------------------- the ground buses (bare tinned wire)
    W("tin", (10, 12), (16, 12), (20, 12), (25, 12), (25, 22), bare=True)          # the middle bus, down under the board
    W("tin", (0, 22), (13, 22), (25, 22), (60, 22), (63, 22), (68, 22), (79, 22), bare=True)   # the bottom bus
    W("tin", (57, 0), (60, 0), (64, 0), (66, 0), (69, 0), (79, 0), (79, 10), (79, 15), (79, 22), bare=True)   # top, right
    W("tin", (13, 18), (13, 22), bare=True)                                       # the volume control's earthy lug
    W("tin", (60, 19), (60, 22), bare=True)                                       # the crystal's earthy end
    W("tin", (68, 20), (68, 22), bare=True)                                       # the 390R's
    # ---------------------------------------------------------------- the preamplifier's runs (bare)
    W("tin", (14, 7), (17, 7), (18, 7), (20, 7), bare=True)                       # the collector run, row 7
    W("tin", (16, 10), (17, 10), (18, 10), (19, 10), (21, 10), bare=True)         # the base run, row 10
    # ---------------------------------------------------------------- left: supply, preamp
    bp = B.edge("BT1+", -4, 52, entry=(0, 16))
    bm = B.edge("BT1-", -4, 136, entry=(0, 44))
    B.add_part("BT1", "batt", {"+": bp, "-": bm})
    W("red", (4, 8), bp)                                                          # BATT
    W("black", (0, 22), bm)
    W("red", (6, 8), (10, 2), via=[n(8, 3)])                                      # VPLUS up beside the rocker
    W("blue", (19, 16), (19, 10))                                                 # B2: the 3k9 up to the base run
    # ---------------------------------------------------------------- right: the output stage
    W("orange", (58, 3), (62, 3), via=[n(57, 3), n(57, 6), n(62, 6)])               # E3 round Q3's body
    W("yellow", (61, 3), (68, 4), via=[n(61, 4)])                                 # CN: the collectors to T2
    # ---------------------------------------------------------------- the switch's lugs, top row (up under the
    # display board, then right), right to left so each keeps its column
    W("black", (45, 11), (57, 12), (60, 12), via=[n(45, 9), n(53, 12)])           # B.R to the 10n's foot (ground)
    W("brown", (44, 11), (56, 19), via=[n(44, 8), n(53, 11)])                     # B.C to the crystal
    W("grey", (43, 11), (62, 16), via=[n(43, 7), n(53, 14), n(54, 17), n(62, 17)])   # B.T to B39, in from below
    W("red", (41, 11), (60, 10), (62, 10), (71, 10), via=[n(41, 6), n(53, 10)])    # SUP from A.C
    W("yellow", (40, 11), (68, 4), via=[n(40, 5), n(53, 6), n(68, 6)])            # CN from A.T to T2
    W("violet", (14, 6), (42, 11), via=[n(14, 5), n(24, 5), n(25, 4), n(42, 4)])  # RLINE from the 4k7 to A.R
    # ---------------------------------------------------------------- bottom row: two out each side, two dip below
    W("grey", (45, 15), (62, 16), via=[n(46, 15), n(53, 15), n(55, 16), n(61, 16)])   # C.R to B39, in from the left
    W("black", (44, 15), (57, 14), via=[n(44, 16), n(46, 16), n(53, 13), n(56, 14)])   # C.C to the 15k's foot
    W("violet", (43, 15), (63, 20), via=[n(43, 17), n(46, 17), n(47, 16), n(52, 16), n(52, 21), n(62, 21)])   # C.T to ETAP
    W("white", (71, 4), (42, 15), via=[n(71, 9), n(53, 9), n(37, 16), n(39, 17), n(42, 17)])   # SEC from T2
    # ---------------------------------------------------------------- long runs under the display board
    W("red", (10, 2), (57, 8), via=[n(24, 2), n(53, 8)])                          # VPLUS under the board to the ribbon
    W("red", (57, 8), (70, 4), via=[n(70, 8)])                                    # and on to T2
    W("blue", (20, 7), (57, 2), (59, 3), via=[n(24, 7), n(53, 2)])                # C2N to the 22n and the BC547's base
    W("violet", (14, 6), (16, 14), via=[n(15, 6), n(24, 6), n(25, 7), n(25, 13), n(24, 14), n(17, 14)])  # RLINE on
    W("green", (13, 16), (40, 15), via=[n(14, 18), n(24, 18), n(25, 15), n(39, 15)])   # WIPER
    # ---------------------------------------------------------------- the RF side
    ant = B.edge("ANT", 485, -4, entry=(160, 0))
    B.add_part("ANT", "ant", {"1": ant})
    W("orange", (80, 2), ant)
    W("yellow", (80, 6), (80, 8), (77, 10))                                       # ANT2
    W("white", (63, 13), (66, 12), (68, 15), via=[n(63, 12)])                     # COLL: up, along to the 33p, T1
    W("blue", (66, 16), (64, 16))                                                 # EMIT: the 33p's foot
    W("black", (60, 12), (57, 14), via=[n(60, 13), n(58, 13)])                    # the 10n to the 15k's foot
    W("black", (57, 14), (60, 19), via=[n(57, 18), n(59, 18)])                    # and on to the crystal's
    # the speaker off the top edge above the display board
    sp = B.edge("SPK1", 250, -4, entry=(82, 2))
    sm = B.edge("SPK2", 256, -4, entry=(84, 2))
    B.add_part("SPK", "spk", {"1": sp, "2": sm})
    W("white", (41, 15), sp, via=[n(41, 16), n(39, 16), n(38, 4), n(41, 2)])      # SPKN
    W("black", (25, 12), sm, via=[n(30, 6), n(42, 3)])


if __name__ == "__main__" and len(sys.argv) > 1 and sys.argv[1] == "tw":
    p, B = twoway_board(wire=len(sys.argv) > 2)
    img = p.d.render(chrome_env="room")
    img.resize((500 * 3, 138 * 3), 0).save(os.path.join(os.path.dirname(__file__), "out", "hw", "tw3.png"))
    print("paint:", B.check_paint())
    print("plate warnings:", p.warnings)
