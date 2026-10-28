"""
make_preview.py: the Workshop preview picture for ZeD UI (Oct 19 2026).

Steam needs a 256 x 256 PNG of 1000 KB at most beside the item's Contents/
folder (the game's validateContents checks both). This builds it from the
mod's own art, no text on it:

  the graded desk   42/media/textures/ZeD/mainmenu/desk.png   (480 x 270)
  the wallpaper     the game's own title painting, read from the install's
                    media/ui/Title.png .. Title4.png (four tiles that fit into
                    1920 x 1080) and cut to the monitor's 4:3 as the menu does;
                    nothing of the game's art lives in the mod (Oct 28 2026)

The painting goes into the CRT's screen the way the main menu draws it
(ZeD_MainMenu.lua: tube at 120,30 size 240 x 180; a black dim over it;
scanlines), then a square is cut around the monitor.

Crops (--crop):
  monitor  (default) a 256 x 256 window of desk pixels at 1x, nothing resampled
           but the painting: the monitor with its picture, the case below.
  desk     the desk's full height (270 x 270) around the monitor, Lanczos down
           to 256 (a touch softer; shows the poster and the boombox edges).

Swap the art with --desk / --wallpaper (any desk picture keeps working while
its screen sits at --tube x,y,w,h); --game points at another install. Run:

  py -I ZeDUI/tools/release/make_preview.py
  py -I ZeDUI/tools/release/make_preview.py --crop desk --dim 0.45 --out other.png

Writes ZeDUI/tools/release/preview.png by default; stage_workshop.ps1 copies
it into Zomboid/Workshop/ZeD-UI/.
"""
import argparse
import os
import sys

from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
MOD = os.path.normpath(os.path.join(HERE, "..", "..", ".."))       # .../mods/ZeD-UI
ART = os.path.join(MOD, "42", "media", "textures", "ZeD", "mainmenu")

SIZE = 256
MAX_BYTES = 1000 * 1024
GAME = r"E:\Project Zomboid\SteamApps\common\ProjectZomboid"
# the painting's tiles and where each sits in the 1920 x 1080 picture; the menu's crop
WALL_TILES = (("Title.png", 0, 0), ("Title2.png", 1024, 0), ("Title3.png", 0, 1024), ("Title4.png", 1024, 1024))
WALL_CROP = (470, 0, 1910, 1080)


def game_wallpaper(game_dir):
    """The game's own title painting assembled from its tiles and cut to 4:3, or None."""
    ui = os.path.join(game_dir, "media", "ui")
    if not all(os.path.isfile(os.path.join(ui, n)) for n, _, _ in WALL_TILES):
        return None
    pic = Image.new("RGB", (1920, 1080))
    for n, x, y in WALL_TILES:
        pic.paste(Image.open(os.path.join(ui, n)).convert("RGB"), (x, y))
    return pic.crop(WALL_CROP)


def build(desk_path, wall_path, tube, dim, scan, crop, cx, top):
    desk = Image.open(desk_path).convert("RGB")
    tx, ty, tw, th = tube

    if wall_path:
        wall = wall_path if isinstance(wall_path, Image.Image) else Image.open(wall_path).convert("RGB")
        # fill the tube keeping the aspect (both 4:3 in ZeD's art), centred
        k = max(tw / wall.width, th / wall.height)
        sw, sh = max(tw, round(wall.width * k)), max(th, round(wall.height * k))
        wall = wall.resize((sw, sh), Image.LANCZOS)
        ox, oy = (sw - tw) // 2, (sh - th) // 2
        wall = wall.crop((ox, oy, ox + tw, oy + th))
        if dim > 0:
            wall = Image.blend(wall, Image.new("RGB", wall.size, (0, 0, 0)), dim)
        if scan > 0:   # every other row a little darker, as the menu's glass does
            px = wall.load()
            for y in range(0, th, 2):
                for x in range(tw):
                    r, g, b = px[x, y]
                    px[x, y] = (round(r * (1 - scan)), round(g * (1 - scan)), round(b * (1 - scan)))
        desk.paste(wall, (tx, ty))

    if crop == "monitor":
        side = SIZE
    else:
        side = min(desk.width, desk.height)
    x0 = max(0, min(desk.width - side, round(cx - side / 2)))
    y0 = max(0, min(desk.height - side, top if top is not None else (desk.height - side) // 2))
    out = desk.crop((x0, y0, x0 + side, y0 + side))
    if side != SIZE:
        out = out.resize((SIZE, SIZE), Image.LANCZOS)
    return out, (x0, y0, side)


def main():
    ap = argparse.ArgumentParser(description="Build the 256 x 256 Workshop preview from ZeD's desk art.")
    ap.add_argument("--desk", default=os.path.join(ART, "desk.png"))
    ap.add_argument("--game", default=GAME, help="the game's install folder (its media/ui holds the painting)")
    ap.add_argument("--wallpaper", default=None,
                    help="picture for the CRT's screen; '' leaves the screen as the desk has it")
    ap.add_argument("--tube", default="120,30,240,180", help="the screen in desk pixels: x,y,w,h")
    ap.add_argument("--dim", type=float, default=0.35,
                    help="black over the painting, 0..1 (the menu uses 0.55 behind its windows)")
    ap.add_argument("--scan", type=float, default=0.10, help="scanline darkening, 0..1")
    ap.add_argument("--crop", choices=("monitor", "desk"), default="monitor")
    ap.add_argument("--cx", type=float, default=240, help="crop centre x in desk pixels (the monitor's middle)")
    ap.add_argument("--top", type=int, default=8, help="crop top in desk pixels (monitor crop)")
    ap.add_argument("--out", default=os.path.join(HERE, "preview.png"))
    a = ap.parse_args()

    tube = tuple(int(v) for v in a.tube.split(","))
    # the painting: the game's own tiles unless --wallpaper names a picture ('' for none)
    wall = a.wallpaper if a.wallpaper is not None else game_wallpaper(a.game)
    if a.wallpaper is None and wall is None:
        print(f"no title painting under {a.game} (media/ui); the screen stays as the desk has it (--game points elsewhere)")
    img, (x0, y0, side) = build(a.desk, wall or None, tube, a.dim, a.scan, a.crop, a.cx,
                                a.top if a.crop == "monitor" else None)
    img.save(a.out, "PNG", optimize=True)

    size = os.path.getsize(a.out)
    check = Image.open(a.out)
    ok = check.size == (SIZE, SIZE) and check.format == "PNG" and size <= MAX_BYTES
    print("preview: %s  %dx%d  %s  %d bytes  (crop %s: %d px square at %d,%d of the desk)"
          % (a.out, check.width, check.height, check.mode, size, a.crop, side, x0, y0))
    if not ok:
        print("NOT VALID for the Workshop: needs a 256 x 256 PNG of 1000 KB at most", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
