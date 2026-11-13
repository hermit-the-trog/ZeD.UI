# ZeD-UI regression - 2026-11-13 00:13 - fullscreen4k (3840x2160 fullscreen)

| | |
|---|---|
| Started | 2026-11-13 00:13:39 |
| Finished | 2026-11-13 00:15:10 (1 min 31 s) |
| Mode | fullscreen4k (3840x2160 fullscreen) |
| Display | fontSize=2 fullScreen=true height=2160 width=3840 |
| Game build | 42.22.2 3d39148846 |
| Mod version | 0.3.0-beta12 |
| Save | Saves/Sandbox/ZeD-QA |
| Manifest | ZeDUI\tools\qa\_b13_lc_manifest.txt (1 scripts) |
| Result | **1/1 pass**, 0 warn, 0 fail, 0 timeout |
| Go numbers | 26173 to 26175 |

Screenshots are in `%USERPROFILE%/Zomboid/Screenshots` (the next run overwrites them). PASS: reached DONE with no ERR line and no Lua error. WARN: DONE with ERR lines of its own, or the script ran twice. FAIL: ok=false, a Java exception in the script's window (with -debug the game logs one even for an error a script catches) or the game lost. TIMEOUT: no DONE in time (the run stops there). Not run: after a timeout, a paused game or a lost game. "(expect ...)" prints are shown, not checked.

## Run notes

- ZeD settings: UI scale 1.75x (4K), additions Vanilla Plus (all on, Restock Casual) (the director's ModOptions.ini kept aside)
- font size: fontSize=2 for the run (was fontSize=2)
- pzrestorewin.ps1 (before a fullscreen run): no backup
- started ProjectZomboid64.exe -debug -nosteam (fullscreen, the director's options.ini)
- loaded; clicked the screen centre (1920,1080) to pass 'click to start'
- the bridge armed in game on Saves/Sandbox/ZeD-QA
- quit: quit to the main menu, then to the desktop (go 26174, 26175)
- font size: the director's line put back (fontSize=2)
- ZeD settings: the director's ModOptions.ini put back

## Results

| # | Script | Tag | Status | Seconds | Screenshots | Notes |
|---:|---|---|---|---:|---|---|
| 1 | _b13_lc.lua | lc | PASS | 14 | zqa_lc_x_4k_open.png, zqa_lc_x_4k_prints.png, zqa_lc_x_4k_print_ab.png, zqa_lc_x_4k_error_stack.png, zqa_lc_x_4k_scratch.png, zqa_lc_x_4k_commands.png, zqa_lc_x_4k_help.png | 3 expected exception(s) ignored (expect=) |

## Scripts

### 1. _b13_lc.lua (`ZEDQA lc`) - PASS, 14 s

- go 26173 at 00:14:34
- 3 expected exception(s) ignored (expect=)
- screenshots: zqa_lc_x_4k_open.png, zqa_lc_x_4k_prints.png, zqa_lc_x_4k_print_ab.png, zqa_lc_x_4k_error_stack.png, zqa_lc_x_4k_scratch.png, zqa_lc_x_4k_commands.png, zqa_lc_x_4k_help.png

```text
[ZeD.QA] state #1 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=32 missing=get
[ZeD.QA] windows reset (R)
ZEDQA lc globals: LC93=false ZeD=true ZeD.DebugConsole=true
ZEDQA lc console in use: ZeD's
ZEDQA lc armed
[ZeD.QA] run #1 ok=true
ZEDQA lc open=true page=log title=Lua console
ZEDQA lc shot open
ZEDQA lc print rows 'hello' = 2 (expect 1)
ZEDQA lc shot prints
ZEDQA lc print a,b row: [a b] n=1   (x2)
ZEDQA lc print(a,b) rows = 2 (expect 1)
ZEDQA lc shot print_ab
ERROR: General f:364> Lua(Vanilla).console> Exception thrown   (expected)
    java.lang.RuntimeException: attempted index of non-table at KahluaUtil.fail(KahluaUtil.java:100).
    Lua(Vanilla).console(spawnpoints.lua:1)
    Lua((MOD:ZeD-GUI)).pcall(ZeD_DebugConsole.lua:266)
    Lua((MOD:ZeD-GUI)).run(ZeD_DebugConsole.lua:266)
    Lua(Vanilla).step(spawnpoints.lua:45)
    Lua(Vanilla).onTick(spawnpoints.lua:19)
ERROR: General f:379> Lua(Vanilla).console> Exception thrown   (expected)
    java.lang.RuntimeException: attempted index of non-table at KahluaUtil.fail(KahluaUtil.java:100).
    Lua(Vanilla).console(spawnpoints.lua:1)
    Lua((MOD:ZeD-GUI)).pcall(ZeD_DebugConsole.lua:266)
    Lua((MOD:ZeD-GUI)).run(ZeD_DebugConsole.lua:266)
    Lua(Vanilla).step(spawnpoints.lua:46)
    Lua(Vanilla).onTick(spawnpoints.lua:19)
ERROR: General f:394> Lua(Vanilla).console> Exception thrown   (expected)
    java.lang.RuntimeException: attempted index of non-table at KahluaUtil.fail(KahluaUtil.java:100).
    Lua(Vanilla).console(spawnpoints.lua:1)
    Lua((MOD:ZeD-GUI)).pcall(ZeD_DebugConsole.lua:266)
    Lua((MOD:ZeD-GUI)).run(ZeD_DebugConsole.lua:266)
    Lua(Vanilla).step(spawnpoints.lua:47)
    Lua(Vanilla).onTick(spawnpoints.lua:19)
ZEDQA lc errrow n=3 box=3 f11=3 mod=ZeD-GUI msg=attempted index of non-table stack=73
ZEDQA lc error rows=1 (expect 1, count 3)
ZEDQA lc stack opened=true
ZEDQA lc shot error_stack
ZEDQA lc export name=ZeD_console_2026-11-13_001442.log lines=42
ZEDQA lc export first line: ZeD-GUI Lua console | 2026-11-13_001442 | 42 of 42 | errors 1
ZEDQA lc export last line: Your user name is taken out of this report. Files like console.txt still have it: look them over before you post them.
ZEDQA lc export lines naming a Users folder: 0
ZEDQA lc NOT RUN scratchpad: LC93.ConsoleScratch missing (this is not LC93's console)
ZEDQA lc scratch print rows a=0 b=0 (expect 1 each; the print(a,b) test above makes none)
ZEDQA lc shot scratch
ZEDQA lc page cmds=cmds
ZEDQA lc shot commands
ZEDQA lc page help=help
ZEDQA lc shot help
ZEDQA lc page back log=log
ZEDQA lc DONE
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
