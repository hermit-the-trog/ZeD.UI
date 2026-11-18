"""Noise, Nov 17 (the director: "What about a twig breaking? Just snapping in half with an exclamation point rising from
the snapping point. And then, of course, all the other lines showing that it is broken." Then: "You stepped on it, not
kicked it upward.") A twig stepped on: the break pushed down, the two halves rising from it in a V, a gap between them,
the pale wood showing at the splintered ends, a side stub so it reads as a twig; the ! rising out of the snap, red;
a snap line out to each side, two pixels clear of the ! (the director: "Diagonal lines are too close to exclamation
point. Make exclamation point red.")"""
import fix_icons as F

def twig(W=22, H=15):
    g = [["."] * W for _ in range(H)]
    def put(x, y, c):
        if 0 <= x < W and 0 <= y < H: g[y][x] = c
    for x in range(1, 9):                                       # the left half: two pixels thick, down to the break
        top = 8 + (x - 1) // 2
        put(x, top, "s"); put(x, top + 1, "S")
    for x in range(13, 21):                                     # the right half, up from the break
        top = 11 - (x - 13) // 2
        put(x, top, "s"); put(x, top + 1, "S")
    put(8, 11, "w"); put(8, 12, "w"); put(8, 13, "w")           # the left end: pale end grain, a splinter pushed down
    put(13, 10, "w"); put(13, 11, "w"); put(13, 12, "w")        # the right end: end grain, a splinter sticking up
    put(17, 8, "s"); put(18, 7, "s")                            # a side stub on the right half, so it reads as a twig
    g = F.outline(g, "Ssw")
    for y in range(1, 7): put(10, y, "R"); put(11, y, "R")      # the !, red, rising out of the snap
    put(10, 8, "R"); put(11, 8, "R")
    for x, y in ((5, 4), (6, 5), (7, 6), (16, 4), (15, 5), (14, 6)):   # the snap lines, two pixels clear of the !
        put(x, y, "k")
    return ["".join(r) for r in g]

if __name__ == "__main__":
    for r in twig(): print(r)
