"""The radio's circuit redrawn from nets.RADIO_NETS: the Philips TDA7000 test circuit (Fig. 4) with an antenna, the
National LM386 minimum-parts amplifier, and the one 220n that joins them.
Lines that cross without a dot are not joined.
usage: python schem_radio.py out_basename   ->  out_basename.svg / .png"""
import sys

import matplotlib
matplotlib.use("Agg")
import schemdraw
import schemdraw.elements as elm

from schem_twoway import S, NOTE

elm.style(elm.STYLE_IEC)
schemdraw.config(fontsize=10, lw=1.2)

GLUE = "#1f5fa8"


def build(out):
    with schemdraw.Drawing(show=False) as d:
        d.config(unit=2.0)
        s = S(d)
        # ------------------------------------------------------------ the TDA7000 as Philips draws it
        x0, x1, yb, yt = 0.0, 21.0, 6.5, 9.0
        s.w((x0, yb), (x1, yb), (x1, yt), (x0, yt), (x0, yb))
        s.text(((x0 + x1) / 2, (yb + yt) / 2), "U1  TDA7000", fontsize=12)
        px = lambda i: x0 + 1.3 + 2.3 * i                       # noqa: E731
        top = {18 - i: (px(i), yt) for i in range(9)}            # 18 at the left ... 10 at the right
        bot = {1 + i: (px(i), yb) for i in range(9)}             # 1 at the left ... 9 at the right
        for n, (x, y) in top.items():
            s.w((x, y), (x, y + 1.0)); s.text((x + 0.25, y - 0.4), str(n), fontsize=8, halign="left")
        for n, (x, y) in bot.items():
            s.w((x, y), (x, y - 1.0)); s.text((x + 0.25, y + 0.4), str(n), fontsize=8, halign="left")
        VT, VB = 15.0, 0.0                                       # the supply rail above and below
        # top side: 18, 17, 15, 12, 11 to the rail; 16 and 14 to ground; 13 from the antenna; 330p from 11 to 10
        for n, lab in ((18, "C18\n220p"), (17, "C17\n330p"), (15, "C15\n100n"), (12, "C12\n150p")):
            x = top[n][0]
            s.two(elm.Capacitor, (x, yt + 1.0), (x, VT), lab, loc="bottom")
            s.dot((x, VT))
        x = top[16][0]
        d.add(elm.Ground().theta(180).at((x, yt + 1.0)))
        x = top[14][0]
        s.two(elm.Capacitor, (x, yt + 1.0), (x, yt + 3.4), "C14\n220p", loc="bottom")
        d.add(elm.Ground().theta(180).at((x, yt + 3.4)))
        x = top[13][0]
        s.two(elm.Capacitor, (x, yt + 1.0), (x, yt + 3.4), "C13\n220p", loc="bottom")
        s.w((x, yt + 3.4), (x, VT - 0.6), (x + 1.0, VT - 0.6), (x + 1.0, VT + 1.4))
        d.add(elm.Antenna().theta(0).at((x + 1.0, VT + 1.4)))
        s.text((x + 1.35, VT + 2.2), "antenna lead", halign="left", fontsize=9, color=NOTE)
        x11, x10 = top[11][0], top[10][0]
        s.two(elm.Capacitor, (x11, yt + 1.0), (x11, VT), "C11\n3n3", loc="top")
        s.dot((x11, VT))
        s.dot((x11, yt + 1.0))
        s.two(elm.Capacitor, (x11, yt + 1.0), (x10, yt + 1.0), "C10 330p", loc="top")
        s.w((top[18][0], VT), (x1 + 1.5, VT), (x1 + 1.5, VB))
        # (pin 13's lead crosses the rail by the antenna)
        # bottom side: 1, 3, 4, 8 to the rail; 5 is the supply; 6 the oscillator; 3n3 from 7 to 9
        for n, lab in ((1, "C1\n150n"), (3, "C3\n22n"), (4, "C4\n10n"), (8, "C8\n180p")):
            x = bot[n][0]
            s.two(elm.Capacitor, (x, yb - 1.0), (x, VB), lab, loc="bottom")
            s.dot((x, VB))
        x5, x6 = bot[5][0], bot[6][0]
        s.w((x5, yb - 1.0), (x5, VB)); s.dot((x5, VB))
        # the oscillator's tank between 5 and 6: 56nH, Cp, and the tuning capacitor in series with Cs
        ya, yb2, yc = 4.3, 2.9, 1.5
        s.dot((x5, ya)); s.dot((x5, yb2)); s.dot((x5, yc))
        s.w((x6, yb - 1.0), (x6, yc))
        s.dot((x6, ya)); s.dot((x6, yb2))
        s.two(elm.Inductor2, (x5, ya), (x6, ya), "L1 56nH", loc="top", loops=3)
        s.two(elm.Capacitor, (x5, yb2), (x6, yb2), "CP 33p", loc="top")
        xm = (x5 + x6) / 2
        s.two(elm.CapacitorVar, (x5, yc), (xm, yc))
        s.two(elm.Capacitor, (xm, yc), (x6, yc))
        s.text((x5 + 0.2, yc - 0.85), "CV", fontsize=9, halign="left")
        s.text((xm + 0.3, yc - 0.85), "CS 100p", fontsize=9, halign="left")
        s.text((x5 - 0.4, yc + 0.0), "TUNE =", fontsize=10, halign="right", color=NOTE)
        x7, x9 = bot[7][0], bot[9][0]
        s.w((x7, yb - 1.0), (x7, 3.6)); s.w((x9, yb - 1.0), (x9, 3.6))
        s.two(elm.Capacitor, (x7, 3.6), (x9, 3.6), "C7 3n3", loc="top")
        # C5 10n across the supply, by pin 5
        s.w((x1 + 1.5, VB), (x1 + 1.5, VB - 1.8))
        s.two(elm.Capacitor, (x1 + 1.5, VB - 1.8), (x1 + 1.5, VB - 4.2), "C5\n10n", loc="bottom")
        d.add(elm.Ground().at((x1 + 1.5, VB - 4.2)))
        s.w((bot[1][0], VB), (x1 + 1.5, VB)); s.dot((x1 + 1.5, VB))
        s.text((x1 + 1.75, VT - 0.4), "supply\n(VP)", halign="left", fontsize=8)
        # pin 2: the audio out, 22k and 1n8 to ground
        x2 = bot[2][0]
        af = (x2, 3.2)
        s.w((x2, yb - 1.0), af); s.dot(af)
        s.w(af, (x2 - 1.2, af[1]))
        # ------------------------------------------------------------ the LM386 and the joining capacitor
        xl = -1.2
        s.dot((xl, af[1]))
        s.w((x2 - 1.2, af[1]), (xl, af[1]))
        s.two(elm.Resistor, (xl, af[1]), (xl, -1.0), "RL\n22k", loc="bottom")
        d.add(elm.Ground().at((xl, -1.0)))
        s.w((xl, af[1]), (xl - 1.4, af[1]))
        s.two(elm.Capacitor, (xl - 1.4, af[1]), (xl - 1.4, -1.0), "C2\n1n8", loc="top")
        d.add(elm.Ground().at((xl - 1.4, -1.0)))
        s.dot((xl - 1.4, af[1]))
        cc_l = (xl - 4.6, af[1])
        s.two(elm.Capacitor, (xl - 1.4, af[1]), cc_l, "CC 220n", loc="top", color=GLUE)
        s.text(((xl - 1.4 + cc_l[0]) / 2, af[1] - 0.95), "(joins the two)", fontsize=8, color=GLUE)
        vr_t, vr_b = (cc_l[0], af[1]), (cc_l[0], af[1] - 4.0)
        vr = d.add(elm.Potentiometer().at(vr_t).to(vr_b).flip())
        s.text((cc_l[0] + 0.45, vr_t[1] - 1.6), "VR1\n10k", fontsize=9, halign="left")
        s.text((cc_l[0] + 0.45, vr_t[1] - 2.9), "= VOL", fontsize=10, halign="left", color=NOTE)
        d.add(elm.Ground().at(vr_b))
        tap = (cc_l[0] - 0.72, vr_t[1] - 2.0)
        op = d.add(elm.Opamp(leads=True).left().at((cc_l[0] - 2.4, tap[1])).anchor("in2"))
        s.w(tap, op.in2)
        s.text((op.in2[0] - 0.2, op.in2[1] + 0.3), "3", fontsize=8, halign="right")
        s.text((op.in1[0] - 0.2, op.in1[1] - 0.3), "2", fontsize=8, halign="right")
        s.w(op.in1, (op.in1[0], op.in1[1] - 1.0))
        d.add(elm.Ground().at((op.in1[0], op.in1[1] - 1.0)))
        cx = op.vs[0]
        s.w(op.vs, (cx, VT)); s.dot((cx, VT))
        s.text((cx + 0.2, op.vs[1] + 0.35), "6", fontsize=8, halign="left")
        s.w(op.vd, (cx, op.vd[1] - 1.2))
        d.add(elm.Ground().at((cx, op.vd[1] - 1.2)))
        s.text((cx + 0.2, op.vd[1] - 0.35), "4", fontsize=8, halign="left")
        s.text((cx - 0.1, op.out[1] + 2.2), "U2  LM386", fontsize=10, halign="right")
        out_ = op.out
        s.text((out_[0] + 0.1, out_[1] + 0.32), "5", fontsize=8, halign="left")
        # the output: 250u to the speaker; 0.05u + 10R to ground
        xo = out_[0] - 0.9
        s.w(out_, (xo, out_[1])); s.dot((xo, out_[1]))
        s.two(elm.Capacitor, (xo, out_[1]), (xo - 3.0, out_[1]), "C20 250u", loc="top", polar=True)
        spk = d.add(elm.Speaker().left().at((xo - 3.0, out_[1])).anchor("in2"))
        s.text((xo - 4.4, out_[1] + 1.3), "speaker 8R", fontsize=9)
        s.w(spk.in1, (spk.in1[0], out_[1] - 3.0))
        d.add(elm.Ground().at((spk.in1[0], out_[1] - 3.0)))
        s.two(elm.Capacitor, (xo, out_[1]), (xo, out_[1] - 2.4), "C21\n0.05u", loc="bottom")
        s.two(elm.Resistor, (xo, out_[1] - 2.4), (xo, out_[1] - 5.0), "R20\n10R", loc="bottom")
        d.add(elm.Ground().at((xo, out_[1] - 5.0)))
        # the supply: the battery and the power switch onto the rail; the display board's ribbon
        vy = VT
        xb = xo - 6.0
        s.w((xb, vy), (top[18][0], vy))
        s.two(elm.Switch, (xb, vy), (xb, vy - 3.0))
        s.text((xb + 0.5, vy - 1.2), "SW1 = PWR", fontsize=10, color=NOTE, halign="left")
        s.two(elm.Battery, (xb, vy - 3.0), (xb, vy - 6.4), "BT1\n4.5V", loc="top", reverse=True)
        d.add(elm.Ground().at((xb, vy - 6.4)))
        xr = xb + 3.2
        s.dot((xr, vy))
        s.w((xr, vy), (xr, vy + 1.4))
        d.add(elm.Dot(open=True).at((xr, vy + 1.4)))
        s.text((xr + 0.3, vy + 1.6), "display board's ribbon:\npower and ground only", fontsize=8, halign="left", color=GLUE)
        d.save(out + ".svg")
        d.save(out + ".png", dpi=110)


if __name__ == "__main__":
    build(sys.argv[1] if len(sys.argv) > 1 else "radio")
