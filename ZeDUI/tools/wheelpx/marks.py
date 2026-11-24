"""The marks: color tells the two actions of a pair apart (design handoff, ZeDUI/HANDOFF_design_menu_marks_eat_20261109.md;
the director, Nov 9 2026: "I want color to distinguish the difference ... when there's an A action and a B action").

The icons stay ink; only the mark that tells a pair apart takes a color: a plus or minus, an in or out arrow, the strike
of an "off". The first of a pair (add, take, load, in, open, up, enter) is blue, the second (remove, put, drop, unload,
out, off, close, down, exit) is red. The shape still carries the meaning, so a player who can't see color loses nothing.
The colors live with the paper and ink in the game (ZeD.Ctx.markBlue / markGold / markRed, Tokens.lua), not here.

Three accents from round 1b (the director's redrawn icons, Nov 16 2026; i_r1.py): blue (water and cold; the giving side
of a pair), red (harm and danger; the taking-away side) and gold (energy and value: fire, light, power, favorite, kept).
The pairs' old kinds read on: add is blue, remove is red. The r_ icons take their kind from i_r1.ACCENT. HOLES (i_r1):
the accent fills what the base cuts out (the medkit's cross), so export.py writes the base without the mark's pixels and
a pointed cell, drawn in one tint, shows the hole.

MARKS: icon id -> "blue", "red" or "gold". What's marked is the icon's mark layer (kit.C.mark(): badges, strikes, and the
arrows marked by hand in i_row, i_gun, i_sym, i_world), except the WHOLE ones, where the glyph is the mark.
When it's unclear which is first (the director's call: the player's side decides), a plus or an in-arrow is blue and a
minus or an out-arrow red, except the container pair, where Take is blue and Put in red whatever way the arrow points.
A new pair follows the same rule.

Left ink on purpose: arrows that say where with no twin (holster*, tent_down, the figures' arrows), pairs told apart by a changed shape (padlock / padlock_open, link / unlink), the window controls, emotes and
the check.
"""

BLUE, RED, GOLD = "blue", "red", "gold"
KINDS = (BLUE, RED, GOLD)
ADD, REMOVE = BLUE, RED                                 # (the pairs' kinds before round 1b: add blue, remove red)

MARKS = {
    # add and remove
    "plus": ADD, "minus": REMOVE,                       # (the whole glyph: every "Add ..." / "Remove ..." row)
    "equip": ADD, "unequip": REMOVE,
    # the container pair: Take blue, Put in red. In the game tray_in (the arrow down into the tray) is Take, Take Out
    # and Loot all; tray_out (the arrow up out of it) is Put In and Transfer all (map.py CTX, ContextIcons.lua). The
    # handoff's table has the two ids the other way round; its rule ("Take is blue and Put in is red whatever way
    # the arrow points") is what's followed here.
    "tray_in": ADD, "tray_out": REMOVE,
    "mag_in": ADD, "rounds_in": ADD, "mag_out": REMOVE, "rounds_out": REMOVE,
    "battery_in": ADD, "battery_out": REMOVE,
    "fill": ADD, "empty": REMOVE,
    "safehouse_claim": ADD, "safehouse_release": REMOVE,
    "to_floor": REMOVE,                                 # (the arrow; the floor dots stay ink)
    "bandage_off": REMOVE, "unplug": REMOVE, "bulb_remove": REMOVE,
    "trash": REMOVE,                                    # (Dispose: the lid)
    # on and off: the "off" twin's strike or x goes red; the "on" has no mark, except autowalk's arrow
    "alarm_off": REMOVE, "ammo_off": REMOVE, "bulb_off": REMOVE, "craft_off": REMOVE, "eye_off": REMOVE,
    "headlight_off": REMOVE, "hotwire_off": REMOVE, "key_off": REMOVE, "magnifier_off": REMOVE, "star_off": REMOVE,
    "target_off": REMOVE, "sit_ground_off": REMOVE, "sneak_off": REMOVE, "autowalk_off": REMOVE,
    "autowalk": ADD,
    # either way: the arrow or badge that tells them apart
    "car_enter": ADD, "car_exit": REMOVE,
    "window_open": ADD, "window_close": REMOVE,
    "zoom_in": ADD, "zoom_out": REMOVE,
    "move_up": ADD, "move_down": REMOVE,
    "box_up": ADD, "box_down": REMOVE,
    # (the lists' own pair, outfit_add / outfit_remove and loadout_add / loadout_remove, went with the add-on
    # ZeD-GUI: Loadouts in 1.0: it colors them with ZeD.PxIcon.addMark and draws them with tools/wheelpx/export_lists.py)
    # Equip Primary / Equip Secondary: the which-hand arrow goes blue in the menus, so the row reads as the add side of
    # Equip / Unequip beside Unequip's red minus (the director, Nov 10 2026, after QA's Mac run; the handoff had kept
    # them ink as arrows that say where). Only the menus color marks: the belt's hands stay ink.
    "hand_main": ADD, "hand_off": ADD,
}
# round 1b (Nov 16 2026): the redrawn icons, each with its one accent
import i_r1 as _R1                                      # noqa: E402
MARKS.update(_R1.ACCENT)
HOLES = set(_R1.HOLES)

WHOLE = {"plus", "minus", "move_up", "move_down", "r_favorite"}   # the glyph is all mark

# STRIP (Icon color, the director, Nov 22 2026: "Let's give the header and footer icons a little taste of color, just
# like we did for context menus."): the inventory lists' heading and footer band icons that have no mark in the menus,
# with the menus' palette and meanings. Kept apart from MARKS so the right-click menu and the wheels, which draw these
# icons too (Filter water, Light fire, the vehicle's padlock, the cog), stay as signed off; only the strips color them.
# export.py writes their zw_<id>_mk.png beside the menus' and the table ZeD.PxIconStripMark. A strip button may name
# another kind for its own side (Same type: Take blue in the World window, Put in red in the Character window).
# The strips' icons already in MARKS keep their menu marks there: tray_in, tray_out, to_floor, trash.
STRIP = {
    "filter": BLUE,          # the drop under the funnel: what comes through
    "view_list": BLUE,       # the bullets: the view on show
    "view_grid": BLUE,       # the first tile: the view on show
    "same_type": BLUE,       # the front sheet: Take (World); the Character window's Put in draws it red
    "same_nearby": RED,      # the arrows out to every container nearby: Put in
    "power": GOLD,           # the stem: power
    "match": GOLD,           # the flame: fire
    "campfire": GOLD,        # the flame: fire (Add fuel)
    "gears": GOLD,           # the hub: a stove's or a machine's settings (heat, power)
    "extinguisher": RED,     # the hose and horn: put out, off
    "padlock": GOLD,         # the shackle: kept (lock the trunk)
}
# STRIP_MORE: a strip icon's further marks, each in a color of its own: id -> the kinds of mark layers 2, 3, ...
# (kit.C.mark(n)), exported as zw_<id>_mk<n>.png. The director, Nov 22 2026, of the Filter: its top bar split down
# the middle, "blue on the left-hand side, red on the right-hand side. So when those two pass through the filter
# cone, only blue comes out." (Mark 1: the bar's left half and the drop, blue; mark 2: the bar's right half, red.)
STRIP_MORE = {
    "filter": [RED],
}


def strip_kinds(id_):
    """a strip icon's mark kinds, layer 1 first: [kind] or [kind, kind2, ...]"""
    return [STRIP[id_]] + list(STRIP_MORE.get(id_, []))


def mark_image(id_, size, n=1):
    """the icon's mark pixels (white on clear) at 16 or 24, or None; n: the mark layer (STRIP_MORE's are 2, 3, ...)"""
    import kit
    if id_ not in MARKS and id_ not in STRIP: return None
    if n > 1 and n - 1 > len(STRIP_MORE.get(id_, [])): return None
    if id_ in WHOLE: return kit.render(id_, size)
    return kit.render_mark(id_, size, n)


def base_image(id_, size):
    """the icon as exported: the whole drawing, or for a HOLES icon the drawing without its mark (the cut-out the
    accent fills at rest)"""
    import kit
    from PIL import ImageChops
    im = kit.render(id_, size)
    if id_ not in HOLES: return im
    m = mark_image(id_, size)
    if m is None: return im
    im.putalpha(ImageChops.subtract(im.getchannel("A"), m.getchannel("A")))
    return im


def check():
    """every marked icon exists and has mark pixels at both sizes; the mark is part of the icon, not all of it
    (unless WHOLE). Returns a list of problems."""
    import kit
    bad = []
    both = dict(STRIP); both.update(MARKS)
    for id_ in STRIP:
        if id_ in MARKS: bad.append("%s: in MARKS and STRIP" % id_)
    for id_, more in STRIP_MORE.items():
        if id_ not in STRIP: bad.append("%s: in STRIP_MORE, not STRIP" % id_); continue
        for k, kind in enumerate(more):
            if kind not in KINDS: bad.append("%s mark %d: kind %r" % (id_, k + 2, kind))
            for sz in (16, 24):
                m = mark_image(id_, sz, k + 2)
                if m is None: bad.append("%s %d: no pixels on mark %d" % (id_, sz, k + 2)); continue
                # the layers never share a pixel (each pixel one color)
                for j in range(1, k + 2):
                    o = mark_image(id_, sz, j)
                    if o is not None and any(a and b for a, b in zip(m.getchannel("A").tobytes(), o.getchannel("A").tobytes())):
                        bad.append("%s %d: marks %d and %d overlap" % (id_, sz, j, k + 2))
    for id_, kind in both.items():
        if kind not in KINDS: bad.append("%s: kind %r" % (id_, kind)); continue
        if id_ not in kit.ICONS: bad.append("%s: no such icon" % id_); continue
        for sz in (16, 24):
            m = mark_image(id_, sz)
            if m is None: bad.append("%s %d: no mark pixels" % (id_, sz)); continue
            full = kit.render(id_, sz).getchannel("A").tobytes()
            mk = m.getchannel("A").tobytes()
            if any(b and not a for a, b in zip(full, mk)): bad.append("%s %d: a mark pixel off the icon" % (id_, sz))
            if id_ not in WHOLE and mk == full: bad.append("%s %d: the mark is the whole icon" % (id_, sz))
            if id_ in HOLES and not base_image(id_, sz).getchannel("A").getbbox(): bad.append("%s %d: nothing left round the hole" % (id_, sz))
    return bad


if __name__ == "__main__":
    import os
    import sys
    sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
    import allicons  # noqa: F401
    problems = check()
    for p in problems: print("FAIL", p)
    print("marks:", len(MARKS), "icons,", len(STRIP), "strip icons,", len(problems), "problems")
    sys.exit(1 if problems else 0)
