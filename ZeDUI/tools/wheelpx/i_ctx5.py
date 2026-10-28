"""The right-click menu, group 5: combat and medical (fighting, weapons and their parts, ammunition; treating wounds,
medicine, checks; the dead). Drawn in the wheels' ink to replace the menu's licensed pictures; the target, the
firearm's magazine in and out, rounds out, rack, the backpack, link and unlink, the knife, the bandage, the needle,
the thermometer, the heart, the flame, the eye and the hand are taken as they are (map.py CTX).

Coordinates are on the 16 grid's live area; U lays them out again on the 24 grid (i_ctx1)."""
import math

from kit import icon
from i_ctx1 import U, W, P


# ------------------------------------------------------------------ fighting
@icon("gun", "ctx5", "the firearm wheel's pistol: a gun, clean the gun, its type", ["Clean Gun", "ContextMenu_GunType"])
def gun(c, s):
    import i_gun
    i_gun._pistol(c, s)


@icon("gun_fire", "ctx5", "a pistol firing, a flash bursting from its muzzle: attack, fire, fire mode", ["Attack", "Fire"])
def gun_fire(c, s):
    # (group 5 round 1, director: "gun fire need refine")
    if s == 16:
        c.grid(["............#..#",
                ".............##.",
                "##########.#####",
                "##########..###.",
                "##########.#####",
                ".####.##.....##.",
                ".####.##....#..#",
                ".####...........",
                "####............",
                "####............"], oy=2)
    else:
        c.grid(["..................#....#",
                "...................#..#.",
                "..............##...####.",
                "##############...######.",
                "##############..########",
                "##############...######.",
                "##############.....####.",
                ".#####...###.......#..#.",
                ".#####..####......#....#",
                ".#####..#.##............",
                ".#####...##.............",
                "######..................",
                "######..................",
                "######.................."], oy=3)


@icon("push", "ctx5", "an arrow driving into a bar: shove, push, insert", ["Shove", "Insert"])
def push(c, s):
    u = U(s)
    c.rect(u(1), u(7), u(9) - u(1), u(9) - u(7))                                  # the shaft
    c.poly(P(s, [(8, 3.5), (12.5, 8), (8, 12.5)]))                                # the head
    c.rect(u(13), u(1.5), u(15) - u(13), u(14.5) - u(1.5))                        # what it drives into


@icon("boot", "ctx5", "a boot: stomp, the shins and thighs", ["Stomp", "ContextMenu_LeftShin"])
def boot(c, s):
    u = U(s)
    c.poly(P(s, [(3.5, 1), (9, 1), (9, 8), (14.5, 10.5), (15, 13.5), (3, 13.5)]))
    c.rect(u(3), u(13.5), u(15) - u(3), u(15) - u(13.5))                          # the sole
    c.rect(u(3), u(12.6), u(15) - u(3), W(s, 0.8, 1.2), v=0)
    for y in (3.5, 6): c.rect(u(5.5), u(y), u(8) - u(5.5), W(s, 0.9, 1.3), v=0)  # the laces


@icon("fist", "ctx5", "a clenched fist: smash, grab", ["Smash", "Grab"])
def fist(c, s):
    u = U(s)
    c.rrect(u(2), u(3), u(14) - u(2), u(13) - u(3), W(s, 2, 3))
    for x in (5, 8, 11): c.rect(u(x), u(3), W(s, 0.9, 1.3), u(7.5) - u(3), v=0)   # between the fingers
    c.rect(u(2), u(7.5), u(9.5) - u(2), W(s, 0.9, 1.3), v=0)                      # the thumb's edge
    c.rect(u(4), u(13), u(12) - u(4), u(15) - u(13))                              # the wrist


@icon("hand_main", "ctx5", "the open hand, an arrow right: equip in the main hand", ["Equip Primary"])
def hand_main(c, s):
    import i_char
    i_char.hand(c, s); c.badge("right")


@icon("hand_off", "ctx5", "the open hand mirrored, an arrow left: equip in the off hand", ["Equip Secondary"])
def hand_off(c, s):
    import i_char
    i_char.hand(c, s); c.flip_h(); c.badge("left")


@icon("holster", "ctx5", "the firearm wheel's pistol, an arrow down: holster it", ["Holster"])
def holster(c, s):
    import i_gun
    i_gun._pistol(c, s); c.badge("down")


@icon("scope", "ctx5", "a rifle scope: the eyepiece, the tube, the turret, the objective, its mounts: attach a scope", ["Attach Scope"])
def scope(c, s):
    if s == 16:
        c.grid([".......##.......",
                "###....##...####",
                "################",
                "################",
                "###.........####",
                "....##....##...."], oy=5)
    else:
        c.grid(["..........####..........",
                "..........####..........",
                "####......####.....#####",
                "####...............#####",
                "########################",
                "########################",
                "########################",
                "####...............#####",
                "####...............#####",
                "......###.....###.......",
                "......###.....###......."], oy=6)


@icon("suppressor", "ctx5", "a suppressor, its rings: attach a suppressor", ["Attach Suppressor"])
def suppressor(c, s):
    u = U(s)
    c.rrect(u(1), u(5), u(13) - u(1), u(11) - u(5), W(s, 1.5, 2.2))
    for x in (4, 7, 10): c.rect(u(x), u(5), W(s, 0.9, 1.3), u(11) - u(5), v=0)   # its rings
    c.rect(u(13), u(6.5), u(15.5) - u(13), u(9.5) - u(6.5))                       # the thread
    c.dot(u(2.6), u(8), W(s, 1, 1.5), v=0)                                        # the bore


@icon("bayonet", "ctx5", "a bayonet, its ring and blade: attach a bayonet", ["Attach Bayonet"])
def bayonet(c, s):
    u = U(s)
    c.poly(P(s, [(6, 7), (15.5, 7.5), (13, 9.5), (6, 9.5)]))                      # the blade
    c.rect(u(4.5), u(5.5), W(s, 1.5, 2.2), u(11) - u(5.5))                        # the guard
    c.rect(u(1), u(7), u(4.5) - u(1), u(9.5) - u(7))                              # the grip
    c.oring(u(5.2), u(3.4), u(2.2) - u(0), W(s, 1, 1.5))                          # the muzzle ring


@icon("ammo", "ctx5", "three rounds standing: ammunition, check or combine it, its type", ["Check Ammo", "Combine Ammo"])
def ammo(c, s):
    u = U(s)
    for x in (2.5, 7, 11.5):
        c.rect(u(x), u(6), u(x + 3) - u(x), u(15) - u(6))                         # the case
        c.ellipse(u(x + 1.5), u(6), u(1.5) - u(0), u(4.5) - u(0)); c.rect(u(x), u(6), u(x + 3) - u(x), u(7.5) - u(6))   # the bullet
        c.rect(u(x), u(12.5), u(x + 3) - u(x), W(s, 0.8, 1.2), v=0)               # the rim


@icon("ammo_off", "ctx5", "the rounds, struck through: no bullets", ["ContextMenu_NoBullets"])
def ammo_off(c, s):
    ammo(c, s); c.slash()


@icon("magazine", "ctx5", "a pistol magazine, a round at its lips: the magazine", ["ContextMenu_Magazine"])
def magazine(c, s):
    u = U(s)
    c.poly(P(s, [(5, 3.5), (11, 3.5), (12.5, 13.5), (6.5, 13.5)]))
    c.rect(u(6), u(13.5), u(13.5) - u(6), u(15) - u(13.5))                        # the base plate
    c.rect(u(6.2), u(5), u(10.6) - u(6.2), W(s, 0.8, 1.2), v=0)
    c.ellipse(u(8), u(2.4), u(2.6) - u(0), u(1.4) - u(0))                         # the round
    for y in (7.5, 10): c.rect(u(7.8), u(y), u(10.2) - u(7.8), W(s, 0.9, 1.3), v=0)   # the witness holes


# ------------------------------------------------------------------ treating wounds, medicine
@icon("bandage_off", "ctx5", "the bandage, a minus: take a bandage off", ["Remove Bandage"])
def bandage_off(c, s):
    import i_char
    i_char.bandage(c, s); c.badge("minus")


@icon("splint", "ctx5", "a limb in outline, a board either side, two wraps binding them: apply a splint", ["Apply Splint", "ContextMenu_Splint"])
def splint(c, s):
    # (group 5 round 1, director: "splint ... need refine": the limb, upright, its boards and wraps)
    if s == 16:
        c.grid(["..##..####..##..",
                "..##.#....#.##..",
                "..##.#....#.##..",
                ".##############.",
                ".##############.",
                "..##.#....#.##..",
                "..##.#....#.##..",
                "..##.#....#.##..",
                "..##.#....#.##..",
                ".##############.",
                ".##############.",
                "..##.#....#.##..",
                "..##.#....#.##..",
                "..##..####..##.."], oy=1)
    else:
        c.grid(["...###...######...###...",
                "...###..##....##..###...",
                "...###..#......#..###...",
                "...###..#......#..###...",
                ".######################.",
                ".######################.",
                ".######################.",
                "...###..#......#..###...",
                "...###..#......#..###...",
                "...###..#......#..###...",
                "...###..#......#..###...",
                "...###..#......#..###...",
                "...###..#......#..###...",
                ".######################.",
                ".######################.",
                ".######################.",
                "...###..#......#..###...",
                "...###..#......#..###...",
                "...###..##....##..###...",
                "...###...######...###..."], oy=2)


@icon("tourniquet", "ctx5", "a limb in outline, a strap pulled tight round it, the rod across, the strap's tail: apply a tourniquet", ["Apply Tourniquet"])
def tourniquet(c, s):
    # (group 5 round 1, director: "tourniquet ... need refine": on the same limb as the splint)
    if s == 16:
        c.grid([".....######.....",
                ".....#....#.....",
                ".....#....#.....",
                ".....#....#.....",
                "...##########...",
                "##############..",
                "##############..",
                "...##########...",
                ".....#....#.##..",
                ".....#....#..##.",
                ".....#....#...##",
                ".....#....#.....",
                ".....#....#.....",
                ".....######....."], oy=1)
    else:
        c.grid(["........########........",
                ".......##......##.......",
                ".......#........#.......",
                ".......#........#.......",
                ".......#........#.......",
                ".......#........#.......",
                "....################....",
                "....################....",
                "#####################...",
                "#####################...",
                "....################....",
                "....################....",
                ".......#........#.###...",
                ".......#........#..###..",
                ".......#........#...###.",
                ".......#........#....###",
                ".......#........#.......",
                ".......#........#.......",
                ".......##......##.......",
                "........########........"], oy=2)


@icon("ointment", "ctx5", "an ointment tube: the crimped end, the body with a cross on it tapering to its shoulder, the cap: ointment, burn salve, treat", ["Apply Ointment", "Apply Burn Salve"])
def ointment(c, s):
    # (group 5 round 1, director: "ointement ... need refine")
    if s == 16:
        c.grid(["##.#######......",
                "##.####.###.....",
                "##.###...###.###",
                "##.####.####.###",
                "##.########.....",
                "##.#######......"], oy=5)
    else:
        c.grid(["###.##############......",
                "###.#######.#######.....",
                "###.#######.########....",
                "###.#####.....######.###",
                "###.#######.########.###",
                "###.#######.########.###",
                "###.################....",
                "###.###############.....",
                "###.##############......"], oy=7)


@icon("pulse", "ctx5", "a heart beat's line: take the pulse, health", ["Take Pulse", "ContextMenu_HasHealth"])
def pulse(c, s):
    c.line(P(s, [(0.5, 9), (4, 9), (5.5, 6), (7.5, 13), (9.5, 2.5), (11, 9), (15.5, 9)]), W(s, 1.6, 2.4))


@icon("pliers", "ctx5", "tweezers on the slant: two arms joined at one end, their tips meeting: take a bullet out", ["Extract Bullet"])
def pliers(c, s):
    c.line(P(s, [(14, 2), (8.2, 5.6), (2.4, 13.6)]), W(s, 1.6, 2.4))
    c.line(P(s, [(14, 2), (10.4, 7.8), (2.4, 13.6)]), W(s, 1.6, 2.4))
    u = U(s); c.dot(u(13.8), u(2.2), W(s, 1.4, 2.1))


@icon("pills", "ctx5", "a capsule and a tablet: take medicine", ["Take Medication"])
def pills(c, s):
    u = U(s)
    c.line(P(s, [(3, 11), (10, 4)]), W(s, 5, 7.5))                                 # the capsule
    c.line(P(s, [(5.4, 5.2), (7.8, 8)]) if False else P(s, [(5, 5.4), (7.6, 7.8)]), W(s, 0, 0)) if False else None
    c.line(P(s, [(4.4, 5.2), (8.2, 9)]), W(s, 1, 1.5), v=0, caps=False)             # its two halves
    c.dot(u(12.5), u(12.5), u(2.6) - u(0)); c.rect(u(10), u(12), u(15) - u(10), W(s, 0.9, 1.3), v=0)   # the tablet, scored


@icon("eyedrop", "ctx5", "a dropper over an eye, a drop falling between them: eye drops", ["Apply Eye Drops"])
def eyedrop(c, s):
    # (group 5 round 1, director: "eyedrop ... need refine")
    if s == 16:
        c.grid([".....####.......",
                ".....####.......",
                "....######......",
                ".....####.......",
                "......##........",
                "................",
                "......#.........",
                ".....###........",
                "................",
                "...########.....",
                ".##...##...##...",
                "#....####....#..",
                ".##...##...##...",
                "...########....."], oy=1)
    else:
        c.grid(["........######..........",
                "........######..........",
                ".......########.........",
                "........######..........",
                ".........####...........",
                "..........##............",
                "........................",
                "..........##............",
                ".........####...........",
                ".........####...........",
                "........................",
                "....##############......",
                "..###.....####.....###..",
                ".##......######......##.",
                "##.......######.......##",
                ".##......######......##.",
                "..###.....####.....###..",
                "....##############......"], oy=3)


@icon("stethoscope", "ctx5", "a stethoscope: a medical check", ["ContextMenu_Medical_Check"])
def stethoscope(c, s):
    u = U(s)
    c.line(P(s, [(3, 1), (3, 6), (6, 9.5), (9, 6), (9, 1)]), W(s, 1.4, 2.1))       # the tubes
    c.line(P(s, [(6, 9.5), (6, 12), (8.5, 14), (11.5, 13)]), W(s, 1.4, 2.1))
    c.oring(u(12.5), u(10.5), u(2.6) - u(0), W(s, 1.3, 2))                         # the chest piece
    c.dot(u(12.5), u(10.5), u(1.1) - u(0))


@icon("spray", "ctx5", "a spray bottle, its mist: disinfect, antiseptic, bleach", ["Disinfect", "Apply Antiseptic"])
def spray(c, s):
    u = U(s)
    c.poly(P(s, [(4, 5.5), (10, 5.5), (11, 15), (3, 15)]))                         # the bottle
    c.rect(u(5), u(2.5), u(9.5) - u(5), u(5.5) - u(2.5))                           # the head
    c.rect(u(9.5), u(3), u(11.5) - u(9.5), W(s, 1.2, 1.8))                         # the nozzle
    c.line(P(s, [(9, 5.5), (11, 8)]), W(s, 1, 1.5))                                # the trigger
    for x, y in ((13.5, 1.5), (14.8, 3.5), (13.5, 5.5)): c.rect(u(x), u(y), W(s, 1, 1.5), W(s, 1, 1.5))   # the mist
    c.rect(u(4.5), u(9), u(9.8) - u(4.5), u(12) - u(9), v=0)                       # the label


@icon("coffin", "ctx5", "a coffin: the dead, throw a corpse over or through", ["ContextMenu_ThrowCorpseOverFence"])
def coffin(c, s):
    u = U(s)
    c.poly(P(s, [(5, 0.5), (11, 0.5), (13.5, 4.5), (11.5, 15.5), (4.5, 15.5), (2.5, 4.5)]))
    c.rect(u(7.25), u(3.5), u(8.75) - u(7.25), u(10) - u(3.5), v=0); c.rect(u(5.5), u(5.25), u(10.5) - u(5.5), u(6.75) - u(5.25), v=0)   # the cross


@icon("holster_left", "ctx5", "the pistol, an arrow left: wear it on the belt, left", ["Equip Belt Left"])
def holster_left(c, s):
    import i_gun
    i_gun._pistol(c, s); c.badge("left")


@icon("holster_right", "ctx5", "the pistol, an arrow right: wear it on the belt, right", ["Equip Belt Right"])
def holster_right(c, s):
    import i_gun
    i_gun._pistol(c, s); c.badge("right")
