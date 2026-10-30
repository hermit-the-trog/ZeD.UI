"""Round 1 review: the red radio at panel 180 and the widescreen TV at 392 (the director's 1.75, 2x zoom), off and on,
the live parts drawn; the TV's screen shows a stand-in picture (Code draws the real one)."""
import sys
from PIL import Image, ImageDraw, ImageFont
import plates_336  # noqa: F401
from physlib import build
import preview as PV
import d_rtv as R

FD = "/usr/share/fonts/truetype/dejavu/"


def face(fn, W, states):
    p, base, sprites = build(fn, [], W=W)
    R.attach(p)
    if p.warnings: print("WARN", p.id, p.warnings)
    out = []
    for st in states:
        im = PV.render_state(base, p.parts, sprites, st).convert("RGBA")
        dr = ImageDraw.Draw(im)
        for q in p.parts:
            if q["t"] == "tvScreen" and st.get("radioOn"):
                cols = [(192, 192, 192), (192, 192, 0), (0, 192, 192), (0, 192, 0), (192, 0, 192), (192, 0, 0), (0, 0, 192)]
                bw = q["w"] / len(cols); y1 = q["y"] + int(q["h"] * 0.68)
                for i, c in enumerate(cols):
                    dr.rectangle((q["x"] + 4 + int(i * bw * 0.98), q["y"] + 6, q["x"] + 3 + int((i + 1) * bw * 0.98), y1), fill=c + (255,))
                dr.rectangle((q["x"] + 4, y1 + 1, q["x"] + q["w"] - 5, q["y"] + q["h"] - 7), fill=(16, 16, 40, 255))
                dr.text((q["x"] + 12, y1 + 8), "WKVL  CH 12   (stand-in picture)", fill=(230, 230, 230, 255))
            if q["t"] == "slotTape" and st.get("hasMedia"):
                dr.rectangle((q["x"], q["y"], q["x"] + q["w"] - 1, q["y"]), fill=(200, 200, 200, 255))
        out.append(im)
    return p, out


def main(out, k=2):
    rad = [R.state_port(False, batt=3), R.state_port(True, freq="98.4", name="Knox Talk Radio", preset=2, batt=3),
           R.state_port(True, cd=True, elapsed="3:42", title="Kentucky Rain", progress=0.45, batt=2, phones=True)]
    tv = [R.state_tv(False, power=False), R.state_tv(True, ch=12, signal=3, tape=True)]
    pr, rads = face(R.radio_red, 180, rad)
    pt, tvs = face(R.tv_wide, 392, tv)
    f = ImageFont.truetype(FD + "DejaVuSans.ttf", 14); fb = ImageFont.truetype(FD + "DejaVuSans-Bold.ttf", 18)
    up = lambda im: im.resize((im.width * k, im.height * k), Image.NEAREST)
    W = max(3 * (up(rads[0]).width + 30), 2 * (up(tvs[0]).width + 30)) + 40
    H = up(rads[0]).height + up(tvs[0]).height + 200
    S = Image.new("RGBA", (W, H), (30, 31, 34, 255)); d = ImageDraw.Draw(S)
    d.text((20, 12), f"Premium Technologies Radio - panel 180, face {pr.W} x {pr.H}, at 1.75 (2x)", font=fb, fill=(230, 230, 224))
    x = 20
    for im, t in zip(rads, ("off", "on: FM", "on: CD playing, phones in")):
        S.alpha_composite(up(im), (x, 44)); d.text((x, 50 + up(im).height), t, font=f, fill=(160, 160, 155)); x += up(im).width + 30
    y = 44 + up(rads[0]).height + 50
    d.text((20, y), f"Premium Technologies Television - {pt.W} x {pt.H}, at 1.75 (2x)", font=fb, fill=(230, 230, 224)); y += 32
    x = 20
    for im, t in zip(tvs, ("no power", "on: channel 12, tape in")):
        S.alpha_composite(up(im), (x, y)); d.text((x, y + up(im).height + 6), t, font=f, fill=(160, 160, 155)); x += up(im).width + 30
    S.save(out); print("wrote", out, S.size)
    for p in (pr, pt):
        print(p.id, p.W, p.H, "hits:", [h["id"] for h in p.hits])


if __name__ == "__main__":
    main(sys.argv[1])
