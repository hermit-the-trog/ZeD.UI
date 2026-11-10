# ZeD-UI regression - 2026-11-09 17:32 - fullscreen4k (3840x2160 fullscreen)

| | |
|---|---|
| Started | 2026-11-09 17:32:37 |
| Finished | 2026-11-09 17:34:55 (2 min 18 s) |
| Mode | fullscreen4k (3840x2160 fullscreen) |
| Display | fullScreen=true height=2160 width=3840 |
| Game build | 42.22.2 3d39148846 |
| Mod version | 0.3.0-beta11 |
| Save | Saves/Sandbox/ZeD-QA |
| Manifest | %USERPROFILE%\Zomboid\mods\ZeD-UI\ZeDUI\tools\qa\rui_manifest.txt (2 scripts) |
| Result | **2/2 pass**, 0 warn, 0 fail, 0 timeout |
| Go numbers | 24536 to 24539 |

Screenshots are in `%USERPROFILE%/Zomboid/Screenshots` (the next run overwrites them). PASS: reached DONE with no ERR line and no Lua error. WARN: DONE with ERR lines of its own, or the script ran twice. FAIL: ok=false, a Java exception in the script's window (with -debug the game logs one even for an error a script catches) or the game lost. TIMEOUT: no DONE in time (the run stops there). Not run: after a timeout, a paused game or a lost game. "(expect ...)" prints are shown, not checked.

## Run notes

- ZeD settings: UI scale 1.75x (4K), additions Vanilla Plus (all on, Restock Casual) (the director's ModOptions.ini kept aside)
- pzrestorewin.ps1 (before a fullscreen run): no backup
- started ProjectZomboid64.exe -debug -nosteam (fullscreen, the director's options.ini)
- loaded; clicked the screen centre (1920,1080) to pass 'click to start'
- the bridge armed in game on Saves/Sandbox/ZeD-QA
- quit: quit to the main menu, then to the desktop (go 24538, 24539)
- ZeD settings: the director's ModOptions.ini put back

## Results

| # | Script | Tag | Status | Seconds | Screenshots | Notes |
|---:|---|---|---|---:|---|---|
| 1 | zedqa_prelude.lua | pre | PASS | 2 |  |  |
| 2 | zedqa_responsiveui.lua | rui | PASS | 41 | zqa_rui_live_strip_on.png, zqa_rui_live_strip_off.png, zqa_rui_live_strip_back.png, zqa_rui_live_list_on.png, zqa_rui_live_list_off.png, zqa_rui_live_list_back.png, zqa_rui_keep_strip.png, zqa_rui_putin.png, zqa_rui_keep_list.png, zqa_rui_esc_list.png, zqa_rui_esc_strip.png, zqa_rui_tick_before.png, zqa_rui_tick_after.png |  |

## Scripts

### 1. zedqa_prelude.lua (`ZEDQA pre`) - PASS, 2 s

- go 24536 at 17:33:44

```text
[ZeD.QA] state #1 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=39 missing=get
[ZeD.QA] windows reset (R)
ZEDQA pre start
[ZeD.QA] run #1 ok=true
ZEDQA pre char true world true speed 1 ticks 60 frames 61
ZEDQA pre search overlay: enabled false, override false, manager false
ZEDQA pre DONE
```

### 2. zedqa_responsiveui.lua (`ZEDQA rui`) - PASS, 41 s

- go 24537 at 17:33:50
- screenshots: zqa_rui_live_strip_on.png, zqa_rui_live_strip_off.png, zqa_rui_live_strip_back.png, zqa_rui_live_list_on.png, zqa_rui_live_list_off.png, zqa_rui_live_list_back.png, zqa_rui_keep_strip.png, zqa_rui_putin.png, zqa_rui_keep_list.png, zqa_rui_esc_list.png, zqa_rui_esc_strip.png, zqa_rui_tick_before.png, zqa_rui_tick_after.png

```text
[ZeD.QA] state #2 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=39 missing=get
[ZeD.QA] windows reset (R)
[ZeD.QA] run #2 ok=true
ZEDQA rui ResponsiveUI loaded true, ZeD support true
ZEDQA rui start: swept 0 test crate(s)
ZEDQA rui crate 931,13040
ZEDQA rui PASS LIVE strip: the menu is open with the ZEDQA live row
ZEDQA rui PASS LIVE strip: the row is greyed with the flag ON
ZEDQA rui PASS LIVE strip: the row is live after the flag went OFF
ZEDQA rui PASS LIVE strip: the SAME ZeD menu is still open after the refresh
ZEDQA rui PASS LIVE strip: the menu stayed at the same position
ZEDQA rui PASS LIVE strip: the selection stayed on the row
ZEDQA rui PASS LIVE strip: the row is greyed again with the flag back ON
ZEDQA rui PASS LIVE strip: still the same menu after the second flip
ZEDQA rui PASS LIVE strip: the selection is still on the row
ZEDQA rui LIVE strip: greyed true -> false -> true, same menu true, selected true
ZEDQA rui PASS LIVE list: the menu is open with the ZEDQA live row
ZEDQA rui PASS LIVE list: the row is greyed with the flag ON
ZEDQA rui PASS LIVE list: the row is live after the flag went OFF
ZEDQA rui PASS LIVE list: the SAME ZeD menu is still open after the refresh
ZEDQA rui PASS LIVE list: the menu stayed at the same position
ZEDQA rui PASS LIVE list: the selection stayed on the row
ZEDQA rui PASS LIVE list: the row is greyed again with the flag back ON
ZEDQA rui PASS LIVE list: still the same menu after the second flip
ZEDQA rui PASS LIVE list: the selection is still on the row
ZEDQA rui LIVE list: greyed true -> false -> true, same menu true, selected true
ZEDQA rui READ spot none indoors, night set
ZEDQA rui READ dark at night: false
ZEDQA rui INFO READ: never dark here (lights)
ZEDQA rui INFO READ: no menu to check by day
ZEDQA rui PASS KEEP strip: the pick counted once and the strip stayed open
ZEDQA rui KEEP strip after the pick (expect keep-open (1), same, open): ZeD menu ZeD_ContextMenu same true open true at 1572,745 | Read 1 greyed false | selected ZEDQA keep-open (1) | Put in false | keep true
ZEDQA rui KEEP strip after the pick (expect keep-open (1), same, open): dark false, loot pane floor, the mod watching true
ZEDQA rui PASS PUTIN before: no Put in Container with the crate 6 tiles off
ZEDQA rui PASS PUTIN: Put in Container appeared in the same open menu
ZEDQA rui PUTIN beside the container: ZeD menu ZeD_ContextMenu same true open true at 1572,745 | Read 1 greyed false | selected ZEDQA keep-open (1) | Put in true | keep true
ZEDQA rui PUTIN beside the container: dark false, loot pane crate, the mod watching true
ZEDQA rui KEEP list submenu open true
ZEDQA rui PASS KEEP list: the pick counted (2) and the submenu stayed open in the same menu
ZEDQA rui KEEP list after the pick (expect same, open, 2 levels, (2) sub): same true open true levels 2 row ZEDQA keep-open (2) sub
ZEDQA rui PASS ESC list: the keep-open pick left the menu open in its submenu
ZEDQA rui ESC: game menu visible true, mod handler reachable true, Main Menu key is ESC true
ZEDQA rui ESC: the mod's handler ran true
ZEDQA rui ESC list: ZeD menu open false (the one held false), game menu visible false
ZEDQA rui PASS ESC list: ZeD's menu closed on Escape
ZEDQA rui PASS ESC strip: the keep-open pick left the menu open in its submenu
ZEDQA rui ESC: game menu visible true, mod handler reachable true, Main Menu key is ESC true
ZEDQA rui ESC: the mod's handler ran true
ZEDQA rui ESC strip: ZeD menu open false (the one held false), game menu visible false
ZEDQA rui PASS ESC strip: ZeD's menu closed on Escape
ZEDQA rui PASS TICK: the Lists pop-up is open with the test list unticked
ZEDQA rui PASS TICK: the same pop-up is still open after the press
ZEDQA rui PASS TICK: the row's tick flipped on
ZEDQA rui PASS TICK: pressed again, still open and ticked back off
ZEDQA rui TICK check false -> true -> false
ZEDQA rui TICK test list removed
ZEDQA rui end: swept 0 test crate(s)
ZEDQA rui put back: style 1, time, place, book, crate
ZEDQA rui RESULT 30 pass, 0 fail
ZEDQA rui DONE
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
