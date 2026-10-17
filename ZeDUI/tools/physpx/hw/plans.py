"""Rough top-view plans of the two hand-wired boards at plate size, for the review page: the approved controls where
they are, the salvaged display board, the circuit's zones, the wires that leave the plate. Colours are CSS classes
the page styles.  usage: python plans.py  ->  plan_radio.svg, plan_twoway.svg"""
import os

HERE = os.path.dirname(os.path.abspath(__file__))


def svg(W, H, body):
    return (f'<svg viewBox="-4 -14 {W + 8} {H + 30}" xmlns="http://www.w3.org/2000/svg" role="img" class="plan">'
            f'<defs><pattern id="holes{W}" width="5" height="5" patternUnits="userSpaceOnUse">'
            f'<circle cx="2.5" cy="2.5" r="0.7" class="hole"/></pattern></defs>'
            f'<rect x="0" y="0" width="{W}" height="{H}" class="perf"/>'
            f'<rect x="0" y="0" width="{W}" height="{H}" fill="url(#holes{W})"/>{body}</svg>')


def rect(x, y, w, h, cls, rx=0):
    return f'<rect x="{x}" y="{y}" width="{w}" height="{h}" class="{cls}" rx="{rx}"/>'


def text(x, y, s, cls="lbl", anchor="start"):
    return f'<text x="{x}" y="{y}" class="{cls}" text-anchor="{anchor}">{s}</text>'


def knob(cx, cy, r, name):
    return (f'<circle cx="{cx}" cy="{cy}" r="{r}" class="knob"/>'
            + text(cx, cy + r + 7, name, "ctl", "middle"))


def key(x, y, w, h, name):
    return rect(x, y, w, h, "key") + text(x + w / 2, y + h + 6, name, "ctl small", "middle")


def wire_out(pts, cls, label=None, lx=0, ly=0, anchor="start"):
    d = "M " + " L ".join(f"{x} {y}" for x, y in pts)
    s = f'<path d="{d}" class="wire {cls}"/>'
    if label: s += text(lx, ly, label, "note", anchor)
    return s


def radio():
    W, H = 440, 128
    b = []
    # the zones of the circuit
    b.append(rect(338, 6, 98, 118, "zone rx"))
    b.append(text(342, 15, "RECEIVER", "zlab"))
    b.append(text(342, 22, "TDA7000 + 20 parts", "zsub"))
    b.append(rect(348, 30, 46, 14, "chip"))
    b.append(text(371, 40, "TDA7000", "chiplab", "middle"))
    b.append(rect(72, 50, 62, 74, "zone amp"))
    b.append(text(76, 59, "AMPLIFIER", "zlab"))
    b.append(text(76, 66, "LM386 + 5 parts", "zsub"))
    b.append(rect(88, 82, 20, 13, "chip"))
    b.append(text(98, 91, "LM386", "chiplab", "middle"))
    # the salvaged display-and-keys board and its ribbon
    b.append(rect(136, 12, 198, 90, "addon"))
    b.append(text(140, 20, "SALVAGED DISPLAY + KEYS BOARD (bolted on)", "zlab light"))
    b.append(rect(148, 22, 144, 34, "lcd"))
    for i in range(6): b.append(key(158 + i * 22, 72, 12, 12, str(i + 1)))
    b.append(key(310, 26, 14, 14, "SEEK"))
    b.append(wire_out([(136, 40), (118, 40), (110, 30)], "ribbon", "ribbon", 92, 48))
    # the audio wire across the bottom
    b.append(wire_out([(352, 52), (340, 112), (150, 114), (64, 112)], "sig", "audio: pin 2 → 220n → volume", 200, 110))
    # the controls (approved places)
    b.append(knob(52, 92, 15, "VOL"))
    b.append(rect(368, 68, 48, 48, "polyv"))
    b.append(knob(392, 92, 15, "TUNE"))
    b.append(text(392, 66, "tuning capacitor", "zsub", "middle"))
    b.append(rect(22, 26, 24, 16, "rocker"))
    b.append(text(34, 50, "PWR", "ctl", "middle"))
    # wires that leave the plate
    b.append(wire_out([(30, 26), (30, 8), (0, 8)], "red", "battery 4.5 V", 2, -4))
    b.append(wire_out([(36, 26), (36, 4), (0, 4)], "blk"))
    b.append(wire_out([(120, 118), (120, 128), (120, 140)], "spk", "speaker", 131, 138))
    b.append(wire_out([(126, 118), (126, 140)], "spk"))
    b.append(wire_out([(404, 22), (424, 12), (440, -6)], "ant", "antenna lead", 436, -8, "end"))
    return svg(W, H, "".join(b))


def twoway():
    W, H = 500, 138
    b = []
    b.append(rect(338, 6, 156, 128, "zone rx"))
    b.append(text(342, 15, "RECEIVER / TRANSMITTER", "zlab"))
    b.append(text(342, 22, "Q1, crystal, 9:2 coil + 11 parts", "zsub"))
    b.append(rect(8, 52, 132, 82, "zone amp"))
    b.append(text(80, 61, "AMPLIFIER", "zlab"))
    b.append(text(80, 68, "Q2, Q3, Q4, speaker", "zsub"))
    b.append(text(80, 75, "transformer + 12 parts", "zsub"))
    b.append(rect(146, 12, 190, 92, "addon"))
    b.append(text(150, 20, "SALVAGED DISPLAY + KEYS BOARD", "zlab light"))
    b.append(rect(158, 22, 164, 36, "lcd"))
    for i, n in enumerate(("CH+", "CH-", "MEM", "MIC", "MUTE")):
        b.append(key(162 + i * 30, 76, 13, 13, n))
    b.append(f'<circle cx="318.5" cy="81" r="3" class="lamp"/>')
    b.append(rect(208, 118, 84, 11, "tape"))
    b.append(text(250, 126, "RANGE (tape)", "ctl small", "middle"))
    b.append(knob(56, 98, 16, "VOL"))
    b.append(knob(444, 92, 22, "DIAL"))
    b.append(text(444, 64, "on the coil's slug", "zsub", "middle"))
    b.append(rect(22, 30, 24, 16, "rocker"))
    b.append(text(34, 54, "PWR", "ctl", "middle"))
    b.append(rect(256, 106, 0, 0, "x"))
    b.append(wire_out([(30, 30), (30, 10), (0, 10)], "red", "battery 9 V", 2, -4))
    b.append(wire_out([(36, 30), (36, 6), (0, 6)], "blk"))
    b.append(wire_out([(110, 130), (110, 152)], "spk", "speaker (the microphone too)", 122, 150))
    b.append(wire_out([(116, 130), (116, 152)], "spk"))
    b.append(wire_out([(470, 40), (486, 20), (500, -6)], "ant", "antenna lead", 496, -8, "end"))
    b.append(wire_out([(146, 44), (128, 44), (120, 36)], "ribbon", "ribbon", 100, 30))
    return svg(W, H, "".join(b))


if __name__ == "__main__":
    for n, f in (("plan_radio.svg", radio), ("plan_twoway.svg", twoway)):
        open(os.path.join(HERE, n), "w").write(f())
    print("ok")
