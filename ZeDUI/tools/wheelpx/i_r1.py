"""Round 1 of the icon redraw (the director, Nov 16 2026): "better represent the action ... More diverse in layout, so
it's easier to distinguish apart from others ... no two icons look alike, with exception for when there are multiple
actions like pick up, put down ... finding more opportunities to accent with red, yellow, and blue ... Icons can only
have ink and one of the three accent colors."
Round 1b, the same day: "take one more pass at just refining every shape, making sure accents run along lines that make
sense ... on the knife ... it should be along the sharp edge of the blade at the bottom ... a few pixel tweaks here and
there ... another smoothing pass".

Every icon here: ink, plus at most one accent, drawn on the mark layer (c.mark()); ACCENT says which color. The
accent sits on the part that carries the meaning, and follows that part's own line (the knife's edge, the crack, the
water, the arrow):
  blue  water and cold; the giving side of a pair (add, take, in, on, open, pick up)
  red   harm and danger (attack, destroy, wounds); the taking-away side of a pair (remove, put, drop, out, off)
  gold  energy and value (fire, light, heat, power, fuel; favorite, locked and kept)
Layouts vary on purpose: an object alone, a tool at work on something, a thing and where it goes, a figure, a result.
HOLES: accents drawn into what used to be a cut-out; in one color (pointed, no color) they stay cut out.
"""
import math
from kit import icon, ICONS

ACCENT = {}
HOLES = {"r_medkit"}


def acc(id_, kind):
    ACCENT[id_] = kind


def G(c, rows, ox=0, oy=0):
    """hand-placed pixels: '#' ink, '*' accent (ink on the mark layer too), 'o' cut clear, anything else left alone"""
    for y, row in enumerate(rows):
        for x, ch in enumerate(row):
            if ch == "#": c.rect(ox + x, oy + y, 1, 1)
            elif ch == "*":
                with c.mark(): c.rect(ox + x, oy + y, 1, 1)
            elif ch == "o": c.rect(ox + x, oy + y, 1, 1, v=0)


def carton(c, s, x, y, w, h):
    """a closed carton seen from the front: its lid seam, the tape's gap across the lid"""
    c.rect(x, y, w, h)
    if s == 24: c.rect(x, y + 3, w, 1, v=0); c.rect(x + w // 2 - 1, y, 2, 3, v=0)
    else: c.rect(x, y + 2, w, 1, v=0); c.rect(x + w // 2 - 1, y, 2, 2, v=0)


# ============================================================ the item menu
@icon("r_favorite", "r1", "a star, gold: favorite", [])
def r_favorite(c, s):
    with c.mark(): ICONS["star"]["fn"](c, s)
acc("r_favorite", "gold")


@icon("r_place", "r1", "a carton not yet placed, an arrow under it down to the shelf it goes on: place", [])
def r_place(c, s):
    # the director, Nov 16: "the arrow should be below the object. You haven't placed it yet. So you have an object
    # that is unplaced with an arrow pointing to where it's going."
    if s == 24:
        carton(c, s, 5, 1, 14, 8)
        G(c, ["...**...", "...**...", "...**...", "********", ".******.", "..****..", "...**..."], 8, 11)
        c.rect(1, 20, 22, 3)
    else:
        carton(c, s, 3, 1, 10, 5)
        G(c, ["..*..", "..*..", "*****", ".***.", "..*.."], 6, 7)
        c.rect(1, 13, 14, 2)
acc("r_place", "red")


@icon("r_pick_up", "r1", "the carton on its shelf, an arrow over it up to where it goes: pick up", [])
def r_pick_up(c, s):
    if s == 24:
        G(c, ["...**...", "..****..", ".******.", "********", "...**...", "...**...", "...**..."], 8, 1)
        carton(c, s, 5, 11, 14, 8)
        c.rect(1, 20, 22, 3)
    else:
        G(c, ["..*..", ".***.", "*****", "..*..", "..*.."], 6, 0)
        carton(c, s, 3, 7, 10, 5)
        c.rect(1, 13, 14, 2)
acc("r_pick_up", "blue")


def _open_box(c, s):
    """an open carton from the front: three-pixel walls, the flaps folded out from the top of each"""
    if s == 24:
        c.rect(4, 12, 16, 11); c.rect(7, 12, 10, 8, v=0)
        G(c, [".##..................##.",
              ".###................###.",
              "..###..............###..",
              "...###............###...",
              "....###..........###...."], 0, 8)
    else:
        c.rect(3, 8, 10, 7); c.rect(4, 8, 8, 5, v=0)
        G(c, [".#............#.",
              "..#..........#..",
              "...#........#..."], 0, 5)


@icon("r_put_in", "r1", "an arrow down into an open carton: put in a container", [])
def r_put_in(c, s):
    _open_box(c, s)
    if s == 24:
        G(c, ["...**...", "...**...", "...**...", "...**...", "...**...", "...**...", "...**...", "...**...",
              "...**...", "...**...", "********", ".******.", "..****..", "...**..."], 8, 0)
    else:
        G(c, ["..*..", "..*..", "..*..", "..*..", "..*..", "..*..", "*****", ".***.", "..*.."], 5, 0)
acc("r_put_in", "red")


@icon("r_take", "r1", "an arrow up out of the open carton: take", [])
def r_take(c, s):
    _open_box(c, s)
    if s == 24:
        G(c, ["...**...", "..****..", ".******.", "********", "...**...", "...**...", "...**...", "...**...",
              "...**...", "...**...", "...**...", "...**...", "...**...", "...**..."], 8, 0)
    else:
        G(c, ["..*..", ".***.", "*****", "..*..", "..*..", "..*..", "..*..", "..*..", "..*.."], 5, 0)
acc("r_take", "blue")


@icon("r_drop", "r1", "a carton tumbling corner first, its lid seam along one edge, speed lines trailing it, the floor: drop", [])
def r_drop(c, s):
    cx, cy, r, seam, lines, floor = ((11.5, 10.5, 7.0, (8, 12), ((5, 0, 5), (11, 0, 2), (18, 0, 5)), 20) if s == 24 else
                                     (7.5, 7.0, 5.0, (5, 7), ((3, 0, 3), (12, 0, 3)), 13))
    for y in range(s):
        for x in range(s):
            if abs(x + 0.5 - cx) + abs(y + 0.5 - cy) <= r: c.rect(x, y, 1, 1)
    k = 18 if s == 24 else 11                                       # the seam: x + y = k, parallel to the upper-left edge
    for x in range(seam[0], seam[1] + 1): c.rect(x, k - x, 1, 1, v=0)
    with c.mark():
        for x, y0, n in lines: c.rect(x, y0, 1, n)
    for x in ((1, 4, 7, 10, 13, 16, 19, 22) if s == 24 else (1, 4, 7, 10, 13)): c.rect(x, floor, 2, 2)
acc("r_drop", "red")


@icon("r_move_to", "r1", "two cartons, an arrow arcing from one over to the other: move to", [])
def r_move_to(c, s):
    if s == 24:
        G(c, [".....##########.....",
              "...##############...",
              "..####........####..",
              "..###..........###..",
              "..##............##..",
              "..##............##..",
              "..##..........######",
              "..##...........####.",
              "..##............##.."], 1, 2)
        carton(c, s, 1, 13, 8, 9); carton(c, s, 15, 13, 8, 9)
    else:
        G(c, ["...######...",
              "..#......#..",
              ".#........#.",
              ".#........#.",
              ".#......#####",
              ".#.......###.",
              ".#........#.."], 1, 1)
        c.rect(1, 9, 6, 6); c.rect(1, 11, 6, 1, v=0)
        c.rect(9, 9, 6, 6); c.rect(9, 11, 6, 1, v=0)


@icon("r_wanted", "r1", "a carton, a blue check beside it: wanted", [])
def r_wanted(c, s):
    if s == 24:
        carton(c, s, 1, 2, 14, 12)
        c.line([(12.5, 17), (16, 20.5), (22, 13)], 5.4, v=0)
        with c.mark(): c.line([(12.5, 17), (16, 20.5), (22, 13)], 3)
    else:
        carton(c, s, 1, 1, 9, 7)
        c.rect(7, 7, 9, 9, v=0)
        G(c, [".......**",
              "......**.",
              "**...**..",
              ".**.**...",
              "..***....",
              "...*....."], 7, 8)
acc("r_wanted", "blue")


@icon("r_unwanted", "r1", "a carton inside a red no-entry ring, the slash across it: unwanted", [])
def r_unwanted(c, s):
    if s == 24:
        carton(c, s, 6, 7, 12, 10)
        c.line([(5.5, 5.5), (18.5, 18.5)], 4.4, v=0)
        with c.mark():
            c.oring(12, 12, 11.5, 2)
            c.line([(5.5, 5.5), (18.5, 18.5)], 2, caps=False)
    else:
        carton(c, s, 4, 5, 8, 6)
        c.line([(3.5, 3.5), (12.5, 12.5)], 3, v=0)
        with c.mark():
            c.oring(8, 8, 7.5, 1.3)
            c.line([(3.5, 3.5), (12.5, 12.5)], 1.2, caps=False)
acc("r_unwanted", "red")


def _page(c, s):
    """a recipe page: its outline, a folded corner, three lines of text"""
    if s == 24:
        c.poly([(1, 1), (11, 1), (16, 6), (16, 22), (1, 22)])
        c.poly([(3, 3), (10, 3), (14, 7), (14, 20), (3, 20)], v=0)
        c.poly([(10, 1), (16, 7), (10, 7)])
        for y in (9, 12, 15): c.rect(5, y, 7, 2)
    else:
        c.poly([(1, 1), (8, 1), (11, 4), (11, 15), (1, 15)])
        c.poly([(2, 2), (7.5, 2), (10, 4.5), (10, 14), (2, 14)], v=0)
        c.poly([(7, 1), (11, 5), (7, 5)])
        for y in (7, 9, 11): c.rect(3, y, 5, 1)


def _lock(c, s, shut=True):
    """a padlock over the page's corner, a clear pixel round it: shut, or its shackle lifted, one leg out"""
    if s == 24:
        top = 12 if shut else 9
        c.rect(11, top - 1, 13, 25 - top, v=0)
        if shut:
            G(c, ["...*****...", "..**...**..", "..**...**..", "..**...**.."], 12, 12)
        else:
            G(c, ["...*****...", "..**...**..", "..**...**..", "..**.......", "..**.......", "..**.......",
                  "..**......."], 12, 9)
        G(c, ["***********", "***********", "****ooo****", "****ooo****", "*****o*****", "*****o*****",
              "***********"], 12, 16)
    else:
        top = 8 if shut else 6
        c.rect(7, top - 1, 9, 17 - top, v=0)
        if shut: G(c, ["..***..", ".*...*.", ".*...*."], 8, 8)
        else: G(c, ["..***..", ".*...*.", ".*.....", ".*.....", ".*....."], 8, 6)
        G(c, ["*******", "*******", "***o***", "***o***", "*******"], 8, 11)


@icon("r_no_recipes", "r1", "a recipe page, a shut gold padlock on it: keep it out of recipes", [])
def r_no_recipes(c, s):
    _page(c, s); _lock(c, s, True)
acc("r_no_recipes", "gold")


@icon("r_recipes_ok", "r1", "the recipe page, the padlock open: usable in recipes again", [])
def r_recipes_ok(c, s):
    _page(c, s); _lock(c, s, False)
acc("r_recipes_ok", "gold")


@icon("r_rename", "r1", "a name label, a text cursor standing in it: rename", [])
def r_rename(c, s):
    if s == 24:
        c.rect(1, 7, 22, 10); c.rect(3, 9, 18, 6, v=0)
        c.rect(5, 11, 3, 2); c.rect(9, 11, 3, 2)
        c.rect(14, 3, 6, 18, v=0)
        G(c, ["##.##", "..#..", "..#..", "..#..", "..#..", "..#..", "..#..", "..#..", "..#..", "..#..", "..#..",
              "..#..", "..#..", "..#..", "..#..", "##.##"], 15, 4)
    else:
        c.rect(1, 4, 14, 8); c.rect(2, 5, 12, 6, v=0)
        c.rect(3, 7, 2, 2); c.rect(6, 7, 2, 2)
        c.rect(9, 1, 5, 14, v=0)
        G(c, ["#.#", ".#.", ".#.", ".#.", ".#.", ".#.", ".#.", ".#.", ".#.", ".#.", ".#.", "#.#"], 10, 2)


# ============================================================ cutting: one icon a verb
@icon("r_chop", "r1", "a cleaver over three chunks on a board: chop", [])
def r_chop(c, s):
    if s == 24:
        G(c, [".#############..........",
              "##############.##.......",
              "##oo##########.#########",
              "##oo##########.##o##o###",
              "##############.#########",
              "##############.##.......",
              "#ooooooooooooo..........",
              "##############..........",
              ".#############.........."], 0, 1)
        for x, y, w, h in ((2, 15, 5, 4), (9, 16, 5, 3), (16, 14, 6, 5)): c.rect(x, y, w, h)
        c.rect(1, 20, 22, 2)
    else:
        G(c, [".########......",
              "##o######.#....",
              "#########.#####",
              "#ooooooooo#####",
              ".########......"], 0, 1)
        for x, y, w, h in ((1, 10, 3, 2), (6, 10, 3, 2), (11, 9, 4, 3)): c.rect(x, y, w, h)
        c.rect(1, 13, 14, 2)


@icon("r_slice", "r1", "a loaf, slices standing off it: slice", [])
def r_slice(c, s):
    if s == 24:
        c.rrect(1, 7, 11, 15, 4); c.rect(1, 13, 11, 9)
        for x in (14, 17, 20):
            c.rect(x, 10, 2, 12); c.rect(x, 9, 1, 1) if x != 20 else c.rect(x + 1, 9, 1, 1)
    else:
        c.rrect(1, 4, 7, 11, 2.5); c.rect(1, 8, 7, 7)
        for x in (9, 11, 13): c.rect(x, 6, 1, 9)


@icon("r_dice", "r1", "a bowl heaped with little cubes, one tumbling off: dice", [])
def r_dice(c, s):
    if s == 24:
        c.ellipse(12, 13, 11, 9); c.rect(0, 0, 24, 13, v=0)
        for x, y in ((2, 8), (7, 7), (12, 8), (17, 7), (4, 2), (9, 3), (14, 2)): c.rect(x, y, 4, 4)
        G(c, ["..#..", ".###.", "#####", ".###.", "..#.."], 19, 1)
    else:
        c.ellipse(8, 9, 7.5, 6); c.rect(0, 0, 16, 9, v=0)
        for x, y in ((1, 5), (5, 6), (9, 5), (3, 1), (7, 2)): c.rect(x, y, 3, 3)
        G(c, [".#.", "###", ".#."], 12, 1)


@icon("r_peel", "r1", "a potato, its peel coming off in a curl: peel", [])
def r_peel(c, s):
    if s == 24:
        c.ellipse(9, 9, 8, 7); c.rect(5, 6, 2, 2, v=0); c.rect(10, 10, 2, 2, v=0)
        G(c, ["##....",
              "###...",
              ".###..",
              "..##..",
              "..##..",
              ".##...",
              "##....",
              "##....",
              ".##...",
              "..###.",
              "...###"], 15, 11)
    else:
        c.ellipse(6, 6, 5.5, 4.5); c.rect(4, 4, 1, 1, v=0); c.rect(7, 7, 1, 1, v=0)
        G(c, ["#...", ".#..", "..#.", ".#..", "#...", ".#..", "..#."], 10, 8)


# ============================================================ the workshop
def _bracket(c, s):
    if s == 24: c.rect(15, 4, 8, 16); c.rect(15, 7, 5, 10, v=0)
    else: c.rect(11, 3, 4, 10); c.rect(11, 5, 2, 6, v=0)


@icon("r_install", "r1", "a part, an arrow carrying it into a bracket: install", [])
def r_install(c, s):
    _bracket(c, s)
    if s == 24:
        c.rect(1, 9, 6, 6)
        with c.mark(): c.rect(8, 11, 10, 2); c.rect(15, 8, 1, 8); c.rect(16, 9, 1, 6); c.rect(17, 10, 1, 4); c.rect(18, 11, 1, 2)
    else:
        c.rect(1, 6, 3, 4)
        with c.mark():
            c.rect(4, 8, 7, 1); c.rect(9, 6, 1, 5); c.rect(10, 7, 1, 3); c.rect(11, 8, 1, 1)
acc("r_install", "blue")


@icon("r_uninstall", "r1", "the part, an arrow carrying it out of the bracket: uninstall", [])
def r_uninstall(c, s):
    _bracket(c, s)
    if s == 24:
        c.rect(1, 9, 6, 6)
        with c.mark(): c.rect(8, 11, 11, 2); c.rect(11, 8, 1, 8); c.rect(10, 9, 1, 6); c.rect(9, 10, 1, 4); c.rect(8, 11, 1, 2)
    else:
        c.rect(1, 6, 3, 4)
        with c.mark():
            c.rect(5, 8, 7, 1); c.rect(7, 6, 1, 5); c.rect(6, 7, 1, 3); c.rect(5, 8, 1, 1)
acc("r_uninstall", "red")


@icon("r_disassemble", "r1", "a part pulled apart in three layers, its screws loose between: take apart", [])
def r_disassemble(c, s):
    if s == 24:
        c.rect(1, 1, 22, 4); c.rect(5, 10, 14, 5); c.rect(1, 19, 22, 4)
        for x in (3, 18):
            G(c, ["***", ".*.", ".*."], x, 6); G(c, ["***", ".*.", ".*."], x, 15)
    else:
        c.rect(1, 1, 14, 3); c.rect(4, 7, 8, 3); c.rect(1, 12, 14, 3)
        for x in (1, 12):
            G(c, ["***", ".*."], x, 4); G(c, ["***", ".*."], x, 10)
acc("r_disassemble", "red")


@icon("r_destroy", "r1", "a brick wall, a red crack running down through it: destroy", [])
def r_destroy(c, s):
    if s == 24:
        for y, xs in ((1, ((1, 7), (9, 15), (17, 22))), (6, ((1, 3), (5, 11), (13, 19), (21, 22))),
                      (11, ((1, 7), (9, 15), (17, 22))), (16, ((1, 3), (5, 11), (13, 19), (21, 22)))):
            for a, b in xs: c.rect(a, y, b - a + 1, 4)
        c.rect(1, 21, 22, 2)
        P = [(12.5, 0.5), (10.5, 5.5), (13.5, 10.5), (10.5, 15.5), (12.5, 20.5)]
        c.line(P, 3.6, v=0)
        with c.mark(): c.line(P, 1.6)
    else:
        for y, xs in ((1, ((1, 5), (7, 11), (13, 14))), (5, ((1, 2), (4, 8), (10, 14))),
                      (9, ((1, 5), (7, 11), (13, 14)))):
            for a, b in xs: c.rect(a, y, b - a + 1, 3)
        c.rect(1, 13, 14, 2)
        P = [(8.5, 0.5), (7, 4), (9, 8), (7.5, 12.5)]
        c.line(P, 2.8, v=0)
        with c.mark(): c.line(P, 1.0)
acc("r_destroy", "red")


@icon("r_dig", "r1", "a spade leaning into a heap of dirt, its T grip up, clods flying off: dig", [])
def r_dig(c, s):
    if s == 24:
        c.poly([(1, 23), (3, 19.5), (8, 17.5), (14, 18), (20, 20), (23, 23)])
        for y in range(6, 17):
            for x in range(5, 16):
                if abs(x + 0.5 - 10.5) + abs(y + 0.5 - 11.5) <= 5.4: c.rect(x, y, 1, 1)
        for t in range(8):
            c.rect(14 + t, 8 - t, 2, 1)
        for t in range(5):
            c.rect(19 + t, -1 + t, 1, 1); c.rect(19 + t, 0 + t, 1, 1)
        c.rect(1, 9, 3, 3); c.rect(4, 4, 2, 2)
    else:
        c.poly([(1, 15), (2.5, 12.5), (6, 11.5), (10, 12), (15, 15)])
        for y in range(3, 11):
            for x in range(2, 11):
                if abs(x + 0.5 - 6.5) + abs(y + 0.5 - 7) <= 3.6: c.rect(x, y, 1, 1)
        for t in range(6):
            c.rect(9 + t, 5 - t, 1, 1)
        for t in range(4):
            c.rect(12 + t, -1 + t, 1, 1); c.rect(12 + t, 0 + t, 1, 1) if t < 3 else None
        c.rect(1, 4, 2, 2)


@icon("r_light", "r1", "a lighter, its hood and wheel, its flame gold: light it", [])
def r_light(c, s):
    if s == 24:
        c.rrect(5, 12, 11, 11, 1.5); c.rect(5, 15, 11, 1, v=0)
        c.rect(5, 8, 7, 4)
        c.oring(14, 10, 2.2, 1.2)
        G(c, ["...*...",
              "...**..",
              "..***..",
              ".*****.",
              ".*****.",
              "**o****",
              "**oo***",
              ".**o**.",
              "..***.."], 9, -1)
        c.rect(9, 8, 3, 1, v=0)
    else:
        c.rect(3, 8, 7, 7); c.rect(3, 10, 7, 1, v=0)
        c.rect(3, 6, 4, 2); c.rect(8, 6, 2, 2)
        G(c, [".*..",
              ".**.",
              "****",
              "*o**",
              ".**."], 5, 0)
acc("r_light", "gold")


# ============================================================ the character wheel, its accents
@icon("r_weapons", "r1", "the knife, its cutting edge red: weapons", [])
def r_weapons(c, s):
    # the director, Nov 16: the red belongs "along the sharp edge of the blade at the bottom", not down its middle.
    # The knife points up and right, so its edge is the blade's lower-right side.
    ICONS["knife"]["fn"](c, s)
    if s == 24:
        edge = [(21, 3), (21, 4), (20, 4), (20, 5), (20, 6), (19, 6), (19, 7), (19, 8), (18, 8), (18, 9), (17, 9),
                (17, 10), (16, 10), (16, 11), (16, 12), (15, 12), (15, 13)]
    else:
        edge = [(14, 2), (14, 3), (13, 3), (13, 4), (12, 5), (12, 6), (11, 6), (11, 7), (10, 8)]
    with c.mark():
        for x, y in edge: c.rect(x, y, 1, 1)
acc("r_weapons", "red")


@icon("r_drink", "r1", "the glass, the water in it blue: drink", [])
def r_drink(c, s):
    ICONS["glass"]["fn"](c, s)
    with c.mark():
        if s == 24: c.rect(5, 13, 14, 2); c.rect(5, 15, 3, 8); c.rect(9, 15, 10, 8); c.rect(8, 19, 1, 4)
        else: c.rect(4, 10, 1, 5); c.rect(6, 10, 6, 4); c.rect(4, 9, 8, 1); c.rect(5, 13, 6, 2)
acc("r_drink", "blue")


@icon("r_medkit", "r1", "the first aid box, its cross red: medicine", [])
def r_medkit(c, s):
    ICONS["medkit"]["fn"](c, s)
    with c.mark():
        if s == 24: c.rect(10, 9, 4, 11); c.rect(6, 13, 12, 3)
        else: c.rect(7, 6, 2, 7); c.rect(4, 8, 8, 2)
acc("r_medkit", "red")


@icon("r_sleep", "r1", "the bed, a gold crescent moon over it: sleep", [])
def r_sleep(c, s):
    ICONS["bed"]["fn"](c, s)
    if s == 24: G(c, ["...***.", ".**....", "**.....", "**.....", "**.....", ".**....", "...***."], 15, 1)
    else: G(c, [".**", "*..", "*..", "*..", ".**"], 11, 1)
acc("r_sleep", "gold")


R1 = ["r_favorite", "r_place", "r_pick_up", "r_put_in", "r_take", "r_drop", "r_move_to", "r_wanted", "r_unwanted",
      "r_no_recipes", "r_recipes_ok", "r_rename", "r_chop", "r_slice", "r_dice", "r_peel", "r_install", "r_uninstall",
      "r_disassemble", "r_destroy", "r_dig", "r_light", "r_weapons", "r_drink", "r_medkit", "r_sleep"]
