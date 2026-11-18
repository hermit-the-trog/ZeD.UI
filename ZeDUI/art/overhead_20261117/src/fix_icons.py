"""Nov 17 fixes (the director: "Fix the sword handle and the bones. The bones need joints."): the PvP skull's crossbones
get a knobbed joint at each end (two lobes and the cleft between); the nearly-broken weapon gets a real hilt
(a brass crossguard square to the blade, a wrapped grip on the blade's line, a pommel)."""

def outline(g, fillchars):
    h, w = len(g), len(g[0]); out = [r[:] for r in g]
    for y in range(h):
        for x in range(w):
            if g[y][x] != ".": continue
            for dy, dx in ((0, 1), (0, -1), (1, 0), (-1, 0)):
                yy, xx = y + dy, x + dx
                if 0 <= yy < h and 0 <= xx < w and g[yy][xx] in fillchars: out[y][x] = "k"; break
    return out

SKULL = ["..kkkkkk..",
         ".kwwwwwwk.",
         "kwwwwwwwwk",
         "kwrrwwrrwk",
         "kwrrwwrrwk",
         "kwwwkkwwwk",
         ".kwwwwwwk.",
         "..kwkkwk..",
         "..kkkkkk.."]

def skull(N=18, sx=4, sy=4):
    g = [["."] * N for _ in range(N)]
    def put(x, y):
        for xx, yy in ((x, y), (N - 1 - x, y), (x, N - 1 - y), (N - 1 - x, N - 1 - y)): g[yy][xx] = "w"
    # one corner's bone end (mirrored to all four): two 2x2 lobes, the cleft between them, the shaft toward the middle
    for x, y in ((3, 1), (4, 1), (3, 2), (4, 2), (1, 3), (2, 3), (1, 4), (2, 4)): put(x, y)
    for i in range(3, 9): put(i, i); put(i + 1, i) if i + 1 < N // 2 else None
    g = outline(g, "w")
    for y, r in enumerate(SKULL):
        for x, ch in enumerate(r):
            if ch != ".": g[sy + y][sx + x] = ch
    return ["".join(r) for r in g]

def sword(N=17):
    g = [["."] * N for _ in range(N)]
    def put(x, y, c):
        if 0 <= x < N and 0 <= y < N: g[y][x] = c
    put(15, 1, "m")                                            # the tip
    for y in range(2, 10):                                     # the blade, 45 degrees: spine shaded, edge bright
        put(15 - y, y, "M"); put(16 - y, y, "m")
    put(11, 5, "k"); put(12, 4, "n")                           # the crack: a nick through the edge, a dull chip by it
    for x, y in ((3, 8), (4, 9), (5, 10), (6, 11), (7, 12)): put(x, y, "Y")   # the crossguard, square to the blade
    for x, y in ((4, 8), (5, 9), (6, 10), (7, 11), (8, 12)): put(x, y, "y")
    for x, y, c in ((4, 11, "S"), (5, 11, "s"), (3, 12, "s"), (4, 12, "S"), (2, 13, "S"), (3, 13, "s")): put(x, y, c)  # the grip, wrapped
    for x, y, c in ((1, 14, "y"), (2, 14, "y"), (0, 15, "y"), (1, 15, "Y"), (2, 15, "Y"), (1, 16, "Y")): put(x, y, c)  # the pommel
    g = outline(g, "mMySsYn")
    return ["".join(r) for r in g]

if __name__ == "__main__":
    for r in skull(): print(r)
    print()
    for r in sword(): print(r)
