# ZeD-UI regression - 2026-11-07 01:18 - windowed (1280x800 window)

| | |
|---|---|
| Started | 2026-11-07 01:18:54 |
| Finished | 2026-11-07 01:21:47 (2 min 52 s) |
| Mode | windowed (1280x800 window) |
| Display | fullScreen=false height=800 width=1280 |
| Game build | 42.22.2 3d39148846 |
| Mod version | 0.1.1242300k |
| Save | Saves/Sandbox/ZeD-QA |
| Manifest | C:\Users\you\Zomboid\mods\ZeD-UI\ZeDUI\tools\qa\b6a_left.txt (3 scripts) |
| Result | **3/3 pass**, 0 warn, 0 fail, 0 timeout |
| Go numbers | 22803 to 22807 |

Screenshots are in `C:/Users/you/Zomboid/Screenshots` (the next run overwrites them). PASS: reached DONE with no ERR line and no Lua error. WARN: DONE with ERR lines of its own, or the script ran twice. FAIL: ok=false, a Java exception in the script's window (with -debug the game logs one even for an error a script catches) or the game lost. TIMEOUT: no DONE in time (the run stops there). Not run: after a timeout, a paused game or a lost game. "(expect ...)" prints are shown, not checked.

## Run notes

- ZeD settings: UI scale Auto (1280x800 window), additions Vanilla Plus (all on, Restock Casual) (the director's ModOptions.ini kept aside)
- pzlaunchwin.ps1: launched windowed; clicked client centre (1929,1118) of 1280x800
- the bridge armed in game on Saves/Sandbox/ZeD-QA
- quit: quit to the main menu, then to the desktop (go 22806, 22807)
- pzrestorewin.ps1: fullScreen=true height=2160 width=3840
- ZeD settings: the director's ModOptions.ini put back

## Results

| # | Script | Tag | Status | Seconds | Screenshots | Notes |
|---:|---|---|---|---:|---|---|
| 1 | zedqa_prelude.lua | pre | PASS | 2 |  |  |
| 2 | zedqa_pin_windows.lua | pnw | PASS | 1 |  |  |
| 3 | zedqa_b6a_left.lua | b6l | PASS | 69 | zqa_b6l_01_char_radio.png, zqa_b6l_02_world_radio.png, zqa_b6l_03_recipes.png, zqa_b6l_04_recipes_card.png, zqa_b6l_05_recipes_closed.png, zqa_b6l_06_vest_card.png, zqa_b6l_07_boots_card.png, zqa_b6l_08_book_card.png, zqa_b6l_09_closed.png |  |

## Scripts

### 1. zedqa_prelude.lua (`ZEDQA pre`) - PASS, 2 s

- go 22803 at 01:19:51

```text
[ZeD.QA] state #1 speed=1 paused=false player=925,13040 grid=15 inCar=false vehicles=11 missing=get
[ZeD.QA] windows reset (R)
ZEDQA pre start
[ZeD.QA] run #1 ok=true
ZEDQA pre char true world true speed 1 ticks 60 frames 61
ZEDQA pre search overlay: enabled false, override false, manager false
ZEDQA pre DONE
```

### 2. zedqa_pin_windows.lua (`ZEDQA pnw`) - PASS, 1 s

- go 22804 at 01:19:56

```text
[ZeD.QA] state #2 speed=1 paused=false player=925,13040 grid=15 inCar=false vehicles=11 missing=get
[ZeD.QA] windows reset (R)
ZEDQA pnw pinned both windows
[ZeD.QA] run #2 ok=true
ZEDQA pnw DONE
```

### 3. zedqa_b6a_left.lua (`ZEDQA b6l`) - PASS, 69 s

- go 22805 at 01:20:01
- screenshots: zqa_b6l_01_char_radio.png, zqa_b6l_02_world_radio.png, zqa_b6l_03_recipes.png, zqa_b6l_04_recipes_card.png, zqa_b6l_05_recipes_closed.png, zqa_b6l_06_vest_card.png, zqa_b6l_07_boots_card.png, zqa_b6l_08_book_card.png, zqa_b6l_09_closed.png

```text
[ZeD.QA] state #3 speed=1 paused=false player=925,13040 grid=15 inCar=false vehicles=11 missing=get
[ZeD.QA] windows reset (R)
ZEDQA b6l start
[ZeD.QA] run #3 ok=true
ZEDQA b6l walkie in hand true, ham set placed 1
ZEDQA b6l char radio tab true
ZEDQA b6l char radio: tab=radio mode=tab card=nil cardW=false clips=0 sub=1
ZEDQA b6l world radio tab true
ZEDQA b6l world radio: tab=radio mode=tab card=nil cardW=false clips=0 sub=nil
ZEDQA b6l recipes: tab=journal mode=tab card=nil cardW=false clips=0 sub=4
ZEDQA b6l press first row at 507,74
ZEDQA b6l recipes card: tab=journal mode=tab card=Animal Feed Bag cardW=165 clips=0 sub=4
ZEDQA b6l the card's X at 246,44
ZEDQA b6l recipes after X: tab=journal mode=tab card=Animal Feed Bag cardW=165 clips=0 sub=4
ZEDQA b6l vest 100 bullet, 30 bite, 55 scratch; boots 100 bite, 100 scratch; book pages 220, read 110
ZEDQA b6l press vest at 450,212
ZEDQA b6l vest card: tab=loot mode=item card=Bulletproof Vest - Police cardW=165 clips=0 sub=4
ZEDQA b6l the card's X at 189,44
ZEDQA b6l press boots at 450,534
ZEDQA b6l boots card: tab=loot mode=item card=Bulletproof Vest - Police cardW=165 clips=0 sub=4
ZEDQA b6l the card's X at 189,44
ZEDQA b6l press book at 450,235
ZEDQA b6l book card: tab=loot mode=item card=Carpentry I: "A Guide to Nailing" cardW=165 clips=0 sub=4
ZEDQA b6l the card's X at 189,44
ZEDQA b6l all closed: tab=loot mode=item card=Carpentry I: "A Guide to Nailing" cardW=165 clips=0 sub=4
ZEDQA b6l taken away 4 items, 1 sets
ZEDQA b6l DONE
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
