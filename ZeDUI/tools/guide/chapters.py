"""The survival guide's five ZeD chapters: one source for the English words (Translate/EN/UI.json) and the guide's data
(42/media/lua/client/ZeD/ZeD_GuideChapters.lua). Run: python chapters.py

Text tokens, filled in game from the player's own bindings and controller (ZeD_SurvivalGuide.lua, fillTokens):
  {bind:TOGGLE_INVENTORY}  a game binding by its KeybindId name: your key, in a key cap
  {key:Interact}           a game binding by its id string
  {pad:A}                  a controller button by ZeD's role (A B X Y LB RB LT RT LS RS DPAD DU DD DL DR SEL START)
  {mouse:0} {mouse:1}      the left / right mouse button, in the game's words
  {lit:Esc}                a key named as written
Two-ways rows: (mouse-and-keyboard text, controller text). ways_from: the game topics whose own two-ways rows a
page shows (their title keys), for game actions, so the buttons are the game's own.
Source of the words: ZeDUI/SURVIVAL_GUIDE_CHAPTERS.md (Build's draft for the director, Nov 4 2026).
"""
import json, os

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "..", ".."))
EN = os.path.join(ROOT, "42/media/lua/shared/Translate/EN/UI.json")
LUA = os.path.join(ROOT, "42/media/lua/client/ZeD/ZeD_GuideChapters.lua")

CH = [
 ("zed", "ZeD", "The screens of this computer, and how to work them.", [
  ("windows", "Two windows",
   "Everything you carry and everything around you sits in two windows. The Character window is you and your things: what you carry, what you wear, your health, your skills and your journal. The World window is the world and its things: the containers near you, the floor, crafting, building, your car and your maps. They open and close together.",
   [("{bind:TOGGLE_INVENTORY} opens both windows", "{pad:Y} opens or hides both"),
    ("Click a window to work in it", "{pad:LB} goes to Character, {pad:RB} to World"),
    ("{lit:Esc} or the close box closes them", "Hold {pad:Y} to close both")], None),
  ("moving", "Moving things",
   "Each open container is a column, side by side: your bag, the shelf, the floor. To move an item, drag it to another column. Pick several first to move them together. The band at the foot of the column says what will move and where.",
   [("Drag an item to another column", "{pad:A} on an item, then Move in its card"),
    ("Ctrl-click picks several, Shift-click a run", "Hold {pad:A} marks a row, Up or Down while held marks more"),
    ("Double-click uses an item", "Hold {pad:X} uses an item")], None),
  ("cards", "Item cards",
   "Click an item and its card opens beside the list: what it is, its condition, its weight and what you can do with it. Food shows a nutrition label. Cards also open for things in the world: generators, campfires, farm plots, troughs, padlocks and water. The card closes by itself when an action finishes.",
   [("Click an item to open its card", "{pad:A} on an item opens its card"),
    ("Click a button in the card", "Up goes to the card's buttons"),
    ("Click the item again to close it", "{pad:B} closes the card")], None),
  ("tabs", "The tabs",
   "The tabs along the top of each window open its pages. Character: Inventory, Equipment, Health, Thermal, Skills and Journal. World: the containers, Crafting, Building, Foraging, Furniture, Vehicle and Maps. A tab shows only when there is something on it.",
   [("Click a tab", "{pad:DPAD} to the tab, {pad:A} to open it")], None),
  ("belt", "The belt and your hands",
   "The belt runs along the foot of the screen. Your two hands sit at its left end, each with a ring that shows the condition of what it holds. The belt's slots hold what you can grab without opening a bag. A gun in your main hand adds a tab for its rounds.",
   None, None),
  ("menus", "Menus and the action bar",
   "Right-click something to see what you can do with it. The menu can be a strip of buttons or a list: choose in Options, ZeD setup. While your character works, the action bar over their head shows what they are doing and how long it has left, in words or in ten segments.",
   [("{mouse:1} for the menu", "{pad:X} for the menu"),
    ("{lit:Esc} or a click away closes it", "{pad:B} closes it")], None),
  ("pins", "Pins on the title bar",
   "Pin what you are watching to the Character window's title bar: a skill, the book you are reading, a bottle, a battery or a weapon's condition. It sits beside your health and weight, so you can watch it without opening a tab. Three at most; a fourth replaces the oldest.",
   [("{mouse:1}, then Pin to title bar", "{pad:X}, then Pin to title bar")], None),
  ("messages", "Messages",
   "Notes from the game and from other mods go into the Messages window instead of covering the screen, so a note you missed can be read later. The notes over your head are kept there too. Questions that need an answer still ask at once.",
   None, None),
  ("look", "Your look",
   "Every ZeD window has a window menu at its top left. It sets the theme (Dark, Light or High contrast), the accent colour, the text size, how see-through windows are, and the controller highlight. A window can keep its own accent.",
   None, None),
  ("setup", "ZeD setup, Full or Simple",
   "Options opens on ZeD setup. It holds every ZeD setting, with a Find box and a help line that explains the setting you point at. Many parts of ZeD come in two forms: Full, drawn as the thing itself (the watch on your wrist, the car's dashboard, the radio's face, this book), and Simple, the same controls as a plain ZeD panel. Choose each in the Full or simple group.",
   None, None),
  ("pad", "On a controller",
   "Every mouse action has a button: {pad:A} is a left click, {pad:X} a right click and {pad:B} backs out. With no window open, hold a direction on the D-pad for a wheel: Left for Character, Right for World, Up for Social, Down for Here and now. Point with the right stick and let go to take. Hold {pad:LB} or {pad:RB} and press another button for one of twelve quick actions you set in ZeD setup.",
   [("{mouse:0}", "{pad:A}"), ("{mouse:1}", "{pad:X}"), ("{lit:Esc}", "{pad:B}")], None),
 ]),
 ("firstdays", "First Days", "What keeps a new survivor alive through the first week.", [
  ("firsthour", "The first hour",
   "Crouch, close the curtains and look around before you do anything else. Zombies see you through windows and hear you through walls. A quiet house you have checked room by room is the safest place you will have for a while.",
   None, ["SurvivalGuide_sneak_fence_title", "SurvivalGuide_curtains_title"]),
  ("water", "Water before it stops",
   "The water will stop running and the power will go out, and nobody will tell you the day. Fill every bottle, pot and bucket you find while the taps still run. Later you will collect rain.",
   None, None),
  ("walk", "Walk, don't run",
   "Running tires you fast, and a tired survivor fights badly. Swinging, carrying and climbing also strain your arms and legs until you rest. Walk between houses and save running for when you need it.",
   None, ["SurvivalGuide_walkingrunning_title"]),
  ("door", "Fight at a door, never in the open",
   "One zombie at a time is a fight. Three at once is a death. Make them come to you through a door, a window or a gap in a fence, and push them over before you swing. If more come than you can take, leave.",
   None, ["SurvivalGuide_melee_attack_title", "SurvivalGuide_shove_title"]),
  ("bag", "A weapon and a bag",
   "Your first two finds should be something to hit with and something to carry in. Put the weapon in your main hand and the bag on your back. A two-handed weapon takes both hands.",
   None, ["SurvivalGuide_equip_primary_title"]),
  ("quiet", "Keep it quiet",
   "Guns, car alarms and house alarms bring every zombie in earshot. Smashing a car window can set off its alarm. If you fire a gun or trip an alarm in town, leave at once.",
   None, None),
  ("infection", "Two infections",
   "Your health panel can say a wound is infected. That is an ordinary infection from dirt, and a clean bandage and disinfectant cure it. The zombie infection is different, and the game never tells you that you have it. Any wound a zombie gives you can carry it: a bite always, a laceration or a scratch sometimes. Clean and bandage every wound, and watch for the signs.",
   None, ["SurvivalGuide_first_aid_title"]),
  ("food", "Food that keeps",
   "Fresh food goes stale and then rotten, and rotten food makes you sick. Eat the fresh things first and keep the cans for later. A fridge slows it down until the power goes.",
   None, None),
  ("learning", "Learning",
   "Skill books make you learn faster at what they teach, but only after you have read them and only at their levels. The TV teaches too, at set hours. Read in daylight or by a lamp.",
   None, None),
  ("where", "Where you are",
   "The map you start with shows only what you have seen. Maps you find fill it in. World window, Maps tab.",
   None, ["SurvivalGuide_map_title"]),
 ]),
 ("b41", "Coming from Build 41", "What changed, for survivors who learned the old ways.", [
  ("traits", "Traits and occupations",
   "Several traits and point costs changed, and some are gone: Lucky and Unlucky no longer exist. Do not copy an old build. Read the costs on the character screen.",
   None, None),
  ("crafting", "Crafting and building were rebuilt",
   "Crafting now happens at workstations, and many recipes must be learned first, from magazines or from your occupation. The World window's Crafting and Building tabs list what you know and what you need.",
   None, None),
  ("carpentry", "Carpentry",
   "Taking furniture apart no longer teaches Carpentry. Build things to learn it.",
   None, None),
  ("weapons", "Weapons wear two ways",
   "A weapon's head and its handle wear separately, and an edged weapon goes dull. Look after the one you rely on.",
   None, None),
  ("strain", "Muscle strain",
   "Swinging, carrying and climbing strain your arms and legs. Strained limbs hurt and work badly until you rest.",
   None, None),
  ("skills", "New skills",
   "Carving, Knapping, Pottery, Glassmaking, Masonry, Blacksmithing and Animal Care are new, and each has its own skill books.",
   None, None),
  ("world", "A bigger world",
   "The map is about twice the size, with new towns, basements and more buildings. Nights are darker.",
   None, None),
  ("foraging", "Foraging finds materials",
   "Foraging now turns up clay, flint and stone for the new crafts, as well as food.",
   None, None),
  ("animals", "Animals",
   "Farms keep animals now: chickens, cows, sheep, pigs and more. They need food, water and care.",
   None, None),
 ]),
 ("controls", "Your Controls", "Every key and button, read from your own settings.", [
  ("keys", "Your keys",
   "Every key the game uses, as you have set it. A key you have changed shows your key, not the default. Change them in Options, Controls.",
   "KEYS", None),
  ("pad", "Your controller",
   "ZeD's controller map: every mouse action has a button. In the world the game's own buttons work as before; the guide's other pages show them with each action.",
   [("{mouse:0}", "{pad:A}"), ("{mouse:1}", "{pad:X}"), ("{lit:Esc}", "{pad:B}"),
    ("{bind:TOGGLE_INVENTORY}", "{pad:Y} the two windows"),
    ("Click a window", "{pad:LB} Character, {pad:RB} World"),
    ("Arrow keys", "{pad:DPAD} moves between things")], None),
 ]),
 ("whatsnew", "What's New in ZeD", "The changes in this version.", [
  ("beta3", "This version",
   "The survival guide: this book or the plain window (Full or Simple in ZeD setup), with five new chapters, the game's rules as numbers and your own keys and buttons on every page. The Mods screen: mods that are on sit on a dark band and mods that are off dim, an Off tab, Hide incompatible, a Simple view and colour labels for folders and separators. The notes over your head in ZeD's bubble, kept in Messages. A hint strip for what is in front of you. Pins on the Character window's title bar.",
   None, None),
 ]),
]


def key(*parts):
    return "UI_ZeD_GCh_" + "_".join(parts)


def main():
    en = {}
    lua = ["-- ZeD-UI/42/media/lua/client/ZeD/ZeD_GuideChapters.lua",
           "-- GENERATED by ZeDUI/tools/guide/chapters.py: edit the words there, not here.",
           "-- The survival guide's five ZeD chapters after the game's own (the director, Nov 4 2026): each section's",
           "-- title and blurb keys, each topic's title and text keys, its two-ways rows (keys of the two sides), the game",
           "-- topics whose own rows it shows (ways_from), or KEYS (every key binding, read live).",
           "ZeD = ZeD or {}",
           "ZeD.GuideChapters = {"]
    for sid, stitle, blurb, topics in CH:
        en[key(sid, "Title")] = stitle
        en[key(sid, "Blurb")] = blurb
        lua.append('    { id = "%s", title = "%s", blurb = "%s", topics = {' % (sid, key(sid, "Title"), key(sid, "Blurb")))
        for tid, ttitle, text, ways, frm in topics:
            en[key(sid, tid, "Title")] = ttitle
            en[key(sid, tid, "Text")] = text
            parts = ['id = "%s"' % tid, 'title = "%s"' % key(sid, tid, "Title"), 'text = "%s"' % key(sid, tid, "Text")]
            if ways == "KEYS":
                parts.append("keys = true")
            elif ways:
                rows = []
                for i, (kb, pad) in enumerate(ways, 1):
                    en[key(sid, tid, "W%dK" % i)] = kb
                    en[key(sid, tid, "W%dP" % i)] = pad
                    rows.append('{ "%s", "%s" }' % (key(sid, tid, "W%dK" % i), key(sid, tid, "W%dP" % i)))
                parts.append("ways = { %s }" % ", ".join(rows))
            if frm:
                parts.append("waysFrom = { %s }" % ", ".join('"%s"' % f for f in frm))
            lua.append("        { %s }," % ", ".join(parts))
        lua.append("    } },")
    lua.append("}")
    lua.append("return ZeD.GuideChapters")
    open(LUA, "w", encoding="utf-8", newline="\n").write("\n".join(lua) + "\n")
    # the English words: added or updated in place
    raw = open(EN, encoding="utf-8-sig", newline="").read()
    nl = "\r\n" if "\r\n" in raw else "\n"
    cur = json.loads(raw)
    changed = 0
    for k, v in en.items():
        if k in cur and cur[k] != v:
            old = '"%s": %s' % (k, json.dumps(cur[k], ensure_ascii=False))
            assert raw.count(old) == 1, k
            raw = raw.replace(old, '"%s": %s' % (k, json.dumps(v, ensure_ascii=False)))
            changed += 1
    new = [(k, v) for k, v in en.items() if k not in cur]
    if new:
        body = raw.rstrip()
        assert body.endswith("}")
        body = body[:-1].rstrip()
        raw = body + "," + nl + ("," + nl).join('    "%s": %s' % (k, json.dumps(v, ensure_ascii=False)) for k, v in new) + nl + "}" + nl
    json.loads(raw)
    bom = open(EN, "rb").read(3) == b"\xef\xbb\xbf"
    open(EN, "w", encoding="utf-8-sig" if bom else "utf-8", newline="").write(raw)
    print("keys:", len(en), "new:", len(new), "changed:", changed)


if __name__ == "__main__":
    main()
