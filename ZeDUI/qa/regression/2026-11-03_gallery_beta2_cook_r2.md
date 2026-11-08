# ZeD-UI regression - 2026-11-03 15:00 - fullscreen4k (3840x2160 fullscreen)

| | |
|---|---|
| Started | 2026-11-03 15:00:41 |
| Finished | 2026-11-03 15:03:29 (2 min 47 s) |
| Mode | fullscreen4k (3840x2160 fullscreen) |
| Display | fullScreen=true height=2160 width=3840 |
| Game build | 42.22.0 e013dbb529 |
| Mod version | 0.1.1242300k |
| Save | Saves/Sandbox/ZeD-QA |
| Manifest | ZeDUI/tools/qa/gallery_beta2_cook.txt (6 scripts) |
| Result | **6/6 pass**, 0 warn, 0 fail, 0 timeout |
| Go numbers | 19710 to 19717 |

Screenshots are in `%USERPROFILE%/Zomboid/Screenshots` (the next run overwrites them). PASS: reached DONE with no ERR line and no Lua error. WARN: DONE with ERR lines of its own, or the script ran twice. FAIL: ok=false, a Java exception in the script's window (with -debug the game logs one even for an error a script catches) or the game lost. TIMEOUT: no DONE in time (the run stops there). Not run: after a timeout, a paused game or a lost game. "(expect ...)" prints are shown, not checked.

## Run notes

- ZeD settings: UI scale 1.75x (4K), additions Vanilla Plus (all on, Restock Casual) (the director's ModOptions.ini kept aside)
- pzrestorewin.ps1 (before a fullscreen run): no backup
- started ProjectZomboid64.exe -debug (fullscreen, the director's options.ini)
- loaded; clicked the screen centre (1920,1080) to pass 'click to start'
- the bridge armed in game on Saves/Sandbox/ZeD-QA
- quit: quit to the main menu, then to the desktop (go 19716, 19717)
- ZeD settings: the director's ModOptions.ini put back

## Results

| # | Script | Tag | Status | Seconds | Screenshots | Notes |
|---:|---|---|---|---:|---|---|
| 1 | zedqa_prelude.lua | pre | PASS | 2 |  |  |
| 2 | gallery_t14_look.lua | g14l | PASS | 1 |  |  |
| 3 | gallery_daylight.lua | day | PASS | 2 |  |  |
| 4 | gallery_hidecon.lua | hcn | PASS | 1 |  |  |
| 5 | zedqa_cook80.lua | c80 | PASS | 59 | zqa_c80_3840x2160_1_open.png, zqa_c80_3840x2160_2_stew_plan.png, zqa_c80_3840x2160_2_stew_made.png, zqa_c80_3840x2160_3_count.png, zqa_c80_3840x2160_4_stirfry_full.png, zqa_c80_3840x2160_4_by_kind.png, zqa_c80_3840x2160_5_dish_list.png, zqa_c80_3840x2160_5_use_instead.png, zqa_c80_3840x2160_5_not_in_reach.png, zqa_c80_3840x2160_6_by_kind_pad.png |  |
| 6 | gallery_t14_end.lua | g14e | PASS | 1 |  |  |

## Scripts

### 1. zedqa_prelude.lua (`ZEDQA pre`) - PASS, 2 s

- go 19710 at 15:01:42

```text
[ZeD.QA] state #1 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=43 missing=get
[ZeD.QA] windows reset (R)
ZEDQA pre start
[ZeD.QA] run #1 ok=true
ZEDQA pre char true world true speed 1 ticks 60 frames 61
ZEDQA pre search overlay: enabled false, override false, manager false
ZEDQA pre DONE
```

### 2. gallery_t14_look.lua (`ZEDQA g14l`) - PASS, 1 s

- go 19711 at 15:01:47

```text
[ZeD.QA] state #2 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=43 missing=get
[ZeD.QA] windows reset (R)
ZEDQA g14l desk menu bar: Debug left out true
ZEDQA g14l position readout and cheat lines off true
ZEDQA g14l left-edge column hidden true
ZEDQA g14l look dark orange small | GAL_LOOK dark orange, GAL_STILL 20
[ZeD.QA] run #2 ok=true
ZEDQA g14l DONE
```

### 3. gallery_daylight.lua (`ZEDQA day`) - PASS, 2 s

- go 19712 at 15:01:51

```text
[ZeD.QA] state #3 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=43 missing=get
[ZeD.QA] windows reset (R)
ZEDQA day time 11.61 -> 11.00
[ZeD.QA] run #3 ok=true
ZEDQA day DONE
```

### 4. gallery_hidecon.lua (`ZEDQA hcn`) - PASS, 1 s

- go 19713 at 15:01:57

```text
[ZeD.QA] state #4 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=43 missing=get
[ZeD.QA] windows reset (R)
ZEDQA hcn the debug console kept hidden
[ZeD.QA] run #4 ok=true
ZEDQA hcn DONE
```

### 5. zedqa_cook80.lua (`ZEDQA c80`) - PASS, 59 s

- go 19714 at 15:02:01
- screenshots: zqa_c80_3840x2160_1_open.png, zqa_c80_3840x2160_2_stew_plan.png, zqa_c80_3840x2160_2_stew_made.png, zqa_c80_3840x2160_3_count.png, zqa_c80_3840x2160_4_stirfry_full.png, zqa_c80_3840x2160_4_by_kind.png, zqa_c80_3840x2160_5_dish_list.png, zqa_c80_3840x2160_5_use_instead.png, zqa_c80_3840x2160_5_not_in_reach.png, zqa_c80_3840x2160_6_by_kind_pad.png

```text
[ZeD.QA] state #5 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=43 missing=get
[ZeD.QA] windows reset (R)
ZEDQA c80 start
[ZeD.QA] run #5 ok=true
ZEDQA c80 before: tab shown false (the character's own bags)
ZEDQA c80 own bags: carrots 0, potatoes 0, cabbage 0, stews 0, pots 0
ZEDQA c80 pot water: 1.5
ZEDQA c80 PASS a pot of water, a carrot and a potato on the character: the Cooking tab is in the strip
ZEDQA c80 PASS the Cooking tab opens
ZEDQA c80 dish Soup; dishes: Soup, Stew
ZEDQA c80 shot 1_open
ZEDQA c80 PASS the pot taken away: the tab goes (carrot and potato still there)
ZEDQA c80 PASS the window leaves the tab when it goes (now loot)
ZEDQA c80 PASS the Dish list picks Stew (now Stew)
ZEDQA c80 PASS three vegetables in the dish (Base.Carrots, Base.Potato, Base.Cabbage)
ZEDQA c80 PASS all three count as ingredients, none as seasoning (0 as seasoning; the hunger total adds them)
ZEDQA c80 PASS Make is lit
ZEDQA c80 PASS no count for one pot
ZEDQA c80 shot 2_stew_plan
ZEDQA c80 PASS one pot of stew made (1)
ZEDQA c80 PASS it holds all three (3): Vegetable Stew
ZEDQA c80 PASS the carrot and the potato went in (cabbage left: 1, part used)
ZEDQA c80 PASS no empty pot left behind
ZEDQA c80 shot 2_stew_made
ZEDQA c80 PASS the Dish list picks Stew (now Stew)
ZEDQA c80 two pots: dish Stew, bases [Base.Pot ok mine, Base.Pot ok mine], in reach [Base.Potato x2, Base.Carrots x2], plan Base.Carrots, Base.Potato
ZEDQA c80 PASS two pots and enough for two: the count shows
ZEDQA c80 PASS the count goes to 2 (2)
ZEDQA c80 PASS and stops at 2 (2)
ZEDQA c80 shot 3_count
ZEDQA c80 PASS two pots of stew made (2)
ZEDQA c80 PASS each holds a carrot and a potato (2, 2)
ZEDQA c80 Base.Broccoli frozen true; Base.Carrots frozen true
ZEDQA c80 dishes now: Stir fry
ZEDQA c80 PASS the Dish list picks Stir-fry (now Stir fry)
ZEDQA c80 stir-fry: recipe Stir fry, max 4, base Base.Pan; the game offers [Base.Onion, Base.Cabbage, Base.Carrots, Base.BellPepper, Base.Tomato, Base.Potato]; frozen now [Base.Broccoli, Base.Carrots]
ZEDQA c80 stir-fry four in: dish Stir fry, bases [Base.Pan ok mine], in reach [Base.Onion x1, Base.Cabbage x1, Base.Carrots x1, Base.BellPepper x1, Base.Tomato x1, Base.Potato x1], plan Base.Potato, Base.Cabbage, Base.Tomato, Base.Onion
ZEDQA c80 PASS four in the stir-fry (Base.Potato, Base.Cabbage, Base.Tomato, Base.Onion)
ZEDQA c80 PASS the four are ingredients (Ingredients 4 / 4), none seasoning
ZEDQA c80 PASS a fifth greys (bell pepper)
ZEDQA c80 PASS a press on it adds nothing
ZEDQA c80 PASS no seasoning offered to a new stir-fry (as the game)
ZEDQA c80 PASS still four (Base.Potato, Base.Cabbage, Base.Tomato, Base.Onion)
ZEDQA c80 PASS frozen broccoli is not offered (as the game)
ZEDQA c80 carrots: 1 usable, why nil
ZEDQA c80 stir-fry full: dish Stir fry, bases [Base.Pan ok mine], in reach [Base.Onion x1, Base.Cabbage x1, Base.Carrots x1, Base.BellPepper x1, Base.Tomato x1, Base.Potato x1], plan Base.Potato, Base.Cabbage, Base.Tomato, Base.Onion
ZEDQA c80 PASS a frozen carrot beside a good one: the good one still goes in
ZEDQA c80 shot 4_stirfry_full
ZEDQA c80 shot 4_by_kind
ZEDQA c80 PASS the Dish list picks Stew (now Stew)
ZEDQA c80 PASS Save is in the band
ZEDQA c80 PASS the dish is saved (1)
ZEDQA c80 PASS Save turns to Forget
ZEDQA c80 PASS the saved dish heads the Dish list
ZEDQA c80 shot 5_dish_list
ZEDQA c80 PASS the saved dish loads (Base.Carrots, Base.Potato)
ZEDQA c80 PASS the potato not in reach: Use <same kind> is offered
ZEDQA c80 PASS Make waits while an ingredient is missing
ZEDQA c80 shot 5_use_instead
ZEDQA c80 PASS Use takes the cabbage (Base.Carrots, Base.Cabbage)
ZEDQA c80 PASS nothing of the same kind: no Use offered
ZEDQA c80 shot 5_not_in_reach
ZEDQA c80 PASS Forget takes it off the list (0)
ZEDQA c80 PASS A on an ingredient: a stop for it
ZEDQA c80 PASS A adds it (Base.Carrots)
ZEDQA c80 PASS A on the dish's row takes it out
ZEDQA c80 PASS A on Sort opens its list
ZEDQA c80 PASS with the list open, only its choices and the boxes are stops
ZEDQA c80 PASS A picks By category and shuts the list
ZEDQA c80 PASS B shuts an open list
ZEDQA c80 PASS the list is shut
ZEDQA c80 shot 6_by_kind_pad
ZEDQA c80 put back: 26 items taken away, the saved dishes as they were
ZEDQA c80 RESULT 47 pass, 0 fail
ZEDQA c80 DONE
```

### 6. gallery_t14_end.lua (`ZEDQA g14e`) - PASS, 1 s

- go 19715 at 15:03:03

```text
[ZeD.QA] state #6 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=43 missing=get
[ZeD.QA] windows reset (R)
ZEDQA g14e put back: menus true, watermark true, column true, options true | look now dark teal
[ZeD.QA] run #6 ok=true
ZEDQA g14e DONE
```

## Console errors outside scripts

ERROR lines from launch to quit that fall in no script's window, once each (count first).

```text
    1x ERROR: General f:N at AngelCodeFont.parseFnt > AngelCodeFont failed to load page 0 texture E:/Project Zomboid/SteamApps/common/ProjectZomboid/media/mainfont_0.png
    1x ERROR: General f:N at AngelCodeFont.parseFnt > AngelCodeFont failed to load page 0 texture E:/Project Zomboid/SteamApps/common/ProjectZomboid/media/mainfont2_0.png
    1x ERROR: General f:N at AngelCodeFont.parseFnt > AngelCodeFont failed to load page 0 texture E:/Project Zomboid/SteamApps/common/ProjectZomboid/media/fonts/zomboidDialogue.bmfc_0.png
    2x ERROR: General f:N at FluidContainerScript.load > Sanitizing container name 'Large Bucket', name may not contain whitespaces.
    2x ERROR: General f:N at FluidContainerScript.load > Sanitizing container name 'Fuel Pump', name may not contain whitespaces.
    1x ERROR: General f:N at CraftRecipeComponentScript.getIconTexture> CraftRecipeComponentScript: Recipe Piano missing UiConfigScript - falling back to SpriteConfigScript first world object face for recipe icon.
    1x ERROR: Lua f:N at Lua(Vanilla).handleMannequinZone > ERROR: Mannequin zone missing properties in media/maps/Muldraugh, KY/objects.lua coords: 13583, 1299, 0
    1x ERROR: General f:N at Basements.mergeRoomsOntoMetaCell > duplicate RoomDef.metaID for room at 10707,9484,0
    1x ERROR: General f:N at IsoMetaGrid.load > invalid room metaID #231 in cell 25,33 while reading map_meta.bin
    1x ERROR: General f:N at IsoMetaGrid.load > invalid room metaID #327914 in cell 25,33 while reading map_meta.bin
    1x ERROR: General f:N at IsoMetaGrid.load > invalid room metaID #327911 in cell 25,33 while reading map_meta.bin
    1x ERROR: General f:N at IsoMetaGrid.load > invalid room metaID #655594 in cell 25,33 while reading map_meta.bin
    2x ERROR: General f:N at LuaManager.getFunctionObject > no such function "Vehicles.Init.Radio"
```
