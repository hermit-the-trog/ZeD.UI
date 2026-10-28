"""The right-click menu, group 4: crafting and building (tools and their verbs, paint and cloth, fire and heat, the
house's parts, furniture, signs). Drawn in the wheels' ink to replace the menu's licensed pictures; bricks, the
screwdriver, the craft tools, the wrench, box up / down, rotate, the knife, minus, the needle, the campfire, the
match, the extinguisher, the broom, the fence, the chair, the bed, the up / down arrows and the skull are taken as
they are (map.py CTX).

Coordinates are on the 16 grid's live area; U lays them out again on the 24 grid (i_ctx1)."""
import math

from PIL import Image, ImageDraw

from kit import icon
from i_ctx1 import U, W, P


# ------------------------------------------------------------------ fixing up
@icon("barricade", "ctx4", "four boards nailed across a window, the way the game stacks them: barricade, unbarricade", ["ContextMenu_Barricade", "ContextMenu_Unbarricade"])
def barricade(c, s):
    # (group 4 round 1, director: "game stacks 4 kinda like you have done with 3 in planks, not cross")
    u = U(s)
    t = W(s, 1.5, 2.2)
    c.rect(u(2.5), u(1), t, u(15) - u(1)); c.rect(u(13.5) - t, u(1), t, u(15) - u(1))   # the window's sides, between the boards
    for i, (x0, x1) in enumerate(((0.5, 14.5), (1.5, 15.5), (0.5, 15), (1, 15.5))):
        y = 1.2 + i * 3.6
        c.rect(u(x0), u(y), u(x1) - u(x0), u(y + 2.6) - u(y))                     # a board
        for x in (x0 + 1.2, x1 - 2.2): c.rect(u(x), u(y + 0.8), W(s, 1, 1.5), W(s, 1, 1.5), v=0)   # its nails


@icon("upgrade", "ctx4", "layers stacked into a step, an arrow up: upgrade", ["ContextMenu_Upgrade"])
def upgrade(c, s):
    u = U(s)
    for y, x0, x1 in ((12, 1, 15), (8, 2.5, 11), (4, 4, 7.5)):
        c.rect(u(x0), u(y), u(x1) - u(x0), u(y + 3) - u(y))
    c.badge("up", corner="tr")


@icon("reinforce", "ctx4", "a shield, a plus: reinforce, fortify, claim a safehouse", ["Reinforce", "ContextMenu_SafehouseClaim"])
def reinforce(c, s):
    c.poly(P(s, [(8, 1), (14, 3), (13.5, 9), (8, 15), (2.5, 9), (2, 3)]))
    u = U(s)
    c.rect(u(7.25), u(4.5), u(8.75) - u(7.25), u(11.5) - u(4.5), v=0); c.rect(u(4.5), u(7.25), u(11.5) - u(4.5), u(8.75) - u(7.25), v=0)


# ------------------------------------------------------------------ tools
@icon("saw", "ctx4", "a handsaw by its shape: the long blade tapering to its tip, the closed handle: saw", ["Saw"])
def saw(c, s):
    # (group 4 round 1, director: "the teeth are so small on a saw at this scale it would be better to focus on the
    # shape of a saw and not the teeth")
    u = U(s)
    c.poly(P(s, [(0.5, 10.4), (11, 4.2), (11, 12.6), (0.5, 12.6)]))               # the blade
    c.rrect(u(10), u(2), u(15.5) - u(10), u(12.6) - u(2), W(s, 2, 3))             # the handle
    c.rrect(u(12), u(4.2), u(13.8) - u(12), u(9) - u(4.2), W(s, 0.8, 1.2), v=0)   # its grip
    c.rect(u(10), u(9.8), W(s, 0.9, 1.3), u(12.6) - u(9.8), v=0)                  # where blade and handle meet


@icon("hammer", "ctx4", "a claw hammer on the slant: the handle, the square face, the split claw: nail, hammer, masonry", ["Nail", "ContextMenu_Masonry"])
def hammer(c, s):
    # (group 4 round 1, director: "hammer ... need work")
    if s == 16:
        c.grid([".....##.........",
                "....####........",
                "....#####.......",
                ".....#####......",
                "......#####.....",
                ".......#####....",
                "......##.####...",
                ".....##...##.#..",
                "....##.....#..#.",
                "...##...........",
                "..##............",
                ".##.............",
                "##.............."], oy=1)
    else:
        u = U(s)
        c.line(P(s, [(1.6, 14.4), (9.4, 6.6)]), 3.6)                                # the handle
        dx, dy = 0.7071, 0.7071; nx, ny = -dy, dx
        cx, cy = 10.0, 6.0
        pts = [(cx - dx * 6.0 + nx * 2.3, cy - dy * 6.0 + ny * 2.3), (cx - dx * 6.0 - nx * 2.3, cy - dy * 6.0 - ny * 2.3),
               (cx + dx * 5.4 - nx * 1.5, cy + dy * 5.4 - ny * 1.5), (cx + dx * 5.4 + nx * 1.5, cy + dy * 5.4 + ny * 1.5)]
        c.poly(P(s, pts))                                                         # the head
        c.poly(P(s, [(cx + dx * 2.6, cy + dy * 2.6), (cx + dx * 5.8 + nx * 0.8, cy + dy * 5.8 + ny * 0.8),
                     (cx + dx * 5.8 - nx * 0.8, cy + dy * 5.8 - ny * 0.8)]), v=0)    # the claw's split
        c.line(P(s, [(cx - dx * 3.4 + nx * 2.6, cy - dy * 3.4 + ny * 2.6), (cx - dx * 3.4 - nx * 2.6, cy - dy * 3.4 - ny * 2.6)]), 1.2, v=0, caps=False)


@icon("welder", "ctx4", "a welding helmet, its visor slot, a spark: weld, metalwork", ["Weld", "ContextMenu_MetalWelding"])
def welder(c, s):
    # (group 4 round 1, director: "welder ... need work": the torch became the helmet)
    u = U(s)
    c.ellipse(u(7), u(7), u(6) - u(0), u(6) - u(0))                              # the helmet's dome
    c.poly(P(s, [(1, 7), (13, 7), (12, 12), (9.5, 15), (4.5, 15), (2, 12)]))       # down to the chin
    c.rrect(u(2.6), u(6), u(11.4) - u(2.6), u(8.6) - u(6), W(s, 0.8, 1.2), v=0)   # the visor
    for x in (5.5, 8.5): c.rect(u(x), u(11.5), W(s, 1, 1.5), u(13.5) - u(11.5), v=0)   # the vents
    import i_ctx1
    i_ctx1._sparkle(c, u(13.6), u(2.4), u(2.4) - u(0), W(s, 0.7, 1.0))             # a spark


@icon("sledge", "ctx4", "a sledgehammer: crush, smash, destroy, take down a floor", ["Crush", "ContextMenu_Destroy"])
def sledge(c, s):
    u = U(s)
    c.line(P(s, [(2, 14.5), (10, 6.5)]), W(s, 1.8, 2.7))                          # the shaft
    c.poly(P(s, [(6.5, 4.5), (10.5, 0.5), (15.5, 5.5), (11.5, 9.5)]))             # the head
    c.line(P(s, [(9, 2.6), (13.4, 7)]), W(s, 0.8, 1.2), v=0)


# ------------------------------------------------------------------ paint and cloth
@icon("paintbrush", "ctx4", "a paintbrush: apply, varnish", ["Apply"])
def paintbrush(c, s):
    c.line(P(s, [(10, 6), (14.5, 1.5)]), W(s, 1.8, 2.7))                          # the handle
    c.poly(P(s, [(7.5, 5), (11, 8.5), (9.5, 10), (6, 6.5)]))                      # the ferrule
    c.poly(P(s, [(5.5, 7), (9, 10.5), (4, 15), (1, 15), (1, 12)]))                # the bristles
    c.line(P(s, [(6.8, 8.6), (3, 13)]), W(s, 0.8, 1.2), v=0)


@icon("paint", "ctx4", "a paint can, paint running down over its label: paint, dye, colours, wall coverings", ["ContextMenu_Paint", "Dye"])
def paint(c, s):
    u = U(s)
    c.arc(u(8), u(5), u(5) - u(0), 180, 360, W(s, 1.1, 1.6), caps=False)          # the handle
    c.rrect(u(2.5), u(5), u(13.5) - u(2.5), u(15) - u(5), W(s, 1, 1.5))           # the can
    c.rect(u(2.5), u(6.6), u(13.5) - u(2.5), W(s, 1, 1.5), v=0)                   # its lid's edge
    c.rect(u(3.8), u(9), u(12.2) - u(3.8), u(12.5) - u(9), v=0)                   # the label
    c.rect(u(5), u(9), W(s, 1.5, 2.2), u(11.5) - u(9)); c.rect(u(9.5), u(9), W(s, 1.5, 2.2), u(10.5) - u(9))   # paint running down


@icon("roller", "ctx4", "a paint roller: plaster, paint a sign", ["ContextMenu_Plaster", "ContextMenu_PaintSign"])
def roller(c, s):
    u = U(s)
    c.rrect(u(1), u(1), u(13) - u(1), u(6) - u(1), W(s, 1, 1.5))                  # the roller
    c.line(P(s, [(13, 3.5), (15, 3.5), (15, 8), (8, 9), (8, 10.5)]), W(s, 1.2, 1.8), caps=False)   # the frame
    c.rect(u(6.8), u(10.5), u(9.2) - u(6.8), u(15) - u(10.5))                     # the grip


@icon("yarn", "ctx4", "a ball of yarn, its strands, two needles through it: knit", ["Knit"])
def yarn(c, s):
    u = U(s)
    c.dot(u(7.5), u(9), u(6) - u(0))
    for k in (-2.6, 0, 2.6):
        c.line(P(s, [(3.2 + k, 12.8 + k), (11.8 + k, 4.2 + k)]), W(s, 0.8, 1.2), v=0, caps=False)   # the strands
    c.line(P(s, [(9.5, 4), (15, 1)]), W(s, 1.2, 1.8)); c.line(P(s, [(11, 6.5), (15.5, 5)]), W(s, 1.2, 1.8))   # the needles
    c.line(P(s, [(11, 13.5), (13.5, 14.5), (15.5, 13)]), W(s, 1, 1.5))           # a loose end


@icon("fabric", "ctx4", "a bolt of cloth: the roll, its end showing, the sheet hanging from it to a pinked edge: fabric, weave, a pattern", ["Weave", "ContextMenu_BlackFloral"])
def fabric(c, s):
    u = U(s)
    c.rrect(u(1), u(1), u(15) - u(1), u(5.5) - u(1), W(s, 2.2, 3.2))              # the roll
    c.dot(u(3.2), u(3.25), u(1.7) - u(0), v=0); c.dot(u(3.2), u(3.25), u(0.8) - u(0))   # its end, rolled
    c.rect(u(1), u(5.5), u(15) - u(1), W(s, 1, 1.5), v=0)
    c.rect(u(3.5), u(6.5), u(12.5) - u(3.5), u(13) - u(6.5))                      # the sheet
    for i in range(6):                                                            # its pinked edge
        x = 3.5 + i * 1.5
        c.poly(P(s, [(x, 13), (x + 1.5, 13), (x + 0.75, 14.8)]))
    for y in (8.6, 11): c.rect(u(3.5), u(y), u(12.5) - u(3.5), W(s, 1, 1.5), v=0)   # the stripes


# ------------------------------------------------------------------ fire and heat
@icon("grill", "ctx4", "a kettle grill: its domed lid, the grate, the bowl and legs: the barbecue, add fuel", ["ContextMenu_BBQ", "Add Fuel"])
def grill(c, s):
    u = U(s)
    c.ellipse(u(8), u(7.2), u(6.5) - u(0), u(4) - u(0)); c.rect(0, 0, s, u(7.2), v=0)  # the bowl
    c.ellipse(u(8), u(6), u(6.5) - u(0), u(4.5) - u(0)); c.rect(0, u(6), s, u(7.2) - u(6), v=0)   # the lid
    c.rect(u(7), u(0.6), u(9) - u(7), u(2) - u(0.6))                                   # its handle
    c.rect(u(1.5), u(5.4), u(14.5) - u(1.5), W(s, 0.8, 1.2), v=0)                      # the lid's edge
    c.line(P(s, [(5, 10.5), (2.5, 15)]), W(s, 1.2, 1.8)); c.line(P(s, [(11, 10.5), (13.5, 15)]), W(s, 1.2, 1.8)); c.line(P(s, [(8, 11), (8, 15)]), W(s, 1.2, 1.8))


@icon("fireplace", "ctx4", "a fireplace, a fire in it: the fireplace, a stone furnace", ["ContextMenu_Fireplace", "ContextMenu_Stone_Furnace"])
def fireplace(c, s):
    u = U(s)
    c.rect(u(0.5), u(1.5), u(15.5) - u(0.5), u(3.5) - u(1.5))                     # the mantel
    c.rect(u(1.5), u(3.5), u(14.5) - u(1.5), u(15) - u(3.5))
    c.rect(u(4.5), u(7), u(11.5) - u(4.5), u(15) - u(7), v=0)                     # the hearth's opening
    c.poly(P(s, [(8, 8), (10, 11), (10, 13.5), (6, 13.5), (6, 11)]))               # the fire
    c.rect(u(5), u(14), u(11) - u(5), W(s, 1, 1.5))


# ------------------------------------------------------------------ the house's parts
@icon("ladder", "ctx4", "a ladder: climb up, a way across", ["ContextMenu_Traversable"])
def ladder(c, s):
    u = U(s)
    c.rect(u(3), u(1), W(s, 2, 3), u(15) - u(1)); c.rect(u(13) - W(s, 2, 3), u(1), W(s, 2, 3), u(15) - u(1))
    for y in (3, 6.5, 10, 13.5): c.rect(u(3), u(y), u(13) - u(3), W(s, 1.3, 2))


@icon("stairs", "ctx4", "a flight of stairs: stairs", ["ContextMenu_Stairs"])
def stairs(c, s):
    if s == 16:
        c.grid([".........######",
                ".........#.....",
                "......####.....",
                "......#........",
                "...####........",
                "...#...........",
                "####...........",
                "#..............",
                "#.............."], ox=1, oy=3)
        c.poly([(1, 15), (15, 15), (15, 3)]) if False else None
        for y in range(3, 15):
            x0 = {3: 10, 4: 10, 5: 7, 6: 7, 7: 7, 8: 4, 9: 4, 10: 4, 11: 1, 12: 1, 13: 1, 14: 1}[y]
            c.rect(x0, y, 15 - x0, 1)
    else:
        for i in range(5):
            c.rect(1 + i * 4.4, 21 - (i + 1) * 4, 23 - 1 - i * 4.4, 4.0)


@icon("curtains", "ctx4", "curtains drawn back from a window: open, close or take down curtains", ["ContextMenu_Open_curtains", "ContextMenu_Close_curtains"])
def curtains(c, s):
    u = U(s)
    c.rect(u(0.5), u(1), u(15.5) - u(0.5), W(s, 1.3, 2))                         # the rail
    c.poly(P(s, [(1, 2.5), (5.5, 2.5), (3.5, 9), (5, 15), (1, 15)]))              # the curtains
    c.poly(P(s, [(15, 2.5), (10.5, 2.5), (12.5, 9), (11, 15), (15, 15)]))
    c.line(P(s, [(2.5, 9.5), (4.4, 9.5)]), W(s, 0.8, 1.2), v=0); c.line(P(s, [(13.5, 9.5), (11.6, 9.5)]), W(s, 0.8, 1.2), v=0)   # the ties


@icon("door", "ctx4", "a door, its two panels and handle: a door, a door frame", ["ContextMenu_Door", "ContextMenu_Door_Frame"])
def door(c, s):
    if s == 16:
        c.rect(3, 1, 10, 14)
        for y0 in (3, 9):
            c.rect(5, y0, 6, 1, v=0); c.rect(5, y0 + 4, 6, 1, v=0); c.rect(5, y0, 1, 5, v=0); c.rect(10, y0, 1, 5, v=0)
        c.rect(11, 8, 1, 1, v=0)
    else:
        c.rect(4, 1, 16, 22)
        for y0 in (3.5, 13):
            c.rect(7, y0, 10, 1.5, v=0); c.rect(7, y0 + 6.5, 10, 1.5, v=0); c.rect(7, y0, 1.5, 8, v=0); c.rect(15.5, y0, 1.5, 8, v=0)
        c.rect(17.5, 12, 1.5, 1.5, v=0)


@icon("window", "ctx4", "a house window, its frame and bars: a window frame", ["ContextMenu_Windows_Frame"])
def window(c, s):
    u = U(s); t = W(s, 2, 3)
    c.rect(u(1.5), u(1), u(14.5) - u(1.5), u(14) - u(1)); c.rect(u(1.5) + t, u(1) + t, u(14.5) - u(1.5) - 2 * t, u(14) - u(1) - 2 * t, v=0)
    c.rect(u(8) - t / 2, u(1), t, u(14) - u(1)); c.rect(u(1.5), u(7.5) - t / 2, u(14.5) - u(1.5), t)
    c.rect(u(0.5), u(14), u(15.5) - u(0.5), W(s, 1.4, 2))                          # the sill


@icon("floor", "ctx4", "floor tiles in perspective, flat and wide: a floor, a roof, tiles", ["ContextMenu_Floor", "ContextMenu_Tile_Floor"])
def floor(c, s):
    # (group 4 round 1, director: "floor small ... need work": flatter and wider, four tiles at 16, laid out pixel by pixel)
    if s == 16:
        top, bot, xt0, xt1, xb0, xb1 = 6, 14, 3.0, 13.0, 0.0, 16.0
        rows_at, cols = (10,), (0.5,)
    else:
        top, bot, xt0, xt1, xb0, xb1 = 8, 22, 4.0, 20.0, 0.0, 24.0
        rows_at, cols = (12, 16), (1 / 3, 2 / 3)
    for y in range(top, bot + 1):
        f = (y - top) / (bot - top)
        x0 = xt0 + (xb0 - xt0) * f; x1 = xt1 + (xb1 - xt1) * f
        w = x1 - x0
        for x in range(s):
            px = x + 0.5
            if not (x0 - 0.01 <= px <= x1 + 0.01): continue
            seam = y in rows_at or any(abs(px - (x0 + w * k + 0.01)) < 0.5 for k in cols)
            if not seam: c.rect(x, y, 1, 1)


@icon("planks", "ctx4", "planks of wood, their grain: wooden, wood", ["Wooden"])
def planks(c, s):
    u = U(s)
    for y in (2, 6.5, 11):
        c.rect(u(1), u(y), u(15) - u(1), u(y + 3.6) - u(y))
        c.line(P(s, [(3, y + 1.8), (7, y + 1.4), (10, y + 2.1)]), W(s, 0.8, 1.2), v=0)   # grain
        c.dot(u(12.5), u(y + 1.8), W(s, 0.9, 1.3), v=0)                                # a knot


# ------------------------------------------------------------------ furniture, signs
@icon("table", "ctx4", "a table: tables", ["ContextMenu_Table", "ContextMenu_Large_Table"])
def table(c, s):
    u = U(s)
    c.rect(u(0.5), u(4), u(15.5) - u(0.5), u(6.5) - u(4))                         # the top
    c.rect(u(2), u(6.5), W(s, 2, 3), u(15) - u(6.5)); c.rect(u(14) - W(s, 2, 3), u(6.5), W(s, 2, 3), u(15) - u(6.5))   # the legs
    c.rect(u(2), u(7.5), u(14) - u(2), W(s, 1.2, 1.8))                            # the apron


@icon("bookcase", "ctx4", "a bookcase full of books: a bookcase", ["ContextMenu_Bookcase"])
def bookcase(c, s):
    if s == 16:
        c.rect(2, 1, 12, 14); c.rect(3, 2, 10, 12, v=0)
        c.rect(2, 7, 12, 1)                                                     # the shelf
        for x, top in ((4, 3), (6, 4), (8, 3), (10, 3), (11, 5)): c.rect(x, top, 1, 7 - top)
        for x, top in ((4, 9), (5, 10), (7, 9), (9, 9), (11, 10)): c.rect(x, top, 1, 14 - top)
    else:
        c.rect(2, 1, 20, 22); c.rect(4, 3, 16, 18, v=0)
        c.rect(2, 11, 20, 2)
        for x, top in ((5, 4), (8, 5), (11, 4), (14, 4), (17, 6)): c.rect(x, top, 2, 11 - top)
        for x, top in ((5, 14), (8, 15), (11, 14), (14, 14), (17, 16)): c.rect(x, top, 2, 21 - top)


@icon("shelves", "ctx4", "open shelves, things on them: shelves, a counter", ["ContextMenu_Shelves", "ContextMenu_MetalShelves"])
def shelves(c, s):
    u = U(s)
    c.rect(u(1.5), u(1), W(s, 1.5, 2.2), u(15) - u(1)); c.rect(u(14.5) - W(s, 1.5, 2.2), u(1), W(s, 1.5, 2.2), u(15) - u(1))
    for y in (5, 10, 14): c.rect(u(1.5), u(y), u(14.5) - u(1.5), W(s, 1.4, 2))
    c.rect(u(4), u(2), u(7) - u(4), u(5) - u(2)); c.rect(u(9), u(3), u(12) - u(9), u(5) - u(3))   # boxes, a jar
    c.rect(u(4.5), u(7), u(10) - u(4.5), u(10) - u(7)); c.dot(u(12), u(8.6), W(s, 1.4, 2))


@icon("locker", "ctx4", "a metal locker, its vents and handle: a locker, a metal crate", ["ContextMenu_SmallLocker", "ContextMenu_MetalCrate"])
def locker(c, s):
    u = U(s)
    c.rect(u(3.5), u(1), u(12.5) - u(3.5), u(15) - u(1))
    for y in (2.8, 4.4, 6): c.rect(u(5.5), u(y), u(10.5) - u(5.5), W(s, 0.8, 1.2), v=0)   # the vents
    c.rect(u(9.5), u(8.5), W(s, 1, 1.5), u(11) - u(8.5), v=0)                      # the handle
    c.rect(u(3.5), u(13.5), u(12.5) - u(3.5), W(s, 0.8, 1.2), v=0)


@icon("tombstone", "ctx4", "a gravestone, a cross on it: a tombstone, a grave", ["ContextMenu_Tombstone"])
def tombstone(c, s):
    u = U(s)
    c.ellipse(u(8), u(6), u(5.5) - u(0), u(5) - u(0)); c.rect(u(2.5), u(6), u(13.5) - u(2.5), u(14) - u(6))
    c.rect(u(7.25), u(3.5), u(8.75) - u(7.25), u(10) - u(3.5), v=0); c.rect(u(5.5), u(5.25), u(10.5) - u(5.5), u(6.75) - u(5.25), v=0)
    c.rect(u(1), u(14), u(15) - u(1), W(s, 1.3, 2))                                # the ground


def _rot(c, src, s, transpose):
    src(c, s)
    c.im = c.im.transpose(transpose); c.d = ImageDraw.Draw(c.im)


@icon("arrow_right", "ctx4", "an arrow pointing right: a sign's right arrow", ["ContextMenu_SignRightArrow"])
def arrow_right(c, s):
    import i_ui
    _rot(c, i_ui.move_down, s, Image.TRANSPOSE)


@icon("arrow_left", "ctx4", "an arrow pointing left: a sign's left arrow", ["ContextMenu_SignLeftArrow"])
def arrow_left(c, s):
    import i_ui
    _rot(c, i_ui.move_up, s, Image.TRANSPOSE)
