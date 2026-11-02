# Compatibility round 4 (Oct 29 and Nov 2 2026) and ZeD-GUI 0.2.0-t11 / t15 for the Compatibility thread v5.
# Sources: compat_round4_candidates.md (the three results sections), round4_post.txt (reply 14),
# tester_changenote_0.2.0-t15.txt, PUNCH_LIST.md items 37 and 40.
EXP = " [i](expected)[/i]"
P = "Part of it does not show: "
T11 = "From ZeD-GUI 0.2.0-t11."
T15 = "From ZeD-GUI 0.2.0-t15."
KAO = "[url=https://steamcommunity.com/profiles/76561199113018152]Kaoeutsu[/url]"   # same Steam page as Wound Expansion's maker
STAR = "[url=https://steamcommunity.com/id/strelka]star[/url]"                       # as on Change Sandbox Options
LOADORDER = ("Find in the load order, Load first and Load last, Load after... and Load before... rules, "
             "separators and folders")
WELCOME = "ZeD already keeps the welcome note and other notes out of the way, in Messages."

# Mods new in round 4: id -> (name, author, list, note, credit link)
# Lists: S Supported, W Works well, C Compatible, V vehicle packs, N Not needed,
# XZ Does not work with ZeD, X broken on 42.21 or 42.22 by itself.
R4 = {
 # first group, Oct 29
 "3459887404": ("Building Craft", "十叁", "C", "Its recipes are in ZeD's Craft and Build tabs.", None),
 "3540503606": ("Neat Crafting & Neat Building - XP & Mod Display", "Afyrmo", "C",
                P + "it adds the XP and the mod's name to the lists of Neat Crafting and Neat Building (both Not needed with ZeD); ZeD's Craft and Build tabs do not show them.", None),
 "3580276809": ("[B42.21] The Only Cure", "Pao", "C", "Its treatments were not tried (they need a bitten character).", None),
 "3818733381": ("The Only Cure+ (Field Surgery)", "NEXCONKER", "C",
                "With The Only Cure on as well, it logs its own \"duplicate object\" errors at load; the game carries on.", None),
 "2980583716": ("Kilometers Per Hour", "Braven", "C", "Loads; ZeD's dashboard draws its own speed, so its reading is not used.", None),
 "3822813865": ("Knox Packs: Upgradable Backpacks", "SA_AS", "C", "Its packs are in ZeD's lists; the upgrades were not tried.", None),
 # second group, Oct 29
 "3819012597": ("Xen's Enhanced GUI", "Xen", "XZ",
                "Both are whole-interface overhauls. With both on, its HUD (health, moodle bar, compass, quick access) draws over ZeD's belt and moodles, and its inventory opens beside ZeD's windows. Run one or the other.", None),
 "3826157418": ("Viewpoint Clean UI", "Bobi Da Baja", "C",
                "Only its update notice showed; its own menu did not take over ZeD's windows. Its options were not tried.", None),
 "3794379457": ("Better World Map", "EROGZ", "C", P + "its labels are for the game's map, not ZeD's Maps tab." + EXP, None),
 "3797292945": ("Locksmith - Padlocks, Lockpicking, & Re-pinning [B42]", "avenoir", "C", "Its rows are in ZeD's item and world menus.", None),
 "3826426915": ("Survivor PDA - RPG Skill Tree, Traders & Missions [B42]", "Batoonchi", "C",
                "Its own window opens on its key, beside ZeD's windows." + EXP, None),
 "3823828778": ("Loot Tracker", "willy_theBean", "C",
                P + "its building colours and restock timer are drawn on the game's map." + EXP, None),
 "3819507580": ("Vital Signs: The 1993 Pocket Notebook", "JGuar", "C", "ZeD's moodle places and hover notes work with it on.", None),
 "3826420021": ("Item Details Panel", "DarMeao Haaaa!", "C",
                "One error of its own at load. Its panels sit beside the game's item tooltip, which ZeD's tooltip runs through, so they may show; not seen in the test.", None),
 "1924146603": ("Disable Welcome Message", "star", "N", "Loads with no errors. " + WELCOME + " Use one.", STAR),
 "3812970899": ("Better Building Plus [B42 MP]", "RedChili", "C", "Its building pieces are in ZeD's Build tab. Needs RC's Structures Framework.", None),
 "3718883428": ("RC's Structures Framework [B42.17+ MP]", "RedChili", "C", "A library for Better Building Plus.", None),
 "3796440093": ("SideWinder's Placement+", "Side Winder", "C", "", None),
 "3809995878": ("Mod Load Order Sorter Extension", "Kaoeutsu", "N",
                f"Loads with no errors. ZeD's Mods screen replaces the load-order screen it extends, and from ZeD-GUI 0.2.0-t15 has {LOADORDER}. Use one. Its optional add-on was not tested.", KAO),
 # third group, Nov 2
 "3813943783": ("Item Arrange Extension", "Kechna", "C", "Needs Item Arrange.", None),
 "3827271522": ("GarageWorks [B42]", "telvary", "C", "", None),
 "3820590495": ("PZ Relationship (Build 42)", "BostonTee", "C", "Tested in single player only; its menu on other players is for multiplayer.", None),
 "3820870164": ("DIY Gear - Craft Weapons, Armor, Tools & Parts", "Phinn", "C", "Its recipes are in ZeD's Craft tab.", None),
 "3802480042": ("PM2 - Complete Repair Overhaul", "CakeDayZ", "C", "", None),
 "3825220364": ("SpiffBoy [B42.21+]", "OhHoop", "C", "", None),
 "3825220785": ("SpiffBoy SDK [B42.21+]", "OhHoop", "C", "A cartridge kit for SpiffBoy.", None),
 "3814251221": ("Crosshair Overhaul", "hogggriiddaaaa", "C", "", None),
 "3795593080": ("More Simple Context Menu Icons", "Kaoeutsu", "N",
                "More icons for Simple Context Menu Icons. ZeD's menus draw their own icons, so these do not show. Use one.", KAO),
 "3824292323": ("Loose Ends: Scenario Editor, Game Master & Story Framework", "nullTrace9342", "C",
                "Its tracker sits at the top right, clear of ZeD's watch.", None),
 "3827432728": ("Ente's Auto Sorter - Inventory/Base/Cars", "Ente", "C",
                "Its button bar at the bottom centre is drawn over the top half of ZeD's belt. Needs Better Containers.", None),
 "3586216562": ("Better Containers", "Eurymachus", "C", "Logs text errors of its own at load; the game carries on.", None),
 "3824731938": ("Extensive health redone", "Wartank", "C", "ZeD's Health tab works with it on.", None),
 "3828392514": ("Drag And Drop (Item Placements)", "Crypt Voice", "C",
                "Dragging out of ZeD's lists into the world was not tried; ZeD's lists keep their own drag." + EXP, None),
 "3826624859": ("Farm Panel Plus (B42)", "Lebanon", "C", "Its panel opens on Ctrl+G, beside ZeD's windows." + EXP, None),
 "3773911887": ("This Is Your Life [B42 Stable] WIP", None, "XZ",
                "Loads with no errors, but ZeD's own Looks screen replaces the character creator it changes, so none of its features show. Run one or the other.", None),
 "3796139100": ("This Is Your Life - Character Creator Overhaul [B42.21]", "MysticaUmbra", "XZ",
                "A fix for This Is Your Life's clothing screen; the same as This Is Your Life.", None),
 "3823338627": ("Modded Clothing Dataset Compatibility [B42]", None, "C",
                "A clothing list for This Is Your Life, which does not work with ZeD (see the Does not work reply).", None),
 # 0.2.0-t15
 "3760450908": ("Immersive Searching [B42MP]", "キツネユキ (yuckyfox)", "S",
                "Containers not yet searched show its \"?\" in ZeD's container strips, a container's list shows things as the search finds them, and Take all and the other moves wait until the search is done. Search all is in the button row when the mod's sandbox option allows it. The searching itself is the mod's; support it on its Workshop page. " + T15, None),
}

# Mods already in v4 whose list, note or maker changed: id -> new fields
CHANGED = {
 # Supported in round 4 (0.2.0-t11)
 "2871469707": dict(list="S", note="Its Transfer category and Loot category buttons are in ZeD's container buttons row, in the Character and World windows, and move the same items the mod's own buttons would. Its Drop all (Category) rows are in ZeD's item menu. " + T11),
 "2854030563": dict(list="S", author="DahakaMVl", note="The mod draws the moodles wherever ZeD puts them (right edge, left edge, or the row above the belt), with its own plates and order; ZeD's hover note follows its order. " + T11),
 "2923554542": dict(list="S", note="The saved XP is a strip under each skill in ZeD's Skills tab (grey for where the skill is, blue for what the saved XP would add); the numbers per book stage are in the row's hover card. " + T11),
 "3410947298": dict(list="S", note="A bag carried inside a bag gets its own column on ZeD's container strip, in the Character and World windows, following the mod's depth and filter options. " + T11),
 "2914075159": dict(list="S", note="Its traits are in ZeD's trait list, and its trait progress page is rows in ZeD's Traits tab: the mod's bars, its gain and lose marks, the trait you have now, and its own numbers and words at the foot. With Traits As Skills on, both share the one tab. " + T11),
 "3789660055": dict(list="S", note="Every container button on ZeD's strips carries a fullness bar in the mod's bands (green, amber, red). " + T11),
 "3819438691": dict(list="S", author="Kaoeutsu", note="Its wounds and conditions show in ZeD's Health tab, in the part's detail and the injury list, in the mod's own words and colours; its treatments are in the part's menu. " + T11),
 # Supported in 0.2.0-t15 (was Not needed)
 "3779201168": dict(list="S", author="FieClaussell", note="ZeD's Mods page reads and saves the same folder file as the mod, so folders made in either show in both and stay when you play without ZeD. A folder's box turns its mods on or off; folders never change the load order. Thanks to FieClaussell for the format; support the mod on its Workshop page. " + T15),
 # Not needed: reasons refreshed with 0.2.0-t15's load order
 "3423660713": dict(note=f"ZeD's Mods screen has its own Auto sort, and from ZeD-GUI 0.2.0-t15 {LOADORDER}. The mod's Sort button is on the game's Mods screen, which ZeD replaces. Use one." + EXP),
 "3567084868": dict(note=f"ZeD's Mods screen does the job: profiles, search, and from ZeD-GUI 0.2.0-t15 {LOADORDER}. With the mod on, ZeD's Mods screen works as usual and the mod's own screens do not show."),
 # file names taken out of notes
 "3056481712": dict(note="Its alert at game start shows raw text keys on 42.21: its translations are in the old format. Not ZeD."),
 "2950750587": dict(note="One error of its own at load on 42.21 (in its weather channel code). Not ZeD."),
 "3036830549": dict(note="Its clothing tooltip errors every frame on 42.21 (a nil call in its own tooltip code), with or without ZeD-GUI. Not ZeD."),
}

# Round 5 (Nov 2 2026, overnight): the Workshop's trending Build 42 mods since Oct 29, ZeD-GUI 0.2.0-t15 code.
# Makers from each mod's mod.info; names as on the Workshop.
R5 = {
 "3830018449": ("Better Context Menu Icons", "SuperOl3g", "N",
                "ZeD's menus draw their own icons for every action, so its icons do not show. Use one.", None),
 "3830422267": ("Immersive Moodles", "Krovenox", "C",
                "Its moving moodle column draws at the top right while ZeD's moodles still show in their place, so each moodle shows twice.", None),
 "3828627678": ("Paravel's Enhanced Inventory", "Paravel", "N",
                "It replaces the game's inventory and loot windows, which ZeD already replaces; none of its windows showed over ZeD's. Needs Paravel's UI. Use one.", None),
 "3828626636": ("Paravel's UI", "Paravel", "N", "The base for Paravel's Enhanced Inventory. Use one.", None),
 "3828137227": ("Light Belt [B42 MP]", "mirusona", "C", "Its lights hang on the belt slots; ZeD's belt works with it on.", None),
 "3829406098": ("Bag Check (B42)", "Slade", "C", "Its Ground Bag add-on was not tested.", None),
 "3827791363": ("Hands-On Interactions", "olavsoe", "C", "Its Viewpoint edition was not tested.", None),
 "3815818643": ("Cheat Menu 2.0 - Rax's Reborn", "Rax", "C",
                "One error of its own: part of it does not load when the game is started in debug mode. Its menu was not opened.", None),
 "3829619974": ("Immersive Sleep", None, "C", "", None),
}
R4.update(R5)
