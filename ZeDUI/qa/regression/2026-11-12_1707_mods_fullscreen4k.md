# ZeD-UI regression - 2026-11-12 17:08 - fullscreen4k (3840x2160 fullscreen)

| | |
|---|---|
| Started | 2026-11-12 17:08:03 |
| Finished | 2026-11-12 17:10:30 (2 min 27 s) |
| Mode | fullscreen4k (3840x2160 fullscreen) |
| Display | fontSize=2 fullScreen=true height=2160 width=3840 |
| Game build | 42.22.2 3d39148846 |
| Mod version | 0.3.0-beta12 |
| Save | Saves/Sandbox/ZeD-QA |
| Manifest | %USERPROFILE%\Zomboid\mods\ZeD-UI\ZeDUI\tools\qa\msc_run2_manifest.txt (1 scripts) |
| Result | **0/1 pass**, 0 warn, 1 fail, 0 timeout |
| Go numbers | 25762 to 25764 |

Screenshots are in `%USERPROFILE%/Zomboid/Screenshots` (the next run overwrites them). PASS: reached DONE with no ERR line and no Lua error. WARN: DONE with ERR lines of its own, or the script ran twice. FAIL: ok=false, a Java exception in the script's window (with -debug the game logs one even for an error a script catches) or the game lost. TIMEOUT: no DONE in time (the run stops there). Not run: after a timeout, a paused game or a lost game. "(expect ...)" prints are shown, not checked.

## Run notes

- ZeD settings: UI scale 1.75x (4K), additions Vanilla Plus (all on, Restock Casual) (the director's ModOptions.ini kept aside)
- font size: fontSize=2 for the run (was fontSize=2)
- pzrestorewin.ps1 (before a fullscreen run): no backup
- started ProjectZomboid64.exe -debug -nosteam (fullscreen, the director's options.ini)
- loaded; clicked the screen centre (1920,1080) to pass 'click to start'
- the bridge armed in game on Saves/Sandbox/ZeD-QA
- quit: quit to the main menu, then to the desktop (go 25763, 25764)
- font size: the director's line put back (fontSize=2)
- ZeD settings: the director's ModOptions.ini put back

## Results

| # | Script | Tag | Status | Seconds | Screenshots | Notes |
|---:|---|---|---|---:|---|---|
| 1 | zedqa_msc_run2.lua | msc2 | **FAIL** | 34 | zqa_msc2_1_both_windows.png, zqa_msc2_2_engine_part_menu.png, zqa_msc2_3_after_mechanics_closed.png, zqa_msc2_4_reopened.png | 12 Java exception(s) in the log |

## Scripts

### 1. zedqa_msc_run2.lua (`ZEDQA msc2`) - FAIL, 34 s

- go 25762 at 17:09:28
- 12 Java exception(s) in the log
- screenshots: zqa_msc2_1_both_windows.png, zqa_msc2_2_engine_part_menu.png, zqa_msc2_3_after_mechanics_closed.png, zqa_msc2_4_reopened.png

```text
ZEDQA msc2 ZeD loaded: false (should be false) | MSC loaded true | screen 3840x2160
ZEDQA msc2 start (22 steps)
[ZeD.QA] run #1 ok=true
ZEDQA msc2 car at 929,13040
ZEDQA msc2 initialized=true hoodOpen=false canAccessEngine=false
ZEDQA msc2 onMechanic called
ZEDQA msc2 t+14 ms: mech=false hood=false msc=false
ZEDQA msc2 t+3084 ms: mech=false hood=true msc=false
ZEDQA msc2 t+6967 ms: mech=true hood=true msc=false
ZEDQA msc2 t+6999 ms: mech=true hood=true msc=true
ZEDQA msc2 first mechanics window visible at 6967 ms, hood open at 3085 ms, Summer Car window first seen at 6999 ms
ZEDQA msc2 steady, hood open: game mechanics window x=1520 y=767 w=800 h=600 visible=true
ZEDQA msc2 steady, hood open: Summer Car engine window x=2330 y=767 w=500 h=785 visible=true title=MSC Engine Components activeTab=engine placement=nil
ZEDQA msc2 shot 1_both_windows
ZEDQA msc2 Summer Car window children/panels: SuperType=ISUIElement, closeButton=ISButton, collapseButton=ISButton, ecuActionButton=ISButton, infoButton=ISButton, leftList=ISScrollingListBox, mechanicsUI=ISVehicleMechanics, pinButton=ISButton, resizeWidget2=ISResizeWidget, resizeWidget=ISResizeWidget, rightList=ISScrollingListBox
ERROR: General f:1910> Lua(Vanilla).pcall> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in pcall at KahluaUtil.fail(KahluaUtil.java:100).
    Lua(Vanilla).pcall(spawnpoints.lua:108)   (x2)
    Lua(Vanilla).contents(spawnpoints.lua:106)
    Lua(Vanilla).tick(spawnpoints.lua:159)
ERROR: General f:1910> Lua(Vanilla).pcall> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in pcall at KahluaUtil.fail(KahluaUtil.java:100).
    Lua(Vanilla).pcall(spawnpoints.lua:108)   (x2)
    Lua(Vanilla).contents(spawnpoints.lua:106)
    Lua(Vanilla).tick(spawnpoints.lua:159)
ERROR: General f:1910> Lua(Vanilla).pcall> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in pcall at KahluaUtil.fail(KahluaUtil.java:100).
    Lua(Vanilla).pcall(spawnpoints.lua:108)   (x2)
    Lua(Vanilla).contents(spawnpoints.lua:106)
    Lua(Vanilla).tick(spawnpoints.lua:159)
ERROR: General f:1910> Lua(Vanilla).pcall> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in pcall at KahluaUtil.fail(KahluaUtil.java:100).
    Lua(Vanilla).pcall(spawnpoints.lua:108)   (x2)
    Lua(Vanilla).contents(spawnpoints.lua:106)
    Lua(Vanilla).tick(spawnpoints.lua:159)
ERROR: General f:1910> Lua(Vanilla).pcall> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in pcall at KahluaUtil.fail(KahluaUtil.java:100).
    Lua(Vanilla).pcall(spawnpoints.lua:108)   (x2)
    Lua(Vanilla).contents(spawnpoints.lua:106)
    Lua(Vanilla).tick(spawnpoints.lua:159)
ERROR: General f:1910> Lua(Vanilla).pcall> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in pcall at KahluaUtil.fail(KahluaUtil.java:100).
    Lua(Vanilla).pcall(spawnpoints.lua:108)   (x2)
    Lua(Vanilla).contents(spawnpoints.lua:106)
    Lua(Vanilla).tick(spawnpoints.lua:159)
ERROR: General f:1910> Lua(Vanilla).pcall> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in pcall at KahluaUtil.fail(KahluaUtil.java:100).
    Lua(Vanilla).pcall(spawnpoints.lua:108)   (x2)
    Lua(Vanilla).contents(spawnpoints.lua:106)
    Lua(Vanilla).tick(spawnpoints.lua:159)
ERROR: General f:1910> Lua(Vanilla).pcall> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in pcall at KahluaUtil.fail(KahluaUtil.java:100).
    Lua(Vanilla).pcall(spawnpoints.lua:108)   (x2)
    Lua(Vanilla).contents(spawnpoints.lua:106)
    Lua(Vanilla).tick(spawnpoints.lua:159)
ERROR: General f:1910> Lua(Vanilla).pcall> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in pcall at KahluaUtil.fail(KahluaUtil.java:100).
    Lua(Vanilla).pcall(spawnpoints.lua:108)   (x2)
    Lua(Vanilla).contents(spawnpoints.lua:106)
    Lua(Vanilla).tick(spawnpoints.lua:159)
ERROR: General f:1910> Lua(Vanilla).pcall> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in pcall at KahluaUtil.fail(KahluaUtil.java:100).
    Lua(Vanilla).pcall(spawnpoints.lua:108)   (x2)
    Lua(Vanilla).contents(spawnpoints.lua:106)
    Lua(Vanilla).tick(spawnpoints.lua:159)
ERROR: General f:1910> Lua(Vanilla).pcall> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in pcall at KahluaUtil.fail(KahluaUtil.java:100).
    Lua(Vanilla).pcall(spawnpoints.lua:108)   (x2)
    Lua(Vanilla).contents(spawnpoints.lua:106)
    Lua(Vanilla).tick(spawnpoints.lua:159)
ERROR: General f:1910> Lua(Vanilla).pcall> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in pcall at KahluaUtil.fail(KahluaUtil.java:100).
    Lua(Vanilla).pcall(spawnpoints.lua:108)   (x2)
    Lua(Vanilla).contents(spawnpoints.lua:106)
    Lua(Vanilla).tick(spawnpoints.lua:159)
ZEDQA msc2 Summer Car window UI children: ISResizeWidget, ISResizeWidget, ISButton, ISButton, ISButton, ISButton, ISScrollingListBox, ISScrollingListBox, ISButton, ISButton, ISButton, ISButton
ZEDQA msc2 doPartContextMenu(Engine) ok=true
ZEDQA msc2 Engine part menu (3 options): DBG: ISVehicleMechanics.cheat=true, Inspect engine components, Remove engine at lift [greyed]
ZEDQA msc2 shot 2_engine_part_menu
ZEDQA msc2 mechanics window closed
ZEDQA msc2 after the mechanics window closed: game mechanics window x=1520 y=767 w=800 h=600 visible=false
ZEDQA msc2 after the mechanics window closed: no Summer Car engine window
ZEDQA msc2 shot 3_after_mechanics_closed
ZEDQA msc2 onMechanic again (hood already open)
ZEDQA msc2 again t+10 ms: mech=false msc=false
ZEDQA msc2 again t+4295 ms: mech=true msc=false
ZEDQA msc2 again t+4311 ms: mech=true msc=true
ZEDQA msc2 reopened: game mechanics window x=1520 y=767 w=800 h=600 visible=true
ZEDQA msc2 reopened: Summer Car engine window x=2330 y=767 w=500 h=785 visible=true title=MSC Engine Components activeTab=engine placement=nil
ZEDQA msc2 shot 4_reopened
ZEDQA msc2 put back: windows closed, car and key removed
ZEDQA msc2 DONE
```

## Console errors outside scripts

ERROR lines from launch to quit that fall in no script's window, once each (count first).

```text
    1x ERROR: General f:N at AngelCodeFont.parseFnt > AngelCodeFont failed to load page 0 texture E:/Project Zomboid/SteamApps/common/ProjectZomboid/media/mainfont_0.png
    1x ERROR: General f:N at AngelCodeFont.parseFnt > AngelCodeFont failed to load page 0 texture E:/Project Zomboid/SteamApps/common/ProjectZomboid/media/mainfont2_0.png
    2x ERROR: General f:N at AngelCodeFont.parseFnt > AngelCodeFont failed to load page 0 texture E:/Project Zomboid/SteamApps/common/ProjectZomboid/media/fonts/zomboidDialogue.bmfc_0.png
    3x ERROR: General f:N at FluidContainerScript.load > Sanitizing container name 'Large Bucket', name may not contain whitespaces.
    3x ERROR: General f:N at FluidContainerScript.load > Sanitizing container name 'Fuel Pump', name may not contain whitespaces.
    1x ERROR: General f:N at CraftRecipeComponentScript.getIconTexture> CraftRecipeComponentScript: Recipe Piano missing UiConfigScript - falling back to SpriteConfigScript first world object face for recipe icon.
    1x ERROR: Lua f:N at Lua(Vanilla).handleMannequinZone > ERROR: Mannequin zone missing properties in media/maps/Muldraugh, KY/objects.lua coords: 13583, 1299, 0
    1x ERROR: General f:N at Basements.mergeRoomsOntoMetaCell > duplicate RoomDef.metaID for room at 10707,9484,0
    1x ERROR: General f:N at IsoMetaGrid.load > invalid room metaID #231 in cell 25,33 while reading map_meta.bin
    1x ERROR: General f:N at IsoMetaGrid.load > invalid room metaID #327914 in cell 25,33 while reading map_meta.bin
    1x ERROR: General f:N at IsoMetaGrid.load > invalid room metaID #327911 in cell 25,33 while reading map_meta.bin
    1x ERROR: General f:N at IsoMetaGrid.load > invalid room metaID #655594 in cell 25,33 while reading map_meta.bin
    1x ERROR: General f:N at LuaManager.getFunctionObject > no such function "Vehicles.Init.Radio"
```
