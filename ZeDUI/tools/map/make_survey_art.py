"""make_survey_art.py - the Survey map's small pictures (Nov 18 2026, Build).

Writes, under 42/media/textures/ZeD/map/:
  woods_dark.png, woods_light.png, woods_hicon.png
      A 16 x 16 tile of tree marks on the theme's forest colour. MapsSurvey.lua lays it over the forest shapes in
      screen pixels (as the game lays its colour blind patterns), so the marks stay the same size at every zoom.
      The colours are MapsSurvey.lua's palette (forest, mark): keep the two in step.
  shield_us.png, shield_ky.png, shield_i.png
      The route shields' shapes, white with a black edge (the interstate's blue and red), 24 x 24, drawn stretched
      to fit the route's number. Pixel art: the game draws them with nearest filtering.

Run from the repo root:  python ZeDUI/tools/map/make_survey_art.py
"""
import os
from PIL import Image

OUT = os.path.join("42", "media", "textures", "ZeD", "map")

# MapsSurvey.lua's palette: (forest, mark)
WOODS = {
    "dark": ("1F3324", "96D2A0"),
    "light": ("B9D2A4", "2F5D2A"),
    "hicon": ("002A0E", "8CFFAA"),
}


def hexrgb(h):
    return tuple(int(h[i:i + 2], 16) for i in (0, 2, 4))


def woods(base, mark):
    """Two small trees per tile (a round crown on a one-pixel trunk), staggered so the rows don't line up."""
    im = Image.new("RGBA", (16, 16), hexrgb(base) + (255,))
    px = im.load()
    m = hexrgb(mark) + (255,)
    crown = [(-1, -1), (0, -1), (1, -1), (-1, 0), (0, 0), (1, 0), (0, -2), (-2, 0), (2, 0), (-1, 1), (0, 1), (1, 1)]
    for cx, cy in ((4, 4), (12, 12)):
        for dx, dy in crown:
            px[(cx + dx) % 16, (cy + dy) % 16] = m
        px[cx % 16, (cy + 2) % 16] = m   # the trunk
    return im


def shield_us():
    """The US route shield: a flat top with two shoulders, sides that run in, a point at the foot."""
    im = Image.new("RGBA", (24, 24), (0, 0, 0, 0))
    px = im.load()
    rows = []
    for y in range(24):
        if y < 3:
            l, r = 3, 20          # the shoulders
        elif y < 15:
            l, r = 1, 22
        else:
            k = y - 15            # the sides run in to the point
            l, r = 1 + k, 22 - k
        rows.append((l, r))
    for y, (l, r) in enumerate(rows):
        if l > r:
            continue
        for x in range(l, r + 1):
            px[x, y] = (255, 255, 255, 255)
    # the black edge: any filled pixel next to an empty one
    edge = []
    for y in range(24):
        for x in range(24):
            if px[x, y][3] == 0:
                continue
            for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                nx, ny = x + dx, y + dy
                if not (0 <= nx < 24 and 0 <= ny < 24) or px[nx, ny][3] == 0:
                    edge.append((x, y))
                    break
    for x, y in edge:
        px[x, y] = (0, 0, 0, 255)
    return im


def shield_ky():
    """A state route: a white circle with a black ring."""
    im = Image.new("RGBA", (24, 24), (0, 0, 0, 0))
    px = im.load()
    c, r = 11.5, 11.0
    for y in range(24):
        for x in range(24):
            d = ((x - c) ** 2 + (y - c) ** 2) ** 0.5
            if d <= r:
                px[x, y] = (0, 0, 0, 255) if d > r - 1.3 else (255, 255, 255, 255)
    return im


def shield_i():
    """The interstate: the US shield's shape, a red band over blue, a white edge."""
    im = shield_us()
    px = im.load()
    for y in range(24):
        for x in range(24):
            a = px[x, y]
            if a[3] == 0:
                continue
            if a[:3] == (0, 0, 0):
                px[x, y] = (255, 255, 255, 255)
            else:
                px[x, y] = (190, 30, 45, 255) if y < 6 else (0, 61, 165, 255)
    return im


def main():
    os.makedirs(OUT, exist_ok=True)
    for name, (base, mark) in WOODS.items():
        woods(base, mark).save(os.path.join(OUT, "woods_%s.png" % name))
    shield_us().save(os.path.join(OUT, "shield_us.png"))
    shield_ky().save(os.path.join(OUT, "shield_ky.png"))
    shield_i().save(os.path.join(OUT, "shield_i.png"))
    print("wrote", sorted(f for f in os.listdir(OUT) if f.startswith(("woods_", "shield_"))))


if __name__ == "__main__":
    main()
