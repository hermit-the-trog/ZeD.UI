#!/usr/bin/env python3
"""
rekey_icons.py - give ZeD's context menu icons and groups vanilla translation keys.

Why: ContextIcons.lua matches options to icons by their English wording
("Walk to", "Sit on ground"). In any other language the option reads
differently and finds no icon, and the category keywords ("Eat", "Open")
miss too. Vanilla already ships every one of those words as a translation
key (ContextMenu_Walk_to, ...), in all of its languages. This script finds,
for every English display name in ContextIcons.lua, the vanilla keys whose
English text is that name, and writes them into two generated blocks at the
bottom of ContextIcons.lua:

  ZeD.ContextIconKeys      one row per English name: { "Walk to", "ContextMenu_Walk_to", ... }
  ZeD.ContextIconVerbKeys  one row per one-word name with every context-menu key that
                           starts with it: { "Open", "ContextMenu_Open_door", ... }
  ZeD.ContextCategoryKeys  one row per category keyword read from
                           ContextMenuRegistry.lua: { "Eat", "ContextMenu_Eat" }

At load, ContextMenuRegistry.lua turns each key into the active language with
getText(key) and builds its lookup from that. The English names in the main
table stay as the fallback for options that mods add without keys.

The main ZeD.ContextIcons table is never touched (it stays the single place
where an icon is assigned). Only the block between the two marker lines at
the bottom of ContextIcons.lua is rewritten, so the script can be re-run any
time (after a game update, or after adding icons) and gives the same result.

Usage:
  py rekey_icons.py                 rewrite the generated blocks
  py rekey_icons.py --dry-run       report only, write nothing
  py rekey_icons.py --report FILE   also save the English-only list as text
  py rekey_icons.py --game DIR      game media/lua/shared/Translate/EN folder
"""
import argparse
import glob
import json
import os
import re
import sys
from collections import defaultdict

HERE = os.path.dirname(os.path.abspath(__file__))
MOD = os.path.abspath(os.path.join(HERE, "..", "..", ".."))
ICONS_LUA = os.path.join(MOD, "42", "media", "lua", "shared", "ZeD", "ContextIcons.lua")
REGISTRY_LUA = os.path.join(MOD, "42", "media", "lua", "client", "ZeD", "ContextMenuRegistry.lua")
GAME_EN = "E:/Project Zomboid/steamapps/common/ProjectZomboid/media/lua/shared/Translate/EN"

BEGIN = "-- BEGIN GENERATED KEYS (rekey_icons.py) - do not edit by hand"
END = "-- END GENERATED KEYS"

# Vanilla files whose keys getText can resolve, and the key prefix each uses.
# Priority is the order of this list: a ContextMenu key beats an IGUI key.
PREFIX_PRIORITY = ["ContextMenu_", "IGUI_", "Fluid_", "Farming_"]
SOURCE_FILES = ["ContextMenu.json", "IG_UI.json", "Fluids.json", "Farming.json"]

# Keys that share a word with a context option but belong to editors, debug
# panels, animal naming and similar. They would only add noise to the map.
DENY = [
    "DebugMenu", "Editor", "PetName", "ContainerTitle", "Photo_", "AnimalType",
    "Animal_Group", "MigrationGroup", "IntensityEvents", "Emote_", "TicketUI",
    "TradingUI", "WarManager", "RolesList", "PlayerStats", "SurvivorSurname",
    "DailyValues", "BannedIPs", "Controller_", "IGUI_Map_", "Challenge_", "ServerSetting", "optionscreen", "MiniScoreboard",
]

MAX_KEYS_PER_NAME = 8      # a name shared by many recipe keys (Omelette...) keeps the best 8
MAX_KEYS_PER_KEYWORD = 3   # category keywords need only the best few

# A category keyword with no key of its own may take the first word of a key
# whose English text starts with it ("Climb" from "Climb over"). Listed
# explicitly so each choice is a decision, not a guess.
KEYWORD_FIRST_WORD = {
    "Refill": ["ContextMenu_RefillContainer"],
    "Extinguish": ["ContextMenu_ExtinguishFire"],
    "Unlock": ["ContextMenu_UnlockDoor"],
    "Lock": ["ContextMenu_LockDoor"],
    "Open": ["ContextMenu_Open_door"],
    "Close": ["ContextMenu_Close_door"],
    "Climb": ["ContextMenu_Climb_over"],
    "Sit": ["ContextMenu_SitGround"],
    "Cut": ["ContextMenu_CutHair"],
    "Equip": ["ContextMenu_Equip_Primary"],
    "Give": ["ContextMenu_WaterAnimal"],
}

# Item names (ItemName.json, keys like "Base.Sausage") are read in game with
# getItemNameFromFullType. They rank last, and a few that mean something else
# as an option name are left out.
ITEM_FILE = "ItemName.json"
ITEM_KEY_RE = re.compile(r"^[A-Za-z]+\.[A-Za-z0-9_]+$")
ITEM_DENY = {"Base.Dice"}
MAX_ITEM_KEYS_PER_NAME = 2


def load_en(game_dir):
    texts = {}
    for name in SOURCE_FILES:
        path = os.path.join(game_dir, name)
        with open(path, encoding="utf-8") as fh:
            for k, v in json.load(fh).items():
                if isinstance(v, str):
                    texts[k] = v
    return texts


def load_items(game_dir):
    items = {}
    with open(os.path.join(game_dir, ITEM_FILE), encoding="utf-8") as fh:
        for k, v in json.load(fh).items():
            if isinstance(v, str) and ITEM_KEY_RE.match(k) and k not in ITEM_DENY:
                items[k] = v
    return items


def allowed(key):
    if not any(key.startswith(p) for p in PREFIX_PRIORITY):
        return False
    return not any(bad in key for bad in DENY)


def key_rank(key):
    for i, p in enumerate(PREFIX_PRIORITY):
        if key.startswith(p):
            return i
    return len(PREFIX_PRIORITY)


KEYED_RE = re.compile(r"^(ContextMenu_|IGUI_|Fluid_|Farming_)")


def parse_icons(src):
    """Return (ordered [(name, icon)], set of explicit keys) from the main table only."""
    head = src.split(BEGIN)[0]
    rows = re.findall(r'^\s*\["([^"]+)"\]\s*=\s*"([^"]+)"', head, re.M)
    names, keys = [], set()
    for k, icon in rows:
        if KEYED_RE.match(k):
            keys.add(k)
        else:
            names.append((k, icon))
    return names, keys


def parse_keywords(src):
    return re.findall(r'^\s*\{\s*"([^"]+)"\s*,\s*"(?:USE|ACTION|CRAFT|EQUIP|TRANSFER|INFO|ADMIN)"\s*\}', src, re.M)


def lua_str(s):
    return '"' + s.replace("\\", "\\\\").replace('"', '\\"') + '"'


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--dry-run", action="store_true")
    ap.add_argument("--report", default=None)
    ap.add_argument("--game", default=GAME_EN)
    args = ap.parse_args()

    texts = load_en(args.game)
    items = load_items(args.game)
    items_by_text = defaultdict(list)
    items_by_text_ci = defaultdict(list)
    for k, v in items.items():
        items_by_text[v].append(k)
        items_by_text_ci[v.lower()].append(k)
    by_text = defaultdict(list)
    by_text_ci = defaultdict(list)
    for k, v in texts.items():
        if not allowed(k):
            continue
        by_text[v].append(k)
        by_text_ci[v.lower()].append(k)

    with open(ICONS_LUA, encoding="utf-8", newline="") as fh:
        src = fh.read()
    names, explicit_keys = parse_icons(src)

    claimed = set(explicit_keys)   # a key already assigned in the main table keeps its own icon
    rows = []                      # (name, [keys])
    english_only = []
    covered = []                   # names whose vanilla keys already have their own entries
    exact_n = ci_n = 0
    skipped_explicit = 0

    seen_names = set()
    for name, icon in names:
        if name in seen_names:
            continue
        seen_names.add(name)
        cands = list(by_text.get(name, []))
        icands = list(items_by_text.get(name, []))
        how = "exact"
        if not cands and not icands:
            cands = list(by_text_ci.get(name.lower(), []))
            icands = list(items_by_text_ci.get(name.lower(), []))
            how = "case-insensitive"
        fresh = []
        for k in sorted(cands, key=lambda x: (key_rank(x), x)):
            if k in explicit_keys:
                skipped_explicit += 1
                continue
            if k in claimed:
                continue
            fresh.append(k)
        fresh = fresh[:MAX_KEYS_PER_NAME]
        # item names: the shortest keys first, a couple at most
        ifresh = [k for k in sorted(icands, key=lambda x: (len(x), x)) if k not in claimed][:MAX_ITEM_KEYS_PER_NAME]
        fresh = (fresh + ifresh)[:MAX_KEYS_PER_NAME]
        cands = cands + icands
        if fresh:
            for k in fresh:
                claimed.add(k)
            rows.append((name, fresh))
            if how == "exact":
                exact_n += 1
            else:
                ci_n += 1
        elif cands:
            # every candidate key already has its own explicit entry
            covered.append(name)
        else:
            english_only.append((name, icon, "no vanilla text says this"))
    rows_keyed = [r for r in rows if r[1]]

    # Verb keys. In English, a label such as "Open Door" finds the icon of the
    # one-word entry "Open" because the registry also tries the first word. Other
    # languages cannot (Japanese has no spaces, German puts the verb last), so
    # every vanilla context-menu key that starts with such a word is listed under
    # it and found by its full translated text.
    single = [(n, i) for n, i in names if " " not in n]
    single_names = {n for n, _ in single}
    all_names = {n for n, _ in names}
    verb_map = defaultdict(list)
    for k in sorted(texts):
        if not k.startswith("ContextMenu_") or not allowed(k):
            continue
        if k in explicit_keys or k in claimed:
            continue
        v = texts[k]
        if " " not in v:
            continue
        fw = v.split(" ")[0]
        if fw in single_names and v not in all_names:
            verb_map[fw].append(k)
    # When a vanilla context-menu key that the main table already assigns says the
    # same word ("Read" is ContextMenu_Read), that entry's icon is the one the
    # player has been shown, so the verb row borrows it instead of the English
    # name's icon.
    explicit_by_text = {}
    for k in sorted(explicit_keys):
        if k in texts:
            explicit_by_text.setdefault(texts[k], k)
    context_by_text = {t: k for t, k in explicit_by_text.items() if k.startswith("ContextMenu_")}
    with open(ICONS_LUA, encoding="utf-8") as fh:
        explicit_icons = dict(re.findall(r'^\s*\["([^"]+)"\]\s*=\s*"([^"]+)"', fh.read().split(BEGIN)[0], re.M))
    conflicts = []
    verb_rows = []
    for n, _ in single:
        if not verb_map.get(n):
            continue
        lead = context_by_text.get(n, n)
        verb_rows.append((lead, verb_map[n]))
    for n, icon in names:
        k = explicit_by_text.get(n)
        if k and explicit_icons.get(k) != icon:
            conflicts.append((n, icon, k, explicit_icons.get(k)))
    verb_n = sum(len(r[1]) for r in verb_rows)

    # Category keywords
    with open(REGISTRY_LUA, encoding="utf-8") as fh:
        reg = fh.read()
    keywords = parse_keywords(reg)
    cat_rows = []
    kw_none = []
    for kw in keywords:
        cands = sorted(by_text.get(kw, []) + [k for k in by_text_ci.get(kw.lower(), []) if k not in by_text.get(kw, [])],
                       key=lambda x: (key_rank(x), x))
        got = False
        if cands:
            cat_rows.append([kw] + cands[:MAX_KEYS_PER_KEYWORD])
            got = True
        fw = [k for k in KEYWORD_FIRST_WORD.get(kw, []) if k in texts and k not in cands]
        if fw:
            cat_rows.append([kw] + fw + ["first"])
            got = True
        if not got:
            kw_none.append(kw)

    # Build the Lua block
    out = []
    out.append(BEGIN)
    out.append("-- ZeD.ContextIconKeys: each row is an English name from ZeD.ContextIcons followed by")
    out.append("-- the vanilla translation keys whose English text is that name. The icon is the one")
    out.append("-- the name has in ZeD.ContextIcons. ContextMenuRegistry turns the keys into the")
    out.append("-- player's language at load; the English name stays as the fallback.")
    out.append("ZeD.ContextIconKeys = {")
    for name, keys in rows_keyed:
        out.append("    { " + ", ".join([lua_str(name)] + [lua_str(k) for k in keys]) + " },")
    out.append("}")
    out.append("")
    out.append("-- ZeD.ContextIconVerbKeys: the same idea for labels that start with a one-word name")
    out.append("-- (\"Open Door\" under \"Open\"). Each row is a one-word English name (or a key that says that")
    out.append("-- word) followed by every vanilla context-menu key whose English text begins with it.")
    out.append("-- They take the icon of the first entry.")
    out.append("ZeD.ContextIconVerbKeys = {")
    for name, keys in verb_rows:
        out.append("    { " + ", ".join([lua_str(name)] + [lua_str(k) for k in keys]) + " },")
    out.append("}")
    out.append("")
    out.append("-- ZeD.ContextCategoryKeys: the group keywords of ContextMenuRegistry with their keys.")
    out.append("-- A trailing \"first\" means: use only the first word of the translated text.")
    out.append("ZeD.ContextCategoryKeys = {")
    for row in cat_rows:
        out.append("    { " + ", ".join(lua_str(x) for x in row) + " },")
    out.append("}")
    out.append(END)
    block = "\n".join(out) + "\n"

    if BEGIN in src:
        pre = src.split(BEGIN)[0]
        post = src.split(END, 1)[1].lstrip("\n") if END in src else ""
        new_src = pre + block + (("\n" + post) if post else "")
    else:
        new_src = src.rstrip("\n") + "\n\n" + block

    total_names = len(seen_names)
    print("English names in ContextIcons:      %d" % total_names)
    print("  got keys (exact text):           %d" % exact_n)
    print("  got keys (case-insensitive):     %d" % ci_n)
    print("  total keyed names:               %d  (%d keys written)" % (len(rows_keyed), sum(len(r[1]) for r in rows_keyed)))
    print("  already covered by explicit keys: %d" % len(covered))
    print("  stay English-only:               %d" % len(english_only))
    print("Verb keys (\"Open Door\" style): %d keys under %d one-word names" % (verb_n, len(verb_rows)))
    print("Same word, two icons in the table (the sort order in ContextMenuRegistry decides): %d" % len(conflicts))
    for n, icon, k, kicon in conflicts:
        print("    %-14s English entry %-26s vs %s %s" % (n, icon, k, kicon))
    print("Explicit translation-key entries kept as they were: %d" % len(explicit_keys))
    print("Candidate keys skipped because the main table already assigns them: %d" % skipped_explicit)
    print("Category keywords: %d, with keys: %d, English-only: %d" % (len(keywords), len(cat_rows), len(kw_none)))
    print("  English-only keywords: " + ", ".join(kw_none))

    if args.report:
        with open(args.report, "w", encoding="utf-8") as fh:
            fh.write("Covered by explicit key entries (%d): %s\n\n" % (len(covered), ", ".join(covered)))
            fh.write("English-only names (%d):\n" % len(english_only))
            for name, icon, why in english_only:
                fh.write("%s\t%s\t%s\n" % (name, icon, why))
            fh.write("\nEnglish-only category keywords: %s\n" % ", ".join(kw_none))

    if args.dry_run:
        print("(dry run, nothing written)")
        return 0
    if new_src != src:
        with open(ICONS_LUA, "w", encoding="utf-8", newline="") as fh:
            fh.write(new_src)
        print("wrote " + ICONS_LUA)
    else:
        print("no change")
    return 0


if __name__ == "__main__":
    sys.exit(main())
