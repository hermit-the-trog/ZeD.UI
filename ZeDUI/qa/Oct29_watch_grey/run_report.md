# ZeD-UI regression - 2026-10-29 21:22 - fullscreen4k (3840x2160 fullscreen)

| | |
|---|---|
| Started | 2026-10-29 21:22:35 |
| Finished | 2026-10-29 21:26:33 (3 min 58 s) |
| Mode | fullscreen4k (3840x2160 fullscreen) |
| Display | fullScreen=true height=2160 width=3840 |
| Game build | 42.22.0 e013dbb529 |
| Mod version | 0.1.1242300k |
| Save | Saves/Sandbox/ZeD-QA |
| Manifest | ZeDUI/tools/qa/watch_grey.txt (2 scripts) |
| Result | **2/2 pass**, 0 warn, 0 fail, 0 timeout |
| Go numbers | 16070 to 16073 |

Screenshots are in `C:/Users/danie/Zomboid/Screenshots` (the next run overwrites them). PASS: reached DONE with no ERR line and no Lua error. WARN: DONE with ERR lines of its own, or the script ran twice. FAIL: ok=false, a Java exception in the script's window (with -debug the game logs one even for an error a script catches) or the game lost. TIMEOUT: no DONE in time (the run stops there). Not run: after a timeout, a paused game or a lost game. "(expect ...)" prints are shown, not checked.

## Run notes

- ZeD settings: UI scale 1.75x (4K) (the director's ModOptions.ini kept aside)
- pzrestorewin.ps1 (before a fullscreen run): no backup
- started ProjectZomboid64.exe -debug (fullscreen, the director's options.ini)
- loaded; clicked the screen centre (1920,1080) to pass 'click to start'
- the bridge armed in game on Saves/Sandbox/ZeD-QA
- quit: quit to the main menu, then to the desktop (go 16072, 16073)
- ZeD settings: the director's ModOptions.ini put back

## Results

| # | Script | Tag | Status | Seconds | Screenshots | Notes |
|---:|---|---|---|---:|---|---|
| 1 | zedqa_prelude.lua | pre | PASS | 1 |  |  |
| 2 | zedqa_watch_grey.lua | wgrey | PASS | 124 | zqa_wg_day_digital_black.png, zqa_wg_night_digital_black.png, zqa_wg_nightbulb_digital_black.png, zqa_wg_daybulb_digital_black.png, zqa_wg_set_digital_black.png, zqa_wg_setnight_digital_black.png, zqa_wg_day_digital_gold.png, zqa_wg_night_digital_gold.png, zqa_wg_nightbulb_digital_gold.png, zqa_wg_daybulb_digital_gold.png, zqa_wg_set_digital_gold.png, zqa_wg_day_classic_black.png, zqa_wg_night_classic_black.png, zqa_wg_nightbulb_classic_black.png, zqa_wg_daybulb_classic_black.png, zqa_wg_set_classic_black.png, zqa_wg_setnight_classic_black.png, zqa_wg_day_classic_gold.png, zqa_wg_night_classic_gold.png, zqa_wg_nightbulb_classic_gold.png, zqa_wg_daybulb_classic_gold.png, zqa_wg_set_classic_gold.png, zqa_wg_day_timez_red.png, zqa_wg_night_timez_red.png, zqa_wg_glow_timez_red.png, zqa_wg_set_timez_red.png, zqa_wg_day_timez_steel.png, zqa_wg_night_timez_steel.png, zqa_wg_glow_timez_steel.png, zqa_wg_set_timez_steel.png, zqa_wg_day_timez_easy.png, zqa_wg_night_timez_easy.png, zqa_wg_set_timez_easy.png, zqa_wg_day_timez_camper.png, zqa_wg_night_timez_camper.png, zqa_wg_set_timez_camper.png, zqa_wg_day_expensive.png, zqa_wg_night_expensive.png, zqa_wg_set_expensive.png, zqa_wg_minyday_digital_black.png, zqa_wg_minynight_digital_black.png, zqa_wg_minylit_digital_black.png, zqa_wg_minyday_digital_gold.png, zqa_wg_minynight_digital_gold.png, zqa_wg_minylit_digital_gold.png, zqa_wg_minyday_classic_black.png, zqa_wg_minynight_classic_black.png, zqa_wg_minylit_classic_black.png, zqa_wg_minyday_classic_gold.png, zqa_wg_minynight_classic_gold.png, zqa_wg_minylit_classic_gold.png, zqa_wg_minyday_timez_red.png, zqa_wg_minynight_timez_red.png, zqa_wg_minylit_timez_red.png, zqa_wg_minyday_timez_steel.png, zqa_wg_minynight_timez_steel.png, zqa_wg_minylit_timez_steel.png, zqa_wg_minyday_timez_easy.png, zqa_wg_minynight_timez_easy.png, zqa_wg_minyday_timez_camper.png, zqa_wg_minynight_timez_camper.png, zqa_wg_minyday_expensive.png, zqa_wg_minynight_expensive.png |  |

## Scripts

### 1. zedqa_prelude.lua (`ZEDQA pre`) - PASS, 1 s

- go 16070 at 21:23:48

```text
[ZeD.QA] windows reset (R)
ZEDQA pre start
[ZeD.QA] run #1 ok=true
ZEDQA pre char true world true speed 1 ticks 60 frames 61
ZEDQA pre search overlay: enabled false, override false, manager false
ZEDQA pre DONE
```

### 2. zedqa_watch_grey.lua (`ZEDQA wgrey`) - PASS, 124 s

- go 16071 at 21:23:52
- screenshots: zqa_wg_day_digital_black.png, zqa_wg_night_digital_black.png, zqa_wg_nightbulb_digital_black.png, zqa_wg_daybulb_digital_black.png, zqa_wg_set_digital_black.png, zqa_wg_setnight_digital_black.png, zqa_wg_day_digital_gold.png, zqa_wg_night_digital_gold.png, zqa_wg_nightbulb_digital_gold.png, zqa_wg_daybulb_digital_gold.png, zqa_wg_set_digital_gold.png, zqa_wg_day_classic_black.png, zqa_wg_night_classic_black.png, zqa_wg_nightbulb_classic_black.png, zqa_wg_daybulb_classic_black.png, zqa_wg_set_classic_black.png, zqa_wg_setnight_classic_black.png, zqa_wg_day_classic_gold.png, zqa_wg_night_classic_gold.png, zqa_wg_nightbulb_classic_gold.png, zqa_wg_daybulb_classic_gold.png, zqa_wg_set_classic_gold.png, zqa_wg_day_timez_red.png, zqa_wg_night_timez_red.png, zqa_wg_glow_timez_red.png, zqa_wg_set_timez_red.png, zqa_wg_day_timez_steel.png, zqa_wg_night_timez_steel.png, zqa_wg_glow_timez_steel.png, zqa_wg_set_timez_steel.png, zqa_wg_day_timez_easy.png, zqa_wg_night_timez_easy.png, zqa_wg_set_timez_easy.png, zqa_wg_day_timez_camper.png, zqa_wg_night_timez_camper.png, zqa_wg_set_timez_camper.png, zqa_wg_day_expensive.png, zqa_wg_night_expensive.png, zqa_wg_set_expensive.png, zqa_wg_minyday_digital_black.png, zqa_wg_minynight_digital_black.png, zqa_wg_minylit_digital_black.png, zqa_wg_minyday_digital_gold.png, zqa_wg_minynight_digital_gold.png, zqa_wg_minylit_digital_gold.png, zqa_wg_minyday_classic_black.png, zqa_wg_minynight_classic_black.png, zqa_wg_minylit_classic_black.png, zqa_wg_minyday_classic_gold.png, zqa_wg_minynight_classic_gold.png, zqa_wg_minylit_classic_gold.png, zqa_wg_minyday_timez_red.png, zqa_wg_minynight_timez_red.png, zqa_wg_minylit_timez_red.png, zqa_wg_minyday_timez_steel.png, zqa_wg_minynight_timez_steel.png, zqa_wg_minylit_timez_steel.png, zqa_wg_minyday_timez_easy.png, zqa_wg_minynight_timez_easy.png, zqa_wg_minyday_timez_camper.png, zqa_wg_minynight_timez_camper.png, zqa_wg_minyday_expensive.png, zqa_wg_minynight_expensive.png

```text
[ZeD.QA] windows reset (R)
ZEDQA wgrey start
[ZeD.QA] run #2 ok=true
ZEDQA wgrey own watch nil at base:leftwrist
ZEDQA wgrey digital_black plate digital_black 248x352 lit=false bulb=false dark=false
ZEDQA wgrey RECT day_digital_black 3576 10 248 352
ZEDQA wgrey digital_black night lit=false bulb=false dark=true
ZEDQA wgrey RECT night_digital_black 3576 10 248 352
ZEDQA wgrey digital_black night bulb lit=false bulb=true dark=true
ZEDQA wgrey RECT nightbulb_digital_black 3576 10 248 352
ZEDQA wgrey digital_black day bulb lit=false bulb=true dark=false
ZEDQA wgrey RECT daybulb_digital_black 3576 10 248 352
ZEDQA wgrey digital_black setting open=true alarm true hour 1
ZEDQA wgrey RECT set_digital_black 3576 10 248 352
ZEDQA wgrey digital_black setting at night lit=false bulb=false dark=true
ZEDQA wgrey RECT setnight_digital_black 3576 10 248 352
ZEDQA wgrey digital_gold plate digital_gold 248x352 lit=false bulb=false dark=false
ZEDQA wgrey RECT day_digital_gold 3576 10 248 352
ZEDQA wgrey digital_gold night lit=false bulb=false dark=true
ZEDQA wgrey RECT night_digital_gold 3576 10 248 352
ZEDQA wgrey digital_gold night bulb lit=false bulb=true dark=true
ZEDQA wgrey RECT nightbulb_digital_gold 3576 10 248 352
ZEDQA wgrey digital_gold day bulb lit=false bulb=true dark=false
ZEDQA wgrey RECT daybulb_digital_gold 3576 10 248 352
ZEDQA wgrey digital_gold setting open=true alarm true hour 1
ZEDQA wgrey RECT set_digital_gold 3576 10 248 352
ZEDQA wgrey classic_black plate classic_black 300x352 lit=false bulb=false dark=false
ZEDQA wgrey RECT day_classic_black 3524 10 300 352
ZEDQA wgrey classic_black night lit=false bulb=false dark=true
ZEDQA wgrey RECT night_classic_black 3524 10 300 352
ZEDQA wgrey classic_black night bulb lit=false bulb=true dark=true
ZEDQA wgrey RECT nightbulb_classic_black 3524 10 300 352
ZEDQA wgrey classic_black day bulb lit=false bulb=true dark=false
ZEDQA wgrey RECT daybulb_classic_black 3524 10 300 352
ZEDQA wgrey classic_black setting open=true alarm true hour 1
ZEDQA wgrey RECT set_classic_black 3524 10 300 352
ZEDQA wgrey classic_black setting at night lit=false bulb=false dark=true
ZEDQA wgrey RECT setnight_classic_black 3524 10 300 352
ZEDQA wgrey classic_gold plate classic_gold 300x352 lit=false bulb=false dark=false
ZEDQA wgrey RECT day_classic_gold 3524 10 300 352
ZEDQA wgrey classic_gold night lit=false bulb=false dark=true
ZEDQA wgrey RECT night_classic_gold 3524 10 300 352
ZEDQA wgrey classic_gold night bulb lit=false bulb=true dark=true
ZEDQA wgrey RECT nightbulb_classic_gold 3524 10 300 352
ZEDQA wgrey classic_gold day bulb lit=false bulb=true dark=false
ZEDQA wgrey RECT daybulb_classic_gold 3524 10 300 352
ZEDQA wgrey classic_gold setting open=true alarm true hour 1
ZEDQA wgrey RECT set_classic_gold 3524 10 300 352
ZEDQA wgrey timez_red plate timez_red 248x352 lit=false bulb=false dark=false
ZEDQA wgrey RECT day_timez_red 3576 10 248 352
ZEDQA wgrey timez_red night lit=false bulb=false dark=true
ZEDQA wgrey RECT night_timez_red 3576 10 248 352
ZEDQA wgrey timez_red glow lit=true bulb=false dark=false
ZEDQA wgrey RECT glow_timez_red 3576 10 248 352
ZEDQA wgrey timez_red setting open=true alarm true hour 1
ZEDQA wgrey RECT set_timez_red 3576 10 248 352
ZEDQA wgrey timez_steel plate timez_steel 248x352 lit=false bulb=false dark=false
ZEDQA wgrey RECT day_timez_steel 3576 10 248 352
ZEDQA wgrey timez_steel night lit=false bulb=false dark=true
ZEDQA wgrey RECT night_timez_steel 3576 10 248 352
ZEDQA wgrey timez_steel glow lit=true bulb=false dark=false
ZEDQA wgrey RECT glow_timez_steel 3576 10 248 352
ZEDQA wgrey timez_steel setting open=true alarm true hour 1
ZEDQA wgrey RECT set_timez_steel 3576 10 248 352
ZEDQA wgrey timez_easy plate timez_easy 300x352 lit=false bulb=false dark=false
ZEDQA wgrey RECT day_timez_easy 3524 10 300 352
ZEDQA wgrey timez_easy night lit=false bulb=false dark=true
ZEDQA wgrey RECT night_timez_easy 3524 10 300 352
ZEDQA wgrey timez_easy setting open=true alarm true hour 1
ZEDQA wgrey RECT set_timez_easy 3524 10 300 352
ZEDQA wgrey timez_camper plate timez_camper 300x352 lit=false bulb=false dark=false
ZEDQA wgrey RECT day_timez_camper 3524 10 300 352
ZEDQA wgrey timez_camper night lit=false bulb=false dark=true
ZEDQA wgrey RECT night_timez_camper 3524 10 300 352
ZEDQA wgrey timez_camper setting open=true alarm true hour 1
ZEDQA wgrey RECT set_timez_camper 3524 10 300 352
ZEDQA wgrey expensive plate expensive 300x352 lit=false bulb=false dark=false
ZEDQA wgrey RECT day_expensive 3524 10 300 352
ZEDQA wgrey expensive night lit=false bulb=false dark=true
ZEDQA wgrey RECT night_expensive 3524 10 300 352
ZEDQA wgrey expensive setting open=true alarm true hour 1
ZEDQA wgrey RECT set_expensive 3524 10 300 352
ZEDQA wgrey digital_black mini box digital_black 88x92
ZEDQA wgrey RECT minyday_digital_black 1433 2037 88 92
ZEDQA wgrey RECT minynight_digital_black 1433 2037 88 92
ZEDQA wgrey digital_black mini lit=true bulb=nil dark=false
ZEDQA wgrey RECT minylit_digital_black 1433 2037 88 92
ZEDQA wgrey digital_gold mini box digital_gold 88x92
ZEDQA wgrey RECT minyday_digital_gold 1433 2037 88 92
ZEDQA wgrey RECT minynight_digital_gold 1433 2037 88 92
ZEDQA wgrey digital_gold mini lit=true bulb=nil dark=false
ZEDQA wgrey RECT minylit_digital_gold 1433 2037 88 92
ZEDQA wgrey classic_black mini box classic_black 88x92
ZEDQA wgrey RECT minyday_classic_black 1433 2037 88 92
ZEDQA wgrey RECT minynight_classic_black 1433 2037 88 92
ZEDQA wgrey classic_black mini lit=true bulb=nil dark=false
ZEDQA wgrey RECT minylit_classic_black 1433 2037 88 92
ZEDQA wgrey classic_gold mini box classic_gold 88x92
ZEDQA wgrey RECT minyday_classic_gold 1433 2037 88 92
ZEDQA wgrey RECT minynight_classic_gold 1433 2037 88 92
ZEDQA wgrey classic_gold mini lit=true bulb=nil dark=false
ZEDQA wgrey RECT minylit_classic_gold 1433 2037 88 92
ZEDQA wgrey timez_red mini box timez_red 88x92
ZEDQA wgrey RECT minyday_timez_red 1433 2037 88 92
ZEDQA wgrey RECT minynight_timez_red 1433 2037 88 92
ZEDQA wgrey timez_red mini lit=true bulb=nil dark=false
ZEDQA wgrey RECT minylit_timez_red 1433 2037 88 92
ZEDQA wgrey timez_steel mini box timez_steel 88x92
ZEDQA wgrey RECT minyday_timez_steel 1433 2037 88 92
ZEDQA wgrey RECT minynight_timez_steel 1433 2037 88 92
ZEDQA wgrey timez_steel mini lit=true bulb=nil dark=false
ZEDQA wgrey RECT minylit_timez_steel 1433 2037 88 92
ZEDQA wgrey timez_easy mini box timez_easy 88x92
ZEDQA wgrey RECT minyday_timez_easy 1433 2037 88 92
ZEDQA wgrey RECT minynight_timez_easy 1433 2037 88 92
ZEDQA wgrey timez_camper mini box timez_camper 88x92
ZEDQA wgrey RECT minyday_timez_camper 1433 2037 88 92
ZEDQA wgrey RECT minynight_timez_camper 1433 2037 88 92
ZEDQA wgrey expensive mini box expensive 88x92
ZEDQA wgrey RECT minyday_expensive 1433 2037 88 92
ZEDQA wgrey RECT minynight_expensive 1433 2037 88 92
ZEDQA wgrey restored own watch nil
ZEDQA wgrey DONE
```

## Console errors outside scripts

ERROR lines from launch to quit that fall in no script's window, once each (count first).

```text
    1x ERROR: General f:N at AngelCodeFont.parseFnt > AngelCodeFont failed to load page 0 texture E:/Project Zomboid/SteamApps/common/ProjectZomboid/media/mainfont_0.png
    1x ERROR: General f:N at AngelCodeFont.parseFnt > AngelCodeFont failed to load page 0 texture E:/Project Zomboid/SteamApps/common/ProjectZomboid/media/mainfont2_0.png
    1x ERROR: General f:N at AngelCodeFont.parseFnt > AngelCodeFont failed to load page 0 texture E:/Project Zomboid/SteamApps/common/ProjectZomboid/media/fonts/zomboidDialogue.bmfc_0.png
    3x ERROR: Mod f:N at ChooseGameInfo.readModInfoAux > tiledef=SupportCorps 8900 file number must be from 100 to 8189
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
