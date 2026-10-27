"""Signs: yes and no, the insult, the target, back, plus and minus, info and help, the game's speed, settings,
zoom, and the ZeD setup wheel's own (theme, text size, focus, scale, see-through, the action bar, messages,
moodles, the guide, the controller, the alarm, health)"""
import math

from kit import icon


@icon("yes", "sym", "a tick: yes, OK", ["emotes/yes", "emotes/signalok", "IGUI_Emote_Yes"])
def yes(c, s):
    if s == 16: c.line([(2, 8.5), (6, 12.5), (14, 3.5)], 2.2)
    else: c.line([(3, 12.5), (9, 18.5), (21.5, 5)], 3.4)


@icon("no", "sym", "a cross: no", ["emotes/no", "IGUI_Emote_No"])
def no(c, s):
    if s == 16: c.line([(3, 3), (13, 13)], 2.4); c.line([(13, 3), (3, 13)], 2.4)
    else: c.line([(4.5, 4.5), (19.5, 19.5)], 3.6); c.line([(19.5, 4.5), (4.5, 19.5)], 3.6)


@icon("insult", "sym", "a speech bubble full of grawlix: insult", ["emotes/insult"])
def insult(c, s):
    if s == 16:
        c.rrect(1, 2, 14, 9, 2); c.poly([(3, 10), (7, 10), (2, 14)])
        c.grid(["#.#..#.#.#",
                "###...#..#",
                "#.#..#.#.#",
                "###.......",
                "#.#......#"], ox=3, oy=4, v=0)
    else:
        c.rrect(1, 2, 22, 14, 3); c.poly([(4, 15), (10, 15), (2.5, 21.5)])
        c.grid(["#..#..####..##",
                "####.#....#.##",
                "#..#.#.##.#.##",
                "####.#.##.#.##",
                "#..#.#..###...",
                "......#.......",
                ".......###..##"], ox=4, oy=5, v=0)


@icon("chat", "sym", "a speech bubble, words in it: the chat", ["UI_ZeD_Wheel_Chat"])
def chat(c, s):
    if s == 16:
        c.rrect(1, 2, 14, 9, 2); c.poly([(3, 10), (7, 10), (2, 14)])
        for x in (4, 7, 10): c.rect(x, 6, 2, 2, v=0)
    else:
        c.rrect(1, 2, 22, 14, 3); c.poly([(4, 15), (10, 15), (2.5, 21.5)])
        for x in (6, 11, 16): c.rect(x, 8, 3, 3, v=0)


@icon("target", "sym", "a target's sights: fire, aim here", ["emotes/fire", "emotes/signalfire"])
def target(c, s):
    if s == 16:
        c.oring(8, 8, 6.2, 1.4)
        c.rect(7, 0, 2, 4); c.rect(7, 12, 2, 4); c.rect(0, 7, 4, 2); c.rect(12, 7, 4, 2)
        c.rect(7, 7, 2, 2)
    else:
        c.oring(12, 12, 9.4, 2.2)
        c.rect(11, 0, 2, 6.5); c.rect(11, 17.5, 2, 6.5); c.rect(0, 11, 6.5, 2); c.rect(17.5, 11, 6.5, 2)
        c.rect(10.5, 10.5, 3, 3)


@icon("target_off", "sym", "the target's sights struck through: cease fire", ["emotes/ceasefire"])
def target_off(c, s):
    target(c, s); c.slash()


@icon("back", "sym", "an arrow turning back: back", ["emotes/back", "IGUI_Emote_Back"])
def back(c, s):
    if s == 16:
        c.arc(8.5, 9.5, 5, -90, 90, 2, caps=False); c.rect(6, 3.5, 3, 2); c.rect(4, 13.5, 4.5, 2)
        c.poly([(1, 4.5), (6.5, 0.5), (6.5, 8.5)])
    else:
        c.arc(13, 13.5, 7.5, -90, 90, 3, caps=False); c.rect(9, 4.5, 4.5, 3); c.rect(4, 19.5, 9, 3)
        c.poly([(1, 6), (9.5, 0.5), (9.5, 11.5)])


@icon("plus", "sym", "a plus: add, put on, attach", ["ZoomIn", "ContextMenu_Equip_Primary"])
def plus(c, s):
    if s == 16: c.rect(2, 7, 12, 2); c.rect(7, 2, 2, 12)
    else: c.rect(3, 10.5, 18, 3); c.rect(10.5, 3, 3, 18)


@icon("minus", "sym", "a minus: take off, remove", ["ZoomOut", "ContextMenu_HotbarRadialRemove", "ContextMenu_Unequip"])
def minus(c, s):
    if s == 16: c.rect(2, 7, 12, 2)
    else: c.rect(3, 10.5, 18, 3)


@icon("info", "sym", "an i in a disc: information, the animal's info", ["ContextMenu_AnimalInfo", "AnimalActions_Stats"])
def info(c, s):
    if s == 16: c.dot(8, 8, 7.2); c.rect(7, 3, 2, 2, v=0); c.rect(7, 6, 2, 7, v=0)
    else: c.dot(12, 12, 11); c.rect(10.5, 4.5, 3, 3, v=0); c.rect(10.5, 9.5, 3, 10, v=0)


@icon("help", "sym", "a question mark in a disc: help, the controller's map", ["UI_ZeD_Wheel_Help"])
def help_(c, s):
    if s == 16:
        c.dot(8, 8, 7.2)
        c.grid([".####.",
                "##..##",
                "....##",
                "...##.",
                "..##..",
                "......",
                "..##.."], ox=5, oy=3, v=0)
    else:
        c.dot(12, 12, 11)
        c.grid([".######.",
                "###..###",
                "##....##",
                ".....###",
                "....###.",
                "...###..",
                "...##...",
                "........",
                "...##...",
                "...##..."], ox=8, oy=5, v=0)


# ------------------------------------------------------------------ the game's speed
@icon("play", "sym", "play: the game at its own speed", ["speedControls/Play_Off", "IGUI_BackButton_Play"])
def play(c, s):
    if s == 16: c.poly([(4, 2), (13, 8), (4, 14)])
    else: c.poly([(6, 3), (20, 12), (6, 21)])


@icon("pause", "sym", "pause", ["speedControls/Pause_Off", "UI_optionscreen_binding_Pause"])
def pause(c, s):
    if s == 16: c.rect(3, 2, 3, 12); c.rect(10, 2, 3, 12)
    else: c.rect(5, 3, 5, 18); c.rect(14, 3, 5, 18)


@icon("ff1", "sym", "two arrowheads: fast forward", ["speedControls/FFwd1_Off", "IGUI_BackButton_FF1"])
def ff1(c, s):
    if s == 16: c.poly([(1, 3), (8, 8), (1, 13)]); c.poly([(8, 3), (15, 8), (8, 13)])
    else: c.poly([(1.5, 4), (12, 12), (1.5, 20)]); c.poly([(12, 4), (22.5, 12), (12, 20)])


@icon("ff2", "sym", "three arrowheads: faster", ["speedControls/FFwd2_Off", "IGUI_BackButton_FF2"])
def ff2(c, s):
    if s == 16:
        for x in (1, 6, 11):
            for i in range(4): c.rect(x + i, 4 + i, 1, 8 - 2 * i)
    else:
        for x in (1, 8.5, 16): c.poly([(x, 5), (x + 6.5, 12), (x, 19)])


@icon("wait", "sym", "a clock: the fastest, wait the time out", ["speedControls/Wait_Off", "IGUI_BackButton_FF3"])
def wait(c, s):
    if s == 16:
        c.oring(8, 8, 7, 1.6); c.rect(7, 3, 2, 6); c.rect(8, 7, 4, 2)
    else:
        c.oring(12, 12, 11, 2.4); c.rect(11, 5, 2.5, 8.5); c.rect(12, 11, 6, 2.5)


@icon("seek", "sym", "two arrowheads to a stop: the next station", ["UI_ZeD_Wheel_RadioNext"])
def seek(c, s):
    if s == 16: c.poly([(1, 3), (6.5, 8), (1, 13)]); c.poly([(6.5, 3), (12, 8), (6.5, 13)]); c.rect(12, 3, 2, 10)
    else: c.poly([(1, 4), (9.5, 12), (1, 20)]); c.poly([(9.5, 4), (18, 12), (9.5, 20)]); c.rect(18.5, 4, 3, 16)


# ------------------------------------------------------------------ settings and zoom
def _cog(c, cx, cy, r, teeth, tw, th, hole):
    c.dot(cx, cy, r)
    for i in range(teeth):
        a = 2 * math.pi * i / teeth; ux, uy = math.cos(a), math.sin(a); vx, vy = -uy, ux
        p = lambda d, t: (cx + ux * d + vx * t, cy + uy * d + vy * t)
        c.poly([p(r - 1, -tw / 2), p(r + th, -tw / 2.6), p(r + th, tw / 2.6), p(r - 1, tw / 2)])
    c.dot(cx, cy, hole, v=0)


@icon("gears", "sym", "a cog: settings, ZeD's setup, the emotes' config", ["emotes/gears", "UI_ZeD_Wheel_Setup", "UI_ZeD_Wheel_Options"])
def gears(c, s):
    if s == 16: _cog(c, 8, 8, 4.6, 8, 2.6, 2.2, 1.9)
    else: _cog(c, 12, 12, 7.2, 8, 3.8, 3.4, 3)


def _mag(c, s):
    if s == 16: c.oring(6.5, 6.5, 6, 1.6); c.line([(11, 11), (14, 14)], 2.6)
    else: c.oring(10, 10, 9, 2.4); c.line([(16.5, 16.5), (21.5, 21.5)], 4)


@icon("zoom_in", "sym", "a magnifier with a plus: zoom in", ["IGUI_BackButton_Zoom_In"])
def zoom_in(c, s):
    _mag(c, s)
    if s == 16: c.rect(4, 6, 5, 1); c.rect(6, 4, 1, 5)
    else: c.rect(6, 9, 8, 2); c.rect(9, 6, 2, 8)


@icon("zoom_out", "sym", "a magnifier with a minus: zoom out", ["IGUI_BackButton_Zoom_Out"])
def zoom_out(c, s):
    _mag(c, s)
    if s == 16: c.rect(4, 6, 5, 1)
    else: c.rect(6, 9, 8, 2)


# ------------------------------------------------------------------ the ZeD setup wheel
@icon("theme", "sym", "a disc half dark: the theme", ["UI_ZeD_Wheel_Theme"])
def theme(c, s):
    if s == 16: c.oring(8, 8, 7, 1.4); c.dot(8, 8, 7); c.rect(8, 0, 8, 16, v=0); c.oring(8, 8, 7, 1.4)
    else: c.dot(12, 12, 11); c.rect(12, 0, 12, 24, v=0); c.oring(12, 12, 11, 2)


@icon("textsize", "sym", "a big A and a small a: the text size", ["UI_ZeD_Wheel_TextSize"])
def textsize(c, s):
    if s == 16:
        c.grid(["...##.....",
                "...##.....",
                "..####....",
                "..#..#....",
                "..#..#....",
                ".##..##...",
                ".######...",
                ".##..##...",
                "##....##..",
                "##....##.."], ox=0, oy=4)
        c.grid([".###.",
                "....#",
                ".####",
                "#...#",
                ".####"], ox=10, oy=9)
    else:
        c.poly([(5.5, 3), (8.5, 3), (14, 21), (11, 21), (7, 7.5), (3, 21), (0.5, 21)])
        c.rect(3.5, 14, 7.5, 2.5)
        c.grid([".####.",
                ".....#",
                ".....#",
                ".#####",
                "#....#",
                "#....#",
                ".#####"], ox=15, oy=14)
        c.grid([".####.",
                ".....#",
                ".....#",
                ".#####",
                "#....#",
                "#....#",
                ".#####"], ox=16, oy=14)


@icon("focus", "sym", "corner marks round a dot: the focus style", ["UI_ZeD_Wheel_FocusStyle"])
def focus(c, s):
    if s == 16:
        c.rect(1, 1, 4, 2); c.rect(1, 1, 2, 4); c.rect(11, 1, 4, 2); c.rect(13, 1, 2, 4)
        c.rect(1, 13, 4, 2); c.rect(1, 11, 2, 4); c.rect(11, 13, 4, 2); c.rect(13, 11, 2, 4)
        c.rect(6, 6, 4, 4)
    else:
        c.rect(1, 1, 7, 3); c.rect(1, 1, 3, 7); c.rect(16, 1, 7, 3); c.rect(20, 1, 3, 7)
        c.rect(1, 20, 7, 3); c.rect(1, 16, 3, 7); c.rect(16, 20, 7, 3); c.rect(20, 16, 3, 7)
        c.rect(9, 9, 6, 6)


@icon("scale", "sym", "a small square grown to a big one: the interface's scale", ["UI_ZeD_Wheel_Scale"])
def scale(c, s):
    if s == 16:
        c.rect(1, 1, 14, 14); c.rect(2, 2, 12, 12, v=0)
        c.rect(1, 9, 6, 6)
        c.line([(8.5, 7.5), (12, 4)], 1.3); c.rect(9, 3, 4, 1); c.rect(12, 3, 1, 4)
    else:
        c.rect(1, 1, 22, 22); c.rect(3, 3, 18, 18, v=0)
        c.rect(1, 14, 9, 9)
        c.line([(12.5, 11.5), (18, 6)], 2); c.rect(13, 5, 6, 2); c.rect(17, 5, 2, 6)


@icon("seethrough", "sym", "a pane over a pane, the front one clear: see-through windows", ["UI_ZeD_Wheel_SeeThrough"])
def seethrough(c, s):
    if s == 16:
        c.rect(1, 1, 9, 9)
        c.rect(5, 5, 10, 10, v=0)
        c.rect(6, 6, 9, 9); c.rect(7, 7, 7, 7, v=0)
        for y in range(7, 14):
            for x in range(7, 14):
                if (x + y) % 2 == 0 and (x < 10 and y < 10): c.rect(x, y, 1, 1)
    else:
        c.rect(1, 1, 13, 13)
        c.rect(7.5, 7.5, 16, 16, v=0)
        c.rect(9, 9, 14, 14); c.rect(11, 11, 10, 10, v=0)
        for y in range(11, 21):
            for x in range(11, 21):
                if (x + y) % 2 == 0 and (x < 14 and y < 14): c.rect(x, y, 1, 1)


@icon("progress", "sym", "a bar part filled: the action bar", ["UI_ZeD_Wheel_ActionBar"])
def progress(c, s):
    if s == 16: c.rect(1, 5, 14, 6); c.rect(2, 6, 12, 4, v=0); c.rect(3, 7, 6, 2)
    else: c.rect(1, 7, 22, 10); c.rect(3, 9, 18, 6, v=0); c.rect(4.5, 10.5, 9, 3)


@icon("inbox", "sym", "an in-tray: the messages", ["UI_ZeD_Wheel_Messages"])
def inbox(c, s):
    if s == 16:
        c.rect(1, 2, 14, 12); c.rect(2, 3, 12, 6, v=0)
        c.rect(5, 8, 6, 2, v=0)
        c.rect(7, 3, 2, 3); c.px((6, 5), (9, 5))
    else:
        c.rect(1, 3, 22, 18); c.rect(3, 5, 18, 8, v=0)
        c.rect(8, 12, 8, 3, v=0)
        c.rect(11, 5, 2, 4); c.poly([(8.5, 8), (15.5, 8), (12, 11.5)])


@icon("smiley", "sym", "a smiling face: the moodles", ["UI_ZeD_Wheel_Moodles"])
def smiley(c, s):
    if s == 16:
        c.dot(8, 8, 7.2)
        c.rect(5, 4, 2, 3, v=0); c.rect(9, 4, 2, 3, v=0)
        c.grid(["#......#", ".#....#.", "..####.."], ox=4, oy=9, v=0)
    else:
        c.dot(12, 12, 11)
        c.rect(7.5, 6, 3, 4.5, v=0); c.rect(13.5, 6, 3, 4.5, v=0)
        c.arc(12, 12, 6, 30, 150, 2.2, v=0)


@icon("guide", "sym", "a book with a question on its cover: the survival guide", ["UI_optionscreen_binding_Toggle Survival Guide", "UI_ZeD_Wheel_Guide"])
def guide(c, s):
    if s == 16:
        c.rect(2, 1, 12, 13); c.rect(4, 1, 1, 12, v=0)                           # the cover, its spine
        c.rect(3, 14, 11, 1)                                                   # the pages' edge
        c.grid([".###.",
                "#...#",
                "...#.",
                "..#..",
                ".....",
                "..#.."], ox=7, oy=3, v=0)
    else:
        c.rect(3, 1, 18, 19); c.rect(6, 1, 1.5, 17.5, v=0)
        c.rect(4.5, 21, 16.5, 2)
        c.grid([".####.",
                "##..##",
                "....##",
                "...##.",
                "..##..",
                "......",
                "..##.."], ox=10, oy=5, v=0)


@icon("gamepad", "sym", "a game controller: the controller's map", ["UI_ZeD_Wheel_ControllerMap"])
def gamepad(c, s):
    if s == 16:
        c.rrect(1, 4, 14, 7, 2); c.rect(1, 9, 4, 4); c.rect(11, 9, 4, 4)
        c.rect(3, 7, 3, 1, v=0); c.rect(4, 6, 1, 3, v=0)
        c.px((11, 6), (12, 8), v=0)
    else:
        c.rrect(1, 6, 22, 10, 3); c.rrect(1, 12, 7, 8, 2.5); c.rrect(16, 12, 7, 8, 2.5)
        c.rect(4, 10, 5, 2, v=0); c.rect(5.5, 8.5, 2, 5, v=0)
        c.dot(16.5, 9.5, 1.3, v=0); c.dot(19, 12, 1.3, v=0)


@icon("alarm", "sym", "a bell: the watch's alarm", ["UI_ZeD_Wheel_WatchAlarm"])
def alarm(c, s):
    if s == 16:
        c.rect(7, 1, 2, 1)
        c.poly([(5, 3), (11, 3), (12, 9), (14, 12), (2, 12), (4, 9)])
        c.rect(6, 13, 4, 2)
    else:
        c.rect(10.5, 1, 3, 2)
        c.poly([(7, 4), (17, 4), (18.5, 13), (21.5, 18), (2.5, 18), (5.5, 13)])
        c.rect(9.5, 19.5, 5, 3)


@icon("heart", "sym", "a heart: you, your health, the health tab", ["Heart2_On", "IGUI_BackButton_PlayerInfo", "health tab"])
def heart(c, s):
    if s == 16:
        c.grid([".###...###.",
                "#####.#####",
                "###########",
                "###########",
                "###########",
                ".#########.",
                "..#######..",
                "...#####...",
                "....###....",
                ".....#....."], ox=2, oy=3)
    else:
        c.circle(7.5, 8.5, 5.5); c.circle(16.5, 8.5, 5.5)
        c.poly([(2.2, 10), (21.8, 10), (12, 21.5)])


@icon("safemode", "sym", "a shield with a tick: safe mode", ["UI_ZeD_Wheel_SafeMode"])
def safemode(c, s):
    if s == 16:
        c.poly([(2, 2), (8, 0.5), (14, 2), (14, 8), (8, 15.5), (2, 8)])
        c.line([(4.5, 7.5), (7, 10), (11.5, 5)], 1.5, v=0)
    else:
        c.poly([(2.5, 3), (12, 0.5), (21.5, 3), (21.5, 11.5), (12, 23.5), (2.5, 11.5)])
        c.line([(7, 11.5), (10.5, 15), (17.5, 7.5)], 2.4, v=0)
