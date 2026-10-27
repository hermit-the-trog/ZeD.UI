"""The world's wheel (D-pad right, ZeD_DpadWheels Wd.*) and what it opens: the map, vehicles, animals, building,
searching, lights and power, fire, seats"""
import math

from kit import icon


@icon("map", "world", "an opened road map, a route to an X: the map, the maps tab", ["IGUI_WorldMap_Toggle", "UI_ZeD_Wheel_Map", "maps tab"])
def map_(c, s):
    if s == 16:
        # drawn as an outline (the folds read), the route and the X in ink
        c.poly([(1, 3), (5, 1), (10, 3), (15, 1), (15, 13), (10, 15), (5, 13), (1, 15)])
        c.poly([(2, 3.7), (4.6, 2.5), (4.6, 12.2), (2, 13.4)], v=0)
        c.poly([(5.6, 2.4), (9.4, 3.7), (9.4, 13.6), (5.6, 12.3)], v=0)
        c.poly([(10.6, 3.7), (14, 2.5), (14, 12.4), (10.6, 13.7)], v=0)
        c.px((3, 11), (4, 10), (6, 9), (8, 8), (11, 7))
        c.px((11, 4), (13, 4), (12, 5), (11, 6), (13, 6))
    else:
        c.poly([(1, 4), (8, 1), (15, 4), (23, 1), (23, 20), (15, 23), (8, 20), (1, 23)])
        c.poly([(2.6, 5.1), (6.8, 3.2), (6.8, 19.2), (2.6, 21)], v=0)
        c.poly([(9.2, 3.0), (13.8, 5.0), (13.8, 21.2), (9.2, 19.2)], v=0)
        c.poly([(16.2, 5.0), (21.4, 3.2), (21.4, 19), (16.2, 21)], v=0)
        for (x, y) in ((3.5, 17.5), (5.2, 16), (9.8, 14.6), (11.6, 13.2), (17.2, 11.4)): c.rect(x, y, 1.6, 1.6)
        c.line([(17.6, 5.6), (20.6, 8.6)], 1.6); c.line([(20.6, 5.6), (17.6, 8.6)], 1.6)


@icon("minimap", "world", "the screen with a small map in its corner: the mini-map", ["IGUI_MiniMap_Toggle"])
def minimap(c, s):
    if s == 16:
        c.rect(1, 2, 14, 12); c.rect(2, 3, 12, 10, v=0)                       # the screen
        c.rect(8, 3, 6, 6)                                                    # the mini-map in its corner
        c.rect(8, 3, 1, 6, v=0); c.rect(8, 8, 6, 1, v=0)
        c.px((11, 4), (10, 5), (11, 5), (12, 5), (11, 6), v=0)                # you, on it
    else:
        c.rect(1, 3, 22, 18); c.rect(3, 5, 18, 14, v=0)
        c.rect(12, 5, 9, 8)
        c.rect(12, 5, 1.5, 8, v=0); c.rect(12, 11.5, 9, 1.5, v=0)
        c.dot(17, 8.2, 1.6, v=0)


@icon("pin", "world", "a map pin: focus the mini-map on you, a marker, a zone's place", ["IGUI_MiniMap_Focus", "IGUI_Zone_Name"])
def pin(c, s):
    if s == 16:
        c.dot(8, 6, 5)
        c.poly([(3.6, 8), (12.4, 8), (8.5, 15), (7.5, 15)])
        c.dot(8, 6, 2, v=0)
    else:
        c.dot(12, 9, 7.5)
        c.poly([(5.4, 12), (18.6, 12), (12.8, 23), (11.2, 23)])
        c.dot(12, 9, 3, v=0)


@icon("car", "world", "a car from the front: vehicles, the vehicle tab", ["UI_ZeD_Wheel_Vehicle", "vehicle tab"])
def car(c, s):
    if s == 16:
        c.poly([(4, 3), (12, 3), (14, 8), (2, 8)])                              # the cabin
        c.poly([(5, 4), (11, 4), (12.4, 7), (3.6, 7)], v=0)                     # the windscreen
        c.rrect(1, 7, 14, 5, 1)                                                  # the body
        c.rect(2, 12, 3, 2); c.rect(11, 12, 3, 2)                                # the wheels
        c.rect(2, 9, 2, 1, v=0); c.rect(12, 9, 2, 1, v=0)                        # the lamps
        c.rect(6, 10, 4, 1, v=0)                                                 # the grille
    else:
        c.poly([(6, 4), (18, 4), (21, 11), (3, 11)])
        c.poly([(7.4, 5.6), (16.6, 5.6), (18.8, 10), (5.2, 10)], v=0)
        c.rrect(1, 10, 22, 8, 2)
        c.rect(3, 18, 4, 3); c.rect(17, 18, 4, 3)
        c.rrect(3, 12, 4, 2.5, 1, v=0); c.rrect(17, 12, 4, 2.5, 1, v=0)
        c.rect(9, 14, 6, 1.5, v=0)


@icon("cow", "world", "a cow's head: animals, the animals tab", ["UI_ZeD_Wheel_Animal", "animals tab", "check the trailer"])
def cow(c, s):
    if s == 16:
        c.grid(["................",
                ".#............#.",
                ".##..........##.",
                "..###......###..",
                "...##########...",
                "#####.####.#####",
                ".####.####.####.",
                "....########....",
                "....########....",
                "....########....",
                "...##########...",
                "..############..",
                "..#.########.#..",
                "..############..",
                "...##########...",
                "................"])
        c.px((5, 12), (10, 12), v=0)                                          # the nostrils
        c.rect(3, 10, 10, 1, v=0); c.rect(4, 10, 8, 1)                        # the muzzle's edge
    else:
        c.line([(2, 2), (3.5, 5), (7.5, 7)], 2.4); c.line([(22, 2), (20.5, 5), (16.5, 7)], 2.4)    # the horns
        c.rrect(6.5, 5.5, 11, 11, 3)                                                                # the head
        c.ellipse(4, 9, 3.6, 2.2); c.ellipse(20, 9, 3.6, 2.2)                                       # the ears
        c.rrect(4.5, 14, 15, 9, 4)                                                                  # the muzzle
        c.rect(4.5, 14, 15, 1.2, v=0); c.rect(6, 14, 12, 1.2)
        c.dot(8.5, 18.5, 1.5, v=0); c.dot(15.5, 18.5, 1.5, v=0)
        c.dot(9, 9.5, 1, v=0); c.dot(15, 9.5, 1, v=0)                                               # the eyes


@icon("toolbox", "world", "a toolbox: craft and build", ["UI_ZeD_Wheel_CraftBuild"])
def toolbox(c, s):
    if s == 16:
        c.rect(5, 3, 6, 1); c.rect(5, 4, 1, 2); c.rect(10, 4, 1, 2)          # the handle
        c.rect(1, 6, 14, 8)
        c.rect(1, 8, 14, 1, v=0)                                              # the lid
        c.rect(7, 7, 2, 3)                                                    # the latch
        c.rect(2, 14, 2, 1); c.rect(12, 14, 2, 1)
    else:
        c.rect(8, 3, 8, 2); c.rect(8, 5, 2, 4); c.rect(14, 5, 2, 4)
        c.rrect(1, 8, 22, 13, 1.5)
        c.rect(1, 11.5, 22, 1.5, v=0)
        c.rect(10, 9.5, 4, 5)
        c.rect(11, 11.5, 2, 1.5, v=0)
        c.rect(3, 21, 3, 2); c.rect(18, 21, 3, 2)


@icon("magnifier", "world", "a magnifying glass: search, investigate the area, the foraging tab", ["UI_ZeD_Wheel_Search", "UI_investigate_area_window_show", "forage tab"])
def magnifier(c, s):
    if s == 16:
        c.oring(6.5, 6.5, 5.5, 2)
        c.line([(10.5, 10.5), (13.5, 13.5)], 2.6)
        c.px((4, 5), (5, 4), v=0)
    else:
        c.oring(9.5, 9.5, 8.5, 3)
        c.line([(16, 16), (21, 21)], 4.2)
        c.px((6, 8), (7, 7), (8, 6), v=0)


@icon("magnifier_off", "world", "the magnifying glass struck through: hide the area window", ["UI_investigate_area_window_hide"])
def magnifier_off(c, s):
    magnifier(c, s); c.slash()


@icon("bulb_on", "world", "a lit bulb: lights and power, a light on", ["UI_ZeD_Wheel_LightsPower", "UI_ZeD_Wheel_RoomLights", "ContextMenu_Turn_On", "vehicle_lightsON"])
def bulb_on(c, s):
    if s == 16:
        c.dot(8, 7.5, 4); c.rect(6, 9, 4, 3)
        c.dot(8, 7.5, 2.2, v=0); c.rect(7, 9, 2, 2, v=0)
        c.rect(6, 12, 4, 1); c.rect(7, 14, 2, 1)
        c.rect(7, 0, 2, 2)                                                    # the rays
        c.px((2, 3), (3, 4), (13, 3), (12, 4), (1, 8), (2, 8), (13, 8), (14, 8))
    else:
        c.dot(12, 11, 6); c.rect(9, 13, 6, 5)
        c.dot(12, 11, 3.8, v=0); c.rect(10.5, 13, 3, 4, v=0)
        c.rect(9, 18.5, 6, 1.5); c.rect(10, 21, 4, 1.5)
        c.rect(11, 0, 2, 3)
        c.line([(3.5, 3.5), (5.5, 5.5)], 1.8); c.line([(20.5, 3.5), (18.5, 5.5)], 1.8)
        c.rect(0.5, 11, 3, 2); c.rect(20.5, 11, 3, 2)


@icon("bulb_off", "world", "the bulb, unlit, struck through: a light off", ["ContextMenu_Turn_Off", "vehicle_lightsOFF"])
def bulb_off(c, s):
    if s == 16:
        c.dot(8, 6.5, 4.5); c.rect(5.5, 8, 5, 4)
        c.dot(8, 6.5, 2.6, v=0); c.rect(6.5, 8, 3, 3, v=0)
        c.rect(6, 12, 4, 1); c.rect(6, 14, 4, 1)
    else:
        c.dot(12, 9.5, 7); c.rect(8.5, 12, 7, 6)
        c.dot(12, 9.5, 4.8, v=0); c.rect(10, 12, 4, 5, v=0)
        c.rect(9, 19, 6, 1.5); c.rect(9, 21.5, 6, 1.5)
    c.slash()


@icon("fence", "world", "a stretch of picket fence: an animal zone", ["IGUI_Zone_Name", "AnimalZone"])
def fence(c, s):
    if s == 16:
        for x in (2, 7, 12):
            c.px((x + 1, 1)); c.rect(x, 2, 3, 13)                                 # a picket, pointed
        c.rect(2, 5, 13, 1); c.rect(2, 10, 13, 1)                               # the rails
    else:
        for x in (1.5, 7.5, 13.5, 19.5):
            c.poly([(x, 7), (x + 1.5, 4), (x + 3, 7), (x + 3, 21), (x, 21)])
        c.rect(1, 10, 22, 2); c.rect(1, 16, 22, 2)
        c.rect(0, 21, 24, 1.5)


@icon("eye", "world", "an open eye: search mode on, the view, show the interface", ["UI_enable_search_mode", "UI_ZeD_Wheel_View"])
def eye(c, s):
    if s == 16:
        c.grid(["................",
                "................",
                "................",
                ".....######.....",
                "...##......##...",
                "..#...####...#..",
                ".#...######...#.",
                "#....##.###....#",
                ".#...######...#.",
                "..#...####...#..",
                "...##......##...",
                ".....######.....",
                "................"])
    else:
        c.grid(["........................",
                "........................",
                "........................",
                "........................",
                ".........######.........",
                "......###......###......",
                "....##............##....",
                "...#.....######.....#...",
                "..#.....########.....#..",
                ".#.....###..#####.....#.",
                "#......###..#####......#",
                "#......##########......#",
                ".#.....##########.....#.",
                "..#.....########.....#..",
                "...#.....######.....#...",
                "....##............##....",
                "......###......###......",
                ".........######.........",
                "........................"])
        c.grid(["........................"] * 4 +
               ["........................",
                "......###......###......",
                "....###...........###...",
                "...##..............##...",
                "..##................##..",
                ".##..................##.",
                "##....................##",
                "##....................##",
                ".##..................##.",
                "..##................##..",
                "...##..............##...",
                "....###...........###...",
                "......###......###......"])


@icon("eye_off", "world", "the eye struck through: search mode off, hide the interface", ["UI_disable_search_mode", "UI_ZeD_Wheel_HideInterface"])
def eye_off(c, s):
    eye(c, s); c.slash()


@icon("box_up", "world", "a storage box, its lid on, an arrow up: pick up", ["IGUI_Pickup", "Furniture_Pickup"])
def box_up(c, s):
    if s == 16:
        for i in range(4): c.rect(7 - i, 1 + i, 2 + 2 * i, 1)                 # the arrow
        c.rect(7, 5, 2, 2)
        _box(c, s)
    else:
        for i in range(6): c.rect(11 - i, 1 + i, 2 + 2 * i, 1)
        c.rect(10, 7, 4, 4)
        _box(c, s)


def _box(c, s):
    """the storage box under an arrow: an overhanging lid, a seam, the body with its hand slot"""
    if s == 16:
        c.rect(1, 8, 14, 2); c.rect(2, 11, 12, 4); c.rect(6, 12, 4, 1, v=0)
    else:
        c.rect(1, 12, 22, 3); c.rect(2, 17, 20, 6); c.rect(8, 19, 8, 2, v=0)


@icon("box_down", "world", "the storage box, an arrow down onto it: place", ["Furniture_Place"])
def box_down(c, s):
    if s == 16:
        c.rect(7, 1, 2, 2)
        for i in range(4): c.rect(4 + i, 3 + i, 8 - 2 * i, 1)
        _box(c, s)
    else:
        c.rect(10, 1, 4, 4)
        for i in range(6): c.rect(6 + i, 5 + i, 12 - 2 * i, 1)
        _box(c, s)


@icon("rotate", "world", "a turning arrow: rotate, reset", ["Furniture_Rotate", "UI_ZeD_Wheel_ResetWindows"])
def rotate(c, s):
    if s == 16: c.turn_arrow(8, 8.5, 6.5, 2, 300, 560, head=4.2)
    else: c.turn_arrow(12, 12.5, 10, 3, 300, 560, head=6.2)


def _u(cx, cy, ux, uy, pts):
    """points in a frame: a along (ux, uy), b across it"""
    vx, vy = -uy, ux
    return [(cx + a * ux + b * vx, cy + a * uy + b * vy) for a, b in pts]


@icon("screwdriver", "world", "a screwdriver: take apart", ["Furniture_Disassemble"])
def screwdriver(c, s):
    if s == 16:
        c.grid(["................",
                "..............#.",
                ".............##.",
                "............##..",
                "...........##...",
                "..........##....",
                ".........##.....",
                "........##......",
                "......###.......",
                ".....#####......",
                "....#####.......",
                "...#####........",
                "..#####.........",
                ".#####..........",
                ".###............",
                "................"])
        c.px((4, 11), (6, 9), v=0)
    else:
        c.line([(12, 12), (21.5, 2.5)], 2.4)
        c.line([(2.5, 21.5), (9, 15)], 5.2)
        c.line([(9.5, 14.5), (11.5, 12.5)], 3.2)
        c.line([(4.5, 17.5), (7.5, 14.5)], 1, v=0)


@icon("wrench", "world", "a wrench, its jaw cut to a nut's flats, a hex in its ring end: repair", ["Furniture_Repair", "Furniture_On2"])
def wrench(c, s):
    u = (math.sqrt(.5), -math.sqrt(.5))
    hexagon = lambda cx, cy, r: _u(cx, cy, 1, 0, [(r * math.cos(math.radians(a + 30)), r * math.sin(math.radians(a + 30))) for a in range(0, 360, 60)])
    if s == 16:
        c.line([(4, 12), (10, 6)], 2.6)
        c.poly(_u(11.6, 4.4, *u, [(-3.6, -1.6), (-1.6, -3.8), (2.6, -3.8), (4.4, -1.4), (4.4, 1.4), (2.6, 3.8), (-1.6, 3.8), (-3.6, 1.6)]))
        c.poly(_u(11.6, 4.4, *u, [(6, -1.3), (0.8, -1.3), (-0.6, 0), (0.8, 1.3), (6, 1.3)]), v=0)     # the jaw: two flats, a vee
        c.dot(3.6, 12.4, 3); c.dot(3.6, 12.4, 1.2, v=0)
    else:
        c.line([(6, 18), (15, 9)], 3.6)
        c.poly(_u(17.6, 6.4, *u, [(-5.4, -2.4), (-2.6, -5.6), (3.6, -5.6), (6.6, -2.2), (6.6, 2.2), (3.6, 5.6), (-2.6, 5.6), (-5.4, 2.4)]))
        c.poly(_u(17.6, 6.4, *u, [(8, -2.1), (1.2, -2.1), (-1, 0), (1.2, 2.1), (8, 2.1)]), v=0)
        c.dot(5.2, 18.8, 4.4); c.poly(hexagon(5.2, 18.8, 2.2), v=0)


@icon("generator", "world", "a generator in its frame, a bolt on the side: the generator", ["ContextMenu_Generator"])
def generator(c, s):
    if s == 16:
        c.rect(1, 4, 14, 1); c.rect(1, 14, 14, 1); c.rect(1, 4, 1, 11); c.rect(14, 4, 1, 11)   # the tube frame
        c.rect(3, 6, 10, 7)
        c.grid(["...#.",
                "..#..",
                ".####",
                "...#.",
                "..#.."], ox=5, oy=7, v=0)
        c.rect(4, 2, 4, 2)                                                    # the cap
    else:
        c.rect(1, 6, 22, 2); c.rect(1, 21, 22, 2); c.rect(1, 6, 2, 17); c.rect(21, 6, 2, 17)
        c.rect(5, 9.5, 14, 10)
        c.poly([(13, 10.5), (8.5, 15.2), (11.7, 15.2), (10, 18.8), (15.5, 13.6), (12.3, 13.6), (14, 10.5)], v=0)
        c.rect(5, 3, 6, 3)


@icon("campfire", "world", "a fire on crossed logs: light or put out a fire", ["ContextMenu_Light_fire", "ContextMenu_Put_out_fire"])
def campfire(c, s):
    if s == 16:
        c.poly([(8, 1), (11.5, 5.5), (12, 8.5), (10, 11), (6, 11), (4, 8.5), (5, 5.5), (6.5, 6.5)])
        c.poly([(8, 5.5), (9.8, 8.4), (8.8, 10.2), (7.2, 10.2), (6.2, 8.4)], v=0)
        c.line([(2, 14), (14, 11.5)], 1.8); c.line([(2, 11.5), (14, 14)], 1.8)
    else:
        c.poly([(12, 1), (17, 7.5), (18, 12), (15, 16), (9, 16), (6, 12), (7, 7.5), (9.5, 9)])
        c.poly([(12, 7.5), (14.6, 11.8), (13.2, 14.6), (10.8, 14.6), (9.4, 11.8)], v=0)
        c.line([(2.5, 21.5), (21.5, 17.5)], 2.8); c.line([(2.5, 17.5), (21.5, 21.5)], 2.8)


@icon("chair", "world", "a wooden chair from the front: furniture, the furniture tab", ["IGUI_BackButton_Movable", "Furniture_Off2", "furniture tab"])
def chair(c, s):
    if s == 16:
        c.rect(3, 1, 10, 6); c.rect(4, 2, 1, 4, v=0); c.rect(7, 2, 2, 4, v=0); c.rect(11, 2, 1, 4, v=0)   # the back, its slats
        c.rect(3, 7, 2, 1)
        c.rect(11, 7, 2, 1)
        c.rect(2, 8, 12, 2)                                                   # the seat
        c.rect(2, 10, 2, 5); c.rect(12, 10, 2, 5)                              # the legs
        c.rect(4, 12, 8, 1)                                                    # the rail
    else:
        c.rect(5, 1, 14, 9); c.rect(7, 3, 2, 5, v=0); c.rect(11, 3, 2, 5, v=0); c.rect(15, 3, 2, 5, v=0)
        c.rect(5, 10, 3, 2); c.rect(16, 10, 3, 2)
        c.rect(3, 12, 18, 3)
        c.rect(3, 15, 3, 8); c.rect(18, 15, 3, 8)
        c.rect(6, 18.5, 12, 1.5)


@icon("gauge", "world", "a dial with its needle: the dashboard", ["IGUI_VehiclePartCatdashboard"])
def gauge(c, s):
    if s == 16:
        c.arc(8, 11, 6, 180, 360, 2, caps=False)
        c.rect(1, 11, 2, 2); c.rect(13, 11, 2, 2)
        c.line([(8, 11), (11.5, 6)], 1.4)
        c.dot(8, 11.5, 1.6)
        c.rect(5, 14, 6, 1)
    else:
        c.arc(12, 16, 9.5, 180, 360, 3, caps=False)
        c.rect(1.5, 16, 3, 3); c.rect(19.5, 16, 3, 3)
        for a in (210, 240, 270, 300, 330):
            r = math.radians(a); c.line([(12 + 5.6 * math.cos(r), 16 + 5.6 * math.sin(r)), (12 + 6.8 * math.cos(r), 16 + 6.8 * math.sin(r))], 1.2)
        c.line([(12, 16), (17, 8.5)], 2)
        c.dot(12, 16.5, 2.4)
        c.rect(7, 21, 10, 1.5)


@icon("bullhorn", "world", "a bullhorn with its sound: shout", ["IGUI_Emote_Shout"])
def bullhorn(c, s):
    if s == 16:
        c.poly([(1, 6), (4, 6), (10, 2), (11, 2), (11, 13), (10, 13), (4, 9), (1, 9)])
        c.rect(4, 9, 2, 4)                                                    # the handle
        c.px((13, 4), (13, 11), (14, 6), (14, 7), (14, 8), (14, 9))           # the sound
    else:
        c.poly([(1, 9), (6, 9), (15, 3), (16.5, 3), (16.5, 20), (15, 20), (6, 14), (1, 14)])
        c.rect(6, 14, 3, 6)
        c.arc(16, 11.5, 5.5, -50, 50, 1.6); c.arc(16, 11.5, 8.5, -45, 45, 1.6)


@icon("rooms", "world", "a floor plan, walls with a door: the rooms editor", ["IGUI_BuildingRoomsEditor_Title"])
def rooms(c, s):
    if s == 16:
        c.rect(1, 1, 14, 14); c.rect(2, 2, 12, 12, v=0)
        c.rect(4, 14, 3, 1, v=0)                                              # the front door
        c.rect(8, 2, 1, 5); c.rect(8, 10, 1, 4)                               # a wall with a doorway
        c.rect(9, 8, 5, 1)
        c.rect(2, 7, 3, 1)
    else:
        c.rect(1, 1, 22, 22); c.rect(3, 3, 18, 18, v=0)
        c.rect(5, 21, 5, 2, v=0)
        c.rect(12, 3, 2, 7); c.rect(12, 15, 2, 6)
        c.rect(14, 12, 7, 2)
        c.rect(3, 10, 5, 2)
