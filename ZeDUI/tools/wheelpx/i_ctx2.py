"""The right-click menu, group 2: food and cooking (dishes, ingredients, cooking's actions, the food types). Drawn
in the wheels' ink to replace the menu's licensed pictures; the apple (Eat), the knife (Chop, Slice), the milk bottle
and the plus (Add) are the wheels' own (map.py CTX).

Coordinates are on the 16 grid's live area; U lays them out again on the 24 grid (i_ctx1)."""
import math

from kit import icon
from i_ctx1 import U, W, P


def _bowl(c, s, top=8.0, rim=1.0, depth=6.0, foot=True):
    """a bowl seen from the side: the lower half of an ellipse under a rim line at `top`"""
    u = U(s)
    c.ellipse(u(8), u(top), u(7) - u(0), u(depth) - u(0))
    c.rect(0, 0, s, u(top), v=0)
    c.rect(u(rim), u(top), u(16 - rim) - u(rim), W(s, 1, 1.5))
    if foot: c.rect(u(5.5), u(top + depth - 0.6), u(10.5) - u(5.5), W(s, 1.5, 2))


def _steam(c, s, xs=(5, 8, 11), y0=1.0, y1=6.0, amp=0.8):
    u = U(s)
    for x0 in xs:
        n = 16
        c.line([(u(x0 + amp * math.sin((y - y0) / (y1 - y0) * 2 * math.pi)), u(y)) for y in [y0 + i * (y1 - y0) / n for i in range(n + 1)]], W(s, 1.1, 1.6))


def _bowl34(c, s, top=8.0, depth=6.0, fill=False):
    """a bowl in three-quarter view (group 2 round 1, director: "bowls need work"): the body, the rim's ellipse with
    its opening showing (or filled: soup to the brim), the foot"""
    u = U(s)
    c.ellipse(u(8), u(top), u(7) - u(0), u(depth) - u(0)); c.rect(0, 0, s, u(top), v=0)      # the body
    c.ellipse(u(8), u(top), u(7) - u(0), u(2) - u(0))                                        # the rim
    c.ellipse(u(8), u(top), u(5.6) - u(0), u(1.0) - u(0), v=0)                               # the opening
    if fill: c.ellipse(u(8), u(top + 0.2), u(4.6) - u(0), u(0.6) - u(0))
    c.rect(u(1), u(top + 1.6), u(15) - u(1), W(s, 0.8, 1.2), v=0)                           # under the lip
    c.rect(u(5.5), u(top + depth - 0.4), u(10.5) - u(5.5), W(s, 1.5, 2))                    # the foot


def _lip(c, s, top=9.0):
    """the bowl's front lip, drawn again in front of what sits in it (a heap of rice, the leaves), a hair of space
    behind it"""
    u = U(s)

    def half(rx, ry, dy=0.0):
        return [(8 + rx * math.cos(math.radians(a)), top + dy + ry * math.sin(math.radians(a))) for a in range(0, 181, 10)]

    c.poly(P(s, half(7, 2, -1.0) + half(5.6, 1.0, -1.0)[::-1]), v=0)             # the hair of space
    c.poly(P(s, half(7, 2) + half(5.6, 1.0)[::-1]))                              # the lip


# ------------------------------------------------------------------ dishes
@icon("pan", "ctx2", "a frying pan, its handle, something frying: omelette, roast, stir-fry, poached eggs", ["ContextMenu_EvolvedRecipe_Omelette", "Roast"])
def pan(c, s):
    u = U(s)
    c.dot(u(6.5), u(8.5), u(5.6) - u(0))
    c.dot(u(6.5), u(8.5), u(4.2) - u(0), v=0)
    c.dot(u(6.5), u(8.5), u(2.6) - u(0))
    c.rect(u(11.5), u(7.5), u(15) - u(11.5), u(9.5) - u(7.5))


@icon("soup", "ctx2", "a bowl of soup, full to the brim, steaming: soup, stew, chili, ramen", ["ContextMenu_EvolvedRecipe_Soup", "Stew"])
def soup(c, s):
    # (group 2 round 1, director: "bowls need work": a bowl in three-quarter view)
    _bowl34(c, s, top=8.5, depth=5.5, fill=True)
    _steam(c, s, y0=1.0, y1=5.6)


@icon("pot", "ctx2", "a cooking pot, its lid and handles: a pot of stew, boil water, stock", ["Beef Stew", "Boil Water"])
def pot(c, s):
    u = U(s)
    c.rrect(u(2.5), u(6.5), u(13.5) - u(2.5), u(14.5) - u(6.5), W(s, 1.5, 2.2))  # the pot
    c.rect(u(1.5), u(4.5), u(14.5) - u(1.5), u(6) - u(4.5))                      # the lid
    c.rect(u(6.5), u(2.5), u(9.5) - u(6.5), u(4) - u(2.5))                       # its knob
    c.rect(u(0.5), u(8), u(2.5) - u(0.5), W(s, 1.5, 2)); c.rect(u(13.5), u(8), u(15.5) - u(13.5), W(s, 1.5, 2))   # the handles


@icon("pie", "ctx2", "a pie in its dish, the crust slit: pie", ["Pie", "ContextMenu_EvolvedRecipe_Pie"])
def pie(c, s):
    u = U(s)
    c.ellipse(u(8), u(9), u(7) - u(0), u(4.5) - u(0))                            # the crust's dome
    c.rect(0, u(9), s, s, v=0)
    c.poly(P(s, [(1, 9), (15, 9), (13, 14), (3, 14)]))                            # the dish
    c.rect(u(1), u(10), u(15) - u(1), W(s, 1, 1.5), v=0)                         # the dish's rim
    for x in (5, 8, 11): c.line(P(s, [(x - 0.8, 6.8), (x + 0.8, 5.6)]), W(s, 0.9, 1.3), v=0)   # the slits


@icon("cake", "ctx2", "a slice of layer cake, a cherry on top: cake, cheesecake", ["Cake", "Cheesecake"])
def cake(c, s):
    c.poly(P(s, [(1, 9), (13, 4.5), (15, 6), (15, 14), (1, 14)]))
    u = U(s)
    c.line(P(s, [(1, 11), (15, 11)]), W(s, 1, 1.5), v=0, caps=False)             # the layers
    c.line(P(s, [(1, 9.6), (15, 7.2)]), W(s, 0.9, 1.3), v=0, caps=False)         # the icing's edge
    c.dot(u(12.5), u(2.6), W(s, 1.6, 2.3))                                       # the cherry


@icon("sandwich", "ctx2", "a sandwich cut corner to corner, its filling: sandwich", ["Sandwich"])
def sandwich(c, s):
    c.poly(P(s, [(1.5, 2), (14.5, 14), (1.5, 14)]))
    c.line(P(s, [(3.5, 6.5), (10, 12.5)]), W(s, 1, 1.5), v=0)                    # the filling's line
    c.line(P(s, [(1.5, 12.4), (12, 12.4)]), W(s, 1, 1.5), v=0, caps=False)


@icon("burger", "ctx2", "a burger: bun, lettuce, patty, bun: burger, pulled pork", ["Burger", "Pulled Pork"])
def burger(c, s):
    u = U(s)
    c.ellipse(u(8), u(7), u(7) - u(0), u(5) - u(0)); c.rect(0, u(7), s, s, v=0)  # the top bun
    for x, y in ((5, 4.5), (8.5, 3.5), (11, 5)): c.rect(u(x), u(y), W(s, 1, 1.5), W(s, 1, 1), v=0)   # the seeds
    c.line(P(s, [(1.5, 8.2), (3.5, 9.2), (5.5, 8.2), (7.5, 9.2), (9.5, 8.2), (11.5, 9.2), (13.5, 8.2), (14.5, 8.8)]), W(s, 1.2, 1.8))   # lettuce
    c.rrect(u(1.5), u(10), u(14.5) - u(1.5), u(12) - u(10), W(s, 0.8, 1))       # the patty
    c.rrect(u(2), u(12.8), u(14) - u(2), u(15) - u(12.8), W(s, 1, 1.4))         # the bottom bun


@icon("salad", "ctx2", "a bowl of leaves, the bowl's lip in front of them: salad", ["Salad", "Fruit Salad"])
def salad(c, s):
    # (group 2 round 1, director: "bowls need work")
    u = U(s)
    _bowl34(c, s, top=9, depth=5)
    for x, y, r in ((4.6, 6.6, 2.7), (8, 5.4, 3.1), (11.4, 6.6, 2.7)): c.dot(u(x), u(y), u(r) - u(0))   # the leaves
    for x in (6.3, 9.7): c.line(P(s, [(x, 9), (x, 4.2)]), W(s, 0.8, 1.2), v=0, caps=False)
    _lip(c, s, top=9)


@icon("pasta", "ctx2", "a plate of spaghetti, a fork stuck in the nest: pasta, lasagna, macaroni", ["Pasta", "Lasagna"])
def pasta(c, s):
    # (group 2 round 1, director: "refine pasta": the twirl became a plate of spaghetti with a fork in it)
    if s == 16:
        c.grid([".............##.",
                "............##..",
                "...........##...",
                "..........##....",
                ".....####.#.....",
                "...##########...",
                "..###..##..###..",
                ".##..##..##..##.",
                ".###..##..##.##.",
                "..############..",
                "................",
                "################",
                ".##############."], oy=1)
    else:
        c.grid(["....................###.",
                "...................###..",
                "..................###...",
                ".................###....",
                "................###.....",
                "...............###......",
                "........######.##.......",
                ".....#############......",
                "....################....",
                "...####...####...####...",
                "..###..###....###..###..",
                "..##..##..####..##..##..",
                ".###.###.##..##.###.###.",
                ".####...####..####..###.",
                "..##################....",
                "...################.....",
                "........................",
                "........................",
                "########################",
                "########################",
                ".######################."], oy=1)


@icon("bowl", "ctx2", "a bowl heaped with rice, the bowl's lip in front of the heap: rice, risotto, porridge, dumplings, meatballs", ["Rice", "Porridge"])
def bowl(c, s):
    # (group 2 round 1, director: "bowls need work")
    u = U(s)
    top = 9.0

    def arc(rx, ry, a0, a1, dy=0.0):
        return [(8 + rx * math.cos(math.radians(a)), top + dy + ry * math.sin(math.radians(a))) for a in range(a0, a1 + 1, 10)]

    c.poly(P(s, arc(7, 2, 180, 360) + arc(5.6, 1.0, 180, 360)[::-1]))            # the rim's back
    c.poly(P(s, arc(5.4, 5.8, 180, 360)))                                         # the heap
    c.poly(P(s, arc(7, 5, 0, 180)))                                               # the bowl
    c.rect(u(5.5), u(top + 4.6), u(10.5) - u(5.5), W(s, 1.5, 2))                 # its foot
    c.rect(u(1), u(top + 1.6), u(15) - u(1), W(s, 0.8, 1.2), v=0)                # under the lip
    _lip(c, s, top=top)
    for x, y in ((6, 5.5), (9.5, 4.5), (8, 7)): c.rect(u(x), u(y), W(s, 1, 1.5), W(s, 1, 1), v=0)   # grains


@icon("hotdog", "ctx2", "a hot dog: the sausage on its bun, sticking out past both ends, mustard on top: hot dog, sausage", ["Hotdog", "Sausage"])
def hotdog(c, s):
    # (group 2 round 1, director: "refine hotdog": no top half to the bun, so it can't read as a burger)
    if s == 16:
        c.grid([".##############.",
                "################",
                "##.##..##..##.##",
                "###..##..##..###",
                ".##############.",
                "................",
                "...##########...",
                "..############..",
                "...##########...",
                "....########...."], oy=3)
    else:
        c.grid(["..####################..",
                ".######################.",
                "########################",
                "##.###..###..###..###.##",
                "###..###..###..###..####",
                "########################",
                ".######################.",
                "..####################..",
                "........................",
                "........................",
                ".....##############.....",
                "....################....",
                "....################....",
                ".....##############.....",
                "......############......"], oy=4)


@icon("taco", "ctx2", "a taco from the side: the half-moon shell and its fold, a frill of lettuce along the top: taco", ["Taco"])
def taco(c, s):
    # (group 2 round 2, director: "taco ... need rework too")
    u = U(s)
    c.dot(u(8), u(7.4), u(7) - u(0)); c.rect(0, 0, s, u(7.4), v=0)              # the shell
    for x, y in ((5, 9.6), (8.5, 11.2), (11, 9.4), (6.8, 12.4), (10, 13.2)): c.rect(u(x), u(y), W(s, 1, 1.5), W(s, 1, 1.5), v=0)   # the tortilla's spots
    c.rect(u(1), u(4.4), u(15) - u(1), u(5.8) - u(4.4))                          # the lettuce
    for x in (2.2, 5.1, 8, 10.9, 13.8): c.dot(u(x), u(4.2), u(1.5) - u(0))      # its frill
    c.rect(u(1), u(6.2), u(15) - u(1), W(s, 0.8, 1.2), v=0)


@icon("wrap", "ctx2", "a burrito rolled in its tortilla, the open end showing the filling, the tortilla's seam: burrito, wrap, spring rolls", ["Burrito", "Wrap"])
def wrap(c, s):
    # (group 2 round 2, director: "wrap/burrito need rework too")
    u = U(s)
    c.line(P(s, [(4, 12), (11, 5)]), W(s, 7.2, 10.8))                             # the roll
    cx, cy = 11.4, 4.6
    c.ellipse(u(cx), u(cy), u(3.4) - u(0), u(3.4) - u(0))                        # the open end
    c.ellipse(u(cx), u(cy), u(2.4) - u(0), u(2.4) - u(0), v=0)
    c.ellipse(u(cx), u(cy), u(1.5) - u(0), u(1.5) - u(0))                        # the filling, rolled in
    c.line(P(s, [(7.4, 4.8), (9.2, 7.4), (11.4, 9.2)]), W(s, 0.9, 1.3), v=0)       # the tortilla's seam
    c.line(P(s, [(2.6, 9.2), (6.6, 13.4)]), W(s, 0.9, 1.3), v=0)                    # the folded end


@icon("waffle", "ctx2", "a waffle: waffles", ["Waffles"])
def waffle(c, s):
    u = U(s)
    c.rrect(u(1.5), u(1.5), u(14.5) - u(1.5), u(14.5) - u(1.5), W(s, 2, 3))
    n = 3; a = u(3.5); b = u(12.5); step = (b - a) / n
    for i in range(n):
        for j in range(n): c.rect(a + i * step + W(s, 0.5, 0.6), a + j * step + W(s, 0.5, 0.6), step - W(s, 1.5, 2), step - W(s, 1.5, 2), v=0)


@icon("pancakes", "ctx2", "a stack of pancakes, butter melting on top: pancakes", ["Pancakes"])
def pancakes(c, s):
    u = U(s)
    for y in (6, 9, 12): c.rrect(u(1), u(y), u(15) - u(1), u(y + 2.4) - u(y), W(s, 1.2, 1.8))
    c.rect(u(6), u(3.5), u(10) - u(6), u(5.5) - u(3.5))                          # the butter
    c.line(P(s, [(11, 7.6), (11, 10)]), W(s, 1.2, 1.8))                           # syrup running


@icon("bread", "ctx2", "a loaf, slashed: bread, meatloaf, bagels, knead", ["Bread", "ContextMenu_EvolvedRecipe_BagelPlain"])
def bread(c, s):
    u = U(s)
    c.rrect(u(1), u(4.5), u(15) - u(1), u(13) - u(4.5), W(s, 3.5, 5))
    for x in (5, 8, 11): c.line(P(s, [(x - 1, 9), (x + 1, 6)]), W(s, 1, 1.5), v=0)


@icon("toast", "ctx2", "a slice of bread, its crust: toast, French toast", ["Toast", "French Toast"])
def toast(c, s):
    u = U(s)
    c.dot(u(5), u(5.5), u(3.8) - u(0)); c.dot(u(11), u(5.5), u(3.8) - u(0))
    c.rect(u(2), u(5.5), u(14) - u(2), u(14) - u(5.5))
    c.dot(u(5), u(5.8), u(2.4) - u(0), v=0); c.dot(u(11), u(5.8), u(2.4) - u(0), v=0)
    c.rect(u(3.5), u(5.8), u(12.5) - u(3.5), u(12.5) - u(5.8), v=0)
    c.rect(u(5), u(5), u(11) - u(5), u(12.5) - u(5), v=0)
    c.dot(u(5), u(5.8), u(1.3) - u(0)); c.dot(u(11), u(5.8), u(1.3) - u(0))
    c.rect(u(4.5), u(6.5), u(11.5) - u(4.5), u(11.5) - u(6.5))


@icon("pizza", "ctx2", "a slice of pizza, its crust and pepperoni: pizza, nachos", ["Pizza", "Nachos"])
def pizza(c, s):
    u = U(s)
    c.poly(P(s, [(1.5, 2), (14.5, 2), (8, 15)]))
    c.rect(u(1.5), u(4), u(14.5) - u(1.5), W(s, 1, 1.5), v=0)                    # the crust's edge
    for x, y in ((6, 6.5), (10, 7), (8, 10.5)): c.dot(u(x), u(y), W(s, 1.1, 1.6), v=0)


@icon("citrus", "ctx2", "a slice of lemon, its segments: citrus, lemonade", ["ContextMenu_FoodType_Citrus", "Make Lemonade"])
def citrus(c, s):
    u = U(s)
    c.dot(u(8), u(8), u(7) - u(0))
    c.oring(u(8), u(8), u(5.6) - u(0), W(s, 0.8, 1.2), v=0)                      # the rind
    for k in range(6):
        a = math.radians(30 + k * 60)
        c.line([(u(8), u(8)), (u(8) + (u(5.4) - u(0)) * math.cos(a), u(8) + (u(5.4) - u(0)) * math.sin(a))], W(s, 0.9, 1.3), v=0, caps=False)


@icon("potato", "ctx2", "a potato, its eyes: baked potato", ["Baked Potato"])
def potato(c, s):
    u = U(s)
    c.poly(P(s, [(3, 5), (7, 3), (12, 4), (15, 8), (13.5, 12.5), (8.5, 14), (3.5, 12.5), (1, 8.5)]))
    for x, y in ((5, 7), (9.5, 6), (11.5, 10), (6.5, 11)): c.rect(u(x), u(y), W(s, 1, 1.5), W(s, 1, 1.5), v=0)


@icon("pepper", "ctx2", "a bell pepper, its stem: peppers, stuffed pepper, hot peppers", ["Stuffed Pepper", "ContextMenu_FoodType_Pepper"])
def pepper(c, s):
    u = U(s)
    for x in (5.5, 10.5): c.ellipse(u(x), u(9.5), u(3.6) - u(0), u(5) - u(0))
    c.ellipse(u(8), u(10), u(2.6) - u(0), u(4.6) - u(0))
    c.line(P(s, [(8, 10.5), (8, 14)]), W(s, 0.8, 1.2), v=0, caps=False)          # the lobes' crease
    c.line(P(s, [(8, 5), (8.5, 2.5), (10.5, 1.5)]), W(s, 1.4, 2))                # the stem


@icon("egg", "ctx2", "an egg: eggs, boiled, scrambled, collect eggs", ["Boiled Egg", "Add Eggs"])
def egg(c, s):
    u = U(s)
    c.ellipse(u(8), u(9), u(4.8) - u(0), u(5.8) - u(0))
    c.ellipse(u(8), u(6.5), u(3.6) - u(0), u(4.6) - u(0))
    c.arc(u(6.2), u(6.8), u(1.8) - u(0), 200, 260, W(s, 0.9, 1.3), v=0, caps=False)   # the shine


@icon("egg_fried", "ctx2", "a fried egg: the white's soft edge, the yolk solid in it: fried eggs", ["Fried Eggs"])
def egg_fried(c, s):
    # (group 2 round 1, director: "refine fried egg")
    u = U(s)
    blobs = ((6.2, 6.4, 4.8), (10.4, 6.8, 4.0), (6.4, 10.8, 3.8), (10.8, 11, 3.6), (8.6, 9, 4.4))
    for x, y, r in blobs: c.dot(u(x), u(y), u(r) - u(0))                         # the white
    t = W(s, 1.4, 2.0)
    for x, y, r in blobs: c.dot(u(x), u(y), u(r) - u(0) - t, v=0)                # its edge only
    c.dot(u(8), u(8.6), u(3) - u(0))                                             # the yolk
    c.rect(u(6.8), u(7.2), W(s, 1, 1.5), W(s, 1, 1.5), v=0)                      # its shine


@icon("kebab", "ctx2", "a kebab: chunks on a skewer: kebab", ["Kebab"])
def kebab(c, s):
    c.line(P(s, [(1.5, 14.5), (14.5, 1.5)]), W(s, 1, 1.5))
    u = U(s)
    for t in (0.24, 0.5, 0.76):
        x = 1.5 + 13 * t; y = 14.5 - 13 * t
        c.dot(u(x), u(y), u(2) - u(0))


@icon("fish", "ctx2", "a fish: fish, seafood, fish and chips, sushi", ["Fish", "ContextMenu_FoodType_Seafood"])
def fish(c, s):
    u = U(s)
    c.ellipse(u(6.5), u(8), u(5.5) - u(0), u(4) - u(0))
    c.poly(P(s, [(10.5, 8), (15, 4), (15, 12)]))
    c.dot(u(3.5), u(7), W(s, 0.8, 1.2), v=0)                                     # the eye
    c.arc(u(4.5), u(8), u(2.5) - u(0), -50, 50, W(s, 0.8, 1.2), v=0, caps=False) # the gill


@icon("bacon", "ctx2", "a rasher of bacon, a streak of fat: bacon", ["Bacon"])
def bacon(c, s):
    pts = [(1 + i * 0.5, 8 + 1.6 * math.sin(i * 0.5 / 14 * 2.2 * math.pi)) for i in range(29)]
    c.line(P(s, pts), W(s, 6, 9))
    c.line(P(s, pts[2:-2]), W(s, 1.1, 1.6), v=0)


@icon("meat", "ctx2", "a ham on the bone: meat, ham, game, rabbit, ribs", ["Ham", "ContextMenu_FoodType_Meat"])
def meat(c, s):
    u = U(s)
    c.ellipse(u(6.5), u(9.5), u(5.5) - u(0), u(5) - u(0))
    c.line(P(s, [(10, 6), (13, 3)]), W(s, 1.8, 2.6))                              # the bone
    c.dot(u(13.2), u(2.2), W(s, 1.2, 1.8)); c.dot(u(14.2), u(3.4), W(s, 1.2, 1.8))
    c.arc(u(6.5), u(9.5), u(3.4) - u(0), 200, 300, W(s, 0.9, 1.3), v=0, caps=False)


@icon("steak", "ctx2", "a steak: a kidney-shaped cut, its rim of fat, a small round bone: steak, pork chop, beef, venison", ["Steak", "Pork Chop"])
def steak(c, s):
    # (group 2 round 1, director: "steak ... need work")
    u = U(s)
    c.poly(P(s, [(1, 8), (2, 4.6), (5.5, 3), (10, 3.6), (14, 5), (15.2, 8.6), (13.6, 12), (9.6, 13), (6.2, 11.8), (3, 12.6), (1.2, 11)]))
    c.line(P(s, [(2.6, 10.6), (3.1, 6), (6, 4.5), (10.2, 5)]), W(s, 0.9, 1.3), v=0)   # the fat's edge
    c.dot(u(11), u(9), u(2.1) - u(0), v=0); c.dot(u(11), u(9), u(1.4) - u(0))         # the bone
    c.dot(u(11), u(9), W(s, 0.55, 0.8), v=0)


@icon("drumstick", "ctx2", "a chicken drumstick: chicken, fried chicken, turkey, poultry", ["Chicken", "ContextMenu_FoodType_Poultry"])
def drumstick(c, s):
    u = U(s)
    c.ellipse(u(6.5), u(6.5), u(5.2) - u(0), u(5.2) - u(0))
    c.line(P(s, [(9, 9), (12.6, 12.6)]), W(s, 1.8, 2.6))
    c.dot(u(12.6), u(14), W(s, 1.2, 1.8)); c.dot(u(14), u(12.6), W(s, 1.2, 1.8))


@icon("cookie", "ctx2", "a cookie, its chips, a bite out of it: cookies", ["Cookies"])
def cookie(c, s):
    u = U(s)
    c.dot(u(8), u(8), u(7) - u(0))
    c.dot(u(14), u(3.5), u(3) - u(0), v=0)                                       # the bite
    for x, y in ((5, 6), (8.5, 10.5), (5.5, 11), (10, 6.5), (11.5, 11)): c.rect(u(x), u(y), W(s, 1.2, 1.8), W(s, 1.2, 1.8), v=0)


@icon("icecream", "ctx2", "an ice cream cone: a full scoop, its scalloped rim on the cone's criss-cross: ice cream", ["Ice Cream"])
def icecream(c, s):
    u = U(s)
    if s == 16:
        c.dot(u(8), u(5.5), u(4.6) - u(0))
        c.poly(P(s, [(3.5, 7.5), (12.5, 7.5), (8, 15.5)]))
        c.rect(u(3), u(7.2), u(13) - u(3), W(s, 1, 1.5), v=0)
        c.line(P(s, [(5.6, 9), (9, 13)]), W(s, 0.8, 1.2), v=0); c.line(P(s, [(10.4, 9), (7, 13)]), W(s, 0.8, 1.2), v=0)
    else:
        # (group 2 round 1, director: "refine ... the large icecream cone")
        c.dot(12, 8, 7.6); c.rect(0, 10.5, 24, 14, v=0)                          # the scoop
        for x in (6, 10, 14, 18): c.dot(x, 11, 2.1)                              # its scalloped rim
        c.rect(3.9, 13.6, 16.2, 1.2, v=0)
        for y in range(15, 24):                                                  # the cone, its lattice pixel by pixel
            hw = 8.0 * (24 - y) / 9.0
            for x in range(24):
                if abs(x + 0.5 - 12) <= hw:
                    lattice = y > 15 and ((x + y) % 4 == 0 or (x - y) % 4 == 0) and abs(x + 0.5 - 12) < hw - 1
                    if not lattice: c.rect(x, y, 1, 1)


@icon("candy", "ctx2", "a wrapped sweet: candy", ["ContextMenu_FoodType_Candy"])
def candy(c, s):
    u = U(s)
    c.ellipse(u(8), u(8), u(3.6) - u(0), u(3) - u(0))
    c.poly(P(s, [(4.5, 8), (1, 4.5), (1, 11.5)])); c.poly(P(s, [(11.5, 8), (15, 4.5), (15, 11.5)]))
    c.rect(u(4.4), u(5), W(s, 1, 1.5), u(11) - u(5), v=0); c.rect(u(11.6) - W(s, 1, 1.5), u(5), W(s, 1, 1.5), u(11) - u(5), v=0)


@icon("chocolate", "ctx2", "a bar of chocolate, its squares: chocolate, cocoa", ["ContextMenu_FoodType_Chocolate"])
def chocolate(c, s):
    if s == 16:
        c.rect(3, 1, 11, 14)
        c.rect(8, 1, 1, 14, v=0)
        for y in (4, 8, 11): c.rect(3, y, 11, 1, v=0)
    else:
        c.rect(4, 1, 16, 22)
        c.rect(11.5, 1, 1.5, 22, v=0)
        for y in (6, 11.5, 17): c.rect(4, y, 16, 1.5, v=0)


@icon("can", "ctx2", "a tin can, its lid and ridges: open a can, open and eat, a can", ["Open and Eat", "Open Can"])
def can(c, s):
    u = U(s)
    c.rect(u(3), u(3.5), u(13) - u(3), u(13.5) - u(3.5))                        # the body
    c.ellipse(u(8), u(13.5), u(5) - u(0), u(1.5) - u(0))                         # its rounded foot
    c.ellipse(u(8), u(3.5), u(5) - u(0), u(1.8) - u(0))                          # the lid
    c.ellipse(u(8), u(3.5), u(3.8) - u(0), u(0.9) - u(0), v=0)
    for y in (7.5, 10.5): c.rect(u(3), u(y), u(13) - u(3), W(s, 0.9, 1.3), v=0) # the ridges


# ------------------------------------------------------------------ cooking: tools and what goes in
@icon("grater", "ctx2", "a box grater: grate", ["Grate"])
def grater(c, s):
    u = U(s)
    c.poly(P(s, [(4.5, 4), (11.5, 4), (13, 15), (3, 15)]))
    c.rect(u(5.5), u(1), u(10.5) - u(5.5), W(s, 1, 1.5)); c.rect(u(5.5), u(1), W(s, 1, 1.5), u(4) - u(1)); c.rect(u(10.5) - W(s, 1, 1.5), u(1), W(s, 1, 1.5), u(4) - u(1))
    for y in (6.5, 9.5, 12.5):
        for x in (6, 8, 10): c.rect(u(x) - W(s, 0.5, 0.7), u(y), W(s, 1, 1.4), W(s, 1, 1.4), v=0)


@icon("mortar", "ctx2", "a mortar and pestle: grind", ["Grind"])
def mortar(c, s):
    _bowl(c, s, top=8, depth=6, foot=True)
    c.line(P(s, [(7, 9), (13, 2)]), W(s, 2.4, 3.6))
    u = U(s); c.rect(u(1), u(8), u(15) - u(1), W(s, 1, 1.5))


@icon("whisk", "ctx2", "a whisk: mix", ["Mix"])
def whisk(c, s):
    u = U(s)
    c.rect(u(7), u(10), u(9) - u(7), u(15) - u(10))
    for rx in (4.2, 2.2):
        c.oring(u(8), u(5.5), u(4.6) - u(0), W(s, 1, 1.4)) if rx == 4.2 else None
    c.ellipse(u(8), u(5.5), u(4.5) - u(0), u(4.8) - u(0)); c.ellipse(u(8), u(5.5), u(3.4) - u(0), u(3.8) - u(0), v=0)
    c.ellipse(u(8), u(5.5), u(2.2) - u(0), u(4.8) - u(0)); c.ellipse(u(8), u(5.5), u(1.2) - u(0), u(3.8) - u(0), v=0)
    c.rect(u(7.5), u(1), W(s, 1, 1.5), u(10) - u(1))


@icon("spoon", "ctx2", "a wooden spoon: stir", ["Stir"])
def spoon(c, s):
    u = U(s)
    c.ellipse(u(5), u(5), u(3.4) - u(0), u(4) - u(0))
    c.line(P(s, [(6.5, 7.5), (13.5, 14.5)]), W(s, 1.8, 2.6))


@icon("shaker", "ctx2", "a salt shaker: add salt or pepper, season, spice", ["Add Salt", "Season"])
def shaker(c, s):
    u = U(s)
    c.ellipse(u(8), u(5), u(4) - u(0), u(3.5) - u(0)); c.rect(0, u(5), s, s, v=0)   # the cap
    c.rect(u(4), u(5.6), u(12) - u(4), W(s, 1, 1.5))
    c.poly(P(s, [(4.5, 7.5), (11.5, 7.5), (12.5, 15), (3.5, 15)]))                   # the body
    for x in (6.5, 9.5): c.rect(u(x), u(3), W(s, 1, 1.5), W(s, 1, 1.5), v=0)        # the holes


@icon("sack", "ctx2", "a sack tied at the neck: flour, sugar, thickener", ["Add Flour", "Add Sugar"])
def sack(c, s):
    c.poly(P(s, [(5.5, 4.5), (10.5, 4.5), (14, 9), (14.5, 14), (1.5, 14), (2, 9)]))
    c.poly(P(s, [(5, 1.5), (8, 3), (11, 1.5), (10.5, 3.6), (5.5, 3.6)]))             # the tie
    u = U(s); c.rect(u(5.5), u(4), u(10.5) - u(5.5), W(s, 0.8, 1.2), v=0)


@icon("oil", "ctx2", "a bottle of oil, a drop on its label: oil, vinegar", ["Add Oil", "Add Vinegar"])
def oil(c, s):
    u = U(s)
    c.rect(u(7), u(1), u(9) - u(7), u(4) - u(1))                                 # the neck
    c.poly(P(s, [(6.5, 4), (9.5, 4), (12, 7.5), (12, 15), (4, 15), (4, 7.5)]))
    c.poly(P(s, [(8, 8.5), (9.6, 11), (8, 12.6), (6.4, 11)]), v=0)                 # the drop


@icon("butter", "ctx2", "a block of butter: butter, spread, fat", ["Add Butter", "ContextMenu_FoodType_Spread"])
def butter(c, s):
    c.poly(P(s, [(1, 7), (5, 4), (15, 4), (11, 7)]))                              # the top
    c.poly(P(s, [(1, 7.8), (11, 7.8), (11, 13), (1, 13)]))                        # the front
    c.poly(P(s, [(11.8, 7.4), (15, 4.8), (15, 10.5), (11.8, 13)]))                # the end


@icon("cheese", "ctx2", "a wedge of cheese, its holes: cheese", ["Add Cheese", "ContextMenu_FoodType_Cheese"])
def cheese(c, s):
    c.poly(P(s, [(1, 7), (11, 2.5), (15, 7), (15, 14), (1, 14)]))
    u = U(s)
    c.rect(u(1), u(7.5), u(15) - u(1), W(s, 0.8, 1.2), v=0)
    for x, y, r in ((4.5, 10.5, 1.4), (9.5, 11, 1.8), (12.5, 9.5, 1.0)): c.dot(u(x), u(y), u(r) - u(0), v=0)


@icon("sauce", "ctx2", "a squeeze bottle: sauce, dressing", ["Add Sauce", "ContextMenu_FoodType_Sauce"])
def sauce(c, s):
    c.poly(P(s, [(7, 1), (9, 1), (10.5, 4), (5.5, 4)]))                           # the nozzle
    u = U(s)
    c.rrect(u(4), u(4.8), u(12) - u(4), u(15) - u(4.8), W(s, 2, 3))
    c.rect(u(4), u(7.5), u(12) - u(4), W(s, 0.8, 1.2), v=0)


@icon("honey", "ctx2", "a honey pot, honey running down: honey, mead, syrup", ["Add Honey", "Fluid_Name_Honey"])
def honey(c, s):
    u = U(s)
    c.rect(u(3), u(2), u(13) - u(3), u(4) - u(2))                                 # the lid
    c.ellipse(u(8), u(10), u(6.5) - u(0), u(5) - u(0))                            # the pot
    c.rect(u(3), u(4.4), u(13) - u(3), W(s, 1, 1.5))
    c.poly(P(s, [(4, 5.4), (12, 5.4), (12, 7), (10, 9), (9.2, 7.2), (7, 8.5), (6, 7), (4, 7)]), v=0)   # the drip


# ------------------------------------------------------------------ the food types
@icon("berries", "ctx2", "three berries and a leaf: berries", ["Pick Berries", "ContextMenu_FoodType_Berry"])
def berries(c, s):
    u = U(s)
    for x, y in ((8, 6.5), (4.8, 11), (11.2, 11)):
        c.dot(u(x), u(y), u(3.3) - u(0), v=0)
        c.dot(u(x), u(y), u(2.6) - u(0))
    c.poly(P(s, [(8, 3.6), (10, 1), (13, 1.5), (11, 3.4)]))


@icon("carrot", "ctx2", "a carrot, its leaves: vegetables", ["ContextMenu_FoodType_Vegetable"])
def carrot(c, s):
    c.poly(P(s, [(6, 6), (10, 10), (1.5, 15)]))
    c.line(P(s, [(9, 7), (12.5, 2)]), W(s, 1.2, 1.8)); c.line(P(s, [(9, 7), (14.5, 5.5)]), W(s, 1.2, 1.8)); c.line(P(s, [(9, 7), (13.8, 3.2)]), W(s, 1.2, 1.8))
    for a in (0.35, 0.6): c.line(P(s, [(6 + (1.5 - 6) * a + 0.6, 6 + 9 * a - 1.4), (6 + (1.5 - 6) * a + 2.2, 6 + 9 * a + 0.2)]), W(s, 0.8, 1.2), v=0)


@icon("nut", "ctx2", "a peanut in its shell: nuts", ["ContextMenu_FoodType_Nut"])
def nut(c, s):
    u = U(s)
    c.dot(u(5.5), u(10.5), u(4.2) - u(0)); c.dot(u(10.5), u(5.5), u(4.2) - u(0))
    c.line(P(s, [(5.5, 10.5), (10.5, 5.5)]), W(s, 5.6, 8.4))
    for x, y in ((5, 10), (7, 12), (10, 5), (12, 7), (8, 8)): c.rect(u(x), u(y), W(s, 1, 1.5), W(s, 1, 1.5), v=0)


@icon("mushroom", "ctx2", "a mushroom, its spotted cap: mushrooms", ["ContextMenu_FoodType_Mushroom"])
def mushroom(c, s):
    u = U(s)
    c.ellipse(u(8), u(8), u(7) - u(0), u(6) - u(0)); c.rect(0, u(8), s, s, v=0)
    c.rrect(u(5.5), u(8.8), u(10.5) - u(5.5), u(15) - u(8.8), W(s, 1, 1.5))
    for x, y in ((5, 5), (10, 4), (8, 6.5)): c.dot(u(x), u(y), W(s, 1, 1.5), v=0)


@icon("peapod", "ctx2", "an open pea pod, corner to corner, its three peas inside, the stalk: beans, peas", ["ContextMenu_FoodType_Bean"])
def peapod(c, s):
    # (group 2 round 1, director: "pea pod ... need work": bigger, a thicker shell, the peas clear of it)
    u = U(s)
    ax, ay, bx, by = 1.0, 14.0, 14.4, 2.2                                        # the pod's two points
    L = math.hypot(bx - ax, by - ay); ex, ey = (bx - ax) / L, (by - ay) / L; nx, ny = -ey, ex

    def lens(h, a=0.0, b=1.0):
        n = 32; pts = []
        for side in (1, -1):
            rng = range(n + 1) if side == 1 else range(n, -1, -1)
            for i in rng:
                t = a + (b - a) * i / n; w = h * math.sin(math.pi * (t - a) / (b - a)) ** 0.8
                pts.append((ax + ex * L * t + nx * w * side, ay + ey * L * t + ny * w * side))
        return pts

    c.poly(P(s, lens(4.3)))                                                      # the pod
    c.poly(P(s, lens(3.0, 0.07, 0.93)), v=0)                                     # open
    for t in (0.27, 0.5, 0.73):
        c.dot(u(ax + ex * L * t), u(ay + ey * L * t), u(1.85) - u(0))            # the peas
    c.line(P(s, [(14.4, 2.2), (15.4, 0.6)]), W(s, 1.2, 1.8))                      # the stalk


@icon("pet_bowl", "ctx2", "a pet's bowl, food heaped in it: pet food, animal feed", ["ContextMenu_FoodType_CatFood", "ContextMenu_FoodType_AnimalFeed"])
def pet_bowl(c, s):
    c.poly(P(s, [(1, 9.5), (15, 9.5), (13, 14), (3, 14)]))
    u = U(s)
    for x, y in ((4.5, 8), (7, 7), (9.5, 7.2), (12, 8), (8.2, 5.2), (5.8, 5.4), (10.6, 5.6)): c.dot(u(x), u(y), W(s, 1.2, 1.8))
    c.rect(u(1), u(10.4), u(15) - u(1), W(s, 0.8, 1.2), v=0)


@icon("leaf", "ctx2", "a leaf, its vein: herbs, a poultice", ["ContextMenu_FoodType_Herb", "ContextMenu_PlantainCataplasm"])
def leaf(c, s):
    c.poly(P(s, [(2, 14), (3, 8), (6.5, 4), (12, 2), (14.5, 1.5), (14, 4), (12, 9.5), (8, 13), (3, 14.5)]))
    c.line(P(s, [(2.5, 14), (11.5, 4.5)]), W(s, 0.9, 1.3), v=0)


@icon("garlic", "ctx2", "a bulb of garlic: garlic", ["ContextMenu_GarlicCataplasm"])
def garlic(c, s):
    u = U(s)
    c.ellipse(u(8), u(10), u(6.5) - u(0), u(5) - u(0))
    c.poly(P(s, [(6.5, 6), (8, 1.5), (9.5, 6)]))
    for x in (5.5, 10.5): c.arc(u(8 if x < 8 else 8), u(10), u(abs(8 - x) + 0.01) - u(0), 0, 1, 1)
    c.line(P(s, [(5.8, 6.5), (5.2, 14)]), W(s, 0.8, 1.2), v=0, caps=False); c.line(P(s, [(10.2, 6.5), (10.8, 14)]), W(s, 0.8, 1.2), v=0, caps=False)
    c.rect(u(3), u(14.5), u(13) - u(3), W(s, 0.8, 1.2))
