"""Bakes the seat picker pop-out's art (the director, Nov 15 2026: the cabin alone, no window frame; interior only, the
floor, the dashboard and the seats in the vehicle's own interior colour; the dashboard a mini of its own ZeD dashboard
at the same pixel size). Every picture is 1 art pixel a pixel; the game draws them at a whole number of screen pixels
an art pixel (nearest), laid on in the order of seat_cabin.cabin(): floor, dashboard, seats, console, people, things,
wheel. Parts carry a 1 px margin for their outline: a part's (x, y) in layout.json is where its margin's corner goes.

usage: python bake_seat_popout.py OUTDIR      (ZeDUI/tools/dashpx beside this folder, or ZED_DASHPX=...)
writes OUTDIR/textures/ZeD/seats/popout/... and OUTDIR/layout.json"""
import json
import os
import sys
import time
from PIL import Image
import seat_cabin as CB
import minidash as MD
import colors

ROWS_MAX = 5


def main(out):
    tex = os.path.join(out, "textures", "ZeD", "seats", "popout")
    for sub in ("", "dash", "floor", "seat"): os.makedirs(os.path.join(tex, sub), exist_ok=True)
    cabs = sorted({c for cs in colors.COLORS.values() for _, c in cs})
    t0 = time.time()
    # the mini dashboards: one per dashboard design and interior colour (colors.COLORS: the choices the game offers)
    dashes = []
    for did, cs in colors.COLORS.items():
        for _, cab in cs:
            n = f"{did}__{cab}"
            CB.mini(n).save(os.path.join(tex, "dash", n + ".png")); dashes.append(n)
    print(f"{len(dashes)} mini dashboards, {time.time() - t0:.0f}s", flush=True)
    # per interior colour: the floor for 1..ROWS_MAX rows, a bucket seat, a whole bench (split), a bench's half
    for cab in cabs:
        seat_m, carpet_m, tub_m = CB.interior(cab)
        for r in range(1, ROWS_MAX + 1):
            CB.floor_part(["bench"] * r, carpet_m, tub_m).save(os.path.join(tex, "floor", f"{cab}_{r}.png"))
        CB.seat_part(CB.SEAT_W, CB.SEAT_H, seat_m).save(os.path.join(tex, "seat", f"{cab}_bucket.png"))
        CB.seat_part(2 * CB.SEAT_W + CB.GAP, CB.SEAT_H, seat_m, bench_split=True).save(os.path.join(tex, "seat", f"{cab}_bench.png"))
        CB.seat_part(CB.SEAT_W + CB.GAP // 2, CB.SEAT_H, seat_m).save(os.path.join(tex, "seat", f"{cab}_half.png"))
    # the same for every vehicle
    CB.dummy_part(True).save(os.path.join(tex, "dummy_you.png"))
    CB.dummy_part(False).save(os.path.join(tex, "dummy_other.png"))
    CB.bag_part().save(os.path.join(tex, "bag.png"))
    CB.box_part().save(os.path.join(tex, "box.png"))
    CB.console_part(CB.SEAT_H - 8).save(os.path.join(tex, "console.png"))
    CB.wheel_part().save(os.path.join(tex, "wheel.png"))
    L = dict(
        note="art pixels; a part's x, y is where its 1 px margin's top-left goes (seat_cabin.lay: x - 1, y - 1)",
        box_w=CB.BW, rim=CB.IN, dash=dict(x=CB.IN, y=CB.IN, w=CB.DASH_W, h=CB.DASH_H, margin=0),
        well=CB.WELL, row_pitch=CB.ROW, pad=CB.PAD, seat_w=CB.SEAT_W, seat_h=CB.SEAT_H, gap=CB.GAP, left_x=CB.LX,
        first_row_y=CB.top(), box_h={str(r): CB.top() + r * CB.ROW + CB.PAD for r in range(1, ROWS_MAX + 1)},
        seat_left=dict(x="left_x", y="first_row_y + row * row_pitch"),
        seat_right=dict(x="left_x + seat_w + gap", y="first_row_y + row * row_pitch"),
        bench=dict(x="left_x", w="2 * seat_w + gap", split_at="seat_w + gap / 2"),
        half_left=dict(x="left_x", w="seat_w + gap / 2"), half_right=dict(x="left_x + seat_w + gap / 2", w="seat_w + gap / 2"),
        console=dict(x="left_x + seat_w + 1", y="row 0 y + 2", only="the front row when it is two buckets"),
        dummy=dict(x="seat x + seat w / 2 - 20", y="seat y - 6", art="dummy_you (the player) / dummy_other (anyone else)"),
        bag=dict(x="seat x + 20", y="seat y + 21"), box=dict(x="seat x + 6", y="seat y + 18", over="bag"),
        wheel=dict(x="left_x + seat_w / 2 - 12.5", y="rim + dash.h - 2", only="while the driver's seat is fitted"),
        key=dict(cx="seat x + seat w / 2", cy="seat y + 12", what="the seat's keycap: free, blocked, items, not fitted; the focused one in the accent"),
        dashes=dashes, cabins=cabs, rows_max=ROWS_MAX,
    )
    with open(os.path.join(out, "layout.json"), "w") as f: json.dump(L, f, indent=1)
    print(f"done, {time.time() - t0:.0f}s: {tex}")


if __name__ == "__main__":
    main(sys.argv[1] if len(sys.argv) > 1 else "out_seat_popout")
