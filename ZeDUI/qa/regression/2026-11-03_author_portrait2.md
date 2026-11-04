# ZeD-UI regression - 2026-11-03 17:40 - fullscreen4k (3840x2160 fullscreen)

| | |
|---|---|
| Started | 2026-11-03 17:40:46 |
| Finished | 2026-11-03 17:43:17 (2 min 30 s) |
| Mode | fullscreen4k (3840x2160 fullscreen) |
| Display | fullScreen=true height=2160 width=3840 |
| Game build | 42.22.0 e013dbb529 |
| Mod version | 0.1.1242300k |
| Save | Saves/Sandbox/ZeD-QA |
| Manifest | ZeDUI/tools/qa/author_portrait2.txt (4 scripts) |
| Result | **4/4 pass**, 0 warn, 0 fail, 0 timeout |
| Go numbers | 19736 to 19741 |

Screenshots are in `C:/Users/danie/Zomboid/Screenshots` (the next run overwrites them). PASS: reached DONE with no ERR line and no Lua error. WARN: DONE with ERR lines of its own, or the script ran twice. FAIL: ok=false, a Java exception in the script's window (with -debug the game logs one even for an error a script catches) or the game lost. TIMEOUT: no DONE in time (the run stops there). Not run: after a timeout, a paused game or a lost game. "(expect ...)" prints are shown, not checked.

## Run notes

- ZeD settings: UI scale 1.75x (4K), additions Vanilla Plus (all on, Restock Casual) (the director's ModOptions.ini kept aside)
- pzrestorewin.ps1 (before a fullscreen run): no backup
- started ProjectZomboid64.exe -debug (fullscreen, the director's options.ini)
- loaded; clicked the screen centre (1920,1080) to pass 'click to start'
- the bridge armed in game on Saves/Sandbox/ZeD-QA
- quit: quit to the main menu, then to the desktop (go 19740, 19741)
- ZeD settings: the director's ModOptions.ini put back

## Results

| # | Script | Tag | Status | Seconds | Screenshots | Notes |
|---:|---|---|---|---:|---|---|
| 1 | zedqa_prelude.lua | pre | PASS | 2 |  |  |
| 2 | gallery_t14_look.lua | g14l | PASS | 1 |  |  |
| 3 | zedqa_author_portrait2.lua | au2 | PASS | 37 | zqa_author2_key_a.png, zqa_author2_key_b.png, zqa_author2_key_c.png, zqa_author2_key_d.png, zqa_author2_wall_a.png, zqa_author2_wall_b.png, zqa_author2_wall_c.png, zqa_author2_wall_d.png, zqa_author2_key_a_z15.png, zqa_author2_key_a_z17.png, zqa_author2_interior_store.png, zqa_author2_interior_store_e.png, zqa_author2_interior_store_n.png |  |
| 4 | gallery_t14_end.lua | g14e | PASS | 1 |  |  |

## Scripts

### 1. zedqa_prelude.lua (`ZEDQA pre`) - PASS, 2 s

- go 19736 at 17:42:01

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

- go 19737 at 17:42:07

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

### 3. zedqa_author_portrait2.lua (`ZEDQA au2`) - PASS, 37 s

- go 19738 at 17:42:11
- screenshots: zqa_author2_key_a.png, zqa_author2_key_b.png, zqa_author2_key_c.png, zqa_author2_key_d.png, zqa_author2_wall_a.png, zqa_author2_wall_b.png, zqa_author2_wall_c.png, zqa_author2_wall_d.png, zqa_author2_key_a_z15.png, zqa_author2_key_a_z17.png, zqa_author2_interior_store.png, zqa_author2_interior_store_e.png, zqa_author2_interior_store_n.png

```text
[ZeD.QA] state #3 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=43 missing=get
[ZeD.QA] windows reset (R)
ZEDQA au2 start
[ZeD.QA] run #3 ok=true
ZEDQA au2 stand-in: hair LeftParting, beard Moustache
ZEDQA au2 shot zqa_author2_key_a
ZEDQA au2 shot zqa_author2_key_b
ZEDQA au2 shot zqa_author2_key_c
ZEDQA au2 shot zqa_author2_key_d
ZEDQA au2 shot zqa_author2_wall_a
ZEDQA au2 shot zqa_author2_wall_b
ZEDQA au2 shot zqa_author2_wall_c
ZEDQA au2 shot zqa_author2_wall_d
ZEDQA au2 shot zqa_author2_key_a_z15
ZEDQA au2 shot zqa_author2_key_a_z17
ZEDQA au2 bust done: the stand-in and the backdrop removed
ZEDQA au2 to the Fossoil store
ZEDQA au2 hid 12 UI elements
ZEDQA au2 zoom 0.25
ZEDQA au2 shot zqa_author2_interior_store
ZEDQA au2 shot zqa_author2_interior_store_e
ZEDQA au2 shot zqa_author2_interior_store_n
ERROR: General f:3111 at LuaManager.getFunctionObject > no such function "Vehicles.Init.Radio"
ERROR: General f:3118 at LuaManager.getFunctionObject > no such function "Vehicles.Init.Radio"
ZEDQA au2 put back: the UI, the character's place, the clock and the zoom
ZEDQA au2 DONE
```

### 4. gallery_t14_end.lua (`ZEDQA g14e`) - PASS, 1 s

- go 19739 at 17:42:51

```text
[ZeD.QA] state #4 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=43 missing=get
[ZeD.QA] windows reset (R)
ZEDQA g14e put back: menus true, watermark true, column true, options true | look now dark teal
[ZeD.QA] run #4 ok=true
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
