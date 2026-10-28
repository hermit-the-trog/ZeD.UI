"""The right-click menu, group 1: everyday actions (moving and sleeping, your things, reading, habits, washing,
grooming, clothes). Drawn in the wheels' ink to replace the menu's licensed pictures (shared/ZeD/ContextIcons.lua);
what a wheel or the container row already says is taken as it is (map.py CTX).

Drawn here: sleeping_bag, pillow, tent, tent_down, climb_window, rope_climb, dumbbell, star_off, box_open, combine,
tooth, nose, wash_hands, washer, sparkle, broom, towel, razor, comb, lipstick, hanger, needle, patch, rip, equip,
unequip, cap, mask, scarf. (The hood toggles take the wheels' jacket.)

Some are hand-placed grids at each size; the rest are drawn once on the 16 grid's live area and laid out again for
24 through U (a unit on the 16 grid maps to 1 + (u - 1) * 22/14 on the 24 grid), lines taking their width per size.
"""
from kit import icon


def U(s):
    """the 16 grid's coordinates on this size's grid"""
    if s == 16: return lambda v: v
    k = 22 / 14
    return lambda v: 1 + (v - 1) * k


def W(s, w16, w24):
    return w16 if s == 16 else w24


def P(s, pts):
    u = U(s); return [(u(x), u(y)) for x, y in pts]


# ------------------------------------------------------------------ moving and sleeping
@icon("sleeping_bag", "ctx1", "a head out of a sleeping bag on the ground: sleep on the ground", ["ContextMenu_SleepOnGround"])
def sleeping_bag(c, s):
    if s == 16:
        c.grid(["......########..",
                ".##..##########.",
                "####.##.##.####.",
                "####.##.##.#####",
                ".##..##.##.#####",
                "......#########.",
                "................",
                "################"], oy=6)
    else:
        c.grid(["..........###########...",
                "..###....#############..",
                ".#####...#############..",
                "#######..###..###..####.",
                "#######..###..###..#####",
                "#######..###..###..#####",
                ".#####...###..###..#####",
                "..###....###..###..####.",
                ".........#############..",
                "..........###########...",
                "........................",
                "........................",
                "########################",
                "########################"], oy=8)


@icon("pillow", "ctx1", "a plump pillow: sleep on the ground with a pillow", ["ContextMenu_SleepOnGroundPillow"])
def pillow(c, s):
    if s == 16:
        c.grid([".##..........##.",
                ".##############.",
                "..############..",
                "..############..",
                "..#####..#####..",
                "..############..",
                "..############..",
                ".##############.",
                ".##..........##."], oy=4)
    else:
        c.grid([".###................###.",
                ".######..........######.",
                "..####################..",
                "..####################..",
                "...##################...",
                "...##################...",
                "...#######....#######...",
                "...#######....#######...",
                "...##################...",
                "...##################...",
                "..####################..",
                "..####################..",
                ".######..........######.",
                ".###................###."], oy=5)


def _tent(c, s):
    if s == 16:
        c.grid([".......##.......",
                ".......##.......",
                "......####......",
                "......####......",
                ".....######.....",
                ".....######.....",
                "....########....",
                "....###..###....",
                "...####..####...",
                "...###....###...",
                "..####....####..",
                "..###......###..",
                ".####......####.",
                "################"], oy=1)
    else:
        c.poly(P(s, [(8, 1.2), (15.2, 14), (0.8, 14)]))
        c.poly(P(s, [(8, 7.6), (10.4, 13.2), (5.6, 13.2)]), v=0)
        u = U(s); c.rect(u(0.8), u(14) - 1, u(15.2) - u(0.8), 2)


@icon("tent", "ctx1", "a tent, its door open: sleep in the tent, put it up", ["ContextMenu_Sleep_in_tent", "ContextMenu_Set_Up_Tent"])
def tent(c, s):
    _tent(c, s)


@icon("tent_down", "ctx1", "the tent, an arrow down: take it down", ["ContextMenu_Take_Down_Tent"])
def tent_down(c, s):
    _tent(c, s); c.badge("down", corner="tr")


@icon("climb_window", "ctx1", "an arrow into a window: climb through", ["ContextMenu_Climb_through"])
def climb_window(c, s):
    if s == 16:
        c.grid(["......##########",
                "......##########",
                "......##......##",
                "........#.....##",
                "........##....##",
                "........###...##",
                "############..##",
                "############..##",
                "........###...##",
                "........##....##",
                "........#.....##",
                "......##......##",
                "......##########",
                "....############"], oy=1)
    else:
        c.rect(9, 1, 14, 3); c.rect(20, 1, 3, 22); c.rect(9, 20, 14, 3); c.rect(6, 21, 17, 2)   # the window frame, its sill
        c.rect(9, 1, 3, 5); c.rect(9, 17, 3, 6)
        c.rect(1, 10.5, 12, 3)                                                  # the arrow, in through it
        c.poly([(11, 6), (17.5, 12), (11, 18)])


@icon("rope_climb", "ctx1", "a rope of knotted sheets: climb the sheet rope, tie it", ["ContextMenu_Climb_Sheet_Rope", "ContextMenu_Tie_escape_rope"])
def rope_climb(c, s):
    u = U(s)
    c.rect(u(1), u(1), u(15) - u(1), W(s, 2, 3))                                # the sill it hangs from
    c.rect(u(7), u(1), u(9) - u(7), u(15) - u(1))                               # the rope
    for y in (5, 10): c.rrect(u(5), u(y), u(11) - u(5), u(y + 2.5) - u(y), W(s, 1, 1.5))   # the knots
    c.poly(P(s, [(8, 13), (10.5, 15), (5.5, 15)]))                              # the end, frayed


@icon("dumbbell", "ctx1", "a barbell with its plates: exercise", ["ContextMenu_Fitness"])
def dumbbell(c, s):
    u = U(s)
    c.rect(u(1), u(7), u(15) - u(1), u(9) - u(7))                               # the bar
    for x0, x1, y0, y1 in ((2, 4, 4, 12), (4.6, 6.4, 2.5, 13.5), (12, 14, 4, 12), (9.6, 11.4, 2.5, 13.5)):
        c.rect(u(x0), u(y0), u(x1) - u(x0), u(y1) - u(y0))


# ------------------------------------------------------------------ your things
@icon("star_off", "ctx1", "the star, struck through: no longer a favourite", ["ContextMenu_Unfavorite"])
def star_off(c, s):
    import i_row
    i_row.star(c, s); c.slash()


@icon("box_open", "ctx1", "a cardboard box, its flaps open: open it, put it in a container", ["ContextMenu_Open", "ContextMenu_MoveToContainer"])
def box_open(c, s):
    c.poly(P(s, [(2.5, 7.5), (13.5, 7.5), (13.5, 15), (2.5, 15)]))             # the box
    c.poly(P(s, [(2.5, 6.5), (0.5, 2.5), (6, 2.5), (7.5, 6.5)]))                # the flaps, open
    c.poly(P(s, [(8.5, 6.5), (10, 2.5), (15.5, 2.5), (13.5, 6.5)]))
    u = U(s); c.rect(u(6), u(10), u(10) - u(6), W(s, 1, 1.5), v=0)              # the hand hold


@icon("combine", "ctx1", "two arrows into one block: combine, merge", ["ContextMenu_Combine", "ContextMenu_MergeAll"])
def combine(c, s):
    u = U(s)
    c.rect(u(6), u(5), u(10) - u(6), u(11) - u(5))                              # what they make
    c.rect(u(1), u(7.25), u(3.5) - u(1), u(8.75) - u(7.25))
    c.poly(P(s, [(3, 5), (5.4, 8), (3, 11)]))
    c.rect(u(12.5), u(7.25), u(15) - u(12.5), u(8.75) - u(7.25))
    c.poly(P(s, [(13, 5), (10.6, 8), (13, 11)]))


# ------------------------------------------------------------------ habits
@icon("tooth", "ctx1", "a molar: chew", ["ContextMenu_Chew"])
def tooth(c, s):
    if s == 16:
        c.grid(["..####..####..",
                ".############.",
                "##############",
                "##############",
                "##############",
                "##############",
                ".############.",
                ".#####..#####.",
                ".####....####.",
                ".####....####.",
                "..###....###..",
                "..###....###..",
                "...#......#..."], ox=1, oy=2)
    else:
        c.grid(["...######....######...",
                ".####################.",
                "######################",
                "######################",
                "######################",
                "######################",
                "######################",
                "######################",
                "######################",
                ".####################.",
                ".########....########.",
                ".#######......#######.",
                ".#######......#######.",
                "..######......######..",
                "..######......######..",
                "..######......######..",
                "...#####......#####...",
                "...#####......#####...",
                "....###........###....",
                "....###........###...."], ox=1, oy=2)


@icon("nose", "ctx1", "a nose: the bridge widening to a rounded base, the crease of the wing, the nostril: sniff", ["ContextMenu_Sniff"])
def nose(c, s):
    # (round 2, director: "the face profile is odd. nose still needs work": the nose people know, drawn in ink)
    if s == 16:
        c.grid(["......####......",
                "......####......",
                "......#####.....",
                "......#####.....",
                "......######....",
                "......######....",
                "......#######...",
                "....#.#######...",
                "...##.########..",
                "..############..",
                ".##############.",
                ".##############.",
                ".##############.",
                ".####..########.",
                "..##....######.."], oy=1)
    else:
        c.grid([".........#####..........",
                ".........######.........",
                ".........######.........",
                ".........#######........",
                ".........#######........",
                ".........########.......",
                ".........########.......",
                ".........#########......",
                ".........#########......",
                ".........##########.....",
                ".......#.##########.....",
                "......##.###########....",
                ".....###.###########....",
                "....################....",
                "...##################...",
                "..####################..",
                ".#####################..",
                ".#####################..",
                ".#####################..",
                ".######...############..",
                "..####.....#########....",
                "...##.......#######....."], oy=1)


# ------------------------------------------------------------------ washing and grooming
@icon("wash_hands", "ctx1", "the open hand, soap bubbles: wash your hands", ["ContextMenu_WashHands"])
def wash_hands(c, s):
    import i_char
    i_char.hand(c, s)
    if s == 16:
        c.rect(10, 0, 6, 6, v=0); c.oring(13, 3, 2.6, 1); c.rect(9, 6, 2, 2, v=0); c.oring(10, 7, 1.4, 1)
    else:
        c.rect(15, 0, 9, 9, v=0); c.oring(19.5, 4.5, 4, 1.5); c.rect(13, 9, 4, 4, v=0); c.oring(15, 11, 2.2, 1.2)


@icon("washer", "ctx1", "a washing machine: wash clothes", ["ContextMenu_WashClothes"])
def washer(c, s):
    u = U(s)
    c.rrect(u(1.5), u(1), u(14.5) - u(1.5), u(15) - u(1), W(s, 1, 1.5))
    c.rect(u(1.5), u(4), u(14.5) - u(1.5), W(s, 1, 1.5), v=0)                  # the control strip's edge
    c.dot(u(4), u(2.5), W(s, 0.8, 1.2), v=0); c.dot(u(6.5), u(2.5), W(s, 0.8, 1.2), v=0)
    c.dot(u(8), u(10), u(4.6) - u(0), v=0)                                       # the door
    c.dot(u(8), u(10), u(3.1) - u(0))
    c.dot(u(8), u(10), u(1.7) - u(0), v=0)


def _sparkle(c, cx, cy, a, b):
    c.poly([(cx, cy - a), (cx + b, cy - b), (cx + a, cy), (cx + b, cy + b), (cx, cy + a), (cx - b, cy + b), (cx - a, cy), (cx - b, cy - b)])


@icon("sparkle", "ctx1", "sparkles: clean, bleach", ["ContextMenu_Clean", "ContextMenu_Bleach"])
def sparkle(c, s):
    u = U(s)
    _sparkle(c, u(6.5), u(9.5), u(6) - u(0), W(s, 1.2, 1.8))
    _sparkle(c, u(12.5), u(3.5), u(2.8) - u(0), W(s, 0.7, 1.0))
    _sparkle(c, u(13), u(12.5), u(2) - u(0), W(s, 0.6, 0.9))


@icon("broom", "ctx1", "a broom, upright: the handle, the binding, a full fan of bristles: mop, sweep, clear the ashes", ["ContextMenu_Sweep", "ContextMenu_Mop"])
def broom(c, s):
    # (group 4 round 1, director: "broom need work" ... "close, just too fork looking": a solid fan, a ragged edge, no long splits)
    n = s
    if s == 16:
        hx, hw, bind0, bind1, head0, head1, h0, h1 = 7, 2, 6, 8, 8, 15, 3.5, 7.0
    else:
        hx, hw, bind0, bind1, head0, head1, h0, h1 = 10.5, 3, 9, 12, 12, 23, 5.0, 11.0
    c.rect(hx, 1, hw, bind0 - 1)                                                  # the handle
    for y in range(bind0, bind1):                                                 # the binding
        c.rect(hx - (2 if s == 16 else 3), y, hw + (4 if s == 16 else 6), 1)
    rows = head1 - head0
    for y in range(head0, head1):                                                 # the bristles, a full fan
        f = (y - head0) / max(1, rows - 1)
        half = h0 + (h1 - h0) * f
        cx = n / 2
        x0, x1 = cx - half, cx + half
        for x in range(n):
            if x0 - 0.01 <= x + 0.5 <= x1 + 0.01:
                gap = False
                if y == head1 - 1 and x % 2 == 1: gap = True                      # a ragged edge
                if y == head1 - 2 and x % 4 == 1: gap = True                      # short gaps just above it
                if not gap: c.rect(x, y, 1, 1)


@icon("towel", "ctx1", "a towel over its rail: dry yourself, wring clothes out", ["ContextMenu_Dry_myself", "ContextMenu_WringClothes"])
def towel(c, s):
    if s == 16:
        c.grid(["################",
                "..############..",
                "..############..",
                "................",
                "..############..",
                "..############..",
                "..############..",
                "..############..",
                "................",
                "..############..",
                "..############..",
                "..#.#.#.#.#.#...",
                "..#.#.#.#.#.#..."], oy=2)
    else:
        c.rect(1, 2, 22, 2); c.rect(4, 4, 16, 4)
        c.rect(4, 9, 16, 9); c.rect(4, 19.5, 16, 2.5)
        for x in range(4, 20, 3): c.rect(x, 22, 2, 2)


@icon("razor", "ctx1", "a safety razor: trim the beard, shave", ["ContextMenu_TrimBeard", "ContextMenu_ShaveHair"])
def razor(c, s):
    u = U(s)
    c.rect(u(2), u(1.5), u(14) - u(2), u(5) - u(1.5))                           # the head
    c.rect(u(2), u(3), u(14) - u(2), W(s, 0.8, 1.2), v=0)                       # the blade's edge
    c.rect(u(7), u(5), u(9) - u(7), u(15) - u(5))                               # the handle
    for y in (9, 11, 13): c.rect(u(7), u(y), u(9) - u(7), W(s, 0.6, 1), v=0)   # its grip


@icon("comb", "ctx1", "a comb: untie or brush the hair", ["ContextMenu_UntieHair"])
def comb(c, s):
    if s == 16:
        c.rect(1, 3, 14, 4)
        for x in range(1, 15, 2): c.rect(x, 7, 1, 6)
    else:
        c.rect(2, 4, 20, 6)
        for i in range(7): c.rect(2 + 3 * i, 10, 2, 10)


@icon("lipstick", "ctx1", "a lipstick: make up", ["IGUI_MakeUp"])
def lipstick(c, s):
    u = U(s)
    c.rect(u(5), u(9), u(11) - u(5), u(15) - u(9))                              # the case
    c.rect(u(5.5), u(6.5), u(10.5) - u(5.5), u(8.2) - u(6.5))                   # the collar
    c.poly(P(s, [(6.2, 6), (6.2, 3), (9.8, 1), (9.8, 6)]))                       # the stick, cut on the slant


@icon("hanger", "ctx1", "a coat hanger: take clothes off, switch or store an outfit", ["ContextMenu_Unequip_Clothing", "ContextMenu_SwitchOutfit"])
def hanger(c, s):
    if s == 16:
        c.grid([".......###......",
                "......##.##.....",
                "..........##....",
                ".........##.....",
                "........##......",
                ".......####.....",
                "......##..##....",
                ".....##....##...",
                "....##......##..",
                "...##........##.",
                "..##..........##",
                ".###############",
                ".###############"], oy=1)
    else:
        c.arc(12, 4.5, 3, 180, 440, 2.4, caps=True)
        c.line([(12, 7.5), (12, 9)], 2.4)
        c.line([(12, 9), (2, 18.5)], 2.6); c.line([(12, 9), (22, 18.5)], 2.6)
        c.rect(1, 18, 22, 3)


@icon("needle", "ctx1", "a needle and its thread: sew, suture, mend clothes", ["ContextMenu_Repair_Clothing", "ContextMenu_Suture"])
def needle(c, s):
    if s == 16:
        c.grid(["...........###..",
                "..........#..#..",
                ".........##.##..",
                "........####.###",
                ".......####....#",
                "......####.....#",
                ".....####.......",
                "....####........",
                "...####.........",
                "..####..........",
                ".###............",
                ".#.............."], oy=1)
    else:
        # (the 16 drawn again at 24, director's round-1 note: "big needle needs to look more like smaller")
        c.grid(["..................####..",
                ".................##..##.",
                "................##...##.",
                "...............##...##..",
                "..............###..#####",
                ".............######...##",
                "............######....##",
                "...........######.....##",
                "..........######........",
                ".........######.........",
                "........######..........",
                ".......######...........",
                "......######............",
                ".....######.............",
                "....######..............",
                "...######...............",
                "..#####.................",
                "..####..................",
                ".###....................",
                ".##.....................",
                ".#......................"], oy=1)


@icon("patch", "ctx1", "a patch, stitched on: add or take off a patch", ["ContextMenu_PatchHole", "ContextMenu_AddPatch"])
def patch(c, s):
    if s == 16:
        c.rect(2, 2, 12, 12)
        for i in range(0, 8, 2):
            c.rect(4 + i, 4, 1, 1, v=0); c.rect(4 + i, 11, 1, 1, v=0)
            c.rect(4, 4 + i, 1, 1, v=0); c.rect(11, 4 + i, 1, 1, v=0)
        c.rect(11, 11, 1, 1, v=0)
    else:
        c.rect(2, 2, 20, 20)
        for i in range(0, 14, 4):
            c.rect(5 + i, 5, 2, 2, v=0); c.rect(5 + i, 17, 2, 2, v=0)
            c.rect(5, 5 + i, 2, 2, v=0); c.rect(17, 5 + i, 2, 2, v=0)


@icon("rip", "ctx1", "a cloth torn in two: rip into strips, tear clothing", ["ContextMenu_RipSheets", "ContextMenu_TearClothing"])
def rip(c, s):
    c.poly(P(s, [(1, 2), (7.5, 2), (6, 4.5), (8, 7), (6, 9.5), (8, 12), (6.5, 14), (1, 14)]))
    c.poly(P(s, [(9.5, 2), (15, 2), (15, 14), (9, 14), (10.5, 12), (8.5, 9.5), (10.5, 7), (8.5, 4.5)]))


# ------------------------------------------------------------------ clothes: equip, the cap, the mask, the scarf
@icon("equip", "ctx1", "the open hand, a plus: equip, take in hand", ["ContextMenu_Equip"])
def equip(c, s):
    import i_char
    i_char.hand(c, s); c.badge("plus")


@icon("unequip", "ctx1", "the open hand, a minus: unequip, put away", ["ContextMenu_Unequip"])
def unequip(c, s):
    import i_char
    i_char.hand(c, s); c.badge("minus")


@icon("cap", "ctx1", "a baseball cap, its brim: turn the cap forward or back", ["ContextMenu_ForwardCap", "ContextMenu_ReverseCap"])
def cap(c, s):
    if s == 16:
        c.grid(["....#####.......",
                "..#########.....",
                ".###########....",
                ".###########....",
                "############....",
                "############....",
                "############....",
                "############....",
                ".......#########",
                "........#######."], oy=4)
        c.rect(5, 4, 2, 1)                                                      # the button
    else:
        c.grid(["......#######...........",
                "....###########.........",
                "...#############........",
                "..###############.......",
                ".################.......",
                ".################.......",
                ".################.......",
                "#################.......",
                "#################.......",
                "#################.......",
                "#################.......",
                "#################.......",
                "..........##############",
                "...........############."], oy=5)
        c.rect(8, 3.5, 3, 1.5)


@icon("mask", "ctx1", "a face mask, its ear loops: cover the face or the head", ["ContextMenu_CoverFace", "ContextMenu_CoverHead"])
def mask(c, s):
    u = U(s)
    c.rrect(u(4), u(4), u(12) - u(4), u(12) - u(4), W(s, 1.5, 2.2))
    for y in (6.5, 8.5): c.rect(u(5), u(y), u(11) - u(5), W(s, 0.8, 1.2), v=0) # the pleats
    for x, a0, a1 in ((4, 90, 270), (12, -90, 90)):
        c.arc(u(x), u(8), u(2.6) - u(0), a0, a1, W(s, 1.1, 1.6), caps=False)   # the loops


@icon("scarf", "ctx1", "a scarf, knotted, its ends hanging: wear the scarf, over the face", ["ContextMenu_Scarf", "ContextMenu_ScarfOverFace"])
def scarf(c, s):
    u = U(s)
    c.rrect(u(2), u(2), u(14) - u(2), u(6) - u(2), W(s, 1.5, 2.2))              # round the neck
    c.ellipse(u(8), u(4), u(3.5) - u(0), u(1.2) - u(0), v=0)
    c.poly(P(s, [(6, 5), (9.5, 5), (8.5, 13), (5, 13)]))                         # the ends
    c.poly(P(s, [(9, 6), (12, 6.5), (13.5, 12), (10.5, 12)]))
    for x in (5.2, 6.6, 8.0): c.rect(u(x), u(13), W(s, 0.8, 1.2), u(15) - u(13))   # the fringe


@icon("tap", "ctx1", "a tap, a drop falling: wash a thing, wash up", ["ContextMenu_WashItem", "ContextMenu_WashAllContainer"])
def tap(c, s):
    if s == 16:
        c.grid(["....####........",
                "......##........",
                "..##########....",
                ".############...",
                ".############...",
                "..........###...",
                "..........###...",
                "................",
                "...........#....",
                "..........###...",
                "..........###...",
                "...........#....",
                "................",
                "################"], oy=1)
    else:
        c.rect(6, 1, 7, 2); c.rect(8.5, 3, 2, 2)                                 # the handle
        c.rrect(2, 5, 17, 4, 1); c.rect(15, 5, 4, 7)                             # the spout
        c.poly([(17, 13.5), (18.8, 17.5), (15.2, 17.5)]); c.dot(17, 18, 2)       # the drop
        c.rect(1, 21, 22, 2)                                                     # the basin's edge
