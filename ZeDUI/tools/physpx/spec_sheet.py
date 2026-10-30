"""Spec sheets for sign-off (director, Oct 30 2026: "make spec sheets for each and I can give a final sign off before I
give to code"): one picture per device, everything the director signs and Code builds from:

  1. at play scale   the face at the width 4K on UI scale 1.75 picks, drawn 2x, in its states
  2. anatomy         the same face at 3x: every click area numbered, every live part lettered, with what each does and
                     the state it reads
  3. every width     each face it ships at, with the UI scales it fills
  4. notes           the design decisions behind it, and what Code feeds it

usage: python spec_sheet.py out_dir [pid ...]     (fonts: $ZED_SHEET_FONTS, a folder with ChicagoFLF.ttf and the
FiraSans / FiraMono files; DejaVu stands in without them)"""
import os
import sys

import numpy as np
from PIL import Image, ImageDraw, ImageFont

import rtv_plates as RP
import w_plates as WP
import d_rtv as R
import d_laundry as L
import offair as O
import export_rtv as XR
import preview as PV
from physlib import build
from plates import DESIGNS

FONTS = os.environ.get("ZED_SHEET_FONTS", "")
DJ = "/usr/share/fonts/truetype/dejavu/"


def font(kind, size):
    files = {"head": ("ChicagoFLF.ttf", "DejaVuSans-Bold.ttf"), "body": ("FiraSans-Regular.ttf", "DejaVuSans.ttf"),
             "semi": ("FiraSans-SemiBold.ttf", "DejaVuSans-Bold.ttf"), "mono": ("FiraMono-Regular.ttf", "DejaVuSansMono.ttf")}[kind]
    p = os.path.join(FONTS, files[0])
    return ImageFont.truetype(p if FONTS and os.path.exists(p) else DJ + files[1], size)


BG = (28, 29, 32); PANEL = (36, 37, 41); INK = (232, 230, 222); DIM = (150, 150, 146); RULE = (70, 71, 76)
HIT = (255, 176, 46); PART = (88, 196, 255); OK = (125, 220, 140)
PW, M = 2400, 64

# ------------------------------------------------------------------ what each control and live part is, in plain words
HITS = {
    "power": "Power on / off", "mute": "Mute", "voldn": "Volume down / up", "volup": "Volume down / up",
    "vol": "Volume (turn the knob)", "tune": "Tune (turn the knob)", "p1": "Presets 1 to 4: press to tune, hold to store",
    "p2": "Presets 1 to 4: press to tune, hold to store", "p3": "Presets 1 to 4: press to tune, hold to store",
    "p4": "Presets 1 to 4: press to tune, hold to store", "phones": "Headphones: plug in / pull out",
    "battery": "Batteries: put in / take out", "slot": "The slot: put a disc or tape in", "eject": "Eject",
    "play": "Play / stop", "chdn": "Channel down / up", "chup": "Channel down / up",
    "channel": "Channel selector, twelve stops (turn)", "door": "The door: shows what is inside",
    "mode_wash": "Washer mode / dryer mode", "mode_dry": "Washer mode / dryer mode"}
HIT_PER = {("cd_player", "battery"): "Batteries: click the meter on the screen (or the item's right-click)",
           ("cd_player", "slot"): "The lid: put a disc in / take it out",
           ("cd_player", "eject"): "OPEN: the lip on the lid's edge",
           ("tv_antique", "power"): "Volume knob, pressed: pull on / push off",
           ("radio_handbuilt", "power"): "The power rocker",
           ("washer", "power"): "Power on / off (the game refuses without power or water)",
           ("washer_dryer", "power"): "Power on / off (washer mode refuses without water)",
           ("dryer", "power"): "Power on / off (the game refuses without power)"}


def part_key(q):
    t, src, kind = q["t"], q.get("src"), q.get("kind")
    if t == "lamp" and src in ("sigBad", "sigFair", "sigGood"): return ("signal",)
    if t == "lamp" and src in ("phWash", "phRinse", "phSpin", "phDry", "phCool"): return ("phase",)
    if t == "lamp" and src in ("modeWash", "modeDry"): return ("mode",)
    if t == "lamp" and src in ("radioOn", "noPower", "running"): return ("power",)
    if t == "bars" and src == "water": return ("water",)
    return (t, src or kind)


PARTS = {
    ("power",): ("The power lamp: lit while on", None),
    ("signal",): ("The signal light: red bad, yellow fair, green good, dark for none", "sigBad / sigFair / sigGood"),
    ("lamp", "phonesIn"): ("A plug in the headphone jack", "phonesIn"),
    ("bars", "batt"): ("Battery level", "batt 0..4"),
    ("needle", "freqF"): ("The needle across the tuning dial", "freqF 0..1 (88 to 108)"),
    ("ptr", "tuneF"): ("The tuning knob's mark", "tuneF"),
    ("ptr", "volF"): ("The volume knob's mark", "volF"),
    ("ptr", "chIdx"): ("The channel selector's pointer", "chIdx 0..11"),
    ("radioDisplay", "fm"): ("Display: band, preset, frequency, station", "display {band, preset, big, line, ...}"),
    ("radioDisplay", "port"): ("Display: band, preset, frequency or CD time, station or title, signal, battery",
                               "display {band, preset, big, line, bars, batt, progress}"),
    ("radioDisplay", "makeshift2"): ("Two-line character display", "display {l1, l2}"),
    ("radioDisplay", "disc"): ("Screen: track, time, battery meter, title", "display {track, time, batt, line}"),
    ("radioDisplay", "vhs"): ("Tape counter and play mark", "display {counter, playing}"),
    ("radioDisplay", "tvch"): ("Channel number", "display {ch}"),
    ("slotDisc", None): ("A disc in the slot", "hasMedia"),
    ("slotTape", None): ("A tape in the deck, its spine under the flap", "hasMedia"),
    ("tvScreen", None): ("The screen: the picture, or the off-air screens", "Code draws it (offair.sets)"),
    ("sprite", "switchOn"): ("The rocker, off or on", "switchOn"),
    ("sprite", "hasItems"): ("Clothes behind the glass", "hasItems"),
    ("ptr", "cycleF"): ("The cycle gauge, START to END while a cycle runs", "cycleF 0..1, by the clock"),
    ("phase",): ("Phase lamps, stepped through while running", "phWash phRinse phSpin / phDry phCool"),
    ("lamp", "noWater"): ("FILL: no water", "noWater"),
    ("water",): ("Water: the meter and the water in the drum", "water 0..5 (fluid against capacity)"),
    ("ptr", "drumF"): ("The drum's baffle, turning while running", "drumF 0..1, by the clock"),
    ("mode",): ("The mode lamps over WASH and DRY", "modeWash / modeDry"),
}
PART_PER = {("dryer", ("power",)): ("The power lamp (green running, red no power); HEAT lights while running", None),
            ("washer", ("power",)): ("The power lamp: green running, red no power", None),
            ("washer_dryer", ("power",)): ("The power lamp: green running, red no power", None),
            ("tv_widescreen", ("power",)): ("The power lamp: green on, red no mains power", None),
            ("tv_black", ("power",)): ("The power lamp: green on, red no mains power", None),
            ("tv_antique", ("power",)): ("The pilot lamp: lit while on", None)}

SCALES_HALF = {154: "0.75 and 1.5", 180: "1.75", 206: "1.0 and 2.0", 257: "1.25"}
SCALES_FULL = {200: "the smallest settings (narrow face)", 336: "0.75 and 1.5", 392: "1.75", 450: "1.0, 2.0 and up",
               562: "1.25"}


# ------------------------------------------------------------------ the devices
def tvs(on_screen):
    return on_screen


DEV = {
    "radio_black": dict(
        title="ValuTech Radio", sub="Item Base.RadioBlack.  Half card.  Batteries.", status="Approved in round 2",
        states=[("off", R.state_port(False, batt=3)), ("on: FM, preset 3", RP.st_black(True)),
                ("on, headphones in", {**RP.st_black(True), "phonesIn": True})],
        notes=["The red radio's model in black and silver, the game's texture for it; the old portables' tuning dial "
               "across the top where the red one has its CD slot.",
               "Amber display. A needle on the dial follows the frequency; the knob turns with it.",
               "Wider panels give the speaker grille the room; the 154 panel takes a smaller tuning knob."]),
    "radio_red": dict(
        title="Premium Technologies Radio", sub="Item Base.RadioRed.  Half card.  Batteries.  Plays CDs.",
        status="Approved Oct 30 (\"Yes. Radio is approved\")",
        states=[("off", R.state_port(False, batt=3)), ("on: FM", R.state_port(True, freq="98.4", name="Knox Talk Radio", preset=2, batt=3)),
                ("on: a CD playing, headphones in", R.state_port(True, cd=True, elapsed="3:42", title="Kentucky Rain", progress=0.45,
                                                                 batt=2, phones=True))],
        notes=["The red shell and cream front of the game's model. The CD slot and eject across the top.",
               "Fluorescent display: FM or CD, the preset, the frequency or the CD's time, the station or the title, the "
               "signal and the battery."]),
    "radio_handbuilt": dict(
        title="Makeshift Radio", sub="Item Base.RadioMakeShift.  Half card.  Batteries.  The car makeshift set keeps its own face.",
        status="Round 2; rocker now drawn off and on",
        states=[("off: the rocker down", RP.st_make(False)), ("on", {**RP.st_make(True), "switchOn": True})],
        notes=["\"Should use the circuit board diagram like the car version. Like it would really work\": the car set's "
               "receiver and amplifier, plus a switched headphone jack and the battery holder on the board. Every wire is "
               "routed on the board's holes and checked against the circuit.",
               "The salvaged display board on top carries the presets and MUTE; tape labels mark VOL and PWR.",
               "Wider panels: the circuit sits in the middle of a wider board, the spare holes either side.",
               "Not made at the 154 panel: the circuit needs a 160 px board. At 0.75 and 1.5 the card falls back the way "
               "the walkies did (to the full card)."]),
    "cd_player": dict(
        title="CD Player", sub="Item Base.CDplayer.  Half card.  Batteries.  No tuner.", status="Approved Oct 30 (\"OK\")",
        states=[("off", RP.st_cd(False)), ("playing", RP.st_cd(True)), ("playing, headphones in", {**RP.st_cd(True), "phonesIn": True})],
        notes=["Built on the Sony portables in the director's photos (the D-223 most): the lid is the whole top, about "
               "80% of the face; a squircle front; the controls in the strip under the lid.",
               "OPEN is a ribbed lip on the lid's edge you pull up on. The headphone jack is in the side.",
               "No battery door: the battery meter on the screen is the click area for the batteries.",
               "The face keeps its round shape at every width, so it grows taller as it grows wider."]),
    "tv_widescreen": dict(
        title="Premium Technologies Television", sub="Item Base.TvWideScreen.  Full card.  Mains power.  Plays video tapes.",
        status="Approved Oct 30 (\"Drop the counter label and its approved\"); signal light Oct 30",
        states=[("no power", R.state_tv(False, power=False)), ("on: Triple-N signs off", R.state_tv(True, ch=2, signal=4)),
                ("a tape in; nothing on channel 8: colour bars", R.state_tv(True, ch=8, signal=2, tape=True, counter="1:05:33"))],
        screens=[None, "signoff_triple_n", "bars"],
        notes=["The silver set and dark bezel of its tiles, a 16:9 tube.",
               "The strip: the tape deck and its counter at the left; channel, volume, mute, power and the headphone jack "
               "at the right. The narrow face takes the same controls in three rows.",
               "The signal is one light: dark for none, red bad, yellow fair, green good."]),
    "tv_black": dict(
        title="ValuTech Television", sub="Item Base.TvBlack.  Full card.  Mains power.  Plays video tapes.",
        status="Round 2; signal light Oct 30",
        states=[("no power", R.state_tv(False, power=False)), ("on: KPATV signs off", R.state_tv(True, ch=7, signal=3)),
                ("weak signal: snow", R.state_tv(True, ch=3, signal=1))],
        screens=[None, "signoff_kpa", "snow_0"],
        notes=["The dark set of its tiles: a 4:3 tube between two speaker grilles, the Premium set's strip.",
               "The narrow face drops the grilles to keep the tube."]),
    "tv_antique": dict(
        title="Antique Television", sub="Item Base.TvAntique.  Full card.  Mains power.  Black and white.",
        status="Round 2; signal light Oct 30",
        states=[("no power", st_off := RP.st_ant(False)), ("on: Life and Living TV signs off", RP.st_ant(True)),
                ("on: GBC", {**RP.st_ant(True), "chIdx": 9, "sigGood": False, "sigFair": True})],
        screens=[None, "signoff_life", "signoff_gbc"],
        notes=["The walnut console sets: the round-cornered tube in a brushed mask, the controls in a column at the right, "
               "drawer fronts along the base.",
               "The channel selector has twelve stops printed 2 to 13; the game's ten channels sit on the first ten.",
               "The volume knob pulls on. The screen is black and white in the tube's green-grey.",
               "The narrow face puts the tube on top and the controls in a row under it."]),
    "washer": dict(
        title="Washer", sub="Object IsoClothingWasher.  Full card.  Mains power and water.  Premium Technologies.",
        status="New: designed on the director's word, for sign-off",
        states=[("no power", L.state("washer", powered=False, water=3)), ("powered, no water", L.state("washer", water=0)),
                ("running: WASH, a load in", L.state("washer", running=True, water=4, items=True, phase="phWash", drum=0.3))],
        anat=L.state("washer", running=True, water=4, items=True, phase="phRinse", drum=0.3),
        notes=["From the game's laundry model: white enamel, a blue control panel, a chrome-ringed glass door. The game's "
               "own Premium Technologies brand, a matched pair with the dryer.",
               "Only what the game does: power on and off, and the door (the contents). Nothing for show that a player "
               "would try to turn: the cycle is a gauge under glass.",
               "The game has no wash phases; WASH, RINSE and SPIN step through by the clock while it runs, and the cycle "
               "gauge with them. FILL lights when there is no water.",
               "The water shows twice: the meter, and the water itself in the drum over the load."]),
    "dryer": dict(
        title="Dryer", sub="Object IsoClothingDryer.  Full card.  Mains power.  Premium Technologies.",
        status="New: designed on the director's word, for sign-off",
        states=[("no power", L.state("dryer", powered=False)), ("powered, a load in", L.state("dryer", items=True)),
                ("running: DRY", L.state("dryer", running=True, items=True, phase="phDry", drum=0.6))],
        notes=["The washer's pair: the same panel and enamel, a solid white door with a smoked window, vent louvres in the "
               "toe kick.",
               "Power on and off, and the door. DRY and COOL step through by the clock while it runs; HEAT lights while it "
               "runs."]),
    "washer_dryer": dict(
        title="Washer-Dryer", sub="Object IsoCombinationWasherDryer.  Full card.  Mains power; water in washer mode.  ValuTech.",
        status="New: designed on the director's word, for sign-off",
        states=[("powered, washer mode, no water", L.state("combo", water=0)),
                ("running: RINSE", L.state("combo", running=True, water=3, items=True, phase="phRinse", drum=0.2)),
                ("dryer mode, running: COOL", L.state("combo", running=True, mode="dry", items=True, phase="phCool", drum=0.8))],
        notes=["The budget all-in-one in ValuTech's light grey with its green wordmark, the game's own brand.",
               "WASH and DRY are the game's mode switch: two keys, the lit one is the mode. Each asks for its mode; the "
               "game wants power (and water for washer mode).",
               "All five phase lamps, FILL in washer mode, the water meter and the water in the drum."]),
}


def wrap(d, text, f, width):
    words, lines, cur = text.split(), [], ""
    for w in words:
        t = (cur + " " + w).strip()
        if d.textlength(t, font=f) <= width: cur = t
        else: lines.append(cur); cur = w
    if cur: lines.append(cur)
    return lines


def face_states(pid, W, states, screens=None):
    D = DESIGNS[pid]
    fn = RP.FN[pid]
    p, base, sprites = build(fn, D["variants"], W=W, **D.get("base", {}))
    if D.get("post"): D["post"](p)
    ims = []
    pics = None
    for i, st in enumerate(states):
        im = PV.render_state(base, p.parts, sprites, st).convert("RGBA")
        sc = screens[i] if screens else None
        if sc:
            q = [x for x in p.parts if x["t"] == "tvScreen"][0]
            if pics is None: pics = XR.screen_pictures(q)
            pic = pics[sc].copy()
            if sc.startswith("signoff_") and sc[8:] in O.GAME_LOGOS and O.GAME_ROOT:
                a = np.asarray(pic.convert("RGB"), np.float32) / 255
                a2 = a.copy(); O.game_logo(a2, sc[8:])
                if q.get("tint"):
                    lum = (a2[..., 0] * 0.3 + a2[..., 1] * 0.59 + a2[..., 2] * 0.11)[..., None]
                    a2 = np.clip(lum * (np.array(O.hexc(q["tint"]), np.float32) / 255) * 1.15, 0, 1)
                al = pic.getchannel("A"); pic = O.to_img(a2).convert("RGBA"); pic.putalpha(al)
            im.alpha_composite(pic, (q["x"], q["y"]))
        ims.append(im)
    return p, ims


def bbox_runs(runs):
    xs, ys = [], []
    for r in runs:
        if len(r) == 3: x0, y, w = r; xs += [x0, x0 + w]; ys += [y, y + 1]
        else: x, y, w, h = r[:4]; xs += [x, x + w]; ys += [y, y + h]
    return min(xs), min(ys), max(xs), max(ys)


def part_box(q):
    t = q["t"]
    if "runs" in q and q["runs"]: return bbox_runs(q["runs"])
    if t == "bars":
        boxes = [bbox_runs(b) for b in q["bars"] if b]
        return min(b[0] for b in boxes), min(b[1] for b in boxes), max(b[2] for b in boxes), max(b[3] for b in boxes)
    if t in ("ptr", "needle") and "cx" in q:
        r = q.get("r1", 6); return q["cx"] - r, q["cy"] - r, q["cx"] + r, q["cy"] + r
    if "x" in q and "w" in q: return q["x"], q["y"], q["x"] + q["w"], q["y"] + q.get("h", 3)
    return None


def badge(d, x, y, txt, col, f):
    w = max(22, int(d.textlength(txt, font=f)) + 12)
    d.rounded_rectangle([x, y, x + w, y + 22], radius=11, fill=col)
    d.text((x + w / 2, y + 11), txt, font=f, fill=(20, 20, 22), anchor="mm")


def sheet(pid, out_dir):
    spec = DEV[pid]
    card = [s for s in RP.SPECS if s[0] == pid][0][2]
    W0 = 180 if card == "half" else 392
    k = 2
    p, hero = face_states(pid, W0, [s for _, s in spec["states"]], spec.get("screens"))
    anat_state = spec.get("anat") or spec["states"][-1][1]
    _, (anat,) = face_states(pid, W0, [anat_state], [spec["screens"][1]] if spec.get("screens") else None)
    up = lambda im, kk: im.resize((im.width * kk, im.height * kk), Image.NEAREST)
    fT, fS, fH = font("head", 40), font("body", 22), font("head", 22)
    fB, fBs, fM, fBadge = font("body", 20), font("semi", 20), font("mono", 17), font("semi", 15)
    # the faces at every width
    ws = list(WP.widths(pid)[1])
    faces = []
    for W in ws:
        try:
            pw, (im,) = face_states(pid, W, [spec["states"][-1][1]], [spec["screens"][-1]] if spec.get("screens") else None)
            faces.append((W, pw, im))
        except Exception as e:
            faces.append((W, None, None))
    if pid in RP.NARROW:
        pw, (im,) = face_states(pid, 200, [spec["states"][-1][1]], [spec["screens"][-1]] if spec.get("screens") else None)
        faces.insert(0, (200, pw, im))
    skipped = [w for w in (RP.HALF if card == "half" else ()) if w not in ws]
    kw = 2 if sum(f[2].width for f in faces if f[2]) * 2 + 40 * len(faces) < PW - 2 * M else 1
    # ---- height estimate, then draw
    H = 4000
    S = Image.new("RGB", (PW, H), BG); d = ImageDraw.Draw(S)
    y = M
    d.text((M, y), spec["title"], font=fT, fill=INK)
    d.text((M, y + 56), spec["sub"], font=fS, fill=DIM)
    # the sign-off box
    bx0 = PW - M - 640
    st_lines = wrap(d, spec["status"], fB, 600)
    bh = 70 + 26 * len(st_lines) + 30
    d.rounded_rectangle([bx0, y - 6, PW - M, y - 6 + bh], radius=8, outline=RULE, width=2, fill=PANEL)
    d.text((bx0 + 20, y + 6), "FOR SIGN-OFF", font=fH, fill=HIT)
    for i, line in enumerate(st_lines): d.text((bx0 + 20, y + 38 + 26 * i), line, font=fB, fill=INK)
    yy = y + 38 + 26 * len(st_lines) + 4
    d.text((bx0 + 20, yy), "Design, Oct 30 2026.   Approved:", font=fB, fill=DIM)
    d.line([bx0 + 330, yy + 20, PW - M - 20, yy + 20], fill=DIM, width=1)
    y += max(130, bh + 10)
    d.line([M, y, PW - M, y], fill=RULE, width=2); y += 24

    def heading(t, sub=None):
        nonlocal y
        d.text((M, y), t, font=fH, fill=INK)
        if sub: d.text((M + d.textlength(t, font=fH) + 18, y + 2), sub, font=fB, fill=DIM)
        y += 40

    # 1. at play scale
    heading("1  At play scale", f"4K, UI scale 1.75: the {W0} {'panel' if card == 'half' else 'plate'} "
                               f"(face {p.W} x {p.H}), drawn 2x")
    x = M
    hmax = 0
    for (lab, _), im in zip(spec["states"], hero):
        u = up(im, k)
        if x + u.width > PW - M: x = M; y += hmax + 50; hmax = 0
        S.paste(u, (x, y), u)
        d.text((x, y + u.height + 8), lab, font=fB, fill=DIM)
        x += u.width + 40; hmax = max(hmax, u.height)
    y += hmax + 60
    # 2. anatomy
    heading("2  Controls and live parts", "numbers: what you click;  letters: what moves or lights, and the state it reads")
    ka = 4 if p.W * 4 <= 1000 else (3 if p.W * 3 <= 1250 else 2)
    u = up(anat, ka).convert("RGB")
    dd = ImageDraw.Draw(u)
    groups, order = {}, []
    for h in p.hits:
        t = HIT_PER.get((pid, h["id"]), HITS.get(h["id"], h["id"]))
        if t not in groups: groups[t] = len(groups) + 1; order.append((groups[t], t, []))
        order[groups[t] - 1][2].append(h["id"])
        x0, y0, w, h_ = h["x"] * ka, h["y"] * ka, h["w"] * ka, h["h"] * ka
        dd.rectangle([x0, y0, x0 + w - 1, y0 + h_ - 1], outline=HIT, width=2)
        badge(dd, x0 - 6, y0 - 14, str(groups[t]), HIT, fBadge)
    pgroups, porder = {}, []
    for q in p.parts:
        key = part_key(q)
        info = PART_PER.get((pid, key)) or PARTS.get(key)
        if not info: continue
        bb = part_box(q)
        if key not in pgroups:
            pgroups[key] = chr(ord("A") + len(pgroups)); porder.append([pgroups[key], info, []])
        src = q.get("src")
        g = [o for o in porder if o[0] == pgroups[key]][0]
        if src and src not in g[2]: g[2].append(src)
        if bb and q["t"] != "sprite" or (bb and q["t"] == "sprite"):
            x0, y0, x1, y1 = [v * ka for v in bb]
            for xx in range(int(x0), int(x1), 6): dd.line([xx, y0, min(xx + 3, x1), y0], fill=PART, width=2); dd.line([xx, y1, min(xx + 3, x1), y1], fill=PART, width=2)
            for yy in range(int(y0), int(y1), 6): dd.line([x0, yy, x0, min(yy + 3, y1)], fill=PART, width=2); dd.line([x1, yy, x1, min(yy + 3, y1)], fill=PART, width=2)
            badge(dd, x1 - 10, y1 - 8, pgroups[key], PART, fBadge)
    S.paste(u, (M, y))
    lx = M + u.width + 50
    lw = PW - M - lx
    ly = y
    if lw < 600:                                          # a wide face: the legend goes under it
        lx, lw, ly = M, PW - 2 * M, y + u.height + 30
    d.text((lx, ly), "Click areas", font=fBs, fill=HIT); ly += 32
    for n, t, ids in order:
        badge(d, lx, ly, str(n), HIT, fBadge)
        lines = wrap(d, t, fB, min(lw - 60, 640))
        for line in lines:
            d.text((lx + 40, ly), line, font=fB, fill=INK); ly += 26
        d.text((lx + 40 + d.textlength(lines[-1], font=fB) + 16, ly - 24), " ".join(ids), font=fM, fill=DIM)
        ly += 4
    ly += 16
    d.text((lx, ly), "Live parts", font=fBs, fill=PART); ly += 32
    for L_, (t, st), srcs in porder:
        if st is None: st = " / ".join(srcs)
        badge(d, lx, ly, L_, PART, fBadge)
        for line in wrap(d, t, fB, lw - 60):
            d.text((lx + 40, ly), line, font=fB, fill=INK); ly += 26
        d.text((lx + 40, ly), st, font=fM, fill=DIM); ly += 30
    y = max(y + u.height, ly) + 50
    # 3. every width
    heading("3  Every width", f"each face it ships at, with the UI scales it fills; drawn {kw}x")
    x = M; hmax = 0
    scales = SCALES_HALF if card == "half" else SCALES_FULL
    for W, pw, im in faces:
        if im is None: continue
        uu = up(im, kw)
        if x + uu.width > PW - M: x = M; y += hmax + 90; hmax = 0
        S.paste(uu, (x, y), uu)
        name = f"{W} {'panel' if card == 'half' else ('narrow' if W == 200 else 'plate')}"
        colw = max(uu.width, 230)
        d.text((x, y + uu.height + 8), f"{name}, face {pw.W} x {pw.H}", font=fBs, fill=INK)
        for i, line in enumerate(wrap(d, f"fills at {scales[W]}", fB, colw)):
            d.text((x, y + uu.height + 34 + 24 * i), line, font=fB, fill=DIM)
        x += colw + 40; hmax = max(hmax, uu.height + 24)
    y += hmax + 80
    if skipped:
        d.text((M, y - 20), "Not made: " + ", ".join(f"the {w} panel" for w in skipped) + " (see the notes).", font=fB, fill=HIT)
        y += 30
    # 4. notes
    heading("4  Notes")
    for n in spec["notes"]:
        lines = wrap(d, n, fB, PW - 2 * M - 40)
        d.ellipse([M + 4, y + 9, M + 12, y + 17], fill=DIM)
        for line in lines: d.text((M + 30, y), line, font=fB, fill=INK); y += 28
        y += 8
    y += 20
    d.line([M, y, PW - M, y], fill=RULE, width=1); y += 18
    d.text((M, y), f"Plate ids: {pid} and {pid}@<width>" + (f"; narrow {pid}_n" if pid in RP.NARROW else "") +
           ".  Source: tools/physpx " + {"radio_handbuilt": "d_rtv_make.py"}.get(pid, "d_laundry.py" if pid in L.WIDE or pid == "washer_dryer" else "d_rtv.py") +
           ", rtv_plates.py.", font=fM, fill=DIM)
    y += 40 + M
    S = S.crop((0, 0, PW, y))
    os.makedirs(out_dir, exist_ok=True)
    path = os.path.join(out_dir, f"spec_{pid}.png")
    S.save(path); print("wrote", path, S.size)
    return path


if __name__ == "__main__":
    O.GAME_ROOT = os.environ.get("ZED_GAME_ROOT") or O.GAME_ROOT
    out = sys.argv[1]
    for pid in (sys.argv[2:] or list(DEV)):
        sheet(pid, out)
