"""Review sheets for the right-click menu's icons, one group at a time (map.CTX), written to
ZeDUI/mockups/zed_menu_icons_v1/:
  review_g<N>_catalogue.png   every icon of the group: the menu's words it stands for (the game's English), today's
                              pictures, the new 16 (paper, 5x) and 24 (accent, 4x), both at 1x; taken-from-the-wheels
                              icons marked
  review_g<N>_strips.png      a few menus as ZeD's strip shows them, today and new, at 1x (doubled) and 1.75x
Run: python review_ctx.py 1"""
import json
import os
import re
import sys

from PIL import Image, ImageDraw

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import allicons  # noqa: F401
import kit
import map as M
from kit import render
from review import cell, PAPER, ACC
from review_row import sans, font, tinted, drawing_for, old_for, P, BG, LABEL, HEAD

ROOT = os.path.normpath(os.path.join(HERE, "..", "..", ".."))
OUT = os.path.join(ROOT, "ZeDUI", "mockups", "zed_menu_icons_v1")
CTX_LUA = os.path.join(ROOT, "42", "media", "lua", "shared", "ZeD", "ContextIcons.lua")
GAME_EN = "E:/Project Zomboid/SteamApps/common/ProjectZomboid/media/lua/shared/Translate/EN"
os.makedirs(OUT, exist_ok=True)

# the strips: a few menus the group's icons show up in (label, [(words, licensed picture)])
STRIPS = {
    1: [
        ("Right-click a thing in your bag", ["ContextMenu_Equip", "ContextMenu_Unequip", "Drop", "Rename", "Favorite",
                                             "Protect from Craft", "Mark Unwanted", "Examine", "Open", "Combine"]),
        ("Sleeping, resting, getting over things", ["Sleep", "Rest", "Sleep on Ground", "Sleep on Ground with Pillow",
                                                     "Sleep in Tent", "Take Down Tent", "Climb over", "Climb through",
                                                     "Climb Sheet Rope", "Exercise"]),
        ("Washing, grooming and clothes", ["Wash", "Wash Hands", "Wash Clothing", "ContextMenu_Dry_myself",
                                           "ContextMenu_TrimBeard", "ContextMenu_UntieHair", "IGUI_MakeUp",
                                           "ContextMenu_UpHoodie", "ContextMenu_ForwardCap", "ContextMenu_CoverFace",
                                           "ContextMenu_Scarf", "Rip Sheets"]),
        ("Reading, habits, your things", ["Read", "Read Map", "Write Journal", "Tear Out Page", "ContextMenu_Smoke",
                                          "ContextMenu_Chew", "ContextMenu_Sniff", "Put In", "Take Out", "Transfer All",
                                          "Lock", "Unlock"]),
    ],
    2: [
        ("Cooking: what a dish can become", ["Soup", "Stew", "Pie", "Cake", "Stir-fry", "Sandwich", "Burger", "Salad",
                                            "Pasta", "Rice", "Omelette", "Beef Stew"]),
        ("More dishes", ["Hotdog", "Taco", "Burrito", "Waffles", "Pancakes", "Bread", "Toast", "Pizza", "Fried Eggs",
                         "Kebab", "Cookies", "Ice Cream"]),
        ("Adding to a dish, preparing it", ["Add Salt", "Add Sugar", "Add Oil", "Add Butter", "Add Milk", "Add Cheese",
                                            "Add Sauce", "Add Honey", "Add Ingredient", "Chop", "Grate", "Grind", "Mix", "Stir"]),
        ("The food types", ["ContextMenu_FoodType_Meat", "ContextMenu_FoodType_Beef", "ContextMenu_FoodType_Poultry",
                            "ContextMenu_FoodType_Seafood", "ContextMenu_FoodType_Fruits", "ContextMenu_FoodType_Vegetable",
                            "ContextMenu_FoodType_Berry", "ContextMenu_FoodType_Nut", "ContextMenu_FoodType_Mushroom",
                            "ContextMenu_FoodType_Bean", "ContextMenu_FoodType_Candy", "ContextMenu_FoodType_Chocolate",
                            "ContextMenu_FoodType_CatFood", "ContextMenu_FoodType_Herb", "Open Can", "Eat"]),
    ],
    3: [
        ("Drinking and brewing", ["Drink", "Brew Tea", "Brew Coffee", "Make Juice", "Make Cocktail", "Blend",
                                  "Brew Beer", "Make Wine", "Ferment", "Distill"]),
        ("Water and pouring", ["Pour", "Fill", "Empty", "Transfer", "Siphon", "Collect Rain", "Filter Water",
                               "Pour Water", "Fill Water Bottle", "ContextMenu_Water"]),
        ("The fluid containers", ["Fluid_Container_Bottle", "Fluid_Container_Cup", "Fluid_Container_Glass",
                                  "Fluid_Container_Goblet", "Fluid_Container_Kettle", "Fluid_Container_WateringCan",
                                  "ContextMenu_Metal_Drum", "Fluid_Container_Well", "Fluid_Container_Bathtub",
                                  "Fluid_Container_WhiteToilet", "Fluid_Container_Flask"]),
        ("The fluid card's words", ["Fluid_Empty", "Fluid_HoldingOneType", "Fluid_Swap", "Fluid_Unknown", "Fluid_Capacity",
                                    "Fluid_Tainted", "Fluid_Poison", "Fluid_Prop_Stress", "Fluid_Prop_Unhappy",
                                    "Fluid_Prop_Calories", "Fluid_Name_Blood"]),
    ],
    4: [
        ("Building and repairing", ["Build", "Barricade", "Disassemble", "Craft", "Repair", "Upgrade", "Reinforce",
                                    "Install", "Uninstall", "Place", "Pick up", "Rotate", "Remove"]),
        ("Tools, paint and cloth", ["Saw", "Nail", "Weld", "Cut", "Crush", "Apply", "Dye", "ContextMenu_Plaster", "Knit",
                                    "Weave", "Sew"]),
        ("Fire and heat", ["Light Fire", "Add Fuel", "Tend Fire", "Extinguish", "ContextMenu_Fireplace",
                           "ContextMenu_Stone_Furnace", "ContextMenu_Clear_Ashes"]),
        ("The house, furniture, signs", ["ContextMenu_Traversable", "ContextMenu_Stairs", "ContextMenu_Open_curtains",
                                         "ContextMenu_Door", "ContextMenu_Windows_Frame", "ContextMenu_Fence", "ContextMenu_Wall",
                                         "ContextMenu_Floor", "Wooden", "ContextMenu_Furniture", "ContextMenu_Table",
                                         "ContextMenu_Bookcase", "ContextMenu_Shelves", "ContextMenu_SmallLocker",
                                         "ContextMenu_Tombstone", "ContextMenu_SignRightArrow", "ContextMenu_SignUpArrow"]),
    ],
    5: [
        ("Fighting", ["Attack", "Aim", "Shove", "Stomp", "Smash", "ContextMenu_Equip", "Equip Primary", "Equip Secondary",
                      "Equip Back", "Equip Belt Left", "Equip Belt Right", "Holster"]),
        ("Weapons and ammunition", ["Reload", "Unload", "Rack", "Attach Weapon Mod", "Detach Weapon Mod", "Attach Scope",
                                    "Attach Suppressor", "Attach Bayonet", "Clean Gun", "Check Ammo", "ContextMenu_Magazine",
                                    "ContextMenu_EjectMagazine", "ContextMenu_NoBullets"]),
        ("Treating wounds", ["Bandage", "Apply Bandage", "Remove Bandage", "Apply Splint", "Apply Tourniquet",
                             "Apply Ointment", "Suture", "Disinfect", "Cauterize", "Extract Bullet"]),
        ("Medicine and checks", ["Take Medication", "Apply Eye Drops", "Take Pulse", "Check Temperature", "Give CPR",
                                 "ContextMenu_Medical_Check", "ContextMenu_ThrowCorpseOverFence", "ContextMenu_EyeRight",
                                 "ContextMenu_LeftMiddleFinger"]),
    ],
    6: [
        ("Vehicles", ["Enter Vehicle", "Exit Vehicle", "Hotwire", "Repair Vehicle", "Refuel", "Change Tire", "Check Engine",
                      "Open Trunk", "Install Part", "ContextMenu_RemoveBurntVehicle", "ContextMenu_VehicleShutOff",
                      "ContextMenu_VehicleHorn", "ContextMenu_VehicleLightbar", "ContextMenu_CarBatteryCharger"]),
        ("Power and electrics", ["Use Generator", "Wire Generator", "ContextMenu_GeneratorUnplug", "Fix Wiring", "Install Light",
                                 "Remove Light", "Turn Off", "Connect Pipe", "Tune Radio", "Set Alarm", "ContextMenu_StopAlarm"]),
        ("Farming and animals", ["Plant", "Harvest", "Till Soil", "Fertilize", "Prune", "ContextMenu_Sow_Seed",
                                 "ContextMenu_ScytheGrass", "Collect Feathers", "Set Trap", "ContextMenu_Fishing",
                                 "ContextMenu_Lure", "ContextMenu_Hutch", "ContextMenu_AnimalGenome", "ContextMenu_PetAnimal",
                                 "ContextMenu_FoodType_Insect"]),
        ("The safehouse, and the rest", ["ContextMenu_Team_up", "ContextMenu_Follow_me", "ContextMenu_WarClaim",
                                         "ContextMenu_ViewSafehouse", "ContextMenu_SafehouseRelease", "ContextMenu_Info",
                                         "ContextMenu_PartInfo", "ContextMenu_Fuel_Full", "ContextMenu_More", "ContextMenu_All",
                                         "ContextMenu_One", "ContextMenu_Uses", "ContextMenu_Delete", "ContextMenu_RecentlyRead",
                                         "Muffin"]),
    ],
}


def english():
    words = {}
    try:
        for f in os.listdir(GAME_EN):
            if f.endswith(".json"):
                try:
                    with open(os.path.join(GAME_EN, f), encoding="utf-8") as h: words.update(json.load(h))
                except Exception:
                    pass
    except OSError:
        pass
    return words


EN = english()


def say(key):
    if key in EN: return EN[key]
    if key.startswith("Base."): return key[5:]
    for pre in ("ContextMenu_", "IGUI_", "Fluid_Name_", "Fluid_Container_", "Fluid_Prop_", "Fluid_"):
        if key.startswith(pre): return key[len(pre):].replace("_", " ")
    return key


def entries():
    """the menu's entries: [(name, licensed picture)] in file order"""
    t = open(CTX_LUA, encoding="utf-8").read()
    body = t[:t.index("ZeD.ContextIconKeys =")]
    return [(m.group(1), m.group(2)) for m in re.finditer(r'\["(.*?)"\]\s*=\s*"([^"]+)"', body)]


def group_rows(g):
    rows = [(lic, id_) for gg, lic, id_ in M.CTX if gg == g]
    byid = {}
    for lic, id_ in rows: byid.setdefault(id_, []).append(lic)
    words = {}
    for name, lic in entries():
        for id_, lics in byid.items():
            if lic in lics: words.setdefault(id_, []).append(say(name))
    module = "i_ctx%d" % g
    new = [i for i in byid if kit.ICONS[i]["fn"].__module__ == module]
    old = [i for i in byid if i not in new]
    return new + old, byid, words, set(new)


def catalogue(g):
    ids, byid, words, new = group_rows(g)
    lf, hf, sf = sans(16), sans(20), sans(13)
    rowh = 33 * 4 + 26
    per = 2
    colw = 1150
    rows = (len(ids) + per - 1) // per
    W, H = per * colw + 30, 100 + rows * rowh
    s = Image.new("RGBA", (W, H), BG + (255,)); d = ImageDraw.Draw(s)
    d.text((24, 16), f"The right-click menu, group {g}: today's pictures, then the new drawings (16 on paper at 5x, 24 on the accent at 4x, both at 1x)", fill=LABEL, font=hf)
    d.text((24, 48), f"{len(new)} new drawings first, then {len(ids) - len(new)} taken from the wheels and the container row as they are (orange name).", fill=(170, 170, 160), font=sf)
    for n, id_ in enumerate(ids):
        x0 = 24 + (n % per) * colw; y = 84 + (n // per) * rowh
        a = cell(render(id_, 16), 22, PAPER); b = cell(render(id_, 24), 33, ACC)
        s.alpha_composite(a.resize((a.width * 5, a.height * 5), Image.NEAREST), (x0, y + 8))
        s.alpha_composite(b.resize((b.width * 4, b.height * 4), Image.NEAREST), (x0 + 22 * 5 + 18, y))
        xs = x0 + 22 * 5 + 33 * 4 + 36
        s.alpha_composite(a, (xs, y + 10)); s.alpha_composite(b, (xs + 30, y + 4))
        tx = xs + 80
        d.text((tx, y + 2), id_ + ("" if id_ in new else "  (from the wheels / the row)"), fill=(170, 170, 160) if id_ in new else HEAD, font=lf)
        ox = tx
        for lic in byid[id_][:6]:
            try:
                im = Image.open(os.path.join(ROOT, "42", "media", "textures", "ZeD", "icons", lic + ".png")).convert("RGBA")
                im.thumbnail((40, 40), Image.LANCZOS)
                s.alpha_composite(tinted(im, (200, 200, 190)), (ox, y + 30)); ox += 48
            except OSError:
                pass
        d.text((ox + 6, y + 40), "today", fill=(140, 140, 130), font=sf)
        ws = words.get(id_, [])
        line, lines = "", []
        for w_ in ws:
            add = (", " if line else "") + w_
            if len(line + add) > 70: lines.append(line); line = w_
            else: line += add
        if line: lines.append(line)
        if len(lines) > 3: lines = lines[:3]; lines[-1] += " ..."
        for i, ln in enumerate(lines): d.text((tx, y + 80 + i * 18), ln, fill=LABEL, font=sf)
    s.save(os.path.join(OUT, f"review_g{g}_catalogue.png"))


def strip(items, sc, today):
    """ZeD's context strip: a row of 22-unit paper cells with an ink edge, the icon in its 16-unit box"""
    cw = P(22, sc); gap = P(3, sc); box = P(16, sc)
    ink = (20, 20, 20, 255); paper = (242, 242, 242, 255)
    W = len(items) * (cw + gap) + gap
    im = Image.new("RGBA", (W, cw + 2 * gap), (84, 92, 60, 255))
    d = ImageDraw.Draw(im)
    hair = max(1, P(1, sc))
    for i, (lic, id_) in enumerate(items):
        x = gap + i * (cw + gap); y = gap
        d.rectangle([x + 2 * hair, y + 2 * hair, x + cw + hair, y + cw + hair], fill=(0, 0, 0, 255))
        d.rectangle([x, y, x + cw - 1, y + cw - 1], fill=ink)
        d.rectangle([x + hair, y + hair, x + cw - 1 - hair, y + cw - 1 - hair], fill=paper)
        if today:
            try: pic = old_for(lic, box)
            except OSError: pic = None
        else: pic = drawing_for(id_, box)
        if pic is not None:
            im.alpha_composite(tinted(pic, (20, 20, 20)), (x + (cw - pic.width) // 2, y + (cw - pic.height) // 2))
    return im


def strips(g):
    lic_of = dict(entries())
    id_of = {lic: id_ for _, lic, id_ in M.CTX}
    lf, hf, sf = sans(15), sans(19), sans(13)
    blocks = []
    for title, names in STRIPS.get(g, []):
        items = [(lic_of.get(n), id_of.get(lic_of.get(n))) for n in names]
        items = [(l, i) for l, i in items if l and i]
        label = ", ".join(say(n) for n in names if lic_of.get(n))
        out = []
        for sc, z in ((1.0, 2), (1.75, 1)):
            a, b = strip(items, sc, True), strip(items, sc, False)
            if z > 1: a = a.resize((a.width * z, a.height * z), Image.NEAREST); b = b.resize((b.width * z, b.height * z), Image.NEAREST)
            out.append((sc, a, b))
        blocks.append((title, label, out))
    W = 24 + max(max(a.width, b.width) for _, _, o in blocks for _, a, b in o) + 160
    H = 70 + sum(60 + sum(max(a.height, b.height) * 2 + 40 for _, a, b in o) for _, _, o in blocks)
    s = Image.new("RGBA", (W, H), BG + (255,)); d = ImageDraw.Draw(s)
    d.text((24, 16), f"The right-click menu, group {g}: a few menus as ZeD's strip shows them, today and new", fill=LABEL, font=hf)
    y = 60
    for title, label, out in blocks:
        d.text((24, y), title, fill=HEAD, font=hf); y += 26
        d.text((24, y), label, fill=(170, 170, 160), font=sf); y += 30
        for sc, a, b in out:
            d.text((24, y + 6), f"{sc:g}x today", fill=LABEL, font=sf); s.alpha_composite(a, (130, y)); y += a.height + 8
            d.text((24, y + 6), f"{sc:g}x new", fill=LABEL, font=sf); s.alpha_composite(b, (130, y)); y += b.height + 24
        y += 10
    s.crop((0, 0, W, y + 10)).save(os.path.join(OUT, f"review_g{g}_strips.png"))


if __name__ == "__main__":
    g = int(sys.argv[1]) if len(sys.argv) > 1 else 1
    catalogue(g); strips(g)
    print("sheets in", OUT)
