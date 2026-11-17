# ZeD-UI regression - 2026-11-17 08:39 - windowed (1280x800 window)

| | |
|---|---|
| Started | 2026-11-17 08:39:41 |
| Finished | 2026-11-17 08:41:38 (1 min 56 s) |
| Mode | windowed (1280x800 window) |
| Display | fontSize=2 fullScreen=false height=800 width=1280 |
| Game build | 42.22.2 3d39148846 |
| Mod version | 0.3.0-beta19 |
| Save | Saves/Sandbox/ZeD-QA |
| Manifest | %USERPROFILE%\Zomboid\ZeD-MultiSlot\tests\qa\multislot.txt (2 scripts) |
| Result | **2/2 pass**, 0 warn, 0 fail, 0 timeout |
| Go numbers | 10000 to 10003 |

Screenshots are in `%USERPROFILE%/Zomboid/Screenshots` (the next run overwrites them). PASS: reached DONE with no ERR line and no Lua error. WARN: DONE with ERR lines of its own, or the script ran twice. FAIL: ok=false, a Java exception in the script's window (with -debug the game logs one even for an error a script catches) or the game lost. TIMEOUT: no DONE in time (the run stops there). Not run: after a timeout, a paused game or a lost game. "(expect ...)" prints are shown, not checked.

## Run notes

- ZeD settings: UI scale Auto (1280x800 window), additions Vanilla Plus (all on, Restock Casual) (the director's ModOptions.ini kept aside)
- font size: fontSize=2 for the run (was fontSize=3)
- pzlaunchwin.ps1: launched windowed; clicked client centre (1920,1080) of 3840x2160; pointer parked at (3836,2156)
- the bridge armed in game on Saves/Sandbox/ZeD-QA
- quit: quit to the main menu, then to the desktop (go 10002, 10003)
- pzrestorewin.ps1: fullScreen=false height=2160 width=3840
- font size: the director's line put back (fontSize=3)
- ZeD settings: the director's ModOptions.ini put back

## Results

| # | Script | Tag | Status | Seconds | Screenshots | Notes |
|---:|---|---|---|---:|---|---|
| 1 | zedqa_prelude.lua | pre | PASS | 2 |  |  |
| 2 | ../../../../../ZeD-MultiSlot/tests/qa/zedqa_multislot.lua | zms | PASS | 20 | zqa_zms_1_sizes_shown.png, zqa_zms_2_space_counts.png, zqa_zms_3_pad_place_mode.png |  |

## Scripts

### 1. zedqa_prelude.lua (`ZEDQA pre`) - PASS, 2 s

- go 10000 at 08:40:50

```text
[ZeD.QA] state #1 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=32 missing=get
[ZeD.QA] windows reset (R)
ZEDQA pre the Lua console was open: closed
ZEDQA pre start
[ZeD.QA] run #1 ok=true
ZEDQA pre char true world true speed 1 ticks 60 frames 61
ZEDQA pre search overlay: enabled false, override false, manager false
ZEDQA layout pre default
ZEDQA pre layout char 1022,0 888x840 rolled false pinned true/true
ZEDQA pre layout world 1930,0 888x840 rolled false pinned true/true
ZEDQA pre ZeD version=0.3.0-beta19 dir=%USERPROFILE%\ZomboidBranch\mods\ZeD-UI
ZEDQA pre tabs: Character loot | World loot
ZEDQA pre DONE
```

### 2. ../../../../../ZeD-MultiSlot/tests/qa/zedqa_multislot.lua (`ZEDQA zms`) - PASS, 20 s

- go 10001 at 08:40:55
- screenshots: zqa_zms_1_sizes_shown.png, zqa_zms_2_space_counts.png, zqa_zms_3_pad_place_mode.png

```text
[ZeD.QA] state #2 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=32 missing=get
[ZeD.QA] windows reset (R)
ZEDQA zms start
[ZeD.QA] run #2 ok=true
ZEDQA zms PASS a grid layout provider is active | VERSION 2
ZEDQA zms PASS 0.2: ZeD-GUI's hook draws shapes (version 2) | VERSION 2
ZEDQA zms PASS a rule is registered with ZeD.ItemRules
ZEDQA zms PASS the options group is with ZeD.Options
ZEDQA zms PASS 0.2: the hunting rifle is the long rifle | XXXXXXX/XXX....
ZEDQA zms PASS 0.2: the axe is the axe shape, ten squares | XXX/XXX/X../X../X../X..
ZEDQA zms PASS 0.2: the hammer is a T | XXX/.X./.X./.X.
ZEDQA zms PASS 0.2: the crowbar is straight 4 | X/X/X/X
ZEDQA zms PASS shotgun shells share a square 30 to one | 30
ZEDQA zms school bag: capacity 15, its footprint 10x9
ZEDQA zms PASS Sizes shown: the add-on laid the inventory out | 148 items in cells, 8 across
ZEDQA zms PASS 0.2: the rifle's cell is its ten squares
ZEDQA zms ZeD's layout of the column: true flat true cols 8 cell 69
ZEDQA zms PASS 0.2: ZeD draws the column square by square
ZEDQA zms PASS 0.2: the axe's drawing has its ten squares
ZEDQA zms shot zqa_zms_1_sizes_shown
ZEDQA zms PASS Space counts: the pockets are 6 x 5 (0.2's finer squares) | 6x5
ZEDQA zms the rule on one more thing into the full pockets: false | your pockets is over full: sort its Overflow first
ZEDQA zms shot zqa_zms_2_space_counts
ZEDQA zms the school bag worn on base:back: its grid 11x10
ZEDQA zms PASS the rifle moved into the school bag (it fits)
ZEDQA zms PASS the axe was refused by the full school bag (it stays in the pockets) | ItemContainer:[type:none, parent:IsoPlayer{ Name:null, ID:40 }]
ZEDQA zms PASS the rule says no for the axe | Small Backpack is over full: sort its Overflow first
ZEDQA zms PASS a grid cell has the X hold of place mode | Claw Hammer
ZEDQA zms PASS place mode may start on it
ZEDQA zms its focus rect: 405,1046 223x300
ZEDQA zms PASS place mode is on (its prompts are up)
ZEDQA zms shot zqa_zms_3_pad_place_mode
ZEDQA zms after letting go: remembered 5,12 turned nil
ZEDQA zms PASS place mode ended on letting go
ZEDQA zms cleaned up 161 things | all checks passed
ZEDQA zms DONE
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
    1x ERROR: General f:N at LuaManager.getFunctionObject > no such function "Vehicles.Init.Radio"
```
