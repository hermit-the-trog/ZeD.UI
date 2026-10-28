"""The right-click menu, group 3: drinks and fluids (drinking and brewing, water and pouring, the fluid containers,
the fluid card's words). Drawn in the wheels' ink to replace the menu's licensed pictures; the glass (Drink), the
siphon, the question mark, the progress bar, the fuel pump and the backpack are the wheels' own (map.py CTX).

Coordinates are on the 16 grid's live area; U lays them out again on the 24 grid (i_ctx1)."""
import math

from kit import icon
from i_ctx1 import U, W, P


def drop(c, s, cx, top, h, v=255):
    """a drop, its point up: centre x, top y, height h (16-grid units)"""
    u = U(s); r = h * 0.38
    c.poly(P(s, [(cx, top), (cx + r * 0.98, top + h - r * 1.25), (cx - r * 0.98, top + h - r * 1.25)]), v=v)
    c.dot(u(cx), u(top + h - r), u(r) - u(0), v=v)


def _tumbler(c, s, level=None):
    """the wheels' glass without its straw: tapered, outlined; filled up to `level` (16-grid y) when given"""
    u = U(s)
    c.poly(P(s, [(2.5, 3), (13.5, 3), (12, 15), (4, 15)]))
    c.poly(P(s, [(3.7, 4.2), (12.3, 4.2), (11, 13.8), (5, 13.8)]), v=0)
    if level is not None:
        t = (level - 4.2) / (13.8 - 4.2)
        c.poly(P(s, [(3.7 + 1.3 * t + 0.4, level), (12.3 - 1.3 * t - 0.4, level), (11, 13.8), (5, 13.8)]))


def _steam(c, s, xs=(6, 9), y0=1.0, y1=5.0, amp=0.7):
    u = U(s)
    for x0 in xs:
        n = 14
        c.line([(u(x0 + amp * math.sin((y - y0) / (y1 - y0) * 2 * math.pi)), u(y)) for y in [y0 + i * (y1 - y0) / n for i in range(n + 1)]], W(s, 1.1, 1.6))


# ------------------------------------------------------------------ drinking and brewing
@icon("mug", "ctx3", "a steaming mug: tea, herbal tea, a kettle", ["Brew Tea", "Brew Herbal Tea"])
def mug(c, s):
    u = U(s)
    c.rrect(u(2), u(6.5), u(11.5) - u(2), u(15) - u(6.5), W(s, 1, 1.5))
    c.oring(u(11.8), u(10.4), u(3) - u(0), W(s, 1.6, 2.4))                       # the handle
    c.rrect(u(2), u(6.5), u(11.5) - u(2), u(15) - u(6.5), W(s, 1, 1.5))
    _steam(c, s, xs=(5, 8.5), y0=0.8, y1=5.2)


@icon("coffee_pot", "ctx3", "a coffee pot: coffee, brew coffee, liqueur", ["Brew Coffee", "ContextMenu_FoodType_Coffee"])
def coffee_pot(c, s):
    u = U(s)
    c.rect(u(4), u(1.5), u(11) - u(4), u(3) - u(1.5))                           # the lid
    c.poly(P(s, [(4.5, 3.5), (10.5, 3.5), (12.5, 9), (12.5, 15), (2.5, 15), (2.5, 9)]))   # the pot
    c.poly(P(s, [(2.6, 5.5), (0.5, 3.6), (0.8, 5.8), (2.6, 8)]))                  # the spout
    c.oring(u(13.4), u(9.5), u(2.4) - u(0), W(s, 1.4, 2.1)); c.rect(u(12.5), u(7), u(13.2) - u(12.5), u(12) - u(7), v=0) if False else None
    c.rect(u(2.5), u(9), u(12.5) - u(2.5), W(s, 1, 1.5), v=0)                   # the waist


@icon("juice", "ctx3", "a juice carton with its straw: juice, cider", ["Make Juice", "ContextMenu_FoodType_Juice"])
def juice(c, s):
    u = U(s)
    c.poly(P(s, [(3, 6), (6.5, 3), (12, 3), (12, 15), (3, 15)]))                 # the carton
    c.rect(u(6.5), u(3), W(s, 1, 1.5), u(15) - u(3), v=0)                        # its fold
    c.poly(P(s, [(7.5, 6), (11, 6), (11, 6.8), (7.5, 6.8)]), v=0)
    c.line(P(s, [(9.5, 3.5), (10.5, 0.8), (13, 0.5)]), W(s, 1.1, 1.6))           # the straw
    c.dot(u(9.6), u(10.5), u(2) - u(0), v=0); c.dot(u(9.6), u(10.5), u(1.2) - u(0))   # an orange on the label


@icon("cocktail", "ctx3", "a cocktail glass, a slice on its rim: a cocktail, mix a drink", ["Make Cocktail", "Fluid_Cocktail"])
def cocktail(c, s):
    u = U(s)
    c.poly(P(s, [(1.5, 3), (14.5, 3), (8, 9.5)]))                                 # the bowl
    c.rect(u(7.25), u(9), u(8.75) - u(7.25), u(14) - u(9))                       # the stem
    c.rect(u(4), u(14), u(12) - u(4), W(s, 1.2, 1.8))                            # the foot
    c.rect(u(1.5), u(4.4), u(14.5) - u(1.5), W(s, 0.9, 1.3), v=0)                # the drink's surface
    c.dot(u(13), u(2.2), u(2) - u(0)); c.dot(u(13), u(2.2), u(1) - u(0), v=0)   # the slice


@icon("blender", "ctx3", "a blender: blend, a mixture", ["Blend", "Fluid_Mixed_Fluids"])
def blender(c, s):
    u = U(s)
    c.rect(u(4.5), u(1), u(11.5) - u(4.5), u(2.5) - u(1))                       # the lid
    c.poly(P(s, [(4, 3), (12, 3), (11, 10), (5, 10)]))                           # the jar
    c.poly(P(s, [(5.2, 4.2), (10.8, 4.2), (10, 8.8), (6, 8.8)]), v=0)
    c.line(P(s, [(6.2, 7.8), (9.8, 6)]), W(s, 1, 1.5))                           # the blade
    c.rrect(u(3), u(10.6), u(13) - u(3), u(15) - u(10.6), W(s, 1, 1.5))          # the base
    c.dot(u(8), u(12.8), W(s, 1, 1.5), v=0)                                      # its knob


@icon("beer", "ctx3", "a mug of beer, its head of foam: beer, brew beer", ["Brew Beer", "ContextMenu_FoodType_Beer"])
def beer(c, s):
    u = U(s)
    for x, r in ((4, 2.2), (7, 2.6), (10, 2.2)): c.dot(u(x), u(4), u(r) - u(0))   # the foam
    c.rect(u(2), u(4.5), u(12) - u(2), u(15) - u(4.5))                           # the mug
    c.oring(u(12.5), u(9.5), u(3) - u(0), W(s, 1.6, 2.4))                        # its handle
    c.rect(u(2), u(4.5), u(12) - u(2), u(15) - u(4.5))
    c.rect(u(2), u(6.2), u(12) - u(2), W(s, 1, 1.5), v=0)                        # under the foam
    for x in (5, 9): c.rect(u(x), u(8.5), W(s, 1, 1.5), u(13.5) - u(8.5), v=0)   # the mug's ribs


@icon("wine", "ctx3", "a wine bottle, its label: wine, liquor, make wine, a glass bottle", ["Make Wine", "ContextMenu_FoodType_Wine"])
def wine(c, s):
    u = U(s)
    c.rect(u(7), u(0.5), u(9) - u(7), u(5) - u(0.5))                             # the neck
    c.poly(P(s, [(7, 5), (9, 5), (11.5, 7.5), (11.5, 15), (4.5, 15), (4.5, 7.5)]))
    c.rect(u(5.8), u(9.5), u(10.2) - u(5.8), u(12.5) - u(9.5), v=0)               # the label


@icon("wine_glass", "ctx3", "a wine glass, wine in its bowl: wine in a glass, champagne, a goblet", ["ContextMenu_EvolvedRecipe_WineInGlass", "Fluid_Container_Goblet"])
def wine_glass(c, s):
    u = U(s)
    c.ellipse(u(8), u(4), u(5) - u(0), u(5.4) - u(0)); c.rect(0, 0, s, u(1), v=0)   # the bowl
    c.ellipse(u(8), u(4), u(3.8) - u(0), u(4.2) - u(0), v=0); c.rect(0, 0, s, u(1), v=0)
    c.ellipse(u(8), u(4.4), u(3.8) - u(0), u(3.8) - u(0)); c.rect(u(3), 0, u(13) - u(3), u(5), v=0)   # the wine
    c.rect(u(3), u(1), W(s, 1.2, 1.8), u(5) - u(1)); c.rect(u(13) - W(s, 1.2, 1.8), u(1), W(s, 1.2, 1.8), u(5) - u(1))
    c.rect(u(7.25), u(9), u(8.75) - u(7.25), u(14) - u(9))                       # the stem
    c.rect(u(4.5), u(14), u(11.5) - u(4.5), W(s, 1.2, 1.8))                      # the foot


@icon("cup", "ctx3", "a takeaway cup, its lid and straw: a cup, a fountain cup", ["Fluid_Container_Cup", "Fluid_Container_CupFountain"])
def cup(c, s):
    u = U(s)
    c.rect(u(3), u(4.5), u(13) - u(3), u(6) - u(4.5))                            # the lid
    c.poly(P(s, [(3.8, 6.8), (12.2, 6.8), (11, 15), (5, 15)]))                   # the cup
    c.rect(u(4), u(9.5), u(12) - u(4), u(11.5) - u(9.5), v=0)                    # its sleeve's edge
    c.rect(u(4.4), u(10), u(11.6) - u(4.4), u(11) - u(10))
    c.line(P(s, [(9, 4.5), (10, 1), (12.5, 0.6)]), W(s, 1.1, 1.6))               # the straw


@icon("jar", "ctx3", "a jar, bubbles rising in it: ferment", ["Ferment"])
def jar(c, s):
    u = U(s)
    c.rect(u(4), u(1.5), u(12) - u(4), u(3.5) - u(1.5))                          # the lid
    c.rrect(u(3), u(4), u(13) - u(3), u(15) - u(4), W(s, 2, 3))                  # the jar
    for x, y, r in ((6, 11.5, 1.4), (9.5, 9.5, 1.1), (7.5, 7, 0.9), (10, 12.5, 0.8)):
        c.dot(u(x), u(y), u(r) - u(0), v=0)                                      # the bubbles


# ------------------------------------------------------------------ water and pouring
@icon("drop", "ctx3", "a drop of water: water, pour, drain, a fluid", ["Pour", "ContextMenu_Water"])
def drop_(c, s):
    drop(c, s, 8, 1, 14)
    u = U(s)
    c.rect(u(5.2), u(9.5), W(s, 1, 1.5), u(12) - u(9.5), v=0)                    # its shine


@icon("bottle", "ctx3", "a water bottle, its cap: a bottle, a canteen, fill the water bottle", ["Fill Water Bottle", "Fluid_Container_Bottle"])
def bottle(c, s):
    u = U(s)
    c.rect(u(6), u(0.5), u(10) - u(6), u(2.5) - u(0.5))                          # the cap
    c.poly(P(s, [(6.5, 3), (9.5, 3), (11.5, 5.5), (11.5, 15), (4.5, 15), (4.5, 5.5)]))
    for y in (7.5, 10.5): c.rect(u(4.5), u(y), u(11.5) - u(4.5), W(s, 1, 1.5), v=0)   # its ridges


@icon("rain", "ctx3", "a cloud, rain falling from it: collect rain, distil, a rain barrel", ["Collect Rain", "Distill Water"])
def rain(c, s):
    u = U(s)
    for x, y, r in ((5, 6, 3.2), (9, 4.5, 3.8), (12.3, 6.6, 2.6)): c.dot(u(x), u(y), u(r) - u(0))   # the cloud
    c.rect(u(2), u(6.5), u(14.5) - u(2), u(9.2) - u(6.5))
    for x, y in ((4.5, 11), (8, 12.3), (11.5, 11)): c.line(P(s, [(x + 0.8, y), (x - 0.4, y + 3)]), W(s, 1.4, 2.1))   # the rain


@icon("bucket", "ctx3", "a bucket, its handle: a bucket, a drum, a trough", ["ContextMenu_Metal_Drum", "ContextMenu_FeedingTrough"])
def bucket(c, s):
    u = U(s)
    c.arc(u(8), u(6.5), u(5.5) - u(0), 180, 360, W(s, 1.2, 1.8), caps=False)     # the handle
    c.poly(P(s, [(1.5, 6), (14.5, 6), (12.5, 15), (3.5, 15)]))
    c.rect(u(1.5), u(8), u(14.5) - u(1.5), W(s, 1, 1.5), v=0)                    # its band


@icon("fill", "ctx3", "the bucket, an arrow down into it: fill", ["Fill"])
def fill(c, s):
    bucket(c, s); c.badge("down", corner="tr")


@icon("empty", "ctx3", "the bucket, an arrow up out of it: empty", ["Empty"])
def empty(c, s):
    bucket(c, s); c.badge("up", corner="tr")


@icon("pour", "ctx3", "a jug tipped, pouring into a glass: transfer, pour from one to another", ["Transfer"])
def pour(c, s):
    u = U(s)
    c.poly(P(s, [(1, 3.5), (6, 1), (9.5, 5.5), (6.8, 8.2)]))                     # the jug, tipped
    c.poly(P(s, [(9.5, 5.5), (11.5, 5.2), (10.4, 6.8)]))
    c.line(P(s, [(11.2, 6.4), (11, 9.5)]), W(s, 1, 1.5))                          # the stream
    c.poly(P(s, [(7.5, 10), (14.5, 10), (13.5, 15), (8.5, 15)]))                 # the glass
    c.poly(P(s, [(8.6, 11), (13.4, 11), (12.7, 14), (9.3, 14)]), v=0)
    c.poly(P(s, [(8.9, 12.5), (13.1, 12.5), (12.7, 14), (9.3, 14)]))


@icon("filter", "ctx3", "a funnel, a drop below it: filter water", ["Filter Water"])
def filter_(c, s):
    u = U(s)
    c.poly(P(s, [(1.5, 1.5), (14.5, 1.5), (9.2, 7.5), (9.2, 10), (6.8, 10), (6.8, 7.5)]))
    c.rect(u(1.5), u(3), u(14.5) - u(1.5), W(s, 1, 1.5), v=0)                    # its rim
    drop(c, s, 8, 11, 4.6)


@icon("watering_can", "ctx3", "a watering can, its spout and rose: water a plant, pour water", ["Pour Water", "Water Plant"])
def watering_can(c, s):
    u = U(s)
    c.rrect(u(4), u(6), u(12) - u(4), u(15) - u(6), W(s, 1, 1.5))               # the can
    c.arc(u(6.5), u(6.5), u(3.4) - u(0), 180, 360, W(s, 1.4, 2.1), caps=False)  # the handle
    c.line(P(s, [(4.5, 12), (0.8, 6.5)]), W(s, 1.4, 2.1))                         # the spout
    c.poly(P(s, [(0, 5), (2.6, 4.6), (1.4, 7.6)]))                                # its rose
    c.rect(u(12), u(8), u(14) - u(12), W(s, 1.4, 2.1))


@icon("well", "ctx3", "a well, its roof and bucket: a well", ["Fluid_Container_Well"])
def well(c, s):
    u = U(s)
    c.poly(P(s, [(8, 0.5), (15, 4.5), (1, 4.5)]))                                 # the roof
    c.rect(u(2.5), u(4.5), W(s, 1.2, 1.8), u(10) - u(4.5)); c.rect(u(13.5) - W(s, 1.2, 1.8), u(4.5), W(s, 1.2, 1.8), u(10) - u(4.5))   # the posts
    c.rect(u(7.5), u(4.5), W(s, 1, 1.5), u(7) - u(4.5))                           # the rope
    c.rect(u(6.5), u(7), u(9.5) - u(6.5), u(9) - u(7))                            # the bucket
    c.rect(u(1), u(10), u(15) - u(1), u(15) - u(10))                              # the wall
    for y, x0 in ((12.5, 1), ): c.rect(u(1), u(y), u(15) - u(1), W(s, 0.9, 1.3), v=0)
    for x in (5, 11): c.rect(u(x), u(10), W(s, 0.9, 1.3), u(12.5) - u(10), v=0)
    c.rect(u(8), u(12.5), W(s, 0.9, 1.3), u(15) - u(12.5), v=0)


@icon("toilet", "ctx3", "a toilet, its tank and bowl: a toilet", ["Fluid_Container_WhiteToilet"])
def toilet(c, s):
    u = U(s)
    c.rect(u(2), u(1.5), u(6.5) - u(2), u(9) - u(1.5))                           # the tank
    c.rect(u(6.5), u(7), u(14.5) - u(6.5), u(9) - u(7))                          # the seat
    c.poly(P(s, [(3, 9.6), (14, 9.6), (12, 12.5), (9, 13), (9, 15), (4.5, 15), (4.5, 12.5)]))   # the bowl
    c.rect(u(2.5), u(3), W(s, 1, 1.5), W(s, 1, 1.5), v=0)                         # the flush handle


@icon("bath", "ctx3", "a bathtub, its tap: a bathtub", ["Fluid_Container_Bathtub"])
def bath(c, s):
    u = U(s)
    c.rrect(u(1), u(7.5), u(15) - u(1), u(13) - u(7.5), W(s, 2.2, 3.2))
    c.rect(u(0.5), u(7.5), u(15.5) - u(0.5), W(s, 1.3, 2))                        # the rim
    c.rect(u(3), u(13), W(s, 1.4, 2), u(15) - u(13)); c.rect(u(12.5), u(13), W(s, 1.4, 2), u(15) - u(13))   # the feet
    c.line(P(s, [(2.5, 7.5), (2.5, 2.5), (5.5, 2.5), (5.5, 4)]), W(s, 1.3, 2))    # the tap
    drop(c, s, 5.5, 4.8, 2.2)


# ------------------------------------------------------------------ the fluid card's words
@icon("flask", "ctx3", "a laboratory flask: a flask, a crucible, an effect", ["Fluid_Effect", "Fluid_Container_Flask"])
def flask(c, s):
    u = U(s)
    c.rect(u(5.5), u(1), u(10.5) - u(5.5), W(s, 1.2, 1.8))                       # the lip
    c.poly(P(s, [(6.5, 2), (9.5, 2), (9.5, 6), (14, 14), (13, 15), (3, 15), (2, 14), (6.5, 6)]))
    c.poly(P(s, [(7.6, 3), (8.4, 3), (8.4, 6.4), (11.2, 11.5), (4.8, 11.5), (7.6, 6.4)]), v=0)   # glass, above the liquid
    c.dot(u(7), u(13), W(s, 0.9, 1.3), v=0); c.dot(u(10), u(12.5), W(s, 0.7, 1.0), v=0)   # bubbles


@icon("poison", "ctx3", "a bottle with a cross on it: poison, acid", ["Fluid_Poison", "ContextMenu_EvolvedRecipe_Poison"])
def poison(c, s):
    u = U(s)
    c.rect(u(6), u(0.5), u(10) - u(6), u(2.5) - u(0.5))                          # the stopper
    c.poly(P(s, [(6.5, 3), (9.5, 3), (12.5, 6.5), (12.5, 15), (3.5, 15), (3.5, 6.5)]))
    c.line(P(s, [(5.5, 8), (10.5, 13)]), W(s, 1.4, 2.1), v=0); c.line(P(s, [(10.5, 8), (5.5, 13)]), W(s, 1.4, 2.1), v=0)


@icon("glass_empty", "ctx3", "an empty glass: empty, free, holding nothing, thirst", ["Fluid_Empty", "Fluid_Free"])
def glass_empty(c, s):
    _tumbler(c, s)


@icon("glass_half", "ctx3", "a glass half full: holding one or two fluids", ["Fluid_HoldingOneType", "Fluid_HoldingTwoTypes"])
def glass_half(c, s):
    _tumbler(c, s, level=8.6)


@icon("swap", "ctx3", "two arrows, one each way: swap", ["Fluid_Swap"])
def swap(c, s):
    u = U(s)
    c.rect(u(1), u(4), u(11) - u(1), W(s, 2, 3)); c.poly(P(s, [(10.5, 1.5), (15, 5), (10.5, 8.5)]))
    c.rect(u(5), u(11) - W(s, 0, 0), u(15) - u(5), W(s, 2, 3)); c.poly(P(s, [(5.5, 8.5), (1, 12), (5.5, 15.5)]))


@icon("skull", "ctx3", "a skull: tainted, deadly poison, a skull sign", ["Fluid_Tainted", "ContextMenu_SignSkull"])
def skull(c, s):
    u = U(s)
    c.ellipse(u(8), u(6.5), u(6) - u(0), u(5.5) - u(0))                          # the cranium
    c.rect(u(4.5), u(10), u(11.5) - u(4.5), u(14) - u(10))                       # the jaw
    c.dot(u(5.6), u(7), u(1.8) - u(0), v=0); c.dot(u(10.4), u(7), u(1.8) - u(0), v=0)   # the eyes
    c.poly(P(s, [(8, 9), (9, 11), (7, 11)]), v=0)                                 # the nose
    for x in (6.5, 9.5): c.rect(u(x), u(12), W(s, 1, 1.5), u(14) - u(12), v=0)   # the teeth


@icon("brain", "ctx3", "a brain from the side, its folds, the small lobe at the back: stress", ["Fluid_Prop_Stress"])
def brain(c, s):
    u = U(s)
    c.ellipse(u(8), u(7.5), u(7) - u(0), u(5.8) - u(0))
    c.ellipse(u(11.6), u(12.4), u(2.8) - u(0), u(2) - u(0))                       # the lobe at the back
    c.line(P(s, [(2.5, 6.5), (4.5, 5), (6, 7), (8, 5), (10, 7), (12, 5), (13.6, 6.5)]), W(s, 0.9, 1.3), v=0)   # the folds
    c.line(P(s, [(3.2, 10), (5, 8.8), (7, 10.4), (9, 9)]), W(s, 0.9, 1.3), v=0)
    c.line(P(s, [(9.4, 12.2), (14, 11.4)]), W(s, 0.9, 1.3), v=0)
    c.line(P(s, [(8, 2.2), (7.4, 4)]), W(s, 0.9, 1.3), v=0)


@icon("sad", "ctx3", "a sad face: unhappiness", ["Fluid_Prop_Unhappy"])
def sad(c, s):
    u = U(s)
    c.dot(u(8), u(8), u(7) - u(0))
    c.rect(u(5), u(4.5), W(s, 2, 3), W(s, 3, 4.5), v=0); c.rect(u(9), u(4.5), W(s, 2, 3), W(s, 3, 4.5), v=0)
    c.arc(u(8), u(13.5), u(3.6) - u(0), 210, 330, W(s, 1.4, 2.1), v=0, caps=True)


@icon("flame", "ctx3", "a flame: fire, use a lighter, burn, calories", ["Use Lighter", "Fluid_Prop_Calories"])
def flame(c, s):
    u = U(s)
    c.poly(P(s, [(8, 0.5), (12, 5.5), (13, 9.5), (11.5, 13.5), (8, 15), (4.5, 13.5), (3, 9.5), (4.5, 6.5), (6, 8.5), (6.5, 4.5)]))
    c.poly(P(s, [(8, 7), (10.2, 10.5), (9.6, 13), (8, 13.8), (6.4, 13), (5.8, 10.5)]), v=0)   # its heart


@icon("blood", "ctx3", "a drop of blood, a spatter beside it: blood, clean a weapon of it", ["Fluid_Name_Blood", "ContextMenu_CleanWeapon"])
def blood(c, s):
    drop(c, s, 6.5, 2, 13)
    u = U(s)
    c.dot(u(12.5), u(5), u(1.6) - u(0)); c.dot(u(13.5), u(10), u(1.1) - u(0)); c.dot(u(11.5), u(13.5), u(0.8) - u(0))
