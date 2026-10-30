"""Round 1 of the maker emblems (proof, nothing in the repo): two concepts per maker, each beside its wordmark plate,
painted through the dash engine at the size a dash shows them (20 px tall).
usage (from tools/dashpx): py -3.14 C:\\Temp\\emblems_r1.py out_prefix"""
import sys, os, math
sys.path.insert(0, os.getcwd())
import numpy as np
from PIL import Image
from engine import Dash, text_w

S = 20                                   # an emblem's height
ROW_H, PAD = 30, 8
NAMES = ["CHEVALIER", "DASH", "FRANKLIN", "MERCIA", "MASTERSON"]
CELL_W = 22 + 4 + text_w("MASTERSON", "57") + 10 + 18
W, H = PAD * 2 + CELL_W * 2, PAD * 2 + ROW_H * len(NAMES)
d = Dash(W, H, seed=3)
M = d.M
BASE = 5.0
bg = np.ones((H, W), bool)
d.slab(bg, BASE, "v_charcoal", bevel=0.1, polish=0.15, on=0.0)


def P(x, y, pts): return [(x + a, y + b) for a, b in pts]
def circ(cx, cy, r): return M().ellipse(cx, cy, r, r).get()
def emb(mask, z, mat, polish=0.9, bevel=0.8): d.slab(mask, z, mat, bevel=bevel, polish=polish, on=BASE)


def rim(outer, inner, z=2.0): emb(outer & ~inner, z, "chrome", 1.0)


# ------------------------------------------------------------------ Chevalier (the Chevrolet parody): heraldic, gold
def chev_a(x, y):      # a heater shield, gold, a chrome chevron across it (the heraldic chevron: CHEValier)
    sh = M().poly(P(x, y, [(1, 0), (19, 0), (19, 9), (16, 15), (10, 20), (4, 15), (1, 9)])).get()
    inner = M().poly(P(x, y, [(2.5, 1.5), (17.5, 1.5), (17.5, 9), (15, 14), (10, 18.3), (5, 14), (2.5, 9)])).get()
    rim(sh, inner); emb(inner, 1.2, "paint_y", 0.8)
    cv = M().poly(P(x, y, [(2, 13), (10, 5), (18, 13), (18, 16.5), (10, 8.5), (2, 16.5)])).get() & inner
    emb(cv, 2.2, "chrome", 1.0)


def chev_b(x, y):      # a chrome roundel, a gold knight (the chess piece) on black: the chevalier himself
    o, i = circ(x + 10, y + 10, 10), circ(x + 10, y + 10, 8.4)
    rim(o, i); emb(i, 0.8, "blackp", 0.5)
    kn = M().poly(P(x, y, [(6, 17), (7, 13), (5.5, 12), (4.5, 10), (6, 7.5), (8, 5.5), (9, 3), (10.5, 5), (13, 6),
                           (14.5, 9), (15, 13), (14, 17)])).get()
    emb(kn & i, 2.0, "paint_y", 0.9)
    eye = (d.XX == x + 9) & (d.YY == y + 8); d.dark[eye] = 0.6


# ------------------------------------------------------------------ Dash (the Chrysler parody): upright, engineered
def dash_a(x, y):      # a forward-leaning bar in red enamel, two chrome speed lines: the dash itself
    o = M().poly(P(x, y, [(5, 3), (21, 3), (17, 17), (1, 17)])).get()
    i = M().poly(P(x, y, [(6.3, 4.5), (19.2, 4.5), (16, 15.5), (3, 15.5)])).get()
    rim(o, i); emb(i, 1.0, "paint_r", 0.6)
    for yy in (8, 11.5):
        ln = M().poly(P(x, y, [(4.5 + (17 - yy) * 0.28 - 1, yy), (18.5 + (17 - yy) * 0.28 - 1, yy),
                               (18.5 + (17 - yy - 1.5) * 0.28 - 1, yy + 1.5), (4.5 + (17 - yy - 1.5) * 0.28 - 1, yy + 1.5)])).get() & i
        emb(ln, 2.0, "chrome", 1.0)


def dash_b(x, y):      # an upright hexagon, a geometric D in chrome: a stamp off an engineering drawing
    o = M().poly(P(x, y, [(10, 0), (19, 5), (19, 15), (10, 20), (1, 15), (1, 5)])).get()
    i = M().poly(P(x, y, [(10, 1.8), (17.4, 6), (17.4, 14), (10, 18.2), (2.6, 14), (2.6, 6)])).get()
    rim(o, i); emb(i, 0.8, "blackp", 0.5)
    dd = M().poly(P(x, y, [(6, 5), (11, 5), (14.5, 8), (14.5, 12), (11, 15), (6, 15)])).get()
    dh = M().poly(P(x, y, [(8.4, 7.4), (10.4, 7.4), (12.1, 9), (12.1, 11), (10.4, 12.6), (8.4, 12.6)])).get()
    emb(dd & ~dh, 2.0, "chrome", 1.0)


# ------------------------------------------------------------------ Franklin (the Ford parody, Louisville's own): plain, blue
def frank_a(x, y):     # a plain blue enamel plate, square-cornered, a white block F: no nonsense
    o = M().rrect(x, y + 3, 22, 14, 2).get(); i = M().rrect(x + 1, y + 4, 20, 12, 1).get()
    rim(o, i); emb(i, 1.0, "v_patrol", 0.6)
    f = M().rect(x + 7, y + 6, 3, 8).get() | M().rect(x + 7, y + 6, 9, 2).get() | M().rect(x + 7, y + 9, 6, 2).get()
    emb(f, 2.0, "paint_w", 0.4)


def frank_b(x, y):     # Ben Franklin's kite: a blue diamond, a chrome bolt across it
    o = M().poly(P(x, y, [(10, 0), (19, 8), (10, 20), (1, 8)])).get()
    i = M().poly(P(x, y, [(10, 2), (17, 8), (10, 18), (3, 8)])).get()
    rim(o, i); emb(i, 1.0, "v_patrol", 0.6)
    bolt = M().poly(P(x, y, [(12.5, 2.5), (6.5, 10.5), (10, 10.5), (7.5, 17.5), (13.8, 8.8), (10.3, 8.8)])).get()
    emb(bolt & i, 2.2, "paint_y", 0.9)


# ------------------------------------------------------------------ Mercia (the Mercedes parody): restrained roundel
def merc_a(x, y):      # the old kingdom of Mercia's arms: a gold saltire on blue, in a fine chrome ring
    o, i = circ(x + 10, y + 10, 10), circ(x + 10, y + 10, 8.8)
    rim(o, i, 1.6); emb(i, 0.8, "v_navy", 0.6)
    s = M().poly(P(x, y, [(4, 5.5), (5.5, 4), (16, 14.5), (14.5, 16)])).get() | M().poly(P(x, y, [(14.5, 4), (16, 5.5), (5.5, 16), (4, 14.5)])).get()
    emb(s & i, 1.8, "paint_y", 0.9)


def merc_b(x, y):      # a fine chrome ring around a chrome M of two peaks, nothing else
    o, i = circ(x + 10, y + 10, 10), circ(x + 10, y + 10, 8.8)
    rim(o, i, 1.6); emb(i, 0.8, "blackp", 0.6)
    m = M().poly(P(x, y, [(4.5, 14.5), (4.5, 6), (6.5, 6), (10, 10.5), (13.5, 6), (15.5, 6), (15.5, 14.5), (13.5, 14.5),
                          (13.5, 9.5), (10, 13.5), (6.5, 9.5), (6.5, 14.5)])).get()
    emb(m & i, 2.0, "chrome", 1.0)


# ------------------------------------------------------------------ Masterson (fictional): the oddball
def mast_a(x, y):      # a rising sun over the horizon in a rounded square: very 1985
    o = M().rrect(x + 1, y + 1, 18, 18, 4).get(); i = M().rrect(x + 2.5, y + 2.5, 15, 15, 3).get()
    rim(o, i); emb(i, 0.8, "blackp", 0.5)
    sun = circ(x + 10, y + 10, 6.5) & i                      # a sunset sun, its lower half cut by black bands
    for gy in (11, 13, 15): sun &= ~(d.YY == y + gy)
    emb(sun, 1.6, "paint_o", 0.7)


def mast_b(x, y):      # a chrome diamond with a four-point star: the master's mark, a compass
    o = M().poly(P(x, y, [(10, 0), (20, 10), (10, 20), (0, 10)])).get()
    i = M().poly(P(x, y, [(10, 2), (18, 10), (10, 18), (2, 10)])).get()
    rim(o, i); emb(i, 0.8, "v_burgundy", 0.6)
    st = M().poly(P(x, y, [(10, 2.8), (11.8, 8.2), (17.2, 10), (11.8, 11.8), (10, 17.2), (8.2, 11.8), (2.8, 10), (8.2, 8.2)])).get()
    emb(st & i, 2.0, "chrome", 1.0)


def wordmark(x, y, t):
    w = text_w(t, "57") + 8
    pl = M().rrect(x, y + 3, w, 14, 1).get()
    d.slab(pl, 1.0, "alu", bevel=0.8, polish=0.6, on=BASE)
    d.text(t, x + 4, y + 6, "paint_k", font="57")


def main():
  ROWS = [("CHEVALIER", chev_a, chev_b), ("DASH", dash_a, dash_b), ("FRANKLIN", frank_a, frank_b),
          ("MERCIA", merc_a, merc_b), ("MASTERSON", mast_a, mast_b)]
  for r, (name, fa, fb) in enumerate(ROWS):
      y = PAD + r * ROW_H + 4
      for c, f in enumerate((fa, fb)):
          x = PAD + c * CELL_W
          f(x, y)
          wordmark(x + 26, y, name)
  
  img = d.render().convert("RGBA")
  pre = sys.argv[1]
  img.save(pre + "_1x.png")
  for k in (2, 4): img.resize((W * k, H * k), Image.NEAREST).save(pre + f"_{k}x.png")
  print(W, H)
  
  
if __name__ == "__main__": main()
