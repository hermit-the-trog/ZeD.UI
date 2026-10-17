"""The game speed control when no watch is worn (director, Oct 16 2026): just a boom box tape deck's keys, nothing
around them. PAUSE, PLAY, FAST FORWARD and the faster one; the key for the game's speed sits pressed down, the others
stand up. Each key's front face shows below its top the way a boom box's keys lean toward you; pressed, the top sinks
and the front shortens.

Plate parts: none live but the four state pictures (speed0 .. speed3, one key down each); click areas speed0 ..
speed3 (ZeD_Watch sets the game speed from the id).
"""
from physlib import *            # noqa: F401,F403
from engine import add_ramp

add_ramp("key_top", "#c9ccd0", light=1.12)        # brushed silver key cap
add_ramp("key_front", "#6b6e73")                  # the cap's front face, in its own shade
add_ramp("key_icon", "#1c1d20")
add_ramp("slot", "#141416")

N = 4
KW, KH, GAP = 26, 22, 2          # a key's footprint (top + front), the gap between keys
W, H = 2 + N * KW + (N - 1) * GAP + 2, KH + 4
UP_TOP, DOWN_DROP = 13, 3        # an up key's top face height; how far a pressed one drops


def key(p, i, down):
    d = p.d
    x = 2 + i * (KW + GAP)
    y0 = 2 + (DOWN_DROP if down else 0)
    top_h = UP_TOP
    front_h = KH - UP_TOP - (DOWN_DROP if down else 0)
    z = Z_FACE + (1.0 if down else 2.6)
    # the slot the key rides in (dark, so a pressed key leaves no gap that shows through: every state is opaque)
    slot = Mask(W, H).rect(x - 1, 1, KW + 2, KH + 2).get()
    d.slab(slot, Z_FACE - 1.5, "blackp", bevel=0.4, polish=0.2)
    # the front face first (a band under the top), then the top over it
    front = Mask(W, H).rrect(x, y0 + top_h - 1, KW, front_h + 1, 1).get()
    d.slab(front, z - 0.8, "key_front", bevel=0.6, polish=0.4)
    top = Mask(W, H).rrect(x, y0, KW, top_h, 1).get()
    d.slab(top, z, "key_top", bevel=1.0, polish=0.7)
    d.grain_brushed(top, 0.04, seed=31 + i)
    cx, cy = x + KW / 2, y0 + top_h / 2
    ix, iy = int(cx), int(cy) - 3                  # icons drawn pixel by pixel, 7 px tall
    if i == 0:                                     # PAUSE: two bars
        d.paint(rbox(d, ix - 3, iy, 2, 7), "key_icon", flatlight=True)
        d.paint(rbox(d, ix + 1, iy, 2, 7), "key_icon", flatlight=True)
    else:                                          # PLAY, then one more arrow per step
        n = i
        x0 = ix - (n * 4) // 2
        for k in range(n):
            for row, wd in enumerate((1, 2, 3, 4, 3, 2, 1)):
                d.paint(rbox(d, x0 + k * 4, iy + row, wd, 1), "key_icon", flatlight=True)
    p.hit(f"speed{i}", x, 2, KW, KH)


def speed_keys(pressed=None, worn=True):
    p = Plate("speed_keys", W, H, seed=29, title="no-watch speed keys")
    for i in range(N):
        key(p, i, pressed == i)
    return p


def state(speed):
    return {f"speed{i}": speed == i for i in range(N)}
