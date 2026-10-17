"""The two-way's circuit redrawn from nets.TWOWAY_NETS (Talking Electronics, "27MHz Links", Fig. 24), shown in LISTEN.
Lines that cross without a dot are not joined.
usage: python schem_twoway.py out_basename   ->  out_basename.svg / .png"""
import sys

import matplotlib
matplotlib.use("Agg")
import schemdraw
import schemdraw.elements as elm

elm.style(elm.STYLE_IEC)
schemdraw.config(fontsize=10, lw=1.2)

GND = 0.0
TL = 18.5          # the T line: talking, the oscillator's supply is the amplifier's output
RL = 17.0          # the R line and the supply rail
SP = 15.5          # the speaker's wire to the amplifier input (talking: the speaker is the microphone)
NOTE = "#b0471a"   # the plate's controls
SWC = "#7a2a00"


class S:
    def __init__(s, d): s.d = d

    def dot(s, p): s.d.add(elm.Dot().at(p))

    def w(s, *pts):
        for a, b in zip(pts, pts[1:]):
            s.d.add(elm.Line().at(a).to(b))

    def two(s, E, a, b, lab=None, loc="bottom", ofst=None, **kw):
        e = E(**kw).at(a).to(b)
        if lab: e = e.label(lab, loc=loc, ofst=ofst) if ofst is not None else e.label(lab, loc=loc)
        return s.d.add(e)

    def text(s, p, t, **kw):
        kw.setdefault("fontsize", 9)
        s.d.add(elm.Label().at(p).label(t, **kw))

    def gnd(s, p):
        s.w(p, (p[0], GND)); s.dot((p[0], GND))

    def contact(s, p, name, side="right"):
        s.d.add(elm.Dot(open=True).at(p))
        if side in ("up", "down"):
            s.text((p[0], p[1] + (0.32 if side == "up" else -0.36)), name, fontsize=8, color=SWC)
            return
        dx = 0.28 if side == "right" else -0.28
        s.text((p[0] + dx, p[1]), name, halign="left" if side == "right" else "right", fontsize=8, color=SWC)

    def spdt(s, com, t, r, title, tpos=(0, -0.55), side="right"):
        """one section of the talk/listen switch, its lever resting on R (listen)"""
        s.contact(t, "T", side); s.contact(r, "R", side)
        s.d.add(elm.Dot(open=True).at(com))
        k = 0.12
        s.d.add(elm.Line().at(com).to((r[0] - k * (r[0] - com[0]), r[1] - k * (r[1] - com[1]))).color(SWC).linewidth(1.8))
        s.text((com[0] + tpos[0], com[1] + tpos[1]), title, fontsize=8, color=SWC)


def build(out):
    with schemdraw.Drawing(show=False) as d:
        d.config(unit=2.0)
        s = S(d)

        # ================================================================ Q1: receiver (listen) / transmitter (talk)
        base = (5.5, 7.5)
        q1 = d.add(elm.BjtNpn(circle=True).right().scale(1.3).at((7.62, base[1])).anchor("base"))
        s.text((q1.center[0] - 0.2, q1.center[1] - 1.55), "Q1 BC547", halign="right")
        qc, qe = q1.collector, q1.emitter
        X = qc[0]
        sup_y = 14.0
        # T1: 9 turns in the collector, 2 turns to the antenna, the slug between them
        t1 = d.add(elm.Transformer(t1=5, t2=3, core=True).right().at((X, 12.0)).anchor("p1"))
        s.w(t1.p2, qc)
        s.w(t1.p1, (X, sup_y)); s.dot((X, sup_y))
        s.text((X - 0.35, 11.0), "T1\n9 turns", halign="right")
        s.d.add(elm.Line().at((X - 0.2, 9.6)).to((X + 1.15, 12.5)).color(NOTE).linewidth(1.6))
        s.d.add(elm.Arrowhead().at((X + 1.15, 12.5)).theta(65).color(NOTE))
        s.text((X - 0.3, 9.45), "slug = DIAL", color=NOTE, halign="right", fontsize=10)
        # the antenna, its loading coil, the 2 turns and 15p across them
        s1, s2 = t1.s1, t1.s2
        a2 = (s1[0] + 0.6, 12.6)
        s.w(s1, (s1[0], a2[1]), a2); s.dot(a2)
        s.text((s1[0] + 0.25, s1[1] - 0.6), "2 turns", halign="left", fontsize=8)
        s.w(a2, (a2[0], 14.8))
        s.two(elm.Inductor2, (a2[0], 14.8), (a2[0], 17.0), "loading\ncoil", loc="bottom", loops=3)
        d.add(elm.Antenna().theta(0).at((a2[0], 17.0)))
        c1x = a2[0] + 1.2
        s.w(a2, (c1x, a2[1]))
        s.two(elm.Capacitor, (c1x, a2[1]), (c1x, 9.8), "C1\n15p", loc="bottom")
        s.w(s2, (s2[0], 9.8), (c1x, 9.8)); s.dot((c1x, 9.8))
        s.gnd((c1x, 9.8))
        # SUP: 33k to the base; the base's 15k to ground and 39n to the switch
        s.w((base[0], sup_y), (X, sup_y))
        s.two(elm.Resistor, (base[0], sup_y), base, "R1\n33k", loc="top")
        s.w(base, q1.base); s.dot(base)
        s.w(base, (0.6, base[1]))
        s.two(elm.Resistor, (0.6, base[1]), (0.6, 0.7), "R2\n15k", loc="bottom")
        s.gnd((0.6, 0.7))
        b39 = (base[0], 2.0)
        s.two(elm.Capacitor, base, (base[0], 4.2), "C3\n39n", loc="bottom")
        s.w((base[0], 4.2), b39); s.dot(b39)
        # collector-emitter 33p; 56R // 82p; 390R // 10n
        xr = X + 1.4
        s.w((X, 9.2), (xr, 9.2)); s.dot((X, 9.2))
        s.two(elm.Capacitor, (xr, 9.2), (xr, 6.0), "C4\n33p", loc="bottom")
        emit = (X, 6.0)
        s.w(qe, emit, (xr, 6.0)); s.dot(emit)
        etap = (X, 3.4)
        s.two(elm.Resistor, emit, etap, "R3\n56R", loc="top")
        s.two(elm.Capacitor, (xr, 6.0), (xr, etap[1]), "C5\n82p", loc="bottom")
        s.w((xr, etap[1]), etap); s.dot(etap); s.dot((xr, etap[1]))
        s.two(elm.Resistor, etap, (X, 0.7), "R4\n390R", loc="bottom")
        s.gnd((X, 0.7))
        s.two(elm.Capacitor, (xr, etap[1]), (xr, 0.7), "C6\n10n", loc="bottom")
        s.gnd((xr, 0.7))

        # the switch's B (crystal) and C (emitter) sections, contacts above, lever on R (listen)
        sb_c, sb_r, sb_t = (3.6, 3.1), (3.1, 2.0), (4.1, 2.0)
        s.spdt(sb_c, sb_t, sb_r, "", side="down")
        s.text((3.6, 3.65), "SW1-B", fontsize=8, color=SWC)
        s.w(sb_t, b39)
        s.gnd(sb_r)
        xx = 2.0
        s.w(sb_c, (xx, sb_c[1]))
        s.two(elm.Crystal, (xx, sb_c[1]), (xx, 0.7), "X1\n27MHz", loc="top")
        s.gnd((xx, 0.7))
        sc_c, sc_r, sc_t = (7.0, 0.9), (6.5, 2.0), (7.5, 2.0)
        s.spdt(sc_c, sc_t, sc_r, "", side="up")
        s.text((7.65, 0.85), "SW1-C", fontsize=8, color=SWC, halign="left")
        s.w(b39, sc_r)
        s.w(sc_t, (sc_t[0], etap[1]), etap)
        s.gnd(sc_c)

        # SW1-A: the oscillator's supply from the T line (talk) or the R line (listen); 10n from SUP
        c2x = c1x + 1.3
        s.w((X, sup_y), (c2x, sup_y)); s.dot((c2x, sup_y))
        s.two(elm.Capacitor, (c2x, sup_y), (c2x, 0.7), "C2\n10n", loc="bottom")
        s.gnd((c2x, 0.7))
        sa_c, sa_t, sa_r = (c2x + 1.0, 15.6), (c2x + 1.9, TL), (c2x + 1.9, RL)
        s.w((c2x, sup_y), (sa_c[0], sup_y), sa_c)
        s.spdt(sa_c, sa_t, sa_r, "SW1-A", tpos=(-0.2, -0.65))

        # ================================================================ the R line: 4n7, 0.47u, 4k7
        x47 = sa_r[0] + 1.3
        s.w(sa_r, (x47, RL)); s.dot((x47, RL))
        s.two(elm.Capacitor, (x47, RL), (x47, 0.7), "C7\n4n7", loc="bottom")
        s.gnd((x47, 0.7))
        # the T line's 22n (crosses the R line)
        x22 = x47 + 1.4
        s.w(sa_t, (x22, TL)); s.dot((x22, TL))
        s.two(elm.Capacitor, (x22, TL), (x22, 0.7), "C8\n22n", loc="bottom")
        s.gnd((x22, 0.7))
        xc9 = x22 + 1.6
        s.w((x47, RL), (xc9, RL)); s.dot((xc9, RL))
        s.two(elm.Capacitor, (xc9, RL), (xc9, 13.2), "C9\n0.47u", loc="bottom", polar=True)
        vr = s.two(elm.Potentiometer, (xc9, 13.2), (xc9, 9.2))
        s.text((xc9 - 0.45, 11.6), "VR1\n10k", halign="right")
        s.text((xc9 - 0.45, 10.4), "VOL", color=NOTE, halign="right", fontsize=10)
        s.gnd((xc9, 9.2))
        wiper = (xc9 + 1.2, vr.tap[1])
        s.w(vr.tap, wiper); s.dot(wiper)
        x5 = xc9 + 5.0
        s.two(elm.Resistor, (xc9, RL), (x5, RL), "R5 4k7", loc="top")
        v2 = (x5 + 0.6, RL)
        s.w((x5, RL), v2); s.dot(v2)

        # ================================================================ Q2: the preamplifier
        s.w(wiper, (wiper[0], SP))
        s.two(elm.Capacitor, wiper, (wiper[0], 8.4), "C10\n39n", loc="bottom")
        s.two(elm.Resistor, (wiper[0], 8.4), (wiper[0], 5.0), "R6\n3k9", loc="bottom")
        b2 = (wiper[0], 3.4)
        s.w((wiper[0], 5.0), b2); s.dot(b2)
        s.two(elm.Capacitor, b2, (wiper[0], 0.7), "C12\n4n7", loc="bottom")
        s.gnd((wiper[0], 0.7))
        q2 = d.add(elm.BjtNpn(circle=True).right().scale(1.3).at((v2[0] - 0.98, b2[1])).anchor("base"))
        s.text((q2.center[0] - 1.1, q2.center[1] - 0.95), "Q2\nBC547", halign="right")
        s.w(b2, q2.base)
        s.gnd(q2.emitter)
        c2n_y = 7.0
        x1m, x220 = wiper[0] + 1.2, wiper[0] + 2.4
        s.two(elm.Resistor, (x1m, c2n_y), (x1m, b2[1]), "R7\n1M", loc="bottom")
        s.two(elm.Capacitor, (x220, c2n_y), (x220, b2[1]), "C11\n220p", loc="bottom")
        s.dot((x1m, b2[1])); s.dot((x220, b2[1]))
        c2n = (q2.collector[0], c2n_y)
        s.w(q2.collector, c2n); s.dot(c2n)
        s.w((x1m, c2n_y), c2n); s.dot((x220, c2n_y))
        # 5k6 from V2 (its lead crosses the speaker's wire above the body)
        s.w(v2, (v2[0], 13.4))
        s.two(elm.Resistor, (v2[0], 13.4), (v2[0], 9.4), "R8\n5k6", loc="bottom")
        s.w((v2[0], 9.4), c2n)
        x100 = v2[0] + 1.5
        s.w(v2, (x100, RL)); s.dot((x100, RL))
        s.w((x100, RL), (x100, 13.4))
        s.two(elm.Capacitor, (x100, 13.4), (x100, 11.4), "C13\n100u", loc="bottom", polar=True)
        s.gnd((x100, 11.4))
        xvp = x100 + 4.6
        s.two(elm.Resistor, (x100, RL), (xvp - 0.6, RL), "R9 220R", loc="top")

        # ================================================================ Q3 + Q4 (a Darlington pair) into T2
        q3 = d.add(elm.BjtNpn(circle=True).right().scale(1.3).at((x100 + 2.3, c2n_y)).anchor("base"))
        s.text((q3.center[0] - 0.55, q3.center[1] + 1.25), "Q3 BC547", halign="right")
        s.w(c2n, q3.base)
        x14 = x100 + 1.1
        s.dot((x14, c2n_y))
        s.two(elm.Capacitor, (x14, c2n_y), (x14, 0.7), "C14\n22n", loc="bottom")
        s.gnd((x14, 0.7))
        q4 = d.add(elm.BjtNpn(circle=True).right().scale(1.3).at((q3.emitter[0] + 0.8, c2n_y - 2.0)).anchor("base"))
        s.text((q4.center[0] + 0.95, q4.center[1] - 0.35), "Q4\nBC338", halign="left")
        s.w(q3.emitter, (q3.emitter[0], q4.base[1]), q4.base)
        cn = (q4.collector[0], 9.6)
        s.w(q3.collector, (q3.collector[0], cn[1]), cn)
        s.w(q4.collector, cn); s.dot(cn)
        e4 = (q4.emitter[0], q4.emitter[1] - 0.6)
        s.w(q4.emitter, e4); s.dot(e4)
        s.two(elm.Resistor, e4, (e4[0], 0.7), "R10\n100R", loc="bottom")
        s.gnd((e4[0], 0.7))
        x33 = e4[0] - 1.3
        s.w(e4, (x33, e4[1])); s.dot((x33, e4[1]))
        s.two(elm.Capacitor, (x33, e4[1]), (x33, 0.7), "C15\n33u", loc="top", polar=True)
        s.gnd((x33, 0.7))
        # the T line comes across and down to the collectors
        xt = q3.collector[0] + 0.0
        s.w((x22, TL), (cn[0] - 0.9, TL), (cn[0] - 0.9, cn[1])); s.dot((cn[0] - 0.9, cn[1]))
        # T2: primary from the supply rail to the collectors
        t2 = d.add(elm.Transformer(t1=6, t2=4, core=True).right().at((cn[0], 13.0)).anchor("p1"))
        s.w(t2.p2, cn)
        vp = (cn[0], RL)
        s.w(t2.p1, vp); s.dot(vp)
        s.w((xvp - 0.6, RL), vp)
        s.text((cn[0] + 0.5, 10.4), "T2", halign="left", fontsize=10)
        # the secondary: to the switch's D section; its other end to ground
        sd_r, sd_t, sd_c = (cn[0] + 2.6, t2.s1[1]), (cn[0] + 2.6, SP), (cn[0] + 3.6, (t2.s1[1] + SP) / 2)
        s.w(t2.s1, sd_r)
        s.w(t2.s2, (cn[0] + 1.9, t2.s2[1]), (cn[0] + 1.9, 0.0)); s.dot((cn[0] + 1.9, 0.0))
        s.spdt(sd_c, sd_t, sd_r, "SW1-D", tpos=(0.1, -0.75), side="left")
        s.w((wiper[0], SP), sd_t)
        s.text((wiper[0] + 5.2, SP + 0.35), "talk: the speaker into the amplifier", fontsize=8, color=SWC)
        xsp = sd_c[0] + 1.0
        s.w(sd_c, (xsp, sd_c[1]))
        spk = d.add(elm.Speaker().right().at((xsp, sd_c[1])).anchor("in1"))
        s.text((xsp + 0.2, sd_c[1] + 1.15), "SPK 8R\n(the microphone too)", halign="left")
        s.gnd(spk.in2)

        # power: the rail to the on/off switch and the 9 V battery
        xb = xsp + 4.0
        s.w(vp, (xb, RL))
        s.two(elm.Switch, (xb, RL), (xb, 12.4))
        s.text((xb + 0.75, 15.0), "SW2\non/off", halign="left")
        s.text((xb + 0.75, 13.6), "PWR", color=NOTE, halign="left", fontsize=10)
        s.two(elm.Battery, (xb, 12.4), (xb, 8.4), "BT1\n9V", loc="bottom", reverse=True)
        s.w((xb, 8.4), (xb, GND)); s.dot((xb, GND))
        # the display board's ribbon off the switched supply (and ground)
        xr = xb - 3.2
        s.dot((xr, RL)); s.w((xr, RL), (xr, RL + 1.2))
        d.add(elm.Dot(open=True).at((xr, RL + 1.2)))
        s.text((xr + 0.3, RL + 1.45), "display board's ribbon:\npower and ground only", fontsize=8, halign="left", color="#1f5fa8")

        # the ground rail
        s.w((0.6, GND), (xb, GND))
        d.add(elm.Ground().at((xb - 2.0, GND)))

        d.save(out + ".svg")
        d.save(out + ".png", dpi=110)


if __name__ == "__main__":
    build(sys.argv[1] if len(sys.argv) > 1 else "twoway")
