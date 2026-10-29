# ZeD-UI regression - 2026-10-29 12:32 - fullscreen4k (3840x2160 fullscreen)

| | |
|---|---|
| Started | 2026-10-29 12:32:46 |
| Finished | 2026-10-29 12:35:00 (2 min 13 s) |
| Mode | fullscreen4k (3840x2160 fullscreen) |
| Display | fullScreen=true height=2160 width=3840 |
| Game build | 42.22.0 e013dbb529 |
| Mod version | 0.1.1242300k |
| Save | Saves/Sandbox/ZeD-QA |
| Manifest | C:/Users/danie/Zomboid/mods/ZeD-UI/ZeDUI/tools/qa/etw_manifest.txt (2 scripts) |
| Result | **2/2 pass**, 0 warn, 0 fail, 0 timeout |
| Go numbers | 15708 to 15711 |

Screenshots are in `C:/Users/danie/Zomboid/Screenshots` (the next run overwrites them). PASS: reached DONE with no ERR line and no Lua error. WARN: DONE with ERR lines of its own, or the script ran twice. FAIL: ok=false, a Java exception in the script's window (with -debug the game logs one even for an error a script catches) or the game lost. TIMEOUT: no DONE in time (the run stops there). Not run: after a timeout, a paused game or a lost game. "(expect ...)" prints are shown, not checked.

## Run notes

- ZeD settings: UI scale 1.75x (4K) (the director's ModOptions.ini kept aside)
- pzrestorewin.ps1 (before a fullscreen run): no backup
- started ProjectZomboid64.exe -debug (fullscreen, the director's options.ini)
- loaded; clicked the screen centre (1920,1080) to pass 'click to start'
- the bridge armed in game on Saves/Sandbox/ZeD-QA
- quit: quit to the main menu, then to the desktop (go 15710, 15711)
- ZeD settings: the director's ModOptions.ini put back

## Results

| # | Script | Tag | Status | Seconds | Screenshots | Notes |
|---:|---|---|---|---:|---|---|
| 1 | zedqa_prelude.lua | pre | PASS | 4 |  |  |
| 2 | zedqa_etw.lua | etw | PASS | 6 | zqa_etw_tab.png |  |

## Scripts

### 1. zedqa_prelude.lua (`ZEDQA pre`) - PASS, 4 s

- go 15708 at 12:34:16

```text
[ZeD.QA] windows reset (R)
ZEDQA pre moved from 869,13025,0 to the drag strip
ZEDQA pre start
[ZeD.QA] run #1 ok=true
ERROR: General f:304 at LuaManager.getFunctionObject > no such function "Vehicles.Init.Radio"
ERROR: General f:307 at LuaManager.getFunctionObject > no such function "Vehicles.Init.Radio"
ZEDQA pre char true world true speed 1 ticks 299 frames 300
ZEDQA pre search overlay: enabled false, override false, manager false
ZEDQA pre DONE
```

### 2. zedqa_etw.lua (`ZEDQA etw`) - PASS, 6 s

- go 15709 at 12:34:24
- screenshots: zqa_etw_tab.png

```text
[ZeD.QA] windows reset (R)
ZEDQA etw start
[ZeD.QA] run #2 ok=true
ZEDQA etw tabs: loot,equip,health,thermal,identity,journal,skills,traits,radio (hosted by Traits As Skills)
ZEDQA etw PASS the Traits tab sits right after Skills
ZEDQA etw PASS the Traits tab is on the strip
ZEDQA etw PASS it has the lit pixel-art icon
ZEDQA etw PASS the mod's data can be read
ZEDQA etw PASS the Character window is on Traits
ZEDQA etw PASS the mod's rows are there: 72
ZEDQA etw rows by group: vitals=3 combat=17 noncombat=39 physical=6 mental=7 delayed=0
ZEDQA etw PASS every row is named in the mod's words
ZEDQA etw PASS the Food vital, named as on the mod's page: Food
ZEDQA etw PASS the runner line is named by its trait: Runner
ZEDQA etw PASS Food's strip is the mod's 31-day average: 0.27500000000000013 / 0.27500000000000013
ZEDQA etw PASS Food's progress line is the mod's "Current value": Current value: 0.28
ZEDQA etw skip Reader System (not on this character's page)
ZEDQA etw PASS etw:runner fills to the mod's 0/4: 0
ZEDQA etw PASS its details carry the mod's line: Runner: 0/4
ZEDQA etw PASS focus on the Traits tab in the strip
ZEDQA etw into the tab from the strip: tas:row:TAS.Vision
ZEDQA etw PASS the D-pad goes into the tab
ZEDQA etw PASS the Food row is a controller stop
ZEDQA etw PASS focus is on the Food row: etw:row:etw:food
ZEDQA etw PASS the details follow focus with no press: etw:food
ZEDQA etw PASS down: the next row (etw:row:etw:thirst)
ZEDQA etw PASS walking rows moves the details: etw:thirst
ZEDQA etw PASS the Food row is picked again
ZEDQA etw PASS the foot shows the mod's own description of what moves it
ZEDQA etw PASS the foot's progress line is the mod's "Current value" line
ZEDQA etw shot zqa_etw_tab.png
ZEDQA etw all checks passed
ZEDQA etw DONE
```

## Console errors outside scripts

ERROR lines from launch to quit that fall in no script's window, once each (count first).

```text
    1x ERROR: General f:N at AngelCodeFont.parseFnt > AngelCodeFont failed to load page 0 texture E:/Project Zomboid/SteamApps/common/ProjectZomboid/media/mainfont_0.png
    1x ERROR: General f:N at AngelCodeFont.parseFnt > AngelCodeFont failed to load page 0 texture E:/Project Zomboid/SteamApps/common/ProjectZomboid/media/mainfont2_0.png
    1x ERROR: General f:N at AngelCodeFont.parseFnt > AngelCodeFont failed to load page 0 texture E:/Project Zomboid/SteamApps/common/ProjectZomboid/media/fonts/zomboidDialogue.bmfc_0.png
    3x ERROR: Mod f:N at ChooseGameInfo.readModInfoAux > tiledef=SupportCorps 8900 file number must be from 100 to 8189
    3x ERROR: General f:N at FluidContainerScript.load > Sanitizing container name 'Large Bucket', name may not contain whitespaces.
    3x ERROR: General f:N at FluidContainerScript.load > Sanitizing container name 'Fuel Pump', name may not contain whitespaces.
    1x ERROR: General f:N at CraftRecipeComponentScript.getIconTexture> CraftRecipeComponentScript: Recipe Piano missing UiConfigScript - falling back to SpriteConfigScript first world object face for recipe icon.
    1x ERROR: Lua f:N at Lua(Vanilla).handleMannequinZone > ERROR: Mannequin zone missing properties in media/maps/Muldraugh, KY/objects.lua coords: 13583, 1299, 0
    1x ERROR: General f:N at Basements.mergeRoomsOntoMetaCell > duplicate RoomDef.metaID for room at 10707,9484,0
    1x ERROR: General f:N at IsoMetaGrid.load > invalid room metaID #231 in cell 25,33 while reading map_meta.bin
    1x ERROR: General f:N at IsoMetaGrid.load > invalid room metaID #327914 in cell 25,33 while reading map_meta.bin
    1x ERROR: General f:N at IsoMetaGrid.load > invalid room metaID #327911 in cell 25,33 while reading map_meta.bin
    1x ERROR: General f:N at IsoMetaGrid.load > invalid room metaID #655594 in cell 25,33 while reading map_meta.bin
```
