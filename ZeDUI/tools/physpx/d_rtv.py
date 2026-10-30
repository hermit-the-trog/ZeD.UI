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


def power_lamp(p, cx, cy, on=Z_FACE):
    d = p.d
    d.dome(cx, cy, 2.2, 2.2, 1.0, "jewel_red_off", polish=0.9, on=on)
    p.lamp(disc(d, cx, cy, 2.0), "radioOn", "#ff3a2e")


# =================================================================================== the Premium Technologies Radio
def radio_red(W=180, worn_=True):
    """Premium Technologies Radio (Base.RadioRed): portable, batteries, plays CDs. The face is W - 20 wide, 132 tall:
    the model's front (red shell, cream panel, slotted grille left, dial window right, the big red tuning knob), the CD
    loading from a slot along the top"""
    F, H = W - 20, 132
    p = Plate("radio_red", F, H, seed=301, title="Premium Technologies Radio")
    d = p.d
    shell = Mask(F, H).rrect(0, 0, F, H, 12).get()
    d.slab(shell, Z_FACE, "rr_red", bevel=3.0, polish=0.5)
    d.grain_pebble(shell, 0.035, seed=302)
    # the CD slot along the top and its eject
    sw = F - 50
    slot = Mask(F, H).rrect(12, 6, sw, 8, 3).get()
    d.slab(slot, 0.8, "chrome", bevel=0.8, polish=1.0, on=Z_FACE)
    d.well(Mask(F, H).rrect(15, 8, sw - 6, 4, 2).get(), 3.0, "rubber", bevel=0.6)
    p.part("slotDisc", x=18, y=9, w=sw - 12, color="#c6ccd2")
    p.hit("slot", 12, 6, sw, 8)
    port_key(p, "eject", F - 34, 4, 22, 12, icon="eject", mat="rr_cream")
    # the cream front
    fr = Mask(F, H).rrect(6, 19, F - 12, H - 25, 5).get()
    d.slab(fr, 1.2, "rr_cream", bevel=1.0, polish=0.5, on=Z_FACE)
    zf = Z_FACE + 1.2
    # the slotted grille, left; it takes the width the controls don't need
    gx, gy = 12, 25
    gw = max(34, F - 12 - 98 - 6 - gx)
    gh = 54
    d.well(Mask(F, H).rrect(gx, gy, gw, gh, 3).get(), 1.0, "rr_cream", bevel=0.6)
    for k in range(8):
        d.well(Mask(F, H).rrect(gx + 4, gy + 5 + k * 6, gw - 8, 3, 1).get(), 2.0, "mesh", bevel=0.5)
    # the dial window, right (the readout is live)
    cx0 = gx + gw + 6                    # the controls' column
    cw = F - 12 - cx0
    window_glass(p, cx0 - 1, gy - 1, cw + 2, 26, face="vfd", bezel="blackp", depth=1.6, on=zf, r=1, bezel_t=2, lens=True)
    p.part("radioDisplay", kind="port", style="vfd", x=cx0, y=gy, w=cw, h=24)
    # power (its lamp) and mute over volume down and up; the tuning knob at the right
    ky = gy + 30
    power_lamp(p, cx0 + 3, ky + 5, on=zf)
    port_key(p, "power", cx0 + 8, ky, 22, 11, "PWR")
    port_key(p, "mute", cx0 + 8, ky + 13, 22, 11, "MUTE")
    port_key(p, "voldn", cx0 + 33, ky, 17, 11, icon="down")
    port_key(p, "volup", cx0 + 33, ky + 13, 17, 11, icon="up")
    p.label("VOL", cx0 + 33, ky + 26, "paint_k", auto_ink=False)
    kr = 11
    kcx, kcy = F - 12 - kr - 1, ky + 12
    fluted_knob(p, kcx, kcy, kr, on=zf, z=5.0, mat="rr_knob", skirt=None, ridges=24, dome=1.2)
    p.part("ptr", src="tuneF", cx=kcx, cy=kcy, r0=kr * 0.3, r1=kr * 0.8, a0=-90, a1=270, color="#f4e9e0", w=1)
    p.hit("tune", kcx - kr, kcy - kr, 2 * kr, 2 * kr, kind="turn")
    p.label("TUNE", kcx, kcy + kr + 3, "paint_k", align="c", auto_ink=False)
    # the presets under the grille, play beside them
    py = gy + gh + 5
    pw = (gw - 6) // 4
    for i in range(4):
        port_key(p, f"p{i + 1}", gx + i * (pw + 2), py, pw, 11, str(i + 1))
    p.label("HOLD TO STORE", gx, py + 14, "paint_k", auto_ink=False)
    port_key(p, "play", cx0, py, 30, 11, icon="play")
    # the bottom: the headphone jack, left; the battery door with its level, right
    by = H - 27
    jack(p, gx + 6, by + 7, label=None)
    p.label("PHONES", gx + 14, by + 5, "paint_k", auto_ink=False)
    bw = 56; bx = F - 12 - bw
    door = Mask(F, H).rrect(bx, by, bw, 15, 2).get()
    d.slab(door, 0.6, "rr_cream", bevel=0.8, polish=0.4, on=zf)
    for xx in range(bx + 4, bx + 14, 3): d.well(Mask(F, H).rect(xx, by + 3, 1, 9).get(), 0.6, None, bevel=0.3)
    p.label("BATT", bx + 17, by + 3, "paint_k", auto_ink=False)
    level_bars(p, "batt", bx + 37, by + 4, 4, 3, 1, 7, 0, "#5fe36a")
    p.hit("battery", bx, by, bw, 15)
    if worn_:
        WR.grime(d, d.solid, amount=0.22, seed=303)
        WR.scuffs(d, WR.mat_mask(d, "rr_red"), 0.0012, seed=304, amount=0.10)
    return p


# =================================================================================== the Premium Technologies Television
def tv_wide(W=392, worn_=True):
    """Premium Technologies Television (Base.TvWideScreen): mains power, plays video tapes. The silver set and its tube
    (its tiles), the strip under the tube in two groups: the tape at the left (slot over eject and play); channel,
    volume, phones and power at the right in two rows"""
    sw = W - 36
    sh = int(round(sw * 9 / 16))
    H = 8 + sh + 20 + 44
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
    ink = "paint_k"
    key = lambda pid, x, y, w, lab=None, ic=None: PR.radio_key(p, pid, x, y, w, 12, lab, mat="tv_bezel", lab_mat="paint_w", icon=ic, z=1.4)
    # the VHS deck, left: a cassette-wide mouth with its hinged flap, eject and play under it
    tw = 112
    mouth = Mask(W, H).rrect(16, sy, tw, 13, 2).get()
    d.slab(mouth, 0.6, "tv_bezel", bevel=0.8, polish=0.6, on=Z_FACE)
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
    level_bars(p, "bars", gx - 16, sy + 2, 4, 2, 1, 2, 2, "#2f8f3e")
    key("voldn", gx + lw + 4, sy + 16, 18, ic="down")
    key("volup", gx + lw + 25, sy + 16, 18, ic="up")
    p.label("VOL", gx + lw + 47, sy + 19, ink, auto_ink=False)
    key("mute", gx - 8, sy + 16, 30, "MUTE")
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


def attach(p):
    for pp in p.parts:
        if pp["t"] == "radioDisplay" and pp["kind"] in LAYOUTS:
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
             hasMedia=tape, phonesIn=phones, kind="tvch")
    return s
