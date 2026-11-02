# ZeD-UI regression - 2026-11-02 12:27 - fullscreen4k (3840x2160 fullscreen)

| | |
|---|---|
| Started | 2026-11-02 12:27:38 |
| Finished | 2026-11-02 12:29:33 (1 min 55 s) |
| Mode | fullscreen4k (3840x2160 fullscreen) |
| Display | fullScreen=true height=2160 width=3840 |
| Game build | 42.22.0 e013dbb529 |
| Mod version | 0.1.1242300k |
| Save | Saves/Sandbox/ZeD-QA |
| Manifest | ZeDUI/tools/qa/pl53_imo.txt (2 scripts) |
| Result | **1/2 pass**, 1 warn, 0 fail, 0 timeout |
| Go numbers | 18696 to 18699 |

Screenshots are in `C:/Users/you/Zomboid/Screenshots` (the next run overwrites them). PASS: reached DONE with no ERR line and no Lua error. WARN: DONE with ERR lines of its own, or the script ran twice. FAIL: ok=false, a Java exception in the script's window (with -debug the game logs one even for an error a script catches) or the game lost. TIMEOUT: no DONE in time (the run stops there). Not run: after a timeout, a paused game or a lost game. "(expect ...)" prints are shown, not checked.

## Run notes

- ZeD settings: UI scale 1.75x (4K), additions Vanilla Plus (all on, Restock Casual) (the director's ModOptions.ini kept aside)
- pzrestorewin.ps1 (before a fullscreen run): no backup
- started ProjectZomboid64.exe -debug (fullscreen, the director's options.ini)
- loaded; clicked the screen centre (1920,1080) to pass 'click to start'
- the bridge armed in game on Saves/Sandbox/ZeD-QA
- quit: quit to the main menu, then to the desktop (go 18698, 18699)
- ZeD settings: the director's ModOptions.ini put back

## Results

| # | Script | Tag | Status | Seconds | Screenshots | Notes |
|---:|---|---|---|---:|---|---|
| 1 | zedqa_prelude.lua | pre | PASS | 1 |  |  |
| 2 | zedqa_immersive_moodles.lua | imo | WARN | 17 | zqa_imo_place_right.png, zqa_imo_place_left.png, zqa_imo_place_bottom.png, zqa_imo_corner_watch.png, zqa_imo_safe_on.png, zqa_imo_hud_off.png, zqa_imo_hud_off_notice.png | 1 ERR line(s) |

## Scripts

### 1. zedqa_prelude.lua (`ZEDQA pre`) - PASS, 1 s

- go 18696 at 12:28:47

```text
[ZeD.QA] state #1 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=41 missing=get
[ZeD.QA] windows reset (R)
ZEDQA pre start
[ZeD.QA] run #1 ok=true
ZEDQA pre char true world true speed 1 ticks 60 frames 61
ZEDQA pre search overlay: enabled false, override false, manager false
ZEDQA pre DONE
```

### 2. zedqa_immersive_moodles.lua (`ZEDQA imo`) - WARN, 17 s

- go 18697 at 12:28:51
- 1 ERR line(s)
- screenshots: zqa_imo_place_right.png, zqa_imo_place_left.png, zqa_imo_place_bottom.png, zqa_imo_corner_watch.png, zqa_imo_safe_on.png, zqa_imo_hud_off.png, zqa_imo_hud_off_notice.png

```text
[ZeD.QA] state #2 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=41 missing=get
[ZeD.QA] windows reset (R)
ZEDQA imo PASS ZeD's Immersive Moodles support is loaded (ZeD.ModSupport.ImmersiveMoodles)
ZEDQA imo PASS the mod's option reader is wrapped
ZEDQA imo start
[ZeD.QA] run #2 ok=true
ZEDQA imo ZeD place right: ZeD layer shown false | M.rect false | game column -20000,-20000 | mod HUD panel true hudOff false | support drawing true | moodles 4 | chips 0
ZEDQA imo PASS ZeD place right: ZeD draws no moodles (layer hidden)
ZEDQA imo PASS ZeD place right: ZeD's moodle rect is nil
ZEDQA imo PASS ZeD place right: the game's column is parked off screen by the mod
ZEDQA imo PASS ZeD place right: the mod's HUD panel is on
ZEDQA imo PASS ZeD place right: no ZeD note drawn (0)
ZEDQA imo PASS ZeD place right: at least three moodles are up (4)
ZEDQA imo shot zqa_imo_place_right
ZEDQA imo ZeD place left: ZeD layer shown false | M.rect false | game column -20000,-20000 | mod HUD panel true hudOff false | support drawing true | moodles 4 | chips 0
ZEDQA imo PASS ZeD place left: ZeD draws no moodles (layer hidden)
ZEDQA imo PASS ZeD place left: ZeD's moodle rect is nil
ZEDQA imo PASS ZeD place left: the game's column is parked off screen by the mod
ZEDQA imo PASS ZeD place left: the mod's HUD panel is on
ZEDQA imo PASS ZeD place left: no ZeD note drawn (0)
ZEDQA imo PASS ZeD place left: at least three moodles are up (4)
ZEDQA imo shot zqa_imo_place_left
ZEDQA imo ZeD place bottom: ZeD layer shown false | M.rect false | game column -20000,-20000 | mod HUD panel true hudOff false | support drawing true | moodles 4 | chips 0
ZEDQA imo PASS ZeD place bottom: ZeD draws no moodles (layer hidden)
ZEDQA imo PASS ZeD place bottom: ZeD's moodle rect is nil
ZEDQA imo PASS ZeD place bottom: the game's column is parked off screen by the mod
ZEDQA imo PASS ZeD place bottom: the mod's HUD panel is on
ZEDQA imo PASS ZeD place bottom: no ZeD note drawn (0)
ZEDQA imo PASS ZeD place bottom: at least three moodles are up (4)
ZEDQA imo shot zqa_imo_place_bottom
ZEDQA imo after a hunger level change: ZeD layer shown false | M.rect false | game column -20000,-20000 | mod HUD panel true hudOff false | support drawing true | moodles 4 | chips 0
ZEDQA imo PASS after a hunger level change: ZeD draws no moodles (layer hidden)
ZEDQA imo PASS after a hunger level change: ZeD's moodle rect is nil
ZEDQA imo PASS after a hunger level change: the game's column is parked off screen by the mod
ZEDQA imo PASS after a hunger level change: the mod's HUD panel is on
ZEDQA imo PASS after a hunger level change: no ZeD note drawn (0)
ZEDQA imo PASS after a hunger level change: at least three moodles are up (4)
ZEDQA imo corner watch 3576,10 248x352 | mod side 1 | its top offset: set 96, read 380 | the watch wants 380
ZEDQA imo PASS the mod's column starts below the corner watch (top offset 380 >= 380)
ZEDQA imo shot zqa_imo_corner_watch
ZEDQA imo safe mode on: ZeD layer shown false | M.rect false | game column -20000,-20000 | mod HUD panel true hudOff false | support drawing false | moodles 4 | chips 0
ZEDQA imo PASS safe mode is on
ZEDQA imo PASS safe mode: the mod still draws its moodles and parks the game's column
ZEDQA imo PASS safe mode: no ZeD note drawn (0)
ZEDQA imo shot zqa_imo_safe_on
ZEDQA imo PASS safe mode is off again
ZEDQA imo safe mode off: ZeD layer shown false | M.rect false | game column -20000,-20000 | mod HUD panel true hudOff false | support drawing true | moodles 4 | chips 0
ZEDQA imo PASS safe mode off: ZeD draws no moodles (layer hidden)
ZEDQA imo PASS safe mode off: ZeD's moodle rect is nil
ZEDQA imo PASS safe mode off: the game's column is parked off screen by the mod
ZEDQA imo PASS safe mode off: the mod's HUD panel is on
ZEDQA imo PASS safe mode off: no ZeD note drawn (0)
ZEDQA imo PASS safe mode off: at least three moodles are up (4)
ZEDQA imo the mod's HUD off: ZeD layer shown true | M.rect true | game column 3782,969 | mod HUD panel false hudOff true | support drawing false | moodles 4 | chips 30
ZEDQA imo PASS HUD off: the support says the mod is not drawing
ZEDQA imo PASS HUD off: ZeD shows the moodles again
ZEDQA imo PASS HUD off: the game's column is on screen where ZeD puts it (3782)
ZEDQA imo shot zqa_imo_hud_off
ZEDQA imo HUD off, after a hunger level change: chips 45 (Moodle notices true)
ZEDQA imo PASS HUD off: ZeD's note shows on a level change
ZEDQA imo shot zqa_imo_hud_off_notice
ZEDQA imo the mod's HUD back on: ZeD layer shown false | M.rect false | game column -20000,-20000 | mod HUD panel true hudOff false | support drawing true | moodles 4 | chips 0
ZEDQA imo PASS the mod's HUD back on: ZeD draws no moodles (layer hidden)
ZEDQA imo PASS the mod's HUD back on: ZeD's moodle rect is nil
ZEDQA imo PASS the mod's HUD back on: the game's column is parked off screen by the mod
ZEDQA imo PASS the mod's HUD back on: the mod's HUD panel is on
ZEDQA imo PASS the mod's HUD back on: no ZeD note drawn (0)
ZEDQA imo PASS the mod's HUD back on: at least three moodles are up (4)
ZEDQA imo put back: place 1, watch 1, safe false
ZEDQA imo summary: 47 PASS, 0 FAIL
ZEDQA imo DONE
```

## Console errors outside scripts

ERROR lines from launch to quit that fall in no script's window, once each (count first).

```text
    1x ERROR: General f:N at AngelCodeFont.parseFnt > AngelCodeFont failed to load page 0 texture E:/Project Zomboid/SteamApps/common/ProjectZomboid/media/mainfont_0.png
    1x ERROR: General f:N at AngelCodeFont.parseFnt > AngelCodeFont failed to load page 0 texture E:/Project Zomboid/SteamApps/common/ProjectZomboid/media/mainfont2_0.png
    1x ERROR: General f:N at AngelCodeFont.parseFnt > AngelCodeFont failed to load page 0 texture E:/Project Zomboid/SteamApps/common/ProjectZomboid/media/fonts/zomboidDialogue.bmfc_0.png
    3x ERROR: General f:N at FluidContainerScript.load > Sanitizing container name 'Large Bucket', name may not contain whitespaces.
    3x ERROR: General f:N at FluidContainerScript.load > Sanitizing container name 'Fuel Pump', name may not contain whitespaces.
    1x ERROR: General f:N at CraftRecipeComponentScript.getIconTexture> CraftRecipeComponentScript: Recipe Piano missing UiConfigScript - falling back to SpriteConfigScript first world object face for recipe icon.
    1x ERROR: Lua f:N at Lua(Vanilla).handleMannequinZone > ERROR: Mannequin zone missing properties in media/maps/Muldraugh, KY/objects.lua coords: 13583, 1299, 0
    1x ERROR: General f:N at Basements.mergeRoomsOntoMetaCell > duplicate RoomDef.metaID for room at 10707,9484,0
    1x ERROR: General f:N at IsoMetaGrid.load > invalid room metaID #231 in cell 25,33 while reading map_meta.bin
    1x ERROR: General f:N at IsoMetaGrid.load > invalid room metaID #327914 in cell 25,33 while reading map_meta.bin
    1x ERROR: General f:N at IsoMetaGrid.load > invalid room metaID #327911 in cell 25,33 while reading map_meta.bin
    1x ERROR: General f:N at IsoMetaGrid.load > invalid room metaID #655594 in cell 25,33 while reading map_meta.bin
    2x ERROR: General f:N at LuaManager.getFunctionObject > no such function "Vehicles.Init.Radio"
```
