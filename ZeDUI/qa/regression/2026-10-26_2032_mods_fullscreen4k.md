# ZeD-UI regression - 2026-10-26 20:32 - fullscreen4k (3840x2160 fullscreen)

| | |
|---|---|
| Started | 2026-10-26 20:32:31 |
| Finished | 2026-10-26 20:35:32 (3 min 1 s) |
| Mode | fullscreen4k (3840x2160 fullscreen) |
| Display | fullScreen=true height=2160 width=3840 |
| Game build | 42.21.0 4a0e9546ec |
| Mod version | 0.1.1242300k |
| Save | Saves/Sandbox/ZeD-QA |
| Manifest | C:\Users\danie\Zomboid\mods\ZeD-UI\ZeDUI\tools\qa\compat_r3_D2.txt (2 scripts) |
| Result | **1/2 pass**, 0 warn, 1 fail, 0 timeout |
| Go numbers | 13761 to 13764 |

Screenshots are in `C:/Users/danie/Zomboid/Screenshots` (the next run overwrites them). PASS: reached DONE with no ERR line and no Lua error. WARN: DONE with ERR lines of its own, or the script ran twice. FAIL: ok=false, a Java exception in the script's window (with -debug the game logs one even for an error a script catches) or the game lost. TIMEOUT: no DONE in time (the run stops there). Not run: after a timeout, a paused game or a lost game. "(expect ...)" prints are shown, not checked.

## Run notes

- ZeD settings: UI scale 1.75x (4K) (the director's ModOptions.ini kept aside)
- pzrestorewin.ps1 (before a fullscreen run): no backup
- started ProjectZomboid64.exe -debug (fullscreen, the director's options.ini)
- loaded; clicked the screen centre (1920,1080) to pass 'click to start'
- the bridge armed in game on Saves/Sandbox/ZeD-QA
- quit: quit to the main menu, then to the desktop (go 13763, 13764)
- ZeD settings: the director's ModOptions.ini put back

## Results

| # | Script | Tag | Status | Seconds | Screenshots | Notes |
|---:|---|---|---|---:|---|---|
| 1 | zedqa_prelude.lua | pre | PASS | 1 |  |  |
| 2 | zedqa_r3_D_cars2.lua | cv | **FAIL** | 28 | zqa_r3D_cv_1_tab.png, zqa_r3D_cv_2_tab.png, zqa_r3D_cv_3_dash.png, zqa_r3D_cv_3_tab.png | 1 Java exception(s) in the log |

## Scripts

### 1. zedqa_prelude.lua (`ZEDQA pre`) - PASS, 1 s

- go 13761 at 20:34:22

```text
:	[ZeD.QA] windows reset (R)
:	ZEDQA pre start
:	[ZeD.QA] run #1 ok=true
:	ZEDQA pre char true world true speed 1 ticks 60 frames 61
:	ZEDQA pre search overlay: enabled false, override false, manager false
:	ZEDQA pre DONE
```

### 2. zedqa_r3_D_cars2.lua (`ZEDQA cv`) - FAIL, 28 s

- go 13762 at 20:34:27
- 1 Java exception(s) in the log
- screenshots: zqa_r3D_cv_1_tab.png, zqa_r3D_cv_2_tab.png, zqa_r3D_cv_3_dash.png, zqa_r3D_cv_3_tab.png

```text
:	[ZeD.QA] windows reset (R)
:	ZEDQA cv modded vehicle scripts: 3 to try, from 2 Workshop items
:	ZEDQA cv start
:	[ZeD.QA] run #2 ok=true
ERROR: General f:793 at LuaManager.getFunctionObject > no such function "Vehicles.Init.Radio"
ERROR: General f:799 at LuaManager.getFunctionObject > no such function "Vehicles.Init.Radio"
:	ZEDQA cv PASS 3402493701 Base.TrailerHome: spawns
:	ZEDQA cv 3402493701 Base.TrailerHome: Vehicle tab true, 37 parts
:	ZEDQA cv PASS 3402493701 Base.TrailerHome: the World window's Vehicle tab opens beside it
:	ZEDQA cv ui Base.TrailerHome vehicle tab: ZeD_ActionBarLayer@0,0,1x1 ; UIDebugConsole@20,1848,1280x292 ; MoodlesUI@3782,1080,48x2160 ; ISButtonPrompt@0,0,1x1 ; ISEquippedItem@10,10,53x621 ; ISHotbar@-10000,-10000,256x82 ; NeatXPBar@3480,180,204x57 ; WaterMarkUI@3604,2127,226x22 ; ZeD_BeltHUD@1438,2041,772x91 ; ZeD_MoodleLayer@3782,1080,48x2160 ; ZeD_Watch@3596,10,228x52 ; ZeD_Window@1134,0,777x735 ; ZeD_Window@1929,0,1617x735 ; ZeD_MessagesToasts@0,0,1x1
:	ZEDQA cv PASS 3402493701 Base.TrailerKbac: spawns
ERROR: General f:1420 at KahluaThread.flushErrorMessage > -------------------------------------------------------------
    attempted index: setContainerContentAmount of non-table: null
ERROR: General f:1420> Lua(Vanilla).pcall> Exception thrown
    java.lang.RuntimeException: attempted index: setContainerContentAmount of non-table: null at KahluaThread.tableget(KahluaThread.java:1430).
    Lua(Vanilla).pcall(spawnpoints.lua:121)
    Lua(Vanilla).t(spawnpoints.lua:121)
    Lua(Vanilla).tick(spawnpoints.lua:177)
:	ZEDQA cv 3402493701 Base.TrailerKbac: Vehicle tab true, 7 parts
:	ZEDQA cv PASS 3402493701 Base.TrailerKbac: the World window's Vehicle tab opens beside it
:	ZEDQA cv ui Base.TrailerKbac vehicle tab: ZeD_ActionBarLayer@0,0,1x1 ; UIDebugConsole@20,1848,1280x292 ; MoodlesUI@3782,1080,48x2160 ; ISButtonPrompt@0,0,1x1 ; ISEquippedItem@10,10,53x621 ; ISHotbar@-10000,-10000,256x82 ; NeatXPBar@3480,180,204x57 ; WaterMarkUI@3604,2127,226x22 ; ZeD_BeltHUD@1438,2041,853x91 ; ZeD_MoodleLayer@3782,1080,48x2160 ; ZeD_Watch@3596,10,228x52 ; ZeD_Window@1134,0,777x735 ; ZeD_Window@1929,0,1617x735 ; ZeD_MessagesToasts@3122,263,595x53 ; ISButton@3813,2051,22x22
:	ZEDQA cv PASS 3554424111 Base.M998_Humvee: spawns
:	ZEDQA cv 3554424111 Base.M998_Humvee: design nyala, dashboard true at 1120,1804 1600x344
:	ZEDQA cv PASS 3554424111 Base.M998_Humvee: the dashboard shows with a design
:	ZEDQA cv PASS 3554424111 Base.M998_Humvee: the dashboard is on screen
:	ZEDQA cv ui Base.M998_Humvee seated: ZeD_ActionBarLayer@0,0,1x1 ; SpeedControls@3641,-4000,189x28 ; UIDebugConsole@20,1848,1280x292 ; MoodlesUI@3782,1080,48x2160 ; ISButtonPrompt@0,0,1x1 ; ISEquippedItem@10,10,53x621 ; NeatXPBar@3480,180,204x57 ; WaterMarkUI@3604,2127,226x22 ; ZeD_Dashboard@1120,1804,1600x344 ; ZeD_MoodleLayer@3782,1080,48x2160 ; ZeD_Watch@3596,10,228x52 ; ZeD_Window@1134,0,777x735 ; ZeD_Window@1929,0,777x735 ; ZeD_MessagesToasts@3122,263,595x53 ; ISButton@3813,2051,22x22
:	ZEDQA cv 3554424111 Base.M998_Humvee: Vehicle tab true, 54 parts
:	ZEDQA cv PASS 3554424111 Base.M998_Humvee: the World window's Vehicle tab opens beside it
:	ZEDQA cv ui Base.M998_Humvee vehicle tab: ZeD_ActionBarLayer@0,0,1x1 ; SpeedControls@3641,-4000,189x28 ; UIDebugConsole@20,1848,1280x292 ; MoodlesUI@3782,1080,48x2160 ; ISButtonPrompt@0,0,1x1 ; ISEquippedItem@10,10,53x621 ; ISHotbar@-10000,-10000,256x82 ; NeatXPBar@3480,180,204x57 ; WaterMarkUI@3604,2127,226x22 ; ZeD_BeltHUD@1438,2041,853x91 ; ZeD_MoodleLayer@3782,1080,48x2160 ; ZeD_Watch@3596,10,228x52 ; ZeD_Window@1134,0,777x735 ; ZeD_Window@1929,0,1617x735 ; ZeD_MessagesToasts@3122,263,1x1 ; ISButton@3813,2051,22x22
:	ZEDQA cv back home 12057,11756
:	ZEDQA cv 8 checks, 0 failed
:	ZEDQA cv all checks passed
:	ZEDQA cv DONE
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
    1x ERROR: General f:N at FluidContainerScript.load > Sanitizing container name 'Jet Fuel Barrel', name may not contain whitespaces.
    1x ERROR: General f:N at CraftRecipeComponentScript.getIconTexture> CraftRecipeComponentScript: Recipe Piano missing UiConfigScript - falling back to SpriteConfigScript first world object face for recipe icon.
    1x ERROR: Lua f:N at Lua(Vanilla).handleMannequinZone > ERROR: Mannequin zone missing properties in media/maps/Muldraugh, KY/objects.lua coords: 13583, 1299, 0
    1x ERROR: General f:N at Basements.mergeRoomsOntoMetaCell > duplicate RoomDef.metaID for room at 10707,9484,0
    1x ERROR: General f:N at IsoMetaGrid.load > invalid room metaID #231 in cell 25,33 while reading map_meta.bin
    1x ERROR: General f:N at IsoMetaGrid.load > invalid room metaID #327914 in cell 25,33 while reading map_meta.bin
    1x ERROR: General f:N at IsoMetaGrid.load > invalid room metaID #327911 in cell 25,33 while reading map_meta.bin
    1x ERROR: General f:N at IsoMetaGrid.load > invalid room metaID #655594 in cell 25,33 while reading map_meta.bin
    3x ERROR: General f:N at ImportedSkeleton.collectBoneFrames > Could not find bone index for node name: "Body"
```
