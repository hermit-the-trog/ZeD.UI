"""Proof only (writes nothing in the repo): the D6 fan speedometer with the hub lifted and the sweep tightened.
usage (from tools/dashpx): py -3.14 C:\\Temp\\d6_proof.py out.png"""
import sys, os, math
sys.path.insert(0, os.getcwd())
import numpy as np
from PIL import Image
import designs as DZ
from dashlib import *
from widgets import window, glare, line_mask
from live import needle_pixels
from designs import lamp_col, L_GEN, L_BRAKE, L_BELTS, L_LT, L_HI, L_ENG, L_RT, RED

PCY, R, A0, A1 = 96, 62, 210, 330


def cl_d6_v2(b, bz="chrome", nd="#ff6a1a"):
    d = b.d
    sx, sy, sw, sh = 128, 22, 224, 66
    b.check_flat(sx - 1, sy - 1, sw + 2, sh + 2, "fan speedometer")
    face = window(d, sx, sy, sw, sh, 2.5, bezel=bz, r=3, bezel_t=2, on=Z_CL)
    pcx, pcy = 240, PCY
    for v in range(0, 101, 5):
        a = A0 + (A1 - A0) * v / 100.0
        ca, sa = math.cos(math.radians(a)), math.sin(math.radians(a))
        L = 6 if v % 10 == 0 else 3
        m = line_mask(d, pcx + ca * R, pcy + sa * R, pcx + ca * (R - L), pcy + sa * (R - L), 1.0) & face
        d.paint(m, "paint_r" if v == 55 else "paint_w")
        if v % 20 == 0:
            d.text(str(v), int(round(pcx + ca * (R - 14))), int(round(pcy + sa * (R - 14))) - 2, "paint_w", align="c")
    cap = np.hypot(d.XX + 0.5 - pcx, d.YY + 0.5 - pcy) <= 26
    capm = cap & face
    d.h[capm] = Z_CL - 1.0 + 1.6 * np.sqrt(np.clip(1 - (np.hypot(d.XX[capm] + 0.5 - pcx, d.YY[capm] + 0.5 - pcy) / 26.0) ** 2, 0, 1))
    d.mat[capm] = d.mid("blackp"); d.polish[capm] = 0.6; d.tex[capm] = 0
    d.text("MPH", pcx, pcy - 26 + 6, "paint_c", align="c", flatlight=True)      # on the shroud, under the needle's root
    glare(d, face, slope=-0.4, width=8, offset=0.12, amount=0.05)
    b.part("needle", src="speed_mph", max=100, cx=pcx, cy=pcy, r0=27, r1=R - 2, a0=A0, a1=A1, color=nd, w=2, hub=0)
    sq_dial(b, 58, 22, "fuel", "E", "F", "fuel", w=64, h=40, needle=nd, red_left=True, low_src="fuelLamp", bezel=bz)
    sq_dial(b, 58, 66, "temp", "C", "H", "temp", w=64, h=38, needle=nd, red_right=True, bezel=bz)
    sq_dial(b, 422, 22, "oil", "L", "H", "oil", w=64, h=40, needle=nd, bezel=bz)
    sq_dial(b, 422, 66, "volts", "8", "18", "batt", w=64, h=38, needle=nd, bezel=bz)
    lamp_col(b, 96, 24, 28, [L_GEN, L_BRAKE, L_BELTS, L_LT])
    lamp_col(b, 356, 24, 28, [L_HI, L_ENG, ("TEMP", "tempLamp", RED), L_RT])
    odometer(b, 225, 93)


DZ.cl_d6 = cl_d6_v2
rows = []
for did in ("d6", "fire"):
    title, cabin, seed, fn, *_ = DZ.DESIGNS[did]
    b = Build(did, cabin, seed=seed, title=title); fn(b)
    print(did, "warnings:", b.warnings)
    plate = np.array(b.d.render().convert("RGBA"))
    n = [p for p in b.parts if p["t"] == "needle" and p["src"] == "speed_mph"][0]
    tiles = []
    for f in (0.0, 0.25, 0.45, 0.55, 0.75, 1.0):
        im = plate.copy(); bad = 0
        a = n["a0"] + (n["a1"] - n["a0"]) * f
        body, edge = needle_pixels(n["cx"], n["cy"], a, n["r0"], n["r1"], 2, 0)
        for (x, y) in body | edge:
            nm = b.d.names[b.d.mat[y, x]]
            ok = nm in ("face",) or nm.startswith("paint") or nm == "blackp" and (x - 240) ** 2 + (y - PCY) ** 2 <= 27 * 27
            im[y, x] = (255, 106, 26, 255) if ok else (255, 0, 255, 255); bad += not ok
        print(f"  {did} {f * 100:.0f} mph: {bad} px off the face")
        tiles.append(im[18:112, 124:356])
    rows.append(np.concatenate(tiles, axis=1))
sheet = np.concatenate(rows, axis=0)
Image.fromarray(sheet).resize((sheet.shape[1] * 2, sheet.shape[0] * 2), Image.NEAREST).save(sys.argv[1])
