"""The marks: color tells the two actions of a pair apart (design handoff, ZeDUI/HANDOFF_design_menu_marks_eat_20261109.md;
the director, Nov 9 2026: "I want color to distinguish the difference ... when there's an A action and a B action").

The icons stay ink; only the mark that tells a pair apart takes a color: a plus or minus, an in or out arrow, the strike
of an "off". The first of a pair (add, take, load, in, open, up, enter) is blue, the second (remove, put, drop, unload,
out, off, close, down, exit) is red. The shape still carries the meaning, so a player who can't see color loses nothing.
The colors live with the paper and ink in the game (ZeD.Ctx.markAdd / markRemove, Tokens.lua), not here.

MARKS: icon id -> "add" or "remove". What's marked is the icon's mark layer (kit.C.mark(): badges, strikes, and the
arrows marked by hand in i_row, i_gun, i_sym, i_world), except the WHOLE ones, where the glyph is the mark.
When it's unclear which is first (the director's call: the player's side decides), a plus or an in-arrow is blue and a
minus or an out-arrow red, except the container pair, where Take is blue and Put in red whatever way the arrow points.
A new pair follows the same rule.

Left ink on purpose: arrows that say where with no twin (hand_main, hand_off, holster*, tent_down, the figures'
arrows), pairs told apart by a changed shape (padlock / padlock_open, link / unlink), the window controls, emotes and
the check; the lists' own plus and minus (outfit_*, loadout_*), which aren't in the menu yet.
"""

ADD, REMOVE = "add", "remove"

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
}

WHOLE = {"plus", "minus", "move_up", "move_down"}       # the glyph is all mark


def mark_image(id_, size):
    """the icon's mark pixels (white on clear) at 16 or 24, or None"""
    import kit
    if id_ not in MARKS: return None
    if id_ in WHOLE: return kit.render(id_, size)
    return kit.render_mark(id_, size)


def check():
    """every marked icon exists and has mark pixels at both sizes; the mark is part of the icon, not all of it
    (unless WHOLE). Returns a list of problems."""
    import kit
    bad = []
    for id_, kind in MARKS.items():
        if kind not in (ADD, REMOVE): bad.append("%s: kind %r" % (id_, kind)); continue
        if id_ not in kit.ICONS: bad.append("%s: no such icon" % id_); continue
        for sz in (16, 24):
            m = mark_image(id_, sz)
            if m is None: bad.append("%s %d: no mark pixels" % (id_, sz)); continue
            full = kit.render(id_, sz).getchannel("A").tobytes()
            mk = m.getchannel("A").tobytes()
            if any(b and not a for a, b in zip(full, mk)): bad.append("%s %d: a mark pixel off the icon" % (id_, sz))
            if id_ not in WHOLE and mk == full: bad.append("%s %d: the mark is the whole icon" % (id_, sz))
    return bad


if __name__ == "__main__":
    import os
    import sys
    sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
    import allicons  # noqa: F401
    problems = check()
    for p in problems: print("FAIL", p)
    print("marks:", len(MARKS), "icons,", len(problems), "problems")
    sys.exit(1 if problems else 0)
