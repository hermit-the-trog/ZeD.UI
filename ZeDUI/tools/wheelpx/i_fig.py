"""The pictogram figures: the doll's template (director, Oct 27: "follow a template or doll"; approved Oct 27: "just
rough enough to still be clear"). 16: head rows 0-4, gap 5, trunk 6-10, legs 11-15. 24: head 0-6, gap 7, trunk 8-15,
legs 16-23. Front views keep the arms one column clear of the body; side views face right.
The 16s are placed by hand (fig16.G16 and the grids here); the 24 front views come from the doll's joints (doll.py),
the 24 side views are placed by hand (fig24.py and here). A figure's on/off mark sits top right, where a figure leaves
room (its feet fill the bottom)."""
import math

import doll as DL
import fig16 as F16
import fig24 as F24
from doll import Px
from kit import icon


def g16(c, rows, dx=0, dy=0):
    for y, r in enumerate(rows):
        for x, ch in enumerate(r):
            if ch == "#" and 0 <= x + dx < 16 and 0 <= y + dy < 16: c.rect(x + dx, y + dy, 1, 1)


def p24(c, px, dx=0, dy=0):
    for (x, y) in px.on:
        if 0 <= x + dx < 24 and 0 <= y + dy < 24: c.rect(x + dx, y + dy, 1, 1)


def fig24(name):
    """the approved 24: a hand-placed side view, or the doll's front view"""
    if name in F24.G24: return F24.G24[name]()
    im = DL.figure(24, name); px = Px(24)
    for y in range(24):
        for x in range(24):
            if im.getpixel((x, y))[3]: px.put(x, y)
    return px


def approved(name, means, slices=(), id_=None):
    """register one of the approved figures as it was signed off"""
    def fn(c, s):
        if s == 16: g16(c, F16.G16[name])
        else: p24(c, fig24(name))
    icon(id_ or name, "fig", means, slices)(fn)


approved("stand", "a person standing: you, the character")
approved("wave", "a person waving: wave", ["IGUI_Emote_Wave", "emotes/wave"])
approved("point", "a person pointing")
approved("shrug", "a person shrugging: shrug, don't know", ["IGUI_Emote_Shrug", "emotes/shrug"])
approved("surrender", "a person, hands up: surrender", ["IGUI_Emote_Surrender", "emotes/surrender"])
approved("salute", "a person saluting: salute", ["IGUI_Emote_Salute", "emotes/salute"])
approved("walk", "a person walking: walk")
approved("run", "a person running: run")
approved("sit", "a person sitting on a chair: sit on a seat", ["UI_ZeD_Wheel_SitSeat", "ContextMenu_SitOnSeat"], "sit_seat")
approved("crouch", "a person crouched low: sneak", ["IGUI_LeftStickButtonRadial_ToggleCrouch", "emotes/crouch_on"], "sneak")
approved("climb", "a person climbing a ladder: climb")
approved("carry", "a person carrying a box: carry")


# ------------------------------------------------------------------ new poses on the same template
W16 = {   # the 16s, placed by hand
"sit_ground": [
    "................",
    "................",
    "................",
    "......###.......",
    ".....#####......",
    ".....#####......",
    ".....#####......",
    "......###.......",
    "................",
    ".....###........",
    "...#.###........",
    "...#.###........",
    "..#..###.....#..",
    "..#..#########..",
    ".....#########..",
    "................"],
"bow": [
    "................",
    "................",
    "..........###...",
    ".........#####..",
    ".........#####..",
    ".........#####..",
    "..........###...",
    "........##......",
    ".......###......",
    "......###.#.....",
    ".....###..#.....",
    ".....##...#.....",
    ".....##.........",
    ".....##.........",
    ".....##.........",
    ".....###........"],
"wave_bye": [
    ".......###......",
    "..#...#####.....",
    "..#...#####.....",
    "..#...#####.....",
    "...#...###......",
    "....#...........",
    ".....####.......",
    "......###.......",
    "......###.#.....",
    "......###..#....",
    "......###...#...",
    "......####......",
    ".....##..##.....",
    "....##....##....",
    "...##......##...",
    "...#........##.."],
"clap": [
    "......###...#...",
    ".....#####....#.",
    ".....#####.##...",
    ".....#####.##.##",
    "......###..##...",
    "..........#.....",
    "......###.#.....",
    "......#####.....",
    "......###.......",
    "......###.......",
    "......###.......",
    "......###.......",
    "......###.......",
    "......###.......",
    "......###.......",
    "......####......"],
"freeze": [
    "......###...##..",
    ".....#####..##..",
    ".....#####...#..",
    ".....#####...#..",
    "......###....#..",
    ".............#..",
    "...#.#####.###..",
    "...#.#####......",
    "..#..#####......",
    "..#..#####......",
    ".....#####......",
    ".....##.##......",
    ".....##.##......",
    ".....##.##......",
    ".....##.##......",
    ".....##.##......"],
"move_out": [
    ".......###......",
    "......#####.....",
    "......#####.....",
    "......#####.....",
    ".......###......",
    "................",
    "......###.......",
    ".....##########.",
    "....#.###.......",
    "...#..###.......",
    "......###.......",
    "......####......",
    ".....##..##.....",
    "....##....##....",
    "...##......##...",
    "...#........##.."],
"follow_me": [
    ".......###......",
    "......#####...#.",
    "......#####..#..",
    "......#####.#...",
    ".......###.#....",
    "..........#.....",
    "......####......",
    ".....####.......",
    "....#.###.......",
    "...#..###.......",
    "......###.......",
    "......####......",
    ".....##..##.....",
    "....##....##....",
    "...##......##...",
    "...#........##.."],
"follow_behind": [   # arms added Oct 27 (director: "follow figs need arms")
    "..###......###..",
    ".#####....#####.",
    ".#####....#####.",
    ".#####....#####.",
    "..###......###..",
    "................",
    "..###......###..",
    ".####.....####..",
    "#.###.#..#.###.#",
    "..###..#...###..",
    "..###......###..",
    "..####.....####.",
    ".##..##...##..##",
    "##....#..##....#",
    "#.....#..#.....#",
    "................",
],
"group": [
    "..###......###..",
    ".#####....#####.",
    ".#####....#####.",
    ".#####....#####.",
    "..###......###..",
    "................",
    ".#####....#####.",
    ".#####....#####.",
    ".#####....#####.",
    ".#####....#####.",
    ".#####....#####.",
    ".##.##....##.##.",
    ".##.##....##.##.",
    ".##.##....##.##.",
    ".##.##....##.##.",
    ".##.##....##.##."],
"carry_animal": [
    "......###.......",
    ".....#####......",
    ".....#####......",
    ".....#####......",
    "......###.....#.",
    "...........####.",
    ".....###..####..",
    ".....########...",
    ".....###..####..",
    ".....###..#..#..",
    ".....###........",
    ".....####.......",
    "....##..##......",
    "....##...##.....",
    "...##.....##....",
    "...#.......#...."],
}


def _bow24():
    c = Px(24)
    c.chain([(10, 15.5), (15, 11)], 4); F24.head(c, 16, 2)
    c.chain([(14, 12.5), (14.5, 18.5)], 2)
    c.rect(8, 16, 4, 8)
    return c


def _sit_ground24():
    c = Px(24)
    F24.head(c, 6, 4); F24.trunk(c, 7, y0=12, h=8, w=4)
    c.rect(7, 19, 15, 3); c.rect(19, 17, 3, 2)
    c.chain([(6, 13), (4, 17), (3, 21)], 2)
    return c


def _wave_bye24():
    c = Px(24)
    F24.head(c, 8); F24.trunk(c, 9)
    c.chain([(9, 10), (6, 6), (5, 1)], 2)
    c.chain([(13, 10), (16, 13), (19, 14)], 2)
    c.chain([(10.5, 16.5), (7.5, 19.5), (5.5, 22.5)], 3); c.chain([(11.5, 16.5), (14.5, 19.5), (16.5, 22.5)], 3)
    return c


def _clap24():
    c = Px(24)
    F24.head(c, 6); F24.trunk(c, 7)
    c.chain([(11, 10), (15, 12), (17, 8)], 2); c.rect(16, 4, 3, 5)
    c.chain([(17.5, 1), (17.5, 2)], 2); c.chain([(21, 2), (22, 1)], 2); c.chain([(21, 6), (23, 6)], 2)
    c.chain([(8.5, 16.5), (8.5, 22.5)], 3); c.rect(8, 23, 5, 1)
    return c


def _move24(arm):
    c = Px(24)
    F24.head(c, 8); F24.trunk(c, 9)
    c.chain([(9, 10), (6, 13), (5, 15)], 2)
    c.chain(arm, 2)
    c.chain([(10.5, 16.5), (7.5, 19.5), (5.5, 22.5)], 3); c.chain([(11.5, 16.5), (14.5, 19.5), (16.5, 22.5)], 3)
    return c


def _walker24(c, ox):
    """a walker narrowed to fit two: the back arm behind, the front arm swinging ahead, a stride"""
    F24.head(c, ox + 2); F24.trunk(c, ox + 3)
    c.chain([(ox + 3.5, 10), (ox + 1.5, 13), (ox + 1, 15)], 2)
    c.chain([(ox + 6.5, 10), (ox + 8.5, 12.5), (ox + 10, 13.5)], 2)
    c.chain([(ox + 4.5, 16.5), (ox + 2.5, 19.5), (ox + 1.5, 22.5)], 3)
    c.chain([(ox + 5.5, 16.5), (ox + 7.5, 19.5), (ox + 8.5, 22.5)], 3)


def _follow_behind24():
    c = Px(24); _walker24(c, 0); _walker24(c, 13); return c


def _person24(c, x0):
    """a front-view figure without its arms: head, trunk, two legs"""
    c.disc(x0, 0, 7)
    c.rect(x0, 8, 7, 8); c.put(x0, 8, False); c.put(x0 + 6, 8, False)
    c.rect(x0, 16, 3, 8); c.rect(x0 + 4, 16, 3, 8)


def _group24():
    c = Px(24); _person24(c, 2); _person24(c, 15); return c


def _freeze24():
    c = Px(24)
    st = fig24("stand")
    for (x, y) in st.on:
        if x < 16: c.put(x, y)                                                 # the stand, its right arm off
    c.rect(16, 8, 5, 2); c.rect(19, 3, 2, 7); c.rect(18, 0, 4, 4)              # the arm out, up, the fist
    return c


def _carry_animal24():
    c = Px(24)
    F24.head(c, 6); F24.trunk(c, 7)
    c.rect(11, 9, 4, 2)
    c.chain([(8.5, 16.5), (5.5, 22.5)], 3); c.chain([(9.5, 16.5), (12.5, 22.5)], 3)
    c.disc(15, 6, 7); c.rect(15, 8, 7, 4)                                      # the lamb's fleece
    c.rect(20, 3, 3, 4); c.put(23, 4)                                          # its head
    c.rect(16, 12, 2, 3); c.rect(20, 12, 2, 3)                                 # its legs
    return c


P24 = {"sit_ground": _sit_ground24, "bow": _bow24, "wave_bye": _wave_bye24, "clap": _clap24,
       "freeze": _freeze24,
       "move_out": lambda: _move24([(13, 10), (18, 10), (22, 10)]),
       "follow_me": lambda: _move24([(13, 10), (17, 6), (20, 2)]),
       "follow_behind": _follow_behind24, "group": _group24, "carry_animal": _carry_animal24}


def pose(id_, means, slices=(), name=None, mark=None, dx16=0, dx24=0, src=None):
    """register a figure: a new pose (W16/P24) or an approved one (src), with an optional on/off mark top right"""
    nm = name or id_

    def fn(c, s):
        if s == 16: g16(c, (F16.G16[src] if src else W16[nm]), dx16)
        else: p24(c, (fig24(src) if src else P24[nm]()), dx24)
        if mark: c.badge(mark, "tr")
    icon(id_, "fig", means, slices)(fn)


pose("sit_ground", "a person sitting on the ground: sit down", ["IGUI_LeftStickButtonRadial_ToggleSitOnGround", "emotes/sit_on", "UI_ZeD_Wheel_Sit"])
pose("sit_ground_off", "the person on the ground, an x: stand up", ["emotes/sit_off"], name="sit_ground", mark="x")
pose("sneak_off", "the crouched person, an x: stop sneaking", ["emotes/crouch_off"], src="crouch", mark="x", dx16=-2, dx24=-4)
pose("autowalk", "a person walking, an arrow on: walk on by itself", ["IGUI_LeftStickButtonRadial_ToggleAutoWalk", "emotes/autowalk_on", "UI_ZeD_Wheel_Walk"], src="walk", mark="right", dx16=-2, dx24=-3)
pose("autowalk_off", "the walking person, an x: stop walking on", ["emotes/autowalk_off"], src="walk", mark="x", dx16=-2, dx24=-3)
pose("wave_bye", "a person walking off, waving back: wave goodbye", ["emotes/wavebye"])
pose("bow", "a person bowing: thank you", ["emotes/thankyou"])
pose("freeze", "a person, a fist raised: freeze", ["emotes/freeze"])
pose("move_out", "a person walking, an arm pointing on ahead: move out", ["emotes/moveout"])
pose("follow_me", "a person walking, an arm raised forward: follow me", ["emotes/followme"])
pose("follow_behind", "two people walking in file: follow behind", ["emotes/followbehind"])
pose("group", "two people: the group", ["emotes/group"])
pose("carry_animal", "a person carrying a lamb: pick the animal up", ["ContextMenu_PickUpAnimal", "AnimalActions_Grab"])


def _undecided(c, s):
    if s == 16:
        g16(c, F16.G16["stand"], -2)
        c.grid(["###", "..#", ".##", ".#.", "...", ".#."], ox=12, oy=0)
    else:
        p24(c, fig24("stand"), -4)
        c.grid(["#####", "#####", "...##", "..###", ".###.", ".##..", ".....", ".##..", ".##.."], ox=17, oy=0)


icon("undecided", "fig", "a person, a question mark: undecided", ["emotes/undecided"])(_undecided)


def _come_here(c, s):
    if s == 16:
        g16(c, F16.G16["stand"], -3); c.badge("left", at=(11, 6))
    else:
        p24(c, fig24("stand"), -5); c.badge("left", at=(17, 9))


icon("come_here", "fig", "a person, an arrow coming to them: come here, come from the front", ["emotes/comehere", "emotes/comefromfront"])(_come_here)


# ------------------------------------------------------------------ hands
def _mitt(c, a, b, w, thumb, tw):
    c.line([a, b], w); c.line(thumb, tw)


def _mirror(half):
    return [r + r[::-1] for r in half]


def clap_v1(c, s):
    """the first clap (Oct 27): read as hands up, celebrating"""
    if s == 16:
        c.grid(_mirror(["..#....#",
                        "...#....",
                        "........",
                        ".....##.",
                        "....###.",
                        "....###.",
                        "...####.",
                        ".#.####.",
                        ".#####..",
                        "..####..",
                        "..####..",
                        "...###..",
                        "...###..",
                        "...###.."]), oy=1)
    else:
        c.grid(_mirror(["....#......#",
                        ".....#.....#",
                        "......#.....",
                        "............",
                        "........###.",
                        ".......####.",
                        ".......####.",
                        "......#####.",
                        "......#####.",
                        "......#####.",
                        "...#..#####.",
                        "...##.#####.",
                        "....#######.",
                        "....######..",
                        ".....#####..",
                        ".....#####..",
                        ".....#####..",
                        "......####..",
                        "......####..",
                        "......####..",
                        "......####.."]), oy=1)


def _over(c, draw):
    """draw a shape over what is there, with a clear pixel round it (a near hand over a far one)"""
    from PIL import ImageDraw, ImageFilter
    from kit import C
    t = C(c.n); draw(t)
    m = t.im.resize((c.n, c.n)).point(lambda q: 255 if q >= 128 else 0)
    c.im.paste(0, mask=m.filter(ImageFilter.MaxFilter(3)).resize(c.im.size))
    c.im.paste(255, mask=m.resize(c.im.size))
    c.d = ImageDraw.Draw(c.im)


def _palm_far(c, s):
    if s == 24:
        for x, top in ((4, 6), (7, 4), (10, 5), (13, 7)): c.rect(x, top, 2, 13 - top)
        c.rect(4, 12, 11, 6); c.rect(5, 18, 9, 1); c.rect(6, 19, 7, 1)
        c.cap(3.5, 15, 1.5, 11.5, 1.1)
    else:
        for x, top in ((3, 5), (5, 3), (7, 4), (9, 6)): c.rect(x, top, 1, 9 - top)
        c.rect(3, 8, 7, 4); c.rect(4, 12, 5, 1)
        c.cap(3, 10.5, 1.2, 7.8, 0.75)


def _palm_near(c, s):
    if s == 24:
        for x, top in ((10, 11), (13, 9), (16, 8), (19, 10)): c.rect(x, top, 2, 17 - top)
        c.rect(10, 16, 11, 5); c.rect(11, 21, 9, 1); c.rect(12, 22, 7, 1)
        c.cap(20.5, 19, 22.5, 15.5, 1.1)
    else:
        for x, top in ((7, 8), (9, 6), (11, 5), (13, 7)): c.rect(x, top, 1, 11 - top)
        c.rect(7, 10, 7, 4); c.rect(8, 14, 5, 1)
        c.cap(13.8, 12.5, 15, 9.8, 0.75)


@icon("clap", "hand", "two open hands together, the near one over the far, the claps above: clap", ["emotes/clap"])
def clap(c, s):
    """redrawn Oct 27 (director: the first "looks a little too much like celebrate, hands up"): the hands overlap,
    one before the other, instead of standing apart side by side"""
    _palm_far(c, s); _over(c, lambda t: _palm_near(t, s))
    if s == 24:
        c.cap(2.5, 1, 3.5, 2.8, 0.8); c.cap(8, 0, 8, 1.8, 0.8); c.cap(13.5, 1, 12.5, 2.8, 0.8)
    else:
        c.px((2, 1), (5, 0), (8, 1))


THUMB24 = [   # placed by hand Oct 27 (director: the first big one was "rough")
    "..........###...........",
    ".........#####..........",
    ".........#####..........",
    ".........#####..........",
    ".........#####..........",
    "........######..........",
    ".......#######..........",
    "......########..........",
    ".####.##############....",
    ".####.###############...",
    ".####.##############....",
    ".####.#######...........",
    ".####.##############....",
    ".####.###############...",
    ".####.##############....",
    ".####.#######...........",
    ".####.#############.....",
    ".####.##############....",
    ".####.#############.....",
    ".####..#####............"]


def _thumb(c, s):
    if s == 16:
        c.rect(1, 7, 2, 8)                                                     # the cuff
        c.rrect(4, 7, 10, 8, 1.5)                                              # the fist
        for y in (9, 11, 13): c.rect(8, y, 6, 1, v=0)                          # the curled fingers
        c.rrect(5, 1, 3, 7, 1.4)                                               # the thumb
    else:
        c.grid(THUMB24, oy=2)


@icon("thumbs_up", "hand", "a thumb up: yes, good, the friendly emotes", ["emotes/thumbsup", "emotes/thumbup"])
def thumbs_up(c, s):
    _thumb(c, s)


@icon("thumbs_down", "hand", "a thumb down: no, bad, the hostile emotes", ["emotes/thumbsdown", "emotes/thumbdown"])
def thumbs_down(c, s):
    _thumb(c, s); c.flip_v()
