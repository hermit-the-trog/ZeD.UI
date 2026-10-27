"""The vehicle's wheel (vanilla ISVehicleMenu's radial): seats and doors, the key, the lights, the heater, the horn,
the windows and locks, the engine, washing, towing, and fuel"""
import math

from kit import icon


# ------------------------------------------------------------------ seats and doors
@icon("seat", "vehicle", "a car seat from the side, its headrest apart, on its base: change seats", ["IGUI_SwitchSeat", "vehicle_changeseats"])
def seat(c, s):
    """the base reworked Oct 27 (director: "needs work on the base. no rails"): a block under the cushion, a clear
    line between, narrowing to the floor"""
    if s == 16:
        c.rect(2, 1, 5, 2)                                                     # the headrest
        c.line([(4.6, 6.4), (6.2, 10.2)], 4)                                   # the back, raked
        c.line([(6.5, 11.3), (13, 10.6)], 3)                                   # the cushion
        c.rect(5, 12, 10, 1, v=0)                                              # the line under it
        c.poly([(7, 13), (13, 13), (12, 15), (8, 15)])                         # the base
    else:
        c.poly([(2.6, 2.6), (10, 1.2), (10.8, 5), (3.4, 6.4)])
        c.line([(7.0, 10), (9.6, 15.6)], 6)
        c.line([(10, 17.2), (20, 16.2)], 4.6)
        c.rect(8, 19, 15, 1, v=0)
        c.poly([(10, 20), (20, 20), (18.5, 23), (11.5, 23)])


def _door(c, s):
    """a car's front door from the side, the nose to the left: the raked pillar, the window, the handle"""
    if s == 16:
        c.poly([(6, 1), (15, 1), (15, 15), (1, 15), (1, 6.5)])
        c.poly([(6.5, 2.3), (13.7, 2.3), (13.7, 7.8), (2.3, 7.8)], v=0)
        c.rect(8, 10, 4, 1, v=0)
    else:
        c.poly([(9, 1), (23, 1), (23, 23), (1, 23), (1, 9.5)])
        c.poly([(9.8, 3), (21, 3), (21, 10), (3.9, 10)], v=0)
        c.rect(12, 13.5, 6, 2, v=0)


@icon("car_door", "vehicle", "a car door from the side: open or close a door", ["ContextMenu_Open_door", "ContextMenu_Close_door"])
def car_door(c, s):
    _door(c, s)


@icon("car_enter", "vehicle", "the car door, an arrow in: get in", ["IGUI_EnterVehicle"])
def car_enter(c, s):
    _door(c, s); c.badge("left")


@icon("car_exit", "vehicle", "the car door, an arrow out: get out", ["IGUI_ExitVehicle", "vehicle_exit"])
def car_exit(c, s):
    _door(c, s); c.badge("right")


# ------------------------------------------------------------------ the key
@icon("key", "vehicle", "a car key: start the engine", ["ContextMenu_VehicleStartEngine", "vehicle_ignitionON"])
def key(c, s):
    if s == 16:
        c.dot(4.5, 8, 3.6); c.dot(3.4, 8, 1.1, v=0)                           # the head, its ring hole
        c.rect(8, 7, 6, 3); c.px((14, 8))                                      # the blade
        c.rect(11, 10, 3, 1); c.rect(12, 11, 2, 1)                             # the bit, one step
    else:
        c.dot(6.5, 12, 5.5); c.dot(4.6, 12, 1.7, v=0)
        c.rect(12, 9.5, 9, 5); c.poly([(21, 9.5), (23, 12), (21, 14.5)])
        c.rect(13.5, 11.5, 7, 1, v=0)                                          # the groove
        c.rect(16, 14.5, 5, 2); c.rect(18, 16.5, 3, 2)                         # the bit, one step


@icon("key_off", "vehicle", "the car key struck through: shut the engine off", ["ContextMenu_VehicleShutOff", "vehicle_ignitionOFF"])
def key_off(c, s):
    key(c, s); c.slash()


@icon("hotwire", "vehicle", "two cables, their stripped ends meeting in a spark: hotwire", ["ContextMenu_VehicleHotwire"])
def hotwire(c, s):
    if s == 16:
        c.line([(1, 3), (4, 3.5), (6, 6)], 2); c.line([(6, 6), (8, 8)], 1)
        c.line([(1, 14), (4, 13.5), (6, 11)], 2); c.line([(6, 11), (8, 9)], 1)
        c.rect(11, 8, 3, 1); c.rect(9, 2, 1, 3); c.rect(9, 12, 1, 3)        # the spark
        c.px((11, 6), (12, 5), (13, 4), (11, 10), (12, 11), (13, 12))
    else:
        c.line([(1, 5), (5.5, 5.5), (9, 9.5)], 3); c.line([(9, 9.5), (12, 12)], 1.5)
        c.line([(1, 20), (5.5, 19.5), (9, 15.5)], 3); c.line([(9, 15.5), (12, 13)], 1.5)
        c.rect(16, 11.5, 6, 2); c.rect(13, 3, 2, 5); c.rect(13, 17, 2, 5)
        c.diag(16, 8, 4, 2, up=True); c.diag(16, 16, 4, 2, up=False)


@icon("hotwire_off", "vehicle", "the wires struck through: you can't hotwire this yet", ["ContextMenu_VehicleHotwireSkill"])
def hotwire_off(c, s):
    hotwire(c, s); c.slash()


# ------------------------------------------------------------------ lights, climate, horn, radio
def _lamp(c, s):
    if s == 16:
        c.ellipse(8, 8, 6.5, 6); c.rect(0, 0, 8, 16, v=0)
        for y in (3, 6, 9, 12): c.rect(1, y, 6, 1)
    else:
        c.ellipse(12, 12, 10.5, 9); c.rect(0, 0, 12, 24, v=0)
        for y in (4.5, 9, 13.5, 18): c.rect(1, y, 9, 2)


@icon("headlight_on", "vehicle", "the headlamp sign, its beams out: headlights on", ["ContextMenu_VehicleHeadlightsOn"])
def headlight_on(c, s):
    _lamp(c, s)


@icon("headlight_off", "vehicle", "the headlamp sign struck through: headlights off", ["ContextMenu_VehicleHeadlightsOff"])
def headlight_off(c, s):
    _lamp(c, s); c.slash()


@icon("heat", "vehicle", "heat rising off a heater: the heater, warm", ["vehicle_temperatureHOT"])
def heat(c, s):
    if s == 16:
        for x0 in (3.5, 8, 12.5):
            c.line([(x0 + 1.0 * math.sin((y - 1.5) / 9 * 2 * math.pi), y) for y in [1.5 + i * 0.5 for i in range(19)]], 1.3)
        c.rect(1, 13, 14, 2)
    else:
        for x0 in (5.5, 12, 18.5):
            c.line([(x0 + 1.6 * math.sin((y - 2) / 14 * 2 * math.pi), y) for y in [2 + i * 0.5 for i in range(29)]], 2.2)
        c.rect(1, 19.5, 22, 3)


@icon("snowflake", "vehicle", "a snowflake: the heater, cold", ["vehicle_temperatureCOLD"])
def snowflake(c, s):
    cx = cy = (7.5 if s == 16 else 12)
    R = 6.5 if s == 16 else 10.5
    w = 1 if s == 16 else 2
    for a in (90, 30, 150):
        r = math.radians(a); dx, dy = R * math.cos(r), R * math.sin(r)
        c.line([(cx - dx, cy - dy), (cx + dx, cy + dy)], w, caps=False)
        for sg in (1, -1):
            bx, by = cx + sg * dx * 0.6, cy + sg * dy * 0.6
            for b in (a + 45, a - 45):
                rb = math.radians(b); L = 2.2 if s == 16 else 3.6
                c.line([(bx, by), (bx + sg * L * math.cos(rb), by + sg * L * math.sin(rb))], w, caps=False)


@icon("horn", "vehicle", "the steering wheel, sound coming off it: the horn", ["ContextMenu_VehicleHorn", "vehicle_horn"])
def horn(c, s):
    if s == 16:
        c.oring(6, 8, 5.5, 1.5)
        c.dot(6, 8.5, 1.6); c.rect(1, 8, 10, 1); c.rect(5.5, 9, 1, 4)
        c.arc(10, 8, 3, -45, 45, 1); c.arc(10, 8, 5, -40, 40, 1)
    else:
        c.oring(8.5, 12, 7.8, 2.4)
        c.dot(8.5, 12.8, 2.4); c.rect(1.5, 11.5, 14, 2); c.rect(7.5, 13, 2, 6)
        c.arc(15.5, 12, 4.5, -45, 45, 2); c.arc(15.5, 12, 7.5, -40, 40, 2)


@icon("lightbar", "vehicle", "an emergency beacon flashing: the light bar", ["ContextMenu_VehicleLightbar", "vehicle_lightbar"])
def lightbar(c, s):
    if s == 16:
        c.ellipse(8, 9, 4, 4.5); c.rect(4, 9, 8, 2)                           # the dome
        c.rect(5, 6, 1, 3, v=0)                                               # its shine
        c.rect(2, 11, 12, 3)                                                  # the base
        c.rect(7, 1, 2, 2); c.px((2, 3), (3, 4), (13, 3), (12, 4)); c.rect(0, 8, 2, 1); c.rect(14, 8, 2, 1)
    else:
        c.ellipse(12, 13, 6.5, 7); c.rect(5.5, 13, 13, 3)
        c.rect(8, 9, 1.6, 5, v=0)
        c.rect(3, 16.5, 18, 4.5); c.rect(1.5, 21, 21, 1.5)
        c.rect(11, 0.5, 2, 3.5); c.line([(3, 3.5), (5.5, 6)], 2); c.line([(21, 3.5), (18.5, 6)], 2)
        c.rect(0, 11.5, 3, 2); c.rect(21, 11.5, 3, 2)


@icon("speaker", "vehicle", "a loudspeaker with its sound: the car radio, a device's options", ["IGUI_DeviceOptions", "vehicle_speakersON"])
def speaker(c, s):
    if s == 16:
        c.rect(1, 6, 3, 4); c.poly([(4, 6), (8, 2.5), (8, 13.5), (4, 10)])
        c.arc(8.5, 8, 3, -50, 50, 1); c.arc(8.5, 8, 5.5, -45, 45, 1)
    else:
        c.rect(1.5, 8.5, 5, 7); c.poly([(6.5, 8.5), (13, 2.5), (13, 21.5), (6.5, 15.5)])
        c.arc(13.5, 12, 4.5, -50, 50, 2); c.arc(13.5, 12, 8.5, -45, 45, 2)


# ------------------------------------------------------------------ windows and locks
def _pane(c, s, glass):
    """a car's side window: the raked pillar at the front; glass in, or only its frame when it is wound down"""
    if s == 16:
        c.poly([(6, 2), (15, 2), (15, 14), (1, 14), (1, 7)])
        if not glass: c.poly([(6.6, 3.4), (13.6, 3.4), (13.6, 12.6), (2.4, 12.6), (2.4, 7.6)], v=0)
        else: c.line([(4.5, 11), (8, 5.5)], 1, v=0)
    else:
        c.poly([(9, 3), (23, 3), (23, 21), (1, 21), (1, 11)])
        if not glass: c.poly([(9.8, 5), (21, 5), (21, 19), (3, 19), (3, 11.8)], v=0)
        else: c.line([(6, 16.5), (11, 8.5)], 1.6, v=0)


@icon("window_open", "vehicle", "the car window's frame, the glass gone down, an arrow down: open the window", ["ContextMenu_Open_window", "vehicle_windowOPEN"])
def window_open(c, s):
    _pane(c, s, False); c.badge("down")


@icon("window_close", "vehicle", "the car window glassed in, an arrow up: close the window", ["ContextMenu_Close_window", "vehicle_windowCLOSED"])
def window_close(c, s):
    _pane(c, s, True); c.badge("up")


@icon("window_smash", "vehicle", "the car window cracked from a blow: smash the window", ["ContextMenu_Vehicle_Smashwindow", "vehicle_smash_window"])
def window_smash(c, s):
    _pane(c, s, True)
    if s == 16:
        c.line([(8.5, 8), (12, 4)], 1, v=0); c.line([(8.5, 8), (13, 10)], 1, v=0); c.line([(8.5, 8), (5, 12)], 1, v=0)
        c.line([(8.5, 8), (4, 8.5)], 1, v=0); c.dot(8.5, 8, 1.2, v=0)
    else:
        for (x, y) in ((18.5, 6), (21, 15), (7, 19), (4, 12.5), (13, 19)): c.line([(13, 11.5), (x, y)], 1.4, v=0)
        c.dot(13, 11.5, 2, v=0)


def _lock(c, s, shut):
    if s == 16:
        c.rrect(2, 7, 12, 8, 1)
        c.dot(8, 10, 1.3, v=0); c.rect(7.5, 10, 1, 3, v=0)
        if shut:
            c.arc(8, 6, 3.2, 180, 360, 1.6, caps=False); c.rect(4, 6, 2, 1); c.rect(10, 6, 2, 1)
        else:
            c.arc(10.5, 4, 3.2, 180, 360, 1.6, caps=False); c.rect(12.5, 4, 2, 3); c.rect(6.5, 4, 2, 1)
    else:
        c.rrect(3, 11, 18, 12, 2)
        c.dot(12, 15.5, 2, v=0); c.rect(11.2, 15.5, 1.6, 4.5, v=0)
        if shut:
            c.arc(12, 8.5, 5, 180, 360, 2.6, caps=False); c.rect(5.7, 8.5, 2.6, 2.5); c.rect(15.7, 8.5, 2.6, 2.5)
        else:
            c.arc(16, 5.5, 5, 180, 360, 2.6, caps=False); c.rect(19.7, 5.5, 2.6, 5.5); c.rect(9.7, 5.5, 2.6, 2)


@icon("padlock", "vehicle", "a shut padlock: lock the doors", ["ContextMenu_Lock_Doors", "ContextMenu_LockDoor"])
def padlock(c, s):
    _lock(c, s, True)


@icon("padlock_open", "vehicle", "an open padlock: unlock the doors", ["ContextMenu_Unlock_Doors", "ContextMenu_UnlockDoor"])
def padlock_open(c, s):
    _lock(c, s, False)


# ------------------------------------------------------------------ the engine, washing, towing
@icon("engine", "vehicle", "the engine block (the check-engine sign): the mechanics", ["ContextMenu_VehicleMechanics", "vehicle_repair"])
def engine(c, s):
    if s == 16:
        c.grid(["................",
                "....######......",
                "......##........",
                "...#########....",
                "...#.......#.#..",
                ".#.#.......###..",
                ".###.......#.#..",
                ".#.#.......#.#..",
                ".###.......###..",
                ".#.#.......#.#..",
                "...#.......#....",
                "...#########....",
                "................"], oy=1)
    else:
        c.rect(8, 2, 8, 2); c.rect(11, 4, 2, 3)                                # the intake
        c.rect(5, 7, 13, 13); c.rect(7, 9, 9, 9, v=0)                          # the block
        c.rect(1, 9, 2, 9); c.rect(3, 12, 2, 2)                                # the fan
        c.rect(18, 12, 2, 2); c.poly([(20, 9), (23, 6), (23, 21), (20, 18)])   # the exhaust
        c.rect(20, 11, 1.6, 5, v=0)


def _car(c, s, y0):
    """a small car from the front, its top at y0: for the wash"""
    if s == 16:
        c.poly([(4, y0), (12, y0), (13.5, y0 + 3), (2.5, y0 + 3)])
        c.poly([(5, y0 + 1), (11, y0 + 1), (11.8, y0 + 2.5), (4.2, y0 + 2.5)], v=0)
        c.rect(1, y0 + 3, 14, 3); c.rect(2, y0 + 6, 3, 1); c.rect(11, y0 + 6, 3, 1)
        c.rect(2, y0 + 4, 2, 1, v=0); c.rect(12, y0 + 4, 2, 1, v=0)
    else:
        c.poly([(6, y0), (18, y0), (20.5, y0 + 4.5), (3.5, y0 + 4.5)])
        c.poly([(7.2, y0 + 1.4), (16.8, y0 + 1.4), (18.4, y0 + 3.6), (5.6, y0 + 3.6)], v=0)
        c.rrect(1, y0 + 4, 22, 5, 1.2); c.rect(3, y0 + 9, 4, 2); c.rect(17, y0 + 9, 4, 2)
        c.rect(3, y0 + 5.5, 3, 1.5, v=0); c.rect(18, y0 + 5.5, 3, 1.5, v=0)


def _drop(c, x, y, h):
    """a water drop, its tip at (x, y), h tall"""
    r = h * 0.36
    c.circle(x, y + h - r, r); c.poly([(x, y), (x + r * 0.95, y + h - r * 1.2), (x - r * 0.95, y + h - r * 1.2)])


@icon("wash", "vehicle", "water falling on a car: wash it", ["ContextMenu_Vehicle_Wash", "Item_WaterDrop"])
def wash(c, s):
    if s == 16:
        _car(c, s, 8)
        c.grid([".#.....#.....#.",
                ".#.....#.....#.",
                "###...###...###",
                "###...###...###",
                ".#.....#.....#."], ox=0, oy=1)
    else:
        _car(c, s, 11)
        for x in (5, 12, 19): _drop(c, x, 1, 7.5)


def _links(c, s, joined):
    if s == 16:
        A = [(3.2, 12.8), (6.3, 9.7)] if joined else [(2.6, 13.4), (5.4, 10.6)]
        B = [(9.7, 6.3), (12.8, 3.2)] if joined else [(10.6, 5.4), (13.4, 2.6)]
        for P in (A, B): c.line(P, 5.2); c.line(P, 2.0, v=0)
        if joined: c.line([(6, 10), (10, 6)], 1.4)
        else: c.px((7, 6), (6, 5), (9, 10), (10, 9))
    else:
        A = [(5, 19), (10, 14)] if joined else [(4, 20), (8.5, 15.5)]
        B = [(14, 10), (19, 5)] if joined else [(15.5, 8.5), (20, 4)]
        for P in (A, B): c.line(P, 7.6); c.line(P, 3.2, v=0)
        if joined: c.line([(9, 15), (15, 9)], 2.2)
        else:
            c.line([(10, 8), (8, 6)], 1.6); c.line([(14, 16), (16, 18)], 1.6)


@icon("link", "vehicle", "two chain links joined: hitch the trailer", ["ContextMenu_Vehicle_AttachTrailer"])
def link(c, s):
    _links(c, s, True)


@icon("unlink", "vehicle", "the two links parted: unhitch the trailer", ["ContextMenu_Vehicle_DetachTrailer"])
def unlink(c, s):
    _links(c, s, False)


# ------------------------------------------------------------------ fuel
@icon("gas_pump", "vehicle", "a fuel pump with its nozzle: fill up at the pump", ["ContextMenu_VehicleRefuelFromPump", "vehicle_refuel_from_pump"])
def gas_pump(c, s):
    if s == 16:
        c.rect(2, 2, 8, 12); c.rect(4, 4, 4, 3, v=0)
        c.rect(1, 14, 10, 1)
        c.rect(10, 10, 3, 1); c.rect(12, 4, 1, 6); c.rect(11, 2, 3, 2)
    else:
        c.rrect(3, 2, 11, 19, 1.5); c.rect(5.5, 4.5, 6, 5, v=0)
        c.rect(1, 21, 15, 2)
        c.line([(14, 16), (19, 16), (19, 7.5)], 2, caps=False); c.rect(17, 3, 4, 4.5)


def _can(c, s, x0=0):
    if s == 16:
        c.rrect(2 + x0, 4, 11, 11, 1)
        c.rect(3 + x0, 1, 5, 1); c.rect(3 + x0, 2, 1, 2); c.rect(7 + x0, 2, 1, 2)
        c.poly([(9 + x0, 4), (11 + x0, 1), (13 + x0, 1.6), (12 + x0, 4)])
        c.line([(4.5 + x0, 6.5), (10.5 + x0, 12.5)], 1, v=0); c.line([(10.5 + x0, 6.5), (4.5 + x0, 12.5)], 1, v=0)
    else:
        c.rrect(2 + x0, 6, 17, 17, 2)
        c.rect(4 + x0, 1.5, 7, 2); c.rect(4 + x0, 3.5, 2, 2.5); c.rect(9 + x0, 3.5, 2, 2.5)
        c.poly([(13 + x0, 6), (16 + x0, 1.5), (19.5 + x0, 2.2), (18 + x0, 6)])
        c.line([(5.5 + x0, 9.5), (15.5 + x0, 19.5)], 1.6, v=0); c.line([(15.5 + x0, 9.5), (5.5 + x0, 19.5)], 1.6, v=0)


@icon("gas_can", "vehicle", "a jerry can: add petrol from a can", ["ContextMenu_VehicleAddGas", "gas_refuel", "Item_Petrol"])
def gas_can(c, s):
    _can(c, s)


@icon("gas_siphon", "vehicle", "the jerry can, a hose drawn from it: siphon the petrol out", ["ContextMenu_VehicleSiphonGas", "gas_siphon"])
def gas_siphon(c, s):
    if s == 16:
        _can(c, s, -1)
        c.line([(11.5, 1.5), (13.5, 1), (14.5, 3), (14.5, 14.5)], 1, caps=False)
    else:
        _can(c, s, -1.5)
        c.line([(17.5, 2), (20.5, 1.2), (22, 3.5), (22, 22.5)], 1.8, caps=False)
