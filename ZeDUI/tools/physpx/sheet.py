"""The approval sheet: the three prototypes at 2x in two states each, captions, and all three at true size."""
import os
import sys

from PIL import Image, ImageDraw, ImageFont

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import proto as P
import preview as PV

FD = "/usr/share/fonts/truetype/dejavu/"
F_T = ImageFont.truetype(FD + "DejaVuSans-Bold.ttf", 30)
F_H = ImageFont.truetype(FD + "DejaVuSans-Bold.ttf", 22)
F_B = ImageFont.truetype(FD + "DejaVuSans.ttf", 16)
F_S = ImageFont.truetype(FD + "DejaVuSans.ttf", 15)
BG, AMBER, TXT, DIM = (23, 23, 25, 255), (255, 214, 120, 255), (230, 230, 226, 255), (160, 160, 156, 255)
K = 2
GAP = 24


def wrap(draw, text, font, width):
    words, lines, cur = text.split(), [], ""
    for w in words:
        t = (cur + " " + w).strip()
        if draw.textlength(t, font=font) <= width: cur = t
        else: lines.append(cur); cur = w
    if cur: lines.append(cur)
    return lines


def block(title, sub, shots, live, look, k=None):
    """shots: [(image, caption)]; returns an RGBA block"""
    K = k or globals()["K"]
    iw = max(im.width for im, _ in shots) * K
    W = len(shots) * iw + (len(shots) + 1) * GAP
    tmp = Image.new("RGBA", (W, 10)); dr = ImageDraw.Draw(tmp)
    cap_lines = [wrap(dr, c, F_S, iw) for _, c in shots]
    live_lines = wrap(dr, "Live: " + live, F_B, W - 2 * GAP)
    look_lines = wrap(dr, "Look only: " + look, F_B, W - 2 * GAP) if look else []
    ih = max(im.height for im, _ in shots) * K
    H = 16 + 28 + 24 + 10 + ih + 8 + 20 * max(len(c) for c in cap_lines) + 10 + 22 * (len(live_lines) + len(look_lines)) + 18
    b = Image.new("RGBA", (W, H), BG); dr = ImageDraw.Draw(b)
    y = 16
    dr.text((GAP, y), title, font=F_H, fill=AMBER); y += 30
    dr.text((GAP, y), sub, font=F_B, fill=DIM); y += 34
    x = GAP
    for (im, _), lines in zip(shots, cap_lines):
        b.alpha_composite(PV.scale(im, K), (x, y))
        yy = y + ih + 8
        for ln in lines: dr.text((x, yy), ln, font=F_S, fill=TXT); yy += 20
        x += iw + GAP
    y += ih + 8 + 20 * max(len(c) for c in cap_lines) + 10
    for ln in live_lines: dr.text((GAP, y), ln, font=F_B, fill=TXT); y += 22
    for ln in look_lines: dr.text((GAP, y), ln, font=F_B, fill=DIM); y += 22
    return b


def details(shots, k=4, note=None):
    """close-ups: [(image, caption)] at k, no title; each keeps its own width"""
    ws = [im.width * k for im, _ in shots]
    W = sum(ws) + (len(shots) + 1) * GAP
    tmp = Image.new("RGBA", (W, 10)); dr = ImageDraw.Draw(tmp)
    cap_lines = [wrap(dr, c, F_S, w) for (_, c), w in zip(shots, ws)]
    note_lines = wrap(dr, note, F_B, W - 2 * GAP) if note else []
    ih = max(im.height for im, _ in shots) * k
    H = 6 + ih + 8 + 20 * max(len(c) for c in cap_lines) + 8 + 22 * len(note_lines) + 16
    b = Image.new("RGBA", (W, H), BG); dr = ImageDraw.Draw(b)
    x, y = GAP, 6
    for (im, _), lines, w in zip(shots, cap_lines, ws):
        b.alpha_composite(PV.scale(im, k), (x, y))
        yy = y + ih + 8
        for ln in lines: dr.text((x, yy), ln, font=F_S, fill=TXT); yy += 20
        x += w + GAP
    y += ih + 8 + 20 * max(len(c) for c in cap_lines) + 8
    for ln in note_lines: dr.text((GAP, y), ln, font=F_B, fill=TXT); y += 22
    return b


def main():
    gp, gb, gs = P.build_green()
    mp, mb, ms = P.build_mw()
    np_, nb, ns = P.build_gen()
    for p in (gp, mp, np_):
        for w in p.warnings: print("  !", p.id, w)
    g_off = PV.render_state(gb, gp.parts, gs, P.green_state(0, 0, False, 7, 40))
    g_on = PV.render_state(gb, gp.parts, gs, P.green_state(200, 35, True, 6, 10, celsius=True))
    m_idle = PV.render_state(mb, mp.parts, ms, P.mw_state("10:08", 4, False))
    m_cook = PV.render_state(mb, mp.parts, ms, P.mw_state("0:47", 2, True))
    n_off = PV.render_state(nb, np_.parts, ns, P.gen_state(False, False, 0.35))
    n_on = PV.render_state(nb, np_.parts, ns, P.gen_state(True, True, 0.8))
    g_detail_a = g_on.crop((0, 0, 114, 128))
    g_detail_b = g_on.crop((114, 0, 342, 128))
    blocks = [
        block("Green range, 1956 (reworked)", "Hollister Custom: the game's green gas range (oven sprites 0 to 3)",
              [(g_off, "Off at 7:40. The OFF key is down; burner knobs at OFF."),
               (g_on, "Baking at 200 °C with 35 minutes left: ON key down, pilot jewel lit. The oven dial printed in Celsius, as the player's setting asks (the Fahrenheit print is the left picture).")],
              "clock hands (game time), Minute Minder pointer (unwinds as the timer runs), oven pointer on the true temperature, ON and OFF keys, pilot jewel. The dial prints in the unit set in the game's options; the stove has no unit switch.",
              "the four burner knobs (the game heats the stove as one)."),
        details([(g_detail_a, "Close up, 4x: the enamel's gloss band, domed glossy knob caps with dirt in their flutes, the rubbed burner legends, a chip or two, pitted chrome."),
                 (g_detail_b, "The brushed aluminium now catches the light in a band and goes darker toward the right; the clock face has aged toward its rim.")],
                k=4),
        block("White touchpad microwave, 1990", "ValuTech: the game's white microwave (sprites 24 to 27), door cropped at the left; the same light wear as the range so the set matches",
              [(m_idle, "Idle: the readout shows the time of day like the real thing; power at HI (five lamps)."),
               (m_cook, "Cooking at medium with 47 seconds left: COOK lit, the oven lamp glowing through the door's screen.")],
              "readout, COOK, the five power lamps, the oven lamp behind the door, every pad: the number pads type the cook time (1, 3, 0 is 1:30), TIME COOK starts a fresh entry, POWER LEVEL steps the five powers.",
              ""),
        block("Red generator, 1988", "Mass GenFac 4000: the game's red generator (sprites 0 to 3) in its tube frame; scuffed paint, chipped edges, grime",
              [(n_off, "Off, a third of a tank, not connected."),
               (n_on, "Running and connected: the rocker at ON, OUTPUT lit, the building's cord plugged into the left outlet, the tank at four fifths.")],
              "ENGINE rocker, OUTPUT lamp, OIL ALERT lamp (lit when the condition is under a quarter), fuel gauge, the cord in the outlet (click the outlet to connect or disconnect).",
              "choke, breakers, the 12 volt posts, the ground terminal."),
    ]
    # the true-size strip
    plates = [(g_off, "Green range"), (m_idle, "Microwave"), (n_on, "Generator")]
    sw = sum(im.width for im, _ in plates) + (len(plates) + 1) * GAP
    sh = 16 + 30 + max(im.height for im, _ in plates) + 34
    strip = Image.new("RGBA", (sw, sh), BG); dr = ImageDraw.Draw(strip)
    dr.text((GAP, 16), "True size at 1920 × 1080 (one plate pixel per screen pixel)", font=F_H, fill=AMBER)
    x = GAP
    for im, cap in plates:
        strip.alpha_composite(im, (x, 54)); dr.text((x, 54 + im.height + 6), cap, font=F_S, fill=DIM); x += im.width + GAP
    W = max(max(b.width for b in blocks), strip.width)
    head_h = 70
    H = head_h + sum(b.height for b in blocks) + strip.height
    sheet = Image.new("RGBA", (W, H), BG); dr = ImageDraw.Draw(sheet)
    dr.text((GAP, 18), "Physical controls: three prototypes, second pass", font=F_T, fill=TXT)
    y = head_h
    for b in blocks:
        sheet.alpha_composite(b, (0, y)); y += b.height
        dr.line([(GAP, y - 4), (W - GAP, y - 4)], fill=(48, 48, 52, 255), width=1)
    sheet.alpha_composite(strip, (0, y))
    out = os.path.join(P.OUT, "prototypes_physical_controls_2.png")
    sheet.convert("RGB").save(out)
    print(out, sheet.size)


if __name__ == "__main__":
    main()
