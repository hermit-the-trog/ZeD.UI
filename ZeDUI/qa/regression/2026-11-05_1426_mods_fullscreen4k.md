# ZeD-UI regression - 2026-11-05 14:27 - fullscreen4k (3840x2160 fullscreen)

| | |
|---|---|
| Started | 2026-11-05 14:27:06 |
| Finished | 2026-11-05 14:32:04 (4 min 58 s) |
| Mode | fullscreen4k (3840x2160 fullscreen) |
| Display | fullScreen=true height=2160 width=3840 |
| Game build | 42.22.1 71e8410c42 attached (version.txt) |
| Mod version | 0.1.1242300k |
| Save | Saves/Sandbox/ZeD-QA |
| Manifest | C:/Users/danie/Zomboid/mods/ZeD-UI/ZeDUI/tools/qa/perf_spikes.txt (2 scripts) |
| Result | **2/2 pass**, 0 warn, 0 fail, 0 timeout |
| Go numbers | 21096 to 21099 |

Screenshots are in `C:/Users/danie/Zomboid/Screenshots` (the next run overwrites them). PASS: reached DONE with no ERR line and no Lua error. WARN: DONE with ERR lines of its own, or the script ran twice. FAIL: ok=false, a Java exception in the script's window (with -debug the game logs one even for an error a script catches) or the game lost. TIMEOUT: no DONE in time (the run stops there). Not run: after a timeout, a paused game or a lost game. "(expect ...)" prints are shown, not checked.

## Run notes

- ZeD settings: UI scale 1.75x (4K), additions Vanilla Plus (all on, Restock Casual) (the director's ModOptions.ini kept aside)
- pzrestorewin.ps1 (before a fullscreen run): no backup
- started ProjectZomboid64.exe -debug (fullscreen, the director's options.ini)
- loaded; clicked the screen centre (1920,1080) to pass 'click to start'
- the bridge armed in game on Saves/Sandbox/ZeD-QA
- quit: quit to the main menu, then to the desktop (go 21098, 21099)
- ZeD settings: the director's ModOptions.ini put back

## Results

| # | Script | Tag | Status | Seconds | Screenshots | Notes |
|---:|---|---|---|---:|---|---|
| 1 | zedqa_prelude.lua | pre | PASS | 2 |  |  |
| 2 | perf_spikes.lua | pks | PASS | 194 |  |  |

## Scripts

### 1. zedqa_prelude.lua (`ZEDQA pre`) - PASS, 2 s

- go 21096 at 14:28:19

```text
[ZeD.QA] state #1 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=45 missing=get
[ZeD.QA] windows reset (R)
ZEDQA pre start
[ZeD.QA] run #1 ok=true
ZEDQA pre char true world true speed 1 ticks 60 frames 61
ZEDQA pre search overlay: enabled false, override false, manager false
ZEDQA pre DONE
```

### 2. perf_spikes.lua (`ZEDQA pks`) - PASS, 194 s

- go 21097 at 14:28:24

```text
[ZeD.QA] state #2 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=45 missing=get
[ZeD.QA] windows reset (R)
[ZeD.QA] run #2 ok=true
ZEDQA pks scene shut, 787 elements timed
ZEDQA pks SPK shut t=712938 frame=36 lua=28 | EveryOneMinute closure 0x1226205146=27, ZeD_MoodleLayer:prerender=1
ZEDQA pks SPK shut t=716674 frame=34 lua=30 | EveryOneMinute closure 0x1226205146=30
ZEDQA pks SPK shut t=720413 frame=34 lua=27 | EveryOneMinute closure 0x1226205146=27
ZEDQA pks SPK shut t=724145 frame=34 lua=27 | EveryOneMinute closure 0x1226205146=27
ZEDQA pks SPK shut t=727890 frame=39 lua=30 | EveryOneMinute closure 0x1226205146=28, WaterMarkUI:render=1, ZeD_BeltHUD:prerender=1
ZEDQA pks SPK shut t=731630 frame=44 lua=35 | EveryOneMinute closure 0x1226205146=27, EveryTenMinutes closure 0x1295764434=4, OnTickEvenPaused closure 0x1421783688=2, ISButton:prerender=1, ZeD_Watch:prerender=1
ZEDQA pks SPK shut t=735360 frame=31 lua=28 | EveryOneMinute closure 0x1226205146=26, OnTick closure 0x1521982200=2
ZEDQA pks SPK shut t=739095 frame=34 lua=27 | EveryOneMinute closure 0x1226205146=27
ZEDQA pks SPK shut t=742837 frame=36 lua=26 | EveryOneMinute closure 0x1226205146=25, ZeD_BeltHUD:prerender=1
ZEDQA pks SPK shut t=746571 frame=37 lua=26 | EveryOneMinute closure 0x1226205146=26
ZEDQA pks SPK shut t=750310 frame=32 lua=25 | EveryOneMinute closure 0x1226205146=25
ZEDQA pks SPK shut t=754046 frame=35 lua=25 | EveryOneMinute closure 0x1226205146=25
ZEDQA pks SPK shut t=757780 frame=36 lua=26 | EveryOneMinute closure 0x1226205146=26
ZEDQA pks SPK shut t=761522 frame=37 lua=31 | EveryOneMinute closure 0x1226205146=27, OnPreUIDraw closure 0x140464827=2, ZeD_ActionBarLayer:prerender=1, ZeD_BeltHUD:prerender=1
ZEDQA pks SPK shut t=765252 frame=33 lua=25 | EveryOneMinute closure 0x1226205146=24, ZeD_Watch:prerender=1
ZEDQA pks SPK shut t=768998 frame=34 lua=29 | EveryOneMinute closure 0x1226205146=25, EveryTenMinutes closure 0x1295764434=2, OnTick closure 0x1741463957=2
ZEDQA pks RES shut frames=7153 spikes=16 worst=44
ZEDQA pks scene open, 821 elements timed
ZEDQA pks SPK open t=775909 frame=25 lua=12 | ZeD_Panel:prerender=9, ZeD_BeltHUD:prerender=2, ZeD_Window:prerender=1
ZEDQA pks SPK open t=776495 frame=29 lua=26 | EveryOneMinute closure 0x1226205146=26
ZEDQA pks SPK open t=780256 frame=38 lua=33 | EveryOneMinute closure 0x1226205146=25, ZeD_Panel:prerender=6, ZeD_Window:prerender=2
ZEDQA pks SPK open t=783996 frame=30 lua=27 | EveryOneMinute closure 0x1226205146=27
ZEDQA pks SPK open t=787742 frame=36 lua=32 | EveryOneMinute closure 0x1226205146=23, ZeD_Panel:prerender=4, OnTick closure 0x1741463957=2, ZeD_BeltHUD:prerender=1, ZeD_Window:prerender=1, ZeD_Watch:prerender=1
ZEDQA pks SPK open t=791251 frame=26 lua=14 | ZeD_Panel:prerender=9, ISButton:prerender=2, ZeD_Window:prerender=2, ISLabel:update=1
ZEDQA pks SPK open t=791517 frame=45 lua=39 | EveryOneMinute closure 0x1226205146=30, ZeD_Panel:prerender=7, ISEquippedItem:prerender=1, ZeD_Watch:prerender=1
ZEDQA pks SPK open t=792350 frame=25 lua=16 | ZeD_Panel:prerender=9, ISInventoryPage:update=2, ZeD_BeltHUD:prerender=2, OnPreUIDraw closure 0x140464827=2, ZeD_Window:update=1
ZEDQA pks SPK open t=795259 frame=44 lua=39 | EveryOneMinute closure 0x1226205146=39
ZEDQA pks SPK open t=798992 frame=35 lua=31 | EveryOneMinute closure 0x1226205146=25, ZeD_Panel:prerender=5, ZeD_BeltHUD:prerender=1
ZEDQA pks SPK open t=802744 frame=30 lua=26 | EveryOneMinute closure 0x1226205146=26
ZEDQA pks SPK open t=806493 frame=40 lua=35 | EveryOneMinute closure 0x1226205146=27, ZeD_Panel:prerender=6, ISButton:prerender=1, ZeD_Watch:prerender=1
ZEDQA pks SPK open t=806539 frame=46 lua=39 | EveryOneMinute closure 0x1226205146=25, ZeD_Panel:prerender=4, EveryHours closure 0x1950627263=4, EveryTenMinutes closure 0x1295764434=4, ZeD_Window:prerender=2
ZEDQA pks SPK open t=810248 frame=30 lua=25 | EveryOneMinute closure 0x1226205146=25
ZEDQA pks SPK open t=813946 frame=25 lua=18 | ZeD_Panel:prerender=17, WaterMarkUI:render=1
ZEDQA pks SPK open t=814005 frame=38 lua=34 | EveryOneMinute closure 0x1226205146=26, ZeD_Panel:prerender=4, ZeD_BeltHUD:prerender=2, ZeD_Watch:prerender=1, ZeD_Window:prerender=1
ZEDQA pks SPK open t=817747 frame=30 lua=24 | EveryOneMinute closure 0x1226205146=24
ZEDQA pks SPK open t=820199 frame=30 lua=18 | ZeD_Panel:prerender=11, ISLabel:update=2, ZeD_Window:prerender=2, ZeD_BeltHUD:prerender=1, ZeD_WindowOverlay:render=1, ZeD_MMOptions:update=1
ZEDQA pks SPK open t=821494 frame=37 lua=31 | EveryOneMinute closure 0x1226205146=25, ZeD_Panel:prerender=5, ZeD_BeltHUD:prerender=1
ZEDQA pks SPK open t=825245 frame=37 lua=31 | EveryOneMinute closure 0x1226205146=25, ZeD_Panel:prerender=5, ZeD_BeltHUD:prerender=1
ZEDQA pks SPK open t=828996 frame=30 lua=25 | EveryOneMinute closure 0x1226205146=25
ZEDQA pks SPK open t=832750 frame=33 lua=25 | EveryOneMinute closure 0x1226205146=25
ZEDQA pks RES open frames=5768 spikes=22 worst=46
ZEDQA pks scene shut2, 821 elements timed
ZEDQA pks SPK shut2 t=840222 frame=36 lua=29 | EveryOneMinute closure 0x1226205146=27, ZeD_BeltHUD:prerender=2
ZEDQA pks SPK shut2 t=843957 frame=39 lua=29 | EveryOneMinute closure 0x1226205146=27, EveryTenMinutes closure 0x1295764434=2
ZEDQA pks SPK shut2 t=847689 frame=37 lua=30 | EveryOneMinute closure 0x1226205146=29, WaterMarkUI:render=1
ZEDQA pks SPK shut2 t=851429 frame=34 lua=26 | EveryOneMinute closure 0x1226205146=26
ZEDQA pks SPK shut2 t=855162 frame=34 lua=27 | EveryOneMinute closure 0x1226205146=27
ZEDQA pks SPK shut2 t=858917 frame=48 lua=38 | EveryOneMinute closure 0x1226205146=33, ISButton:update=2, ZeD_BeltHUD:prerender=2, ISResizableButton:update=1
ZEDQA pks SPK shut2 t=862644 frame=34 lua=25 | EveryOneMinute closure 0x1226205146=25
ZEDQA pks SPK shut2 t=866378 frame=33 lua=27 | EveryOneMinute closure 0x1226205146=27
ZEDQA pks SPK shut2 t=870111 frame=33 lua=26 | EveryOneMinute closure 0x1226205146=26
ZEDQA pks SPK shut2 t=873854 frame=36 lua=27 | EveryOneMinute closure 0x1226205146=27
ZEDQA pks SPK shut2 t=877588 frame=37 lua=28 | EveryOneMinute closure 0x1226205146=28
ZEDQA pks SPK shut2 t=881322 frame=35 lua=29 | EveryOneMinute closure 0x1226205146=26, EveryTenMinutes closure 0x1295764434=3
ZEDQA pks SPK shut2 t=885062 frame=31 lua=26 | EveryOneMinute closure 0x1226205146=26
ZEDQA pks SPK shut2 t=888797 frame=36 lua=30 | EveryOneMinute closure 0x1226205146=28, OnTick closure 0x90735674=2
ZEDQA pks SPK shut2 t=892533 frame=38 lua=31 | EveryOneMinute closure 0x1226205146=31
ZEDQA pks SPK shut2 t=896269 frame=34 lua=27 | EveryOneMinute closure 0x1226205146=25, ZeD_ActionBarLayer:prerender=2
ZEDQA pks RES shut2 frames=7146 spikes=16 worst=48
ZEDQA pks DONE
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
    1x ERROR: Lua f:N at KahluaThread.pcall > Lua code called from the wrong thread, owner=GameLoadingThread current=MainThread
    1x ERROR: Lua f:N at Lua(Vanilla).handleMannequinZone > ERROR: Mannequin zone missing properties in media/maps/Muldraugh, KY/objects.lua coords: 13583, 1299, 0
    1x ERROR: General f:N at Basements.mergeRoomsOntoMetaCell > duplicate RoomDef.metaID for room at 10707,9484,0
    1x ERROR: General f:N at IsoMetaGrid.load > invalid room metaID #231 in cell 25,33 while reading map_meta.bin
    1x ERROR: General f:N at IsoMetaGrid.load > invalid room metaID #327914 in cell 25,33 while reading map_meta.bin
    1x ERROR: General f:N at IsoMetaGrid.load > invalid room metaID #327911 in cell 25,33 while reading map_meta.bin
    1x ERROR: General f:N at IsoMetaGrid.load > invalid room metaID #655594 in cell 25,33 while reading map_meta.bin
    2x ERROR: General f:N at LuaManager.getFunctionObject > no such function "Vehicles.Init.Radio"
```
