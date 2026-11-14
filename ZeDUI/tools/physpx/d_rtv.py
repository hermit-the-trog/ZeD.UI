"""The ordinary radios, the CD player and the TVs (REQUEST_design_radio_tv_faces_20261030.md). Round 1: the
Premium Technologies Radio (Base.RadioRed, half card) and the Premium Technologies Television (Base.TvWideScreen,
full card), for the director's sign-off before the other five and the other widths (director, Oct 30 2026: "Front,
landscape"; "one of each first").

Each face is drawn from the game's own model: the red radio from its model texture (media/textures/WorldItems/
RadioRed.png: red shell, a cream front with a slotted grille, a dial window, a big red tuning knob, two little lamps)
and the TV from its tiles (appliances_television_01_0..3: a silver set, a dark bezel round the tube, the tape slot and
two keys under the screen).

W is the width from the fit tables: the half card's PANEL width for the radio (the face is W - 20, as the walkies),
the plate's own width for the TV.

Controls (ids as the walkies and car radios use them, so the wiring carries over):
  power   press            the power key (the lamp beside it lights: part lamp src radioOn)
  vol     turn             (TV) not used; volume is volup / voldn and mute
  voldn / volup / mute     press
  tune    turn             the radio's big knob (part ptr src tuneF)
  p1..p4  press            presets: press to go, hold to store
  chup / chdn press        (TV) channel up and down
  slot    press            insert media (CD on the radio, a tape on the TV); part slotDisc / slotTape shows it in
  eject / play  press      eject; play and stop
  phones  press            the headphone jack: plug in / out (part lamp src phonesIn draws the plug's tip)
  battery press            (radio) the battery door: put in / take out (part bars src batt on the door)
Live: radioDisplay (frequency or channel, signal, battery, the CD's time and progress), the power lamp, the media in
its slot, the plug, and on the TV the screen (part tvScreen: picture, static or the station's text, Code's).
"""
import math

from physlib import *            # noqa: F401,F403
import wear as WR
from engine import add_ramp
import d_props as PR

add_ramp("rr_red", "#c4463f")                  # the red radio's shell (its model texture)
add_ramp("rr_cream", "#d8d3c5", light=1.08)    # its front panel
add_ramp("rr_knob", "#c23b35", light=1.05)     # the tuning knob
add_ramp("tv_silver", "#a7a9ae", light=1.1)    # the widescreen set's case (its tiles)
add_ramp("tv_bezel", "#2c2d30")                # the dark surround of the tube

# readout colours (figure, unlit ghost): the Premium radio's blue-green VFD, the TV's little red channel LED
PR.STYLE.setdefault("vfd", ("#62e6ff", "#0d2a33"))
PR.STYLE.setdefault("led", ("#ff3a24", "#2a0806"))


def lay_port(w):
    """the portable radio's window (w x 24): band over preset at the left, the frequency (or the CD's time) big at the
    right, the signal under the band; the station (or the CD's title) marching along the bottom, the battery at its end;
    with a CD playing, a progress line under it all"""
    return [
        {"t": "text", "src": "band", "x": 3, "y": 2, "font": "35"},
        {"t": "text", "src": "preset", "x": 3, "y": 8, "font": "35"},
        {"t": "seg", "src": "big", "x": w - 3, "y": 2, "cw": 6, "ch": 11, "pitch": 8, "st": 1, "n": 5, "ghost": True},
        {"t": "text", "src": "line", "x": 3, "y": 16, "font": "35", "w": w - 6, "marquee": True},
        {"t": "bars", "src": "progress", "x": 3, "y": 22, "n": max(4, (w - 6) // 3), "bw": 2, "gap": 1, "h0": 1, "dh": 0},
    ]


def lay_tvch(w):
    """the TV's channel LED: two digits"""
    return [
        {"t": "seg", "src": "ch", "x": w - 3, "y": 2, "cw": 5, "ch": 8, "pitch": 7, "st": 1, "n": 2, "ghost": True},
    ]


def port_key(p, pid, x, y, w, h, label=None, icon=None, mat="rr_cream", ink="paint_k"):
    PR.radio_key(p, pid, x, y, w, h, label, mat=mat, lab_mat=ink, icon=icon, z=1.6)


def jack(p, cx, cy, label="PHONES", ink="paint_k", on=Z_FACE):
    d = p.d
    d.torus(cx, cy, 2.2, 4.6, 1.8, "chrome", polish=1.0, on=on)
    d.dome(cx, cy, 2.2, 2.2, -1.4, "hole", polish=0.2, on=on)
    p.lamp(disc(d, cx, cy, 2.0), "phonesIn", "#cfd3d6", halo=False)
    p.hit("phones", cx - 6, cy - 6, 12, 12)
    if label: p.label(label, cx, cy + 7, ink, align="c", auto_ink=False)


def level_bars(p, src, x, y, n, bw, gap, h0, dh, color, base="ledoff"):
    """n little bars set in wells, lit live from the left (the microwave's power bars' part)"""
    d = p.d; bars = []
    hmax = h0 + dh * (n - 1)
    for i in range(n):
        h = h0 + dh * i
        m = rbox(d, x + i * (bw + gap), y + hmax - h, bw, h)
        d.well(m, 0.5, base, bevel=0.3)
        bars.append(runs_of(m))
    p.part("bars", src=src, max=n, bars=bars, color=color)


# the signal light (director, Oct 30 2026: "(none), red (bad), yellow, green (good)", "radio light"): one jewel lamp
# that shows the reception by its colour; dark when there is nothing (or the set is off). Code lights one of the three
# from the signal level: 0 none, 1 sigBad, 2 sigFair, 3 and up sigGood (signal_lamp_state below).
SIGNAL_COLORS = (("sigBad", "#ff3a2e"), ("sigFair", "#ffd23a"), ("sigGood", "#5dff7a"))


def signal_lamp(p, cx, cy, r=2.2, on=Z_FACE):
    d = p.d
    d.dome(cx, cy, r + 0.2, r + 0.2, 1.0, "jewel_off", polish=0.9, on=on)
    for src, col in SIGNAL_COLORS:
        p.lamp(disc(d, cx, cy, r), src, col)


def signal_lamp_state(level, live=True):
    """the three lamp keys for a signal level (0..4)"""
    lv = int(level) if live else 0
    return {"sigBad": lv == 1, "sigFair": lv == 2, "sigGood": lv >= 3}


def power_lamp(p, cx, cy, on=Z_FACE):
    d = p.d
    d.dome(cx, cy, 2.2, 2.2, 1.0, "jewel_red_off", polish=0.9, on=on)
    p.lamp(disc(d, cx, cy, 2.0), "radioOn", "#ff3a2e")


# =================================================================================== the Premium Technologies Radio
def tv_strip(p, W, sy, keymat="tv_bezel", ink="paint_k", vhs=True):
    """the strip under a TV's tube: the VHS deck and its counter at the left (vhs); channel (its LED and signal), volume,
    mute, power (lamp: green on, red no power) and the headphone jack at the right"""
    d = p.d; H = p.H
    key = lambda pid, x, y, w, lab=None, ic=None: PR.radio_key(p, pid, x, y, w, 12, lab, mat=keymat, lab_mat="paint_w", icon=ic, z=1.4)
    if W < 300:
        return tv_strip_n(p, W, sy, key, keymat, ink, vhs)
    if vhs:
        # the VHS deck, left: a cassette-wide mouth with its hinged flap, eject and play under it
        gx_ = W - 16 - 40 - 12 - 82                  # where the channel group starts (its signal light 12 px left of it)
        tw = max(72, min(112, gx_ - 16 - 6 - 52 - 22))
        mouth = Mask(W, H).rrect(16, sy, tw, 13, 2).get()
        d.slab(mouth, 0.6, keymat, bevel=0.8, polish=0.6, on=Z_FACE)
        flap = Mask(W, H).rect(20, sy + 3, tw - 8, 7).get()
        d.well(flap, 1.2, "tv_bezel", bevel=0.5)                                 # the flap, pushed in a little
        d.seam(Mask(W, H).rect(20, sy + 3, tw - 8, 1).get(), 0.5)               # its hinge line
        p.part("slotTape", x=22, y=sy + 9, w=tw - 12, color="#3a3a3a")          # a cassette in: its spine shows under the flap
        p.hit("slot", 16, sy, tw, 13)
        # the tape counter beside the mouth (blank with no tape in): part radioDisplay kind vhs, fields counter, playing
        cw_ = 52
        window_glass(p, 16 + tw + 6 - 1, sy - 1, cw_ + 2, 15, face="vfd", bezel="tv_bezel", depth=1.2, on=Z_FACE, r=1, bezel_t=1, lens=True)
        p.part("radioDisplay", kind="vhs", style="vfd", x=16 + tw + 6, y=sy, w=cw_, h=13)
        key("eject", 16, sy + 17, 26, ic="eject")
        key("play", 46, sy + 17, 34, ic="play")
        p.label("VHS", 86, sy + 20, ink, auto_ink=False)
    # power and its lamp at the far right (green: on; red: no power), phones under it
    rx = W - 16
    key("power", rx - 40, sy, 40, "POWER")
    d.dome(rx - 47, sy + 6, 2.2, 2.2, 1.0, "jewel_red_off", polish=0.9, on=Z_FACE)
    p.lamp(disc(d, rx - 47, sy + 6, 2.0), "radioOn", "#5dff7a")
    p.lamp(disc(d, rx - 47, sy + 6, 2.0), "noPower", "#ff3a2e")
    jack(p, rx - 6, sy + 22, label=None)
    p.label("PHONES", rx - 14, sy + 20, ink, align="r", auto_ink=False)
    # channel (its LED, its signal) over volume
    gx = rx - 40 - 12 - 82
    lw = 22
    window_glass(p, gx - 1, sy - 1, lw + 2, 14, face="lens", bezel="tv_bezel", depth=1.2, on=Z_FACE, r=1, bezel_t=1, lens=True)
    p.part("radioDisplay", kind="tvch", style="led", x=gx, y=sy, w=lw, h=12)
    key("chdn", gx + lw + 4, sy, 18, ic="down")
    key("chup", gx + lw + 25, sy, 18, ic="up")
    p.label("CH", gx + lw + 47, sy + 3, ink, auto_ink=False)
    signal_lamp(p, gx - 9, sy + 6)
    key("voldn", gx + lw + 4, sy + 16, 18, ic="down")
    key("volup", gx + lw + 25, sy + 16, 18, ic="up")
    p.label("VOL", gx + lw + 47, sy + 19, ink, auto_ink=False)
    key("mute", gx - 8, sy + 16, 30, "MUTE")


STRIP_H = 44              # the strip's height under the bezel; the narrow strip is one row taller
STRIP_H_N = 60


def tv_strip_n(p, W, sy, key, keymat, ink, vhs):
    """the narrow faces' strip (200 px): the same controls in three rows. The tape and its counter; eject, play, mute
    and power; the signal light and channel, volume and the headphone jack"""
    d = p.d; H = p.H
    if vhs:
        tw = W - 32 - 6 - 52
        d.slab(Mask(W, H).rrect(16, sy, tw, 13, 2).get(), 0.6, keymat, bevel=0.8, polish=0.6, on=Z_FACE)
        d.well(Mask(W, H).rect(20, sy + 3, tw - 8, 7).get(), 1.2, "tv_bezel", bevel=0.5)
        d.seam(Mask(W, H).rect(20, sy + 3, tw - 8, 1).get(), 0.5)
        p.part("slotTape", x=22, y=sy + 9, w=tw - 12, color="#3a3a3a")
        p.hit("slot", 16, sy, tw, 13)
        window_glass(p, 16 + tw + 6 - 1, sy - 1, 52 + 2, 15, face="vfd", bezel="tv_bezel", depth=1.2, on=Z_FACE, r=1, bezel_t=1, lens=True)
        p.part("radioDisplay", kind="vhs", style="vfd", x=16 + tw + 6, y=sy, w=52, h=13)
        key("eject", 16, sy + 17, 26, ic="eject")
        key("play", 46, sy + 17, 34, ic="play")
        p.label("VHS", 84, sy + 20, ink, auto_ink=False)
    y2 = sy + 17
    rx = W - 16
    key("power", rx - 40, y2, 40, "POWER")
    d.dome(rx - 47, y2 + 6, 2.2, 2.2, 1.0, "jewel_red_off", polish=0.9, on=Z_FACE)
    p.lamp(disc(d, rx - 47, y2 + 6, 2.0), "radioOn", "#5dff7a")
    p.lamp(disc(d, rx - 47, y2 + 6, 2.0), "noPower", "#ff3a2e")
    key("mute", rx - 40 - 12 - 32, y2, 30, "MUTE")
    y3 = sy + 34
    signal_lamp(p, 21, y3 + 6)
    lw = 22; gx = 28
    window_glass(p, gx - 1, y3 - 1, lw + 2, 14, face="lens", bezel="tv_bezel", depth=1.2, on=Z_FACE, r=1, bezel_t=1, lens=True)
    p.part("radioDisplay", kind="tvch", style="led", x=gx, y=y3, w=lw, h=12)
    key("chdn", gx + lw + 4, y3, 18, ic="down")
    key("chup", gx + lw + 25, y3, 18, ic="up")
    p.label("CH", gx + lw + 47, y3 + 3, ink, auto_ink=False)
    vx = gx + lw + 60
    key("voldn", vx, y3, 18, ic="down")
    key("volup", vx + 21, y3, 18, ic="up")
    p.label("VOL", vx + 43, y3 + 3, ink, auto_ink=False)
    jack(p, rx - 5, y3 + 6, label=None)


# =================================================================================== the Premium Technologies Television
def tv_wide(W=392, worn_=True):
    """Premium Technologies Television (Base.TvWideScreen): mains power, plays video tapes. The silver set and its tube
    (its tiles), the strip under the tube in two groups: the tape at the left (slot over eject and play); channel,
    volume, phones and power at the right in two rows"""
    sw = W - 36
    sh = int(round(sw * 9 / 16))
    H = 8 + sh + 20 + (STRIP_H if W >= 300 else STRIP_H_N)
    p = Plate("tv_wide", W, H, seed=311, title="Premium Technologies Television")
    d = p.d
    case = Mask(W, H).rrect(0, 0, W, H, 5).get()
    d.slab(case, Z_FACE, "tv_silver", bevel=2.6, polish=0.6)
    d.grain_brushed(case, 0.025, seed=312)
    # the dark bezel round the tube; the name on it under the glass
    bz = Mask(W, H).rrect(10, 8, W - 20, sh + 20, 4).get()
    d.slab(bz, 0.8, "tv_bezel", bevel=1.2, polish=0.5, on=Z_FACE)
    zb = Z_FACE + 0.8
    glass_panel(p, 18, 14, sw, sh, on=zb, r=6, mat="blackglass")
    p.part("tvScreen", x=18, y=14, w=sw, h=sh, r=6)
    p.label("PREMIUM TECHNOLOGIES", W // 2, 14 + sh + 4, "paint_w", align="c", auto_ink=False)
    sy = 8 + sh + 20 + 6                     # the strip's first row
    tv_strip(p, W, sy, keymat="tv_bezel", ink="paint_k", vhs=True)
    if worn_:
        WR.grime(d, d.solid, amount=0.16, seed=313)
        WR.scuffs(d, WR.mat_mask(d, "tv_silver"), 0.0008, seed=314, amount=0.08)
    return p


def lay_vhs(w):
    """the VCR's tape counter (w x 11): the play mark while the tape runs, the counter (h:mm:ss) at the right"""
    return [
        {"t": "tri", "when": "playing", "x": 3, "y": 2, "size": 6},
        {"t": "text", "src": "counter", "x": w - 3, "y": 2, "font": "57", "align": "r"},
    ]


LAYOUTS = {"port": lay_port, "tvch": lay_tvch, "vhs": lay_vhs}



# =================================================================================== round 2: the other five
add_ramp("vt_black", "#2a2b2e")                # the ValuTech radio's shell (its model texture, black)
add_ramp("vt_silver", "#c9cac6", light=1.08)   # its front
add_ramp("dial_glass", "#e9e2c8", light=1.05)  # the tuning scale's card behind its glass
add_ramp("cd_grey", "#3d4456", light=1.05)     # the CD player's shell: the photo's blue-grey metallic, darkened to the icon
add_ramp("cd_lid", "#4b5368", light=1.08)
add_ramp("tvb_case", "#3b3d41")                # the ValuTech set's case (its tiles)
add_ramp("walnut", "#7a4a26", light=1.05)      # the antique set's cabinet
add_ramp("tv_mask", "#9a9890", light=1.05)     # the brushed mask round its tube
add_ramp("brass", "#b8913f", light=1.15)
add_ramp("crate", "#c4a473", light=1.08)
PR.STYLE.setdefault("amber", ("#ffb22e", "#2a1a06"))
PR.STYLE.setdefault("char", ("#1f2a0c", "#8b9e4c"))


# ----------------------------------------------------------------------------------- round 4 (the director, Nov 12 2026)
# "I want to make the black radio look much more like the model ... choose characteristics that represent each. Same
# with the red. This one is more of like a roundish boombox ... one side would be the speaker. The other side would be
# the dial and buttons and screen. The CD tray ... can be a full-width drawer. Same with the black radio."
# Each radio has two looks in the game, the item's model and the tile's sprite; each face takes from both.
add_ramp("vt_grey", "#85888a", light=1.06)     # the black radio's front (its model: a grey face in a black case)
ANT_H = 14                                     # the aerial stands this far above the case


def aerial(p, x, top, base_y):
    """a telescopic aerial, up: two chrome sections and its tip (both models have one)"""
    d = p.d
    d.slab(Mask(d.W, d.H).rect(x - 1, base_y - 7, 4, 9).get(), 1.4, "chrome", bevel=1.0, polish=1.0)
    d.slab(Mask(d.W, d.H).rect(x, top + 3, 2, base_y - 7 - top - 3).get(), 1.0, "chrome", bevel=0.6, polish=1.0)
    d.dome(x + 1, top + 2.5, 2.2, 2.2, 1.6, "chrome", polish=1.0)


def louvres(p, x, y, w, h, on, mat, pitch=7, bar=4):
    """a slatted speaker opening (the models' grille): a dark well, thick slats of the face's colour across it"""
    d = p.d
    d.well(Mask(d.W, d.H).rrect(x, y, w, h, 2).get(), 2.2, "mesh", bevel=0.6)
    n = (h - 3) // pitch
    y0 = y + (h - (n * pitch - (pitch - bar))) // 2
    for k in range(n):
        d.slab(Mask(d.W, d.H).rect(x + 2, y0 + k * pitch, w - 4, bar).get(), 1.6, mat, bevel=1.0, polish=0.5, on=on - 2.2)


def round_speaker(p, cx, cy, r, on, ring_mat="chrome", cap_mat="rr_red"):
    """a round speaker behind a slotted grille in a bright ring (the red radio's sprite), a cap at its middle"""
    d = p.d
    d.torus(cx, cy, r - 3, r, 1.6, ring_mat, polish=1.0, on=on)
    inner = disc(d, cx, cy, r - 3)
    d.well(inner, 1.4, "mesh", bevel=0.8)
    for yy in range(int(cy - r) + 5, int(cy + r) - 3, 4):
        m = disc(d, cx, cy, r - 5) & rbox(d, int(cx - r), yy, 2 * r, 2)
        d.slab(m, 1.2, "rr_cream", bevel=0.5, polish=0.5, on=on - 1.4)
    d.dome(cx, cy, max(3, r * 0.22), max(3, r * 0.22), 1.6, cap_mat, polish=0.8, on=on)


FULL_F = 320          # from this panel width a radio is on the full card and draws its full-card layout


def full_scale(F):
    """the two widest full cards get a bigger radio, not a longer one (the director, Nov 13 2026: "Column 3 and column
    4 need to be taller. So just bigger radios in general. They're just too wide right now. They're not believable.")"""
    k = F / 336.0
    return k if k > 1.25 else 1.0


def d_speaker(p, x, y, w, h, on, ring_mat="chrome", cap_mat="rr_red"):
    """a D-shaped speaker (the red radio's sprite): flat toward the controls, round toward the end of the body; the
    slotted grille in a bright rim, a cap at the round end's middle"""
    d = p.d
    R_ = min(h / 2, w - 8)                         # a narrow one is a D with flatter shoulders
    cx, cy = x + w - R_, y + h / 2
    def dm(i):
        return (rbox(d, x + i, int(y + i), int(w - R_ - i), int(h - 2 * i))
                | Mask(d.W, d.H).rrect(x + i, y + i, w - 2 * i, h - 2 * i, max(1, R_ - i)).get())
    d.slab(dm(0), 1.6, ring_mat, bevel=1.4, polish=1.0, on=on)
    d.well(dm(3), 1.6 + 1.4, "mesh", bevel=0.8)
    inner = dm(5)
    for yy in range(int(y) + 6, int(y + h) - 5, 4):
        d.slab(inner & rbox(d, int(x), yy, int(w), 2), 1.2, "rr_cream", bevel=0.5, polish=0.5, on=on - 1.4)
    cr = max(4, h * 0.11)
    d.dome(max(cx - R_ * 0.15, x + cr + 6), cy, cr, cr, 1.6, cap_mat, polish=0.8, on=on)


def chrome_btn(p, pid, cx, cy, r, on, cap=None, icon=None, ink="paint_k"):
    """a round chrome push button (the red radio, the director, Nov 13 2026: "a retro radio inspired by like a 50s
    radio. So let's make all the buttons round metal or chrome buttons"); what it does is printed on the face under it
    (a word, a number or a symbol), the arrows engraved on the button itself"""
    d = p.d
    d.torus(cx, cy, r - 0.5, r + 1.0, 0.8, "steel", polish=0.7, on=on)          # its collar
    d.dome(cx, cy, r, r, 2.2, "chrome", polish=1.0, on=on)
    ty = int(cy + r + 3)
    if icon == "up": arrow_icon(p, cx, cy, True, ink)
    elif icon == "down": arrow_icon(p, cx, cy, False, ink)
    elif icon == "eject":
        arrow_icon(p, cx, ty + 1, True, ink, w=7, h=4)
        d.paint(rbox(d, int(cx - 3), ty + 5, 7, 1), ink, flatlight=True)
    elif icon == "play":
        tri = Mask(d.W, d.H).poly([(cx - 6, ty), (cx - 6, ty + 5), (cx - 2, ty + 2.5)]).get(0.45)
        d.paint(tri, ink, flatlight=True)
        d.paint(rbox(d, int(cx - 1), ty, 1, 5), ink, flatlight=True)
        d.paint(rbox(d, int(cx + 1), ty, 5, 5), ink, flatlight=True)
    if cap: p.label(cap, int(cx), ty, ink, align="c", auto_ink=False)
    p.hit(pid, int(cx - r - 2), int(cy - r - 2), 2 * r + 4, 2 * r + 11)


def radio_red_full(W, worn_=True):
    """the red radio on the full card (the director, Nov 13 2026: "full card width, not the half card, for the stereo
    faces"): the same set, the same parts and ids. The controls are on the left (a third and a bit); the
    speaker is the sprite's D, flat toward them and round toward the end of the body, the CD drawer the width of the top."""
    F, T = W, ANT_H                                # the full card's faces are keyed by their own width, as the TVs are
    k = full_scale(F)
    BH = int(round(170 * k)); H = T + BH
    p = Plate("radio_red", F, H, seed=301, title="Premium Technologies Radio")
    d = p.d
    R_ = 34
    shell = Mask(F, H).rrect(0, T, F, BH, R_).get()
    aerial(p, 34, 0, T + 4)
    d.slab(shell, Z_FACE, "rr_red", bevel=3.4, polish=0.55)
    d.grain_pebble(shell, 0.035, seed=302)
    K = lambda v: int(round(v * k))
    sx0 = 26; sw = F - 2 * sx0
    sy, sh = T + K(6), K(9)
    slot = Mask(F, H).rrect(sx0, sy, sw, sh, 3).get()
    d.slab(slot, 0.8, "chrome", bevel=0.8, polish=1.0, on=Z_FACE)
    d.well(Mask(F, H).rrect(sx0 + 3, sy + 2, sw - 6, sh - 4, 2).get(), 3.0, "rubber", bevel=0.6)
    p.part("slotDisc", x=sx0 + 6, y=sy + sh // 2, w=sw - 12, color="#c6ccd2")
    p.hit("slot", sx0, sy, sw, sh)
    fr = Mask(F, H).rrect(6, T + K(19), F - 12, BH - K(19) - 6, R_ - 12).get()
    d.slab(fr, 1.2, "rr_cream", bevel=1.0, polish=0.5, on=Z_FACE)
    zf = Z_FACE + 1.2
    # (the director, Nov 13 2026: "The radios only have a speaker on the left side. So the controls take up a little
    # over a third, and the speaker grill takes up 2/3.")
    # ("I don't like the two round speakers right next to each other ... The controls are on the left, and the
    # speaker is D-shaped." As the tile's sprite.)
    cw = min(int(F * 0.36), int(150 * k))
    gy, gh = T + K(26), K(98)
    cx0 = 18
    gx = cx0 + cw + 10
    gw = F - 16 - gx
    d_speaker(p, gx, gy, gw, gh, zf)
    oy = gy + 2
    window_glass(p, cx0 - 1, oy - 1, cw + 2, 26, face="vfd", bezel="blackp", depth=1.6, on=zf, r=1, bezel_t=2, lens=True)
    p.part("radioDisplay", kind="port", style="vfd", x=cx0, y=oy, w=cw, h=24)
    # round chrome buttons, their names printed under them: power and mute, volume down and up, the knob beside them;
    # along the foot the four presets, eject and play
    # the buttons keep their grouping and grow with the set ("Can you keep the buttons grouped together the same? ...
    # or make them bigger to keep up with the scale?"); what is left over sits evenly above and below the group
    br = K(6)
    step = K(23)
    e = max(0, (gh - 26 - K(74)) // 2) if k > 1 else 0
    kr = min(int(19 * k), (cw - int(58 * k)) // 2)
    kcx, kcy = cx0 + cw - kr - 3, oy + 26 + K(5) + e + kr
    ya = oy + 26 + K(5) + e + br; yb = ya + step; yc = yb + step
    xa, xb = cx0 + int(17 * k), cx0 + int(39 * k)
    power_lamp(p, cx0 + 3, ya, on=zf)
    chrome_btn(p, "power", xa, ya, br, zf, cap="PWR")
    chrome_btn(p, "mute", xb, ya, br, zf, cap="MUTE")
    chrome_btn(p, "voldn", xa, yb, br, zf, icon="down")
    chrome_btn(p, "volup", xb, yb, br, zf, icon="up")
    p.label("VOL", (xa + xb) // 2, yb + br + 3, "paint_k", align="c", auto_ink=False)
    fluted_knob(p, kcx, kcy, kr, on=zf, z=5.0, mat="rr_knob", skirt=2.0, ridges=28, dome=1.2)
    p.part("ptr", src="tuneF", cx=kcx, cy=kcy, r0=kr * 0.3, r1=kr * 0.8, a0=-90, a1=270, color="#f4e9e0", w=1)
    p.hit("tune", kcx - kr, kcy - kr, 2 * kr, 2 * kr, kind="turn")
    p.label("TUNE", kcx, kcy + kr + 4, "paint_k", align="c", auto_ink=False)
    pitch = min(int(22 * k), (cw - 2 * br - 2) // 5)
    for i in range(4):
        chrome_btn(p, f"p{i + 1}", cx0 + br + 1 + i * pitch, yc, br, zf, cap=str(i + 1))
    chrome_btn(p, "eject", cx0 + cw - br - 1 - pitch, yc, br, zf, icon="eject")
    chrome_btn(p, "play", cx0 + cw - br - 1, yc, br, zf, icon="play")
    by = T + BH - K(27)
    bx0 = 26
    jack(p, bx0 + 6, by + 7, label=None)
    p.label("PHONES", bx0 + 14, by + 5, "paint_k", auto_ink=False)
    bw = 56; bx = F - 26 - bw
    # no battery door on the front (the director, Nov 13 2026: the cells go in a plate on the back, "which we're not
    # showing ... just leave the meter there"); the meter is still the click area for the batteries
    p.label("BATT", bx + 17, by + 3, "paint_k", auto_ink=False)
    level_bars(p, "batt", bx + 37, by + 4, 4, 3, 1, 7, 0, "#5fe36a")
    p.hit("battery", bx, by, bw, 15)
    if worn_:
        WR.grime(d, d.solid, amount=0.22, seed=303)
        WR.scuffs(d, WR.mat_mask(d, "rr_red"), 0.0012, seed=304, amount=0.10)
    return p


def radio_black_full(W, worn_=True):
    """the black radio on the full card (the director, Nov 13 2026): the slatted speaker over the left two thirds; the amber
    screen, the two keys, the big knob, the presets and volume on the right; the same parts and ids as the half card's."""
    F, T = W, ANT_H                                # the full card's faces are keyed by their own width, as the TVs are
    k = full_scale(F)
    BH = int(round(170 * k)); H = T + BH
    p = Plate("radio_black", F, H, seed=321, title="ValuTech Radio")
    d = p.d
    shell = Mask(F, H).rrect(0, T, F, BH, 6).get()
    aerial(p, F - 24, 0, T + 4)
    d.slab(shell, Z_FACE, "vt_black", bevel=3.0, polish=0.45)
    d.grain_pebble(shell, 0.04, seed=322)
    K = lambda v: int(round(v * k))
    fr = Mask(F, H).rrect(6, T + 5, F - 12, BH - 5 - K(22), 3).get()
    d.slab(fr, 1.2, "vt_grey", bevel=1.0, polish=0.5, on=Z_FACE)
    d.grain_brushed(fr, 0.03, seed=323)
    zf = Z_FACE + 1.2
    cw = min(int(F * 0.36), int(150 * k))          # the controls: a little over a third (no wider than its keys can fill)
    gx, gy, gh = 12, T + 11, K(108)
    cx0 = F - 12 - cw
    gw = cx0 - 8 - gx
    louvres(p, gx, gy, gw, gh, zf, "vt_grey", pitch=int(9 * k), bar=int(5 * k))
    oy = gy + 2
    window_glass(p, cx0 - 1, oy - 1, cw + 2, 26, face="lens", bezel="blackp", depth=1.6, on=zf, r=1, bezel_t=2, lens=True)
    p.part("radioDisplay", kind="fm", style="amber", x=cx0, y=oy, w=cw, h=24)
    kh = int(11 * k)
    key = lambda pid, x, y, w, lab=None, ic=None: PR.radio_key(p, pid, x, y, w, kh, lab, mat="blackp", lab_mat="paint_w", icon=ic, z=1.6)
    kr = min(int(22 * k), int(cw * 0.19))
    e = max(0, (gh - 33 - 2 * kr - K(12) - kh) // 2) if k > 1 else 0   # the bigger sets: the group sits in the middle of what is left
    kcx, kcy = cx0 + cw - kr - 3, oy + 31 + e + kr
    lb = cw - 2 * kr - 12
    ka = min(int(34 * k), int((lb - 11) * 0.58)); kb = min(int(20 * k), lb - 11 - ka)
    ky = kcy - kh - 1
    power_lamp(p, cx0 + 3, ky + kh // 2, on=zf)
    key("power", cx0 + 8, ky, ka, "PWR")
    key("mute", cx0 + 8, ky + kh + 2, ka, "MUTE")
    key("voldn", cx0 + 11 + ka, ky, kb, ic="down")
    key("volup", cx0 + 11 + ka, ky + kh + 2, kb, ic="up")
    p.label("VOL", cx0 + 11 + ka + kb // 2, ky + 2 * kh + 5, "paint_k", align="c", auto_ink=False)
    fluted_knob(p, kcx, kcy, kr, on=zf, z=5.0, mat="blackp", skirt=None, ridges=28, dome=1.2)
    p.part("ptr", src="tuneF", cx=kcx, cy=kcy, r0=kr * 0.3, r1=kr * 0.8, a0=-90, a1=270, color="#e8e8e8", w=1)
    p.hit("tune", kcx - kr, kcy - kr, 2 * kr, 2 * kr, kind="turn")
    p.label("TUNE", kcx, kcy + kr + 3, "paint_k", align="c", auto_ink=False)
    py = kcy + kr + K(12)
    pw = (cw - 6) // 4
    for i in range(4):
        key(f"p{i + 1}", cx0 + i * (pw + 2), py, pw, str(i + 1))
    by = gy + gh + 6
    jack(p, gx + 6, by + 7, label=None)
    p.label("PHONES", gx + 14, by + 5, "paint_k", auto_ink=False)
    bw = 56; bx = F - 12 - bw
    # no battery door on the front (the director, Nov 13 2026: the cells go in a plate on the back, "which we're not
    # showing ... just leave the meter there"); the meter is still the click area for the batteries
    p.label("BATT", bx + 17, by + 3, "paint_k", auto_ink=False)
    level_bars(p, "batt", bx + 37, by + 4, 4, 3, 1, 7, 0, "#5fe36a")
    p.hit("battery", bx, by, bw, 15)
    if worn_:
        WR.grime(d, d.solid, amount=0.24, seed=324)
        WR.scuffs(d, WR.mat_mask(d, "vt_black"), 0.0012, seed=325, amount=0.10)
    return p


def radio_red(W=180, worn_=True):
    """Premium Technologies Radio (Base.RadioRed): portable, batteries, plays CDs. Round 4 (the director, Nov 12 2026):
    a roundish boombox, "more round than square, but not quite as egg". From the sprite: the round body, the round
    speaker in its bright ring, the cream front. From the model: the red shell, the big red tuning knob, the aerial.
    One side is the speaker (two of them where the panel is wide enough), the other the screen, the keys and the knob.
    The CD drawer runs the width of the top; eject sits with play."""
    if W >= FULL_F: return radio_red_full(W, worn_)
    F, T = W - 20, ANT_H
    BH = 132; H = T + BH
    p = Plate("radio_red", F, H, seed=301, title="Premium Technologies Radio")
    d = p.d
    R_ = 26
    shell = Mask(F, H).rrect(0, T, F, BH, R_).get()
    aerial(p, 26, 0, T + 4)
    d.slab(shell, Z_FACE, "rr_red", bevel=3.4, polish=0.55)
    d.grain_pebble(shell, 0.035, seed=302)
    # the CD drawer: the width of the top
    sx0 = 20; sw = F - 2 * sx0
    slot = Mask(F, H).rrect(sx0, T + 6, sw, 9, 3).get()
    d.slab(slot, 0.8, "chrome", bevel=0.8, polish=1.0, on=Z_FACE)
    d.well(Mask(F, H).rrect(sx0 + 3, T + 8, sw - 6, 5, 2).get(), 3.0, "rubber", bevel=0.6)
    p.part("slotDisc", x=sx0 + 6, y=T + 10, w=sw - 12, color="#c6ccd2")
    p.hit("slot", sx0, T + 6, sw, 9)
    # the cream front, round as the body
    fr = Mask(F, H).rrect(6, T + 19, F - 12, BH - 25, R_ - 12).get()
    d.slab(fr, 1.2, "rr_cream", bevel=1.0, polish=0.5, on=Z_FACE)
    zf = Z_FACE + 1.2
    # (the director, Nov 13 2026: "The controls are on the left, and the speaker is D-shaped"; "half card red radio
    # should shift the controls and the D shape"; "let's make all the buttons round metal or chrome buttons".)
    cw = 76 if F >= 150 else 66
    gy, gh = T + 25, 50
    cx0 = 14
    gx = cx0 + cw + 6
    gw = F - 14 - gx
    d_speaker(p, gx, gy, gw, gh, zf)
    # the screen
    window_glass(p, cx0 - 1, gy - 1, cw + 2, 26, face="vfd", bezel="blackp", depth=1.6, on=zf, r=1, bezel_t=2, lens=True)
    p.part("radioDisplay", kind="port", style="vfd", x=cx0, y=gy, w=cw, h=24)
    # power (its lamp) and mute, the red knob beside them
    br = 5
    ya = gy + 34
    power_lamp(p, cx0 + 3, ya, on=zf)
    chrome_btn(p, "power", cx0 + 15, ya, br, zf, cap="PWR")
    chrome_btn(p, "mute", cx0 + 35, ya, br, zf, cap="MUTE")
    kr = 11 if F >= 150 else 9
    kcx, kcy = cx0 + cw - kr - 3, gy + 28 + kr + 2
    fluted_knob(p, kcx, kcy, kr, on=zf, z=5.0, mat="rr_knob", skirt=2.0, ridges=24, dome=1.2)
    p.part("ptr", src="tuneF", cx=kcx, cy=kcy, r0=kr * 0.3, r1=kr * 0.8, a0=-90, a1=270, color="#f4e9e0", w=1)
    p.hit("tune", kcx - kr, kcy - kr, 2 * kr, 2 * kr, kind="turn")
    # one row along the foot of the front: volume down and up, the four presets, eject and play
    yb = gy + gh + 11
    x0b, x1b = cx0 + br + 1, F - 14 - br - 1
    pitch = (x1b - x0b) / 7
    bx_ = lambda k: int(round(x0b + k * pitch))
    chrome_btn(p, "voldn", bx_(0), yb, br, zf, icon="down")
    chrome_btn(p, "volup", bx_(1), yb, br, zf, icon="up")
    p.label("VOL", (bx_(0) + bx_(1)) // 2, yb + br + 3, "paint_k", align="c", auto_ink=False)
    for i in range(4):
        chrome_btn(p, f"p{i + 1}", bx_(2 + i), yb, br, zf, cap=str(i + 1))
    chrome_btn(p, "eject", bx_(6), yb, br, zf, icon="eject")
    chrome_btn(p, "play", bx_(7), yb, br, zf, icon="play")
    bx0 = cx0
    # the foot: the headphone jack, left; the battery door with its level, right
    by = T + BH - 24
    jack(p, bx0 + 6, by + 7, label=None)
    p.label("PHONES", bx0 + 14, by + 5, "paint_k", auto_ink=False)
    bw = 56; bx = F - 16 - bw
    # no battery door on the front (the director, Nov 13 2026: the cells go in a plate on the back, "which we're not
    # showing ... just leave the meter there"); the meter is still the click area for the batteries
    p.label("BATT", bx + 17, by + 3, "paint_k", auto_ink=False)
    level_bars(p, "batt", bx + 37, by + 4, 4, 3, 1, 7, 0, "#5fe36a")
    p.hit("battery", bx, by, bw, 15)
    if worn_:
        WR.grime(d, d.solid, amount=0.22, seed=303)
        WR.scuffs(d, WR.mat_mask(d, "rr_red"), 0.0012, seed=304, amount=0.10)
    return p


def lay_cd(w):
    """the CD player's window (w x 24): track and the time big; the title marching; the progress line"""
    return [
        {"t": "text", "src": "band", "x": 3, "y": 2, "font": "35"},
        {"t": "text", "src": "preset", "x": 3, "y": 8, "font": "35"},
        {"t": "seg", "src": "big", "x": w - 3, "y": 2, "cw": 6, "ch": 11, "pitch": 8, "st": 1, "n": 5, "ghost": True},
        {"t": "text", "src": "line", "x": 3, "y": 16, "font": "35", "w": w - 6, "marquee": True},
        {"t": "bars", "src": "progress", "x": 3, "y": 22, "n": max(4, (w - 6) // 3), "bw": 2, "gap": 1, "h0": 1, "dh": 0},
    ]


def lay_fm(w):
    """a radio without a CD (w x 24): the red radio's window less the CD's progress line"""
    return [f for f in lay_port(w) if f.get("src") != "progress"]


def lay_char2(cols):
    return [{"t": "cells", "src": "l1", "x": 3, "y": 3, "cols": cols, "pitch": 6, "font": "35"},
            {"t": "cells", "src": "l2", "x": 3, "y": 11, "cols": cols, "pitch": 6, "font": "35", "marquee": True}]


LAYOUTS.update({"cd": lay_cd, "fm": lay_fm})


def dial_scale(p, x, y, w, h, on, needle="#e0251b"):
    """an analog tuning scale behind glass (the black radio's, from the old portables): FM 88-108 printed, the red
    pointer runs along it live (part needle src freqF, pivoted far below so it travels nearly flat)"""
    d = p.d
    window_glass(p, x, y, w, h, face="dial_glass", bezel="blackp", depth=1.4, on=on, r=1, bezel_t=2, lens=True)
    ix, iw = x + 8, w - 16
    for i, lab in enumerate(("88", "92", "96", "100", "104", "108")):
        tx = ix + int(round(i * iw / 5))
        d.paint(rbox(d, tx, y + h - 6, 1, 3), "paint_k", flatlight=True)
        d.text(lab, tx, y + 2, "paint_k", align="c", flatlight=True)
    for i in range(26):
        tx = ix + int(round(i * iw / 25))
        d.paint(rbox(d, tx, y + h - 5, 1, 2), "paint_k", flatlight=True)
    R_ = 600
    half = iw / 2
    import math as _m
    da = _m.degrees(_m.asin(half / R_))
    p.part("needle", src="freqF", cx=ix + iw / 2, cy=y + h - 2 + R_, r0=R_ - h + 4, r1=R_ - 1, a0=-90 - da, a1=-90 + da,
           color=needle, w=1, hub=0)


def radio_black(W=180, worn_=True):
    """ValuTech Radio (Base.RadioBlack): portable, batteries, no CD. Round 4 (the director, Nov 12 2026: "much more
    like the model"). From the model: the black case, the grey face, the big slatted speaker over most of the front,
    the tuning scale with its orange needle, the two small keys, the one big black knob, the aerial. From the sprite:
    the row of keys along the foot. The tuning scale runs the width of the top, as the red radio's CD drawer does."""
    if W >= FULL_F: return radio_black_full(W, worn_)
    F, T = W - 20, ANT_H
    BH = 132; H = T + BH
    p = Plate("radio_black", F, H, seed=321, title="ValuTech Radio")
    d = p.d
    shell = Mask(F, H).rrect(0, T, F, BH, 6).get()
    aerial(p, F - 24, 0, T + 4)
    d.slab(shell, Z_FACE, "vt_black", bevel=3.0, polish=0.45)
    d.grain_pebble(shell, 0.04, seed=322)
    # (the director, Nov 12 2026: "just get rid of the analog dial. Leave the digital screen ... shift the plate up so
    # the black gap is at the bottom.")
    fr = Mask(F, H).rrect(6, T + 5, F - 12, BH - 27, 3).get()
    d.slab(fr, 1.2, "vt_grey", bevel=1.0, polish=0.5, on=Z_FACE)
    d.grain_brushed(fr, 0.03, seed=323)
    zf = Z_FACE + 1.2
    RC = 62                                       # the controls' side: as narrow as the screen allows
    gx, gy, gh = 12, T + 11, 54
    gw = F - 12 - RC - 6 - gx
    louvres(p, gx, gy, gw, gh, zf, "vt_grey")
    cx0 = gx + gw + 6; cw = RC
    window_glass(p, cx0 - 1, gy - 1, cw + 2, 26, face="lens", bezel="blackp", depth=1.6, on=zf, r=1, bezel_t=2, lens=True)
    p.part("radioDisplay", kind="fm", style="amber", x=cx0, y=gy, w=cw, h=24)
    key = lambda pid, x, y, w, lab=None, ic=None: PR.radio_key(p, pid, x, y, w, 11, lab, mat="blackp", lab_mat="paint_w", icon=ic, z=1.6)
    # the model's two small keys (power with its lamp, mute) and its one big knob
    ky = gy + 31
    power_lamp(p, cx0 + 3, ky + 5, on=zf)
    key("power", cx0 + 8, ky, 22, "PWR")
    key("mute", cx0 + 8, ky + 13, 22, "MUTE")
    kr = 13
    kcx, kcy = cx0 + cw - kr - 1, ky + 11
    fluted_knob(p, kcx, kcy, kr, on=zf, z=5.0, mat="blackp", skirt=None, ridges=24, dome=1.2)
    p.part("ptr", src="tuneF", cx=kcx, cy=kcy, r0=kr * 0.3, r1=kr * 0.8, a0=-90, a1=270, color="#e8e8e8", w=1)
    p.hit("tune", kcx - kr, kcy - kr, 2 * kr, 2 * kr, kind="turn")
    # the sprite's row of keys along the foot: the presets under the speaker, volume under the screen
    py = gy + gh + 5
    pw = min(18, (gw - 6) // 4)
    for i in range(4):
        key(f"p{i + 1}", gx + i * (pw + 2), py, pw, str(i + 1))
    key("voldn", cx0, py, 15, ic="down")
    key("volup", cx0 + 17, py, 15, ic="up")
    p.label("VOL", cx0, py + 13, "paint_k", auto_ink=False)
    p.label("TUNE", kcx, py + 3, "paint_k", align="c", auto_ink=False)
    by = T + BH - 43
    jack(p, gx + 6, by + 7, label=None)
    p.label("PHONES", gx + 14, by + 5, "paint_k", auto_ink=False)
    bw = 56; bx = F - 12 - bw
    # no battery door on the front (the director, Nov 13 2026: the cells go in a plate on the back, "which we're not
    # showing ... just leave the meter there"); the meter is still the click area for the batteries
    p.label("BATT", bx + 17, by + 3, "paint_k", auto_ink=False)
    level_bars(p, "batt", bx + 37, by + 4, 4, 3, 1, 7, 0, "#5fe36a")
    p.hit("battery", bx, by, bw, 15)
    if worn_:
        WR.grime(d, d.solid, amount=0.24, seed=324)
        WR.scuffs(d, WR.mat_mask(d, "vt_black"), 0.0012, seed=325, amount=0.10)
    return p


def lay_disc(w):
    """the disc player's little LCD (w x 16): the track and the time, the battery at the right; the title marching"""
    return [
        {"t": "text", "src": "track", "x": 3, "y": 2, "font": "35"},
        {"t": "text", "src": "time", "x": 15, "y": 2, "font": "35"},
        {"t": "bars", "src": "batt", "x": w - 13, "y": 7, "n": 3, "bw": 3, "gap": 1, "h0": 5, "dh": 0},
        {"t": "text", "src": "line", "x": 3, "y": 9, "font": "35", "w": w - 6, "marquee": True},
    ]


LAYOUTS.update({"disc": lay_disc})


def round_key(p, pid, cx, cy, r, icon=None, mat="chrome", ink="paint_k", on=Z_FACE):
    """a small round silver button (the disc player's)"""
    d = p.d
    d.dome(cx, cy, r, r, 1.6, mat, polish=1.0, on=on)
    if icon == "minus": d.paint(rbox(d, int(cx - 2), int(cy), 5, 1), ink, flatlight=True)
    elif icon == "plus":
        d.paint(rbox(d, int(cx - 2), int(cy), 5, 1), ink, flatlight=True); d.paint(rbox(d, int(cx), int(cy - 2), 1, 5), ink, flatlight=True)
    elif icon == "stop": d.paint(rbox(d, int(cx - 1), int(cy - 1), 3, 3), ink, flatlight=True)
    elif icon == "play":
        for i in range(4): d.paint(rbox(d, int(cx - 1 + i), int(cy - 3 + i), 1, 7 - 2 * i), ink, flatlight=True)
    elif icon == "power":                        # the power mark: a broken ring and its stroke
        ring_ = ring(d, cx, cy, 2.2, 3.3) & ~((d.YY < cy - 1) & (abs(d.XX + 0.5 - cx) < 1.6))
        d.paint(ring_, ink, flatlight=True); d.paint(rbox(d, int(cx), int(cy - 4), 1, 4), ink, flatlight=True)
    elif icon == "mute":                         # a small speaker and a cross
        d.paint(rbox(d, int(cx - 4), int(cy - 1), 2, 3), ink, flatlight=True)
        d.paint(rbox(d, int(cx - 2), int(cy - 2), 1, 5), ink, flatlight=True)
        for i in range(3):
            d.paint(rbox(d, int(cx + 1 + i), int(cy - 1 + i), 1, 1), ink, flatlight=True)
            d.paint(rbox(d, int(cx + 3 - i), int(cy - 1 + i), 1, 1), ink, flatlight=True)
    p.hit(pid, cx - r - 1, cy - r - 1, 2 * r + 2, 2 * r + 2)


def cd_player(W=180, worn_=True):
    """CD Player (Base.CDplayer): a portable disc player, batteries, no tuner. Drawn on the players the game's is based
    on (the director's photos, Oct 30 2026: the 1990s and 2000s portables). Round 3 (director: "buttons on the bottom,
    the top and middle are the CD lid. usually minimal buttons on the lid"; the photos): the lid is the whole top of the
    player, about four fifths of the face, its edge the body's own; along the front under it, one row of controls.
    The lid carries nothing but its name and OPEN.
    Controls: the lid (slot: open it to put a disc in or take it out) and OPEN, a ribbed lip on its front edge; along the
    front, VOL - and +, POWER, the LCD, MUTE, play; the
    headphone jack in the right side wall (director: "phones would be on the side"). No battery door (director: "for the
    battery, lose the button, clicking the meter on the screen or right click in the inventory can change the battery"):
    the battery hit is the LCD's meter. No maker's marks."""
    import numpy as np
    F = W - 20
    H = int(round(F * 0.94))
    p = Plate("cd_player", F, H, seed=331, title="CD Player")
    d = p.d
    # the body (the D-223, director's photo, Oct 30 2026): square shoulders at the top and a squircle front
    # (director: "more squircle bottom, give the buttons more room")
    bcx, n_ = F / 2, 4.0
    yb, ys = H - 2, int(H * 0.55)                 # the front's lowest point; where the squircle front starts
    def sq(cy, a, b):                             # the lower half of a squircle centred at (bcx, cy)
        return ((np.abs(d.XX + 0.5 - bcx) / a) ** n_ + (np.abs(d.YY + 0.5 - cy) / b) ** n_ <= 1) & (d.YY >= cy)
    def sq_y(x, cy, a, b):
        t = min(1.0, abs(x - bcx) / a)
        return cy + b * (1 - t ** n_) ** (1 / n_)
    aB, bB = bcx - 2, yb - ys
    body = Mask(F, H).rrect(2, 0, F - 4, ys + 10, 14).get() | sq(ys, aB, bB)
    d.slab(body, Z_FACE, "blackp", bevel=3.0, polish=0.6)
    d.grain_pebble(body, 0.02, seed=332)
    inner = Mask(F, H).rrect(4, 2, F - 8, ys + 8, 12).get() | sq(ys, aB - 2, bB - 2)
    # the lid: the whole top; its front edge a second squircle above the body's, leaving an even band of front for the
    # controls, a little deeper at the middle for the LCD
    band = 24                                     # the band's depth at the middle
    ysL = ys - 8                                  # where the lid's front starts curving at the sides
    aL, bL = aB, (yb - band) - ysL
    lid = inner & ((d.YY < ysL) | sq(ysL, aL, bL))
    d.seam(lid ^ (lid & np.roll(lid, -1, 0) & np.roll(lid, 1, 0) & np.roll(lid, -1, 1) & np.roll(lid, 1, 1)), 0.6)
    d.slab(lid, 1.8, "cd_lid", bevel=2.4, polish=0.75, on=Z_FACE)
    ys_l, xs_l = np.nonzero(lid)
    # the lid's click area stops above the OPEN lip and the keys up the strip's ends (they are clicks of their own)
    lid_bottom = int(min(sq_y(x, ysL, aL, bL) for x in (int(F * 0.14), F - int(F * 0.14)))) - 18
    p.hit("slot", int(xs_l.min()), int(ys_l.min()), int(xs_l.max() - xs_l.min() + 1), lid_bottom - int(ys_l.min()))
    p.label("DISC PLAYER", int(bcx), int(H * 0.30), "paint_c", align="c", auto_ink=False, check=False)
    edge = lambda x: sq_y(x, ysL, aL, bL)         # the lid's front edge at column x
    bottom = lambda x: sq_y(x, ys, aB, bB)        # the body's front edge at column x
    mid = lambda x: int(round((edge(x) + bottom(x)) / 2))
    # OPEN (director: "the open is like a lip, you pull up on"): the lid keeps its outline; at the left of its front
    # the edge is a lip, ribbed for the thumb, its name above the ribs
    tx0, tx1 = int(F * 0.14), int(F * 0.30)
    span = (d.XX >= tx0) & (d.XX < tx1)
    for k in (2, 4, 6):
        d.seam(lid & ~sq(ysL, aL, bL - k) & sq(ysL, aL, bL - k + 1) & span, 0.5)
    tcx = (tx0 + tx1) // 2
    p.label("OPEN", tcx + 2, int(edge(tcx)) - 15, "paint_c", align="c", auto_ink=False, check=False)
    lip = lid & ~sq(ysL, aL, bL - 17) & (d.YY >= ysL) & span
    ys_, xs_ = np.nonzero(lip)
    p.hit("eject", int(xs_.min()), int(ys_.min()), int(xs_.max() - xs_.min() + 1), int(ys_.max() - ys_.min() + 1))
    zs = Z_FACE
    # the LCD at the bottom of the crescent, where it is widest
    lw, lh = int(F * 0.31), 16
    lx = int(bcx - lw / 2)
    ly = int(round(edge(bcx))) + 3
    window_glass(p, lx - 1, ly - 1, lw + 2, lh + 2, face="lcdgrey", bezel="blackp", depth=1.2, on=zs, r=1, bezel_t=1, lens=False)
    p.part("radioDisplay", kind="disc", style="lcd", x=lx, y=ly, w=lw, h=lh)
    p.hit("battery", lx + lw - 14, ly + 5, 13, 9)   # no door: clicking the meter (or the item's right-click) changes it
    # the round keys up the crescent either side: VOL - and +, POWER at the left; MUTE and play at the right
    for pid, ic, x, r in (("voldn", "minus", 0.085, 5), ("volup", "plus", 0.175, 5), ("power", "power", 0.27, 5),
                          ("mute", "mute", 0.73, 5), ("play", "play", 0.835, 6)):
        cx = int(round(F * x))
        round_key(p, pid, cx, mid(cx), r, icon=ic, on=zs)
    # the headphone jack in the right side wall, just under the lid (director: "phones would be on the side")
    jy = mid(F - 10)
    sock = Mask(F, H).rect(F - 8, jy - 5, 6, 11).get() & body
    d.slab(sock, 0.8, "chrome", bevel=0.6, polish=1.0, on=Z_FACE)
    hole = Mask(F, H).rect(F - 5, jy - 2, 3, 5).get()
    d.well(hole, 1.0, "hole", bevel=0.3)
    p.lamp(hole, "phonesIn", "#cfd3d6", halo=False)
    p.hit("phones", F - 9, jy - 6, 9, 13)
    if worn_:
        WR.grime(d, d.solid, amount=0.18, seed=333)
        WR.scuffs(d, WR.mat_mask(d, "cd_lid"), 0.0012, seed=334, amount=0.10)
    return p


def radio_make(W=180, worn_=True):
    """Makeshift Radio (Base.RadioMakeShift): built on a scrap of wood (its tile): a board with a two-line character
    display, a battery pack taped down, a hand-wound coil, pots for knobs, tact switches, a bare speaker"""
    F, H = W - 20, 132
    p = Plate("radio_make", F, H, seed=341, title="Makeshift Radio")
    d = p.d
    base = Mask(F, H).rrect(0, 0, F, H, 2).get()
    d.slab(base, Z_FACE, "crate", bevel=1.6, polish=0.3)
    d.grain_pebble(base, 0.05, seed=342)
    for yy in range(4, H, 7): d.dark[yy, 2:F - 2] += 0.03                      # the wood's grain
    # the board
    bx0, by0, bw0, bh0 = 8, 8, F - 16, 62
    brd = Mask(F, H).rrect(bx0, by0, bw0, bh0, 2).get()
    d.slab(brd, 1.4, "pcb", bevel=0.8, polish=0.5, on=Z_FACE)
    zb = Z_FACE + 1.4
    for (x, y) in ((bx0 + 4, by0 + 4), (bx0 + bw0 - 5, by0 + 4), (bx0 + 4, by0 + bh0 - 5), (bx0 + bw0 - 5, by0 + bh0 - 5)):
        screw(p, x, y, on=zb, mat="steel")
    cols = (bw0 - 20 - 4) // 6
    dw = cols * 6 + 6
    window_glass(p, bx0 + 9, by0 + 6, dw + 2, 20, face="lcdlit", bezel="blackp", depth=1.0, on=zb, r=0, bezel_t=1, lens=False)
    p.part("radioDisplay", kind="makeshift2", style="char", x=bx0 + 10, y=by0 + 7, w=dw, h=18, fields=lay_char2(cols))
    # the tact switches: PWR and the presets
    ty = by0 + 32
    PR.tact(p, "power", bx0 + 10, ty, 12, 12, None)
    d.text("PWR", bx0 + 16, ty + 15, "paint_w", align="c", flatlight=True)
    power_lamp(p, bx0 + 28, ty + 6, on=zb)
    for i in range(4):
        x = bx0 + 40 + i * 18
        PR.tact(p, f"p{i + 1}", x, ty, 12, 12, None)
        d.text(str(i + 1), x + 6, ty + 15, "paint_w", align="c", flatlight=True)
    PR.tact(p, "mute", bx0 + bw0 - 24, ty, 12, 12, None)
    d.text("MUTE", bx0 + bw0 - 18, ty + 15, "paint_w", align="c", flatlight=True)
    # below the board on the wood: the coil, the battery pack, the pots, the speaker, the jack
    yb = by0 + bh0 + 6
    # the battery pack, taped (its tile's red pack): the level is three LEDs on its lead
    pk = Mask(F, H).rrect(8, yb, 38, 22, 2).get()
    d.slab(pk, 3.0, "paint_r", bevel=1.0, polish=0.5, on=Z_FACE)
    for xx in (14, 34): d.slab(Mask(F, H).rect(xx, yb - 1, 6, 24).get(), 0.5, "tape", bevel=0.3, polish=0.3, on="cur")
    p.label("9V", 27, yb + 8, "paint_w", align="c", auto_ink=False, check=False)
    level_bars(p, "batt", 10, yb + 26, 4, 3, 1, 4, 0, "#5fe36a")
    p.hit("battery", 8, yb, 38, 22)
    # the hand-wound coil: copper turns on a card former
    cx_, cw_c = 52, 18
    d.slab(Mask(F, H).rrect(cx_ - 2, yb + 1, cw_c + 4, 22, 1).get(), 0.6, "blackp", bevel=0.4, polish=0.3, on=Z_FACE)
    for k in range(9):
        d.slab(Mask(F, H).rect(cx_, yb + 3 + k * 2, cw_c, 1).get(), 1.6, "copper", bevel=0.4, polish=0.9, on=Z_FACE)
    # the jack under the coil
    jack(p, cx_ + cw_c // 2, yb + 33, label=None)
    d.text("PHONES", cx_ + cw_c // 2, yb + 41, "paint_k", align="c", flatlight=True)
    # tune and volume are pots
    PR.pot(p, "vol", 90, yb + 12, 8)
    d.text("VOL", 90, yb + 25, "paint_k", align="c", flatlight=True)
    PR.pot(p, "tune", 114, yb + 12, 8)
    d.text("TUNE", 114, yb + 25, "paint_k", align="c", flatlight=True)
    # the bare speaker at the right, its cone and its rim
    sx, sy_ = F - 20, yb + 14
    d.torus(sx, sy_, 8, 11, 1.6, "steel", polish=0.7, on=Z_FACE)
    d.dome(sx, sy_, 8, 8, -1.8, "paint_k", polish=0.25, on=Z_FACE)
    d.dome(sx, sy_, 3, 3, 0.8, "steel", polish=0.6, on=Z_FACE - 1.8)
    if worn_:
        WR.grime(d, d.solid, amount=0.26, seed=343)
    return p


def tv_black(W=392, worn_=True):
    """ValuTech Television (Base.TvBlack): mains power, plays video tapes. The dark set of its tiles: a 4:3 tube in a
    dark bezel, the same strip as the Premium set (VHS deck and counter, channel, volume, power, phones)"""
    gw = 26 if W >= 300 else 0                   # a speaker grille each side of the tube (none on the narrow face)
    sw = W - 36 - 2 * (gw + 6) if gw else W - 36
    sh = int(round(sw * 3 / 4))
    H = 8 + sh + 20 + (STRIP_H if W >= 300 else STRIP_H_N)
    p = Plate("tv_black", W, H, seed=351, title="ValuTech Television")
    d = p.d
    case = Mask(W, H).rrect(0, 0, W, H, 4).get()
    d.slab(case, Z_FACE, "tvb_case", bevel=2.4, polish=0.45)
    d.grain_pebble(case, 0.03, seed=352)
    for gx in ((10, W - 10 - gw) if gw else ()):
        d.well(Mask(W, H).rrect(gx, 8, gw, sh + 20, 3).get(), 1.0, "tvb_case", bevel=0.6)
        for xx in range(gx + 4, gx + gw - 3, 4):
            d.well(Mask(W, H).rrect(xx, 14, 2, sh + 8, 1).get(), 2.0, "mesh", bevel=0.4)
    tx0 = 10 + gw + 6 if gw else 10
    bz = Mask(W, H).rrect(tx0, 8, sw + 16, sh + 20, 3).get()
    d.slab(bz, 0.8, "tv_bezel", bevel=1.2, polish=0.5, on=Z_FACE)
    glass_panel(p, tx0 + 8, 14, sw, sh, on=Z_FACE + 0.8, r=10, mat="blackglass")
    p.part("tvScreen", x=tx0 + 8, y=14, w=sw, h=sh, r=10)
    p.label("VALUTECH", W // 2, 14 + sh + 4, "paint_w", align="c", auto_ink=False)
    tv_strip(p, W, 8 + sh + 20 + 6, keymat="blackp", ink="paint_w", vhs=True)
    if worn_:
        WR.grime(d, d.solid, amount=0.20, seed=353)
        WR.scuffs(d, WR.mat_mask(d, "tvb_case"), 0.0010, seed=354, amount=0.10)
    return p


TV_CHANNELS = 12          # the antique set's selector: twelve stops (VHF 2-13 printed), the game's stations by index


def tv_antique(W=392, worn_=True):
    """Antique Television (Base.TvAntique): mains power, no tape. Its tiles' walnut cabinet, the round-cornered tube
    in a brushed mask, the controls in a column at the right: the channel selector (a detented dial, 2-13), the volume
    knob (pull for on), the signal eye, the headphone jack"""
    if W < 300:
        return tv_antique_n(W, worn_)
    cw_ = 92                                     # the control column
    sw = W - 28 - cw_ - 8
    sh = int(round(sw * 3 / 4))
    rail = 20                                    # the console's base rail with its drawer fronts (the console sets)
    H = 14 + sh + 14 + rail
    p = Plate("tv_antique", W, H, seed=361, title="Antique Television")
    d = p.d
    cab = Mask(W, H).rrect(0, 0, W, H, 6).get()
    d.slab(cab, Z_FACE, "walnut", bevel=3.0, polish=0.55)
    d.grain_brushed(cab, 0.06, seed=362)
    for yy in range(3, H, 5): d.dark[yy, 3:W - 3] += 0.025
    # the mask round the tube and the tube
    mk = Mask(W, H).rrect(10, 8, sw + 16, sh + 12, 8).get()
    d.slab(mk, 1.0, "tv_mask", bevel=1.2, polish=0.8, on=Z_FACE)
    d.grain_brushed(mk, 0.04, seed=365)
    glass_panel(p, 18, 14, sw, sh, on=Z_FACE + 1.0, r=16, mat="blackglass")
    p.part("tvScreen", x=18, y=14, w=sw, h=sh, r=16, tint="#a8c0a0")
    # the control column on its brushed plate
    px0 = W - 10 - cw_
    # (the director, Nov 12 2026: "the right side should be a black background where the dials are ... a silver
    # background ... directly behind the dial, and the dial should be black. And the speaker grill at the bottom should
    # be silver. But everything else on that side is black ... surrounded by probably chrome, just like we've done with
    # the car dashboards")
    d.slab(Mask(W, H).rrect(px0 - 2, 6, cw_ + 4, H - 12 - rail, 5).get(), 1.0, "chrome", bevel=1.0, polish=1.0, on=Z_FACE)
    pl = Mask(W, H).rrect(px0, 8, cw_, H - 16 - rail, 4).get()
    d.slab(pl, 1.0, "blackp", bevel=0.8, polish=0.55, on=Z_FACE)
    d.grain_pebble(pl, 0.02, seed=366)
    zp = Z_FACE + 1.0
    ccx = px0 + cw_ // 2
    # the channel selector on its black plate (the VHF dial of the old sets): twelve stops printed round it, the
    # pointer lands on one (ptr angles, src chIdx); turning it is the channel
    cy1, r1 = 44, 17
    pr_ = r1 + 16
    sp_ = Mask(W, H).rrect(px0 + 6, cy1 - pr_ + 4, cw_ - 12, 2 * pr_ - 4, 3).get()
    d.slab(sp_, 0.6, "tv_mask", bevel=0.6, polish=0.8, on=zp)
    d.grain_brushed(sp_, 0.04, seed=367)
    zk = zp + 0.6
    angs = [-225 + i * (270 / (TV_CHANNELS - 1)) for i in range(TV_CHANNELS)]
    for i, a_ in enumerate(angs):
        tx = ccx + math.cos(math.radians(a_)) * (r1 + 9); ty = cy1 + math.sin(math.radians(a_)) * (r1 + 9)
        d.text(str(i + 2), int(round(tx)), int(round(ty)) - 2, "paint_k", align="c", flatlight=True)
    fluted_knob(p, ccx, cy1, r1, on=zk, z=5.0, mat="blackp", skirt=1.4, skirt_mat="chrome", ridges=12, dome=0.8)
    p.part("ptr", src="chIdx", cx=ccx, cy=cy1, r0=r1 * 0.25, r1=r1 * 0.85, angles=angs, color="#efe6cf", w=2)
    p.hit("channel", ccx - r1, cy1 - r1, 2 * r1, 2 * r1, kind="turn")
    p.label("CHANNEL", ccx, cy1 + pr_ + 3, "paint_w", align="c", auto_ink=False)
    # the volume knob: pull for on (power is a press on it; turning it is the volume)
    cy2, r2 = cy1 + pr_ + 26, 12
    fluted_knob(p, ccx, cy2, r2, on=zp, z=5.0, mat="blackp", skirt=1.2, skirt_mat="chrome", ridges=12, dome=0.8)
    p.part("ptr", src="volF", cx=ccx, cy=cy2, r0=r2 * 0.3, r1=r2 * 0.8, a0=-225, a1=45, color="#efe6cf", w=1)
    p.hit("vol", ccx - r2, cy2 - r2, 2 * r2, 2 * r2, kind="turn")
    p.hit("power", ccx - r2, cy2 - r2, 2 * r2, 2 * r2)
    p.label("VOLUME - PULL ON", ccx, cy2 + r2 + 4, "paint_w", align="c", auto_ink=False)
    # the speaker: wood slats down the column
    sy0_ = cy2 + r2 + 14; sy1_ = H - 8 - rail - 26
    if sy1_ - sy0_ > 12:
        d.well(Mask(W, H).rrect(px0 + 8, sy0_, cw_ - 16, sy1_ - sy0_, 2).get(), 1.2, "mesh", bevel=0.6)
        for yy in range(sy0_ + 3, sy1_ - 2, 4):
            d.slab(Mask(W, H).rect(px0 + 10, yy, cw_ - 20, 2).get(), 1.0, "tv_mask", bevel=0.4, polish=0.9, on=zp - 1.2)
    # the small row at the foot: the power lamp, the signal eye, mute, the headphone jack
    fy = H - 8 - rail - 24
    d.dome(px0 + 14, fy + 8, 2.4, 2.4, 1.0, "jewel_red_off", polish=0.9, on=zp)
    p.lamp(disc(d, px0 + 14, fy + 8, 2.2), "radioOn", "#ffb040")
    d.dome(px0 + 30, fy + 8, 7, 7, -1.0, "blackp", polish=0.5, on=zp)
    signal_lamp(p, px0 + 30, fy + 8, r=3.6, on=zp - 1.0)
    PR.radio_key(p, "mute", px0 + 42, fy + 2, 26, 12, "MUTE", mat="blackp", lab_mat="paint_w", z=1.4)
    jack(p, px0 + cw_ - 15, fy + 8, label=None)
    p.label("SIGNAL", px0 + 30, fy + 17, "paint_w", align="c", auto_ink=False)
    p.label("PHONES", px0 + cw_ - 15, fy + 17, "paint_w", align="c", auto_ink=False)
    # the base rail: three drawer fronts, each with its brass pull
    ry = H - 6 - rail + 4
    dwn = 3; dg = 6; dw_ = (W - 20 - (dwn - 1) * dg) // dwn
    for i in range(dwn):
        x = 10 + i * (dw_ + dg)
        d.well(Mask(W, H).rrect(x, ry, dw_, rail - 6, 2).get(), 1.0, "walnut", bevel=0.8)
        d.dome(x + dw_ // 2, ry + (rail - 6) // 2, 2.6, 2.6, 1.6, "brass", polish=0.9, on=Z_FACE - 1.0)
    if worn_:
        WR.grime(d, d.solid, amount=0.22, seed=363)
        WR.scuffs(d, WR.mat_mask(d, "walnut"), 0.0010, seed=364, amount=0.08)
    return p


def tv_antique_n(W=200, worn_=True):
    """the antique set's narrow face (200 px): the tube across the top, the controls in a row on the brushed plate under
    it (the channel selector, the volume knob, the power lamp, the signal eye, mute, the headphone jack), the rail"""
    sw = W - 36
    sh = int(round(sw * 3 / 4))
    rail = 16
    row = 58                                     # the control row's height
    H = 8 + sh + 12 + row + 6 + rail
    p = Plate("tv_antique", W, H, seed=361, title="Antique Television")
    d = p.d
    cab = Mask(W, H).rrect(0, 0, W, H, 6).get()
    d.slab(cab, Z_FACE, "walnut", bevel=3.0, polish=0.55)
    d.grain_brushed(cab, 0.06, seed=362)
    for yy in range(3, H, 5): d.dark[yy, 3:W - 3] += 0.025
    mk = Mask(W, H).rrect(10, 8, sw + 16, sh + 12, 8).get()
    d.slab(mk, 1.0, "tv_mask", bevel=1.2, polish=0.8, on=Z_FACE)
    d.grain_brushed(mk, 0.04, seed=365)
    glass_panel(p, 18, 14, sw, sh, on=Z_FACE + 1.0, r=12, mat="blackglass")
    p.part("tvScreen", x=18, y=14, w=sw, h=sh, r=12, tint="#a8c0a0")
    # the control plate under the tube
    py0 = 8 + sh + 12 + 2
    d.slab(Mask(W, H).rrect(8, py0 - 2, W - 16, row + 4, 5).get(), 1.0, "chrome", bevel=1.0, polish=1.0, on=Z_FACE)
    pl = Mask(W, H).rrect(10, py0, W - 20, row, 4).get()
    d.slab(pl, 1.0, "blackp", bevel=0.8, polish=0.55, on=Z_FACE)
    d.grain_pebble(pl, 0.02, seed=366)
    zp = Z_FACE + 1.0
    # the channel selector at the left on its black plate, its twelve stops printed round it
    r1 = 11
    ccx, cy1 = 10 + 6 + r1 + 13, py0 + row // 2 - 3
    sp_ = Mask(W, H).rrect(ccx - r1 - 13, py0 + 3, 2 * (r1 + 13), row - 6, 3).get()
    d.slab(sp_, 0.6, "tv_mask", bevel=0.6, polish=0.8, on=zp)
    d.grain_brushed(sp_, 0.04, seed=367)
    zk = zp + 0.6
    angs = [-225 + i * (270 / (TV_CHANNELS - 1)) for i in range(TV_CHANNELS)]
    for i, a_ in enumerate(angs):
        tx = ccx + math.cos(math.radians(a_)) * (r1 + 8); ty = cy1 + math.sin(math.radians(a_)) * (r1 + 8)
        d.text(str(i + 2), int(round(tx)), int(round(ty)) - 2, "paint_k", align="c", flatlight=True)
    fluted_knob(p, ccx, cy1, r1, on=zk, z=5.0, mat="blackp", skirt=1.2, skirt_mat="chrome", ridges=12, dome=0.8)
    p.part("ptr", src="chIdx", cx=ccx, cy=cy1, r0=r1 * 0.25, r1=r1 * 0.85, angles=angs, color="#efe6cf", w=2)
    p.hit("channel", ccx - r1, cy1 - r1, 2 * r1, 2 * r1, kind="turn")
    p.label("CHANNEL", ccx, py0 + row - 10, "paint_k", align="c", auto_ink=False)
    # the volume knob (pull for on)
    r2 = 10
    vcx, vcy = ccx + r1 + 13 + 8 + r2 + 4, cy1
    fluted_knob(p, vcx, vcy, r2, on=zp, z=5.0, mat="blackp", skirt=1.2, skirt_mat="chrome", ridges=12, dome=0.8)
    p.part("ptr", src="volF", cx=vcx, cy=vcy, r0=r2 * 0.3, r1=r2 * 0.8, a0=-225, a1=45, color="#efe6cf", w=1)
    p.hit("vol", vcx - r2, vcy - r2, 2 * r2, 2 * r2, kind="turn")
    p.hit("power", vcx - r2, vcy - r2, 2 * r2, 2 * r2)
    p.label("VOLUME", vcx, vcy + r2 + 4, "paint_w", align="c", auto_ink=False)
    p.label("PULL ON", vcx, vcy + r2 + 11, "paint_w", align="c", auto_ink=False)
    # the small things at the right: the power lamp and the signal eye over mute and the jack
    x0 = vcx + r2 + 12 + max(0, (W - 10 - 6 - (vcx + r2 + 12) - 74) // 2)   # the cluster centred in what is left
    fy = py0 + 10
    d.dome(x0 + 4, fy + 6, 2.4, 2.4, 1.0, "jewel_red_off", polish=0.9, on=zp)
    p.lamp(disc(d, x0 + 4, fy + 6, 2.2), "radioOn", "#ffb040")
    d.dome(x0 + 22, fy + 6, 7, 7, -1.0, "blackp", polish=0.5, on=zp)
    signal_lamp(p, x0 + 22, fy + 6, r=3.6, on=zp - 1.0)
    p.label("SIGNAL", x0 + 22, fy + 15, "paint_w", align="c", auto_ink=False)
    fy2 = fy + 24
    PR.radio_key(p, "mute", x0, fy2, 26, 12, "MUTE", mat="blackp", lab_mat="paint_w", z=1.4)
    jack(p, x0 + 36, fy2 + 6, label=None)
    p.label("PHONES", x0 + 44, fy2 + 4, "paint_w", auto_ink=False)
    # the base rail: two drawer fronts with their brass pulls
    ry = H - 4 - rail
    dwn = 2; dg = 6; dw_ = (W - 20 - (dwn - 1) * dg) // dwn
    for i in range(dwn):
        x = 10 + i * (dw_ + dg)
        d.well(Mask(W, H).rrect(x, ry, dw_, rail - 4, 2).get(), 1.0, "walnut", bevel=0.8)
        d.dome(x + dw_ // 2, ry + (rail - 4) // 2, 2.4, 2.4, 1.6, "brass", polish=0.9, on=Z_FACE - 1.0)
    if worn_:
        WR.grime(d, d.solid, amount=0.22, seed=363)
        WR.scuffs(d, WR.mat_mask(d, "walnut"), 0.0010, seed=364, amount=0.08)
    return p


def attach(p):
    for pp in p.parts:
        if pp["t"] == "radioDisplay" and "fields" in pp and "color" not in pp:
            col, ghost = PR.STYLE[pp["style"]]; pp["color"], pp["ghost"] = col, ghost
        elif pp["t"] == "radioDisplay" and pp["kind"] in LAYOUTS:
            col, ghost = PR.STYLE[pp["style"]]
            pp["color"], pp["ghost"], pp["fields"] = col, ghost, LAYOUTS[pp["kind"]](pp["w"])
    return p


def reading_port(on=True, freq="98.4", name="Knox Talk Radio", preset=2, signal=3, batt=3, cd=False, elapsed="3:42",
                 title="Compact disc", progress=0.4, **_):
    if not on: return {}
    n = 40
    return {"band": "CD" if cd else "FM", "preset": "" if cd else (f"P{preset}" if preset else ""), "big": elapsed if cd else freq,
            "bars": 0 if cd else signal, "batt": batt, "line": (title if cd else name).upper(),
            "progress": int(progress * n) if cd else 0}


def state_port(on=True, **kw):
    s = PR.radio_state("port", on=on, freq=kw.get("freq", "98.4"), name=kw.get("name", ""), preset=kw.get("preset", 2),
                       volume=kw.get("volume", 0.6), switch_on=on, has_media=kw.get("cd", False))
    s.update(display=reading_port(on=on, **kw), tuneF=kw.get("tune", 0.3), batt=kw.get("batt", 3), phonesIn=kw.get("phones", False))
    return s


def state_tv(on=True, ch=12, signal=4, tape=False, phones=False, power=True, counter="0:42:17", playing=True):
    live = on and power
    disp = {"ch": f"{ch:02d}"} if live else {}
    if live and tape: disp.update(counter=counter, playing=playing)
    s = dict(radioOn=live, power=live, noPower=not power, display=disp, bars=signal if live else 0,
             hasMedia=tape, phonesIn=phones, kind="tvch", **signal_lamp_state(signal, live))
    return s
