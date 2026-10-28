"""The right-click menu, group 6, the last: vehicles, power, farming, animals, the safehouse, and the rest (warnings,
"more", "one", counts). Drawn in the wheels' ink to replace the menu's licensed pictures; what the wheels already
say is taken as it is (map.py CTX).

Coordinates are on the 16 grid's live area; U lays them out again on the 24 grid (i_ctx1)."""
import math

from kit import icon
from i_ctx1 import U, W, P


# ------------------------------------------------------------------ vehicles and power
@icon("tire", "ctx6", "a tyre, its tread and hub: change a tyre, let it down", ["Change Tire", "IGUI_DeflateTire"])
def tire(c, s):
    u = U(s)
    c.dot(u(8), u(8), u(7) - u(0))
    c.dot(u(8), u(8), u(4.4) - u(0), v=0)
    c.dot(u(8), u(8), u(2.8) - u(0))                                             # the hub
    c.dot(u(8), u(8), W(s, 0.8, 1.2), v=0)
    for k in range(10):                                                         # the tread, notches at the rim
        a = math.radians(k * 36)
        c.line([(u(8) + (u(6.2) - u(0)) * math.cos(a), u(8) + (u(6.2) - u(0)) * math.sin(a)),
                (u(8) + (u(7.4) - u(0)) * math.cos(a), u(8) + (u(7.4) - u(0)) * math.sin(a))], W(s, 0.9, 1.3), v=0, caps=False)


@icon("car_x", "ctx6", "the car, a cross: take a burnt-out car away", ["ContextMenu_RemoveBurntVehicle"])
def car_x(c, s):
    import i_world
    i_world.car(c, s); c.badge("x", corner="tr")


@icon("car_battery", "ctx6", "a car battery, its two terminals, plus and minus: the battery charger", ["ContextMenu_CarBatteryCharger"])
def car_battery(c, s):
    u = U(s)
    c.rect(u(1), u(4.5), u(15) - u(1), u(14.5) - u(4.5))
    c.rect(u(3), u(2.5), u(5.5) - u(3), u(4.5) - u(2.5)); c.rect(u(10.5), u(2.5), u(13) - u(10.5), u(4.5) - u(2.5))   # the terminals
    c.rect(u(3), u(8.5), u(6) - u(3), W(s, 1, 1.5), v=0); c.rect(u(4) , u(7.5), W(s, 1, 1.5), u(10.5) - u(7.5), v=0)   # plus
    c.rect(u(10), u(8.5), u(13) - u(10), W(s, 1, 1.5), v=0)                     # minus


def _plug(c, s):
    u = U(s)
    c.rrect(u(3), u(4.5), u(13) - u(3), u(10.5) - u(4.5), W(s, 1.5, 2.2))        # the plug's body
    c.rect(u(5), u(1), W(s, 1.5, 2.2), u(4.5) - u(1)); c.rect(u(11) - W(s, 1.5, 2.2), u(1), W(s, 1.5, 2.2), u(4.5) - u(1))   # its prongs
    c.rect(u(7), u(10.5), u(9) - u(7), u(15) - u(10.5))                           # the cable


@icon("plug", "ctx6", "a plug, its prongs and cable: plug in, wire a generator, charge", ["ContextMenu_GeneratorPlug", "Charge"])
def plug(c, s):
    _plug(c, s)


@icon("unplug", "ctx6", "the plug, a minus: unplug", ["ContextMenu_GeneratorUnplug"])
def unplug(c, s):
    _plug(c, s); c.badge("minus")


@icon("wires", "ctx6", "two wires, their bared ends, a spark jumping between: fix the wiring", ["Fix Wiring"])
def wires(c, s):
    u = U(s)
    c.line(P(s, [(0.5, 3), (4, 3), (5.5, 5.5)]), W(s, 2, 3))
    c.line(P(s, [(15.5, 13), (12, 13), (10.5, 10.5)]), W(s, 2, 3))
    import i_ctx1
    i_ctx1._sparkle(c, u(8), u(8), u(3.6) - u(0), W(s, 0.9, 1.3))               # the spark


@icon("bulb_remove", "ctx6", "the lit bulb, a minus: take a light out", ["Remove Light"])
def bulb_remove(c, s):
    import i_world
    i_world.bulb_on(c, s); c.badge("minus")


@icon("pipe", "ctx6", "a pipe, its elbow, a flange at each end: connect a pipe", ["Connect Pipe"])
def pipe(c, s):
    u = U(s)
    c.rect(u(2), u(3), u(12) - u(2), u(7) - u(3))                                 # along
    c.rect(u(8), u(3), u(12) - u(8), u(13.5) - u(3))                              # and down
    c.rect(u(0.8), u(2), u(2.6) - u(0.8), u(8) - u(2))                            # the flanges
    c.rect(u(7), u(13.2), u(13) - u(7), u(15) - u(13.2))
    c.rect(u(0.8), u(4.6), u(10.4) - u(0.8), W(s, 0.8, 1.2), v=0) if False else None


@icon("alarm_off", "ctx6", "the alarm clock, struck through: stop the alarm", ["ContextMenu_StopAlarm"])
def alarm_off(c, s):
    import i_sym
    i_sym.alarm(c, s); c.slash()


# ------------------------------------------------------------------ farming
@icon("plant", "ctx6", "a sprout in a mound of soil: plant, farming, gardening, a planter", ["Plant", "ContextMenu_Farming"])
def plant(c, s):
    u = U(s)
    c.ellipse(u(8), u(15), u(7) - u(0), u(4) - u(0))                              # the soil
    c.rect(u(7.25), u(4), u(8.75) - u(7.25), u(11.5) - u(4))                       # the stem
    c.poly(P(s, [(8, 7), (3, 4), (2, 1.5), (5.5, 1.5), (8, 4.5)]))                 # its leaves
    c.poly(P(s, [(8, 6), (12.5, 3), (14, 0.8), (10.5, 1), (8, 3.5)]))


@icon("crop", "ctx6", "a ripe ear of wheat, its grains paired up the stalk: harvest, the crops", ["Harvest", "ContextMenu_Crops"])
def crop(c, s):
    if s == 16:
        c.grid([".......##.......",
                ".......##.......",
                "....##.##.##....",
                ".....######.....",
                "....##.##.##....",
                ".....######.....",
                "....##.##.##....",
                ".....######.....",
                ".......##.......",
                "....##.##.......",
                ".....###........",
                ".......##.......",
                ".......##.......",
                ".......##......."], oy=1)
    else:
        c.grid(["..........####..........",
                "..........####..........",
                "..........####..........",
                "......###.####.###......",
                ".......##########.......",
                "........########........",
                "......###.####.###......",
                ".......##########.......",
                "........########........",
                "......###.####.###......",
                ".......##########.......",
                "........########........",
                "..........####..........",
                "......###.####..........",
                ".......#######..........",
                "........######..........",
                "..........####..........",
                "..........####..........",
                "..........####..........",
                "..........####.........."], oy=2)


@icon("shovel", "ctx6", "a shovel: dig, till the soil, dig a grave, bury", ["Till Soil", "ContextMenu_Dig"])
def shovel(c, s):
    u = U(s)
    c.line(P(s, [(12.5, 3.5), (7, 9)]), W(s, 1.6, 2.4))                           # the shaft
    c.rect(u(11.5), u(1), u(15) - u(11.5), W(s, 1.6, 2.4)); c.line(P(s, [(13, 1.6), (12.5, 3.5)]), W(s, 1.6, 2.4))   # the grip
    c.poly(P(s, [(6, 7), (9, 10), (5, 15), (2, 15), (1, 12)]))                     # the blade
    c.line(P(s, [(5, 9.2), (3.4, 12.6)]), W(s, 0.8, 1.2), v=0)


@icon("compost", "ctx6", "a steaming heap: fertilise, the composter, take compost", ["Fertilize", "ContextMenu_Composter"])
def compost(c, s):
    u = U(s)
    c.ellipse(u(8), u(15), u(7) - u(0), u(7) - u(0)); c.rect(0, u(15), s, s, v=0)   # the heap
    for x, y in ((5, 11.5), (9, 10), (11, 12.6), (7, 13.4)): c.rect(u(x), u(y), W(s, 1, 1.5), W(s, 1, 1.5), v=0)
    for x0 in (5.5, 8, 10.5):
        c.line([(u(x0 + 0.6 * math.sin(i / 6 * 2 * math.pi)), u(1 + i * 0.6)) for i in range(9)], W(s, 1.1, 1.6))   # steam


@icon("seed", "ctx6", "three seeds, upright, apart, each with its seam: sow a seed, the seeds", ["ContextMenu_Sow_Seed", "ContextMenu_Seeds"])
def seed(c, s):
    u = U(s)
    for x, y in ((3.8, 11), (12.2, 11), (8, 4.2)):
        c.ellipse(u(x), u(y), u(2) - u(0), u(3) - u(0))
        c.rect(u(x) - W(s, 0.5, 0.75), u(y - 1.6), W(s, 1, 1.5), u(y + 1.6) - u(y - 1.6), v=0)   # its seam


@icon("scythe", "ctx6", "a scythe: the long handle, the blade sweeping out along the top: cut the grass", ["ContextMenu_ScytheGrass"])
def scythe(c, s):
    if s == 16:
        c.grid(["......#######...",
                "...##########...",
                ".####......###..",
                "##..........##..",
                "............##..",
                "...........##...",
                "...........##...",
                "........######..",
                "..........##....",
                "..........##....",
                ".........##.....",
                ".........##.....",
                ".........##.....",
                "........##......"], oy=1)
    else:
        c.grid(["..........##########....",
                "......##############....",
                "...#########.....#####..",
                ".#######..........####..",
                "####..............####..",
                "##................####..",
                "..................###...",
                ".................####...",
                ".................###....",
                ".............#########..",
                ".............#########..",
                "................###.....",
                "................###.....",
                "...............###......",
                "...............###......",
                "...............###......",
                "..............###.......",
                "..............###.......",
                "..............###.......",
                ".............###........"], oy=2)


@icon("feather", "ctx6", "a feather: its wide vane, the shaft, the quill: collect feathers", ["Collect Feathers"])
def feather(c, s):
    c.poly(P(s, [(15, 1), (13.5, 6), (9.5, 10.5), (4.5, 13), (3.5, 11.5), (5, 7.5), (9, 3.5)]))
    c.line(P(s, [(1, 15), (14.4, 1.6)]), W(s, 0.9, 1.3), v=0)                        # the shaft
    c.line(P(s, [(1, 15), (4.4, 11.6)]), W(s, 1.4, 2.1))                             # the quill
    c.line(P(s, [(10.6, 6.8), (13, 6.8)]), W(s, 0.8, 1.2), v=0); c.line(P(s, [(7, 10.4), (9.4, 10.6)]), W(s, 0.8, 1.2), v=0)   # notches in the vane


@icon("trap", "ctx6", "a cage trap, its door up: set a trap, check it, a trap", ["Set Trap", "Check Trap"])
def trap(c, s):
    u = U(s)
    t = W(s, 1.2, 1.8)
    c.rect(u(1), u(6), u(15) - u(1), u(14.5) - u(6)); c.rect(u(1) + t, u(6) + t, u(15) - u(1) - 2 * t, u(14.5) - u(6) - 2 * t, v=0)   # the cage
    for x in (4.5, 8, 11.5): c.rect(u(x), u(6), W(s, 1, 1.5), u(14.5) - u(6))          # its bars
    c.poly(P(s, [(1, 6), (5, 1), (6, 2), (2.6, 6)]))                                   # the door, propped up
    c.rect(u(4), u(1), u(11) - u(4), W(s, 1, 1.5)); c.rect(u(10.4), u(1), W(s, 1, 1.5), u(6) - u(1))   # its trigger


# ------------------------------------------------------------------ animals
@icon("rod", "ctx6", "a fishing rod, its line and reel: fish, a fishing net", ["ContextMenu_Fishing", "ContextMenu_FishingNet"])
def rod(c, s):
    u = U(s)
    c.line(P(s, [(1.5, 14.5), (13.5, 1.5)]), W(s, 1.4, 2.1))                       # the rod
    c.dot(u(4.6), u(10), u(1.8) - u(0))                                            # the reel
    c.line(P(s, [(13.5, 1.5), (15, 4), (15, 13)]), W(s, 0.8, 1.2), caps=False)     # the line
    c.arc(u(13.6), u(13), u(1.4) - u(0), 0, 180, W(s, 1, 1.4), caps=False)          # the hook


@icon("hook", "ctx6", "a fish hook, a worm on it: bait, a lure, add bait", ["ContextMenu_Lure", "ContextMenu_Discard_Bait"])
def hook(c, s):
    u = U(s)
    c.rect(u(9), u(1), u(11) - u(9), W(s, 1.4, 2))                                 # the eye
    c.line(P(s, [(10, 2), (10, 11)]), W(s, 1.6, 2.4), caps=False)                  # the shank
    c.arc(u(7), u(11), u(3) - u(0), 0, 180, W(s, 1.6, 2.4), caps=False)            # the bend
    c.poly(P(s, [(4, 11), (3, 7.5), (5.6, 9.4)]))                                   # the barb
    c.line(P(s, [(10, 5), (12.5, 6.5), (10, 8), (12.5, 9.5)]), W(s, 1.4, 2.1))      # the worm


@icon("hutch", "ctx6", "a hutch, its roof, door and ramp: the hutch, its animals", ["ContextMenu_Hutch"])
def hutch(c, s):
    u = U(s)
    c.poly(P(s, [(8, 1), (15.5, 6.5), (0.5, 6.5)]))                                 # the roof
    c.rect(u(2), u(6.5), u(14) - u(2), u(12) - u(6.5))                              # the house
    c.dot(u(8), u(9.6), u(1.8) - u(0), v=0); c.rect(u(6.2), u(9.6), u(9.8) - u(6.2), u(12) - u(9.6), v=0)   # its door
    c.line(P(s, [(9.6, 12), (14.5, 15)]), W(s, 1.4, 2.1))                           # the ramp
    c.rect(u(2), u(12), W(s, 1.4, 2.1), u(15) - u(12)); c.rect(u(13), u(12), W(s, 1.4, 2.1), u(14) - u(12))   # the legs


@icon("dna", "ctx6", "a strand of DNA, its two threads twisting, rungs between: an animal's genome, change it", ["ContextMenu_AnimalGenome", "ContextMenu_ModifyGenome"])
def dna(c, s):
    if s == 16:
        c.grid(["...##########...",
                "....##....##....",
                ".....##..##.....",
                "......####......",
                ".....##..##.....",
                "....##....##....",
                "...##########...",
                "...##########...",
                "....##....##....",
                ".....##..##.....",
                "......####......",
                ".....##..##.....",
                "....##....##....",
                "...##########..."], oy=1)
    else:
        c.grid(["...##################...",
                "....###..........###....",
                ".....###........###.....",
                "......###......###......",
                ".......###....###.......",
                "........###..###........",
                ".........######.........",
                "........###..###........",
                ".......###....###.......",
                "......###......###......",
                ".....###........###.....",
                "....###..........###....",
                "...##################...",
                "....###..........###....",
                ".....###........###.....",
                "......###......###......",
                ".......###....###.......",
                "........###..###........",
                ".........######.........",
                "........###..###........",
                ".......###....###.......",
                "......################.."], oy=1)


@icon("bug", "ctx6", "a beetle: insects, debug", ["ContextMenu_FoodType_Insect", "ContextMenu_Debug"])
def bug(c, s):
    u = U(s)
    c.ellipse(u(8), u(9.5), u(4.4) - u(0), u(5.2) - u(0))                           # the body
    c.dot(u(8), u(3.8), u(2.2) - u(0))                                              # the head
    c.rect(u(7.5), u(5.6), W(s, 1, 1.5), u(14.6) - u(5.6), v=0)                     # the wing case's line
    for y in (7, 10, 13):
        c.line(P(s, [(3.6, y), (1, y - 1)]), W(s, 1, 1.5)); c.line(P(s, [(12.4, y), (15, y - 1)]), W(s, 1, 1.5))   # the legs
    c.line(P(s, [(7, 2), (5, 0.5)]), W(s, 0.9, 1.3)); c.line(P(s, [(9, 2), (11, 0.5)]), W(s, 0.9, 1.3))   # feelers


# ------------------------------------------------------------------ the safehouse
@icon("flag", "ctx6", "a flag on its pole: claim the place", ["ContextMenu_WarClaim"])
def flag(c, s):
    u = U(s)
    c.rect(u(2.5), u(1), W(s, 1.6, 2.4), u(15) - u(1))                              # the pole
    c.poly(P(s, [(4, 1.5), (14.5, 1.5), (11.5, 5), (14.5, 8.5), (4, 8.5)]))         # the flag


def _shield(c, s):
    c.poly(P(s, [(8, 1), (14, 3), (13.5, 9), (8, 15), (2.5, 9), (2, 3)]))


@icon("shield_plain", "ctx6", "a shield: see the safehouse", ["ContextMenu_ViewSafehouse"])
def shield_plain(c, s):
    _shield(c, s)
    u = U(s); c.poly(P(s, [(8, 3), (12.2, 4.4), (11.8, 8.6), (8, 12.8)]), v=0)


@icon("shield_minus", "ctx6", "the shield, a minus: give up the safehouse", ["ContextMenu_SafehouseRelease"])
def shield_minus(c, s):
    _shield(c, s); c.badge("minus")


# ------------------------------------------------------------------ the rest: warnings, more, one, counts
@icon("warning", "ctx6", "a warning sign: a triangle, an exclamation mark: a warning, can't do it now", ["ContextMenu_Fuel_Full", "ContextMenu_DigWithHandsTT"])
def warning(c, s):
    u = U(s)
    c.poly(P(s, [(8, 1), (15.5, 14.5), (0.5, 14.5)]))
    c.rect(u(7.2), u(5.5), u(8.8) - u(7.2), u(10.5) - u(5.5), v=0)                   # the mark
    c.rect(u(7.2), u(11.6), u(8.8) - u(7.2), u(13.2) - u(11.6), v=0)


@icon("more", "ctx6", "three dots: more, misc, or", ["ContextMenu_More", "ContextMenu_Misc"])
def more(c, s):
    u = U(s)
    for x in (3, 8, 13): c.dot(u(x), u(8), u(1.9) - u(0))


@icon("one", "ctx6", "a figure one: one", ["ContextMenu_One"])
def one(c, s):
    u = U(s)
    c.rect(u(7), u(2), u(9.5) - u(7), u(13) - u(2))
    c.poly(P(s, [(7, 2), (9.5, 2), (9.5, 4), (4.5, 6), (4.5, 4.5)]))
    c.rect(u(4.5), u(13), u(12) - u(4.5), u(15) - u(13))


@icon("tally", "ctx6", "tally marks, four and a stroke through: uses, a count", ["ContextMenu_Uses"])
def tally(c, s):
    u = U(s)
    for x in (3, 6, 9, 12): c.rect(u(x), u(2), W(s, 1.5, 2.2), u(14) - u(2))
    c.line(P(s, [(1, 11.5), (15, 4.5)]), W(s, 1.5, 2.2))
