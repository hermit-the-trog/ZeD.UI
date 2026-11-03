# ZeD-UI regression - 2026-11-02 23:11 - fullscreen4k (3840x2160 fullscreen)

| | |
|---|---|
| Started | 2026-11-02 23:11:02 |
| Finished | 2026-11-02 23:13:21 (2 min 18 s) |
| Mode | fullscreen4k (3840x2160 fullscreen) |
| Display | fullScreen=true height=2160 width=3840 |
| Game build | 42.22.0 e013dbb529 |
| Mod version | 0.1.1242300k |
| Save | Saves/Sandbox/ZeD-QA |
| Manifest | ZeDUI/tools/qa/new_checks.txt (3 scripts) |
| Result | **1/3 pass**, 2 warn, 0 fail, 0 timeout |
| Go numbers | 19275 to 19279 |

Screenshots are in `C:/Users/you/Zomboid/Screenshots` (the next run overwrites them). PASS: reached DONE with no ERR line and no Lua error. WARN: DONE with ERR lines of its own, or the script ran twice. FAIL: ok=false, a Java exception in the script's window (with -debug the game logs one even for an error a script catches) or the game lost. TIMEOUT: no DONE in time (the run stops there). Not run: after a timeout, a paused game or a lost game. "(expect ...)" prints are shown, not checked.

## Run notes

- ZeD settings: UI scale 1.75x (4K), additions Vanilla Plus (all on, Restock Casual) (the director's ModOptions.ini kept aside)
- pzrestorewin.ps1 (before a fullscreen run): no backup
- started ProjectZomboid64.exe -debug (fullscreen, the director's options.ini)
- loaded; clicked the screen centre (1920,1080) to pass 'click to start'
- the bridge armed in game on Saves/Sandbox/ZeD-QA
- quit: quit to the main menu, then to the desktop (go 19278, 19279)
- ZeD settings: the director's ModOptions.ini put back

## Results

| # | Script | Tag | Status | Seconds | Screenshots | Notes |
|---:|---|---|---|---:|---|---|
| 1 | zedqa_prelude.lua | pre | PASS | 4 |  |  |
| 2 | zedqa_disclosure_walk.lua | dsc | WARN | 35 | zqa_dsc_c_health_1.png, zqa_dsc_c_thermal_1.png, zqa_dsc_c_identity_1.png, zqa_dsc_c_journal_1.png, zqa_dsc_c_journal_2.png, zqa_dsc_c_skills_1.png, zqa_dsc_w_craft_1.png, zqa_dsc_w_craft_2.png, zqa_dsc_w_build_1.png, zqa_dsc_w_maps_1.png, zqa_dsc_w_forage_1.png | 5 ERR line(s) |
| 3 | zedqa_button_census.lua | bcn | WARN | 10 |  | 11 ERR line(s) |

## Scripts

### 1. zedqa_prelude.lua (`ZEDQA pre`) - PASS, 4 s

- go 19275 at 23:12:01

```text
[ZeD.QA] state #1 speed=1 paused=false player=914,13054 grid=19 inCar=false vehicles=53 missing=get
[ZeD.QA] windows reset (R)
ZEDQA pre moved from 914,13054,0 to the drag strip
ZEDQA pre clock 23.18 -> 11.00 (daylight)
ZEDQA pre start
[ZeD.QA] run #1 ok=true
ZEDQA pre char true world true speed 1 ticks 299 frames 300
ZEDQA pre search overlay: enabled false, override false, manager false
ZEDQA pre DONE
```

### 2. zedqa_disclosure_walk.lua (`ZEDQA dsc`) - WARN, 35 s

- go 19276 at 23:12:08
- 5 ERR line(s)
- screenshots: zqa_dsc_c_health_1.png, zqa_dsc_c_thermal_1.png, zqa_dsc_c_identity_1.png, zqa_dsc_c_journal_1.png, zqa_dsc_c_journal_2.png, zqa_dsc_c_skills_1.png, zqa_dsc_w_craft_1.png, zqa_dsc_w_craft_2.png, zqa_dsc_w_build_1.png, zqa_dsc_w_maps_1.png, zqa_dsc_w_forage_1.png

```text
[ZeD.QA] state #2 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=43 missing=get
[ZeD.QA] windows reset (R)
ZEDQA dsc start
[ZeD.QA] run #2 ok=true
ZEDQA dsc tabs: Character 7, World 7
ZEDQA dsc c loot: 0 disclosure(s)
ZEDQA dsc c equip: 0 disclosure(s)
ZEDQA dsc c health: 1 disclosure(s) health:__disclosure
ZEDQA dsc PASS c health health:__disclosure: listed
ZEDQA dsc PASS c health health:__disclosure: the press runs
ZEDQA dsc PASS c health health:__disclosure: the tab changes when pressed
ZEDQA dsc PASS c health health:__disclosure: still listed once pressed
ZEDQA dsc PASS c health health:__disclosure: the second press runs
ZEDQA dsc PASS c health health:__disclosure: pressed again, the tab is back as it was
ZEDQA dsc c thermal: 1 disclosure(s) thermal:__disclosure
ZEDQA dsc PASS c thermal thermal:__disclosure: listed
ZEDQA dsc PASS c thermal thermal:__disclosure: the press runs
ZEDQA dsc PASS c thermal thermal:__disclosure: the tab changes when pressed
ZEDQA dsc PASS c thermal thermal:__disclosure: still listed once pressed
ZEDQA dsc PASS c thermal thermal:__disclosure: the second press runs
ZEDQA dsc PASS c thermal thermal:__disclosure: pressed again, the tab is back as it was
ZEDQA dsc c identity: 1 disclosure(s) identity:__disclosure
ZEDQA dsc PASS c identity identity:__disclosure: listed
ZEDQA dsc PASS c identity identity:__disclosure: the press runs
ZEDQA dsc FAIL c identity identity:__disclosure: the tab changes when pressed
ZEDQA dsc PASS c identity identity:__disclosure: still listed once pressed
ZEDQA dsc PASS c identity identity:__disclosure: the second press runs
ZEDQA dsc PASS c identity identity:__disclosure: pressed again, the tab is back as it was
ZEDQA dsc c journal: 2 disclosure(s) journal:__kills, journal:group:6_1993
ZEDQA dsc PASS c journal journal:__kills: listed
ZEDQA dsc PASS c journal journal:__kills: the press runs
ZEDQA dsc FAIL c journal journal:__kills: the tab changes when pressed
ZEDQA dsc PASS c journal journal:__kills: still listed once pressed
ZEDQA dsc PASS c journal journal:__kills: the second press runs
ZEDQA dsc PASS c journal journal:__kills: pressed again, the tab is back as it was
ZEDQA dsc PASS c journal journal:group:6_1993: listed
ZEDQA dsc PASS c journal journal:group:6_1993: the press runs
ZEDQA dsc FAIL c journal journal:group:6_1993: the tab changes when pressed
ZEDQA dsc PASS c journal journal:group:6_1993: still listed once pressed
ZEDQA dsc PASS c journal journal:group:6_1993: the second press runs
ZEDQA dsc PASS c journal journal:group:6_1993: pressed again, the tab is back as it was
ZEDQA dsc c skills: 1 disclosure(s) skills:__disclosure
ZEDQA dsc PASS c skills skills:__disclosure: listed
ZEDQA dsc PASS c skills skills:__disclosure: the press runs
ZEDQA dsc PASS c skills skills:__disclosure: the tab changes when pressed
ZEDQA dsc PASS c skills skills:__disclosure: still listed once pressed
ZEDQA dsc PASS c skills skills:__disclosure: the second press runs
ZEDQA dsc PASS c skills skills:__disclosure: pressed again, the tab is back as it was
ZEDQA dsc w loot: 0 disclosure(s)
ZEDQA dsc w craft: 2 disclosure(s) craft:section:freq, craft:section:all
ZEDQA dsc PASS w craft craft:section:freq: listed
ZEDQA dsc PASS w craft craft:section:freq: the press runs
ZEDQA dsc PASS w craft craft:section:freq: the tab changes when pressed
ZEDQA dsc PASS w craft craft:section:freq: still listed once pressed
ZEDQA dsc PASS w craft craft:section:freq: the second press runs
ZEDQA dsc PASS w craft craft:section:freq: pressed again, the tab is back as it was
ZEDQA dsc PASS w craft craft:section:all: listed
ZEDQA dsc PASS w craft craft:section:all: the press runs
ZEDQA dsc PASS w craft craft:section:all: the tab changes when pressed
ZEDQA dsc PASS w craft craft:section:all: still listed once pressed
ZEDQA dsc PASS w craft craft:section:all: the second press runs
ZEDQA dsc PASS w craft craft:section:all: pressed again, the tab is back as it was
ZEDQA dsc w build: 1 disclosure(s) build:section:all
ZEDQA dsc PASS w build build:section:all: listed
ZEDQA dsc PASS w build build:section:all: the press runs
ZEDQA dsc FAIL w build build:section:all: the tab changes when pressed
ZEDQA dsc PASS w build build:section:all: still listed once pressed
ZEDQA dsc PASS w build build:section:all: the second press runs
ZEDQA dsc PASS w build build:section:all: pressed again, the tab is back as it was
ZEDQA dsc w furniture: 0 disclosure(s)
ZEDQA dsc w maps: 1 disclosure(s) map:disclosure
ZEDQA dsc PASS w maps map:disclosure: listed
ZEDQA dsc PASS w maps map:disclosure: the press runs
ZEDQA dsc PASS w maps map:disclosure: the tab changes when pressed
ZEDQA dsc PASS w maps map:disclosure: still listed once pressed
ZEDQA dsc PASS w maps map:disclosure: the second press runs
ZEDQA dsc PASS w maps map:disclosure: pressed again, the tab is back as it was
ZEDQA dsc w forage: 1 disclosure(s) forage:disclosure
ZEDQA dsc PASS w forage forage:disclosure: listed
ZEDQA dsc PASS w forage forage:disclosure: the press runs
ZEDQA dsc PASS w forage forage:disclosure: the tab changes when pressed
ZEDQA dsc PASS w forage forage:disclosure: still listed once pressed
ZEDQA dsc PASS w forage forage:disclosure: the second press runs
ZEDQA dsc PASS w forage forage:disclosure: pressed again, the tab is back as it was
ZEDQA dsc w animals: 0 disclosure(s)
ZEDQA dsc PASS disclosures found and walked: 11
ZEDQA dsc summary: 4 of 67 checks FAIL
ZEDQA dsc DONE
```

### 3. zedqa_button_census.lua (`ZEDQA bcn`) - WARN, 10 s

- go 19277 at 23:12:46
- 11 ERR line(s)

```text
[ZeD.QA] state #3 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=43 missing=get
[ZeD.QA] windows reset (R)
ZEDQA bcn start
[ZeD.QA] run #3 ok=true
ZEDQA bcn tabs: 14
ZEDQA bcn c loot: 28 stops
ZEDQA bcn PASS c loot: the controller has stops to land on
ZEDQA bcn PASS c loot: every stop has something behind it
ZEDQA bcn FAIL c loot: every stop sits inside its window (outside: invrow:13, invrow:14, invrow:15)
ZEDQA bcn c equip: 61 stops
ZEDQA bcn PASS c equip: the controller has stops to land on
ZEDQA bcn FAIL c equip: every stop has something behind it (dead: equippart:Head, equippart:Neck, equippart:Upper Torso, equippart:Right Upper Arm, equippart:Left Upper Arm, equippart:Lower Torso, equippart:Right Forearm, equippart:Left Forearm, equippart:Groin, equippart:Right Hand, equippart:Left Hand, equippart:Right Upper Leg, equippart:Left Upper Leg, equippart:Right Lower Leg, equippart:Left Lower Leg, equippart:Right Foot, equippart:Left Foot)
ZEDQA bcn FAIL c equip: every stop sits inside its window (outside: equippart:Head, equippart:Neck, equippart:Upper Torso, equippart:Right Upper Arm, equippart:Left Upper Arm, equippart:Lower Torso, equippart:Right Forearm, equippart:Left Forearm, equippart:Groin, equippart:Right Hand, equippart:Left Hand, equippart:Right Upper Leg, equippart:Left Upper Leg, equippart:Right Lower Leg, equippart:Left Lower Leg, equippart:Right Foot, equippart:Left Foot, invrow:13, invrow:14, invrow:15)
ZEDQA bcn c health: 50 stops
ZEDQA bcn PASS c health: the controller has stops to land on
ZEDQA bcn PASS c health: every stop has something behind it
ZEDQA bcn FAIL c health: every stop sits inside its window (outside: invrow:13, invrow:14, invrow:15)
ZEDQA bcn c thermal: 48 stops
ZEDQA bcn PASS c thermal: the controller has stops to land on
ZEDQA bcn FAIL c thermal: every stop has something behind it (dead: thermalpart:Head, thermalpart:Neck, thermalpart:Upper Torso, thermalpart:Right Upper Arm, thermalpart:Left Upper Arm, thermalpart:Lower Torso, thermalpart:Right Forearm, thermalpart:Left Forearm, thermalpart:Groin, thermalpart:Right Hand, thermalpart:Left Hand, thermalpart:Right Upper Leg, thermalpart:Left Upper Leg, thermalpart:Right Lower Leg, thermalpart:Left Lower Leg, thermalpart:Right Foot, thermalpart:Left Foot)
ZEDQA bcn FAIL c thermal: every stop sits inside its window (outside: invrow:13, invrow:14, invrow:15)
ZEDQA bcn c identity: 43 stops
ZEDQA bcn PASS c identity: the controller has stops to land on
ZEDQA bcn FAIL c identity: every stop has something behind it (dead: identity:trait:Dextrous, identity:trait:Fast Reader, identity:trait:Speed Demon, identity:trait:Strong, identity:trait:Vehicle Knowledge, identity:trait:Hearty Appetite, identity:trait:Prone to Illness, identity:trait:Reluctant Fighter, identity:trait:Slow Healer, identity:trait:Smoker)
ZEDQA bcn FAIL c identity: every stop sits inside its window (outside: hb:part, hb:do, hb:row:h:cut:Bald, hb:more, identity:trait:Dextrous, identity:trait:Fast Reader, identity:trait:Speed Demon, identity:trait:Strong, identity:trait:Vehicle Knowledge, identity:trait:Hearty Appetite, identity:trait:Prone to Illness, identity:trait:Reluctant Fighter, identity:trait:Slow Healer, identity:trait:Smoker, invrow:13, invrow:14, invrow:15)
ZEDQA bcn c journal: 32 stops
ZEDQA bcn PASS c journal: the controller has stops to land on
ZEDQA bcn PASS c journal: every stop has something behind it
ZEDQA bcn FAIL c journal: every stop sits inside its window (outside: invrow:13, invrow:14, invrow:15)
ZEDQA bcn c skills: 88 stops
ZEDQA bcn PASS c skills: the controller has stops to land on
ZEDQA bcn PASS c skills: every stop has something behind it
ZEDQA bcn FAIL c skills: every stop sits inside its window (outside: skill:Pottery, skill:Tailoring, skill:Welding, skill:First Aid, skill:Fishing, skill:Foraging, skill:Tracking, skill:Trapping, skill:Fitness, skill:Lightfooted, skill:Nimble, skill:Running, skill:Sneaking, skill:Strength, training:col1_Aiming, training:col1_Blacksmith, training:col1_Butchering, training:col1_Carpentry, training:col1_Carving, training:col1_Cooking, training:col1_Electricity, training:col1_Farming, training:col1_FirstAid, training:col1_Fishing, training:col1_FlintKnapping, training:col1_Foraging, training:col2_Glassmaking, training:col2_Husbandry, training:col2_LongBlade, training:col2_Maintenance, training:col2_Masonry, training:col2_Mechanics, training:col2_MetalWelding, training:col2_Pottery, training:col2_Reloading, training:col2_Tailoring, training:col2_Tracking, training:col2_Trapping, invrow:13, invrow:14, invrow:15)
ZEDQA bcn w loot: 14 stops
ZEDQA bcn PASS w loot: the controller has stops to land on
ZEDQA bcn PASS w loot: every stop has something behind it
ZEDQA bcn PASS w loot: every stop sits inside its window
ZEDQA bcn w craft: 22 stops
ZEDQA bcn PASS w craft: the controller has stops to land on
ZEDQA bcn PASS w craft: every stop has something behind it
ZEDQA bcn PASS w craft: every stop sits inside its window
ZEDQA bcn w build: 18 stops
ZEDQA bcn PASS w build: the controller has stops to land on
ZEDQA bcn PASS w build: every stop has something behind it
ZEDQA bcn PASS w build: every stop sits inside its window
ZEDQA bcn w furniture: 19 stops
ZEDQA bcn PASS w furniture: the controller has stops to land on
ZEDQA bcn PASS w furniture: every stop has something behind it
ZEDQA bcn PASS w furniture: every stop sits inside its window
ZEDQA bcn w maps: 33 stops
ZEDQA bcn PASS w maps: the controller has stops to land on
ZEDQA bcn PASS w maps: every stop has something behind it
ZEDQA bcn PASS w maps: every stop sits inside its window
ZEDQA bcn w forage: 17 stops
ZEDQA bcn PASS w forage: the controller has stops to land on
ZEDQA bcn PASS w forage: every stop has something behind it
ZEDQA bcn PASS w forage: every stop sits inside its window
ZEDQA bcn w animals: 17 stops
ZEDQA bcn PASS w animals: the controller has stops to land on
ZEDQA bcn PASS w animals: every stop has something behind it
ZEDQA bcn PASS w animals: every stop sits inside its window
ZEDQA bcn stops listed: 490, dead: 44 (Lua/zedqa_button_census.txt)
ZEDQA bcn summary: 10 of 42 checks FAIL
ZEDQA bcn DONE
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
