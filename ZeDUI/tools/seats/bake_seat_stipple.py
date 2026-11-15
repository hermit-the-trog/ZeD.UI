"""The seat pop-out's stipple (Nov 15 2026, seat pop-out): a seat that can't be reached from here gets a 50% black
stipple over it (the handoff's seat states). One stipple per seat shape, read off the baked seats' own outline (the
shapes are the same in every interior color): a black pixel where the seat has a pixel and (x + y) is even.

    python bake_seat_stipple.py POPOUT_DIR      (the folder bake_seat_popout.py writes: .../textures/ZeD/seats/popout)

writes POPOUT_DIR/stip_bucket.png, stip_half.png, and the bench's two places, stip_bench_l.png and stip_bench_r.png
(the bench split where its seam is: 1 px margin + seat_w + gap / 2)."""
import os
import sys
from PIL import Image

SEAT_W, GAP = 46, 8


def stipple(src):
    im = Image.open(src).convert("RGBA")
    out = Image.new("RGBA", im.size, (0, 0, 0, 0))
    a = im.getchannel("A").load()
    o = out.load()
    for y in range(im.height):
        for x in range(im.width):
            if a[x, y] > 0 and (x + y) % 2 == 0:
                o[x, y] = (0, 0, 0, 255)
    return out


def main(d):
    seat = os.path.join(d, "seat")
    stipple(os.path.join(seat, "v_navy_bucket.png")).save(os.path.join(d, "stip_bucket.png"))
    stipple(os.path.join(seat, "v_navy_half.png")).save(os.path.join(d, "stip_half.png"))
    bench = stipple(os.path.join(seat, "v_navy_bench.png"))
    cut = 1 + SEAT_W + GAP // 2
    bench.crop((0, 0, cut, bench.height)).save(os.path.join(d, "stip_bench_l.png"))
    bench.crop((cut, 0, bench.width, bench.height)).save(os.path.join(d, "stip_bench_r.png"))
    print("stipple written to", d)


if __name__ == "__main__":
    main(sys.argv[1])
